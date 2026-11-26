class_name ThirdTrials
extends RefCounted
## Rendering-independent rules for the Third Observance. The world supplies
## actual life, range, visibility, refuge, motion and held-input eligibility.

signal event_raised(kind: String, payload: Dictionary)
signal trial_completed(slot: String, trial_id: String)

const LIGHT_CAPACITY: float = 100.0
const LIGHT_DRAIN_PER_SECOND: float = 4.0
const LIGHT_RECHARGE_PER_SECOND: float = 12.0
const LIGHT_HOLD_SECONDS: float = 2.0
const STRINGS_HOLD_SECONDS: float = 2.0
const STRINGS_CATCH_SECONDS: float = 3.0
const CHIMES_COMMAND_SECONDS: float = 0.45
const DAMPER_COMMAND_SECONDS: float = 0.5
const SHAPE_NAMES: Array[String] = ["Circle", "Crescent", "Triangle", "Diamond"]
const EPSILON: float = 0.000001

var live: bool = false
var slot_trials: Dictionary = {}
var completed: Dictionary = {"silent": false, "echoes": false, "relay": false}
## A weak-owner callable installed by TrialSet also rejects legacy cargo.
var cargo_admission: Callable
var light_cells: Dictionary = {}
var light_lit: Array[bool] = [false, false, false]
var light_charge: Dictionary = {}
var light_holds: Dictionary = {}
var strings_stage: int = 0
var strings_layout: Array[int] = []
var strings_half: int = 0
var strings_curved: bool = true
var strings_cooldown: float = 0.0
var strings_holds: Dictionary = {}
var chimes_phrase: int = 0
var chimes_index: int = 0
var chimes_sequences: Array = []
var chimes_cooldown: float = 0.0
var damper: int = -1
var damper_cooldown: float = 0.0

var _strings_rounds: Array[Dictionary] = []
var _strings_release_required: Dictionary = {}


func configure(seed_value: int, mapping: Dictionary) -> void:
	live = false
	slot_trials = mapping.duplicate()
	completed = {"silent": false, "echoes": false, "relay": false}
	light_cells.clear()
	light_lit.assign([false, false, false])
	light_charge.clear()
	light_holds.clear()
	strings_stage = 0
	strings_cooldown = 0.0
	strings_holds.clear()
	_strings_release_required.clear()
	_strings_rounds.clear()
	var strings_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	strings_rng.seed = seed_value ^ 0x535452494E47
	for unused: int in range(3):
		var curved: Array[int] = [0, 1]
		var angular: Array[int] = [2, 3]
		if strings_rng.randi_range(0, 1) == 1:
			curved.reverse()
		if strings_rng.randi_range(0, 1) == 1:
			angular.reverse()
		var layout: Array[int] = []
		for half: int in range(2):
			if strings_rng.randi_range(0, 1) == 0:
				layout.append(curved[half])
				layout.append(angular[half])
			else:
				layout.append(angular[half])
				layout.append(curved[half])
		_strings_rounds.append({"layout": layout, "half": strings_rng.randi_range(0, 1), "curved": strings_rng.randi_range(0, 1) == 1})
	_load_strings_round()
	chimes_phrase = 0
	chimes_index = 0
	chimes_cooldown = 0.0
	damper = -1
	damper_cooldown = 0.0
	chimes_sequences.clear()
	var chimes_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	chimes_rng.seed = seed_value ^ 0x4348494D4553
	for unused: int in range(2):
		var phrase: Array[int] = [0, 1, 2, 3]
		for index: int in range(3, 0, -1):
			var other: int = chimes_rng.randi_range(0, index)
			var held: int = phrase[index]
			phrase[index] = phrase[other]
			phrase[other] = held
		chimes_sequences.append(phrase)
	# Two different phrases teach the bank without adding an unbounded retry loop.
	if chimes_sequences[0] == chimes_sequences[1]:
		var first: int = int(chimes_sequences[1].pop_front())
		chimes_sequences[1].append(first)


func set_live(value: bool) -> void:
	live = value
	if not value:
		interrupt_all()


func step(delta: float) -> void:
	if not live or not _valid_delta(delta):
		return
	strings_cooldown = maxf(0.0, strings_cooldown - delta)
	chimes_cooldown = maxf(0.0, chimes_cooldown - delta)
	damper_cooldown = maxf(0.0, damper_cooldown - delta)


func progress_for_slot(slot: String) -> float:
	if bool(completed.get(slot, false)):
		return 1.0
	match str(slot_trials.get(slot, "")):
		"light":
			return float(light_lit.count(true)) / 3.0
		"strings":
			return float(strings_stage) / 3.0
		"chimes":
			return float(chimes_phrase * 4 + chimes_index) / 8.0
	return 0.0


func charge_for(actor_id: int) -> float:
	return float(light_charge.get(actor_id, LIGHT_CAPACITY)) if actor_id > 0 else 0.0


func carried_cell(actor_id: int) -> int:
	return int(light_cells.get(actor_id, -1))


func cell_available(cell: int) -> bool:
	return cell >= 0 and cell < 3 and not light_lit[cell] and not light_cells.values().has(cell)


func pickup_cell(actor_id: int, cell: int) -> bool:
	if not _can_act("silent", "light") or actor_id <= 0 or carried_cell(actor_id) >= 0 or not cell_available(cell):
		return false
	if cargo_admission.is_valid() and not bool(cargo_admission.call(actor_id)):
		return false
	light_cells[actor_id] = cell
	light_charge[actor_id] = charge_for(actor_id)
	event_raised.emit("light_pickup", {"actor_id": actor_id, "cell": cell})
	return true


func update_light_charge(actor_id: int, delta: float, in_refuge: bool) -> float:
	var previous: float = charge_for(actor_id)
	if not _can_act("silent", "light") or actor_id <= 0 or not _valid_delta(delta):
		return previous
	var next: float = previous
	if in_refuge:
		next = minf(LIGHT_CAPACITY, previous + LIGHT_RECHARGE_PER_SECOND * delta)
	elif carried_cell(actor_id) >= 0:
		next = maxf(0.0, previous - LIGHT_DRAIN_PER_SECOND * delta)
	light_charge[actor_id] = next
	if previous > EPSILON and next <= EPSILON:
		light_holds.erase(actor_id)
		event_raised.emit("light_depleted", {"actor_id": actor_id, "cell": carried_cell(actor_id)})
	return next


func update_light_hold(actor_id: int, lamp: int, delta: float, valid: bool) -> bool:
	if not _can_act("silent", "light") or actor_id <= 0 or not _valid_delta(delta):
		return false
	if not valid or lamp < 0 or lamp >= 3 or light_lit[lamp] or carried_cell(actor_id) != lamp or charge_for(actor_id) <= EPSILON:
		light_holds.erase(actor_id)
		return false
	var hold: Dictionary = light_holds.get(actor_id, {"index": lamp, "progress": 0.0})
	if int(hold.index) != lamp:
		hold = {"index": lamp, "progress": 0.0}
	hold.progress = minf(LIGHT_HOLD_SECONDS, float(hold.progress) + delta)
	light_holds[actor_id] = hold
	if float(hold.progress) + EPSILON < LIGHT_HOLD_SECONDS:
		return false
	light_lit[lamp] = true
	light_cells.erase(actor_id)
	light_holds.erase(actor_id)
	event_raised.emit("light_deposit", {"actor_id": actor_id, "cell": lamp, "lamp": lamp, "lit": light_lit.count(true), "required": 3})
	if not light_lit.has(false):
		_complete("silent", "light")
	return true


func strings_answer() -> int:
	if strings_stage >= 3:
		return -1
	for rope: int in range(strings_half * 2, strings_half * 2 + 2):
		if (strings_layout[rope] < 2) == strings_curved:
			return rope
	return -1


func strings_clue() -> String:
	if strings_stage >= 3:
		return "All three safety catches are locked open."
	return "In the %s pair, cut the %s shape." % ["LEFT" if strings_half == 0 else "RIGHT", "CURVED" if strings_curved else "ANGULAR"]


func update_strings_hold(actor_id: int, rope: int, delta: float, valid: bool) -> bool:
	if not _can_act("echoes", "strings") or actor_id <= 0 or not _valid_delta(delta):
		return false
	if not valid:
		strings_holds.erase(actor_id)
		_strings_release_required.erase(actor_id)
		return false
	if rope < 0 or rope >= 4 or strings_cooldown > EPSILON or _strings_release_required.has(actor_id):
		strings_holds.erase(actor_id)
		return false
	var hold: Dictionary = strings_holds.get(actor_id, {"index": rope, "stage": strings_stage, "progress": 0.0})
	if int(hold.index) != rope or int(hold.stage) != strings_stage:
		hold = {"index": rope, "stage": strings_stage, "progress": 0.0}
	hold.progress = minf(STRINGS_HOLD_SECONDS, float(hold.progress) + delta)
	strings_holds[actor_id] = hold
	if float(hold.progress) + EPSILON < STRINGS_HOLD_SECONDS:
		return false
	# Cut resolution retires every accumulated hold before replacing the clue.
	# Held input must be released; two helpers cannot reuse the previous round.
	for id: int in strings_holds:
		_strings_release_required[id] = true
	strings_holds.clear()
	if rope != strings_answer():
		strings_cooldown = STRINGS_CATCH_SECONDS
		event_raised.emit("strings_error", {"actor_id": actor_id, "rope": rope, "stage": strings_stage, "cooldown": STRINGS_CATCH_SECONDS, "noise": 10.0})
		return false
	strings_stage += 1
	_load_strings_round()
	event_raised.emit("strings_cut", {"actor_id": actor_id, "rope": rope, "stage": strings_stage, "required": 3})
	if strings_stage >= 3:
		_complete("echoes", "strings")
	return true


func strike_bell(actor_id: int, bell: int) -> bool:
	if not _can_act("relay", "chimes") or actor_id <= 0 or bell < 0 or bell >= 4 or chimes_cooldown > EPSILON:
		return false
	chimes_cooldown = CHIMES_COMMAND_SECONDS
	var phrase: int = chimes_phrase
	if bell != int(chimes_sequences[chimes_phrase][chimes_index]):
		chimes_index = 0
		event_raised.emit("chime_error", {"actor_id": actor_id, "bell": bell, "phrase": phrase, "index": 0, "noise": 10.0, "damped": damper == bell})
		return false
	chimes_index += 1
	var banked: bool = chimes_index == 4
	if banked:
		chimes_phrase += 1
		chimes_index = 0
	event_raised.emit("chime_strike", {"actor_id": actor_id, "bell": bell, "phrase": phrase, "next_phrase": chimes_phrase, "index": chimes_index, "banked": banked, "noise": 1.0 if damper == bell else 6.0, "damped": damper == bell})
	if chimes_phrase >= 2:
		_complete("relay", "chimes")
	return true


func toggle_damper(actor_id: int, bell: int) -> bool:
	if not _can_act("relay", "chimes") or actor_id <= 0 or bell < 0 or bell >= 4 or damper_cooldown > EPSILON:
		return false
	damper = -1 if damper == bell else bell
	damper_cooldown = DAMPER_COMMAND_SECONDS
	event_raised.emit("damper", {"actor_id": actor_id, "bell": bell, "damper": damper})
	return true


func interrupt_actor(actor_id: int) -> void:
	light_holds.erase(actor_id)
	strings_holds.erase(actor_id)
	_strings_release_required.erase(actor_id)


func interrupt_all() -> void:
	light_holds.clear()
	strings_holds.clear()
	_strings_release_required.clear()


func release_actor(actor_id: int) -> Dictionary:
	var cell: int = carried_cell(actor_id)
	light_cells.erase(actor_id)
	interrupt_actor(actor_id)
	if cell >= 0:
		event_raised.emit("light_released", {"actor_id": actor_id, "cell": cell})
	return {"cell": cell}


func _load_strings_round() -> void:
	if strings_stage >= _strings_rounds.size():
		return
	var round_value: Dictionary = _strings_rounds[strings_stage]
	strings_layout.assign(round_value.layout)
	strings_half = int(round_value.half)
	strings_curved = bool(round_value.curved)


func _can_act(slot: String, trial_id: String) -> bool:
	return live and str(slot_trials.get(slot, "")) == trial_id and not bool(completed[slot])


func _complete(slot: String, trial_id: String) -> void:
	if not _can_act(slot, trial_id):
		return
	completed[slot] = true
	trial_completed.emit(slot, trial_id)


func _valid_delta(delta: float) -> bool:
	return is_finite(delta) and delta > 0.0
