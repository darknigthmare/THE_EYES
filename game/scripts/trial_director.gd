class_name TrialDirector
extends RefCounted
## Rendering-independent match authority for THE EYES: The First Observance.
## Call step() once per simulation tick. World actors report verified interactions.
## This class does not perform physics, line-of-sight traces, damage, or networking.

signal event_raised(kind: String, payload: Dictionary)

const PREPARATION_SECONDS: float = 8.0
const MAX_ENERGY: float = 100.0
const ENERGY_PER_SECOND: float = 4.0
const RELAY_SECONDS: float = 12.0
const RELAY_DECAY_PER_SECOND: float = 1.0 / 24.0
const EPSILON: float = 0.000001
const POWER_SPECS: Dictionary = {
	"trap": {"cost": 25.0, "cooldown": 4.0, "requires_los": true},
	"mark": {"cost": 20.0, "cooldown": 6.0, "requires_los": true},
	"summon": {"cost": 45.0, "cooldown": 16.0, "requires_los": true},
	"blink": {"cost": 8.0, "cooldown": 2.0, "requires_los": false},
}
const DIFFICULTY_SPECS: Dictionary = {
	"story": {"hunt": 600.0, "escape": 90.0},
	"standard": {"hunt": 480.0, "escape": 65.0},
	"ruthless": {"hunt": 360.0, "escape": 50.0},
}

var phase: String = "preparation"
var mode: String = "survivor"
var difficulty: String = "standard"
var winner: String = ""
var time_left: float = 480.0
var grace_left: float = PREPARATION_SECONDS
var escape_left: float = 65.0
var energy: float = MAX_ENERGY
var terror: float = 0.0
var seals: Dictionary = {"silent": false, "echoes": false, "relay": false}
var cooldowns: Dictionary = {"trap": 0.0, "mark": 0.0, "summon": 0.0, "blink": 0.0}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var echo_sequence: Array[int] = []
var echo_index: int = 0
var echo_errors: int = 0
var motes_delivered: int = 0
var relay_progress: float = 0.0
var eye_socket: int = 0
var alive_count: int = 1
var escaped_count: int = 0

var _relay_checkpoint: float = 0.0
var _escape_duration: float = 65.0


func configure(p_mode: String, p_difficulty: String, p_seed: int, survivor_count: int = 1) -> void:
	mode = p_mode.to_lower() if p_mode.to_lower() in ["survivor", "eye"] else "survivor"
	difficulty = p_difficulty.to_lower()
	if not DIFFICULTY_SPECS.has(difficulty):
		difficulty = "standard"
	var settings: Dictionary = DIFFICULTY_SPECS[difficulty]
	phase = "preparation"
	winner = ""
	time_left = float(settings["hunt"])
	grace_left = PREPARATION_SECONDS
	_escape_duration = float(settings["escape"])
	escape_left = _escape_duration
	energy = MAX_ENERGY
	terror = 0.0
	seals = {"silent": false, "echoes": false, "relay": false}
	cooldowns = {"trap": 0.0, "mark": 0.0, "summon": 0.0, "blink": 0.0}
	echo_index = 0
	echo_errors = 0
	motes_delivered = 0
	relay_progress = 0.0
	_relay_checkpoint = 0.0
	eye_socket = 0
	alive_count = maxi(1, survivor_count)
	escaped_count = 0
	rng.seed = p_seed
	# A seeded permutation makes every symbol meaningful and avoids ambiguous runs.
	echo_sequence.assign([0, 1, 2, 3])
	for index: int in range(echo_sequence.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var temporary: int = echo_sequence[index]
		echo_sequence[index] = echo_sequence[other]
		echo_sequence[other] = temporary
	event_raised.emit("phase", {"phase": phase, "previous": ""})


func step(delta: float) -> void:
	if not _valid_delta(delta) or phase == "ended":
		return
	var remaining_delta: float = delta
	if phase == "preparation":
		var preparation_step: float = minf(remaining_delta, grace_left)
		grace_left = maxf(0.0, grace_left - preparation_step)
		remaining_delta -= preparation_step
		if grace_left > 0.0:
			return
		_change_phase("hunt")
	if not _is_live() or remaining_delta <= 0.0:
		return
	# Do not regenerate resources beyond the instant at which a match terminates.
	var budget: float = time_left if phase == "hunt" else escape_left
	var live_delta: float = minf(remaining_delta, maxf(0.0, budget))
	energy = clampf(energy + ENERGY_PER_SECOND * live_delta, 0.0, MAX_ENERGY)
	terror = clampf(terror + 0.7 * live_delta, 0.0, 100.0)
	for power: String in cooldowns:
		cooldowns[power] = maxf(0.0, float(cooldowns[power]) - live_delta)
	if phase == "hunt":
		time_left = maxf(0.0, time_left - live_delta)
		if time_left <= 0.0:
			_finish("eye", "hunt_timeout")
	elif phase == "escape":
		escape_left = maxf(0.0, escape_left - live_delta)
		if escape_left <= 0.0:
			_finish("eye", "escape_timeout")


func can_use(power: String, has_line_of_sight: bool = true) -> bool:
	if not _is_live() or not POWER_SPECS.has(power):
		return false
	var spec: Dictionary = POWER_SPECS[power]
	if bool(spec["requires_los"]) and not has_line_of_sight:
		return false
	return float(cooldowns[power]) <= EPSILON and energy + EPSILON >= float(spec["cost"])


func try_use(power: String, has_line_of_sight: bool = true) -> bool:
	if not can_use(power, has_line_of_sight):
		return false
	var spec: Dictionary = POWER_SPECS[power]
	var cost: float = float(spec["cost"])
	energy = maxf(0.0, energy - cost)
	cooldowns[power] = float(spec["cooldown"])
	event_raised.emit("power", {
		"power": power, "cost": cost, "cooldown": float(spec["cooldown"]), "energy": energy,
	})
	return true


func switch_socket(index: int) -> bool:
	if index < 0 or index > 3 or index == eye_socket:
		return false
	if not try_use("blink", false):
		return false
	eye_socket = index
	return true


func deliver_mote() -> bool:
	if not _is_live() or bool(seals["silent"]) or motes_delivered >= 3:
		return false
	motes_delivered += 1
	event_raised.emit("delivery", {"delivered": motes_delivered, "required": 3})
	if motes_delivered == 3:
		_complete_seal("silent")
	return true


func input_echo(symbol: int) -> bool:
	if not _is_live() or bool(seals["echoes"]) or symbol < 0 or symbol > 3:
		return false
	if echo_sequence.is_empty():
		return false
	if symbol != echo_sequence[echo_index]:
		echo_index = 0
		echo_errors += 1
		event_raised.emit("echo_error", {"errors": echo_errors, "progress": 0})
		return false
	echo_index += 1
	event_raised.emit("echo_correct", {"progress": echo_index, "required": echo_sequence.size()})
	if echo_index == echo_sequence.size():
		_complete_seal("echoes")
	return true


func charge_relay(delta: float, actively_holding: bool) -> void:
	if not _is_live() or not _valid_delta(delta) or bool(seals["relay"]):
		return
	if actively_holding:
		relay_progress = minf(1.0, relay_progress + delta / RELAY_SECONDS)
		if relay_progress + EPSILON >= 2.0 / 3.0:
			_relay_checkpoint = 2.0 / 3.0
		elif relay_progress + EPSILON >= 1.0 / 3.0:
			_relay_checkpoint = 1.0 / 3.0
		# Snap roundoff at checkpoints so repeated short ticks cannot undershoot.
		relay_progress = maxf(relay_progress, _relay_checkpoint)
		if relay_progress + EPSILON >= 1.0:
			relay_progress = 1.0
			_complete_seal("relay")
	else:
		relay_progress = maxf(_relay_checkpoint, relay_progress - delta * RELAY_DECAY_PER_SECOND)


func register_elimination() -> void:
	if not _is_live() or alive_count <= 0:
		return
	alive_count -= 1
	if alive_count == 0:
		_finish("eye", "all_eliminated")


func register_escape() -> void:
	if phase != "escape" or alive_count <= 0:
		return
	escaped_count += 1
	alive_count -= 1
	_finish("survivors", "first_escape")


func _complete_seal(seal_id: String) -> void:
	if bool(seals[seal_id]):
		return
	seals[seal_id] = true
	event_raised.emit("seal", {"seal": seal_id, "completed": seals.values().count(true), "required": 3})
	if bool(seals["silent"]) and bool(seals["echoes"]) and bool(seals["relay"]):
		escape_left = _escape_duration
		_change_phase("escape")


func _change_phase(next_phase: String) -> void:
	if phase == next_phase:
		return
	var previous: String = phase
	phase = next_phase
	event_raised.emit("phase", {"phase": phase, "previous": previous})


func _finish(result: String, reason: String) -> void:
	if phase == "ended":
		return
	winner = result
	_change_phase("ended")
	event_raised.emit("result", {"winner": winner, "reason": reason, "escaped": escaped_count, "alive": alive_count})


func _is_live() -> bool:
	return phase == "hunt" or phase == "escape"


func _valid_delta(delta: float) -> bool:
	return is_finite(delta) and delta > 0.0
