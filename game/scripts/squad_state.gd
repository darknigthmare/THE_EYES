class_name EyesSquadState
extends RefCounted
## Life and rescue authority for the explicit local Survivor Squad mode.
## The world owns health, position, reach, sight, input and damage interruption.
## Call step once per live frame; call advance_revive only while the world has
## validated continuous rescue, or cancel_revive as soon as that hold breaks.

signal event_raised(kind: String, payload: Dictionary)

const BLEED_SECONDS: float = 35.0
const REVIVE_SECONDS: float = 6.0
const REVIVE_HEALTH: float = 35.0
const REVIVE_PROTECTION: float = 5.0
const EPSILON: float = 0.000001

var members: Dictionary = {}
var human_id: int = 0
var live: bool = false


func configure(member_ids: Array[int], p_human_id: int) -> void:
	live = false
	members.clear()
	for actor_id: int in member_ids:
		if actor_id <= 0 or members.has(actor_id):
			continue
		members[actor_id] = {
			"state": "active", "recoveries": 0, "bleed_left": 0.0,
			"reviver": 0, "revive_progress": 0.0,
		}
	human_id = p_human_id if members.has(p_human_id) else 0


func set_live(value: bool) -> void:
	if value:
		live = human_id > 0 and _has_active_member()
		return
	live = false
	var interrupted: Array[Dictionary] = []
	for actor_id: int in members:
		_clear_reservation(actor_id, interrupted)
	_emit_interruptions(interrupted)


func fall(actor_id: int) -> bool:
	if not live or not is_active(actor_id):
		return false
	if int(members[actor_id]["recoveries"]) > 0:
		_eliminate_members([actor_id], "second_fall")
	else:
		members[actor_id]["state"] = "downed"
		members[actor_id]["bleed_left"] = BLEED_SECONDS
		var interrupted: Array[Dictionary] = []
		_release_links(actor_id, interrupted)
		_emit_interruptions(interrupted)
		event_raised.emit("squad_downed", {"actor_id": actor_id, "bleed_seconds": BLEED_SECONDS})
	_resolve_wipe()
	return true


func step(delta: float) -> void:
	if not live or not _valid_delta(delta):
		return
	var expired: Array[int] = []
	for actor_id: int in members:
		if not is_downed(actor_id):
			continue
		var remaining: float = maxf(0.0, float(members[actor_id]["bleed_left"]) - delta)
		members[actor_id]["bleed_left"] = remaining
		if remaining <= EPSILON:
			expired.append(actor_id)
	_eliminate_members(expired, "bleedout")
	_resolve_wipe()


func begin_revive(helper_id: int, subject_id: int) -> bool:
	if not live or helper_id == subject_id or not is_active(helper_id) or not is_downed(subject_id):
		return false
	var current_helper: int = int(members[subject_id]["reviver"])
	# Repeated hold ticks may reassert the same reservation without restarting it.
	if current_helper == helper_id:
		return true
	if current_helper != 0 or _subject_for_helper(helper_id) != 0:
		return false
	members[subject_id]["reviver"] = helper_id
	members[subject_id]["revive_progress"] = 0.0
	event_raised.emit("squad_revive_started", {"actor_id": subject_id, "helper_id": helper_id})
	return true


func advance_revive(helper_id: int, subject_id: int, delta: float) -> bool:
	if not live or not _valid_delta(delta) or helper_id == subject_id or not is_active(helper_id) or not is_downed(subject_id):
		return false
	if int(members[subject_id]["reviver"]) != helper_id:
		return false
	var progress: float = minf(REVIVE_SECONDS, float(members[subject_id]["revive_progress"]) + delta)
	members[subject_id]["revive_progress"] = progress
	if progress + EPSILON >= REVIVE_SECONDS:
		members[subject_id]["state"] = "active"
		members[subject_id]["recoveries"] = 1
		members[subject_id]["bleed_left"] = 0.0
		members[subject_id]["reviver"] = 0
		members[subject_id]["revive_progress"] = 0.0
		event_raised.emit("squad_revived", {
			"actor_id": subject_id, "helper_id": helper_id,
			"health": REVIVE_HEALTH, "protection": REVIVE_PROTECTION,
		})
	return true


func cancel_revive(helper_id: int) -> void:
	if not live:
		return
	var subject_id: int = _subject_for_helper(helper_id)
	if subject_id == 0:
		return
	var interrupted: Array[Dictionary] = []
	_clear_reservation(subject_id, interrupted)
	_emit_interruptions(interrupted)


func is_active(actor_id: int) -> bool:
	return members.has(actor_id) and str(members[actor_id]["state"]) == "active"


func is_downed(actor_id: int) -> bool:
	return members.has(actor_id) and str(members[actor_id]["state"]) == "downed"


func is_eliminated(actor_id: int) -> bool:
	return members.has(actor_id) and str(members[actor_id]["state"]) == "eliminated"


func member(actor_id: int) -> Dictionary:
	if not members.has(actor_id):
		return {}
	return members[actor_id].duplicate(true)


func _subject_for_helper(helper_id: int) -> int:
	if helper_id <= 0:
		return 0
	for actor_id: int in members:
		if int(members[actor_id]["reviver"]) == helper_id:
			return actor_id
	return 0


func _clear_reservation(subject_id: int, interrupted: Array[Dictionary]) -> void:
	var helper_id: int = int(members[subject_id]["reviver"])
	members[subject_id]["reviver"] = 0
	members[subject_id]["revive_progress"] = 0.0
	if helper_id > 0:
		interrupted.append({"actor_id": subject_id, "helper_id": helper_id})


func _release_links(actor_id: int, interrupted: Array[Dictionary]) -> void:
	for subject_id: int in members:
		if subject_id == actor_id or int(members[subject_id]["reviver"]) == actor_id:
			_clear_reservation(subject_id, interrupted)


func _emit_interruptions(interrupted: Array[Dictionary]) -> void:
	for payload: Dictionary in interrupted:
		event_raised.emit("squad_revive_interrupted", payload)


func _eliminate_members(actor_ids: Array[int], reason: String) -> void:
	var eliminated: Array[int] = []
	var interrupted: Array[Dictionary] = []
	for actor_id: int in actor_ids:
		if not members.has(actor_id) or is_eliminated(actor_id):
			continue
		members[actor_id]["state"] = "eliminated"
		members[actor_id]["bleed_left"] = 0.0
		eliminated.append(actor_id)
	for actor_id: int in eliminated:
		_release_links(actor_id, interrupted)
	# Every affected state and reservation is committed before any notification.
	_emit_interruptions(interrupted)
	for actor_id: int in eliminated:
		event_raised.emit("squad_eliminated", {"actor_id": actor_id, "reason": reason})


func _has_active_member() -> bool:
	for actor_id: int in members:
		if is_active(actor_id):
			return true
	return false


func _resolve_wipe() -> void:
	if not live or _has_active_member():
		return
	var remaining: Array[int] = []
	for actor_id: int in members:
		if is_downed(actor_id):
			remaining.append(actor_id)
	live = false
	_eliminate_members(remaining, "squad_wipe")


func _valid_delta(delta: float) -> bool:
	return is_finite(delta) and delta > 0.0
