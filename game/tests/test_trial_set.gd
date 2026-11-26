extends SceneTree
## Domain regression checks for the six-trial selection and Second Observance.
const Rules = preload("res://scripts/trial_set.gd")
const Director = preload("res://scripts/trial_director.gd")
var assertions: int = 0
var cases: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_contracts()
	_test_determinism()
	_test_mix_coverage()
	_test_generated_content()
	_test_inactive_and_preparation()
	_test_invalid_commands()
	_test_unique_ownership()
	_test_cargo_exclusion()
	_test_wrong_deposit_and_rate_limit()
	_test_vault_banks_and_completion()
	_test_release_lifecycle()
	_test_ritual_checkpoints()
	_test_ritual_errors_and_duplicate_input()
	_test_ritual_hold()
	_test_clock_inverse_and_bounds()
	_test_clock_rate_limit_and_reset()
	_test_clock_solvability()
	_test_solver_is_read_only()
	_test_director_selected_actions()
	_test_director_timeout_freezes_trials()
	_test_all_mixed_completions()
	_test_reconfigure()
	_test_director_reconfigure_retires_old_authority()
	print("TrialSet: %d cases, %d assertions, %d failures" % [cases, assertions, failures])
	quit(1 if failures > 0 else 0)


func _new(contract: String = "second", seed_value: int = 271126) -> Rules:
	var rules: Rules = Rules.new()
	rules.configure(seed_value, contract)
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
	var recorded: Array[Dictionary] = []
	rules.event_raised.connect(func(kind: String, payload: Dictionary) -> void:
		recorded.append({"kind": kind, "payload": payload.duplicate(true)})
	)
	return recorded


func _mapping_key(rules: Rules) -> String:
	return "%s/%s/%s" % [rules.trial_for_slot("silent"), rules.trial_for_slot("echoes"), rules.trial_for_slot("relay")]


func _light_all(rules: Rules, actor: int = 1) -> void:
	rules.take_ember(actor)
	for vessel: int in rules.ritual_sequence:
		rules.light_vessel(actor, vessel)
		rules.step(0.35)


func _test_contracts() -> void:
	cases += 1
	_check(_mapping_key(_new("first")) == "silent/echoes/relay", "First retains original trials")
	_check(_mapping_key(_new("second")) == "vault/ritual/clock", "Second selects all three alternates")
	_check(_mapping_key(_new("third")) == "light/strings/chimes", "Third selects all three new subsets")
	_check(_mapping_key(_new("invalid")) == "silent/echoes/relay", "invalid contract safely defaults to First")
	_check(_new("SECOND").contract == "second", "contract matching is case insensitive")
	_check(_new().trial_for_slot("invalid").is_empty(), "unknown slot has no trial")


func _test_determinism() -> void:
	cases += 1
	var first: Rules = _new("mix", 1701)
	var second: Rules = _new("mix", 1701)
	_check(first.slot_trials == second.slot_trials, "same seed reproduces mixed choices")
	_check(first.vault_targets == second.vault_targets and first.ritual_sequence == second.ritual_sequence, "same seed reproduces memory and ritual puzzles")
	_check(first.clock_hands == second.clock_hands and first.clock_target == second.clock_target, "same seed reproduces clock puzzle")
	second.configure(1701, "second")
	_check(first.vault_targets == second.vault_targets and first.ritual_sequence == second.ritual_sequence and first.clock_start == second.clock_start, "trial puzzle does not change when contract changes")
	var original: Director = Director.new()
	var alternate: Director = Director.new()
	original.configure("survivor", "standard", 1701)
	alternate.configure("survivor", "standard", 1701, 1, "mix")
	_check(original.echo_sequence == alternate.echo_sequence, "new selection has no effect on original Echo RNG")


func _test_mix_coverage() -> void:
	cases += 1
	var seen: Dictionary = {}
	for seed_value: int in range(256):
		var rules: Rules = _new("mix", seed_value)
		seen[_mapping_key(rules)] = true
		for slot: String in Rules.SLOT_VARIANTS:
			_check(Rules.SLOT_VARIANTS[slot].has(rules.trial_for_slot(slot)), "mixed selection stays in its assigned bay")
	_check(seen.size() == 27, "seeded selection reaches all twenty-seven bay combinations")


func _test_generated_content() -> void:
	cases += 1
	var rules: Rules = _new()
	var unique: Dictionary = {}
	for relic: int in rules.vault_targets:
		unique[relic] = true
		_check(relic >= 0 and relic < 6, "vault target is a real relic ID")
	_check(unique.size() == 4 and rules.vault_cradles == [-1, -1, -1, -1], "four unique targets start with four empty cradles")
	var sequence: Array[int] = rules.ritual_sequence.duplicate()
	sequence.sort()
	_check(sequence == [0, 1, 2, 3, 4], "ritual uses each vessel exactly once")
	_check(rules.clock_start != rules.clock_target, "clock never starts already solved")
	_check(Rules.RELIC_NAMES == ["Orb", "Spire", "Cube", "Ring", "Crown", "Diamond"], "relic IDs match physical visual names")


func _test_inactive_and_preparation() -> void:
	cases += 1
	var rules: Rules = _new("first")
	_check(not rules.pickup_relic(1, 0) and not rules.take_ember(1) and not rules.turn_clock(0, 1), "unselected alternate apparatus cannot advance")
	rules.configure(1, "second")
	_check(not rules.live, "configure starts trials inactive during preparation")
	_check(not rules.pickup_relic(1, 0) and not rules.take_ember(1) and not rules.turn_clock(0, 1), "preparation rejects all alternate commands")
	var director: Director = Director.new()
	director.configure("eye", "standard", 1, 4, "second")
	director.step(7.99)
	_check(not director.trial_set.live, "director keeps alternate trials inactive through grace")
	director.step(0.01)
	_check(director.trial_set.live, "hunt transition activates alternate trials")


func _test_invalid_commands() -> void:
	cases += 1
	var rules: Rules = _new()
	_check(not rules.pickup_relic(0, 0) and not rules.pickup_relic(-1, 0), "invalid actor IDs cannot own relics")
	_check(not rules.pickup_relic(1, -1) and not rules.pickup_relic(1, 6), "out of range relic IDs reject")
	_check(not rules.deposit_relic(1, -1) and not rules.deposit_relic(1, 4), "invalid cradles reject")
	_check(not rules.take_ember(0) and not rules.light_vessel(1, -1) and not rules.light_vessel(1, 5), "invalid ritual input rejects")
	_check(not rules.turn_clock(-1, 1) and not rules.turn_clock(3, 1) and not rules.turn_clock(0, 0) and not rules.turn_clock(0, 2), "invalid lever and direction reject")
	var start: Array[int] = rules.clock_hands.duplicate()
	rules.turn_clock(0, 1)
	for invalid: float in [-1.0, 0.0, INF, NAN]:
		rules.step(invalid)
	_near(rules.clock_cooldown, 0.25, "invalid time cannot bypass command cooldown")
	_check(rules.clock_hands != start, "valid clock command still functions after rejected inputs")


func _test_unique_ownership() -> void:
	cases += 1
	var rules: Rules = _new()
	_check(rules.pickup_relic(11, 0), "available relic can be picked up")
	_check(not rules.pickup_relic(12, 0), "two actors cannot own one relic")
	_check(not rules.pickup_relic(11, 1), "one actor cannot carry two relics")
	_check(rules.carried_relic(11) == 0 and rules.carried_relic(12) == -1, "ownership query returns exact holder")
	_check(not rules.relic_available(0) and rules.relic_available(1), "availability excludes carried relic")


func _test_cargo_exclusion() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.pickup_relic(1, 0)
	_check(not rules.take_ember(1), "relic carrier cannot also take ember")
	rules.release_actor(1)
	_check(rules.take_ember(1), "free-handed actor can take ember")
	_check(not rules.take_ember(2) and not rules.pickup_relic(1, 0), "ember has one owner and excludes relic cargo")
	_check(not rules.light_vessel(2, rules.ritual_sequence[0]), "non-owner cannot light vessels")


func _test_wrong_deposit_and_rate_limit() -> void:
	cases += 1
	var rules: Rules = _new()
	var target: int = rules.vault_targets[0]
	rules.pickup_relic(1, target)
	_check(not rules.deposit_relic(1, 1), "correct object in the wrong cradle rejects")
	_check(rules.carried_relic(1) == target and rules.vault_cradles == [-1, -1, -1, -1], "wrong deposit retains cargo and leaves all banks untouched")
	_check(not rules.deposit_relic(1, 0), "wrong attempt has bounded per-actor cooldown")
	rules.step(0.34)
	_check(not rules.deposit_relic(1, 0), "deposit remains blocked before cooldown boundary")
	rules.step(0.01)
	_check(rules.deposit_relic(1, 0), "correct deposit works at cooldown boundary")
	_check(rules.carried_relic(1) == -1 and rules.vault_cradles[0] == target, "accepted deposit consumes ownership and locks exact ID")


func _test_vault_banks_and_completion() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	for cradle: int in [2, 0, 3, 1]:
		var target: int = rules.vault_targets[cradle]
		_check(rules.pickup_relic(cradle + 1, target), "unique target remains obtainable")
		_check(rules.deposit_relic(cradle + 1, cradle), "cradles accept their targets independently of visit order")
		_check(not rules.relic_available(target), "banked relic cannot re-enter inventory")
	_check(bool(rules.completed.silent) and rules.progress_for_slot("silent") == 1.0, "four cradles complete Vault")
	_check(not rules.pickup_relic(8, 0) and not rules.deposit_relic(1, 0), "completed Vault rejects further input")
	_check(events.filter(func(event: Dictionary) -> bool: return event.kind == "trial_complete").size() == 1, "Vault emits one completion")


func _test_release_lifecycle() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.pickup_relic(1, 2)
	rules.take_ember(2)
	rules.set_live(false)
	var relic: Dictionary = rules.release_actor(1)
	var ember: Dictionary = rules.release_actor(2)
	_check(relic.relic == 2 and not relic.ember and rules.relic_available(2), "post-result cleanup releases recoverable relic identity")
	_check(ember.relic == -1 and ember.ember and rules.ember_owner == 0, "post-result cleanup releases shared ember")
	_check(rules.release_actor(1) == {"relic": -1, "ember": false}, "repeated cleanup is idempotent")
	_check(rules.completed.values().count(true) == 0, "cleanup cannot grant progress")


func _test_ritual_checkpoints() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.take_ember(1)
	for index: int in range(3):
		_check(rules.light_vessel(1, rules.ritual_sequence[index]), "correct vessel advances sequence")
		rules.step(0.35)
	_check(rules.ritual_index == 3 and rules.ritual_bank == 2, "first pair is banked while third vessel is provisional")
	_check(not rules.light_vessel(1, rules.ritual_sequence[4]), "wrong unlit vessel fails")
	_check(rules.ritual_index == 2 and rules.ritual_bank == 2 and rules.ember_owner == 0, "mistake removes only unbanked vessel and returns ember")
	_check(rules.ritual_vessel_lit(rules.ritual_sequence[0]) and not rules.ritual_vessel_lit(rules.ritual_sequence[2]), "world lighting query preserves banked pair only")
	rules.step(0.35)
	rules.take_ember(2)
	for index: int in range(2, 4):
		rules.light_vessel(2, rules.ritual_sequence[index])
		rules.step(0.35)
	_check(rules.ritual_bank == 4, "second correct pair banks permanently")


func _test_ritual_errors_and_duplicate_input() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	rules.take_ember(1)
	_check(not rules.light_vessel(1, rules.ritual_sequence[1]), "wrong first vessel rejects")
	_check(rules.ritual_index == 0 and rules.ember_owner == 0, "wrong opening resets safely to empty bank")
	_check(events[-1].kind == "ritual_error" and events[-1].payload.ember_released, "wrong vessel publishes recovery feedback")
	rules.take_ember(1)
	_check(not rules.light_vessel(1, rules.ritual_sequence[0]), "retaking ember cannot bypass per-actor command cooldown")
	rules.step(0.35)
	rules.light_vessel(1, rules.ritual_sequence[0])
	rules.step(0.35)
	_check(not rules.light_vessel(1, rules.ritual_sequence[0]) and rules.ritual_index == 1 and rules.ember_owner == 1, "repeated lit-vessel interaction is harmless")


func _test_ritual_hold() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.charge_ritual(8.0, true)
	_near(rules.ritual_hold, 0.0, "occupancy before all vessels cannot charge")
	_light_all(rules)
	_check(rules.ritual_index == 5 and rules.ritual_bank == 4 and rules.ember_owner == 0, "fifth vessel readies hold and returns ember")
	rules.charge_ritual(7.9, true)
	_check(not bool(rules.completed.echoes), "partial final hold cannot finish ritual")
	for invalid: float in [-1.0, 0.0, INF, NAN]:
		rules.charge_ritual(invalid, false)
	_near(rules.ritual_hold, 7.9, "invalid occupancy time cannot erase or extend hold")
	rules.charge_ritual(0.1, false)
	_near(rules.ritual_hold, 0.0, "leaving ring resets unbanked hold")
	_check(rules.ritual_index == 5 and rules.ritual_bank == 4, "leaving ring preserves every lit vessel")
	for unused: int in range(480):
		rules.charge_ritual(1.0 / 60.0, true)
	_check(bool(rules.completed.echoes), "eight continuous seconds complete ritual at physics precision")
	rules.charge_ritual(1.0, false)
	_near(rules.ritual_hold, 8.0, "completed ritual cannot be undone")


func _test_clock_inverse_and_bounds() -> void:
	cases += 1
	var rules: Rules = _new()
	for lever: int in range(3):
		var before: Array[int] = rules.clock_hands.duplicate()
		_check(rules.turn_clock(lever, 1), "forward lever command succeeds")
		var changed: Array[int] = []
		for hand: int in range(3):
			if rules.clock_hands[hand] == posmod(before[hand] + 1, 6):
				changed.append(hand)
		var expected: Array = [[0, 1], [1, 2], [0, 2]][lever]
		_check(changed == expected, "lever effects match the readable A+B, B+C, C+A apparatus")
		rules.step(0.25)
		_check(rules.turn_clock(lever, -1), "reverse lever command succeeds")
		rules.step(0.25)
		_check(rules.clock_hands == before, "reverse is an exact inverse")
	for unused: int in range(12):
		rules.turn_clock(0, -1)
		rules.step(0.25)
		for hand: int in rules.clock_hands:
			_check(hand >= 0 and hand < 6, "negative moves wrap into six legal hand positions")


func _test_clock_rate_limit_and_reset() -> void:
	cases += 1
	var rules: Rules = _new()
	var target: Array[int] = rules.clock_target.duplicate()
	_check(not rules.confirm_clock() and not bool(rules.completed.relay), "wrong clock confirmation cannot finish")
	_check(not rules.turn_clock(0, 1), "confirmation shares the global command cooldown")
	rules.step(0.25)
	rules.turn_clock(0, 1)
	_check(not rules.turn_clock(1, 1) and not rules.reset_clock(), "different lever and reset cannot bypass global cooldown")
	rules.step(0.25)
	_check(rules.reset_clock(), "clock can reset after cooldown")
	_check(rules.clock_hands == rules.clock_start and rules.clock_moves == 0, "reset restores generated starting state")
	_check(rules.clock_target == target, "clock target remains immutable")


func _test_clock_solvability() -> void:
	cases += 1
	# Independent enumeration of every sequence of at most three legal turns.
	# This checks the difficulty floor without trusting the production BFS.
	var too_close: Dictionary = _short_clock_offsets()
	var seeds: Array[int] = []
	for seed_value: int in range(128):
		seeds.append(seed_value)
	seeds.append(271126)
	for seed_value: int in seeds:
		var rules: Rules = _new("second", seed_value)
		var solution: Array[Vector2i] = rules.clock_solution()
		_check(solution.size() >= Rules.CLOCK_MIN_SOLUTION_TURNS and solution.size() <= 9, "generated clock needs at least four legal turns and has a bounded solution")
		var offset: Vector3i = Vector3i(posmod(rules.clock_target[0] - rules.clock_start[0], 6), posmod(rules.clock_target[1] - rules.clock_start[1], 6), posmod(rules.clock_target[2] - rules.clock_start[2], 6))
		_check(not too_close.has(offset), "no sequence of zero, one, two or three moves can solve seed %d" % seed_value)
		for move: Vector2i in solution:
			_check(rules.turn_clock(move.x, move.y), "solver move accepted by production command")
			rules.step(0.25)
		_check(rules.clock_hands == rules.clock_target and not bool(rules.completed.relay), "alignment requires a separate confirmation")
		_check(rules.confirm_clock() and bool(rules.completed.relay), "explicit confirmation seals aligned clock")
		rules.step(1.0)
		_check(not rules.reset_clock() and not rules.turn_clock(0, 1) and not rules.confirm_clock(), "completed clock is immutable")


func _short_clock_offsets() -> Dictionary:
	var offsets: Dictionary = {Vector3i.ZERO: true}
	var moves: Array[Vector3i] = [Vector3i(1, 1, 0), Vector3i(-1, -1, 0), Vector3i(0, 1, 1), Vector3i(0, -1, -1), Vector3i(1, 0, 1), Vector3i(-1, 0, -1)]
	for first: Vector3i in moves:
		for second: Vector3i in moves:
			for third: Vector3i in moves:
				for offset: Vector3i in [first, first + second, first + second + third]:
					offsets[Vector3i(posmod(offset.x, 6), posmod(offset.y, 6), posmod(offset.z, 6))] = true
	return offsets


func _test_solver_is_read_only() -> void:
	cases += 1
	var rules: Rules = _new()
	var before: Array[int] = rules.clock_hands.duplicate()
	var solution: Array[Vector2i] = rules.clock_solution()
	var cached: Array[Vector2i] = rules.clock_solution()
	_check(solution == cached and rules.clock_hands == before and rules.clock_moves == 0, "solver does not execute moves")
	solution.clear()
	_check(rules.clock_solution() == cached, "callers cannot mutate cached solver output")


func _test_director_selected_actions() -> void:
	cases += 1
	var director: Director = Director.new()
	director.configure("survivor", "story", 271126, 1, "second")
	director.step(8.0)
	_check(not director.deliver_mote() and not director.input_echo(director.echo_sequence[0]), "legacy input cannot advance replaced slots")
	director.charge_relay(12.0, true)
	_near(director.relay_progress, 0.0, "legacy relay cannot bypass selected Clock")
	for slot: String in ["silent", "echoes", "relay"]:
		_finish_slot(director, slot)
		_check(bool(director.seals[slot]) and director.progress_for_slot(slot) == 1.0, "selected completion banks exactly its Director slot")
	_check(director.phase == "escape", "three alternate completions open same escape phase")
	director.register_escape()
	_check(director.winner == "survivors" and not director.trial_set.live, "alternate match uses ordinary victory and freezes trial inputs")


func _test_director_timeout_freezes_trials() -> void:
	cases += 1
	var director: Director = Director.new()
	director.configure("eye", "standard", 4, 4, "second")
	director.step(8.0)
	director.trial_set.pickup_relic(1, director.trial_set.vault_targets[0])
	director.trial_set.turn_clock(0, 1)
	director.time_left = 0.1
	director.step(2.0)
	_check(director.phase == "ended" and not director.trial_set.live, "timeout freezes selected trial authority")
	var remaining: float = director.trial_set.clock_cooldown
	director.step(100.0)
	_near(director.trial_set.clock_cooldown, remaining, "clock cooldown freezes at match end")
	_check(not director.trial_set.deposit_relic(1, 0) and not director.trial_set.take_ember(2) and not director.trial_set.turn_clock(1, 1), "late commands cannot modify a timed-out match")


func _test_all_mixed_completions() -> void:
	cases += 1
	var seen: Dictionary = {}
	for seed_value: int in range(256):
		var director: Director = Director.new()
		director.configure("eye", "standard", seed_value, 4, "mix")
		var key: String = _mapping_key(director.trial_set)
		if seen.has(key):
			continue
		seen[key] = true
		director.step(8.0)
		for slot: String in ["silent", "echoes", "relay"]:
			_finish_slot(director, slot)
		_check(director.phase == "escape" and director.seals.values().count(true) == 3, "mixed combination reaches three-seal escape: " + key)
		if seen.size() == 27:
			break
	_check(seen.size() == 27, "all twenty-seven mixed combinations completed through production commands")


func _test_reconfigure() -> void:
	cases += 1
	var rules: Rules = _new()
	var target: Array[int] = rules.clock_target.duplicate()
	rules.pickup_relic(1, 0)
	rules.take_ember(2)
	rules.turn_clock(0, 1)
	rules.configure(271126, "first")
	_check(not rules.live and rules.vault_carriers.is_empty() and rules.ember_owner == 0, "reconfigure clears cargo and live state")
	_check(rules.clock_moves == 0 and rules.clock_cooldown == 0.0 and rules.actor_cooldowns.is_empty(), "reconfigure clears command progress")
	_check(rules.ritual_index == 0 and rules.ritual_bank == 0 and rules.ritual_hold == 0.0, "reconfigure clears ritual state")
	_check(rules.clock_target == target and rules.completed.values().count(true) == 0, "reconfigure regenerates deterministic puzzle and clears seals")


func _test_director_reconfigure_retires_old_authority() -> void:
	cases += 1
	var director: Director = Director.new()
	director.configure("survivor", "story", 271126, 1, "second")
	director.step(8.0)
	var old_rules: Rules = director.trial_set
	old_rules.pickup_relic(1, old_rules.vault_targets[0])
	director.configure("eye", "standard", 271127, 4, "first")
	_check(not old_rules.live and not director.trial_set.live, "reconfiguring retires old authority and starts new preparation")
	_check(not old_rules.deposit_relic(1, 0) and not old_rules.turn_clock(0, 1), "old world references cannot issue late trial commands")
	_check(not old_rules.event_raised.is_connected(director._on_trial_event) and not old_rules.trial_completed.is_connected(director._on_trial_completed), "retired authority no longer forwards events into the new match")
	_check(director.trial_for_slot("silent") == "silent" and director.seals.values().count(true) == 0, "new contract is independent of retired cargo and progress")


func _finish_slot(director: Director, slot: String) -> void:
	var rules: Rules = director.trial_set
	match director.trial_for_slot(slot):
		"silent":
			for unused: int in range(3):
				director.deliver_mote()
		"echoes":
			for symbol: int in director.echo_sequence:
				director.input_echo(symbol)
		"relay":
			director.charge_relay(12.0, true)
		"vault":
			for cradle: int in range(4):
				rules.pickup_relic(1, rules.vault_targets[cradle])
				rules.deposit_relic(1, cradle)
				director.step(0.35)
		"ritual":
			rules.take_ember(2)
			for vessel: int in rules.ritual_sequence:
				rules.light_vessel(2, vessel)
				director.step(0.35)
			rules.charge_ritual(8.0, true)
		"clock":
			for move: Vector2i in rules.clock_solution():
				rules.turn_clock(move.x, move.y)
				director.step(0.25)
			rules.confirm_clock()
		"light":
			for cell: int in range(3):
				rules.third.pickup_cell(cell + 1, cell)
				rules.third.update_light_hold(cell + 1, cell, 2, true)
		"strings":
			for unused: int in range(3):
				rules.third.update_strings_hold(1, rules.third.strings_answer(), 2, true)
				rules.third.interrupt_actor(1)
		"chimes":
			for phrase: Array in rules.third.chimes_sequences:
				for bell: int in phrase:
					rules.third.strike_bell(1, bell)
					director.step(0.45)
