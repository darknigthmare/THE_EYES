#!/usr/bin/env python3
"""Fetch selected official Godot templates without downloading every platform.

Uses HTTP byte ranges and Python's ZIP CRC verification. TLS and the official
Godot release URL establish provenance; the JSON manifest records local SHA-256
hashes for repeatability. A whole-archive release checksum cannot be checked
without downloading the whole archive, and this tool does not claim otherwise.

Example:
    python3 tools/fetch_export_templates.py --destination /tmp/godot-templates \
        --platform windows --platform linux

Standard library only. Does not modify system installations or user preferences.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import urllib.request
import zipfile


class HTTPRangeFile(io.RawIOBase):
    """Seekable read-only HTTP file with one bounded forward-read cache."""

    def __init__(self, url: str, block_size: int = 16 * 1024 * 1024) -> None:
        super().__init__()
        self.source_url = url
        with urllib.request.urlopen(
            urllib.request.Request(url, method="HEAD"), timeout=60
        ) as response:
            self.url = response.url
            self.length = int(response.headers["Content-Length"])
        self.position = 0
        self.block_size = block_size
        self.read_limit = self.length
        self.cache_start = 0
        self.cache = b""
        self.bytes_downloaded = 0

    def readable(self) -> bool:
        return True

    def seekable(self) -> bool:
        return True

    def tell(self) -> int:
        return self.position

    def seek(self, offset: int, whence: int = os.SEEK_SET) -> int:
        if whence == os.SEEK_SET:
            target = offset
        elif whence == os.SEEK_CUR:
            target = self.position + offset
        elif whence == os.SEEK_END:
            target = self.length + offset
        else:
            raise ValueError("Invalid seek origin")
        if target < 0:
            raise ValueError("Cannot seek before the archive")
        self.position = target
        return target

    def read(self, size: int = -1) -> bytes:
        if size is None or size < 0:
            size = max(0, self.length - self.position)
        size = min(size, max(0, self.length - self.position))
        output = bytearray()
        while len(output) < size:
            cache_end = self.cache_start + len(self.cache)
            if not (self.cache_start <= self.position < cache_end):
                self._fill_cache()
                cache_end = self.cache_start + len(self.cache)
            count = min(size - len(output), cache_end - self.position)
            start = self.position - self.cache_start
            output.extend(self.cache[start : start + count])
            self.position += count
        return bytes(output)

    def _fill_cache(self) -> None:
        start = self.position
        end = min(self.length - 1, self.read_limit - 1, start + self.block_size - 1)
        if end < start:
            raise RuntimeError("ZIP read exceeded the selected entry bounds")
        request = urllib.request.Request(
            self.url, headers={"Range": f"bytes={start}-{end}"}
        )
        with urllib.request.urlopen(request, timeout=120) as response:
            expected_range = f"bytes {start}-{end}/{self.length}"
            if response.status != 206 or response.headers.get("Content-Range") != expected_range:
                raise RuntimeError("Server ignored the byte range; refusing a full archive download")
            data = response.read(end - start + 2)
        if len(data) != end - start + 1:
            raise RuntimeError("Truncated HTTP byte range")
        self.cache_start = start
        self.cache = data
        self.bytes_downloaded += len(data)


def selected_members(platforms: list[str], names: list[str]) -> list[str]:
    required = ["templates/version.txt"]
    if "templates/icudt_godot.dat" in names:
        required.append("templates/icudt_godot.dat")
    patterns = {
        "windows": r"templates/windows_release_x86_64\.exe$",
        "linux": r"templates/linux_release\.x86_64$",
        "web": r"templates/web_(?:nothreads_)?release\.zip$",
    }
    for platform in platforms:
        matches = [name for name in names if re.fullmatch(patterns[platform], name)]
        if not matches:
            raise RuntimeError(f"No matching official template found for {platform!r}")
        required.extend(matches)
        if platform == "windows" and "templates/windows_release_x86_64_console.exe" in names:
            required.append("templates/windows_release_x86_64_console.exe")
    missing = [name for name in required if name not in names]
    if missing:
        raise RuntimeError(f"Missing archive entries: {missing}")
    return sorted(set(required))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", default="4.7.2", help="Official stable Godot release version")
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--platform", choices=["windows", "linux", "web"], action="append")
    parser.add_argument("--list", action="store_true", help="List members without extracting")
    arguments = parser.parse_args()
    if not re.fullmatch(r"\d+\.\d+(?:\.\d+)?", arguments.version):
        parser.error("Version must be a numeric stable release, such as 4.7.2")
    platforms = arguments.platform or ["windows", "linux"]
    url = (
        "https://github.com/godotengine/godot-builds/releases/download/"
        f"{arguments.version}-stable/Godot_v{arguments.version}-stable_export_templates.tpz"
    )
    print(f"Reading official Godot {arguments.version} template index", flush=True)
    remote = HTTPRangeFile(url)
    results: list[dict[str, object]] = []
    with zipfile.ZipFile(remote) as archive:
        if arguments.list:
            for info in archive.infolist():
                print(f"{info.filename}\t{info.file_size}\t{info.compress_size}")
            print(f"Downloaded index bytes: {remote.bytes_downloaded}")
            return 0
        members = selected_members(platforms, archive.namelist())
        arguments.destination.mkdir(parents=True, exist_ok=True)
        for name in members:
            info = archive.getinfo(name)
            # The local header contains a 16-bit extra-field length. Bound
            # prefetch to this member plus that maximum, avoiding unrelated
            # platforms when a tiny file follows a large template.
            remote.read_limit = min(
                remote.length,
                info.header_offset + 30 + len(info.filename.encode("utf-8")) + 65535 + info.compress_size,
            )
            target = arguments.destination / Path(name).name
            temporary = target.with_name(target.name + ".partial")
            print(f"Extracting {target.name} ({info.file_size:,} bytes)", flush=True)
            try:
                with archive.open(info) as source, temporary.open("wb") as output:
                    shutil.copyfileobj(source, output, length=1024 * 1024)
                if temporary.stat().st_size != info.file_size:
                    raise RuntimeError(f"Incorrect extracted size for {name}")
                temporary.replace(target)
            finally:
                temporary.unlink(missing_ok=True)
            if target.name.startswith("linux_"):
                target.chmod(target.stat().st_mode | 0o111)
            digest = hashlib.sha256()
            with target.open("rb") as source:
                for chunk in iter(lambda: source.read(1024 * 1024), b""):
                    digest.update(chunk)
            results.append({
                "member": name,
                "filename": target.name,
                "bytes": info.file_size,
                "archive_crc32": f"{info.CRC:08x}",
                "sha256": digest.hexdigest(),
            })
    manifest = {
        "source": url,
        "version": arguments.version,
        "whole_archive_bytes": remote.length,
        "downloaded_bytes": remote.bytes_downloaded,
        "verification": "HTTPS official release, ZIP CRC32, local SHA-256; no whole-archive checksum",
        "templates": results,
    }
    (arguments.destination / "download-manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Downloaded {remote.bytes_downloaded:,} of {remote.length:,} archive bytes", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
