extends SceneTree
## Domain invariants, independent clue checks and real Director composition.
const Rules = preload("res://scripts/third_trials.gd")
const SetRules = preload("res://scripts/trial_set.gd")
const Director = preload("res://scripts/trial_director.gd")
const ALL: Dictionary = {"silent": "light", "echoes": "strings", "relay": "chimes"}
var cases: int = 0
var assertions: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_configuration()
	_test_inactive_guards()
	_test_invalid_commands()
	_test_cell_ownership()
	_test_cross_cargo()
	_test_charge_budget()
	_test_depleted_charge()
	_test_matching_lamp()
	_test_light_interruption()
	_test_invalid_deltas()
	_test_light_completion()
	_test_release_lifecycle()
	_test_generated_clues()
	_test_strings_tick_boundary()
	_test_strings_safety_catch()
	_test_strings_release_boundary()
	_test_strings_competing_holds()
	_test_strings_target_change()
	_test_strings_cooldown()
	_test_chime_generation()
	_test_chime_rate_limit()
	_test_chime_bank()
	_test_damper_and_noise()
	_test_chime_completion()
	_test_invalid_bells()
	_test_interrupt_all()
	_test_result_freeze()
	_test_reconfigure()
	_test_determinism()
	_test_director_completion()
	_test_retired_child()
	print("ThirdTrials: %d cases, %d assertions, %d failures" % [cases, assertions, failures])
	quit(1 if failures > 0 else 0)


func _new(seed_value: int = 271126) -> Rules:
	var rules: Rules = Rules.new()
	rules.configure(seed_value, ALL)
	rules.set_live(true)
	return rules


func _check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)


func _near(actual: float, expected: float, message: String) -> void:
	_check(absf(actual - expected) < 0.00001, message)


func _events(rules: Rules) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	rules.event_raised.connect(func(kind: String, payload: Dictionary) -> void: events.append({"kind": kind, "payload": payload.duplicate(true)}))
	return events


func _completions(rules: Rules) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	rules.trial_completed.connect(func(slot: String, trial: String) -> void: events.append({"slot": slot, "trial": trial}))
	return events


func _solve_clue(rules: Rules) -> Array[int]:
	# Independent readable-clue interpretation, without calling production solver.
	var answers: Array[int] = []
	for rope: int in range(4):
		var on_required_side: bool = rope < 2 if rules.strings_half == 0 else rope >= 2
		var name_value: String = Rules.SHAPE_NAMES[rules.strings_layout[rope]]
		var is_curved: bool = name_value in ["Circle", "Crescent"]
		if on_required_side and is_curved == rules.strings_curved:
			answers.append(rope)
	return answers


func _finish_phrase(rules: Rules, actor_id: int = 1) -> void:
	var phrase: Array = rules.chimes_sequences[rules.chimes_phrase].duplicate()
	for bell: int in phrase:
		rules.strike_bell(actor_id, bell)
		rules.step(0.45)


func _test_configuration() -> void:
	cases += 1
	var rules: Rules = Rules.new()
	var mapping: Dictionary = ALL.duplicate()
	rules.configure(1, mapping)
	mapping.silent = "vault"
	_check(not rules.live and rules.slot_trials == ALL, "configuration copies selection and starts inactive")
	_check(rules.light_lit == [false, false, false] and rules.light_cells.is_empty(), "three unique cells begin unbanked and unowned")
	_check(rules.strings_stage == 0 and rules.strings_layout.size() == 4, "first rope stage exists at configuration")
	_check(rules.chimes_phrase == 0 and rules.chimes_index == 0 and rules.damper == -1, "chime bank, index and damper reset")
	_check(rules.progress_for_slot("unknown") == 0.0 and rules.charge_for(0) == 0.0, "invalid queries have no fabricated state")
	_check(rules.light_charge.is_empty(), "queries do not register fake owners")


func _test_inactive_guards() -> void:
	cases += 1
	var rules: Rules = Rules.new()
	rules.configure(3, ALL)
	_check(not rules.pickup_cell(1, 0) and not rules.update_strings_hold(1, 0, 2.0, true) and not rules.strike_bell(1, 0) and not rules.toggle_damper(1, 0), "preparation rejects all trial commands")
	rules.update_light_charge(1, 100, true)
	_check(rules.light_charge.is_empty(), "preparation does not mutate charge")
	rules.configure(3, {"silent": "silent", "echoes": "echoes", "relay": "relay"})
	rules.set_live(true)
	_check(not rules.pickup_cell(1, 0) and not rules.update_strings_hold(1, 0, 2, true) and not rules.strike_bell(1, 0) and not rules.toggle_damper(1, 0), "inactive apparatus cannot act")


func _test_invalid_commands() -> void:
	cases += 1
	var rules: Rules = _new()
	for id: int in [0, -5]:
		_check(not rules.pickup_cell(id, 0) and not rules.update_light_hold(id, 0, 2, true) and not rules.update_strings_hold(id, 0, 2, true), "nonpositive actors cannot own cells or holds")
		_check(not rules.strike_bell(id, 0) and not rules.toggle_damper(id, 0), "nonpositive actors cannot operate bells")
	for index: int in [-1, 3, 99]:
		_check(not rules.pickup_cell(1, index) and not rules.cell_available(index), "invalid cell indices reject")
	_check(rules.light_cells.is_empty() and rules.light_holds.is_empty() and rules.strings_holds.is_empty(), "invalid commands leave no reservations")


func _test_cell_ownership() -> void:
	cases += 1
	var rules: Rules = _new()
	_check(rules.pickup_cell(1, 0), "first actor claims cell")
	_check(not rules.pickup_cell(2, 0) and not rules.pickup_cell(1, 1), "cell and carrier each have unique ownership")
	_check(rules.pickup_cell(2, 1) and rules.carried_cell(1) == 0 and rules.carried_cell(2) == 1, "independent cells can travel in parallel")
	_check(not rules.cell_available(0) and rules.cell_available(2), "availability respects actual ownership")


func _test_cross_cargo() -> void:
	cases += 1
	var rules: SetRules = SetRules.new()
	for seed_value: int in range(256):
		rules.configure(seed_value, "mix")
		if rules.slot_trials.silent == "light" and rules.slot_trials.echoes == "ritual":
			break
	rules.set_live(true)
	_check(rules.slot_trials.silent == "light" and rules.slot_trials.echoes == "ritual", "mixed cell-and-ember fixture exists")
	_check(rules.take_ember(1) and not rules.third.pickup_cell(1, 0), "ember owner cannot gain cell through direct child authority")
	rules.release_actor(1)
	_check(rules.third.pickup_cell(1, 0) and not rules.take_ember(1), "cell owner cannot acquire legacy ember")
	var released: Dictionary = rules.release_actor(1)
	_check(released.get("cell", -1) == 0 and rules.third.cell_available(0), "TrialSet release reaches composed cell owner")
	_check(rules.take_ember(1), "release restores ordinary inventory admission")


func _test_charge_budget() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.update_light_charge(1, 50, false)
	_near(rules.charge_for(1), 100, "empty hands do not drain outside refuge")
	rules.pickup_cell(1, 0)
	rules.update_light_charge(1, 2.5, false)
	_near(rules.charge_for(1), 90, "carried cell drains four units per second")
	rules.update_light_charge(1, 0.5, true)
	_near(rules.charge_for(1), 96, "refuge recharges twelve units per second")
	rules.update_light_charge(1, 10, true)
	_near(rules.charge_for(1), 100, "charge is capped at capacity")
	rules.update_light_charge(1, 4, false)
	rules.release_actor(1)
	rules.pickup_cell(1, 1)
	_near(rules.charge_for(1), 84, "drop and repick cannot refill charge")


func _test_depleted_charge() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	rules.pickup_cell(1, 0)
	rules.update_light_hold(1, 0, 1, true)
	rules.update_light_charge(1, 30, false)
	rules.update_light_charge(1, 20, false)
	_check(rules.charge_for(1) == 0 and rules.light_holds.is_empty(), "depletion clamps at zero and interrupts alignment")
	_check(events.filter(func(e: Dictionary) -> bool: return e.kind == "light_depleted").size() == 1, "one depletion edge emits one warning")
	_check(not rules.update_light_hold(1, 0, 2, true) and rules.carried_cell(1) == 0, "depleted lamp cannot align but cargo remains recoverable")
	rules.update_light_charge(1, 1, true)
	_check(rules.update_light_hold(1, 0, 2, true), "refuge recovery restores alignment without a soft lock")


func _test_matching_lamp() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.pickup_cell(1, 2)
	_check(not rules.update_light_hold(1, 0, 5, true), "unique cell rejects wrong lamp")
	_check(not rules.update_light_hold(2, 2, 5, true), "non-owner cannot align another actor's cell")
	_check(rules.carried_cell(1) == 2 and rules.light_lit.count(true) == 0, "wrong target preserves cargo and banks")
	rules.update_light_hold(1, 2, 1.9, true)
	_check(not rules.light_lit[2], "alignment requires full interval")
	_check(rules.update_light_hold(1, 2, 0.1, true) and rules.light_lit[2], "matching lamp banks at two seconds")
	_check(rules.carried_cell(1) == -1 and not rules.cell_available(2), "bank consumes unique cell permanently")


func _test_light_interruption() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.pickup_cell(1, 0)
	rules.update_light_hold(1, 0, 1.9, true)
	rules.update_light_hold(1, 0, 0.1, false)
	_check(not rules.update_light_hold(1, 0, 0.1, true), "range, motion or release loss resets the entire hold")
	_near(float(rules.light_holds[1].progress), 0.1, "resumed hold starts fresh")
	rules.interrupt_actor(1)
	_check(rules.light_holds.is_empty() and rules.carried_cell(1) == 0, "damage interruption preserves held cell")


func _test_invalid_deltas() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.pickup_cell(1, 0)
	rules.update_light_hold(1, 0, 1, true)
	rules.update_strings_hold(2, rules.strings_answer(), 1, true)
	for delta: float in [0.0, -1.0, INF, NAN]:
		rules.update_light_charge(1, delta, false)
		rules.update_light_hold(1, 0, delta, false)
		rules.update_strings_hold(2, 0, delta, false)
		rules.step(delta)
	_near(rules.charge_for(1), 100, "invalid delta never corrupts charge")
	_near(float(rules.light_holds[1].progress), 1, "invalid hold delta cannot extend or erase alignment")
	_near(float(rules.strings_holds[2].progress), 1, "invalid hold delta cannot extend or erase cut")


func _test_light_completion() -> void:
	cases += 1
	var rules: Rules = _new()
	var completions: Array[Dictionary] = _completions(rules)
	for cell: int in [2, 0, 1]:
		_check(rules.pickup_cell(cell + 1, cell), "remaining unique cell can be claimed")
		_check(rules.update_light_hold(cell + 1, cell, 2, true), "independent lamp banks")
	_check(rules.completed.silent and rules.progress_for_slot("silent") == 1.0 and completions == [{"slot": "silent", "trial": "light"}], "three lamps complete once")
	_check(not rules.update_light_hold(1, 0, 2, true) and not rules.pickup_cell(1, 0), "completed light trial is immutable")


func _test_release_lifecycle() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.pickup_cell(1, 1)
	rules.update_light_charge(1, 5, false)
	rules.update_light_hold(1, 1, 1, true)
	rules.set_live(false)
	_check(rules.release_actor(1) == {"cell": 1} and rules.release_actor(1) == {"cell": -1}, "post-result release is idempotent")
	_check(rules.cell_available(1) and rules.light_holds.is_empty(), "lifecycle release restores reachable cell")
	_near(rules.charge_for(1), 80, "release retains charge until next match")
	_check(rules.light_lit.count(true) == 0, "cleanup cannot grant progress")


func _test_generated_clues() -> void:
	cases += 1
	var observed: Dictionary = {}
	for seed_value: int in range(128):
		var rules: Rules = _new(seed_value)
		for stage: int in range(3):
			var sorted: Array[int] = rules.strings_layout.duplicate()
			sorted.sort()
			var answers: Array[int] = _solve_clue(rules)
			_check(sorted == [0, 1, 2, 3] and answers.size() == 1, "seed %d stage %d has one evidence-supported solution and four exact shape IDs" % [seed_value, stage])
			_check(answers[0] == rules.strings_answer(), "readable-clue solver and authoritative acceptance agree")
			observed[str(rules.strings_layout) + rules.strings_clue()] = true
			_check(rules.update_strings_hold(1, answers[0], 2, true), "all generated stages accept their unique solution")
			rules.interrupt_actor(1)
		_check(rules.completed.echoes and rules.strings_answer() == -1, "all three banks finish without a fourth solution")
	_check(observed.size() > 20, "seeded rope evidence varies across fixtures")


func _test_strings_tick_boundary() -> void:
	cases += 1
	var rules: Rules = _new()
	var rope: int = rules.strings_answer()
	for unused: int in range(119):
		rules.update_strings_hold(1, rope, 1.0 / 60.0, true)
	_check(rules.strings_stage == 0, "119 physics frames cannot bank a cut")
	_check(rules.update_strings_hold(1, rope, 1.0 / 60.0, true) and rules.strings_stage == 1, "120 frames bank the exact two-second cut")


func _test_strings_safety_catch() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.update_strings_hold(1, rules.strings_answer(), 2, true)
	rules.interrupt_actor(1)
	var events: Array[Dictionary] = _events(rules)
	var wrong: int = (rules.strings_answer() + 1) % 4
	_check(not rules.update_strings_hold(1, wrong, 2, true), "wrong deliberate cut engages safety catch")
	_check(rules.strings_stage == 1 and rules.strings_cooldown == 3, "wrong cut preserves prior bank and starts three-second catch")
	_check(events[-1].kind == "strings_error" and events[-1].payload.noise == 10.0, "mistake exposes explicit bounded noise")
	rules.interrupt_actor(1)
	_check(not rules.update_strings_hold(2, rules.strings_answer(), 10, true), "another actor cannot bypass safety catch")
	rules.step(3)
	_check(rules.update_strings_hold(2, rules.strings_answer(), 2, true) and rules.strings_stage == 2, "catch recovers without losing bank")


func _test_strings_release_boundary() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.update_strings_hold(1, rules.strings_answer(), 2, true)
	_check(not rules.update_strings_hold(1, rules.strings_answer(), 2, true) and rules.strings_stage == 1, "held input cannot cut a second newly generated stage")
	rules.update_strings_hold(1, 0, 0.01, false)
	_check(rules.update_strings_hold(1, rules.strings_answer(), 2, true), "release admits a new deliberate stage action")


func _test_strings_competing_holds() -> void:
	cases += 1
	var rules: Rules = _new()
	var rope: int = rules.strings_answer()
	rules.update_strings_hold(1, rope, 1, true)
	rules.update_strings_hold(2, rope, 1.9, true)
	rules.update_strings_hold(1, rope, 1, true)
	_check(rules.strings_holds.is_empty() and rules.strings_stage == 1, "stage transition retires all partial old-stage holds")
	_check(not rules.update_strings_hold(2, rules.strings_answer(), 2, true), "second helper must release stale hold")
	rules.interrupt_actor(2)
	_check(not rules.update_strings_hold(2, rules.strings_answer(), 0.1, true), "old helper's 1.9 seconds cannot carry into new stage")


func _test_strings_target_change() -> void:
	cases += 1
	var rules: Rules = _new()
	var answer: int = rules.strings_answer()
	rules.update_strings_hold(1, (answer + 1) % 4, 1.9, true)
	rules.update_strings_hold(1, answer, 0.1, true)
	_near(float(rules.strings_holds[1].progress), 0.1, "changing rope starts fresh commitment")
	rules.update_strings_hold(1, -1, 0.1, true)
	_check(rules.strings_holds.is_empty(), "invalid target clears actionable hold")


func _test_strings_cooldown() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.update_strings_hold(1, (rules.strings_answer() + 1) % 4, 2, true)
	for delta: float in [NAN, INF, 0.0, -1.0]:
		rules.step(delta)
	_near(rules.strings_cooldown, 3, "invalid deltas cannot pay catch cooldown")
	rules.step(2.99)
	rules.interrupt_actor(1)
	_check(not rules.update_strings_hold(1, rules.strings_answer(), 2, true), "cut remains blocked before catch deadline")
	rules.step(0.01)
	_check(rules.update_strings_hold(1, rules.strings_answer(), 2, true), "cut admitted at exact catch deadline")


func _test_chime_generation() -> void:
	cases += 1
	for seed_value: int in range(128):
		var rules: Rules = _new(seed_value)
		for phrase: Array in rules.chimes_sequences:
			var sorted: Array = phrase.duplicate()
			sorted.sort()
			_check(sorted == [0, 1, 2, 3], "each phrase demonstrates every distinct physical bell once")
		_check(rules.chimes_sequences[0] != rules.chimes_sequences[1], "second phrase is visibly different from first")


func _test_chime_rate_limit() -> void:
	cases += 1
	var rules: Rules = _new()
	_check(rules.strike_bell(1, rules.chimes_sequences[0][0]), "first correct bell advances")
	_check(not rules.strike_bell(2, rules.chimes_sequences[0][1]), "another actor cannot bypass global bell interval")
	rules.step(0.44)
	_check(not rules.strike_bell(1, rules.chimes_sequences[0][1]), "bell blocked before interval")
	rules.step(0.01)
	_check(rules.strike_bell(2, rules.chimes_sequences[0][1]) and rules.chimes_index == 2, "bell accepted at exact interval")


func _test_chime_bank() -> void:
	cases += 1
	var rules: Rules = _new()
	_finish_phrase(rules)
	_check(rules.chimes_phrase == 1 and rules.chimes_index == 0 and rules.progress_for_slot("relay") == 0.5, "first phrase is a permanent half-way bank")
	rules.strike_bell(1, rules.chimes_sequences[1][0])
	rules.step(0.45)
	var wrong: int = (int(rules.chimes_sequences[1][1]) + 1) % 4
	_check(not rules.strike_bell(1, wrong), "wrong valid bell rejects")
	_check(rules.chimes_phrase == 1 and rules.chimes_index == 0, "mistake resets only current phrase")
	_check(rules.chimes_cooldown == 0.45, "wrong strike consumes anti-spam interval")


func _test_damper_and_noise() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	var first: int = int(rules.chimes_sequences[0][0])
	_check(rules.toggle_damper(1, first), "damper can be attached")
	_check(not rules.toggle_damper(2, (first + 1) % 4), "damper has shared anti-spam interval")
	rules.strike_bell(1, first)
	_check(events[-1].kind == "chime_strike" and events[-1].payload.noise == 1.0, "damped correct note produces one noise unit")
	rules.step(0.5)
	var second: int = int(rules.chimes_sequences[0][1])
	rules.strike_bell(2, second)
	_check(events[-1].payload.noise == 6.0, "undamped correct note produces six noise units")
	rules.step(0.5)
	var wrong: int = (int(rules.chimes_sequences[0][2]) + 1) % 4
	rules.toggle_damper(1, wrong)
	_check(rules.damper == wrong, "moving damper leaves exactly one selected bell")
	rules.strike_bell(1, wrong)
	_check(events[-1].kind == "chime_error" and events[-1].payload.noise == 10.0 and events[-1].payload.damped, "wrong damped strike still produces ten units as stated")
	rules.step(0.5)
	rules.toggle_damper(1, wrong)
	_check(rules.damper == -1, "same-bell toggle removes damper")


func _test_chime_completion() -> void:
	cases += 1
	var rules: Rules = _new()
	var completions: Array[Dictionary] = _completions(rules)
	_finish_phrase(rules)
	_finish_phrase(rules)
	_check(rules.chimes_phrase == 2 and rules.completed.relay and rules.progress_for_slot("relay") == 1.0, "eight accepted notes complete two phrases")
	_check(completions == [{"slot": "relay", "trial": "chimes"}], "chime completion fires exactly once")
	_check(not rules.strike_bell(1, 0) and not rules.toggle_damper(1, 0), "completed chimes cannot ring or move damper")


func _test_invalid_bells() -> void:
	cases += 1
	var rules: Rules = _new()
	for bell: int in [-1, 4, 99]:
		_check(not rules.strike_bell(1, bell) and not rules.toggle_damper(1, bell), "invalid bell identity rejected")
	_check(rules.chimes_cooldown == 0 and rules.damper_cooldown == 0 and rules.chimes_index == 0, "invalid targets consume no valid gameplay state")


func _test_interrupt_all() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.pickup_cell(1, 0)
	rules.update_light_hold(1, 0, 1.9, true)
	rules.update_strings_hold(2, rules.strings_answer(), 1.9, true)
	rules.interrupt_all()
	_check(rules.light_holds.is_empty() and rules.strings_holds.is_empty(), "pause interrupts all partial holds")
	_check(rules.carried_cell(1) == 0 and rules.strings_stage == 0, "pause keeps cargo and banked state")
	_check(not rules.update_light_hold(1, 0, 0.1, true) and not rules.update_strings_hold(2, rules.strings_answer(), 0.1, true), "resume cannot finish interrupted nearly-complete holds")


func _test_result_freeze() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.pickup_cell(1, 0)
	rules.strike_bell(1, rules.chimes_sequences[0][0])
	rules.toggle_damper(1, 0)
	rules.set_live(false)
	var charge: float = rules.charge_for(1)
	var cooldown: float = rules.chimes_cooldown
	rules.step(100)
	rules.update_light_charge(1, 100, false)
	_check(not rules.update_light_hold(1, 0, 2, true) and not rules.update_strings_hold(1, rules.strings_answer(), 2, true) and not rules.strike_bell(1, 0), "ended authority rejects late actions")
	_check(rules.charge_for(1) == charge and rules.chimes_cooldown == cooldown and rules.chimes_index == 1, "result freezes resource, cooldown and phrase progress")


func _test_reconfigure() -> void:
	cases += 1
	var rules: Rules = _new()
	var phrases: Array = rules.chimes_sequences.duplicate(true)
	var layout: Array[int] = rules.strings_layout.duplicate()
	rules.pickup_cell(1, 0)
	rules.update_light_charge(1, 10, false)
	rules.update_light_hold(1, 0, 2, true)
	rules.update_strings_hold(1, rules.strings_answer(), 2, true)
	_finish_phrase(rules)
	rules.toggle_damper(1, 0)
	rules.configure(271126, ALL)
	_check(not rules.live and rules.completed.values().count(true) == 0 and rules.light_lit.count(true) == 0, "new match starts inactive with no inherited seals")
	_check(rules.light_cells.is_empty() and rules.light_charge.is_empty() and rules.light_holds.is_empty() and rules.strings_holds.is_empty(), "new match removes all actor ownership and partial progress")
	_check(rules.strings_stage == 0 and rules.strings_layout == layout and rules.chimes_sequences == phrases and rules.chimes_phrase == 0 and rules.damper == -1, "same seed restores puzzle, banks and controls")


func _test_determinism() -> void:
	cases += 1
	var first: SetRules = SetRules.new()
	var second: SetRules = SetRules.new()
	first.configure(2112, "third")
	second.configure(2112, "mix")
	_check(first.third.chimes_sequences == second.third.chimes_sequences and first.third.strings_layout == second.third.strings_layout and first.third.strings_clue() == second.third.strings_clue(), "trial seed streams do not depend on contract selection")
	_check(first.vault_targets == second.vault_targets and first.clock_start == second.clock_start and first.ritual_sequence == second.ritual_sequence, "adding third trials does not perturb existing puzzle streams")
	_check(first.slot_trials == ALL and first.contract == "third", "Third selects new subsets in declared slots")


func _test_director_completion() -> void:
	cases += 1
	var director: Director = Director.new()
	var events: Array[String] = []
	director.event_raised.connect(func(kind: String, _payload: Dictionary) -> void: events.append(kind))
	director.configure("survivor", "story", 271126, 1, "third")
	director.step(8)
	var rules: Rules = director.trial_set.third
	for cell: int in range(3):
		rules.pickup_cell(cell + 1, cell)
		rules.update_light_hold(cell + 1, cell, 2, true)
	for unused: int in range(3):
		rules.update_strings_hold(1, _solve_clue(rules)[0], 2, true)
		rules.interrupt_actor(1)
	_finish_phrase(rules)
	_finish_phrase(rules)
	_check(director.phase == "escape" and director.seals.values().count(true) == 3, "three child completions open real Director escape")
	_check(events.count("trial_complete") == 3, "child forwarding emits one public completion per trial")
	director.register_escape()
	_check(director.winner == "survivors" and not rules.live, "ordinary escape wins and freezes child authority")


func _test_retired_child() -> void:
	cases += 1
	var parent: SetRules = SetRules.new()
	parent.configure(1, "third")
	parent.set_live(true)
	var old: Rules = parent.third
	old.pickup_cell(1, 0)
	parent.configure(2, "first")
	_check(not old.live and old != parent.third and not parent.third.live, "reconfigure retires prior child rather than resetting referenced object")
	_check(not old.update_light_hold(1, 0, 2, true) and parent.completed.values().count(true) == 0, "stale old-world command cannot complete new match")
	_check(not old.event_raised.is_connected(parent._on_third_event) and not old.trial_completed.is_connected(parent._on_third_completed), "retired child has no event path into new match")
