extends SceneTree
## Local squad life/rescue authority; spatial eligibility is tested by the world.
const Rules = preload("res://scripts/squad_state.gd")
var assertions: int = 0
var cases: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_configuration()
	_test_unknown_members_and_snapshots()
	_test_preparation_guards()
	_test_first_fall_and_duplicate()
	_test_reservation_and_idempotent_begin()
	_test_invalid_pairs()
	_test_exclusive_reservations()
	_test_progress_requires_exact_reservation()
	_test_separate_time_budgets()
	_test_cancel_and_restart()
	_test_revive_boundary_and_payload()
	_test_physics_tick_precision()
	_test_invalid_deltas()
	_test_downed_helper_releases_reservation()
	_test_eliminated_helper_releases_reservation()
	_test_bleedout_releases_reservation()
	_test_parallel_rescues()
	_test_second_fall_is_final()
	_test_squad_wipe()
	_test_second_fall_can_trigger_wipe()
	_test_end_freezes_authority()
	_test_reconfigure()
	_test_helper_reuse_has_no_global_cooldown()
	_test_invalid_roster_cannot_activate()
	_test_bleedout_and_rescue_ordering()
	_test_freeze_clears_all_reservations_once()
	print("SquadState: %d cases, %d assertions, %d failures" % [cases, assertions, failures])
	quit(1 if failures > 0 else 0)


func _new(ids: Array[int] = [1, 2, 3, 4, 5], human: int = 1) -> Rules:
	var rules: Rules = Rules.new()
	rules.configure(ids, human)
	rules.set_live(true)
	return rules


func _check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)


func _near(actual: float, expected: float, description: String) -> void:
	_check(absf(actual - expected) < 0.00001, description)


func _events(rules: Rules) -> Array[Dictionary]:
	var recorded: Array[Dictionary] = []
	var weak: WeakRef = weakref(rules)
	rules.event_raised.connect(func(kind: String, payload: Dictionary) -> void:
		var current: Rules = weak.get_ref()
		recorded.append({"kind": kind, "payload": payload.duplicate(true), "members": current.members.duplicate(true), "live": current.live})
	)
	return recorded


func _count(events: Array[Dictionary], kind: String) -> int:
	var result: int = 0
	for event: Dictionary in events:
		if event.kind == kind:
			result += 1
	return result


func _revive(rules: Rules, helper: int, subject: int) -> void:
	rules.begin_revive(helper, subject)
	rules.advance_revive(helper, subject, Rules.REVIVE_SECONDS)


func _test_configuration() -> void:
	cases += 1
	var rules: Rules = Rules.new()
	var ids: Array[int] = [0, 1, 2, 1, -5, 3]
	rules.configure(ids, 1)
	_check(not rules.live and rules.human_id == 1, "configuration starts inactive with a registered human")
	_check(rules.members.size() == 3 and ids == [0, 1, 2, 1, -5, 3], "invalid and duplicate roster IDs do not create members or mutate caller data")
	for id: int in [1, 2, 3]:
		_check(rules.member(id) == {"state": "active", "recoveries": 0, "bleed_left": 0.0, "reviver": 0, "revive_progress": 0.0}, "every member starts with an independent complete life record")


func _test_unknown_members_and_snapshots() -> void:
	cases += 1
	var rules: Rules = _new()
	for id: int in [0, -1, 999]:
		_check(not rules.is_active(id) and not rules.is_downed(id) and not rules.is_eliminated(id) and rules.member(id).is_empty(), "foreign ID has no fabricated life state")
	var copy: Dictionary = rules.member(1)
	copy.state = "eliminated"
	copy.recoveries = 99
	copy.clear()
	_check(rules.is_active(1) and int(rules.member(1).recoveries) == 0, "member snapshots cannot change authority")


func _test_preparation_guards() -> void:
	cases += 1
	var rules: Rules = Rules.new()
	rules.configure([1, 2], 1)
	var before: Dictionary = rules.members.duplicate(true)
	_check(not rules.fall(2) and not rules.begin_revive(1, 2) and not rules.advance_revive(1, 2, 6.0), "preparation rejects falls and rescue commands")
	rules.step(100.0)
	rules.cancel_revive(1)
	_check(rules.members == before and rules.is_active(1), "preparation freezes actions while status queries remain readable")
	rules.set_live(true)
	_check(rules.live and rules.fall(2), "registered squad activates normally")


func _test_first_fall_and_duplicate() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	_check(rules.fall(2) and rules.is_downed(2) and not rules.is_active(2), "first lethal event downs its member")
	_near(float(rules.member(2).bleed_left), 35.0, "first fall starts the full bleedout budget")
	_check(int(rules.member(2).recoveries) == 0, "fall alone does not claim a successful recovery")
	rules.step(3.0)
	_check(not rules.fall(2), "repeated damage notification cannot down the same body again")
	_near(float(rules.member(2).bleed_left), 32.0, "duplicate fall cannot refresh bleedout")
	_check(_count(events, "squad_downed") == 1 and events[0].members[2].state == "downed" and events[0].payload.bleed_seconds == 35.0, "down event is unique and follows its committed state")


func _test_reservation_and_idempotent_begin() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	rules.fall(2)
	_check(rules.begin_revive(1, 2), "active helper reserves a downed subject")
	rules.advance_revive(1, 2, 1.5)
	_check(rules.begin_revive(1, 2), "same hold can idempotently reassert its reservation")
	_near(float(rules.member(2).revive_progress), 1.5, "reasserting a hold preserves earned progress")
	_check(_count(events, "squad_revive_started") == 1, "repeated begin emits one started event")
	_check(events[1].members[2].reviver == 1 and events[1].payload == {"actor_id": 2, "helper_id": 1}, "start payload names the committed reservation")


func _test_invalid_pairs() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.fall(2)
	rules.fall(3)
	var before: Dictionary = rules.members.duplicate(true)
	for pair: Array in [[0, 2], [-1, 2], [999, 2], [1, 999], [1, 1], [2, 2], [2, 3], [1, 4]]:
		_check(not rules.begin_revive(pair[0], pair[1]), "foreign, self, downed-helper and active-subject reservations reject")
	_check(rules.members == before, "invalid rescue requests leave every life record unchanged")


func _test_exclusive_reservations() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.fall(2)
	rules.fall(4)
	rules.begin_revive(1, 2)
	rules.advance_revive(1, 2, 2.0)
	var before: Dictionary = rules.members.duplicate(true)
	_check(not rules.begin_revive(3, 2), "one subject cannot have competing helpers")
	_check(not rules.begin_revive(1, 4), "one helper cannot channel on two subjects")
	_check(rules.members == before, "competing requests cannot steal or reset a valid rescue")
	_check(rules.begin_revive(3, 4), "another independent pair may rescue simultaneously")


func _test_progress_requires_exact_reservation() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.fall(2)
	_check(not rules.advance_revive(1, 2, 6.0), "progress cannot be submitted before reserving")
	rules.begin_revive(1, 2)
	var before: Dictionary = rules.members.duplicate(true)
	_check(not rules.advance_revive(3, 2, 6.0) and not rules.advance_revive(1, 4, 6.0), "wrong helper or subject cannot advance a reservation")
	_check(rules.members == before, "rejected progress does not change life, timer or channel")
	rules.cancel_revive(1)
	_check(not rules.advance_revive(1, 2, 6.0), "cancelled reservation cannot submit stale progress")


func _test_separate_time_budgets() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.fall(2)
	rules.begin_revive(1, 2)
	rules.step(4.0)
	_near(float(rules.member(2).revive_progress), 0.0, "ordinary time cannot silently advance a rescue")
	_near(float(rules.member(2).bleed_left), 31.0, "rescue reservation does not pause bleedout")
	rules.advance_revive(1, 2, 2.0)
	_near(float(rules.member(2).bleed_left), 31.0, "hold submission does not double-decrement the world's bleedout step")
	rules.fall(3)
	rules.step(1.0)
	_near(float(rules.member(2).bleed_left), 30.0, "existing member keeps its original deadline")
	_near(float(rules.member(3).bleed_left), 34.0, "later fall owns a separate bleedout budget")


func _test_cancel_and_restart() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	rules.fall(2)
	rules.begin_revive(1, 2)
	rules.advance_revive(1, 2, 5.5)
	rules.cancel_revive(3)
	_near(float(rules.member(2).revive_progress), 5.5, "unrelated helper cancellation cannot interrupt a rescue")
	rules.cancel_revive(1)
	rules.cancel_revive(1)
	_check(rules.member(2).reviver == 0 and rules.member(2).revive_progress == 0.0, "actual interruption clears ownership and all partial progress")
	_check(_count(events, "squad_revive_interrupted") == 1, "duplicate cancellation emits no repeated interruption")
	_check(events[-1].members[2].reviver == 0 and events[-1].payload == {"actor_id": 2, "helper_id": 1}, "interruption exposes the cleared reservation")
	_check(rules.begin_revive(3, 2), "a new helper can reserve the released subject")
	rules.advance_revive(3, 2, 0.5)
	_check(rules.is_downed(2), "new helper cannot inherit the previous partial hold")


func _test_revive_boundary_and_payload() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	rules.fall(2)
	rules.begin_revive(1, 2)
	_check(rules.advance_revive(1, 2, 5.99) and rules.is_downed(2), "hold remains incomplete just before six seconds")
	_check(rules.advance_revive(1, 2, 0.01) and rules.is_active(2), "exactly six seconds returns the subject to active state")
	var member: Dictionary = rules.member(2)
	_check(member.recoveries == 1 and member.bleed_left == 0.0 and member.reviver == 0 and member.revive_progress == 0.0, "revival consumes its one opportunity and clears life/channel timers")
	_check(events[-1].kind == "squad_revived" and events[-1].payload == {"actor_id": 2, "helper_id": 1, "health": 35.0, "protection": 5.0}, "world receives exact restored health and protection")
	_check(events[-1].members[2].state == "active" and events[-1].members[2].recoveries == 1, "revive event follows the committed active state")
	_check(not rules.advance_revive(1, 2, 6.0) and not rules.begin_revive(1, 2), "late hold commands cannot revive a living subject twice")
	_check(_count(events, "squad_revived") == 1, "one completed channel emits one recovery")


func _test_physics_tick_precision() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.fall(2)
	rules.begin_revive(1, 2)
	for tick: int in range(360):
		rules.step(1.0 / 60.0)
		rules.advance_revive(1, 2, 1.0 / 60.0)
	_check(rules.is_active(2), "360 physical hold ticks complete the six-second rescue without roundoff delay")
	rules.fall(3)
	for tick: int in range(2100):
		rules.step(1.0 / 60.0)
	_check(rules.is_eliminated(3) and rules.member(3).bleed_left == 0.0, "2100 physical ticks reach the exact 35-second bleedout boundary")


func _test_invalid_deltas() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	rules.fall(2)
	rules.begin_revive(1, 2)
	rules.advance_revive(1, 2, 1.0)
	var before: Dictionary = rules.members.duplicate(true)
	var count: int = events.size()
	for invalid: float in [-1.0, 0.0, INF, -INF, NAN]:
		rules.step(invalid)
		_check(not rules.advance_revive(1, 2, invalid), "nonpositive and nonfinite hold time rejects")
	_check(rules.members == before and events.size() == count, "invalid time cannot extend bleedout, poison progress or emit events")


func _test_downed_helper_releases_reservation() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	rules.fall(2)
	rules.begin_revive(1, 2)
	rules.advance_revive(1, 2, 4.0)
	_check(rules.fall(1), "a helper can suffer a real first fall during a rescue")
	_check(rules.is_downed(1) and rules.member(2).reviver == 0 and rules.member(2).revive_progress == 0.0, "helper fall clears the subject's reservation and hold")
	_check(not rules.advance_revive(1, 2, 6.0), "downed helper cannot complete an interrupted rescue")
	_check(_count(events, "squad_revive_interrupted") == 1 and rules.begin_revive(3, 2), "another active teammate can take over after helper fall")


func _test_eliminated_helper_releases_reservation() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.fall(1)
	_revive(rules, 3, 1)
	rules.fall(2)
	rules.begin_revive(1, 2)
	rules.advance_revive(1, 2, 3.0)
	rules.fall(1)
	_check(rules.is_eliminated(1) and rules.member(2).reviver == 0 and rules.member(2).revive_progress == 0.0, "helper's final fall cannot leave a locked downed subject")
	_check(rules.begin_revive(3, 2), "released subject remains rescuable by a living teammate")


func _test_bleedout_releases_reservation() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	rules.fall(2)
	rules.begin_revive(1, 2)
	rules.advance_revive(1, 2, 5.0)
	rules.step(34.99)
	_check(rules.is_downed(2), "near-deadline subject remains recoverable before the boundary")
	rules.step(0.01)
	_check(rules.is_eliminated(2) and rules.member(2).reviver == 0, "bleedout terminates the subject and frees its helper")
	_check(events[-1].kind == "squad_eliminated" and events[-1].payload.reason == "bleedout", "bleedout emits its exact elimination reason")
	_check(not rules.advance_revive(1, 2, 1.0), "late completion cannot resurrect an expired subject")
	rules.step(100.0)
	_check(_count(events, "squad_eliminated") == 1, "expired member is counted once")


func _test_parallel_rescues() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.fall(2)
	rules.fall(4)
	rules.begin_revive(1, 2)
	rules.begin_revive(3, 4)
	rules.advance_revive(1, 2, 4.0)
	rules.advance_revive(3, 4, 2.0)
	rules.cancel_revive(1)
	_near(float(rules.member(4).revive_progress), 2.0, "one cancellation cannot disturb another pair's channel")
	rules.advance_revive(3, 4, 4.0)
	_check(rules.is_active(4) and rules.is_downed(2), "independent rescue may complete while the other remains downed")
	_check(rules.begin_revive(4, 2), "a recovered teammate can immediately help somebody else")


func _test_second_fall_is_final() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	rules.fall(2)
	_revive(rules, 1, 2)
	_check(rules.fall(2) and rules.is_eliminated(2), "the first post-recovery fall eliminates immediately")
	_check(events[-1].payload.reason == "second_fall" and events[-1].members[2].state == "eliminated", "second-fall event exposes final state and reason")
	_check(not rules.fall(2) and not rules.begin_revive(1, 2), "eliminated member cannot gain another recovery")
	_check(_count(events, "squad_downed") == 1 and _count(events, "squad_eliminated") == 1, "final fall does not fabricate another down or duplicate elimination")


func _test_squad_wipe() -> void:
	cases += 1
	var rules: Rules = _new([1, 2, 3], 1)
	var events: Array[Dictionary] = _events(rules)
	rules.fall(1)
	rules.fall(2)
	_check(rules.live, "one active rescuer keeps two downed teammates recoverable")
	rules.fall(3)
	_check(not rules.live and rules.is_eliminated(1) and rules.is_eliminated(2) and rules.is_eliminated(3), "no active rescuers causes immediate team wipe")
	_check(_count(events, "squad_eliminated") == 3, "wipe emits one final elimination per remaining downed member")
	for event: Dictionary in events:
		if event.kind == "squad_eliminated":
			_check(event.payload.reason == "squad_wipe" and not event.live, "wipe event reports reason after live state closes")
			for id: int in [1, 2, 3]:
				_check(event.members[id].state == "eliminated", "all wipe states are committed before its first elimination event")
	var count: int = events.size()
	rules.step(100.0)
	rules.set_live(true)
	_check(not rules.live and not rules.fall(1) and not rules.begin_revive(1, 2) and events.size() == count, "terminal roster cannot reopen or produce duplicate outcomes")


func _test_second_fall_can_trigger_wipe() -> void:
	cases += 1
	var rules: Rules = _new([1, 2], 1)
	var events: Array[Dictionary] = _events(rules)
	rules.fall(1)
	_revive(rules, 2, 1)
	rules.fall(2)
	rules.fall(1)
	_check(not rules.live and rules.is_eliminated(1) and rules.is_eliminated(2), "last active member's second fall ends remaining rescue opportunity")
	_check(events[-2].payload.reason == "second_fall" and events[-1].payload.reason == "squad_wipe", "direct elimination and cascading wipe retain distinct reasons")
	_check(_count(events, "squad_eliminated") == 2, "mixed final-fall and wipe paths count each actor once")


func _test_end_freezes_authority() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	rules.fall(2)
	rules.begin_revive(1, 2)
	rules.advance_revive(1, 2, 3.0)
	rules.step(2.0)
	rules.set_live(false)
	var frozen: Dictionary = rules.members.duplicate(true)
	var count: int = events.size()
	_check(frozen[2].reviver == 0 and frozen[2].revive_progress == 0.0 and frozen[2].bleed_left == 33.0, "match freeze releases holds while retaining life state and remaining bleed budget")
	_check(not rules.fall(1) and not rules.begin_revive(1, 2) and not rules.advance_revive(1, 2, 6.0), "ended commands cannot mutate the squad")
	rules.step(100.0)
	rules.cancel_revive(1)
	rules.set_live(false)
	_check(rules.members == frozen and events.size() == count, "ended timers and repeated cleanup remain frozen")


func _test_reconfigure() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.fall(2)
	_revive(rules, 1, 2)
	rules.fall(3)
	rules.begin_revive(1, 3)
	rules.advance_revive(1, 3, 4.0)
	rules.configure([10, 20], 20)
	_check(not rules.live and rules.human_id == 20 and rules.members.size() == 2, "rematch replaces roster and starts preparation")
	_check(rules.member(1).is_empty() and rules.member(2).is_empty() and rules.member(3).is_empty(), "old actor IDs have no authority in new match")
	_check(rules.member(10).recoveries == 0 and rules.member(20).recoveries == 0 and rules.member(10).reviver == 0, "rematch resets recovery counts, channels and life timers")
	rules.set_live(true)
	_check(not rules.advance_revive(1, 3, 6.0) and rules.fall(10), "stale hold commands reject while fresh roster remains playable")


func _test_helper_reuse_has_no_global_cooldown() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.fall(2)
	rules.fall(3)
	_revive(rules, 1, 2)
	_check(rules.begin_revive(1, 3), "completing one rescue immediately frees its helper without a global cooldown")
	rules.advance_revive(1, 3, 6.0)
	_check(rules.is_active(2) and rules.is_active(3) and rules.member(1).recoveries == 0, "rescuing does not consume the helper's personal recovery opportunity")


func _test_invalid_roster_cannot_activate() -> void:
	cases += 1
	var rules: Rules = _new([], 1)
	_check(not rules.live and rules.members.is_empty() and rules.human_id == 0, "empty squad cannot become live")
	rules.configure([2, 3], 1)
	rules.set_live(true)
	_check(not rules.live and rules.human_id == 0 and not rules.fall(2), "foreign human ID cannot create an orphan playable squad")
	rules.configure([1], 1)
	rules.set_live(true)
	rules.fall(1)
	_check(not rules.live and rules.is_eliminated(1), "one-member roster cannot wait for an impossible rescuer")


func _test_bleedout_and_rescue_ordering() -> void:
	cases += 1
	var rules: Rules = _new()
	rules.fall(2)
	rules.begin_revive(1, 2)
	rules.advance_revive(1, 2, 5.9)
	rules.step(34.9)
	rules.advance_revive(1, 2, 0.1)
	rules.step(0.1)
	_check(rules.is_active(2), "accepted completion before expiry cancels its bleedout deadline")
	rules.fall(3)
	rules.begin_revive(1, 3)
	rules.advance_revive(1, 3, 5.9)
	rules.step(35.0)
	_check(not rules.advance_revive(1, 3, 0.1) and rules.is_eliminated(3), "already-resolved expiry cannot be reversed by a late completion")


func _test_freeze_clears_all_reservations_once() -> void:
	cases += 1
	var rules: Rules = _new()
	var events: Array[Dictionary] = _events(rules)
	rules.fall(2)
	rules.fall(4)
	rules.begin_revive(1, 2)
	rules.begin_revive(3, 4)
	rules.advance_revive(1, 2, 2.0)
	rules.advance_revive(3, 4, 4.0)
	rules.set_live(false)
	rules.set_live(false)
	_check(_count(events, "squad_revive_interrupted") == 2, "freezing concurrent channels interrupts each exactly once")
	for event: Dictionary in events:
		if event.kind == "squad_revive_interrupted":
			_check(not event.live and event.members[2].reviver == 0 and event.members[4].reviver == 0, "every freeze event observes all helper locks already cleared")
