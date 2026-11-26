#!/usr/bin/env python3
"""Recover one pinned CI execution; publish only an explicit evidence allowlist."""
import argparse
import base64
import hashlib
import io
import itertools
import json
import math
import os
from pathlib import Path
import re
import stat
import struct
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

REPO = "darknigthmare/THE_EYES"
BRANCH = "feat/trial-workshop"
SOURCE = "6392ebf30b0acb909e218bc4c12c36e2d0b3faa0"
SOURCE_TREE = "218a1715ed6d11e1d8c4c223acb29e16a4066714"
RUN = 45903325362
ENGINE = "4.7.2.stable.official.ed1daf0bf"
REPORT = "docs/qa/V0_5_VERIFICATION.md"
PREFIX = "docs/qa/v0.5/"
VIEWS = "menu workshop practice practice_clear manual result save_error result_save_error".split()
TRIALS = "silent echoes relay vault ritual clock light strings chimes".split()
SLOTS = ["silent", "echoes", "relay"]
ARTIFACTS = {
    "gameplay-verification": (15157730616, 9780, "490de1523d9b6e8d9281c347b28747dcda205f55c9d9e01043aebe008d0c0157"),
    "native-visuals": (15157461003, 2159877, "f264597193c03d266fe5f872badd84df43a1802a0fc57caab637f6676d01389c"),
}
SUITES = [
    ("test_director.gd", "TrialDirector", "assertions"),
    ("test_world.gd", "World integration", "assertions"),
    ("test_survivor_route.gd", "", "legacy"),
    ("test_trial_set.gd", "TrialSet", "assertions"),
    ("test_second_world.gd", "Second world integration", "assertions"),
    ("test_second_survivor_route.gd", "", "legacy"),
    ("test_squad_state.gd", "SquadState", "assertions"),
    ("test_squad_world.gd", "Squad world integration", "assertions"),
    ("test_squad_route.gd", "Squad routes", "sessions"),
    ("test_third_trials.gd", "ThirdTrials", "assertions"),
    ("test_third_world.gd", "Third world integration", "assertions"),
    ("test_third_survivor_route.gd", "Third pressured routes", "sessions"),
    ("test_practice_state.gd", "PracticeState", "assertions"),
    ("test_practice_records.gd", "PracticeRecords", "assertions"),
    ("test_practice_ui.gd", "Practice interface", "assertions"),
    ("test_practice_world.gd", "Practice world integration", "assertions"),
    ("test_practice_routes.gd", "Practice ordinary-input routes", "sessions"),
]
LOG_NAMES = ["import.log"] + [name + ".log" for name, _, _ in SUITES]
VISUAL_NAMES = ["VISUAL_PROVENANCE.json"] + [v + suffix for v in VIEWS for suffix in (".png", ".log")]
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
BAD = re.compile(r"(?im)^\s*(?:(?:SCRIPT|USER)\s+)?ERROR\s*:|Parse Error:|Compile Error:|Failed to load|Failed to export project|^\s*(?:FAIL|ROUTE_FAILURE):|Traceback \(most recent call last\)|^\s*(?:Killed|Aborted|Segmentation fault)(?:\s|$)|\b[1-9][0-9]* failures\b")
TOKEN = os.environ.get("GH_TOKEN", "")


def require(ok, message):
    if not ok:
        raise RuntimeError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False, allow_nan=False) + "\n").encode("utf-8")


def git(*args, binary=False, env=None):
    result = subprocess.run(["git", *args], check=True, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, env=env)
    return result.stdout if binary else result.stdout.decode("utf-8").strip()


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, newurl):
        return None


NO_REDIRECT = urllib.request.build_opener(NoRedirect())


def api_request(path):
    return urllib.request.Request(
        "https://api.github.com/repos/" + REPO + "/" + path,
        headers={"Authorization": "Bearer " + TOKEN,
                 "Accept": "application/vnd.github+json",
                 "X-GitHub-Api-Version": "2022-11-28",
                 "User-Agent": "THE-EYES-v05-evidence-recovery"})


def api(path):
    try:
        with NO_REDIRECT.open(api_request(path), timeout=60) as response:
            body = response.read(4 * 1024 * 1024 + 1)
    except urllib.error.HTTPError as error:
        raise RuntimeError("GitHub API status " + str(error.code)) from None
    require(len(body) <= 4 * 1024 * 1024, "Oversized API response")
    return json.loads(body)


def fetch_archive(meta, expected, bundle):
    artifact_id, expected_size, expected_hash = expected
    require(meta["id"] == artifact_id and not meta["expired"], "Wrong or expired artifact")
    require(meta.get("digest") == "sha256:" + expected_hash, "API artifact digest changed")
    require(meta["size_in_bytes"] == expected_size, "API artifact size changed")
    identity = meta["workflow_run"]
    require(identity["id"] == RUN and identity["head_sha"] == SOURCE
            and identity["head_branch"] == BRANCH, "Artifact source mismatch")
    location = None
    try:
        with NO_REDIRECT.open(api_request("actions/artifacts/" + str(artifact_id) + "/zip"), timeout=60):
            raise RuntimeError("Expected an explicit signed artifact redirect")
    except urllib.error.HTTPError as error:
        require(error.code == 302, "Artifact download API did not return 302")
        location = error.headers.get("Location")
    parsed = urllib.parse.urlsplit(location or "")
    require(parsed.scheme == "https" and parsed.hostname and not parsed.username
            and not parsed.password, "Invalid signed download location")
    # A NEW request has no Authorization header. Never print its signed URL.
    request = urllib.request.Request(location, headers={"User-Agent": "THE-EYES-v05-evidence-recovery"})
    try:
        with NO_REDIRECT.open(request, timeout=120) as response:
            data = response.read(32 * 1024 * 1024 + 1)
    except (urllib.error.URLError, TimeoutError):
        raise RuntimeError("Unsigned artifact storage download failed") from None
    require(len(data) == expected_size and sha(data) == expected_hash, "Artifact ZIP digest or size mismatch")
    destination = bundle / "original-artifacts" / (meta["name"] + ".zip")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)
    return data


def unzip_exact(data, expected_names):
    result = {}
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        entries = archive.infolist()
        require(len(entries) == len(expected_names), "Unexpected artifact member count")
        require({item.filename for item in entries} == set(expected_names), "Artifact paths differ from allowlist")
        require(sum(item.file_size for item in entries) <= 64 * 1024 * 1024, "Oversized artifact contents")
        for item in entries:
            require(not item.is_dir() and not stat.S_ISLNK(item.external_attr >> 16), "Invalid artifact member type")
            require(item.filename not in result and not (item.flag_bits & 1), "Duplicate or encrypted ZIP member")
            require(item.file_size <= 16 * 1024 * 1024, "Oversized artifact member")
            result[item.filename] = archive.read(item)  # Also checks the ZIP CRC.
    return result


def clean_log(name, data):
    text = ANSI.sub("", data.decode("utf-8"))
    require("Godot Engine v" + ENGINE in text, "Missing pinned Godot header: " + name)
    require(not BAD.search(text), "Error or failed assertion in " + name)
    return text


def rows(text, marker):
    return [json.loads(value) for value in re.findall(r"(?m)^" + re.escape(marker) + r" (.+)$", text)]


def one(items, description):
    require(len(items) == 1, "Expected exactly one " + description)
    return items[0]


def legacy(text, marker):
    value = one(re.findall(r"(?m)^" + marker + r" (.+)$", text), marker)
    result = {}
    for key, item in re.findall(r"([a-z_]+)=(\{[^}]*\}|\[[^\]]*\]|[^\s]+)", value):
        require(key not in result, "Duplicate legacy route field")
        try:
            result[key] = json.loads(item)
        except json.JSONDecodeError:
            result[key] = item
    return result


def positive(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and value > 0


def won(result):
    return (result.get("winner") == "survivors" and positive(result.get("elapsed"))
            and set(result.get("seals", {})) == set(SLOTS)
            and all(value is True for value in result["seals"].values()))


def replace_section(text, titles, title, body):
    matches = list(re.finditer(r"(?m)^## (?:" + "|".join(re.escape(t) for t in titles) + r")[ \t]*\n", text))
    match = one(matches, "report section " + title)
    following = re.search(r"(?m)^## ", text[match.end():])
    end = match.end() + following.start() if following else len(text)
    return text[:match.start()] + "## " + title + "\n\n" + body.rstrip() + "\n\n" + text[end:]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--workflow-run", required=True, type=int)
    parser.add_argument("--expected-head", required=True)
    parser.add_argument("--bundle-dir", required=True)
    parser.add_argument("--publish", action="store_true")
    args = parser.parse_args()
    require((args.source_commit, args.workflow_run, args.expected_head) == (SOURCE, RUN, SOURCE), "This collector is pinned to one source/run/target parent")
    require(bool(TOKEN), "GH_TOKEN is required")
    require(git("rev-parse", "HEAD") == args.expected_head, "Checkout is not the exact expected target parent")
    require(not git("status", "--porcelain", "--untracked-files=all"), "Target checkout is dirty")
    require(git("rev-parse", SOURCE + "^{tree}") == SOURCE_TREE, "Source tree mismatch")
    require(remote_head() == args.expected_head, "Target branch moved before collection")
    bundle = Path(args.bundle_dir).resolve()
    require(not bundle.is_relative_to(Path.cwd().resolve()), "Bundle must be outside target checkout")
    bundle.mkdir(parents=True, exist_ok=True)
    source_entries = [entry for entry in git("ls-tree", "-rz", SOURCE, binary=True).split(b"\0") if entry]
    require(len(source_entries) == 204, "Full source file count changed")
    source_manifest = []
    entries = git("ls-tree", "-rz", SOURCE, "--", "game", "tools", ".github/workflows", binary=True)
    for entry in entries.split(b"\0"):
        if not entry:
            continue
        header, raw_path = entry.split(b"\t", 1)
        mode, kind, blob = header.decode("ascii").split()
        path = raw_path.decode("utf-8")
        require(kind == "blob" and mode in ("100644", "100755"), "Unexpected protected source entry")
        data = git("cat-file", "blob", blob, binary=True)
        require(Path(path).is_file() and not Path(path).is_symlink() and Path(path).read_bytes() == data, "Protected checkout differs: " + path)
        source_manifest.append({"path": path, "git_blob_sha": blob, "git_mode": mode, "bytes": len(data), "sha256": sha(data)})
    require(len(source_manifest) == 117, "Protected source manifest must contain 117 files")

    deadline = time.monotonic() + 600
    while True:
        run = api("actions/runs/" + str(RUN))
        require(run["head_sha"] == SOURCE and run["head_branch"] == BRANCH
                and run["event"] == "push" and run["path"] == ".github/workflows/verify.yml"
                and run["run_attempt"] == 1 and run["head_repository"]["full_name"] == REPO, "Source workflow identity mismatch")
        if run["status"] == "completed":
            break
        require(time.monotonic() < deadline, "Source CI is not complete; rerun this collector after completion")
        print("Waiting for the pinned source CI to finish", flush=True)
        time.sleep(15)
    require(run["conclusion"] == "success", "Source CI did not succeed")
    jobs = api("actions/runs/" + str(RUN) + "/attempts/1/jobs?per_page=100")
    require(jobs["total_count"] == len(jobs["jobs"]), "Jobs pagination is incomplete")
    job = one([item for item in jobs["jobs"] if item["name"] == "godot"], "Godot job")
    require(job["status"] == "completed" and job["conclusion"] == "success", "Godot job did not succeed")
    gates = ["Install the verified Godot version", "Import and verify all seventeen gameplay suites",
             "Render the Workshop presentation fixtures", "Retain native presentation evidence", "Retain verification logs"]
    for name in gates:
        step = one([item for item in job["steps"] if item["name"] == name], name)
        require(step["status"] == "completed" and step["conclusion"] == "success", "Required source gate failed: " + name)
    listing = api("actions/runs/" + str(RUN) + "/artifacts?per_page=100")
    require(listing["total_count"] == len(listing["artifacts"]) == 2, "Expected exactly two source artifacts")
    downloaded, artifact_evidence = {}, []
    for kind, expected in ARTIFACTS.items():
        name = kind + "-" + SOURCE + "-1"
        meta = one([item for item in listing["artifacts"] if item["name"] == name], name)
        archive = fetch_archive(meta, expected, bundle)
        downloaded[kind] = unzip_exact(archive, LOG_NAMES if kind == "gameplay-verification" else VISUAL_NAMES)
        artifact_evidence.append({"id": meta["id"], "name": name, "size_in_bytes": len(archive),
                                  "api_digest": meta["digest"], "download_sha256": sha(archive)})
    raw_logs = downloaded["gameplay-verification"]
    texts = {name: clean_log(name, data) for name, data in raw_logs.items()}
    suite_results = []
    session_counts = {"test_survivor_route.gd": 1, "test_second_survivor_route.gd": 1,
                      "test_squad_route.gd": 3, "test_third_survivor_route.gd": 2, "test_practice_routes.gd": 9}
    for name, label, category in SUITES:
        entry = {"suite": name, "category": category, "cases": None, "assertions": None,
                 "sessions": None, "failures": 0, "log": PREFIX + "logs/gameplay/" + name + ".log"}
        if category == "assertions":
            match = one(re.findall(r"(?m)^" + re.escape(label) + r": (\d+) cases, (\d+) assertions, (\d+) failures[ \t]*$", texts[name + ".log"]), label + " summary")
            entry["cases"], entry["assertions"], entry["failures"] = map(int, match)
            require(entry["cases"] > 0 and entry["assertions"] > 0 and entry["failures"] == 0, "Invalid assertion summary: " + name)
        elif category == "sessions":
            match = one(re.findall(r"(?m)^" + re.escape(label) + r": (\d+) sessions, (\d+) failures[ \t]*$", texts[name + ".log"]), label + " summary")
            entry["sessions"], entry["failures"] = map(int, match)
            require(entry["sessions"] == session_counts[name] and entry["failures"] == 0, "Invalid session summary: " + name)
        else:
            entry["sessions"] = 1
            entry["summary_basis"] = "Single validated success marker and successful source CI gate; no standalone case/assertion summary"
        suite_results.append(entry)
    cases = sum(item["cases"] or 0 for item in suite_results)
    assertions = sum(item["assertions"] or 0 for item in suite_results)
    require((len(suite_results), cases, assertions) == (17, 257, 6079), "Actual suite totals differ from this pinned revision")

    pressured = []
    for name, marker, contract in [("test_survivor_route.gd", "SURVIVOR_ROUTE_RESULT", "first"),
                                   ("test_second_survivor_route.gd", "SECOND_SURVIVOR_RESULT", "second")]:
        result = legacy(texts[name + ".log"], marker)
        require(won(result) and result.get("phase") == "ended" and positive(result.get("vitality")), "Legacy pressured route did not win")
        if contract == "first":
            require(result.get("deliveries") == 3, "First route delivery evidence missing")
        else:
            require(isinstance(result.get("cradles"), list) and len(result["cradles"]) == 4
                    and all(isinstance(value, int) and value >= 0 for value in result["cradles"])
                    and positive(result.get("clock_moves")), "Second route puzzle evidence missing")
        call = r'game\.start_match\(\s*"survivor"\s*,\s*"Keeper"\s*,\s*"story"\s*,\s*271126'
        call += r'\s*,\s*"second"' if contract == "second" else ""
        call += r'\s*\)'
        require(re.search(call, git("show", SOURCE + ":game/tests/" + name)), "Legacy configuration changed")
        pressured.append({"suite": name, "configuration_from_source": {"role": "survivor", "contract": contract,
                          "archetype": "Keeper", "difficulty": "story", "seed": 271126}, "observed": result})
    squad = rows(texts["test_squad_route.gd.log"], "SQUAD_ROUTE_RESULT")
    require(len(squad) == 3 and {item["contract"] for item in squad} == {"first", "second", "mix"}, "Squad contract coverage differs")
    for result in squad:
        require(won(result) and result.get("failures") == [] and result.get("seed") == 271126
                and result.get("difficulty") == "story" and result["squad"]["orders"] >= 3
                and result["human_distance"] >= 5 and positive(result["human_health"]), "Invalid pressured Squad result")
        pressured.append({"suite": "test_squad_route.gd", "configuration_from_source": {"role": "squad"}, "observed": result})
    third = rows(texts["test_third_survivor_route.gd.log"], "THIRD_SURVIVOR_RESULT")
    require(len(third) == 2 and {item["role"] for item in third} == {"survivor", "squad"}, "Third role coverage differs")
    for result in third:
        require(won(result) and result.get("failures") == [] and result.get("contract") == "third"
                and result.get("seed") == 271126 and result.get("difficulty") == "story"
                and result["human_distance"] >= 20 and result["lamps"] == [True, True, True]
                and result["cage_stages"] == 3 and result["bell_phrases"] == 2, "Invalid Third pressured result")
        own = result["human_trial_events"]
        require((own["light_deposit"] == 3 and own["strings_cut"] == 3 and own["chime_strike"] >= 8)
                if result["role"] == "survivor" else own["chime_strike"] > 0, "Third human contribution missing")
        pressured.append({"suite": "test_third_survivor_route.gd", "observed": result})
    practice = rows(texts["test_practice_routes.gd.log"], "PRACTICE_ROUTE_RESULT")
    require(len(practice) == 9 and {item["trial_id"] for item in practice} == set(TRIALS), "Practice trial coverage differs")
    for result in practice:
        slot = SLOTS[TRIALS.index(result["trial_id"]) % 3]
        require(result.get("success") is True and result.get("failures") == []
                and result["archetype"] == "Keeper" and result["seed"] == 271126
                and positive(result["elapsed"]) and result["distance"] > 1 and result["health"] == 100
                and result["completion_events"] == 1 and result["match_results"] == 0
                and result["seals"] == {key: key == slot for key in SLOTS}, "Invalid practice completion")
    bots = rows(texts["test_second_world.gd.log"], "SECOND_BOT_ROUTE")
    require(len(bots) == 28 and all(won(item) and item["wounds"] == 0 for item in bots), "Invalid unopposed bot routes")
    mixes = [item for item in bots if item["contract"] == "mix"]
    reference = [item for item in bots if item["contract"] == "second"]
    expected_mixes = {"/".join(items) for items in itertools.product(["silent", "vault", "light"], ["echoes", "ritual", "strings"], ["relay", "clock", "chimes"])}
    require(len(mixes) == 27 and {item["mapping"] for item in mixes} == expected_mixes
            and len(reference) == 1 and reference[0]["mapping"] == "vault/ritual/clock", "Bot mapping coverage differs")
    require(one(rows(texts["test_second_world.gd.log"], "SECOND_WORLD_ROUTES"), "bot aggregate") == bots, "Bot aggregate differs from individual route markers")
    require(len(pressured) == 7, "Expected seven pressured sessions")

    visual = downloaded["native-visuals"]
    provenance = json.loads(visual["VISUAL_PROVENANCE.json"])
    require(provenance.get("schema_version") == 1 and provenance.get("source_commit") == SOURCE
            and str(provenance.get("workflow_run")) == str(RUN) and provenance.get("engine") == "4.7.2"
            and provenance.get("renderer") == "native OpenGL compatibility, software Mesa, Xvfb"
            and provenance.get("staged_fixtures") is True and provenance.get("playthrough_evidence") is False
            and provenance.get("hardware_performance_evidence") is False, "Visual provenance mismatch")
    image_entries = provenance["images"]
    require(len(image_entries) == 8 and {item["view"] for item in image_entries} == set(VIEWS), "Visual coverage differs")
    images = []
    for view in VIEWS:
        entry = one([item for item in image_entries if item["view"] == view], view)
        data = visual[view + ".png"]
        require(entry["path"] == view + ".png" and entry["sha256"] == sha(data), "PNG provenance hash mismatch")
        require(len(data) >= 33 and data[:8] == b"\x89PNG\r\n\x1a\n" and data[12:16] == b"IHDR", "Invalid PNG header")
        width, height = struct.unpack(">II", data[16:24])
        require(1 <= width <= 8192 and 1 <= height <= 8192, "Invalid PNG dimensions")
        capture = clean_log(view + ".log", visual[view + ".log"])
        one(re.findall(r"(?m)^THE_EYES_VISUAL_FIXTURE view=" + re.escape(view) + r" [^\r\n]*$", capture), view + " fixture marker")
        one(re.findall(r"(?m)^QA_CAPTURE [^\r\n]*/" + re.escape(view) + r"\.png result=0[ \t]*$", capture), view + " capture success")
        images.append({"view": view, "path": PREFIX + view + ".png", "sha256": sha(data), "bytes": len(data), "width": width, "height": height})


    totals = {"suites": len(suite_results), "assertion_suites": sum(item["category"] == "assertions" for item in suite_results),
              "route_suites": sum(item["category"] != "assertions" for item in suite_results),
              "cases": cases, "assertions": assertions, "failures": sum(item["failures"] for item in suite_results),
              "pressured_sessions": len(pressured), "practice_sessions": len(practice),
              "unopposed_bot_routes": len(bots), "distinct_mix_mappings": len(expected_mixes)}
    notes = [
        "This is an exact GitHub Actions CI execution, not evidence of a successful local import or local test run.",
        "The 257 named cases and 6079 assertions come from twelve suite summaries. Some cases deliberately stage edge conditions; these are not 257 complete matches.",
        "Seven pressured sessions and nine practice sessions use ordinary inputs and real physics. Their elapsed values are simulation observations, not wall-clock benchmarks or novice target times.",
        "The 28 unopposed bot routes are already included in Second world integration cases/assertions: one Second reference and all 27 distinct Mix mappings. They are not additional pressured human sessions.",
        "The source CI helper checks process exit status and engine errors. Individual artifact logs do not separately record return codes or wall times; none are fabricated here.",
        "Legacy route configuration is attributed to the pinned GDScript source, separately from the fields printed by the route marker.",
        "Native images are staged presentation fixtures. Human visual review, Windows graphical playthroughs, hardware performance, novice usability and Unreal execution are separate gates.",
    ]
    run_identity = {key: run.get(key) for key in ("id", "html_url", "head_sha", "head_branch", "event", "path", "run_attempt", "status", "conclusion", "created_at", "updated_at")}
    log_manifest = [{"path": PREFIX + "logs/gameplay/" + name, "artifact_member": name,
                     "bytes": len(raw_logs[name]), "sha256": sha(raw_logs[name])} for name in LOG_NAMES]
    results = {"schema_version": 2, "release": "0.5.0", "evidence_kind": "github_actions_ci",
               "source_commit": SOURCE, "source_tree": SOURCE_TREE, "workflow_run": RUN,
               "workflow_run_url": run["html_url"], "job_id": job["id"], "engine": ENGINE,
               "execution": {"runner": "ubuntu-latest", "headless_gameplay": True, "fixed_fps": 60, "audio_driver": "Dummy"},
               "totals": totals, "suites": suite_results, "pressured_sessions": pressured,
               "practice_sessions": practice, "unopposed_bot_routes": bots,
               "distinct_mix_mappings": sorted(expected_mixes), "logs": log_manifest,
               "artifacts": artifact_evidence, "source_file_count": 204,
               "source_manifest_scope": ["game/", "tools/", ".github/workflows/"],
               "source_manifest_count": len(source_manifest), "source_manifest": source_manifest, "notes": notes}
    output = {PREFIX + "GAMEPLAY_RESULTS.json": encoded(results)}
    combined = [b"THE EYES v0.5.0 - exact GitHub Actions gameplay evidence\n",
                ("Source: " + SOURCE + "\nRun: " + run["html_url"] + "\n").encode(),
                b"Original artifact member bytes follow between boundaries; individual originals are also retained.\n"]
    for name in LOG_NAMES:
        combined.append(("\n===== BEGIN " + name + " sha256=" + sha(raw_logs[name]) + " bytes=" + str(len(raw_logs[name])) + " =====\n").encode())
        combined.append(raw_logs[name])
        combined.append(("\n===== END " + name + " =====\n").encode())
        output[PREFIX + "logs/gameplay/" + name] = raw_logs[name]
    output[PREFIX + "GAMEPLAY_LOG.txt"] = b"".join(combined)
    output[PREFIX + "VISUAL_PROVENANCE.json"] = visual["VISUAL_PROVENANCE.json"]
    for view in VIEWS:
        output[PREFIX + view + ".png"] = visual[view + ".png"]
        output[PREFIX + "logs/visual/" + view + ".log"] = visual[view + ".log"]

    body = ["Source commit: `" + SOURCE + "`. [Verified CI run](" + run["html_url"] + "), attempt 1; Godot job `" + str(job["id"]) + "`.",
            "", "The completed CI execution passed **17 suites, 257 cases, 6079 assertions and zero failures**. The import and gameplay gate, native fixture gate and both artifact uploads all completed successfully.",
            "", "This evidence comes from that exact CI execution. It does not establish a successful local import or local test run.",
            "", "| Suite | Cases | Assertions | Complete sessions | Failures |", "|---|---:|---:|---:|---:|"]
    for item in suite_results:
        cells = [str(item[key]) if item[key] is not None else "—" for key in ("cases", "assertions", "sessions", "failures")]
        body.append("| `" + item["suite"] + "` | " + " | ".join(cells) + " |")
    body += ["", "### Pressured session observations", "", "| Role | Contract | Seed | Elapsed simulation seconds |", "|---|---|---:|---:|"]
    for item in pressured:
        observed, configured = item["observed"], item.get("configuration_from_source", {})
        role = observed.get("role", configured.get("role"))
        contract = observed.get("contract", configured.get("contract"))
        seed = observed.get("seed", configured.get("seed"))
        body.append(f"| {role} | {contract} | {seed} | {observed['elapsed']:.2f} |")
    body += ["", "### Practice session observations", "", "| Trial | Archetype | Seed | Elapsed simulation seconds |", "|---|---|---:|---:|"]
    for item in practice:
        body.append(f"| {item['trial_id']} | {item['archetype']} | {item['seed']} | {item['elapsed']:.2f} |")
    body += ["", "### Scope and retained evidence", ""] + ["- " + note for note in notes[1:6]]
    body += ["", "[Machine-readable results and the 117-file source manifest](v0.5/GAMEPLAY_RESULTS.json), [combined verbatim gameplay logs](v0.5/GAMEPLAY_LOG.txt), [18 individual gameplay logs](v0.5/logs/gameplay/), and [recovery provenance](v0.5/RECOVERY_PROVENANCE.json) retain the underlying evidence."]
    report = Path(REPORT).read_text(encoding="utf-8")
    report = replace_section(report, ["Local gameplay evidence", "Gameplay evidence"], "Gameplay evidence", "\n".join(body))
    presentation = ["Eight native staged fixtures were rendered from the same exact source and run using Godot 4.7.2, OpenGL compatibility, software Mesa and Xvfb.",
                    "", "The recovery verifies artifact digests, the source manifest, every PNG hash/header, and all eight capture success markers. **Human visual review remains pending.** These fixtures do not establish a complete graphical playthrough or hardware performance.",
                    "", "| Fixture | PNG | Dimensions |", "|---|---|---:|"]
    for item in images:
        presentation.append(f"| {item['view']} | [{item['view']}.png](v0.5/{item['view']}.png) | {item['width']} × {item['height']} |")
    presentation += ["", "[Original visual provenance](v0.5/VISUAL_PROVENANCE.json), [individual capture logs](v0.5/logs/visual/), and [recovery provenance](v0.5/RECOVERY_PROVENANCE.json) preserve the source and hashes. This section records automated capture validation; visual inspection can be recorded in a later documentation commit."]
    report = replace_section(report, ["Native presentation inspection"], "Native presentation inspection", "\n".join(presentation))
    output[REPORT] = report.encode("utf-8")
    allowed = {REPORT, PREFIX + "GAMEPLAY_RESULTS.json", PREFIX + "GAMEPLAY_LOG.txt",
               PREFIX + "VISUAL_PROVENANCE.json", PREFIX + "RECOVERY_PROVENANCE.json"}
    allowed.update(PREFIX + "logs/gameplay/" + name for name in LOG_NAMES)
    allowed.update(PREFIX + view + ".png" for view in VIEWS)
    allowed.update(PREFIX + "logs/visual/" + view + ".log" for view in VIEWS)
    recovery = {"schema_version": 1, "source_commit": SOURCE, "source_tree": SOURCE_TREE,
                "source_workflow": run_identity, "source_job": {key: job.get(key) for key in ("id", "name", "status", "conclusion", "started_at", "completed_at", "steps")},
                "collector_commit": os.environ.get("GITHUB_SHA"), "collector_workflow_run": os.environ.get("GITHUB_RUN_ID"),
                "expected_target_parent": args.expected_head, "target_branch": BRANCH,
                "collected_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "artifacts": artifact_evidence, "totals": totals, "native_images": images,
                "human_visual_review_completed": False, "allowed_commit_paths": sorted(allowed),
                "file_manifest_scope": "Files exactly as produced by this recovery; excludes this provenance JSON to avoid a self hash",
                "recovery_output_files": [{"path": path, "bytes": len(data), "sha256": sha(data)} for path, data in sorted(output.items())]}
    output[PREFIX + "RECOVERY_PROVENANCE.json"] = encoded(recovery)
    require(set(output) == allowed and len(allowed) == 39, "Output allowlist mismatch")
    for path, data in sorted(output.items()):
        target = Path(path)
        require(not target.is_symlink() and target.resolve().is_relative_to(Path.cwd().resolve()), "Unsafe output path")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        target.chmod(0o644)
        retained = bundle / "evidence" / path
        retained.parent.mkdir(parents=True, exist_ok=True)
        retained.write_bytes(data)
    git("archive", "--format=zip", "--prefix=THE_EYES-tested-source/",
        "--output=" + str(bundle / "THE_EYES_v0.5_tested_source.zip"), SOURCE)
    (bundle / "SOURCE_MANIFEST.json").write_bytes(encoded({"source_commit": SOURCE, "source_tree": SOURCE_TREE, "files": source_manifest}))
    status = {"source_commit": SOURCE, "source_workflow_run": RUN, "expected_target_parent": args.expected_head,
              "target_branch": BRANCH, "published": False, "candidate_commit": None, "totals": totals}
    try:
        if args.publish:
            # Forced add is required because the repository ignores *.log.
            git("add", "-f", "--", *sorted(allowed))
            changed = {part.decode("utf-8") for part in git("diff", "--cached", "--name-only", "-z", binary=True).split(b"\0") if part}
            require(bool(changed) and changed <= allowed, "Staged files escape the exact evidence allowlist")
            require(REPORT in changed and PREFIX + "GAMEPLAY_RESULTS.json" in changed, "Missing evidence changes")
            require(all(line.startswith(("A\t", "M\t")) for line in git("diff", "--cached", "--name-status", "--no-renames").splitlines()), "Unexpected staged deletion or rename")
            git("-c", "user.name=github-actions[bot]", "-c", "user.email=41898282+github-actions[bot]@users.noreply.github.com",
                "-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "commit", "-m", "docs(qa): recover exact v0.5 CI evidence")
            candidate = git("rev-parse", "HEAD")
            status["candidate_commit"] = candidate
            require(git("show", "-s", "--format=%P", candidate) == args.expected_head, "Candidate does not have the exact expected single parent")
            committed = {part.decode("utf-8") for part in git("diff-tree", "--no-commit-id", "--name-only", "-r", "-z", candidate, binary=True).split(b"\0") if part}
            require(committed == changed and committed <= allowed, "Committed paths escape the allowlist")
            require(not git("diff", args.expected_head, candidate, "--", "game", "tools", ".github/workflows"), "Protected source changed")
            require(not git("status", "--porcelain", "--untracked-files=all"), "Unexpected working tree changes remain")
            git("archive", "--format=zip", "--prefix=THE_EYES_v0.5/",
                "--output=" + str(bundle / "THE_EYES_v0.5_source_and_evidence.zip"), candidate)
            require(remote_head() == args.expected_head, "Target branch advanced; no automatic rebase or retry")
            git("push", "--force-with-lease=refs/heads/" + BRANCH + ":" + args.expected_head,
                "https://github.com/" + REPO + ".git", "HEAD:refs/heads/" + BRANCH, env=git_auth_env())
            status["published"] = True
        print(json.dumps(status, sort_keys=True), flush=True)
        summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
        if summary_path:
            with open(summary_path, "a", encoding="utf-8") as summary:
                summary.write("## THE EYES evidence recovery\n\n17 suites; 257 cases; 6079 assertions; zero failures.\n\n7 pressured sessions; 9 practice sessions; 28 unopposed bot routes; 27 distinct Mix mappings; 8 staged native images.\n\nPublished: " + str(status["published"]) + ". Candidate commit: `" + str(status["candidate_commit"]) + "`.\n")
    except Exception as error:
        status["error"] = type(error).__name__ + ": " + str(error)
        raise
    finally:
        (bundle / "RECOVERY_STATUS.json").write_bytes(encoded(status))
        checksums = []
        for path in sorted(bundle.rglob("*")):
            if path.is_file() and path.name != "SHA256SUMS":
                checksums.append(sha(path.read_bytes()) + "  " + path.relative_to(bundle).as_posix())
        (bundle / "SHA256SUMS").write_text("\n".join(checksums) + "\n", encoding="utf-8")


def git_auth_env():
    environment = os.environ.copy()
    credential = base64.b64encode(("x-access-token:" + TOKEN).encode()).decode("ascii")
    environment.update({"GIT_CONFIG_COUNT": "1", "GIT_CONFIG_KEY_0": "http.https://github.com/.extraheader",
                        "GIT_CONFIG_VALUE_0": "AUTHORIZATION: basic " + credential,
                        "GIT_TERMINAL_PROMPT": "0"})
    return environment


def remote_head():
    line = git("ls-remote", "--exit-code", "https://github.com/" + REPO + ".git", "refs/heads/" + BRANCH, env=git_auth_env())
    fields = line.split()
    require(len(fields) == 2 and fields[1] == "refs/heads/" + BRANCH, "Could not resolve exact target branch")
    return fields[0]


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("EVIDENCE_RECOVERY_ERROR: " + type(error).__name__ + ": " + str(error), flush=True)
        raise SystemExit(1)
