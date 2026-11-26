class_name PracticeRecords
extends RefCounted
## Small local notebook, independent of last_observance.json and match results.
## One in-memory attempt; only fixed per-trial / per-archetype totals persist.

const PracticeRules = preload("res://scripts/practice_state.gd")
const TrialSetRules = preload("res://scripts/trial_set.gd")
const SCHEMA_VERSION: int = 1
const DEFAULT_PATH: String = "user://practice_records.json"
const ARCHETYPES: Array[String] = ["Veil", "Tinker", "Runner", "Keeper"]
const MAX_COUNTER: int = 1000000
const MAX_SECONDS: float = PracticeRules.MAX_SECONDS
const MAX_FILE_BYTES: int = 131072

var last_error: String = ""
var read_only: bool = false
var recovered_from_backup: bool = false

var _path: String
var _records: Dictionary
var _attempt: Dictionary = {}
var _loaded: bool = false
var _read_only_reason: String = ""


func _init(path: String = DEFAULT_PATH) -> void:
	_path = path
	_records = _empty_records()


func load_records() -> bool:
	_loaded = true
	_attempt.clear()
	read_only = false
	recovered_from_backup = false
	last_error = ""
	_read_only_reason = ""
	if not _valid_path():
		return _block_save("The practice notebook path must be an absolute file path.")
	var source: String = _path
	if not FileAccess.file_exists(_path):
		if DirAccess.dir_exists_absolute(_path):
			return _block_save("The practice notebook path is a folder, not a file.")
		# Windows rename can remove its destination before the move succeeds.
		# Recover only an absent primary; never hide a corrupt or newer primary.
		source = _path + ".bak"
		if not FileAccess.file_exists(source):
			if DirAccess.dir_exists_absolute(source):
				return _block_save("The practice notebook backup path is a folder, not a file.")
			_records = _empty_records()
			return true
	var parsed: Dictionary = _read_document(source)
	if not bool(parsed.get("ok", false)):
		return false
	var document: Dictionary = parsed.document
	if not _accept_schema(document):
		return false
	_records = _sanitize(document)
	recovered_from_backup = source != _path
	return true


func begin_attempt(trial_id: String, archetype: String, seed: int) -> bool:
	# Loading first also protects an existing future-version file if a caller
	# forgets the explicit load on startup. Practice can still continue in memory.
	if not _loaded:
		load_records()
	if not PracticeRules.TRIAL_IDS.has(trial_id) or not ARCHETYPES.has(archetype) or not TrialSetRules.valid_practice_seed(seed):
		last_error = "The practice attempt has an unknown trial, survivor or seed."
		return false
	if not _attempt.is_empty():
		last_error = "Finish or abandon the current practice attempt before starting another."
		return false
	var trial: Dictionary = _records.trials[trial_id]
	var record: Dictionary = trial.by_archetype[archetype]
	if int(record.attempts) >= MAX_COUNTER:
		last_error = "The practice notebook has reached its attempt limit for this survivor and trial."
		return false
	record.attempts = int(record.attempts) + 1
	record.last_seed = seed
	record.last_seconds = 0.0
	_recount(trial)
	_attempt = {"trial_id": trial_id, "archetype": archetype, "seed": seed}
	if not read_only:
		last_error = ""
	return true


func complete_attempt(seconds: float) -> bool:
	if _attempt.is_empty():
		last_error = "There is no active practice attempt to complete."
		return false
	if not is_finite(seconds) or seconds < 0.0 or seconds > MAX_SECONDS:
		last_error = "The practice duration is outside the notebook's supported range."
		return false
	var trial: Dictionary = _records.trials[str(_attempt.trial_id)]
	var record: Dictionary = trial.by_archetype[str(_attempt.archetype)]
	record.completions = mini(int(record.attempts), int(record.completions) + 1)
	record.last_seed = int(_attempt.seed)
	record.last_seconds = seconds
	if int(record.best_seed) == 0 or seconds < float(record.best_seconds):
		record.best_seconds = seconds
		record.best_seed = int(_attempt.seed)
	_recount(trial)
	_attempt.clear()
	if not read_only:
		last_error = ""
	return true


func abandon_attempt() -> void:
	# Beginning an attempt is counted, but an abandoned attempt is never completed.
	_attempt.clear()


func snapshot() -> Dictionary:
	return _records.duplicate(true)


func save_records() -> bool:
	if not _loaded and not load_records():
		return false
	if read_only:
		last_error = _read_only_reason if not _read_only_reason.is_empty() else "The existing practice notebook is preserved; this session is in memory only."
		return false
	if not _valid_path():
		last_error = "The practice notebook path must be an absolute file path."
		return false
	# Recheck the on-disk schema before replacement, including after a successful
	# initial load. An upgraded or damaged notebook must never be overwritten.
	if FileAccess.file_exists(_path):
		var parsed: Dictionary = _read_document()
		if not bool(parsed.get("ok", false)) or not _accept_schema(parsed.document):
			return false
	elif DirAccess.dir_exists_absolute(_path):
		last_error = "The practice notebook path is a folder, not a file."
		return false
	if FileAccess.file_exists(_path + ".bak"):
		# The backup can be the sole surviving copy after a failed Windows move.
		# Preserve unsupported backup data even when a valid primary also exists.
		var backup: Dictionary = _read_document(_path + ".bak")
		if not bool(backup.get("ok", false)) or not _accept_schema(backup.document):
			return false
	elif DirAccess.dir_exists_absolute(_path + ".bak"):
		last_error = "The practice notebook backup path is a folder, not a file."
		return false
	var parent: String = _path.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent):
		var directory_error: Error = DirAccess.make_dir_recursive_absolute(parent)
		if directory_error != OK:
			last_error = "Could not create the practice notebook folder (error %d)." % directory_error
			return false
	var temporary: String = _path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Could not open the temporary practice notebook (error %d)." % FileAccess.get_open_error()
		return false
	file.store_string(JSON.stringify(_records, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary)
		last_error = "Could not finish writing the practice notebook (error %d)." % write_error
		return false
	# Keep one recoverable prior notebook before replacing the primary. Godot's
	# Windows rename removes an existing destination before calling MoveFileW;
	# same-directory replacement alone is therefore not atomic on that platform.
	if FileAccess.file_exists(_path) and not _prepare_backup():
		DirAccess.remove_absolute(temporary)
		return false
	var rename_error: Error = _replace_file(temporary, _path)
	if rename_error != OK:
		DirAccess.remove_absolute(temporary)
		if not FileAccess.file_exists(_path) and FileAccess.file_exists(_path + ".bak"):
			if _restore_backup():
				last_error = "Could not replace the practice notebook (error %d); the previous notebook was restored." % rename_error
			else:
				last_error = "Could not replace or restore the practice notebook (error %d); the previous notebook remains in its .bak file." % rename_error
		else:
			last_error = "Could not replace the practice notebook (error %d); the existing notebook was preserved." % rename_error
		return false
	last_error = ""
	return true


func _valid_path() -> bool:
	return not _path.is_empty() and (_path.begins_with("user://") or _path.is_absolute_path()) and not _path.ends_with("/") and not _path.begins_with("res://")


func _prepare_backup() -> bool:
	var backup: String = _path + ".bak"
	var staged: String = backup + ".tmp"
	var copy_error: Error = DirAccess.copy_absolute(_path, staged)
	if copy_error != OK:
		if FileAccess.file_exists(staged):
			DirAccess.remove_absolute(staged)
		last_error = "Could not prepare the practice notebook backup (error %d); the primary was preserved." % copy_error
		return false
	# Failure here may lose an older backup, but the current primary remains
	# intact. Never begin primary replacement unless this backup is installed.
	var backup_error: Error = DirAccess.rename_absolute(staged, backup)
	if backup_error != OK:
		DirAccess.remove_absolute(staged)
		last_error = "Could not install the practice notebook backup (error %d); the primary was preserved." % backup_error
		return false
	return true


func _restore_backup() -> bool:
	var staged: String = _path + ".restore.tmp"
	var copy_error: Error = DirAccess.copy_absolute(_path + ".bak", staged)
	if copy_error != OK:
		if FileAccess.file_exists(staged):
			DirAccess.remove_absolute(staged)
		return false
	var restore_error: Error = _replace_file(staged, _path)
	if restore_error != OK:
		DirAccess.remove_absolute(staged)
		return false
	return true


func _replace_file(source: String, destination: String) -> Error:
	# A small seam lets tests simulate Windows' delete-then-failed-move behavior
	# without modifying real user files or depending on the host platform.
	return DirAccess.rename_absolute(source, destination)


func _read_document(source: String = "") -> Dictionary:
	var read_path: String = _path if source.is_empty() else source
	var file: FileAccess = FileAccess.open(read_path, FileAccess.READ)
	if file == null:
		_block_save("Could not read the existing practice notebook (error %d); it has been preserved." % FileAccess.get_open_error())
		return {"ok": false}
	if file.get_length() > MAX_FILE_BYTES:
		file.close()
		_block_save("The practice notebook is too large to load safely; it has been preserved.")
		return {"ok": false}
	var content: String = file.get_as_text()
	var read_error: Error = file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		_block_save("Could not finish reading the practice notebook (error %d); it has been preserved." % read_error)
		return {"ok": false}
	var parser: JSON = JSON.new()
	if parser.parse(content) != OK or not parser.data is Dictionary:
		_block_save("The practice notebook is not valid JSON data; it has been preserved.")
		return {"ok": false}
	return {"ok": true, "document": parser.data}


func _accept_schema(document: Dictionary) -> bool:
	var version: Variant = document.get("schema_version", null)
	if not _number(version) or float(version) != float(SCHEMA_VERSION):
		return _block_save("This practice notebook uses an unsupported schema; it has been preserved.")
	return true


func _block_save(message: String) -> bool:
	read_only = true
	_read_only_reason = message
	last_error = message
	return false


static func _empty_record() -> Dictionary:
	return {"attempts": 0, "completions": 0, "last_seed": 0, "last_seconds": 0.0, "best_seconds": 0.0, "best_seed": 0}


static func _empty_records() -> Dictionary:
	var trials: Dictionary = {}
	for trial_id: String in PracticeRules.TRIAL_IDS:
		var roles: Dictionary = {}
		for archetype: String in ARCHETYPES:
			roles[archetype] = _empty_record()
		trials[trial_id] = {"attempts": 0, "completions": 0, "by_archetype": roles}
	return {"schema_version": SCHEMA_VERSION, "trials": trials}


static func _sanitize(document: Dictionary) -> Dictionary:
	var cleaned: Dictionary = _empty_records()
	var source: Variant = document.get("trials", {})
	if not source is Dictionary:
		return cleaned
	for trial_id: String in PracticeRules.TRIAL_IDS:
		var source_trial: Variant = source.get(trial_id, {})
		if not source_trial is Dictionary:
			continue
		var roles: Variant = source_trial.get("by_archetype", {})
		if not roles is Dictionary:
			continue
		var trial: Dictionary = cleaned.trials[trial_id]
		for archetype: String in ARCHETYPES:
			var source_record: Variant = roles.get(archetype, {})
			if not source_record is Dictionary:
				continue
			var record: Dictionary = trial.by_archetype[archetype]
			record.attempts = _counter(source_record.get("attempts", 0))
			record.completions = mini(int(record.attempts), _counter(source_record.get("completions", 0)))
			record.last_seed = _seed(source_record.get("last_seed", 0))
			var last_seconds: Variant = source_record.get("last_seconds", 0.0)
			if int(record.last_seed) > 0 and int(record.completions) > 0 and _duration(last_seconds):
				record.last_seconds = float(last_seconds)
			var best_seed: int = _seed(source_record.get("best_seed", 0))
			var best_seconds: Variant = source_record.get("best_seconds", null)
			if int(record.completions) > 0 and best_seed > 0 and _duration(best_seconds):
				record.best_seed = best_seed
				record.best_seconds = float(best_seconds)
		_recount(trial)
	return cleaned


static func _recount(trial: Dictionary) -> void:
	trial.attempts = 0
	trial.completions = 0
	for archetype: String in ARCHETYPES:
		trial.attempts += int(trial.by_archetype[archetype].attempts)
		trial.completions += int(trial.by_archetype[archetype].completions)


static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _counter(value: Variant) -> int:
	return int(clampf(float(value), 0.0, float(MAX_COUNTER))) if _number(value) else 0


static func _seed(value: Variant) -> int:
	if not _number(value) or float(value) != floorf(float(value)) or float(value) < 1.0 or float(value) > float(TrialSetRules.PRACTICE_MAX_SEED):
		return 0
	return int(value)


static func _duration(value: Variant) -> bool:
	return _number(value) and float(value) >= 0.0 and float(value) <= MAX_SECONDS
