extends SceneTree
## Real file-backed notebook tests; every file stays inside a unique QA folder.

const Records = preload("res://scripts/practice_records.gd")
const Practice = preload("res://scripts/practice_state.gd")

class FailedWindowsMove:
	extends Records
	var fail_next_move: bool = false
	var fail_restore: bool = false

	func _replace_file(source: String, destination: String) -> Error:
		if source.ends_with(".restore.tmp") and fail_restore:
			return ERR_FILE_CANT_WRITE
		if fail_next_move:
			fail_next_move = false
			if FileAccess.file_exists(destination):
				DirAccess.remove_absolute(destination)
			return ERR_FILE_CANT_WRITE
		return super._replace_file(source, destination)

var cases: int = 0
var assertions: int = 0
var failures: int = 0
var _base: String = ""


func _initialize() -> void:
	_base = "user://qa_practice_records_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(_base) == OK, "create isolated notebook QA folder")
	_test_empty_notebook()
	_test_invalid_commands()
	_test_single_attempt_lifecycle()
	_test_exactly_once_and_zero_time()
	_test_archetype_bests()
	_test_round_trip_and_attempt_recovery()
	_test_snapshot_isolation()
	_test_sanitized_known_schema()
	_test_counter_limit()
	_test_invalid_documents_preserved()
	_test_future_schema_preserved()
	_test_external_schema_change()
	_test_atomic_replacement_failure()
	_test_windows_failed_move_restores_primary()
	_test_windows_failed_restore_keeps_backup()
	_test_missing_primary_recovers_backup()
	_test_backup_does_not_hide_invalid_primary()
	_test_invalid_or_future_backup_preserved()
	_test_future_backup_with_valid_primary()
	_test_match_result_separation()
	_test_path_and_size_limits()
	_cleanup(_base)
	print("PracticeRecords: %d cases, %d assertions, %d failures" % [cases, assertions, failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)


func _path(name: String) -> String:
	return _base.path_join(name + ".json")


func _new(name: String) -> Records:
	var notebook: Records = Records.new(_path(name))
	_check(notebook.load_records(), "load fresh notebook " + name)
	return notebook


func _write(path: String, content: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "open QA fixture " + path.get_file())
	if file != null:
		file.store_string(content)
		file.flush()
		file.close()


func _read(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content: String = file.get_as_text()
	file.close()
	return content


func _role(notebook: Records, trial_id: String, archetype: String) -> Dictionary:
	return notebook.snapshot().trials[trial_id].by_archetype[archetype]


func _finish(notebook: Records, trial_id: String, archetype: String, seed_value: int, seconds: float) -> void:
	_check(notebook.begin_attempt(trial_id, archetype, seed_value), "begin notebook attempt " + trial_id + "/" + archetype)
	_check(notebook.complete_attempt(seconds), "complete notebook attempt " + trial_id + "/" + archetype)


func _test_empty_notebook() -> void:
	cases += 1
	var notebook: Records = _new("empty")
	var data: Dictionary = notebook.snapshot()
	_check(int(data.schema_version) == 1 and data.size() == 2, "notebook has only version and trial summaries")
	_check(data.trials.size() == 9 and not notebook.read_only and notebook.last_error.is_empty(), "fresh notebook contains nine writable summaries")
	for id: String in Practice.TRIAL_IDS:
		var trial: Dictionary = data.trials[id]
		_check(trial.size() == 3 and int(trial.attempts) == 0 and int(trial.completions) == 0, "empty trial summary " + id)
		_check(trial.by_archetype.size() == 4, "exactly four survivor records " + id)
		for archetype: String in Records.ARCHETYPES:
			_check(trial.by_archetype[archetype] == {"attempts": 0, "completions": 0, "last_seed": 0, "last_seconds": 0.0, "best_seconds": 0.0, "best_seed": 0}, "empty fixed record " + id + "/" + archetype)
	_check(not FileAccess.file_exists(_path("empty")), "reading missing notebook does not write a file")


func _test_invalid_commands() -> void:
	cases += 1
	var notebook: Records = _new("invalid_commands")
	var before: Dictionary = notebook.snapshot()
	_check(not notebook.begin_attempt("unknown", "Veil", 1701), "unknown trial rejected")
	_check(not notebook.begin_attempt("silent", "unknown", 1701), "unknown archetype rejected")
	_check(not notebook.begin_attempt("silent", "veil", 1701), "archetype identity is explicit")
	for seed_value: int in [-1, 0, 1000000]:
		_check(not notebook.begin_attempt("silent", "Veil", seed_value), "invalid seed rejected")
	_check(not notebook.complete_attempt(2.0), "completion without begin rejected")
	_check(notebook.snapshot() == before, "invalid commands do not create records")
	_check(notebook.begin_attempt("silent", "Veil", 1), "valid seed begins attempt")
	var started: Dictionary = notebook.snapshot()
	for seconds: float in [-1.0, INF, NAN, Records.MAX_SECONDS + 1.0]:
		_check(not notebook.complete_attempt(seconds), "invalid duration rejected")
	_check(notebook.snapshot() == started, "invalid duration does not alter attempts or completions")
	_check(notebook.complete_attempt(5.0), "invalid duration leaves attempt available for a valid completion")


func _test_single_attempt_lifecycle() -> void:
	cases += 1
	var notebook: Records = _new("lifecycle")
	_check(notebook.begin_attempt("vault", "Runner", 1701), "first attempt starts")
	_check(not notebook.begin_attempt("light", "Keeper", 1702), "second concurrent attempt rejected")
	_check(int(notebook.snapshot().trials.light.attempts) == 0, "rejected concurrent attempt is not counted")
	notebook.abandon_attempt()
	_check(not notebook.complete_attempt(10.0), "abandoned attempt cannot complete")
	var abandoned: Dictionary = _role(notebook, "vault", "Runner")
	_check(int(abandoned.attempts) == 1 and int(abandoned.completions) == 0 and int(abandoned.last_seed) == 1701, "abandon preserves attempted seed and count")
	_finish(notebook, "vault", "Runner", 1702, 12.5)
	_check(notebook.begin_attempt("vault", "Runner", 1703), "retry begins after completion")
	notebook.abandon_attempt()
	var retried: Dictionary = _role(notebook, "vault", "Runner")
	_check(int(retried.attempts) == 3 and int(retried.completions) == 1, "only successful retry increments completions")
	_check(int(retried.last_seed) == 1703 and float(retried.last_seconds) == 0.0, "last fields describe latest attempt, including abandonment")
	_check(int(retried.best_seed) == 1702 and float(retried.best_seconds) == 12.5, "abandon keeps previous best completion")


func _test_exactly_once_and_zero_time() -> void:
	cases += 1
	var notebook: Records = _new("once")
	_finish(notebook, "echoes", "Veil", 1701, 0.0)
	var before: Dictionary = notebook.snapshot()
	_check(not notebook.complete_attempt(0.0) and notebook.snapshot() == before, "duplicate completion cannot inflate counters")
	_finish(notebook, "echoes", "Veil", 1702, 4.0)
	var record: Dictionary = _role(notebook, "echoes", "Veil")
	_check(int(record.completions) == 2 and int(record.best_seed) == 1701 and float(record.best_seconds) == 0.0, "zero-duration completion remains a valid best")
	_finish(notebook, "echoes", "Veil", 1703, 0.0)
	_check(int(_role(notebook, "echoes", "Veil").best_seed) == 1701, "equal best time keeps original best seed")


func _test_archetype_bests() -> void:
	cases += 1
	var notebook: Records = _new("roles")
	_finish(notebook, "relay", "Veil", 1701, 20.0)
	_finish(notebook, "relay", "Tinker", 1702, 8.0)
	_finish(notebook, "relay", "Veil", 1703, 15.0)
	_finish(notebook, "relay", "Tinker", 1704, 9.0)
	_finish(notebook, "relay", "Runner", 1705, 19.0)
	_finish(notebook, "relay", "Keeper", 1706, 21.0)
	var trial: Dictionary = notebook.snapshot().trials.relay
	_check(int(trial.attempts) == 6 and int(trial.completions) == 6, "trial totals sum all archetype summaries")
	_check(float(trial.by_archetype.Veil.best_seconds) == 15.0 and int(trial.by_archetype.Veil.best_seed) == 1703, "Veil improves only Veil's best")
	_check(float(trial.by_archetype.Tinker.best_seconds) == 8.0 and int(trial.by_archetype.Tinker.best_seed) == 1702, "slower Tinker attempt keeps earlier Tinker best")
	_check(float(trial.by_archetype.Runner.best_seconds) == 19.0 and float(trial.by_archetype.Keeper.best_seconds) == 21.0, "Runner and Keeper have independent bests")
	_check(not trial.has("best_seconds") and not trial.has("best_seed"), "there is no misleading shared archetype leaderboard")


func _test_round_trip_and_attempt_recovery() -> void:
	cases += 1
	var notebook: Records = _new("round_trip")
	_check(notebook.begin_attempt("chimes", "Keeper", 999999), "begin persisted unfinished attempt")
	_check(notebook.save_records(), "save counts after begin")
	var reloaded: Records = Records.new(_path("round_trip"))
	_check(reloaded.load_records(), "reload saved attempts")
	_check(int(_role(reloaded, "chimes", "Keeper").attempts) == 1, "attempt count survives relaunch")
	_check(not reloaded.complete_attempt(1.0), "active attempt handle never survives relaunch")
	_finish(reloaded, "chimes", "Keeper", 1701, 19.75)
	_check(reloaded.save_records(), "replace notebook after completion")
	var again: Records = Records.new(_path("round_trip"))
	_check(again.load_records() and again.snapshot() == reloaded.snapshot(), "save and load preserve all bounded records")
	_check(not FileAccess.file_exists(_path("round_trip") + ".tmp"), "successful replacement leaves no temporary file")
	var parsed: Dictionary = JSON.parse_string(_read(_path("round_trip")))
	_check(not parsed.has("active_attempt") and parsed.size() == 2, "persistent document contains no active session or event history")


func _test_snapshot_isolation() -> void:
	cases += 1
	var notebook: Records = _new("snapshot")
	_finish(notebook, "light", "Runner", 1701, 30.0)
	var data: Dictionary = notebook.snapshot()
	data.trials.light.by_archetype.Runner.completions = 999
	data.trials.erase("silent")
	_check(int(_role(notebook, "light", "Runner").completions) == 1 and notebook.snapshot().trials.size() == 9, "nested snapshot edits cannot mutate notebook")


func _test_sanitized_known_schema() -> void:
	cases += 1
	var fixture: Dictionary = {
		"schema_version": 1, "history": ["ignored"],
		"trials": {
			"unknown": {"attempts": 999},
			"relay": {"attempts": 99999, "completions": 99999, "by_archetype": {
				"Veil": {"attempts": 6.9, "completions": 99, "last_seed": 1701, "last_seconds": 15.5, "best_seconds": 12.0, "best_seed": 1702, "history": [1, 2, 3]},
				"Tinker": {"attempts": -5, "completions": 20, "last_seed": -1, "last_seconds": -4, "best_seconds": -10, "best_seed": 99},
				"Runner": {"attempts": "100", "completions": true, "last_seed": 1.5, "last_seconds": "fast", "best_seconds": 7.0, "best_seed": 1000000},
				"Keeper": {"attempts": 2, "completions": 1, "last_seed": 1703, "last_seconds": 1e30, "best_seconds": 1e30, "best_seed": 1703},
				"Intruder": {"attempts": 99},
			}},
			"silent": "invalid",
			"echoes": {"by_archetype": ["invalid"]},
		},
	}
	_write(_path("sanitized"), JSON.stringify(fixture))
	var notebook: Records = Records.new(_path("sanitized"))
	_check(notebook.load_records() and not notebook.read_only, "known schema with malformed fields loads bounded values")
	var data: Dictionary = notebook.snapshot()
	_check(data.size() == 2 and data.trials.size() == 9, "unknown roots and trial IDs are discarded")
	var trial: Dictionary = data.trials.relay
	_check(trial.size() == 3 and trial.by_archetype.size() == 4, "only approved summary fields and four archetypes persist")
	_check(int(trial.attempts) == 8 and int(trial.completions) == 7, "trial totals are recomputed from bounded role counts")
	_check(int(trial.by_archetype.Veil.attempts) == 6 and int(trial.by_archetype.Veil.completions) == 6, "fractions are floored and completions cannot exceed attempts")
	_check(trial.by_archetype.Veil.size() == 6 and float(trial.by_archetype.Veil.best_seconds) == 12.0, "valid best preserved without arbitrary history")
	_check(int(trial.by_archetype.Tinker.attempts) == 0 and int(trial.by_archetype.Tinker.best_seed) == 0, "negative counts and best without completion cleared")
	_check(int(trial.by_archetype.Runner.attempts) == 0 and int(trial.by_archetype.Runner.last_seed) == 0, "strings, booleans and fractional seeds rejected")
	_check(float(trial.by_archetype.Keeper.last_seconds) == 0.0 and int(trial.by_archetype.Keeper.best_seed) == 0, "oversized duration cannot become a plausible best")
	_finish(notebook, "relay", "Keeper", 1704, 40.0)
	_check(float(_role(notebook, "relay", "Keeper").best_seconds) == 40.0, "next valid completion repairs missing best metadata")
	_check(notebook.save_records(), "sanitized known schema can be saved")
	var output: Dictionary = JSON.parse_string(_read(_path("sanitized")))
	_check(not output.has("history") and not output.trials.has("unknown"), "save does not persist discarded arbitrary data")


func _test_counter_limit() -> void:
	cases += 1
	var fixture: Dictionary = {"schema_version": 1, "trials": {"clock": {"by_archetype": {"Veil": {"attempts": 1e30, "completions": 1e30}}}}}
	_write(_path("counter_limit"), JSON.stringify(fixture))
	var notebook: Records = Records.new(_path("counter_limit"))
	_check(notebook.load_records(), "oversized counters load bounded")
	var record: Dictionary = _role(notebook, "clock", "Veil")
	_check(int(record.attempts) == Records.MAX_COUNTER and int(record.completions) == Records.MAX_COUNTER, "counter cap applied before integer conversion")
	_check(not notebook.begin_attempt("clock", "Veil", 1701), "saturated summary cannot overflow")
	_check(notebook.begin_attempt("clock", "Tinker", 1701), "counter cap is local to one trial and archetype")


func _test_invalid_documents_preserved() -> void:
	cases += 1
	var invalids: Array[String] = ["{broken", "[]", "null", "{\"trials\":{}}", "{\"schema_version\":true}"]
	for index: int in range(invalids.size()):
		var path: String = _path("invalid_doc_%d" % index)
		_write(path, invalids[index])
		var notebook: Records = Records.new(path)
		_check(not notebook.load_records() and notebook.read_only and not notebook.last_error.is_empty(), "invalid notebook reports readable error and preserves data")
		_finish(notebook, "silent", "Veil", 1701, 5.0)
		_check(not notebook.save_records(), "invalid existing notebook blocks replacement")
		_check(_read(path) == invalids[index], "invalid existing bytes remain untouched")


func _test_future_schema_preserved() -> void:
	cases += 1
	var source: String = "{\"schema_version\":2,\"future_data\":[1,2,3]}"
	_write(_path("future"), source)
	var notebook: Records = Records.new(_path("future"))
	# No explicit load: begin must still discover and protect the future schema.
	_check(notebook.begin_attempt("relay", "Tinker", 1701), "practice can continue in memory with a future notebook")
	_check(notebook.read_only and not notebook.last_error.is_empty(), "implicit load detects unsupported schema")
	_check(notebook.complete_attempt(12.0) and not notebook.save_records(), "future schema cannot be overwritten after a completion")
	_check(_read(_path("future")) == source, "future notebook remains byte-for-byte intact")
	_check(not FileAccess.file_exists(_path("future") + ".tmp"), "schema rejection happens before temporary write")


func _test_external_schema_change() -> void:
	cases += 1
	var notebook: Records = _new("upgraded")
	_finish(notebook, "strings", "Runner", 1701, 15.0)
	_check(notebook.save_records(), "save supported notebook before external upgrade")
	var upgraded: String = "{\"schema_version\":3,\"future_progress\":42}"
	_write(_path("upgraded"), upgraded)
	_check(not notebook.save_records() and notebook.read_only, "save rechecks schema even after earlier successful load")
	_check(_read(_path("upgraded")) == upgraded, "external newer schema is preserved")


func _test_atomic_replacement_failure() -> void:
	cases += 1
	var notebook: Records = _new("atomic")
	_finish(notebook, "ritual", "Keeper", 1701, 30.0)
	_check(notebook.save_records(), "save initial valid notebook")
	var old_content: String = _read(_path("atomic"))
	_finish(notebook, "ritual", "Keeper", 1702, 25.0)
	var temporary: String = _path("atomic") + ".tmp"
	_check(DirAccess.make_dir_absolute(temporary) == OK, "block temporary filename with owned QA folder")
	_check(not notebook.save_records() and not notebook.last_error.is_empty(), "temporary write failure is reported")
	_check(_read(_path("atomic")) == old_content, "failed temporary write never truncates valid notebook")
	DirAccess.remove_absolute(temporary)
	_check(notebook.save_records(), "retry after filesystem failure succeeds")
	var reloaded: Records = Records.new(_path("atomic"))
	_check(reloaded.load_records() and int(_role(reloaded, "ritual", "Keeper").completions) == 2, "successful replacement contains new completion")
	_check(not FileAccess.file_exists(temporary), "completed atomic save removes temporary file")


func _test_match_result_separation() -> void:
	cases += 1
	var match_path: String = _base.path_join("last_observance.json")
	var match_bytes: String = "{\"winner\":\"survivors\",\"seed\":1701,\"untouched\":true}"
	_write(match_path, match_bytes)
	var notebook: Records = Records.new(_base.path_join("practice_records.json"))
	_check(notebook.load_records(), "practice file loads next to prior match result")
	_finish(notebook, "silent", "Veil", 1701, 30.0)
	_check(notebook.save_records(), "save separate practice file")
	_check(_read(match_path) == match_bytes, "practice notebook never changes last match result")


func _test_path_and_size_limits() -> void:
	cases += 1
	for invalid_path: String in ["", "relative.json", "res://practice_records.json"]:
		var invalid: Records = Records.new(invalid_path)
		_check(not invalid.load_records() and not invalid.save_records(), "invalid or resource path rejected")
	var folder_path: String = _base.path_join("folder.json")
	DirAccess.make_dir_absolute(folder_path)
	var folder: Records = Records.new(folder_path)
	_check(not folder.load_records() and not folder.save_records(), "folder cannot be replaced with notebook file")
	var large_path: String = _path("oversized")
	var oversized: String = " ".repeat(Records.MAX_FILE_BYTES + 1)
	_write(large_path, oversized)
	var large: Records = Records.new(large_path)
	_check(not large.load_records() and large.read_only and not large.save_records(), "oversized file rejected before JSON parsing")
	_check(_read(large_path).length() == Records.MAX_FILE_BYTES + 1, "oversized source preserved")
	var nested: Records = Records.new(_base.path_join("nested/folder/notebook.json"))
	_check(nested.load_records(), "new nested notebook path is valid")
	_finish(nested, "clock", "Tinker", 1701, Records.MAX_SECONDS)
	_check(nested.save_records(), "save creates parent folder and accepts maximum finite duration")


func _test_windows_failed_move_restores_primary() -> void:
	cases += 1
	var path: String = _path("windows_restore")
	var notebook: FailedWindowsMove = FailedWindowsMove.new(path)
	_check(notebook.load_records(), "load Windows replacement simulation")
	_finish(notebook, "relay", "Tinker", 1701, 15.0)
	_check(notebook.save_records(), "save original before simulated Windows failure")
	var old_content: String = _read(path)
	_finish(notebook, "relay", "Tinker", 1702, 12.0)
	notebook.fail_next_move = true
	_check(not notebook.save_records(), "Windows delete-then-failed-move reports unsuccessful save")
	_check(_read(path) == old_content and _read(path + ".bak") == old_content, "failed Windows move restores previous primary and retains backup")
	_check(notebook.last_error.contains("restored"), "save error reports successful rollback without claiming new progress persisted")
	_check(not FileAccess.file_exists(path + ".tmp") and not FileAccess.file_exists(path + ".restore.tmp") and not FileAccess.file_exists(path + ".bak.tmp"), "failed replacement cleans only staging files")
	_check(notebook.save_records(), "new progress can be saved after successful rollback")
	var loaded: Records = Records.new(path)
	_check(loaded.load_records() and int(_role(loaded, "relay", "Tinker").completions) == 2, "retry persists the completion that previously failed to save")


func _test_windows_failed_restore_keeps_backup() -> void:
	cases += 1
	var path: String = _path("windows_backup")
	var notebook: FailedWindowsMove = FailedWindowsMove.new(path)
	_check(notebook.load_records(), "load Windows recovery failure simulation")
	_finish(notebook, "light", "Runner", 1701, 30.0)
	_check(notebook.save_records(), "save original before simulated restoration failure")
	var old_content: String = _read(path)
	_finish(notebook, "light", "Runner", 1702, 25.0)
	notebook.fail_next_move = true
	notebook.fail_restore = true
	_check(not notebook.save_records() and not FileAccess.file_exists(path), "failed move and restoration leave no misleading primary")
	_check(_read(path + ".bak") == old_content and notebook.last_error.contains(".bak"), "failed restoration preserves and identifies recovery backup")
	var loaded: Records = Records.new(path)
	_check(loaded.load_records() and loaded.recovered_from_backup and not loaded.read_only, "relaunch recovers valid backup when primary is absent")
	_check(int(_role(loaded, "light", "Runner").completions) == 1, "backup recovery returns last saved completion without inventing failed save")
	_check(loaded.save_records() and FileAccess.file_exists(path), "subsequent save reconstructs missing primary")
	_check(_read(path + ".bak") == old_content, "reconstructing primary retains the recovery copy")


func _test_missing_primary_recovers_backup() -> void:
	cases += 1
	var path: String = _path("missing_primary")
	var notebook: Records = _new("missing_primary")
	_finish(notebook, "vault", "Veil", 1701, 30.0)
	_check(notebook.save_records(), "save first primary")
	var first: String = _read(path)
	_finish(notebook, "vault", "Veil", 1702, 20.0)
	_check(notebook.save_records() and _read(path + ".bak") == first, "second save keeps exactly the previous primary in fixed backup")
	DirAccess.remove_absolute(path)
	var loaded: Records = Records.new(path)
	_check(loaded.load_records() and loaded.recovered_from_backup, "absent primary explicitly recovers last complete backup")
	_check(int(_role(loaded, "vault", "Veil").completions) == 1, "recovery uses previous saved totals")
	_check(not FileAccess.file_exists(path), "loading backup is read-only until explicit save")
	_check(loaded.save_records(), "explicit save rebuilds absent primary")
	_check(loaded.load_records() and not loaded.recovered_from_backup, "subsequent load prefers rebuilt primary")


func _test_backup_does_not_hide_invalid_primary() -> void:
	cases += 1
	var invalids: Array[String] = ["{corrupt", "{\"schema_version\":2,\"future\":true}"]
	for index: int in range(invalids.size()):
		var path: String = _path("invalid_primary_%d" % index)
		var original: Records = Records.new(path)
		original.load_records()
		_finish(original, "clock", "Keeper", 1701, 25.0)
		_check(original.save_records(), "write valid recovery fixture")
		var backup: String = _read(path)
		_write(path + ".bak", backup)
		_write(path, invalids[index])
		var loaded: Records = Records.new(path)
		_check(not loaded.load_records() and loaded.read_only and not loaded.recovered_from_backup, "existing invalid or future primary cannot be hidden by valid backup")
		_check(not loaded.save_records(), "invalid primary with valid backup still blocks replacement")
		_check(_read(path) == invalids[index] and _read(path + ".bak") == backup, "both primary and backup remain untouched")


func _test_invalid_or_future_backup_preserved() -> void:
	cases += 1
	var invalids: Array[String] = ["{broken", "{\"schema_version\":3,\"future\":42}"]
	for index: int in range(invalids.size()):
		var path: String = _path("invalid_backup_%d" % index)
		_write(path + ".bak", invalids[index])
		var loaded: Records = Records.new(path)
		_check(not loaded.load_records() and loaded.read_only, "invalid or future sole backup blocks new primary")
		_finish(loaded, "strings", "Runner", 1701, 15.0)
		_check(not loaded.save_records() and not FileAccess.file_exists(path), "memory practice cannot replace invalid sole backup")
		_check(_read(path + ".bak") == invalids[index], "sole invalid or future backup remains intact")


func _test_future_backup_with_valid_primary() -> void:
	cases += 1
	var notebook: Records = _new("future_backup")
	_finish(notebook, "chimes", "Keeper", 1701, 20.0)
	_check(notebook.save_records(), "write supported primary beside future backup fixture")
	var primary: String = _read(_path("future_backup"))
	var future: String = "{\"schema_version\":9,\"future_progress\":123}"
	_write(_path("future_backup") + ".bak", future)
	_check(not notebook.save_records() and notebook.read_only, "save protects newer backup even beside supported primary")
	_check(_read(_path("future_backup")) == primary and _read(_path("future_backup") + ".bak") == future, "future backup protection preserves both files")


func _cleanup(path: String) -> void:
	for file: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	for folder: String in DirAccess.get_directories_at(path):
		_cleanup(path.path_join(folder))
	DirAccess.remove_absolute(path)
