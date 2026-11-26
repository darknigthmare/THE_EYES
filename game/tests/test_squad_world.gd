extends SceneTree
## Squad integration fixtures in the real main scene. Actors may be positioned
## explicitly to isolate spatial/lifecycle boundaries; no full-match claim is
## made here. The staged AI rescue at the end uses real navigation and physics.
## Run: godot --headless --fixed-fps 60 --audio-driver Dummy --path game
##      --script res://tests/test_squad_world.gd

const MAIN_SCENE = preload("res://scenes/main.tscn")
const Arena = preload("res://scripts/arena.gd")
const Props = preload("res://scripts/trial_apparatus.gd")
const Survivor = preload("res://scripts/survivor.gd")
const DT: float = 1.0 / 60.0
const HELPER_POINT: Vector3 = Vector3(-5, 0.05, 19)
const SUBJECT_POINT: Vector3 = Vector3(-5, 0.05, 17.8)
var game
var cases: int = 0
var assertions: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Engine.physics_ticks_per_second = 60
	game = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	game.qa_capture = "test-only-no-file"
	game.qa_done = true
	game.soundscape.set_enabled(false)
	await _test_populations_and_identity()
	await _test_preparation_and_membership()
	await _test_downed_legacy_actions()
	await _test_downed_collection_actions()
	await _test_downed_ritual_occupancy()
	await _test_rescue_range_and_sight()
	await _test_rescue_release_and_movement()
	await _test_rescue_damage_interruption()
	await _test_pause_resets_rescue()
	await _test_human_rescue_reservations()
	await _test_bot_rescue_reservations()
	await _test_helper_fall_releases_rescue()
	await _test_six_second_rescue_and_protection()
	await _test_elimination_and_wipe_counts()
	await _test_keeper_self_and_ties()
	await _test_keeper_allies_and_cooldown()
	await _test_keeper_range_and_occlusion()
	await _test_orders_and_escape_override()
	await _test_combined_relay_tick()
	await _test_spectator_and_team_escape()
	await _test_session_reset()
	await _test_eye_perception()
	await _test_real_bot_walk_and_rescue()
	_release_inputs()
	game.soundscape.stop_all()
	await process_frame
	await process_frame
	game.queue_free()
	await process_frame
	await process_frame
	print("Squad world integration: %d cases, %d assertions, %d failures" % [cases, assertions, failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)


func _near(actual: float, expected: float, description: String) -> void:
	_check(absf(actual - expected) < 0.001, "%s (%.4f vs %.4f)" % [description, actual, expected])


func _release_inputs() -> void:
	for action: String in ["interact", "move_left", "move_right", "move_forward", "move_back", "jump", "sprint", "crouch", "ability"]:
		Input.action_release(action)


func _start_isolated(contract: String = "first", role: String = "squad", archetype: String = "Veil", begin_live: bool = true) -> void:
	_release_inputs()
	game.start_match(role, archetype, "story", 271126, contract)
	game.soundscape.set_enabled(false)
	game.set_physics_process(false)
	for actor: EyesSurvivor in game.actors:
		actor.active = false
	await physics_frame
	await physics_frame
	if begin_live:
		game.director.step(8.0)


func _put(actor: EyesSurvivor, point: Vector3) -> void:
	actor.global_position = point
	actor.velocity = Vector3.ZERO
	actor.move_target = point


func _down(actor: EyesSurvivor) -> void:
	# Isolated damage fixture: remove spawn/previous-hit protection, then use the
	# real damage boundary and its state events. Never directly set life state.
	actor.respawn_shield = 0.0
	actor.invulnerability = 0.0
	game._hurt(actor, 1000.0, "Integration fixture wound")


func _stage_pair() -> void:
	await _start_isolated()
	_put(game.player, HELPER_POINT)
	_put(game.bots[0].actor, SUBJECT_POINT)
	for index: int in range(1, 4):
		_put(game.bots[index].actor, Vector3(-17 + index * 2, 0.05, 20))
	_down(game.bots[0].actor)


func _row(actor: EyesSurvivor) -> Dictionary:
	return game.squad_world.state.member(actor.get_instance_id())


func _pulse(ticks: int) -> void:
	for tick: int in range(ticks):
		game.squad_world.step(DT)


func _event_count(kind: String) -> int:
	var count: int = 0
	for entry: Dictionary in game.event_log:
		if entry.kind == kind:
			count += 1
	return count


func _wall_between(first: Vector3, second: Vector3) -> StaticBody3D:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.3, 2.5, 0.18)
	collision.shape = shape
	wall.add_child(collision)
	game.add_child(wall)
	wall.global_position = Vector3((first.x + second.x) * 0.5, 1.25, (first.z + second.z) * 0.5)
	wall.rotation.y = atan2(second.x - first.x, second.z - first.z)
	return wall


func _finish_first_contract() -> void:
	# Legal authority commands stage the exit phase for order/result fixtures.
	# Spatial objective completion has separate First and Second world suites.
	for index: int in range(3):
		game.director.deliver_mote()
	for symbol: int in game.director.echo_sequence:
		game.director.input_echo(symbol)
	game.director.charge_relay(12.0, true)


func _order_input(value: String) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = "squad_" + value
	event.pressed = true
	game._unhandled_input(event)


func _test_populations_and_identity() -> void:
	cases += 1
	for archetype: String in ["Veil", "Tinker", "Runner", "Keeper"]:
		await _start_isolated("first", "squad", archetype)
		_check(game.session_mode == "squad" and game.mode == "survivor", archetype + " selects the explicit local Squad session")
		_check(game.actors.size() == 5 and game.bots.size() == 4 and game.director.alive_count == 5, archetype + " spawns one human and four allies")
		var names: Dictionary = {}
		var ids: Dictionary = {}
		for actor: EyesSurvivor in game.actors:
			names[actor.display_name] = true
			ids[actor.get_instance_id()] = true
			_check(actor.team_id == game.player.get_instance_id() and _row(actor).state == "active", "roster membership and team identity agree for " + actor.display_name)
			_check((actor.body_mesh.get_node("NameTag") as Label3D).text.contains(actor.display_name), "world nameplate identifies " + actor.display_name)
		_check(names.size() == 5 and ids.size() == 5 and game.squad_world.hud_data().members.size() == 5, archetype + " has five distinct identities in world and HUD")
		_check(game.get_viewport().get_camera_3d() == game.player.camera, "Squad starts at the human camera")
	await _start_isolated("first", "survivor")
	_check(game.actors.size() == 1 and game.bots.is_empty() and game.squad_world == null and game.director.alive_count == 1, "legacy solo population and authority remain unchanged")
	await _start_isolated("first", "eye")
	_check(game.actors.size() == 4 and game.bots.size() == 4 and game.squad_world == null and game.director.alive_count == 4, "legacy Eye retains four autonomous survivors")
	_check(game.player not in game.actors and game.get_viewport().get_camera_3d() == game.eye_camera, "Eye does not silently gain a fifth human survivor")


func _test_preparation_and_membership() -> void:
	cases += 1
	await _start_isolated("first", "squad", "Keeper", false)
	_check(not game.squad_world.state.live and game.director.phase == "preparation", "grace freezes squad life authority")
	game._hurt(game.player, 1000.0, "Preparation fixture")
	_check(game.player.health == 100.0 and not game.squad_world.state.fall(game.player.get_instance_id()), "preparation rejects damage and falls")
	_check(not game.squad_world.try_ability(game.player) and game.player.ability_cooldown == 0.0, "preparation ability rejection does not spend cooldown")
	_order_input("follow")
	_check(game.squad_world.order == "follow", "leader may plan a follow order during grace")
	game.director.step(8.0)
	_check(game.squad_world.state.live, "real director hunt event activates squad authority immediately")
	var foreign: EyesSurvivor = Survivor.new()
	game.add_child(foreign)
	foreign.reset_body(HELPER_POINT, "Keeper", true)
	foreign.team_id = game.player.team_id
	foreign.active = false
	_check(not game.squad_world.eligible(foreign) and not game.squad_world.try_ability(foreign), "matching a team ID cannot grant foreign roster membership")
	game._hurt(foreign, 1000.0, "Foreign fixture")
	_check(foreign.health == 100.0 and not game.squad_world.state.fall(foreign.get_instance_id()), "foreign actor cannot mutate match casualties")
	foreign.queue_free()
	await process_frame


func _test_downed_legacy_actions() -> void:
	cases += 1
	await _start_isolated("first", "squad", "Keeper")
	var actor: EyesSurvivor = game.player
	_put(actor, Arena.MOTE_POSITIONS[0] + Vector3(0, 0.05, 0.8))
	_check(game._pickup(actor, 0), "active human physically acquires a legacy mote")
	_put(actor, Arena.STATIONS.echoes + Vector3(0, 0.05, 2.0))
	game._interact_player()
	_check(game.echo_open and actor.controls_locked, "legacy Echo panel can be opened before a fall")
	_down(actor)
	_check(actor.downed and actor.health == 0.0 and not actor.eliminated and game.director.alive_count == 5, "first lethal hit downs without reducing alive count")
	_check(not game.punishment and not game.punishment_used and not game.echo_open and not actor.controls_locked, "Squad fall closes Echo without invoking solo Second Sight")
	_check(actor.carrying == -1 and game.motes_state[0] == 0 and game.arena.motes[0].visible, "fall drops carried legacy cargo back into the real world")
	_check(not game._pickup(actor, 0) and not game._deliver(actor), "downed body cannot pick up or deliver a mote")
	var wounds: int = game.metrics.wounds
	game._hurt(actor, 20.0, "Repeated fixture")
	_check(game.metrics.wounds == wounds and not actor.damage(20.0), "downed body cannot receive repeated wounds")
	_check(not actor.use_ability() and not game.squad_world.try_ability(actor) and actor.ability_cooldown == 0.0, "downed Keeper cannot heal or spend an ability")
	_check(not game.squad_world.set_order("hold"), "downed human cannot issue orders")
	_put(actor, Arena.STATIONS.relay + Vector3(0, 0.05, 2.0))
	Input.action_press("interact")
	_near(game._update_player_objectives(2.0), 0.0, "downed human contributes no relay rate")
	_near(game.director.relay_progress, 0.0, "downed input does not charge the relay")
	Input.action_release("interact")
	_put(actor, HELPER_POINT)
	var before: Vector3 = actor.global_position
	actor.active = true
	Input.action_press("move_forward")
	Input.action_press("jump")
	for tick: int in range(30):
		await physics_frame
	_release_inputs()
	actor.active = false
	_check(Vector2(actor.global_position.x - before.x, actor.global_position.z - before.z).length() < 0.01 and actor.velocity.y <= 0.1, "real downed controller cannot walk or jump")
	_near((actor.collider.shape as CapsuleShape3D).height, 0.7, "downed controller presents the lowered physical capsule")


func _test_downed_collection_actions() -> void:
	cases += 1
	await _start_isolated("second")
	var actor: EyesSurvivor = game.player
	var trial = game.director.trial_set
	var relic: int = trial.vault_targets[0]
	_put(actor, Props.RELIC_POSITIONS[relic] + Vector3(0, 0.05, 0.8))
	_check(game.trial_world.perform(actor, "vault_pickup", relic), "active squad member acquires required Vault cargo")
	_down(actor)
	_check(trial.carried_relic(actor.get_instance_id()) == -1 and trial.relic_available(relic), "down releases the required relic for other survivors")
	var commands: Array[Dictionary] = [
		{"kind":"vault_read", "point":Props.VAULT_DESK, "index":0},
		{"kind":"vault_pickup", "point":Props.RELIC_POSITIONS[relic], "index":relic},
		{"kind":"vault_deposit", "point":Props.CRADLE_POSITIONS[0], "index":0},
		{"kind":"ember_pickup", "point":Props.EMBER_POSITION, "index":0},
		{"kind":"ritual_light", "point":Props.VESSEL_POSITIONS[0], "index":0},
		{"kind":"clock_turn", "point":Props.CLOCK_LEVERS[0], "index":0},
		{"kind":"clock_reset", "point":Props.CLOCK_CENTER, "index":0},
		{"kind":"clock_confirm", "point":Props.CLOCK_CENTER, "index":0},
	]
	var hands: Array[int] = trial.clock_hands.duplicate()
	for command: Dictionary in commands:
		_put(actor, command.point + Vector3(0, 0.05, 0.8))
		_check(not game.trial_world.perform(actor, command.kind, command.index), "downed dispatcher rejects nearby " + command.kind)
		_check(game.trial_world.nearest(actor).is_empty(), "downed body offers no " + command.kind + " interaction")
	_check(trial.clock_hands == hands and trial.vault_carriers.is_empty() and trial.ember_owner == 0 and trial.ritual_index == 0, "rejected downed commands preserve apparatus state")
	var other: EyesSurvivor = game.bots[0].actor
	_put(other, Props.EMBER_POSITION + Vector3(0, 0.05, 0.8))
	_check(game.trial_world.perform(other, "ember_pickup"), "active ally can carry the shared ember")
	_down(other)
	_check(trial.ember_owner == 0 and not game.trial_world.has_cargo(other), "fall returns the shared ember instead of stranding it on a body")


func _test_downed_ritual_occupancy() -> void:
	cases += 1
	await _start_isolated("second")
	var trial = game.director.trial_set
	var operator: EyesSurvivor = game.bots[0].actor
	_put(operator, Props.EMBER_POSITION + Vector3(0, 0.05, 0.8))
	_check(game.trial_world.perform(operator, "ember_pickup"), "Ritual occupancy fixture takes the real ember")
	for vessel: int in trial.ritual_sequence:
		_put(operator, Props.VESSEL_POSITIONS[vessel] + Vector3(0, 0.05, 0.6))
		_check(game.trial_world.perform(operator, "ritual_light", vessel), "Ritual occupancy fixture lights vessel " + str(vessel))
		game.director.step(0.35)
	_check(trial.ritual_index == 5, "five actual vessel commands arm the hold")
	_put(operator, HELPER_POINT)
	_put(game.player, Props.RITUAL_CENTER + Vector3(1.5, 0.05, 0))
	_down(game.player)
	game.trial_world.step(2.0)
	_near(trial.ritual_hold, 0.0, "downed body inside the physical ring is not an eligible occupant")
	_put(operator, Props.RITUAL_CENTER + Vector3(-1.5, 0.05, 0))
	game.trial_world.step(2.0)
	_near(trial.ritual_hold, 2.0, "active ally in the same ring advances its hold")
	_put(operator, HELPER_POINT)
	game.trial_world.step(DT)
	_check(trial.ritual_hold == 0.0 and trial.ritual_index == 5, "leaving only a downed occupant resets hold while preserving completed vessels")


func _test_rescue_range_and_sight() -> void:
	cases += 1
	await _stage_pair()
	var subject: EyesSurvivor = game.bots[0].actor
	var world: EyesSquadWorld = game.squad_world
	_check(world.in_rescue_range(game.player, subject), "nearby downed ally has a clear real rescue ray")
	_check(not world.in_rescue_range(subject, subject), "downed actor cannot rescue itself")
	_check(world._hold_rescue(game.player, subject, 1.0), "valid physical hold begins")
	var wall: StaticBody3D = _wall_between(game.player.global_position, subject.global_position)
	await physics_frame
	await physics_frame
	_check(not game.has_sight(game.player.target_point(), subject.target_point()) and not world.in_rescue_range(game.player, subject), "real wall blocks rescue within nominal reach")
	_check(not world._hold_rescue(game.player, subject, DT) and _row(subject).reviver == 0 and _row(subject).revive_progress == 0.0, "occlusion interrupts and clears the entire rescue hold")
	wall.queue_free()
	await physics_frame
	await physics_frame
	_put(game.player, subject.global_position + Vector3(0, 0, 1.81))
	_check(not world._hold_rescue(game.player, subject, 1.0), "rescue rejects an unobstructed target beyond 1.8 metres")
	_put(game.player, subject.global_position + Vector3(0, 0, 1.79))
	_check(world._hold_rescue(game.player, subject, 1.0), "rescue accepts the inner side of its range boundary")
	_put(game.player, subject.global_position + Vector3(0, 0, 1.81))
	world._hold_rescue(game.player, subject, DT)
	_near(_row(subject).revive_progress, 0.0, "leaving range does not bank an earlier hold")


func _test_rescue_release_and_movement() -> void:
	cases += 1
	await _stage_pair()
	var subject: EyesSurvivor = game.bots[0].actor
	Input.action_press("interact")
	_pulse(120)
	_near(_row(subject).revive_progress, 2.0, "continuous E advances the actual human rescue path")
	Input.action_release("interact")
	game.squad_world.step(DT)
	_check(_row(subject).revive_progress == 0.0 and _row(subject).reviver == 0, "releasing E resets progress and ownership")
	Input.action_press("interact")
	_pulse(60)
	Input.action_press("move_forward")
	game.squad_world.step(DT)
	_near(_row(subject).revive_progress, 0.0, "movement input interrupts before the controller moves")
	Input.action_release("move_forward")
	_pulse(60)
	game.player.velocity = Vector3(0.4, 0, 0)
	game.squad_world.step(DT)
	_near(_row(subject).revive_progress, 0.0, "actual horizontal velocity also interrupts a hold")
	game.player.velocity = Vector3.ZERO
	_pulse(60)
	Input.action_press("jump")
	game.squad_world.step(DT)
	_near(_row(subject).revive_progress, 0.0, "jump input cannot preserve rescue progress")
	Input.action_release("jump")
	_pulse(60)
	game.player.velocity = Vector3(0, 0.6, 0)
	game.squad_world.step(DT)
	_near(_row(subject).revive_progress, 0.0, "airborne motion interrupts even without horizontal input")
	game.player.velocity = Vector3.ZERO
	_release_inputs()
	_check(_event_count("squad_revive_interrupted") == 5, "each real release/movement interruption emits exactly once")


func _test_rescue_damage_interruption() -> void:
	cases += 1
	await _stage_pair()
	var subject: EyesSurvivor = game.bots[0].actor
	Input.action_press("interact")
	_pulse(120)
	game.player.respawn_shield = 0.0
	game.player.invulnerability = 0.0
	game._hurt(game.player, 1.0, "Rescuer interruption fixture")
	_check(game.player.health == 99.0 and _row(subject).revive_progress == 0.0 and _row(subject).reviver == 0, "real wound immediately cancels the helper's reservation")
	_check(not game.squad_world._hold_rescue(game.player, subject, DT), "damage interruption cannot reacquire in the same tick")
	Input.action_release("interact")
	game.squad_world.step(0.29)
	_check(not game.squad_world._hold_rescue(game.player, subject, DT), "interruption delay lasts through 0.29 seconds")
	game.squad_world.step(0.02)
	Input.action_press("interact")
	_pulse(60)
	_near(_row(subject).revive_progress, 1.0, "resumed rescue starts at zero after the damage delay")
	_check(subject.downed and _event_count("squad_revived") == 0, "interrupted partial holds cannot combine into a premature rescue")


func _test_human_rescue_reservations() -> void:
	cases += 1
	await _stage_pair()
	var first: EyesSurvivor = game.bots[0].actor
	var nearer: EyesSurvivor = game.bots[1].actor
	Input.action_press("interact")
	_pulse(60)
	_put(nearer, HELPER_POINT + Vector3(0.55, 0, -0.55))
	_down(nearer)
	_check(game.squad_world.nearby_downed(game.player) == first, "new closer casualty cannot steal the human's existing valid hold")
	_pulse(60)
	_near(_row(first).revive_progress, 2.0, "original human reservation continues without restarting")
	_near(_row(nearer).revive_progress, 0.0, "unselected nearer casualty gains no phantom progress")
	Input.action_release("interact")
	game.squad_world.step(DT)
	var helper: EyesSurvivor = game.bots[2].actor
	_put(helper, nearer.global_position + Vector3(0.5, 0, 0))
	_check(game.squad_world._hold_rescue(helper, nearer, 1.0), "AI helper reserves the nearer body")
	_check(game.squad_world.nearby_downed(game.player) == first, "human selection skips a body already owned by another helper")
	Input.action_press("interact")
	_pulse(60)
	_check(_row(first).reviver == game.player.get_instance_id() and _row(nearer).reviver == helper.get_instance_id(), "two valid rescuers retain separate subject ownership")


func _test_pause_resets_rescue() -> void:
	cases += 1
	await _stage_pair()
	var subject: EyesSurvivor = game.bots[0].actor
	Input.action_press("interact")
	_pulse(120)
	var bleed: float = _row(subject).bleed_left
	game._pause()
	_check(paused and not game.squad_world.state.live and _row(subject).reviver == 0 and _row(subject).revive_progress == 0.0, "real pause resets the partial rescue and freezes life authority")
	game.squad_world.state.step(10.0)
	for tick: int in range(3):
		await process_frame
	_near(_row(subject).bleed_left, bleed, "paused scene preserves the downed actor's remaining bleed budget")
	_check(not game.squad_world.state.advance_revive(game.player.get_instance_id(), subject.get_instance_id(), 6.0), "paused life authority cannot finish a rescue")
	game._resume()
	game.squad_world.step(DT)
	_check(not paused and game.squad_world.state.live and subject.downed, "resume reactivates a live match without granting a free recovery")
	_check(not Input.is_action_pressed("interact"), "pause/resume releases the stale held rescue action")
	_near(_row(subject).revive_progress, 0.0, "resume alone cannot restart the cancelled rescue")
	Input.action_press("interact")
	game.squad_world.step(DT)
	_near(_row(subject).revive_progress, DT, "a fresh E press starts a new continuous rescue from zero")


func _test_bot_rescue_reservations() -> void:
	cases += 1
	await _start_isolated()
	var helper: EyesSurvivor = game.bots[1].actor
	var existing: EyesSurvivor = game.bots[2].actor
	_put(game.player, HELPER_POINT + Vector3(0, 0, -0.3))
	_put(helper, HELPER_POINT)
	_put(existing, HELPER_POINT + Vector3(0, 0, -1.2))
	_put(game.bots[0].actor, HELPER_POINT + Vector3(0, 0, 1.5))
	_put(game.bots[3].actor, Vector3(-15, 0.05, 20))
	_down(existing)
	_check(game.squad_world._hold_rescue(helper, existing, 1.0), "AI reservation fixture starts a valid later-roster channel")
	game.squad_world._assign_rescuers()
	_down(game.player)
	game.squad_world._assign_rescuers()
	_check(game.squad_world.assignments.get(existing.get_instance_id(), 0) == helper.get_instance_id(), "new earlier-roster casualty cannot steal a channeling AI helper")
	_near(_row(existing).revive_progress, 1.0, "assignment refresh preserves the valid existing hold")
	var assigned: Array = game.squad_world.assignments.values()
	_check(assigned.size() == 2 and assigned[0] != assigned[1], "two reachable casualties receive distinct helpers")
	_check(game.squad_world.assignments.get(game.player.get_instance_id(), 0) != helper.get_instance_id(), "new casualty uses a free helper instead of breaking a reservation")


func _test_helper_fall_releases_rescue() -> void:
	cases += 1
	await _stage_pair()
	var subject: EyesSurvivor = game.bots[0].actor
	Input.action_press("interact")
	_pulse(60)
	_down(game.player)
	_check(game.player.downed and subject.downed and game.director.alive_count == 5, "helper fall leaves two rescuable casualties without premature eliminations")
	_check(_row(subject).reviver == 0 and _row(subject).revive_progress == 0.0, "falling helper releases its subject and all partial progress")
	_check(not game.squad_world._hold_rescue(game.player, subject, 6.0), "fallen helper cannot complete the old hold")
	_check(game.squad_world.state.live and _event_count("result") == 0, "remaining active allies keep the team alive")


func _test_six_second_rescue_and_protection() -> void:
	cases += 1
	await _stage_pair()
	var subject: EyesSurvivor = game.bots[0].actor
	Input.action_press("interact")
	_pulse(359)
	_check(subject.downed and subject.health == 0.0 and _event_count("squad_revived") == 0, "359 fixed ticks do not complete a six-second rescue")
	_near(_row(subject).revive_progress, 359.0 * DT, "physical hold accumulates the expected pre-completion budget")
	game.squad_world.step(DT)
	Input.action_release("interact")
	_check(not subject.downed and subject.active and not subject.eliminated and _row(subject).recoveries == 1, "tick 360 restores the actual actor and records its one recovery")
	_near(subject.health, 35.0, "rescue restores exactly 35 HP")
	_near(subject.respawn_shield, 5.0, "rescue grants exactly five seconds of protection")
	_check(game.director.alive_count == 5 and _event_count("squad_revived") == 1, "successful rescue neither duplicates a life nor emits duplicate success")
	var wounds: int = game.metrics.wounds
	game._hurt(subject, 7.0, "Protected fixture")
	_check(subject.health == 35.0 and game.metrics.wounds == wounds, "immediate damage is rejected after rescue")
	for tick: int in range(241):
		await physics_frame
	game._hurt(subject, 7.0, "Still protected fixture")
	_check(subject.health == 35.0 and subject.respawn_shield > 0.8 and subject.respawn_shield < 1.1, "real controller keeps protection beyond its shorter hit invulnerability")
	for tick: int in range(62):
		await physics_frame
	game._hurt(subject, 7.0, "Expired protection fixture")
	_check(subject.respawn_shield == 0.0 and subject.health == 28.0 and game.metrics.wounds == wounds + 1, "real controller expires protection after five seconds and accepts damage")
	subject.active = false


func _test_elimination_and_wipe_counts() -> void:
	cases += 1
	await _stage_pair()
	var recovered: EyesSurvivor = game.bots[0].actor
	Input.action_press("interact")
	_pulse(360)
	Input.action_release("interact")
	recovered.active = false
	_down(recovered)
	_check(recovered.eliminated and not recovered.downed and not recovered.visible and game.director.alive_count == 4, "second fall after recovery eliminates exactly one actual actor")
	var events: int = _event_count("squad_eliminated")
	_down(recovered)
	_check(game.director.alive_count == 4 and _event_count("squad_eliminated") == events, "repeated lethal reports cannot decrement the team again")
	var expired: EyesSurvivor = game.bots[1].actor
	_down(expired)
	game.squad_world.state.step(35.0)
	_check(expired.eliminated and game.director.alive_count == 3, "bleedout propagates one elimination to match authority")
	_down(game.player)
	_down(game.bots[2].actor)
	_check(game.director.phase == "hunt", "last active rescuer keeps two downed allies recoverable")
	_down(game.bots[3].actor)
	_check(game.director.phase == "ended" and game.director.winner == "eye" and game.director.alive_count == 0, "no active rescuers resolves all remaining downed members into team loss")
	_check(_event_count("squad_eliminated") == 5 and _event_count("result") == 1 and game.squad_world.counters.eliminations == 5, "wipe produces five total eliminations and exactly one result")
	for actor: EyesSurvivor in game.actors:
		_check(actor.eliminated and not actor.downed and not actor.active and not actor.visible, "wipe freezes and removes " + actor.display_name)
	var before: Dictionary = game.squad_world.summary()
	game.squad_world.step(100.0)
	game._hurt(game.player, 1000.0, "After result fixture")
	_check(game.squad_world.summary() == before and _event_count("result") == 1 and not game.squad_world.state.live, "terminal squad cannot restart timers, wounds or results")


func _test_keeper_self_and_ties() -> void:
	cases += 1
	await _start_isolated("first", "squad", "Keeper")
	_put(game.player, HELPER_POINT)
	_put(game.bots[0].actor, SUBJECT_POINT)
	game.player.health = 20.0
	game.bots[0].actor.health = 90.0
	_check(game.squad_world.healing_target(game.player) == game.player, "critically wounded Keeper prioritizes itself over a healthier nearby ally")
	game.squad_world.auto_ability(game.player)
	_check(game.player.health == 50.0 and game.bots[0].actor.health == 90.0 and game.squad_world.counters.heals == 1, "automatic Keeper self-heal succeeds instead of refusing the healthier target")
	await _start_isolated("first", "squad", "Keeper")
	_put(game.player, HELPER_POINT)
	_put(game.bots[0].actor, SUBJECT_POINT)
	game.player.health = 50.0
	game.bots[0].actor.health = 50.0
	_check(game.squad_world.healing_target(game.player) == game.player, "equal HP tie retains the Keeper as recipient")
	_check(game.squad_world.try_ability(game.player) and game.player.health == 80.0 and game.bots[0].actor.health == 50.0, "tie policy affects the actual healed actor")


func _test_keeper_allies_and_cooldown() -> void:
	cases += 1
	await _start_isolated("first", "squad", "Keeper")
	var ally: EyesSurvivor = game.bots[0].actor
	_put(game.player, HELPER_POINT)
	_put(ally, SUBJECT_POINT)
	_put(game.bots[1].actor, Vector3(15, 0.05, 19))
	game.player.health = 65.0
	ally.health = 10.0
	game.bots[1].actor.health = 1.0
	_check(game.squad_world.healing_target(game.player) == ally, "Keeper selects the most injured eligible nearby ally rather than a distant critical member")
	_check(game.squad_world.try_ability(game.player), "nearby ally heal uses the real ability boundary")
	_check(ally.health == 40.0 and game.player.health == 65.0 and game.bots[1].actor.health == 1.0, "Mend adds thirty HP only to its chosen physical recipient")
	_near(game.player.ability_cooldown, 35.0, "ally Mend consumes the ordinary Keeper cooldown")
	_check(not game.squad_world.try_ability(game.player) and ally.health == 40.0 and game.squad_world.counters.heals == 1, "cooldown blocks a repeated ally heal without duplicate healing events")
	_down(ally)
	_check(game.squad_world.healing_target(game.player) == game.player, "downed member is excluded from healing and needs a rescue")


func _test_keeper_range_and_occlusion() -> void:
	cases += 1
	await _start_isolated("first", "squad", "Keeper")
	var ally: EyesSurvivor = game.bots[0].actor
	_put(game.player, HELPER_POINT)
	_put(ally, HELPER_POINT + Vector3(0, 0, -4.01))
	game.player.health = 80.0
	ally.health = 10.0
	_check(not game.player.use_ability(ally) and game.player.ability_cooldown == 0.0 and ally.health == 10.0, "direct Keeper boundary rejects a target outside four metres without spending cooldown")
	_put(ally, HELPER_POINT + Vector3(0, 0, -2.0))
	_check(game.has_sight(game.player.target_point(), ally.target_point()), "healing fixture begins with a clear actual ray")
	var wall: StaticBody3D = _wall_between(game.player.global_position, ally.global_position)
	await physics_frame
	await physics_frame
	_check(not game.has_sight(game.player.target_point(), ally.target_point()), "real wall occludes the nearby injured ally")
	_check(not game.player.use_ability(ally) and game.player.ability_cooldown == 0.0 and ally.health == 10.0, "direct ability cannot heal through architecture")
	_check(game.squad_world.healing_target(game.player) == game.player, "automatic target selection also excludes an occluded ally")
	_check(game.squad_world.try_ability(game.player) and game.player.health == 100.0 and ally.health == 10.0, "blocked ally causes a legal capped self-heal, with no wall healing")
	wall.queue_free()
	await physics_frame
	await physics_frame


func _test_orders_and_escape_override() -> void:
	cases += 1
	await _start_isolated()
	# Keep this formation point outside the southern cover blocks; a nearest
	# free grid cell can legitimately be the ally's current position otherwise.
	_put(game.player, Vector3(-14, 0.05, 15))
	var data: Dictionary = game.bots[0]
	var actor: EyesSurvivor = data.actor
	_put(actor, Vector3(-14, 0.05, 20))
	_order_input("follow")
	_check(game.squad_world.order == "follow" and game.squad_world.counters.orders == 1, "real order input selects Follow once")
	_check(not game.squad_world.set_order("follow") and not game.squad_world.set_order("invented"), "duplicate and unknown orders do not mutate team order")
	_check(game.squad_world.drive_bot(data, 0, DT) and data.task == "follow" and not data.path.is_empty(), "Follow supplies an actual navigable formation path")
	var target: Vector3 = data.target
	var before: Vector3 = actor.global_position
	actor.active = true
	for tick: int in range(45):
		game.squad_world.drive_bot(data, 0, DT)
		await physics_frame
	actor.active = false
	_check(actor.global_position.distance_to(before) > 1.0 and actor.global_position.distance_to(target) < before.distance_to(target), "real ally controller walks toward the Follow formation (from %s to %s, target %s, path %s)" % [before, actor.global_position, target, data.path])
	_order_input("hold")
	var held: Vector3 = actor.global_position
	_put(game.player, Vector3(8, 0.05, 19))
	_check(game.squad_world.drive_bot(data, 0, DT) and data.task == "hold" and data.target.is_equal_approx(held), "Hold retains the ally's order-time position when the leader moves")
	_order_input("work")
	_check(not game.squad_world.drive_bot(data, 0, DT), "Work returns the ally to ordinary trial decision authority")
	game._update_bots(DT, false)
	_check(data.task not in ["hold", "follow", "rescue", ""] and not data.path.is_empty(), "Work selects a real objective and route")
	_order_input("hold")
	_finish_first_contract()
	_check(game.director.phase == "escape" and game.squad_world.state.live, "three legal seals activate the real escape phase")
	game._update_bots(DT, false)
	for bot: Dictionary in game.bots:
		_check(bot.task == "escape", "open exit overrides Hold for " + bot.actor.display_name)
	_check(game.squad_world.order == "hold", "evacuation priority preserves the leader's chosen order as metadata")


func _test_spectator_and_team_escape() -> void:
	cases += 1
	await _start_isolated()
	_down(game.player)
	game.squad_world.state.step(35.0)
	_check(game.player.eliminated and game.director.alive_count == 4 and game.director.phase == "hunt", "human bleedout allows surviving allies to continue")
	var watched: EyesSurvivor = game.bots[0].actor
	_check(game.get_viewport().get_camera_3d() == game.spectator_camera and game._spectator_actor() == watched, "human elimination switches the actual viewport to an ally spectator camera")
	_check(game.spectator_camera.global_position.is_equal_approx(watched.head.global_position - watched.global_basis.z * 0.24), "spectator camera is attached to the selected ally's current head location")
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_3
	key.pressed = true
	game._unhandled_input(key)
	watched = game.bots[2].actor
	_check(game._spectator_actor() == watched, "real numeric input switches to ally three")
	_put(watched, Vector3(6, 0.05, 19))
	game._update_spectator()
	_check(game.spectator_camera.global_position.is_equal_approx(watched.head.global_position - watched.global_basis.z * 0.24), "spectator updates its actual camera when the selected ally moves")
	_down(watched)
	game.squad_world.state.step(35.0)
	game._update_spectator()
	_check(game._spectator_actor() == game.bots[3].actor, "spectator skips an eliminated selected ally")
	var wheel: InputEventMouseButton = InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	game._unhandled_input(wheel)
	_check(game._spectator_actor() == game.bots[0].actor, "real mouse wheel wraps the surviving ally cameras")
	_finish_first_contract()
	game.director.register_escape()
	_check(game.director.winner == "survivors" and game.director.escaped_count == 1 and _event_count("result") == 1, "one allied escape still wins the team match after human elimination")
	_check(not game.squad_world.state.live and game.player.eliminated, "team victory freezes life authority without resurrecting the spectator")
	await _start_isolated("first", "survivor")
	_check(game.get_viewport().get_camera_3d() == game.player.camera and not game.spectator_camera.current and game.squad_world == null, "restarting from a spectator result restores the actual solo camera and clears Squad")


func _test_combined_relay_tick() -> void:
	cases += 1
	await _start_isolated()
	var point: Vector3 = Arena.STATIONS.relay + Vector3(0, 0.05, 2.4)
	_put(game.player, point)
	for data: Dictionary in game.bots:
		_put(data.actor, point)
		data.task = "relay"
		data.target = point
		data.think = 10.0
		data.repath = 10.0
		data.action_time = 0.0
		data.hiding = 0.0
	Input.action_press("interact")
	game._physics_process(1.0)
	_near(game.director.relay_progress, 0.15, "one real main tick caps the human plus four allies at 1.8 relay rate and applies it once")
	_check(not game.director.seals.relay and game.director.phase == "hunt", "one stacked relay tick does not prematurely complete the seal")
	await _start_isolated()
	_put(game.player, point)
	for data: Dictionary in game.bots:
		data.task = "relay"
		data.target = point
		data.think = 10.0
		data.repath = 10.0
		data.action_time = 0.0
		data.hiding = 0.0
	Input.action_press("interact")
	game._physics_process(1.0)
	_near(game.director.relay_progress, 1.0 / 12.0, "human-only hold gains its full rate despite the empty allied contribution pass")
	game._physics_process(1.0)
	_near(game.director.relay_progress, 2.0 / 12.0, "following main tick neither double-charges nor decays the human's ongoing hold")
	Input.action_release("interact")


func _test_session_reset() -> void:
	cases += 1
	await _stage_pair()
	Input.action_press("interact")
	_pulse(60)
	var previous: EyesSquadWorld = game.squad_world
	var previous_bot: WeakRef = weakref(game.bots[0].actor)
	await _start_isolated("first", "survivor")
	_check(game.squad_world == null and not previous.state.live and previous.assignments.is_empty(), "leaving Squad shuts down its authority and reservations")
	_check(previous_bot.get_ref() == null and game.actors.size() == 1 and game.player.team_id == 0 and not game.player.downed, "solo restart removes old allies and clears the human's team/life flags")
	_check(game.get_viewport().get_camera_3d() == game.player.camera, "solo restart restores the real human camera")
	await _start_isolated()
	_check(game.squad_world != previous and game.squad_world.order == "work" and game.squad_world.counters.downs == 0 and game.squad_world.counters.revives == 0, "fresh Squad owns a clean state machine and counters")
	for actor: EyesSurvivor in game.actors:
		_check(_row(actor).state == "active" and _row(actor).recoveries == 0 and actor.health == 100.0, "rematch restores a fresh recovery budget for " + actor.display_name)
	_check(not previous.state.fall(game.player.get_instance_id()) and game.director.alive_count == 5, "retained old authority cannot mutate the new session")


func _test_eye_perception() -> void:
	cases += 1
	await _start_isolated()
	for actor: EyesSurvivor in game.actors:
		_put(actor, Vector3(0, 0.05, 17))
		actor.gaze = 95.0
	var visible: EyesSurvivor = game.bots[0].actor
	var preferred: EyesSurvivor = game.bots[1].actor
	_put(visible, Vector3(0, 0.05, -10))
	_put(preferred, Vector3(2, 0.05, -10))
	visible.gaze = 20.0
	preferred.gaze = 60.0
	game.eye_forward = (Vector3(0, 1.2, -10) - Arena.SOCKETS[0]).normalized()
	_check(game.eye_sees(visible.target_point()) and game.eye_sees(preferred.target_point()), "Eye targeting fixture exposes two real visible allies")
	_check(not game.eye_sees(game.player.target_point()), "central architecture really occludes the higher-gaze human")
	_check(game._perceived_squad_target() == preferred, "Eye chooses a visible teammate without using the hidden human's higher score")
	_down(preferred)
	_check(game._perceived_squad_target() == visible, "downed visible teammate is excluded from Eye selection")
	game._update_eye_ai(DT)
	_check(game.last_seen.is_equal_approx(visible.target_point()) and game.sight_memory > 0.0, "Eye AI records the selected active teammate's visible position")
	_down(visible)
	_check(game._perceived_squad_target() == null, "Eye acquires no target when only downed or occluded members remain")
	game.squad_world.state.step(35.0)
	_check(preferred.eliminated and visible.eliminated and game._perceived_squad_target() == null, "eliminated actors cannot become perception targets again")


func _test_real_bot_walk_and_rescue() -> void:
	cases += 1
	await _start_isolated()
	_put(game.player, Vector3(-14, 0.05, 18))
	var data: Dictionary = game.bots[0]
	var helper: EyesSurvivor = data.actor
	_put(helper, Vector3(-14, 0.05, 9))
	for index: int in range(1, 4):
		_put(game.bots[index].actor, Vector3(17 + index, 0.05, 19))
	_down(game.player)
	var start: Vector3 = helper.global_position
	var travelled: float = 0.0
	var longest_path: int = 0
	var frames: int = 0
	helper.active = true
	while game.player.downed and frames < 60 * 18:
		game.squad_world.step(DT)
		game.squad_world.drive_bot(data, 0, DT)
		longest_path = maxi(longest_path, data.path.size())
		var previous: Vector3 = helper.global_position
		await physics_frame
		travelled += previous.distance_to(helper.global_position)
		frames += 1
	helper.active = false
	game.player.active = false
	var result: Dictionary = {"seconds":snappedf(frames * DT, 0.01), "travelled":snappedf(travelled, 0.01), "start":str(start), "end":str(helper.global_position), "task":str(data.task), "path_points":longest_path, "human_state":_row(game.player).state, "health":game.player.health, "revives":game.squad_world.counters.revives}
	print("SQUAD_STAGED_RESCUE " + JSON.stringify(result))
	_check(travelled > 6.0 and longest_path > 2 and helper.global_position.distance_to(start) > 6.0, "AI rescuer traverses its actual AStar route with the real CharacterBody controller")
	_check(not game.player.downed and not game.player.eliminated and game.player.health == 35.0 and game.player.respawn_shield > 4.9, "physically arrived AI completes the full rescue and restores the human")
	_check(frames > 360 and frames < 60 * 18 and game.squad_world.counters.revives == 1 and game.director.alive_count == 5, "AI travel plus continuous hold succeeds within the staged bleed budget exactly once")
