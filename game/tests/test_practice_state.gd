extends SceneTree
## Workshop domain invariants, using the real authorities and seeded puzzles.

const Practice = preload("res://scripts/practice_state.gd")
const Director = preload("res://scripts/trial_director.gd")
const Rules = preload("res://scripts/trial_set.gd")
var cases: int = 0
var assertions: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_catalogue()
	_test_session_validation()
	_test_session_completion()
	_test_elapsed_bounds()
	_test_single_bay()
	_test_inactive_actions()
	_test_no_eye_or_deadline()
	_test_puzzle_parity()
	_test_all_nine_completions()
	_test_checkpoints_and_interruptions()
	_test_invalid_reconfigure()
	_test_retired_authorities()
	_test_same_seed_retry()
	_test_normal_match_after_practice()
	print("PracticeState: %d cases, %d assertions, %d failures" % [cases, assertions, failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)


func _near(actual: float, expected: float, message: String) -> void:
	_check(absf(actual - expected) < 0.00001, message)


func _practice(trial_id: String, seed_value: int = 271126) -> Director:
	var director: Director = Director.new()
	_check(director.configure_practice(trial_id, seed_value), "configure practice " + trial_id)
	return director


func _events(director: Director) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	director.event_raised.connect(func(kind: String, payload: Dictionary) -> void:
		events.append({"kind": kind, "payload": payload.duplicate(true)})
	)
	return events


func _count(events: Array[Dictionary], kind: String) -> int:
	var count: int = 0
	for event: Dictionary in events:
		if str(event.kind) == kind:
			count += 1
	return count


func _test_catalogue() -> void:
	cases += 1
	var catalogue: Array[Dictionary] = Practice.catalogue()
	var ids: Array[String] = []
	_check(catalogue.size() == 9, "catalogue contains all nine current trials")
	for item: Dictionary in catalogue:
		var id: String = str(item.trial_id)
		ids.append(id)
		_check(str(item.slot_id) == Rules.slot_for_trial(id), "catalogue bay matches domain " + id)
		_check(str(item.title) == str(Rules.TRIAL_NAMES[id]), "catalogue keeps existing trial title " + id)
		_check(not str(item.summary).is_empty() and not str(item.controls).is_empty() and not str(item.checkpoints).is_empty(), "catalogue explains purpose, controls and checkpoints " + id)
		_check(item.instructions is Array and item.instructions.size() >= 3 and item.instructions.size() <= 5, "catalogue gives a bounded readable guide " + id)
		_check(item.size() == 7, "catalogue contains only public guide fields " + id)
	_check(ids == ["silent", "echoes", "relay", "vault", "ritual", "clock", "light", "strings", "chimes"], "catalogue order groups the three Observances")
	catalogue[0].title = "Changed"
	catalogue[0].instructions.clear()
	_check(str(Practice.entry("silent").title) == "Silent Countdown" and Practice.entry("silent").instructions.size() >= 3, "catalogue values cannot be mutated through a previous response")
	_check(Practice.entry("unknown").is_empty() and Rules.slot_for_trial("unknown").is_empty(), "unknown trial has no guide or bay")


func _test_session_validation() -> void:
	cases += 1
	var session: Practice = Practice.new()
	_check(not session.active and session.trial_id.is_empty(), "new session has no selection")
	_check(session.configure("vault", 1), "minimum seed is accepted")
	session.step(2.5)
	var before: Dictionary = session.snapshot()
	for invalid: String in ["", "unknown", "Vault", "silent/echoes"]:
		_check(not session.configure(invalid, 1701), "unknown trial rejected without fallback")
	for invalid_seed: int in [-1, 0, 1000000]:
		_check(not session.configure("silent", invalid_seed), "out-of-range seed rejected")
	_check(session.snapshot() == before, "invalid configuration preserves active attempt")
	_check(session.configure("chimes", 999999) and session.elapsed == 0.0, "maximum seed starts fresh attempt")


func _test_session_completion() -> void:
	cases += 1
	var session: Practice = Practice.new()
	_check(session.complete("silent").is_empty(), "unconfigured session cannot complete")
	session.configure("light", 1701)
	session.step(4.25)
	_check(session.complete("vault").is_empty() and session.active, "other trial cannot complete the selected session")
	var result: Dictionary = session.complete("light")
	_check(result == {"trial_id": "light", "slot_id": "silent", "seed": 1701, "elapsed": 4.25}, "completion carries only workshop identity and elapsed time")
	_check(session.completed and not session.active, "completion retires active attempt")
	_check(session.complete("light").is_empty(), "completion is emitted once")
	session.step(100.0)
	_near(session.elapsed, 4.25, "completed elapsed time freezes")
	var copy: Dictionary = session.snapshot()
	copy.completed = false
	_check(session.completed, "snapshot is detached from authority")


func _test_elapsed_bounds() -> void:
	cases += 1
	var session: Practice = Practice.new()
	session.configure("relay", 1701)
	for value: float in [0.0, -1.0, INF, NAN]:
		session.step(value)
	_near(session.elapsed, 0.0, "invalid deltas do not affect workshop elapsed time")
	session.step(Practice.MAX_SECONDS * 2.0)
	session.step(Practice.MAX_SECONDS * 2.0)
	_near(session.elapsed, Practice.MAX_SECONDS, "elapsed storage remains finite and bounded")
	_check(session.active and not session.completed, "elapsed storage limit is never a time limit")


func _test_single_bay() -> void:
	cases += 1
	for id: String in Practice.TRIAL_IDS:
		var director: Director = _practice(id)
		var slot: String = Rules.slot_for_trial(id)
		_check(director.phase == "practice" and director.is_practice() and director.is_live(), "workshop starts immediately live " + id)
		_check(director.trial_set.live and director.trial_set.third.live, "normal world authority remains live " + id)
		_check(director.trial_set.contract == "practice" and director.trial_set.slot_trials.values().count("") == 2, "exactly one bay selected " + id)
		_check(director.seals.values().count(true) == 0 and director.trial_set.completed.values().count(true) == 0, "inactive seals are not fake completions " + id)
		_check(director.trial_set.third.slot_trials == director.trial_set.slot_trials, "third-trial authority receives same one-bay selection " + id)
		for bay: String in Rules.SLOT_VARIANTS:
			_check(director.trial_for_slot(bay) == (id if bay == slot else ""), "correct bay mask " + id + "/" + bay)
			if bay != slot:
				director.trial_set.mark_slot_complete(bay)
				_check(not bool(director.trial_set.completed[bay]), "inactive bay cannot be marked complete")


func _test_inactive_actions() -> void:
	cases += 1
	for id: String in Practice.TRIAL_IDS:
		var director: Director = _practice(id)
		var rules: Rules = director.trial_set
		if id != "silent":
			_check(not director.deliver_mote(), "inactive delivery rejected " + id)
		if id != "echoes":
			_check(not director.input_echo(director.echo_sequence[0]), "inactive Echoes input rejected " + id)
		if id != "relay":
			director.charge_relay(12.0, true)
			_check(director.relay_progress == 0.0, "inactive Relay charge rejected " + id)
		if id != "vault":
			_check(not rules.pickup_relic(1, 0) and not rules.deposit_relic(1, 0), "inactive Vault commands rejected " + id)
		if id != "ritual":
			_check(not rules.take_ember(1) and not rules.light_vessel(1, 0), "inactive Ritual commands rejected " + id)
		if id != "clock":
			_check(not rules.turn_clock(0, 1) and not rules.confirm_clock(), "inactive Clock commands rejected " + id)
		if id != "light":
			_check(not rules.third.pickup_cell(1, 0) and not rules.third.update_light_hold(1, 0, 2.0, true), "inactive Light commands rejected " + id)
		if id != "strings":
			_check(not rules.third.update_strings_hold(1, rules.third.strings_answer(), 2.0, true), "inactive Strings commands rejected " + id)
		if id != "chimes":
			_check(not rules.third.strike_bell(1, 0) and not rules.third.toggle_damper(1, 0), "inactive Chimes commands rejected " + id)
		_check(director.seals.values().count(true) == 0 and director.phase == "practice", "rejected inactive commands cannot complete practice " + id)


func _test_no_eye_or_deadline() -> void:
	cases += 1
	var director: Director = _practice("clock")
	var events: Array[Dictionary] = _events(director)
	for power: String in ["trap", "mark", "summon", "blink"]:
		_check(not director.can_use(power) and not director.try_use(power), "practice rejects Eye power " + power)
	_check(not director.switch_socket(1), "practice rejects Eye socket switching")
	director.register_elimination()
	director.register_escape()
	_check(director.alive_count == 1 and director.escaped_count == 0, "practice cannot enter elimination or escape scoring")
	_check(director.trial_set.turn_clock(0, 1), "selected puzzle uses normal command path")
	_check(not director.trial_set.turn_clock(0, 1), "normal Clock cooldown still applies")
	director.step(0.25)
	_check(director.trial_set.turn_clock(0, -1), "practice tick advances trial cooldown")
	director.step(10000.0)
	_check(director.phase == "practice" and director.winner.is_empty(), "practice never times out")
	_near(director.practice.elapsed, 10000.25, "practice tracks elapsed simulation time")
	_check(director.time_left == 0.0 and director.escape_left == 0.0 and director.grace_left == 0.0, "practice exposes no countdown budgets")
	_check(director.energy == Director.MAX_ENERGY and director.terror == 0.0, "practice does not grow Eye pressure")
	_check(_count(events, "power") == 0 and _count(events, "result") == 0, "practice emits neither Eye casts nor competitive result")


func _test_puzzle_parity() -> void:
	cases += 1
	for seed_value: int in [1, 1701, 999999]:
		var match_director: Director = Director.new()
		match_director.configure("survivor", "standard", seed_value, 1, "third")
		var expected: Rules = match_director.trial_set
		for id: String in Practice.TRIAL_IDS:
			var practice: Director = _practice(id, seed_value)
			var actual: Rules = practice.trial_set
			_check(practice.echo_sequence == match_director.echo_sequence, "practice preserves Echoes RNG stream " + id)
			_check(actual.vault_targets == expected.vault_targets and actual.ritual_sequence == expected.ritual_sequence, "practice preserves alternate puzzle streams " + id)
			_check(actual.clock_start == expected.clock_start and actual.clock_target == expected.clock_target, "practice preserves Clock start and target " + id)
			_check(actual.third.strings_layout == expected.third.strings_layout and actual.third.strings_clue() == expected.third.strings_clue(), "practice preserves Strings clue and tags " + id)
			_check(actual.third.chimes_sequences == expected.third.chimes_sequences, "practice preserves Chimes phrases " + id)


func _test_all_nine_completions() -> void:
	cases += 1
	for id: String in Practice.TRIAL_IDS:
		var director: Director = _practice(id)
		var events: Array[Dictionary] = _events(director)
		director.step(1.25)
		_solve(director)
		_check(director.phase == "ended" and director.is_practice() and not director.is_live(), "genuine selected trial ends practice " + id)
		_check(director.practice.completed and not director.practice.active, "session marks one completion " + id)
		_check(director.seals.values().count(true) == 1 and bool(director.seals[Rules.slot_for_trial(id)]), "only the real selected seal completes " + id)
		_check(director.trial_set.completed.values().count(true) == 1, "domain contains only one completed seal " + id)
		_check(not director.trial_set.live and not director.trial_set.third.live, "completion freezes underlying trial authorities " + id)
		_check(director.winner.is_empty() and director.escaped_count == 0, "practice has no winner or escaped survivor " + id)
		_check(_count(events, "practice_completed") == 1 and _count(events, "result") == 0, "one dedicated completion and no match result " + id)
		for event: Dictionary in events:
			if str(event.kind) == "practice_completed":
				_check(event.payload.trial_id == id and int(event.payload.seed) == 271126 and float(event.payload.elapsed) >= 1.25, "completion preserves chosen seed and elapsed " + id)
			if str(event.kind) == "phase":
				_check(str(event.payload.phase) != "escape", "practice never enters escape phase " + id)
			if str(event.kind) == "seal":
				_check(int(event.payload.required) == 1 and int(event.payload.completed) == 1, "practice requires exactly one genuine seal " + id)
		var elapsed: float = director.practice.elapsed
		director.step(90000.0)
		director.register_escape()
		director.register_elimination()
		_solve(director, false)
		_near(director.practice.elapsed, elapsed, "terminal practice time freezes " + id)
		_check(_count(events, "practice_completed") == 1 and _count(events, "result") == 0, "post-completion commands cannot duplicate or change result " + id)


func _test_checkpoints_and_interruptions() -> void:
	cases += 1
	var relay: Director = _practice("relay")
	relay.charge_relay(6.0, true)
	relay.charge_relay(100.0, false)
	_near(relay.relay_progress, 1.0 / 3.0, "practice retains Relay checkpoint and decay")
	var light: Director = _practice("light")
	light.trial_set.third.pickup_cell(1, 0)
	light.trial_set.third.update_light_hold(1, 0, 1.5, true)
	light.trial_set.third.update_light_hold(1, 0, 0.1, false)
	_check(not light.trial_set.third.update_light_hold(1, 0, 0.5, true), "invalid world hold cannot accumulate across interruption")
	_check(not bool(light.trial_set.third.light_lit[0]), "practice still needs a full uninterrupted Light alignment")
	var strings: Director = _practice("strings")
	var answer: int = strings.trial_set.third.strings_answer()
	_check(strings.trial_set.third.update_strings_hold(1, answer, 2.0, true), "first normal Strings hold completes a stage")
	_check(not strings.trial_set.third.update_strings_hold(1, strings.trial_set.third.strings_answer(), 2.0, true), "practice retains release-between-pulls requirement")
	_check(strings.trial_set.third.strings_stage == 1, "held input does not skip practice stages")


func _test_invalid_reconfigure() -> void:
	cases += 1
	var director: Director = _practice("relay")
	director.charge_relay(4.0, true)
	var original: Rules = director.trial_set
	var events: Array[Dictionary] = _events(director)
	_check(not director.configure_practice("unknown", 1701) and not director.configure_practice("light", 0), "invalid director practice request rejected")
	_check(director.trial_set == original and director.phase == "practice" and director.practice.trial_id == "relay", "invalid selection does not replace live authority")
	_near(director.relay_progress, 1.0 / 3.0, "invalid selection preserves progress")
	_check(events.is_empty(), "invalid selection emits no phase changes")
	_check(not original.configure_practice("unknown", 1701) and original.live, "invalid trial-set request preserves live state")


func _test_retired_authorities() -> void:
	cases += 1
	var director: Director = _practice("vault")
	var old: Rules = director.trial_set
	old.pickup_relic(1, old.vault_targets[0])
	director.configure_practice("light", 271126)
	_check(not old.live and not old.third.live, "reconfigure retires old selection and third authority")
	_check(not old.deposit_relic(1, 0), "stale world cannot finish retired trial")
	old.trial_completed.emit("silent", "vault")
	_check(director.phase == "practice" and director.seals.values().count(true) == 0, "stale completion signals are disconnected")
	var third = director.trial_set.third
	director.configure("survivor", "standard", 271126)
	_check(not third.live and not director.is_practice(), "normal configuration retires workshop state")


func _test_same_seed_retry() -> void:
	cases += 1
	var director: Director = _practice("clock", 1701)
	var start: Array[int] = director.trial_set.clock_start.duplicate()
	var target: Array[int] = director.trial_set.clock_target.duplicate()
	_solve(director)
	director.configure_practice("clock", 1701)
	_check(director.phase == "practice" and director.practice.elapsed == 0.0 and not director.practice.completed, "retry starts a new active attempt")
	_check(director.trial_set.clock_start == start and director.trial_set.clock_target == target and director.trial_set.clock_hands == start, "same-seed retry reproduces original Clock puzzle")
	_check(director.seals.values().count(true) == 0, "retry resets the actual seal")
	var varied: bool = false
	for seed_value: int in range(2, 10):
		director.configure_practice("clock", seed_value)
		varied = varied or director.trial_set.clock_start != start or director.trial_set.clock_target != target
	_check(varied, "new seeds can generate new practice puzzles")


func _test_normal_match_after_practice() -> void:
	cases += 1
	var director: Director = _practice("silent")
	_solve(director)
	director.configure("survivor", "standard", 1701)
	var events: Array[Dictionary] = _events(director)
	_check(not director.is_practice() and director.phase == "preparation" and not director.is_live(), "normal match keeps preparation after a workshop")
	director.step(8.0)
	for unused: int in range(3):
		director.deliver_mote()
	_check(director.phase == "hunt", "one normal seal still cannot trigger escape")
	for symbol: int in director.echo_sequence:
		director.input_echo(symbol)
	director.charge_relay(12.0, true)
	_check(director.phase == "escape" and director.seals.values().count(true) == 3, "normal match still requires all three seals")
	director.register_escape()
	_check(director.winner == "survivors" and director.escaped_count == 1, "normal escape still awards competitive victory")
	_check(_count(events, "result") == 1 and _count(events, "practice_completed") == 0, "normal match keeps its original result path")


func _solve(director: Director, verify: bool = true) -> void:
	var rules: Rules = director.trial_set
	var id: String = director.practice.trial_id
	match id:
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
			rules.take_ember(1)
			for vessel: int in rules.ritual_sequence:
				rules.light_vessel(1, vessel)
				director.step(0.35)
			rules.charge_ritual(8.0, true)
		"clock":
			for move: Vector2i in rules.clock_solution():
				rules.turn_clock(move.x, move.y)
				director.step(0.25)
			rules.confirm_clock()
		"light":
			for lamp: int in range(3):
				rules.third.pickup_cell(1, lamp)
				rules.third.update_light_hold(1, lamp, 2.0, true)
		"strings":
			for unused: int in range(3):
				rules.third.update_strings_hold(1, -1, 0.1, false)
				rules.third.update_strings_hold(1, rules.third.strings_answer(), 2.0, true)
		"chimes":
			for phrase in rules.third.chimes_sequences:
				for bell: int in phrase:
					rules.third.strike_bell(1, bell)
					director.step(0.45)
	if verify:
		_check(director.practice.completed, "normal domain commands solve practice " + id)
