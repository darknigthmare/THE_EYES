class_name TrialSet
extends RefCounted
## Deterministic alternate-trial authority. The world validates physical reach,
## visibility, inventory visuals and eligible circle occupancy before calling it.

signal event_raised(kind: String, payload: Dictionary)
signal trial_completed(slot: String, trial_id: String)

const ThirdRules = preload("res://scripts/third_trials.gd")
const RELIC_NAMES: Array[String] = ["Orb", "Spire", "Cube", "Ring", "Crown", "Diamond"]
const TRIAL_NAMES: Dictionary = {
	"silent": "Silent Countdown", "vault": "The Memory Vault",
	"echoes": "Trial of the Echoes", "ritual": "The Ritual Circle",
	"relay": "Clockwork Relay", "clock": "The Clock Room",
	"light": "Light in the Darkness", "strings": "Strings of Despair", "chimes": "Chimes of Doom",
}
const SLOT_VARIANTS: Dictionary = {
	"silent": ["silent", "vault", "light"], "echoes": ["echoes", "ritual", "strings"], "relay": ["relay", "clock", "chimes"],
}
const RITUAL_HOLD_SECONDS: float = 8.0
const ACTOR_COMMAND_SECONDS: float = 0.35
const CLOCK_COMMAND_SECONDS: float = 0.25
const CLOCK_STEPS: int = 6
const CLOCK_MIN_SOLUTION_TURNS: int = 4
const CLOCK_TRANSFORMS: Array[Vector3i] = [Vector3i(1, 1, 0), Vector3i(0, 1, 1), Vector3i(1, 0, 1)]
const EPSILON: float = 0.000001
const PRACTICE_MIN_SEED: int = 1
const PRACTICE_MAX_SEED: int = 999999

var contract: String = "first"
var slot_trials: Dictionary = {"silent": "silent", "echoes": "echoes", "relay": "relay"}
var live: bool = false
var completed: Dictionary = {"silent": false, "echoes": false, "relay": false}
var vault_targets: Array[int] = []
var vault_cradles: Array[int] = [-1, -1, -1, -1]
var vault_carriers: Dictionary = {}
var ritual_sequence: Array[int] = []
var ritual_index: int = 0
var ritual_bank: int = 0
var ritual_hold: float = 0.0
var ember_owner: int = 0
var clock_hands: Array[int] = []
var clock_target: Array[int] = []
var clock_start: Array[int] = []
var clock_moves: int = 0
var clock_cooldown: float = 0.0
var actor_cooldowns: Dictionary = {}
var third: ThirdRules = ThirdRules.new()

var _solution_from: Vector3i = Vector3i(-1, -1, -1)
var _solution_cache: Array[Vector2i] = []


func configure(p_seed: int, p_contract: String = "first") -> void:
	_configure(p_seed, p_contract)


func configure_practice(trial_id: String, p_seed: int) -> bool:
	# Validate first: a rejected selection must not retire the current authority.
	if slot_for_trial(trial_id).is_empty() or not valid_practice_seed(p_seed):
		return false
	_configure(p_seed, "practice", trial_id)
	return true


static func slot_for_trial(trial_id: String) -> String:
	for slot: String in SLOT_VARIANTS:
		if SLOT_VARIANTS[slot].has(trial_id):
			return slot
	return ""


static func valid_practice_seed(p_seed: int) -> bool:
	return p_seed >= PRACTICE_MIN_SEED and p_seed <= PRACTICE_MAX_SEED


func _configure(p_seed: int, p_contract: String, practice_trial: String = "") -> void:
	contract = p_contract.to_lower()
	if not practice_trial.is_empty():
		contract = "practice"
	elif contract not in ["first", "second", "mix", "third"]:
		contract = "first"
	live = false
	completed = {"silent": false, "echoes": false, "relay": false}
	var selection_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	selection_rng.seed = p_seed ^ 0x534554
	for slot: String in SLOT_VARIANTS:
		var variant: int = 0
		if contract == "second":
			variant = 1
		elif contract == "third":
			variant = 2
		elif contract == "mix":
			# v0.4 explicitly expands the resolved pool to 27 combinations.
			variant = selection_rng.randi_range(0, 2)
		slot_trials[slot] = SLOT_VARIANTS[slot][variant]
		if contract == "practice":
			slot_trials[slot] = practice_trial if slot == slot_for_trial(practice_trial) else ""
	# Separate random streams keep the same trial's puzzle stable across contracts
	# and prevent any change to the original director's Echo random stream.
	var vault_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	vault_rng.seed = p_seed ^ 0x5641554C54
	vault_targets.assign(_permutation(6, vault_rng).slice(0, 4))
	vault_cradles.assign([-1, -1, -1, -1])
	vault_carriers.clear()
	var ritual_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	ritual_rng.seed = p_seed ^ 0x52495455414C
	ritual_sequence = _permutation(5, ritual_rng)
	ritual_index = 0
	ritual_bank = 0
	ritual_hold = 0.0
	ember_owner = 0
	var clock_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	clock_rng.seed = p_seed ^ 0x434C4F434B
	clock_target.clear()
	for unused: int in range(3):
		clock_target.append(clock_rng.randi_range(0, CLOCK_STEPS - 1))
	# Choose by true graph distance, not scramble length: reversible moves can
	# otherwise cancel into a trivial puzzle. This visits a finite state graph
	# once, with no random retries, and only returns legally reachable starts.
	var starts: Array[Vector3i] = _clock_distant_starts(_clock_vector(clock_target))
	var start: Vector3i = starts[clock_rng.randi_range(0, starts.size() - 1)]
	clock_start.assign([start.x, start.y, start.z])
	clock_hands.assign(clock_start)
	clock_moves = 0
	clock_cooldown = 0.0
	actor_cooldowns.clear()
	_solution_from = Vector3i(-1, -1, -1)
	_solution_cache.clear()
	# Retire stale world references before constructing the next match's rules.
	third.set_live(false)
	if third.event_raised.is_connected(_on_third_event):
		third.event_raised.disconnect(_on_third_event)
	if third.trial_completed.is_connected(_on_third_completed):
		third.trial_completed.disconnect(_on_third_completed)
	third = ThirdRules.new()
	third.configure(p_seed, slot_trials)
	var weak_owner: WeakRef = weakref(self)
	third.cargo_admission = func(actor_id: int) -> bool:
		var owner = weak_owner.get_ref()
		return owner != null and owner.carried_relic(actor_id) < 0 and owner.ember_owner != actor_id
	third.event_raised.connect(_on_third_event)
	third.trial_completed.connect(_on_third_completed)


func set_live(value: bool) -> void:
	live = value
	third.set_live(value)


func step(delta: float) -> void:
	if not live or not _valid_delta(delta):
		return
	third.step(delta)
	clock_cooldown = maxf(0.0, clock_cooldown - delta)
	for actor_id: int in actor_cooldowns.keys():
		var left: float = maxf(0.0, float(actor_cooldowns[actor_id]) - delta)
		if left <= EPSILON:
			actor_cooldowns.erase(actor_id)
		else:
			actor_cooldowns[actor_id] = left


func trial_for_slot(slot: String) -> String:
	return str(slot_trials.get(slot, ""))


func mark_slot_complete(slot: String) -> void:
	# Director calls this for legacy trials so selection progress stays coherent.
	if completed.has(slot) and not trial_for_slot(slot).is_empty():
		completed[slot] = true
		third.completed[slot] = true


func progress_for_slot(slot: String) -> float:
	if not completed.has(slot):
		return 0.0
	if bool(completed[slot]):
		return 1.0
	match trial_for_slot(slot):
		"vault":
			return float(4 - vault_cradles.count(-1)) / 4.0
		"ritual":
			return minf(0.99, float(ritual_index) / 5.0 * 0.8 + ritual_hold / RITUAL_HOLD_SECONDS * 0.2)
		"clock":
			var aligned: int = 0
			for index: int in range(3):
				if clock_hands[index] == clock_target[index]:
					aligned += 1
			return float(aligned) / 3.0 * 0.9
		"light", "strings", "chimes":
			return third.progress_for_slot(slot)
	return 0.0


func relic_available(index: int) -> bool:
	return index >= 0 and index < RELIC_NAMES.size() and not vault_cradles.has(index) and not vault_carriers.values().has(index)


func carried_relic(actor_id: int) -> int:
	return int(vault_carriers.get(actor_id, -1))


func pickup_relic(actor_id: int, index: int) -> bool:
	if not _can_act("silent", "vault") or actor_id <= 0 or carried_relic(actor_id) >= 0 or ember_owner == actor_id or third.carried_cell(actor_id) >= 0:
		return false
	if not relic_available(index):
		return false
	vault_carriers[actor_id] = index
	event_raised.emit("vault_pickup", {"actor_id": actor_id, "relic": index})
	return true


func deposit_relic(actor_id: int, cradle: int) -> bool:
	if not _can_act("silent", "vault") or not _actor_ready(actor_id) or cradle < 0 or cradle >= 4:
		return false
	var relic: int = carried_relic(actor_id)
	if relic < 0 or vault_cradles[cradle] >= 0:
		return false
	actor_cooldowns[actor_id] = ACTOR_COMMAND_SECONDS
	if relic != vault_targets[cradle]:
		event_raised.emit("vault_error", {"actor_id": actor_id, "cradle": cradle, "relic": relic})
		return false
	vault_cradles[cradle] = relic
	vault_carriers.erase(actor_id)
	event_raised.emit("vault_deposit", {"actor_id": actor_id, "cradle": cradle, "relic": relic, "deposited": 4 - vault_cradles.count(-1), "required": 4})
	if not vault_cradles.has(-1):
		_complete("silent", "vault")
	return true


func release_actor(actor_id: int) -> Dictionary:
	# Lifecycle cleanup is allowed after a result; it never mutates trial progress.
	var released: Dictionary = {"relic": carried_relic(actor_id), "ember": ember_owner == actor_id and actor_id > 0}
	var released_third: Dictionary = third.release_actor(actor_id)
	if int(released_third.cell) >= 0:
		released.cell = int(released_third.cell)
	vault_carriers.erase(actor_id)
	if bool(released["ember"]):
		ember_owner = 0
	if int(released["relic"]) >= 0 or bool(released["ember"]):
		event_raised.emit("cargo_released", {"actor_id": actor_id, "relic": int(released["relic"]), "ember": bool(released["ember"])})
	return released


func take_ember(actor_id: int) -> bool:
	if not _can_act("echoes", "ritual") or actor_id <= 0 or ember_owner != 0 or carried_relic(actor_id) >= 0 or ritual_index >= 5 or third.carried_cell(actor_id) >= 0:
		return false
	ember_owner = actor_id
	event_raised.emit("ember_taken", {"actor_id": actor_id})
	return true


func ritual_vessel_lit(index: int) -> bool:
	if index < 0 or index >= 5:
		return false
	for position: int in range(ritual_index):
		if ritual_sequence[position] == index:
			return true
	return false


func light_vessel(actor_id: int, index: int) -> bool:
	if not _can_act("echoes", "ritual") or not _actor_ready(actor_id) or ember_owner != actor_id or index < 0 or index >= 5 or ritual_index >= 5:
		return false
	# Repeated interaction with a lit vessel is harmless, including a banked one.
	if ritual_vessel_lit(index):
		return false
	actor_cooldowns[actor_id] = ACTOR_COMMAND_SECONDS
	if index != ritual_sequence[ritual_index]:
		ritual_index = ritual_bank
		ritual_hold = 0.0
		ember_owner = 0
		event_raised.emit("ritual_error", {"actor_id": actor_id, "vessel": index, "progress": ritual_index, "bank": ritual_bank, "ember_released": true})
		return false
	ritual_index += 1
	if ritual_index == 2 or ritual_index == 4:
		ritual_bank = ritual_index
	event_raised.emit("ritual_vessel", {"actor_id": actor_id, "vessel": index, "progress": ritual_index, "bank": ritual_bank, "required": 5})
	if ritual_index == 5:
		ember_owner = 0
		event_raised.emit("ritual_ready", {"actor_id": actor_id, "hold_seconds": RITUAL_HOLD_SECONDS})
	return true


func charge_ritual(delta: float, occupied: bool) -> void:
	if not _can_act("echoes", "ritual") or not _valid_delta(delta) or ritual_index != 5:
		return
	if not occupied:
		ritual_hold = 0.0
		return
	ritual_hold = minf(RITUAL_HOLD_SECONDS, ritual_hold + delta)
	if ritual_hold + EPSILON >= RITUAL_HOLD_SECONDS:
		ritual_hold = RITUAL_HOLD_SECONDS
		_complete("echoes", "ritual")


func turn_clock(lever: int, direction: int) -> bool:
	if not _clock_ready() or lever < 0 or lever >= 3 or direction not in [-1, 1]:
		return false
	var state: Vector3i = _clock_after(_clock_vector(clock_hands), lever, direction)
	clock_hands.assign([state.x, state.y, state.z])
	clock_moves += 1
	clock_cooldown = CLOCK_COMMAND_SECONDS
	event_raised.emit("clock_turn", {"lever": lever, "direction": direction, "hands": clock_hands.duplicate(), "moves": clock_moves})
	return true


func reset_clock() -> bool:
	if not _clock_ready():
		return false
	clock_hands.assign(clock_start)
	clock_moves = 0
	clock_cooldown = CLOCK_COMMAND_SECONDS
	event_raised.emit("clock_reset", {"hands": clock_hands.duplicate()})
	return true


func confirm_clock() -> bool:
	if not _clock_ready():
		return false
	clock_cooldown = CLOCK_COMMAND_SECONDS
	if clock_hands != clock_target:
		event_raised.emit("clock_error", {"hands": clock_hands.duplicate()})
		return false
	_complete("relay", "clock")
	return true


func clock_solution() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if trial_for_slot("relay") != "clock" or bool(completed["relay"]):
		return result
	var start: Vector3i = _clock_vector(clock_hands)
	var target: Vector3i = _clock_vector(clock_target)
	if start == target:
		return result
	if start == _solution_from:
		return _solution_cache.duplicate()
	var queue: Array[Vector3i] = [start]
	var visited: Dictionary = {start: true}
	var previous: Dictionary = {}
	var moves: Dictionary = {}
	var cursor: int = 0
	while cursor < queue.size() and not visited.has(target):
		var current: Vector3i = queue[cursor]
		cursor += 1
		for lever: int in range(3):
			for direction: int in [1, -1]:
				var next: Vector3i = _clock_after(current, lever, direction)
				if visited.has(next):
					continue
				visited[next] = true
				previous[next] = current
				moves[next] = Vector2i(lever, direction)
				queue.append(next)
	if not visited.has(target):
		return result
	var current: Vector3i = target
	while current != start:
		result.append(moves[current])
		current = previous[current]
	result.reverse()
	_solution_from = start
	_solution_cache = result.duplicate()
	return result


func _can_act(slot: String, trial_id: String) -> bool:
	return live and trial_for_slot(slot) == trial_id and not bool(completed[slot])


func _on_third_event(kind: String, payload: Dictionary) -> void:
	event_raised.emit(kind, payload)


func _on_third_completed(slot: String, trial_id: String) -> void:
	if _can_act(slot, trial_id) and bool(third.completed[slot]):
		_complete(slot, trial_id)


func _actor_ready(actor_id: int) -> bool:
	return actor_id > 0 and float(actor_cooldowns.get(actor_id, 0.0)) <= EPSILON


func _clock_ready() -> bool:
	return _can_act("relay", "clock") and clock_cooldown <= EPSILON


func _complete(slot: String, trial_id: String) -> void:
	if bool(completed[slot]):
		return
	completed[slot] = true
	event_raised.emit("trial_complete", {"slot": slot, "trial": trial_id})
	trial_completed.emit(slot, trial_id)


func _valid_delta(delta: float) -> bool:
	return is_finite(delta) and delta > 0.0


func _permutation(count: int, random: RandomNumberGenerator) -> Array[int]:
	var values: Array[int] = []
	for index: int in range(count):
		values.append(index)
	for index: int in range(count - 1, 0, -1):
		var other: int = random.randi_range(0, index)
		var temporary: int = values[index]
		values[index] = values[other]
		values[other] = temporary
	return values


func _clock_vector(values: Array[int]) -> Vector3i:
	return Vector3i(values[0], values[1], values[2])


func _clock_distant_starts(target: Vector3i) -> Array[Vector3i]:
	var candidates: Array[Vector3i] = []
	var queue: Array[Vector3i] = [target]
	var distances: Dictionary = {target: 0}
	var cursor: int = 0
	# Three hands with six positions bound this to at most 216 visited states.
	# The present coupled gear system reaches 108; 48 have shortest distance 4.
	while cursor < queue.size():
		var current: Vector3i = queue[cursor]
		var depth: int = int(distances[current])
		cursor += 1
		if depth >= CLOCK_MIN_SOLUTION_TURNS:
			candidates.append(current)
			continue
		for lever: int in range(3):
			for direction: int in [1, -1]:
				var next: Vector3i = _clock_after(current, lever, direction)
				if distances.has(next):
					continue
				distances[next] = depth + 1
				queue.append(next)
	return candidates


func _clock_after(state: Vector3i, lever: int, direction: int) -> Vector3i:
	var change: Vector3i = CLOCK_TRANSFORMS[lever] * direction
	return Vector3i(posmod(state.x + change.x, CLOCK_STEPS), posmod(state.y + change.y, CLOCK_STEPS), posmod(state.z + change.z, CLOCK_STEPS))
