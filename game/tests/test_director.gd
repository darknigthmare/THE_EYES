extends SceneTree
## Real headless tests for match invariants; no graphics or mocked engine required.

const Director = preload("res://scripts/trial_director.gd")
var failures: int = 0
var assertions: int = 0
var cases: int = 0


func _initialize() -> void:
	_test_configure()
	_test_difficulties()
	_test_seeded_echoes()
	_test_preparation_protection()
	_test_split_delta()
	_test_invalid_delta()
	_test_unknown_power()
	_test_line_of_sight()
	_test_power_transaction()
	_test_cooldown_boundary()
	_test_energy_rejection()
	_test_socket_validation()
	_test_socket_switch()
	_test_delivery_limit()
	_test_echo_errors()
	_test_echo_completion()
	_test_relay_checkpoints()
	_test_relay_invalid_input()
	_test_three_seals_required()
	_test_first_escape_wins()
	_test_premature_escape()
	_test_hunt_timeout()
	_test_escape_timeout()
	_test_all_eliminated()
	_test_terminal_freeze()
	_test_reconfigure()
	_test_event_order()
	print("TrialDirector: %d cases, %d assertions, %d failures" % [cases, assertions, failures])
	quit(1 if failures > 0 else 0)


func _new_director(count: int = 1) -> Director:
	var director: Director = Director.new()
	director.configure("survivor", "standard", 1701, count)
	return director


func _live(count: int = 1) -> Director:
	var director: Director = _new_director(count)
	director.step(8.0)
	return director


func _record(director: Director) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	director.event_raised.connect(func(kind: String, payload: Dictionary) -> void:
		events.append({"kind": kind, "payload": payload.duplicate(true)})
	)
	return events


func _check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)


func _near(actual: float, expected: float, description: String) -> void:
	_check(absf(actual - expected) < 0.00001, description + " (%.8f vs %.8f)" % [actual, expected])


func _complete_all(director: Director) -> void:
	for unused: int in range(3):
		director.deliver_mote()
	for symbol: int in director.echo_sequence:
		director.input_echo(symbol)
	director.charge_relay(12.0, true)


func _test_configure() -> void:
	cases += 1
	var d: Director = _new_director(4)
	_check(d.phase == "preparation" and d.winner.is_empty(), "new match begins in preparation")
	_check(d.mode == "survivor" and d.difficulty == "standard", "requested role and difficulty")
	_check(d.alive_count == 4 and d.escaped_count == 0, "survivor counts initialize")
	_near(d.time_left, 480.0, "standard hunt budget")
	_near(d.energy, 100.0, "energy starts full")
	_check(d.seals.values().count(true) == 0, "no seals start completed")


func _test_difficulties() -> void:
	cases += 1
	var d: Director = Director.new()
	d.configure("EYE", "Story", 10, 0)
	_check(d.mode == "eye" and d.difficulty == "story", "configuration is case insensitive")
	_near(d.time_left, 600.0, "story hunt budget")
	_near(d.escape_left, 90.0, "story escape budget")
	_check(d.alive_count == 1, "invalid survivor count becomes one")
	d.configure("eye", "ruthless", 10)
	_near(d.time_left, 360.0, "ruthless hunt budget")
	_near(d.escape_left, 50.0, "ruthless escape budget")
	d.configure("invalid", "invalid", 10)
	_check(d.mode == "survivor" and d.difficulty == "standard", "unknown configuration falls back safely")


func _test_seeded_echoes() -> void:
	cases += 1
	var d: Director = _new_director()
	var other: Director = _new_director()
	_check(d.echo_sequence == other.echo_sequence, "same seed yields identical echo sequence")
	var sorted_sequence: Array[int] = d.echo_sequence.duplicate()
	sorted_sequence.sort()
	_check(sorted_sequence == [0, 1, 2, 3], "sequence is a permutation of all four valid symbols")
	var found_different: bool = false
	for seed_value: int in range(10):
		other.configure("survivor", "standard", seed_value)
		found_different = found_different or d.echo_sequence != other.echo_sequence
	_check(found_different, "different seeds can vary the puzzle")


func _test_preparation_protection() -> void:
	cases += 1
	var d: Director = _new_director()
	for power: String in ["trap", "mark", "summon", "blink"]:
		_check(not d.try_use(power), "preparation rejects " + power)
	_check(not d.deliver_mote(), "preparation rejects delivery")
	_check(not d.input_echo(d.echo_sequence[0]), "preparation rejects echo input")
	d.charge_relay(12.0, true)
	d.register_elimination()
	d.register_escape()
	_check(d.relay_progress == 0.0 and d.alive_count == 1 and d.escaped_count == 0, "preparation protects survivors and relay")
	_near(d.energy, 100.0, "rejected preparation actions do not spend resources")


func _test_split_delta() -> void:
	cases += 1
	var d: Director = _new_director()
	d.step(10.0)
	_check(d.phase == "hunt", "large frame crosses preparation boundary")
	_near(d.grace_left, 0.0, "grace clamps at zero")
	_near(d.time_left, 478.0, "only residual frame time consumes hunt budget")
	d = _new_director()
	d.step(7.0)
	_check(d.phase == "preparation", "partial grace stays in preparation")
	d.step(1.0)
	_near(d.time_left, 480.0, "exact preparation boundary preserves hunt budget")


func _test_invalid_delta() -> void:
	cases += 1
	var d: Director = _live()
	d.try_use("trap")
	for invalid: float in [0.0, -4.0, INF, NAN]:
		d.step(invalid)
	_near(d.time_left, 480.0, "invalid delta cannot consume clock")
	_near(d.energy, 75.0, "invalid delta cannot regenerate resources")
	_near(float(d.cooldowns["trap"]), 4.0, "invalid delta cannot bypass cooldown")


func _test_unknown_power() -> void:
	cases += 1
	var d: Director = _live()
	var events: Array[Dictionary] = _record(d)
	_check(not d.can_use("unknown") and not d.try_use("unknown"), "unknown abilities reject cleanly")
	_near(d.energy, 100.0, "unknown ability has no cost")
	_check(events.is_empty(), "unknown ability emits no success event")


func _test_line_of_sight() -> void:
	cases += 1
	var d: Director = _live()
	for power: String in ["trap", "mark", "summon"]:
		_check(not d.try_use(power, false), "occlusion rejects " + power)
	_near(d.energy, 100.0, "occluded actions spend no energy")
	_check(d.try_use("blink", false), "socket blink does not require target line of sight")


func _test_power_transaction() -> void:
	cases += 1
	var d: Director = _live()
	var events: Array[Dictionary] = _record(d)
	_check(d.try_use("summon"), "funded visible summon succeeds")
	_near(d.energy, 55.0, "summon spends exactly 45 energy")
	_near(float(d.cooldowns["summon"]), 16.0, "summon cooldown begins")
	_check(events.size() == 1 and events[0]["kind"] == "power", "successful cast emits one power event")
	_check(not d.try_use("summon"), "repeated summon is rejected")
	_near(d.energy, 55.0, "rejected repeat does not charge again")


func _test_cooldown_boundary() -> void:
	cases += 1
	var d: Director = _live()
	d.try_use("trap")
	d.step(3.99)
	_check(not d.can_use("trap"), "cooldown is enforced before boundary")
	d.step(0.01)
	_check(d.can_use("trap"), "cooldown clears at exact boundary")
	_near(d.energy, 91.0, "live regeneration uses elapsed seconds")
	d.step(10.0)
	_near(d.energy, 100.0, "regeneration clamps at capacity")


func _test_energy_rejection() -> void:
	cases += 1
	var d: Director = _live()
	d.energy = 24.0
	_check(not d.try_use("trap"), "underfunded trap rejects")
	_near(d.energy, 24.0, "underfunded cast preserves energy")
	_near(float(d.cooldowns["trap"]), 0.0, "underfunded cast creates no cooldown")
	d.energy = 25.0
	_check(d.try_use("trap"), "exact funding is accepted")
	_near(d.energy, 0.0, "exact funding leaves zero, never negative")


func _test_socket_validation() -> void:
	cases += 1
	var d: Director = _live()
	_check(not d.switch_socket(-1) and not d.switch_socket(4), "invalid socket indices reject")
	_check(not d.switch_socket(0), "blinking to active socket rejects")
	_near(d.energy, 100.0, "invalid switch never spends energy")
	_check(d.eye_socket == 0, "rejected switches leave socket unchanged")


func _test_socket_switch() -> void:
	cases += 1
	var d: Director = _live()
	_check(d.switch_socket(3) and d.eye_socket == 3, "valid switch changes socket")
	_near(d.energy, 92.0, "switch costs eight energy")
	_check(not d.switch_socket(1) and d.eye_socket == 3, "switch cooldown preserves active socket")
	d.step(2.0)
	_check(d.switch_socket(1) and d.eye_socket == 1, "switch unlocks after two seconds")


func _test_delivery_limit() -> void:
	cases += 1
	var d: Director = _live()
	for count: int in range(3):
		_check(d.deliver_mote(), "valid mote delivery " + str(count + 1))
	_check(bool(d.seals["silent"]) and d.motes_delivered == 3, "three deliveries award the Silent seal")
	_check(not d.deliver_mote() and d.motes_delivered == 3, "extra deliveries do not duplicate objective")
	_check(d.phase == "hunt", "one seal does not open exit")


func _test_echo_errors() -> void:
	cases += 1
	var d: Director = _live()
	_check(not d.input_echo(-1) and not d.input_echo(4), "invalid symbols reject")
	_check(d.echo_errors == 0 and d.echo_index == 0, "invalid symbols do not cause gameplay penalty")
	_check(d.input_echo(d.echo_sequence[0]), "first correct symbol advances")
	var wrong: int = (d.echo_sequence[1] + 1) % 4
	_check(not d.input_echo(wrong), "wrong valid symbol fails")
	_check(d.echo_index == 0 and d.echo_errors == 1, "mistake resets current sequence and counts one error")
	_check(not bool(d.seals["echoes"]), "error cannot award a seal")


func _test_echo_completion() -> void:
	cases += 1
	var d: Director = _live()
	for symbol: int in d.echo_sequence:
		_check(d.input_echo(symbol), "correct sequence element")
	_check(bool(d.seals["echoes"]) and d.echo_index == 4, "whole sequence awards seal")
	_check(not d.input_echo(0) and d.echo_errors == 0, "completed sequence is immutable")


func _test_relay_checkpoints() -> void:
	cases += 1
	var d: Director = _live()
	d.charge_relay(4.0, true)
	_near(d.relay_progress, 1.0 / 3.0, "relay reaches first checkpoint in four seconds")
	d.charge_relay(2.0, true)
	_near(d.relay_progress, 0.5, "relay advances continuously")
	d.charge_relay(24.0, false)
	_near(d.relay_progress, 1.0 / 3.0, "released relay cannot fall below checkpoint")
	d.charge_relay(4.0, true)
	d.charge_relay(24.0, false)
	_near(d.relay_progress, 2.0 / 3.0, "second checkpoint is retained")
	d.charge_relay(4.0, true)
	_check(bool(d.seals["relay"]), "twelve net seconds complete relay")
	d.charge_relay(100.0, false)
	_near(d.relay_progress, 1.0, "completed relay never decays")


func _test_relay_invalid_input() -> void:
	cases += 1
	var d: Director = _live()
	for invalid: float in [0.0, -12.0, INF, NAN]:
		d.charge_relay(invalid, true)
	_near(d.relay_progress, 0.0, "invalid charging intervals are ignored")
	for unused: int in range(720):
		d.charge_relay(1.0 / 60.0, true)
	_near(d.relay_progress, 1.0, "small physics steps complete without floating point lockout")
	_check(bool(d.seals["relay"]), "small steps emit completed relay")


func _test_three_seals_required() -> void:
	cases += 1
	var d: Director = _live()
	d.charge_relay(12.0, true)
	for symbol: int in d.echo_sequence:
		d.input_echo(symbol)
	_check(d.phase == "hunt", "two seals keep exit shut")
	d.deliver_mote()
	d.deliver_mote()
	_check(d.phase == "hunt", "partial last trial keeps exit shut")
	d.deliver_mote()
	_check(d.phase == "escape", "third seal opens escape")
	_near(d.escape_left, 65.0, "escape phase receives its full window")


func _test_first_escape_wins() -> void:
	cases += 1
	var d: Director = _live(4)
	_complete_all(d)
	var events: Array[Dictionary] = _record(d)
	d.register_escape()
	_check(d.phase == "ended" and d.winner == "survivors", "first valid escape wins team round")
	_check(d.escaped_count == 1 and d.alive_count == 3, "escaping survivor leaves active population")
	d.register_escape()
	_check(d.escaped_count == 1 and d.alive_count == 3, "duplicate escape cannot double count after result")
	_check(events.filter(func(event: Dictionary) -> bool: return event["kind"] == "result").size() == 1, "result emits once")


func _test_premature_escape() -> void:
	cases += 1
	var d: Director = _new_director()
	d.register_escape()
	d.step(8.0)
	d.register_escape()
	_check(d.escaped_count == 0 and d.alive_count == 1 and d.winner.is_empty(), "crossing locked exit cannot win")


func _test_hunt_timeout() -> void:
	cases += 1
	var d: Director = _new_director()
	var events: Array[Dictionary] = _record(d)
	d.step(1000.0)
	_check(d.phase == "ended" and d.winner == "eye", "oversized step still resolves hunt timeout")
	_near(d.time_left, 0.0, "hunt clock clamps to zero")
	_check(events[-1]["payload"]["reason"] == "hunt_timeout", "timeout has explicit reason")


func _test_escape_timeout() -> void:
	cases += 1
	var d: Director = _live()
	d.step(479.0)
	_complete_all(d)
	d.step(64.0)
	_check(d.phase == "escape", "last-second seals still grant a full escape window")
	d.step(1.0)
	_check(d.phase == "ended" and d.winner == "eye", "escape timeout awards Eye win")
	_near(d.escape_left, 0.0, "escape clock clamps at zero")


func _test_all_eliminated() -> void:
	cases += 1
	var d: Director = _live(2)
	d.register_elimination()
	_check(d.phase == "hunt" and d.alive_count == 1, "one survivor remaining keeps round active")
	d.register_elimination()
	_check(d.phase == "ended" and d.winner == "eye" and d.alive_count == 0, "last elimination awards Eye win")
	d.register_elimination()
	_check(d.alive_count == 0, "duplicate elimination never drives population negative")


func _test_terminal_freeze() -> void:
	cases += 1
	var d: Director = _live()
	d.try_use("trap")
	d.register_elimination()
	var events: Array[Dictionary] = _record(d)
	d.step(100.0)
	d.charge_relay(12.0, true)
	_check(not d.try_use("mark") and not d.deliver_mote() and not d.input_echo(d.echo_sequence[0]), "ended game rejects actions")
	d.register_escape()
	d.register_elimination()
	_near(d.energy, 75.0, "ended game resources are frozen")
	_near(d.time_left, 480.0, "ended game clock is frozen")
	_near(d.relay_progress, 0.0, "ended game objectives are frozen")
	_check(events.is_empty() and d.winner == "eye", "ended game emits no extra state transitions")


func _test_reconfigure() -> void:
	cases += 1
	var d: Director = _live()
	var sequence_before: Array[int] = d.echo_sequence.duplicate()
	d.try_use("summon")
	_complete_all(d)
	d.register_escape()
	d.configure("survivor", "standard", 1701, 3)
	_check(d.phase == "preparation" and d.winner.is_empty(), "reconfigure clears result")
	_check(d.alive_count == 3 and d.escaped_count == 0, "reconfigure restores population")
	_check(d.seals.values().count(true) == 0 and d.motes_delivered == 0 and d.echo_index == 0, "reconfigure clears objectives")
	_near(d.relay_progress, 0.0, "reconfigure clears relay")
	_near(d.energy, 100.0, "reconfigure refills energy")
	_near(float(d.cooldowns["summon"]), 0.0, "reconfigure clears cooldowns")
	_check(d.echo_sequence == sequence_before, "reconfigure preserves deterministic seed behavior")


func _test_event_order() -> void:
	cases += 1
	var d: Director = _new_director()
	var events: Array[Dictionary] = _record(d)
	d.step(8.0)
	_complete_all(d)
	d.register_escape()
	_check(events[0]["kind"] == "phase" and events[0]["payload"]["phase"] == "hunt", "hunt transition is observable")
	var seal_events: Array[Dictionary] = events.filter(func(event: Dictionary) -> bool: return event["kind"] == "seal")
	_check(seal_events.size() == 3, "one event per seal")
	_check(seal_events[2]["payload"]["completed"] == 3, "seal event exposes total completed count")
	_check(events[-2]["kind"] == "phase" and events[-2]["payload"]["phase"] == "ended", "terminal phase precedes result")
	_check(events[-1]["kind"] == "result" and events[-1]["payload"]["winner"] == "survivors", "result is final event")
