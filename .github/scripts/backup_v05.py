#!/usr/bin/env python3
"""Prepare or publish the verified public THE EYES v0.5.0 backup."""
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import zipfile
from datetime import datetime, timezone

REPO = "darknigthmare/THE_EYES"
TAG = "v0.5.0"
VERSION = "0.5.0"
PACKAGE = "THE_EYES_v0.5.0_Windows_x64"
BACKUP = "THE_EYES_v0.5.0_COMPLETE_BACKUP.zip"
CHECKSUM = BACKUP + ".sha256"
ORIGINAL = {PACKAGE + ".zip", "SHA256SUMS.txt", "WINDOWS_SMOKE.json"}
TEMPLATE_SHA = "d34d36f3be1a6c49c56525ae86469b92e4f417ddf0b43cf00dd80c385c4b0562"
TRIALS = "silent echoes relay vault ritual clock light strings chimes".split()
TEMP = Path(os.environ["RUNNER_TEMP"])
FINAL = os.environ["FINAL_MAIN"]
BUILD = os.environ["EXPECTED_BUILD_COMMIT"]

def need(condition, message):
    if not condition:
        raise RuntimeError(message)

def run(*args, cwd=None, data=None):
    return subprocess.check_output([str(x) for x in args], cwd=cwd, input=data)

def gh(path):
    return json.loads(run("gh", "api", f"repos/{REPO}/{path}"))

def git(repo, *args, data=None):
    return run("git", "-C", repo, *args, data=data)

def text(raw):
    return raw.decode("utf-8").strip()

def sha(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

def zip_sha(archive, member):
    with archive.open(member) as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

def write_json(path, value):
    Path(path).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def checksum_entries(raw):
    entries = {}
    for line in raw.decode("utf-8-sig").splitlines():
        match = re.fullmatch(r"([a-fA-F0-9]{64}) [ *](.+)", line)
        need(match is not None, "Malformed checksum line")
        digest, name = match.groups()
        need(name not in entries, f"Duplicate checksum: {name}")
        entries[name] = digest.lower()
    return entries

def members(archive):
    names = archive.namelist()
    need(len(names) == len(set(names)), "Duplicate ZIP member")
    for name in names:
        path = PurePosixPath(name)
        need(not path.is_absolute() and ".." not in path.parts and "\\" not in name,
             f"Invalid ZIP member path: {name}")
    need(archive.testzip() is None, "ZIP CRC failure")
    return {item.filename for item in archive.infolist() if not item.is_dir()}

def download_asset(asset, path):
    with Path(path).open("wb") as target:
        subprocess.run(["gh", "api", f"repos/{REPO}/releases/assets/{asset['id']}",
                        "-H", "Accept: application/octet-stream"], stdout=target, check=True)
    digest = sha(path)
    need(Path(path).stat().st_size == asset["size"], f"Asset size mismatch: {asset['name']}")
    if asset.get("digest"):
        need(asset["digest"].lower() == "sha256:" + digest,
             f"GitHub asset digest mismatch: {asset['name']}")
    return digest

def release():
    value = gh(f"releases/tags/{TAG}")
    need(value["tag_name"] == TAG and value["draft"] is False, "Release is not public v0.5.0")
    names = [asset["name"] for asset in value["assets"]]
    need(len(names) == len(set(names)), "Duplicate release asset names")
    return value

def no_backup_assets(value):
    existing = {asset["name"] for asset in value["assets"]} & {BACKUP, CHECKSUM}
    need(not existing, "Refusing to overwrite existing backup asset(s): " + ", ".join(sorted(existing)))

def tag_commit_api():
    obj = gh(f"git/ref/tags/{TAG}")["object"]
    for _ in range(16):
        if obj["type"] == "commit":
            return obj["sha"]
        need(obj["type"] == "tag", "Unexpected release tag object")
        obj = gh(f"git/tags/{obj['sha']}")["object"]
    raise RuntimeError("Release tag nesting is excessive")

def inventory(directory):
    return {path.relative_to(directory).as_posix(): {"bytes": path.stat().st_size, "sha256": sha(path)}
            for path in sorted(directory.rglob("*")) if path.is_file()}

def output(name, value):
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as stream:
            stream.write(f"{name}={value}\n")

def summary(message):
    print(message)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as stream:
            stream.write(message + "\n")

def prepare():
    official = release()
    no_backup_assets(official)
    need({asset["name"] for asset in official["assets"]} == ORIGINAL,
         "Expected exactly the three original release assets")
    need(tag_commit_api() == BUILD, "Release tag differs from pinned executable commit")

    mirror = TEMP / "eyes-backup-mirror.git"
    source = TEMP / "eyes-backup-source"
    restored = TEMP / "eyes-backup-restored.git"
    restored_worktree = TEMP / "eyes-backup-restored-worktree"
    payload = TEMP / "eyes-backup-payload"
    result = TEMP / "eyes-backup-release"
    for path in [mirror, source, restored, restored_worktree, payload, result]:
        need(not path.exists(), f"Temporary destination already exists: {path.name}")
    payload.mkdir()
    result.mkdir()
    release_dir = payload / "release"
    release_dir.mkdir()

    asset_records = []
    for asset in sorted(official["assets"], key=lambda item: item["name"]):
        digest = download_asset(asset, release_dir / asset["name"])
        asset_records.append({"name": asset["name"], "id": asset["id"], "bytes": asset["size"],
                              "sha256": digest, "github_digest": asset.get("digest"),
                              "url": asset["browser_download_url"]})
    outer = checksum_entries((release_dir / "SHA256SUMS.txt").read_bytes())
    need(set(outer) == {PACKAGE + ".zip", "WINDOWS_SMOKE.json"}, "Unexpected release checksum entries")
    for name, digest in outer.items():
        need(sha(release_dir / name) == digest, f"Release checksum mismatch: {name}")

    with zipfile.ZipFile(release_dir / (PACKAGE + ".zip")) as archive:
        names = members(archive)
        prefix = PACKAGE + "/"
        need(all(name.startswith(prefix) for name in names), "Unexpected Windows package root")
        sums = checksum_entries(archive.read(prefix + "SHA256SUMS.txt"))
        need({prefix + name for name in sums} == names - {prefix + "SHA256SUMS.txt"},
             "Windows package checksum coverage is incomplete")
        for name, digest in sums.items():
            need(zip_sha(archive, prefix + name) == digest, f"Windows payload mismatch: {name}")
        build_info = json.loads(archive.read(prefix + "BUILD_INFO.json").decode("utf-8-sig"))
        need(build_info["project_version"] == VERSION, "Incorrect Windows version")
        need(build_info["source_commit"] == BUILD and build_info["source_worktree_dirty"] is False,
             "Windows source commit or clean-worktree proof differs")
        need(build_info["template_sha256"] == TEMPLATE_SHA, "Windows export template differs")
        need(build_info["godot_version"].startswith("4.7.2.stable"), "Unexpected Godot version")
        need(build_info["executable_sha256"] == zip_sha(archive, prefix + "THE_EYES.exe"),
             "Executable digest differs from BUILD_INFO")

    report = json.loads((release_dir / "WINDOWS_SMOKE.json").read_text(encoding="utf-8-sig"))
    expected = {(role, contract, "") for role in ["survivor", "eye", "squad"]
                for contract in ["first", "second", "mix", "third"]}
    expected |= {("practice", "practice", trial) for trial in TRIALS}
    need(report["schema_version"] == 3 and report["project_version"] == VERSION, "Smoke schema/version differs")
    need(report["source_commit"] == BUILD and report["archive_sha256"] == outer[PACKAGE + ".zip"],
         "Smoke report describes a different source/archive")
    need(report["godot_version"] == build_info["godot_version"], "Smoke and build engine versions differ")
    need(report["platform"] == "Windows" and report["mode"] == "headless" and
         report["graphical_hardware_playtest"] is False, "Unexpected smoke evidence scope")
    cases = report["cases"]
    need(len(cases) == 21 and {(c["role"], c["contract"], c.get("trial_id", "")) for c in cases} == expected,
         "Smoke matrix is not the exact 21 required cases")
    need(all(c["session_mode"] == c["role"] and c["exit_code"] == 0 and c["frames_requested"] == 240
             and c["ready_marker_seen"] is True and c["engine_errors_seen"] is False for c in cases),
         "A native Windows startup case did not pass")

    run("git", "clone", "--mirror", f"https://github.com/{REPO}.git", mirror)
    need(text(git(mirror, "rev-parse", "--is-shallow-repository")) == "false", "Mirror is shallow")
    need(text(git(mirror, "rev-parse", FINAL + "^{commit}")) == FINAL, "Final source commit unavailable")
    need(text(git(mirror, "rev-parse", f"refs/tags/{TAG}^{{commit}}")) == BUILD, "Mirror release tag differs")
    git(mirror, "merge-base", "--is-ancestor", BUILD, FINAL)
    git(mirror, "diff", "--no-ext-diff", "--no-textconv", "--exit-code", BUILD, FINAL, "--", "game", "tools")
    code_trees = {}
    for directory in ["game", "tools"]:
        built = text(git(mirror, "rev-parse", f"{BUILD}:{directory}"))
        final = text(git(mirror, "rev-parse", f"{FINAL}:{directory}"))
        need(built == final, f"{directory}/ differs from executable source")
        code_trees[directory] = final
    git(mirror, "worktree", "add", "--detach", source, FINAL)

    source_zip = payload / "SOURCE_FINAL_MAIN.zip"
    git(mirror, "archive", "--format=zip", "--prefix=THE_EYES/", f"--output={source_zip}", FINAL)
    blobs = {}
    for entry in git(mirror, "ls-tree", "-rz", "--full-tree", FINAL).split(b"\0"):
        if not entry:
            continue
        metadata, raw_path = entry.split(b"\t", 1)
        mode, kind, oid = metadata.decode("ascii").split()
        need(kind == "blob", "Submodules require explicit backup support")
        blobs[raw_path.decode("utf-8")] = {"mode": mode, "blob": oid}
    with zipfile.ZipFile(source_zip) as archive:
        names = members(archive)
        need(names == {"THE_EYES/" + name for name in blobs}, "Source ZIP file set differs from Git")
        for name, info in blobs.items():
            content = archive.read("THE_EYES/" + name)
            need(text(git(mirror, "hash-object", "--stdin", data=content)) == info["blob"],
                 f"Source ZIP blob mismatch: {name}")
            info["sha256"] = hashlib.sha256(content).hexdigest()
    write_json(payload / "SOURCE_BLOBS.json", blobs)

    git(mirror, "update-ref", "refs/heads/backup-final-main", FINAL)
    refs = text(git(mirror, "for-each-ref", "--format=%(refname) %(objectname)")).splitlines()
    bundle = payload / "THE_EYES.bundle"
    git(mirror, "bundle", "create", bundle, "--all")
    git(mirror, "bundle", "verify", bundle)
    run("git", "clone", "--mirror", bundle, restored)
    git(restored, "fsck", "--full", "--strict")
    need(text(git(restored, "for-each-ref", "--format=%(refname) %(objectname)")).splitlines() == refs,
         "Restored bundle refs differ from source mirror")
    need(text(git(restored, "rev-parse", BUILD + "^{commit}")) == BUILD, "Build commit missing from bundle")
    git(restored, "worktree", "add", "--detach", restored_worktree, FINAL)
    need(text(git(restored_worktree, "rev-parse", "HEAD")) == FINAL, "Restored worktree commit differs")
    need(not text(git(restored_worktree, "status", "--porcelain")), "Restored worktree is not clean")

    bible = source / "docs" / "bible"
    need(bible.is_dir() and (bible / "15_TRIAL_WORKSHOP.md").is_file(), "Workshop bible chapter missing")
    shutil.copytree(bible, payload / "Bible_EN")
    chapters = sorted(bible.glob("*.md"), key=lambda path: (path.name != "README.md", path.name))
    combined = f"# THE EYES — Complete Game Bible (English)\n\nSource commit: {FINAL}\n"
    for chapter in chapters:
        combined += f"\n\n---\n\n<!-- Source: docs/bible/{chapter.name} -->\n\n" + chapter.read_text(encoding="utf-8")
    (payload / "THE_EYES_BIBLE_EN.md").write_text(combined + "\n", encoding="utf-8")
    shutil.copy2(source / "docs" / "DEMARRAGE_FR.md", payload / "DEMARRAGE_FR.md")
    guide = f"""# Restaurer THE EYES v0.5.0

Cette sauvegarde contient le projet Godot, l'historique Git accessible lors de
la capture, la Bible en anglais, les guides français et les trois fichiers
officiels de la préversion Windows v0.5.0.

## Provenance

- Dépôt public : https://github.com/{REPO}
- Source finale sauvegardée : {FINAL}
- Source exacte de l'exécutable : {BUILD}
- Version : {TAG}
- Les arbres game/ et tools/ des deux commits sont identiques.
- Le commit du workflow de sauvegarde est indiqué séparément dans BACKUP_MANIFEST.json.

## Vérifier les fichiers

Télécharger {BACKUP} et {CHECKSUM} depuis la release officielle.
Avant extraction, comparer l'empreinte SHA-256 du ZIP à celle du fichier .sha256.

Sous Linux ou dans un terminal disposant de sha256sum :

    sha256sum -c {CHECKSUM}

Sous PowerShell :

    Get-FileHash -Algorithm SHA256 .\\{BACKUP}

Extraire ensuite tout le ZIP. Depuis le dossier extrait, vérifier les composants :

    sha256sum -c SHA256SUMS.txt

Le manifeste interne décrit les composants. L'empreinte du ZIP complet reste
externe : un fichier ne peut pas contenir sa propre empreinte définitive.

## Récupérer le projet et tout l'historique Git sauvegardé

La vérification CI a cloné le bundle dans un dépôt neuf, comparé toutes les
références et exécuté git fsck --full --strict avec succès.

Pour préserver toutes les références sauvegardées :

    git clone --mirror THE_EYES.bundle THE_EYES_RESTORED.git
    git -C THE_EYES_RESTORED.git fsck --full --strict
    git -C THE_EYES_RESTORED.git worktree add --detach ../THE_EYES_RESTORED {FINAL}

Pour une copie de travail simple :

    git clone --branch backup-final-main THE_EYES.bundle THE_EYES_RESTORED
    git -C THE_EYES_RESTORED checkout --detach {FINAL}
    git -C THE_EYES_RESTORED fsck --full --strict

Ouvrir ensuite THE_EYES_RESTORED/game/project.godot avec Godot 4.7.2.
La branche backup-final-main fournit un point de restauration explicite.

## Récupérer les sources sans Git

Extraire SOURCE_FINAL_MAIN.zip. Ouvrir THE_EYES/game/project.godot dans Godot 4.7.2.
Chaque fichier de cette archive a été comparé au blob Git du commit final.
SOURCE_BLOBS.json enregistre les chemins, modes, identifiants Git et SHA-256.

## Jouer à la version Windows

Dans release/, vérifier SHA256SUMS.txt, puis extraire entièrement
{PACKAGE}.zip et ouvrir THE_EYES.exe.
Conserver ensemble les fichiers extraits. Voir DEMARRAGE_FR.md pour les commandes.

WINDOWS_SMOKE.json décrit 21 démarrages natifs Windows en mode headless,
dont neuf épreuves Workshop. Ces contrôles ne constituent pas une partie
graphique sur matériel Windows ni une mesure de performances.

## Documentation et données personnelles

THE_EYES_BIBLE_EN.md regroupe les chapitres ; Bible_EN/ conserve les originaux.
Cette sauvegarde du projet public n'inclut pas les carnets ou réglages propres
à une installation du jeu. Conserver séparément ces fichiers locaux si nécessaire.
"""
    (payload / "RESTAURER_FR.md").write_text(guide, encoding="utf-8")
    release_metadata = {"id": official["id"], "tag": TAG, "prerelease": official["prerelease"],
                        "url": official["html_url"], "published_at": official["published_at"],
                        "assets": asset_records}
    write_json(release_dir / "RELEASE_METADATA.json", release_metadata)
    manifest = {
        "schema_version": 1, "project": "THE EYES", "project_version": VERSION,
        "created_at": datetime.now(timezone.utc).isoformat(), "repository": REPO,
        "final_main_commit": FINAL, "executable_source_commit": BUILD,
        "backup_workflow_commit": os.environ["GITHUB_SHA"],
        "workflow_run_id": int(os.environ["GITHUB_RUN_ID"]),
        "workflow_run_attempt": int(os.environ.get("GITHUB_RUN_ATTEMPT", "1")),
        "workflow_run_url": f"https://github.com/{REPO}/actions/runs/{os.environ['GITHUB_RUN_ID']}",
        "source_tree": text(git(mirror, "rev-parse", FINAL + "^{tree}")),
        "identical_game_tools_trees": code_trees, "git_refs": refs,
        "source_blob_count": len(blobs), "release": release_metadata,
        "verification": {
            "source_zip_compared_to_every_git_blob": True,
            "bundle_restored_into_fresh_mirror": True,
            "bundle_refs_match": True, "fresh_bundle_fsck_full_strict_exit_code": 0,
            "restored_worktree_clean_at_final_main": True,
            "original_release_assets_sha256_verified": True,
            "windows_package_crc_and_all_file_hashes_verified": True,
            "windows_smoke_schema": 3, "windows_smoke_case_count": 21,
            "windows_graphical_hardware_playtest": False,
        },
        "files": inventory(payload),
    }
    write_json(payload / "BACKUP_MANIFEST.json", manifest)
    hashes = inventory(payload)
    (payload / "SHA256SUMS.txt").write_text(
        "".join(f"{info['sha256']}  {name}\n" for name, info in hashes.items()), encoding="utf-8")
    archive_path = result / BACKUP
    with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(payload.rglob("*")):
            if path.is_file():
                archive.write(path, path.relative_to(payload).as_posix())
    with zipfile.ZipFile(archive_path) as archive:
        names = members(archive)
        sums = checksum_entries(archive.read("SHA256SUMS.txt"))
        need(names == set(sums) | {"SHA256SUMS.txt"}, "Complete backup checksum coverage differs")
        for name, digest in sums.items():
            need(zip_sha(archive, name) == digest, f"Complete backup readback mismatch: {name}")
        saved = json.loads(archive.read("BACKUP_MANIFEST.json"))
        need(set(saved["files"]) == names - {"BACKUP_MANIFEST.json", "SHA256SUMS.txt"},
             "Manifest file coverage differs")
        for name, info in saved["files"].items():
            need(info["sha256"] == sums[name] and info["bytes"] == archive.getinfo(name).file_size,
                 f"Manifest file metadata differs: {name}")
    digest = sha(archive_path)
    (result / CHECKSUM).write_text(f"{digest}  {BACKUP}\n", encoding="utf-8")
    output("backup_sha256", digest)
    summary(f"Verified complete backup: {BACKUP}\n\nSHA-256: {digest}\n\n"
            f"Source {FINAL}; executable source {BUILD}; {len(blobs)} source blobs; "
            f"{len(refs)} Git refs; 21 native Windows headless startup cases.")

def publish():
    directory = TEMP / "eyes-backup-release"
    archive_path = directory / BACKUP
    digest = sha(archive_path)
    need(re.fullmatch(r"[0-9a-f]{64}", os.environ["EXPECTED_BACKUP_SHA256"]) is not None,
         "Missing prepared backup digest")
    need(digest == os.environ["EXPECTED_BACKUP_SHA256"], "Downloaded backup differs from prepared artifact")
    need(checksum_entries((directory / CHECKSUM).read_bytes()) == {BACKUP: digest},
         "External backup checksum differs")
    with zipfile.ZipFile(archive_path) as archive:
        manifest = json.loads(archive.read("BACKUP_MANIFEST.json"))
    need(manifest["repository"] == REPO and manifest["final_main_commit"] == FINAL and
         manifest["executable_source_commit"] == BUILD, "Backup provenance differs from pinned inputs")
    original = {item["name"]: item for item in manifest["release"]["assets"]}
    need(set(original) == ORIGINAL, "Backup original release asset set differs")
    current = release()
    no_backup_assets(current)
    need(current["id"] == manifest["release"]["id"], "Release was replaced after preparation")
    need(tag_commit_api() == BUILD, "Release tag changed after preparation")

    def check_originals(value):
        by_name = {item["name"]: item for item in value["assets"]}
        need(ORIGINAL <= set(by_name), "An original release asset disappeared")
        for name, recorded in original.items():
            item = by_name[name]
            need(item["id"] == recorded["id"] and item["size"] == recorded["bytes"],
                 f"Original release asset changed: {name}")
            if item.get("digest"):
                need(item["digest"].lower() == "sha256:" + recorded["sha256"],
                     f"Original release asset digest changed: {name}")

    check_originals(current)
    need({item["name"] for item in current["assets"]} == ORIGINAL, "Unexpected release assets before publication")
    subprocess.run(["gh", "release", "upload", TAG, str(archive_path), str(directory / CHECKSUM),
                    "--repo", REPO], check=True)
    # No --clobber, deletion, tag mutation, release-note editing or automatic rollback.
    published = release()
    need(published["id"] == current["id"], "Release changed during publication")
    check_originals(published)
    need(tag_commit_api() == BUILD, "Release tag changed during publication")
    by_name = {item["name"]: item for item in published["assets"]}
    receipts = []
    for name in [BACKUP, CHECKSUM]:
        need(name in by_name, f"Published asset missing: {name}")
        local_digest = sha(directory / name)
        downloaded_digest = download_asset(by_name[name], TEMP / ("published-" + name))
        need(downloaded_digest == local_digest, f"Published asset readback mismatch: {name}")
        receipts.append({"name": name, "id": by_name[name]["id"], "bytes": by_name[name]["size"],
                         "sha256": downloaded_digest, "url": by_name[name]["browser_download_url"]})
    summary("Published backup assets, verified by downloading their exact bytes:\n\n" +
            json.dumps({"release_url": published["html_url"], "assets": receipts}, indent=2))

if __name__ == "__main__":
    need(os.environ["GITHUB_REPOSITORY"] == REPO, "Unexpected repository")
    need(re.fullmatch(r"[0-9a-f]{40}", FINAL) is not None, "FINAL_MAIN must be a full commit SHA")
    need(re.fullmatch(r"[0-9a-f]{40}", BUILD) is not None, "EXPECTED_BUILD_COMMIT must be a full commit SHA")
    need(len(sys.argv) == 2 and sys.argv[1] in {"prepare", "publish"}, "Expected prepare or publish")
    {"prepare": prepare, "publish": publish}[sys.argv[1]]()
