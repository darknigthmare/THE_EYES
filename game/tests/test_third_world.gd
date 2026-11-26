extends SceneTree
## Physical admission and lifecycle fixtures for The Lantern Covenant.
## Fixtures position/injure actors deliberately; the final unopposed bot route
## runs normal production physics without moving actors or granting progress.

const MAIN_SCENE = preload("res://scenes/main.tscn")
const Props = preload("res://scripts/third_apparatus.gd")
const SecondProps = preload("res://scripts/trial_apparatus.gd")
const Rules = preload("res://scripts/trial_set.gd")
const Survivor = preload("res://scripts/survivor.gd")
var game
var failures: int = 0
var assertions: int = 0
var cases: int = 0
var route_result: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Engine.physics_ticks_per_second = 60
	game = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	game.soundscape.set_enabled(false)
	game.qa_capture = "test-only-no-file"
	game.qa_done = true
	await _test_contract_props_and_reset()
	await _test_preparation_and_remote_commands()
	await _test_occluded_pickup()
	await _test_unique_cells_and_release()
	await _test_carried_cell_identity()
	await _test_cross_trial_cargo()
	await _test_charge_and_refuge_sight()
	await _test_light_hold_release_and_identity()
	await _test_light_motion_and_sight_reset()
	await _test_damage_and_pause_reset()
	await _test_depletion_and_recovery()
	await _test_all_three_refuges()
	await _test_strings_public_clues_and_cuts()
	await _test_strings_wrong_cut_and_latch()
	await _test_strings_interruption_and_actor_life()
	await _test_chimes_controls_and_noise()
	await _test_chimes_banks_and_completion()
	await _test_bots_observe_before_answering()
	await _test_bot_observation_epoch()
	await _test_bot_recharge_goal()
	await _test_rescue_priority()
	await _test_actor_membership_and_downed()
	await _test_full_third_bot_route()
	Input.action_release("interact")
	paused = false
	game.soundscape.stop_all()
	game.queue_free()
	await process_frame
	await process_frame
	print("THIRD_WORLD_ROUTE " + JSON.stringify(route_result))
	print("Third world integration: %d cases, %d assertions, %d failures" % [cases, assertions, failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)


func _near(actual: float, expected: float, label: String) -> void:
	_check(absf(actual - expected) < 0.002, label + " (%.4f vs %.4f)" % [actual, expected])


func _start(contract: String = "third", role: String = "survivor", seed_value: int = 271126, live: bool = true) -> void:
	paused = false
	Input.action_release("interact")
	game.start_match(role, "Keeper", "story", seed_value, contract)
	game.soundscape.set_enabled(false)
	game.set_physics_process(false)
	for actor: EyesSurvivor in game.actors:
		actor.active = false
	await physics_frame
	await physics_frame
	if live:
		game.director.step(8.0)


func _place(actor: EyesSurvivor, point: Vector3, offset: Vector3 = Vector3(0, 0.05, 0.85)) -> void:
	actor.global_position = point + offset
	actor.velocity = Vector3.ZERO


func _step(seconds: float) -> void:
	game.director.step(seconds)
	game.trial_world.step(seconds)


func _wall(point: Vector3) -> StaticBody3D:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.2, 2.8, 0.18)
	col.shape = box
	wall.add_child(col)
	game.add_child(wall)
	wall.global_position = point + Vector3(0, 1.4, 0.45)
	return wall


func _test_contract_props_and_reset() -> void:
	cases += 1
	await _start()
	var props = game.apparatus.third
	_check(props.cell_nodes.size() == 3 and props.lamp_cores.size() == 3, "Third builds three cell cradles and three physical lamps")
	_check(props.rope_tags.size() == 4 and props.catches.size() == 3, "Third builds four tagged rope controls and three safety indicators")
	_check(props.bell_pivots.size() == 4, "Third builds four real bell stations")
	_check(game.director.trial_set.slot_trials == {"silent": "light", "echoes": "strings", "relay": "chimes"}, "Third slots resolve exact authored trial IDs")
	var previous_world: WeakRef = weakref(game.trial_world)
	var previous_child: WeakRef = weakref(game.trial_world.third)
	await _start("first")
	_check(previous_world.get_ref() == null and previous_child.get_ref() == null, "rematch releases old world and child helpers without a RefCounted cycle")
	_check(game.apparatus.third.get_child_count() == 0, "First rematch removes all Third apparatus")
	_check(game.apparatus.relic_nodes.is_empty() and game.arena.motes[0].get_parent().visible, "First legacy presentation restored")
	await _start("second")
	_check(game.apparatus.third.get_child_count() == 0 and game.apparatus.relic_nodes.size() == 6, "Second restores only its own apparatus")
	await _start()
	_check(game.apparatus.third.cell_nodes.size() == 3 and game.apparatus.relic_nodes.is_empty(), "Third rematch creates one clean fresh apparatus")


func _test_preparation_and_remote_commands() -> void:
	cases += 1
	await _start("third", "survivor", 271126, false)
	_place(game.player, Props.CELL_POSITIONS[0])
	_check(not game.trial_world.perform(game.player, "light_pickup", 0), "preparation rejects cell ownership")
	_check(game.trial_world.nearest(game.player).is_empty(), "preparation offers no live Third actions")
	game.director.step(8.0)
	_place(game.player, Vector3.ZERO, Vector3(0, 0.05, 5))
	for kind: String in ["light_pickup", "light_align", "strings_read", "strings_cut", "chimes_read", "chimes_strike", "chimes_damp"]:
		_check(not game.trial_world.perform(game.player, kind, 0), "remote physical command rejects: " + kind)
	_check(game.trial_world.nearest(game.player).is_empty(), "distant actor cannot acquire a third-trial prompt")
	await _start("first")
	_place(game.player, Props.CELL_POSITIONS[0])
	_check(not game.trial_world.perform(game.player, "light_pickup", 0), "inactive Light trial cannot grant cell")
	_place(game.player, Props.ROPE_POSITIONS[0])
	_check(not game.trial_world.perform(game.player, "strings_cut", 0), "inactive Strings rejects control")
	_place(game.player, Props.BELL_POSITIONS[0])
	_check(not game.trial_world.perform(game.player, "chimes_strike", 0), "inactive Chimes rejects bell")


func _test_occluded_pickup() -> void:
	cases += 1
	await _start()
	_place(game.player, Props.CELL_POSITIONS[0])
	var wall: StaticBody3D = _wall(Props.CELL_POSITIONS[0])
	await physics_frame
	await physics_frame
	_check(not game.trial_world.perform(game.player, "light_pickup", 0), "nearby cell behind actual solid wall rejects")
	_check(game.trial_world.nearest(game.player).is_empty(), "occluded cell has no usable prompt")
	wall.queue_free()
	await physics_frame
	await physics_frame
	_check(game.trial_world.nearest(game.player).get("kind", "") == "light_pickup", "clear ray restores correct physical prompt")
	_check(game.trial_world.interact(game.player), "ordinary interact acquires clear nearby cell")
	_check(game.director.trial_set.third.carried_cell(game.player.get_instance_id()) == 0, "nearest interaction picks exactly the requested cell")


func _test_unique_cells_and_release() -> void:
	cases += 1
	await _start("third", "eye")
	var a: EyesSurvivor = game.actors[0]
	var b: EyesSurvivor = game.actors[1]
	var state = game.director.trial_set.third
	_place(a, Props.CELL_POSITIONS[1])
	_place(b, Props.CELL_POSITIONS[1], Vector3(0.2, 0.05, 0.9))
	_check(game.trial_world.perform(a, "light_pickup", 1), "first actor obtains unique cell")
	_check(not game.trial_world.perform(b, "light_pickup", 1), "second actor cannot duplicate cell")
	_check(game.trial_world.has_cargo(a), "common cargo query includes power cells")
	game.trial_world.release(a)
	game.apparatus.refresh(0.0)
	_check(state.cell_available(1) and state.carried_cell(a.get_instance_id()) == -1 and game.apparatus.third.cell_nodes[1].visible, "release restores available visible cell to its cradle")
	_check(game.trial_world.perform(b, "light_pickup", 1), "another nearby actor can recover the released cell")
	_check(not game.trial_world.perform(b, "light_pickup", -1) and not game.trial_world.perform(b, "light_pickup", 3), "invalid cell indices reject safely")


func _test_cross_trial_cargo() -> void:
	cases += 1
	var chosen: int = -1
	for seed_value: int in range(256):
		var selection = Rules.new()
		selection.configure(seed_value, "mix")
		if selection.trial_for_slot("silent") == "light" and selection.trial_for_slot("echoes") == "ritual":
			chosen = seed_value
			break
	_check(chosen >= 0, "Mix provides real Light plus Ritual fixture")
	if chosen < 0:
		return
	await _start("mix", "survivor", chosen)
	_place(game.player, Props.CELL_POSITIONS[0])
	_check(game.trial_world.perform(game.player, "light_pickup", 0), "mixed Light cell pickup works")
	_place(game.player, SecondProps.EMBER_POSITION)
	_check(not game.trial_world.perform(game.player, "ember_pickup"), "power-cell carrier cannot also take Ritual ember")
	game.trial_world.release(game.player)
	_check(game.trial_world.perform(game.player, "ember_pickup"), "released power cell frees hands for ember")
	_place(game.player, Props.CELL_POSITIONS[0])
	_check(not game.trial_world.perform(game.player, "light_pickup", 0), "ember carrier cannot take a power cell")
	game.trial_world.release(game.player)
	_check(not game.trial_world.has_cargo(game.player), "common release clears either cargo type")


func _test_carried_cell_identity() -> void:
	cases += 1
	await _start()
	var id: int = game.player.get_instance_id()
	_place(game.player, Props.CELL_POSITIONS[0])
	game.trial_world.perform(game.player, "light_pickup", 0)
	game.trial_world.step(0.01)
	var visual: Node3D = game.apparatus.third.carry_nodes[id]
	var label: Label3D = visual.get_node("CellLantern/CellIdentity")
	_check(visual.visible and label.text == "1", "first carried cell shows its real numbered identity")
	game.trial_world.release(game.player)
	_check(not visual.visible, "released cell cannot remain visible in the actor's hands")
	_place(game.player, Props.CELL_POSITIONS[1])
	game.trial_world.perform(game.player, "light_pickup", 1)
	game.trial_world.step(0.01)
	_check(visual == game.apparatus.third.carry_nodes[id] and visual.visible and label.text == "2", "same actor's reused lantern updates to its newly carried cell identity")
	game.trial_world.release(game.player)
	_check(not visual.visible and game.director.trial_set.third.cell_available(0) and game.director.trial_set.third.cell_available(1), "both released required cells return safely and hands stay visibly empty")


func _test_charge_and_refuge_sight() -> void:
	cases += 1
	await _start()
	var state = game.director.trial_set.third
	var id: int = game.player.get_instance_id()
	_place(game.player, Props.CELL_POSITIONS[0])
	game.trial_world.perform(game.player, "light_pickup", 0)
	_step(1.0)
	_near(state.charge_for(id), 96.0, "carrying outside refuge drains four charge per second")
	_place(game.player, Props.BASE_REFUGE, Vector3(0, 0.05, 2.1))
	_check(game.trial_world.third.in_refuge(game.player), "permanent refuge admits nearby actor with clear sight")
	_step(0.25)
	_near(state.charge_for(id), 99.0, "permanent refuge restores twelve charge per second")
	_place(game.player, Props.LAMP_POSITIONS[0])
	_check(not game.trial_world.third.in_refuge(game.player), "unlit lamp does not count as refuge")
	var wall: StaticBody3D = _wall(Props.BASE_REFUGE)
	_place(game.player, Props.BASE_REFUGE, Vector3(0, 0.05, 2.1))
	await physics_frame
	await physics_frame
	_check(not game.trial_world.third.in_refuge(game.player), "wall prevents recharge through physical architecture")
	var before: float = state.charge_for(id)
	_step(0.25)
	_near(state.charge_for(id), before - 1.0, "occluded refuge cannot silently replenish charge")
	wall.queue_free()
	await physics_frame


func _test_light_hold_release_and_identity() -> void:
	cases += 1
	await _start()
	var state = game.director.trial_set.third
	var id: int = game.player.get_instance_id()
	_place(game.player, Props.CELL_POSITIONS[0])
	game.trial_world.perform(game.player, "light_pickup", 0)
	_place(game.player, Props.LAMP_POSITIONS[1])
	Input.action_press("interact")
	_step(2.1)
	_check(not state.light_lit.has(true) and state.carried_cell(id) == 0, "wrong refuge identity preserves carried cell without progress")
	_place(game.player, Props.LAMP_POSITIONS[0])
	_check(game.trial_world.perform(game.player, "light_align", 0) and not state.light_lit[0], "instant command admits alignment but cannot grant held progress")
	_step(1.0)
	_check(state.light_holds.has(id) and not state.light_lit[0], "one still second creates partial alignment only")
	Input.action_release("interact")
	_step(0.05)
	_check(not state.light_holds.has(id), "releasing E resets alignment")
	Input.action_press("interact")
	_step(1.1)
	_check(not state.light_lit[0], "new attempt cannot reuse released progress")
	_step(0.9)
	_check(state.light_lit[0] and state.carried_cell(id) == -1, "two uninterrupted still seconds bank the exact refuge")
	_check(game.trial_world.third.in_refuge(game.player), "newly lit lamp becomes a real recharge refuge")
	Input.action_release("interact")


func _test_light_motion_and_sight_reset() -> void:
	cases += 1
	await _start()
	var state = game.director.trial_set.third
	var id: int = game.player.get_instance_id()
	_place(game.player, Props.CELL_POSITIONS[0])
	game.trial_world.perform(game.player, "light_pickup", 0)
	_place(game.player, Props.LAMP_POSITIONS[0])
	Input.action_press("interact")
	_step(1.0)
	game.player.velocity.x = 0.5
	_step(0.05)
	_check(not state.light_holds.has(id), "physical movement resets alignment")
	game.player.velocity = Vector3.ZERO
	_step(1.0)
	var wall: StaticBody3D = _wall(Props.LAMP_POSITIONS[0])
	await physics_frame
	await physics_frame
	_step(0.05)
	_check(not state.light_holds.has(id) and not state.light_lit[0], "lost sight interrupts held alignment before completion")
	wall.queue_free()
	await physics_frame
	await physics_frame
	_step(1.0)
	_place(game.player, Props.LAMP_POSITIONS[0], Vector3(0, 0.05, 2.1))
	_step(0.05)
	_check(not state.light_holds.has(id), "leaving physical reach resets alignment")
	Input.action_release("interact")


func _test_damage_and_pause_reset() -> void:
	cases += 1
	await _start()
	var state = game.director.trial_set.third
	var id: int = game.player.get_instance_id()
	_place(game.player, Props.CELL_POSITIONS[0])
	game.trial_world.perform(game.player, "light_pickup", 0)
	_place(game.player, Props.LAMP_POSITIONS[0])
	Input.action_press("interact")
	_step(1.0)
	game.player.invulnerability = 0.0
	game.player.respawn_shield = 0.0
	game._hurt(game.player, 1.0, "Third physical damage fixture")
	_check(not state.light_holds.has(id) and game.player.health == 99.0, "real accepted damage clears ongoing alignment")
	_step(1.0)
	game._pause()
	_check(paused and not state.light_holds.has(id), "real pause clears ongoing alignment")
	game.trial_world.step(2.0)
	_check(not state.light_lit[0], "paused world cannot finish a held action")
	game._resume()
	game.set_physics_process(false)
	_step(1.0)
	_check(not state.light_lit[0], "resume requires the full new alignment duration")
	Input.action_release("interact")


func _test_depletion_and_recovery() -> void:
	cases += 1
	await _start()
	var state = game.director.trial_set.third
	var id: int = game.player.get_instance_id()
	_place(game.player, Props.CELL_POSITIONS[0])
	game.trial_world.perform(game.player, "light_pickup", 0)
	_step(25.0)
	_near(state.charge_for(id), 0.0, "ordinary drain reaches bounded zero charge")
	_place(game.player, Props.LAMP_POSITIONS[0])
	Input.action_press("interact")
	_step(2.1)
	_check(not state.light_lit[0] and state.carried_cell(id) == 0, "empty lamp blocks alignment without deleting required cell")
	Input.action_release("interact")
	_place(game.player, Props.BASE_REFUGE, Vector3(0, 0.05, 2.1))
	_step(3.0)
	_near(state.charge_for(id), 36.0, "depleted lamp recovers at physically reachable permanent refuge")
	_place(game.player, Props.LAMP_POSITIONS[0])
	Input.action_press("interact")
	_step(2.0)
	_check(state.light_lit[0], "recovered lamp can complete its original required alignment")
	Input.action_release("interact")


func _test_all_three_refuges() -> void:
	cases += 1
	await _start()
	var state = game.director.trial_set.third
	for index: int in range(3):
		_place(game.player, Props.CELL_POSITIONS[index])
		_check(game.trial_world.perform(game.player, "light_pickup", index), "physical cell pickup for refuge %d" % index)
		_place(game.player, Props.LAMP_POSITIONS[index])
		Input.action_press("interact")
		_step(2.0)
		Input.action_release("interact")
		_step(0.05)
		_check(state.light_lit[index], "physical alignment banks refuge %d" % index)
	_check(game.director.seals.silent and state.light_cells.is_empty(), "third refuge awards one director seal and consumes all cells")
	_check(not game.trial_world.perform(game.player, "light_align", 2), "completed Light cannot award more progress")
	game.apparatus.refresh(0.0)
	_check(game.apparatus.third.lamp_labels[2].text.contains("LIT") and not game.apparatus.third.cell_nodes[2].visible, "visible lamp and cradle agree with authoritative completion")


func _test_strings_public_clues_and_cuts() -> void:
	cases += 1
	await _start()
	var state = game.director.trial_set.third
	for round_value: int in range(3):
		_place(game.player, Props.STRINGS_DESK, Vector3(0, 0.05, 2.2))
		_check(game.trial_world.perform(game.player, "strings_read"), "physical panel admits clue inspection")
		game.apparatus.refresh(0.0)
		_check(game.apparatus.third.strings_board.text.contains(state.strings_clue()), "geometry displays the actual clue used by authority")
		var answer: int = state.strings_answer()
		_check(answer / 2 == state.strings_half and (state.strings_layout[answer] < 2) == state.strings_curved, "public half and curvature clues explain the correct rope")
		_place(game.player, Props.ROPE_POSITIONS[answer])
		Input.action_press("interact")
		_step(2.0)
		_check(state.strings_stage == round_value + 1, "two-second physical cut banks exactly one stage")
		Input.action_release("interact")
		_step(0.05)
	_check(game.director.seals.echoes and not game.director.seals.silent and not game.director.seals.relay, "third cut awards its matching director seal only")


func _test_strings_wrong_cut_and_latch() -> void:
	cases += 1
	await _start()
	var state = game.director.trial_set.third
	var wrong: int = (state.strings_answer() + 1) % 4
	_place(game.player, Props.ROPE_POSITIONS[wrong])
	Input.action_press("interact")
	_step(2.0)
	_check(state.strings_stage == 0 and state.strings_cooldown == 3.0, "wrong physical cut activates bounded three-second safety catch")
	_check(game.player.health == 100.0, "safety catch does not inflict unavoidable damage")
	_step(3.0)
	_check(state.strings_cooldown == 0.0 and state.strings_holds.is_empty(), "unchanged held input cannot automatically repeat a resolved cut")
	Input.action_release("interact")
	_step(0.05)
	_place(game.player, Props.ROPE_POSITIONS[state.strings_answer()])
	Input.action_press("interact")
	_step(2.0)
	_check(state.strings_stage == 1, "released and corrected physical cut recovers after safety catch")
	Input.action_release("interact")
	_step(0.05)
	wrong = (state.strings_answer() + 1) % 4
	_place(game.player, Props.ROPE_POSITIONS[wrong])
	Input.action_press("interact")
	_step(2.0)
	_check(state.strings_stage == 1, "later error preserves previously banked cage stage")
	Input.action_release("interact")


func _test_strings_interruption_and_actor_life() -> void:
	cases += 1
	await _start()
	var state = game.director.trial_set.third
	var id: int = game.player.get_instance_id()
	var answer: int = state.strings_answer()
	_place(game.player, Props.ROPE_POSITIONS[answer])
	Input.action_press("interact")
	_step(1.0)
	game.player.velocity.z = 0.4
	_step(0.1)
	_check(state.strings_holds.is_empty(), "moving actor cannot retain partial rope cut")
	game.player.velocity = Vector3.ZERO
	_step(1.0)
	game._pause()
	_check(state.strings_holds.is_empty(), "pause clears rope hold as well as lamp hold")
	game._resume()
	game.set_physics_process(false)
	_step(1.0)
	game.player.downed = true
	game.trial_world.step(0.1)
	_check(not state.strings_holds.has(id) and state.strings_stage == 0, "downed participant cannot continue a physical cut")
	game.player.downed = false
	Input.action_release("interact")


func _test_chimes_controls_and_noise() -> void:
	cases += 1
	await _start()
	var state = game.director.trial_set.third
	var bell: int = state.chimes_sequences[0][0]
	_place(game.player, Props.BELL_POSITIONS[bell])
	_check(game.trial_world.nearest(game.player).get("kind", "") == "chimes_strike", "nearest physical bell exposes its real strike command")
	_check(game.trial_world.interact(game.player, -1) and state.damper == bell, "ordinary reverse/R action toggles the nearby bell damper")
	_check(game.trial_world.interact(game.player) and state.chimes_index == 1, "ordinary E strikes the correctly damped first bell")
	_near(game.noise_memory, 1.0, "quiet strike emits one second of real Eye noise memory")
	_near(game.last_noise.distance_to(Props.BELL_POSITIONS[bell]), 0.0, "noise originates at struck physical bell")
	_check(game.apparatus.third.bell_swing[bell] > 0.0, "accepted strike starts the real bell animation")
	_check(not game.trial_world.perform(game.player, "chimes_strike", bell), "shared cooldown rejects immediate duplicate strike")
	_step(0.5)
	bell = state.chimes_sequences[0][1]
	_place(game.player, Props.BELL_POSITIONS[bell])
	_check(game.trial_world.perform(game.player, "chimes_strike", bell), "next undamped physical bell advances phrase")
	_near(game.noise_memory, 6.0, "undamped correct strike produces louder Eye cue")
	_step(0.5)
	bell = (state.chimes_sequences[0][2] + 1) % 4
	_place(game.player, Props.BELL_POSITIONS[bell])
	_check(not game.trial_world.perform(game.player, "chimes_strike", bell) and state.chimes_index == 0, "wrong bell resets only the current phrase")
	_near(game.noise_memory, 10.0, "wrong strike produces bounded loud noise cue")


func _test_chimes_banks_and_completion() -> void:
	cases += 1
	await _start()
	var state = game.director.trial_set.third
	for index: int in range(4):
		var bell: int = state.chimes_sequences[0][index]
		_place(game.player, Props.BELL_POSITIONS[bell])
		_check(game.trial_world.perform(game.player, "chimes_strike", bell), "first-phrase physical bell accepted")
		_step(0.5)
	_check(state.chimes_phrase == 1 and not game.director.seals.relay, "first complete phrase banks without prematurely awarding seal")
	var wrong: int = (state.chimes_sequences[1][0] + 1) % 4
	_place(game.player, Props.BELL_POSITIONS[wrong])
	game.trial_world.perform(game.player, "chimes_strike", wrong)
	_check(state.chimes_phrase == 1 and state.chimes_index == 0, "second-phrase error preserves first phrase checkpoint")
	_step(0.5)
	for index: int in range(4):
		var bell: int = state.chimes_sequences[1][index]
		_place(game.player, Props.BELL_POSITIONS[bell])
		_check(game.trial_world.perform(game.player, "chimes_strike", bell), "second-phrase physical bell accepted")
		_step(0.5)
	_check(state.chimes_phrase == 2 and game.director.seals.relay, "eight correct physical notes award matching seal once")
	_check(not game.trial_world.perform(game.player, "chimes_strike", 0), "completed Chimes rejects extra strikes")


func _test_bots_observe_before_answering() -> void:
	cases += 1
	await _start("third", "eye")
	var data: Dictionary = game.bots[1]
	var actor: EyesSurvivor = data.actor
	_check(game.trial_world.assign_slot(data, "echoes") and data.task == "strings_observe", "uninformed bot first seeks the physical clue panel")
	_place(actor, Vector3.ZERO, Vector3(0, 0.05, 5))
	data.action_time = 3.0
	game.trial_world.bot_arrived(data, 0.1)
	_check(not data.has("strings_seen_stage") and data.action_time == 0.0, "remote bot cannot acquire clue knowledge")
	_place(actor, Props.STRINGS_DESK, Vector3(0, 0.05, 2.2))
	data.action_time = 1.9
	game.trial_world.bot_arrived(data, 0.1)
	_check(not data.has("strings_seen_stage"), "clue observation retains its two-second cost")
	data.action_time = 2.0
	game.trial_world.bot_arrived(data, 0.1)
	_check(data.get("strings_seen_stage", -1) == 0, "two nearby seconds authorizes current-stage knowledge")
	game.trial_world.assign_slot(data, "echoes")
	_check(data.task == "strings_cut" and data.trial_index == game.director.trial_set.third.strings_answer(), "informed bot then selects the evidence-backed rope")
	data = game.bots[2]
	actor = data.actor
	game.trial_world.assign_slot(data, "relay")
	_check(data.task == "chimes_observe", "uninformed bell bot seeks score before selecting notes")
	_place(actor, Props.CHIMES_DESK, Vector3(0, 0.05, 2.2))
	data.action_time = 0.0
	game.trial_world.bot_arrived(data, 0.1)
	data.action_time = 2.0
	game.trial_world.bot_arrived(data, 0.1)
	game.trial_world.assign_slot(data, "relay")
	_check(data.task == "chimes_damp" and data.chimes_seen_phrase == 0, "informed bell bot plans physical damping before its first strike")


func _test_bot_observation_epoch() -> void:
	cases += 1
	await _start("third", "squad")
	var state = game.director.trial_set.third
	var data: Dictionary = game.bots[1]
	var actor: EyesSurvivor = data.actor
	game.trial_world.assign_slot(data, "echoes")
	_place(actor, Props.STRINGS_DESK, Vector3(0, 0.05, 2.2))
	data.action_time = 0.0
	game.trial_world.bot_arrived(data, 0.1)
	data.action_time = 1.9
	game.trial_world.bot_arrived(data, 0.1)
	_place(game.player, Props.ROPE_POSITIONS[state.strings_answer()])
	Input.action_press("interact")
	_step(2.0)
	Input.action_release("interact")
	_check(state.strings_stage == 1, "human physical cut replaces clue while bot is still observing")
	data.action_time = 2.0
	game.trial_world.bot_arrived(data, 0.1)
	_check(data.action_time == 0.0 and int(data.get("strings_seen_stage", -1)) != 1, "new clue discards time accumulated on previous stage")
	data.action_time = 1.9
	game.trial_world.bot_arrived(data, 0.1)
	_check(int(data.get("strings_seen_stage", -1)) != 1, "new clue still requires two complete observation seconds")
	data.action_time = 2.0
	game.trial_world.bot_arrived(data, 0.1)
	_check(data.strings_seen_stage == 1, "new stage becomes known only after its own observation")
	data.task = "strings_cut"
	data.trial_index = state.strings_answer()
	data.strings_seen_stage = 0
	_place(actor, Props.ROPE_POSITIONS[data.trial_index])
	game.trial_world.step(2.0)
	_check(state.strings_stage == 1 and not state.strings_holds.has(actor.get_instance_id()), "stale bot clue cannot authorize a hold on a new stage")
	data = game.bots[2]
	actor = data.actor
	game.trial_world.assign_slot(data, "relay")
	_place(actor, Props.CHIMES_DESK, Vector3(0, 0.05, 2.2))
	data.action_time = 0.0
	game.trial_world.bot_arrived(data, 0.1)
	data.action_time = 1.9
	game.trial_world.bot_arrived(data, 0.1)
	for index: int in range(4):
		var bell: int = state.chimes_sequences[0][index]
		_place(game.player, Props.BELL_POSITIONS[bell])
		game.trial_world.perform(game.player, "chimes_strike", bell)
		_step(0.5)
	_check(state.chimes_phrase == 1, "human physical phrase advances while bot observes old score")
	data.action_time = 2.0
	game.trial_world.bot_arrived(data, 0.1)
	_check(data.action_time == 0.0 and int(data.get("chimes_seen_phrase", -1)) != 1, "new phrase resets the bot's score observation time")
	data.action_time = 2.0
	game.trial_world.bot_arrived(data, 0.1)
	_check(data.chimes_seen_phrase == 1, "new phrase can be learned after two fresh seconds")
	var travelling_bell: int = state.chimes_sequences[1][0]
	data.task = "chimes_strike"
	data.trial_index = travelling_bell
	data.action_time = 0.5
	_place(actor, Props.BELL_POSITIONS[travelling_bell])
	_place(game.player, Props.BELL_POSITIONS[travelling_bell])
	_check(game.trial_world.perform(game.player, "chimes_strike", travelling_bell), "human completes note that a travelling informed bot had planned")
	_step(0.5)
	var previous_events: int = game.event_log.size()
	game.trial_world.bot_arrived(data, 0.1)
	_check(state.chimes_index == 1 and game.event_log.size() == previous_events, "arrival discards stale strike instead of resetting teammate's phrase")
	_check(data.think == 0.0 and data.action_time == 0.0, "stale bell action requests an immediate fresh goal")
	data.task = "chimes_damp"
	data.action_time = 0.5
	var previous_damper: int = state.damper
	game.trial_world.bot_arrived(data, 0.1)
	_check(state.damper == previous_damper, "stale arrival cannot move the shared damper to an obsolete goal")


func _test_bot_recharge_goal() -> void:
	cases += 1
	await _start("third", "eye")
	var data: Dictionary = game.bots[0]
	var actor: EyesSurvivor = data.actor
	var state = game.director.trial_set.third
	_place(actor, Props.CELL_POSITIONS[0])
	game.trial_world.perform(actor, "light_pickup", 0)
	game.trial_world.step(22.0)
	_check(state.charge_for(actor.get_instance_id()) < 25.0, "bot fixture genuinely depletes through ordinary charge update")
	_check(game.trial_world.cargo_goal(data) and data.task == "light_recharge", "low-charge carrier chooses physical refuge rather than impossible alignment")
	_place(actor, Props.BASE_REFUGE, Vector3(0, 0.05, 2.1))
	game.trial_world.step(7.0)
	_check(state.charge_for(actor.get_instance_id()) >= 90.0, "waiting at clear permanent refuge recharges the bot")
	game.trial_world.cargo_goal(data)
	_check(data.task == "light_align" and data.trial_index == 0, "recharged bot resumes its original matching-cell objective")


func _test_actor_membership_and_downed() -> void:
	cases += 1
	await _start("third", "squad")
	var actor: EyesSurvivor = game.player
	var state = game.director.trial_set.third
	_place(actor, Props.CELL_POSITIONS[0])
	game.trial_world.perform(actor, "light_pickup", 0)
	actor.invulnerability = 0.0
	actor.respawn_shield = 0.0
	game._hurt(actor, 100.0, "Third downed cargo fixture")
	_check(actor.downed and state.carried_cell(actor.get_instance_id()) < 0 and state.cell_available(0), "actual squad lethal fall safely returns required cell")
	_check(not game.trial_world.perform(actor, "light_pickup", 0) and game.trial_world.nearest(actor).is_empty(), "downed member cannot use nearby trial objects")
	var stranger: EyesSurvivor = Survivor.new()
	game.add_child(stranger)
	stranger.active = false
	_place(stranger, Props.CELL_POSITIONS[0])
	_check(not game.trial_world.perform(stranger, "light_pickup", 0), "actor outside match roster cannot acquire ownership")
	_place(stranger, Props.BELL_POSITIONS[0])
	_check(not game.trial_world.perform(stranger, "chimes_strike", 0), "actor outside match roster cannot ring authoritative bell")
	stranger.queue_free()
	await process_frame


func _test_rescue_priority() -> void:
	cases += 1
	for kind: String in ["light_align", "strings_cut"]:
		await _start("third", "squad")
		var state = game.director.trial_set.third
		var id: int = game.player.get_instance_id()
		if kind == "light_align":
			_place(game.player, Props.CELL_POSITIONS[0])
			game.trial_world.perform(game.player, "light_pickup", 0)
			_place(game.player, Props.LAMP_POSITIONS[0])
		else:
			_place(game.player, Props.ROPE_POSITIONS[state.strings_answer()])
		Input.action_press("interact")
		_step(1.0)
		_check(state.light_holds.has(id) if kind == "light_align" else state.strings_holds.has(id), "rescue fixture begins a real partial " + kind)
		var subject: EyesSurvivor = game.actors[1]
		_place(subject, game.player.global_position, Vector3(0.8, 0, 0))
		subject.invulnerability = 0.0
		subject.respawn_shield = 0.0
		game._hurt(subject, 100.0, "Rescue priority apparatus fixture")
		_check(subject.downed and game.squad_world.nearby_downed(game.player) == subject, "real downed teammate is reachable beside apparatus")
		game.squad_world.step(1.0)
		game.trial_world.step(1.0)
		_check(game.squad_world.player_rescuing, "held E is admitted to physical teammate rescue")
		_check(state.light_holds.is_empty() and state.strings_holds.is_empty(), "rescue clears all previous held trial progress")
		_check(not state.light_lit.has(true) and state.strings_stage == 0, "rescue cannot simultaneously finish lamp or cut rope")
		var row: Dictionary = game.squad_world.state.member(subject.get_instance_id())
		_check(float(row.get("revive_progress", row.get("revive_seconds", 0.0))) > 0.0, "only the rescue accumulated positive held progress")
		Input.action_release("interact")


func _test_full_third_bot_route() -> void:
	cases += 1
	Input.action_release("interact")
	game.start_match("eye", "Keeper", "story", 271126, "third")
	game.soundscape.set_enabled(false)
	game.set_physics_process(true)
	var origins: Array[Vector3] = []
	var distances: Array[float] = [0.0, 0.0, 0.0, 0.0]
	for actor: EyesSurvivor in game.actors:
		origins.append(actor.global_position)
	var frames: int = 0
	while game.director.phase != "ended" and frames < 450 * 60:
		await physics_frame
		for index: int in range(game.actors.size()):
			distances[index] += game.actors[index].global_position.distance_to(origins[index])
			origins[index] = game.actors[index].global_position
		frames += 1
	game.set_physics_process(false)
	var won: bool = game.director.phase == "ended" and game.director.winner == "survivors"
	var state = game.director.trial_set.third
	_check(won, "unopposed Third bots physically complete all trials and escape")
	_check(not state.light_lit.has(false) and state.strings_stage == 3 and state.chimes_phrase == 2, "normal bot route banks every new objective")
	var moved: int = 0
	for distance: float in distances:
		if distance > 20.0:
			moved += 1
	_check(moved >= 3, "multiple agents physically travel meaningful routes")
	route_result = {"contract": "third", "seed": 271126, "winner": game.director.winner, "simulated_seconds": snappedf(game.elapsed, 0.01), "distances": distances, "all_seals": game.director.seals.duplicate(), "opposition": "human Eye idle; unopposed integration route"}
	if not won:
		for data: Dictionary in game.bots:
			print("THIRD_BOT_STALL " + str({"task": data.task, "position": data.actor.global_position, "target": data.target, "action_time": data.action_time, "health": data.actor.health, "cell": state.carried_cell(data.actor.get_instance_id()), "charge": state.charge_for(data.actor.get_instance_id()), "stage": state.strings_stage, "phrase": state.chimes_phrase, "note": state.chimes_index}))
