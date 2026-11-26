extends SceneTree
## World authority and physical bot routes for the Observance Collection.
## Run with --headless --fixed-fps 60 --audio-driver Dummy.
## Isolated command fixtures position actors explicitly. Full routes below use
## ordinary physics and bot logic without actor, time or progress overrides.

const MAIN_SCENE = preload("res://scenes/main.tscn")
const Props = preload("res://scripts/trial_apparatus.gd")
const Rules = preload("res://scripts/trial_set.gd")
const Survivor = preload("res://scripts/survivor.gd")
const ROUTE_LIMIT_SECONDS: int = 450
var game
var failures: int = 0
var assertions: int = 0
var cases: int = 0
var route_results: Array[Dictionary] = []


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
	await _test_distance_and_inactive_guards()
	await _test_nearest_interaction_and_occlusion()
	await _test_relic_release_and_recovery()
	await _test_actor_membership_and_elimination()
	await _test_legacy_cargo_exclusion()
	await _test_physical_ritual_occupancy()
	await _test_physical_clock_controls()
	await _test_bot_route("second", 271126)
	var mixed: Dictionary = _mixed_seeds()
	_check(mixed.size() == 27, "fixture discovers every ternary Seeded Mix combination")
	for mapping: String in mixed:
		await _test_bot_route("mix", int(mixed[mapping]))
	Input.action_release("interact")
	game.soundscape.stop_all()
	await process_frame
	await process_frame
	game.queue_free()
	await process_frame
	await process_frame
	print("SECOND_WORLD_ROUTES " + JSON.stringify(route_results))
	print("Second world integration: %d cases, %d assertions, %d failures" % [cases, assertions, failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)


func _near(actual: float, expected: float, description: String) -> void:
	_check(absf(actual - expected) < 0.001, description + " (%.4f vs %.4f)" % [actual, expected])


func _start_isolated(contract: String = "second", role: String = "survivor", seed_value: int = 271126, begin_live: bool = true) -> void:
	Input.action_release("interact")
	game.start_match(role, "Veil", "story", seed_value, contract)
	game.soundscape.set_enabled(false)
	game.set_physics_process(false)
	for actor in game.actors:
		actor.active = false
	await physics_frame
	await physics_frame
	if begin_live:
		game.director.step(8.0)


func _place(actor: EyesSurvivor, point: Vector3, offset: Vector3 = Vector3(0, 0.05, 0.8)) -> void:
	actor.global_position = point + offset
	actor.velocity = Vector3.ZERO


func _mapping(rules: Rules) -> String:
	return "%s/%s/%s" % [rules.trial_for_slot("silent"), rules.trial_for_slot("echoes"), rules.trial_for_slot("relay")]


func _mixed_seeds() -> Dictionary:
	var mappings: Dictionary = {}
	for seed_value: int in range(1024):
		var rules: Rules = Rules.new()
		rules.configure(seed_value, "mix")
		var key: String = _mapping(rules)
		if not mappings.has(key):
			mappings[key] = seed_value
		if mappings.size() == 27:
			break
	return mappings


func _test_distance_and_inactive_guards() -> void:
	cases += 1
	await _start_isolated("second", "survivor", 271126, false)
	var actor: EyesSurvivor = game.player
	_place(actor, Props.RELIC_POSITIONS[0])
	_check(not game.trial_world.perform(actor, "vault_pickup", 0), "preparation rejects nearby relic pickup")
	_check(game.trial_world.nearest(actor).is_empty(), "preparation offers no live apparatus command")
	game.director.step(8.0)
	_place(actor, Vector3(-24, 0, 0), Vector3(0, 0.05, 0))
	var before: Array[int] = game.director.trial_set.clock_hands.duplicate()
	for kind: String in ["vault_read", "vault_pickup", "vault_deposit", "ember_pickup", "ritual_light", "clock_turn", "clock_reset", "clock_confirm"]:
		_check(not game.trial_world.perform(actor, kind, 0), "remote dispatcher rejects " + kind)
	_check(game.trial_world.nearest(actor).is_empty() and not game.trial_world.interact(actor), "remote nearest/interact cannot target distant apparatus")
	_check(game.director.trial_set.clock_hands == before and game.director.trial_set.vault_carriers.is_empty() and game.director.trial_set.ember_owner == 0, "distance rejection preserves puzzle and ownership")
	_check(not game.trial_world.perform(actor, "invented_command"), "unknown world command rejects")
	await _start_isolated("first")
	actor = game.player
	_place(actor, Props.RELIC_POSITIONS[0])
	_check(not game.trial_world.perform(actor, "vault_pickup", 0), "First contract rejects inactive Vault pickup")
	_place(actor, Props.VAULT_DESK)
	_check(not game.trial_world.perform(actor, "vault_read"), "First contract rejects inactive Vault display")
	_place(actor, Props.EMBER_POSITION)
	_check(not game.trial_world.perform(actor, "ember_pickup"), "First contract rejects inactive Ritual pickup")
	_place(actor, Props.CLOCK_LEVERS[0])
	_check(not game.trial_world.perform(actor, "clock_turn", 0), "First contract rejects inactive Clock controls")


func _test_nearest_interaction_and_occlusion() -> void:
	cases += 1
	await _start_isolated()
	var actor: EyesSurvivor = game.player
	_place(actor, Props.VAULT_DESK, Vector3(0, 0.05, 0.65))
	var option: Dictionary = game.trial_world.nearest(actor)
	_check(option.get("kind", "") == "vault_read", "nearby desk resolves its real read command")
	_check(game.trial_world.interact(actor) and game.apparatus.reveal_left > 7.9, "ordinary interaction reveals the eight-second memory reference")
	game.apparatus.refresh(8.0)
	_near(game.apparatus.reveal_left, 0.0, "memory reference hides after its display budget")
	var target: int = game.director.trial_set.vault_targets[0]
	var point: Vector3 = Props.RELIC_POSITIONS[target]
	_place(actor, point, Vector3(0, 0.05, 1.2))
	_check(game.has_sight(actor.target_point(), point + Vector3.UP * 1.65), "close-range fixture initially has a clear real ray")
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.1, 2.5, 0.18)
	collision.shape = shape
	wall.add_child(collision)
	game.add_child(wall)
	wall.global_position = point + Vector3(0, 1.25, 0.6)
	await physics_frame
	await physics_frame
	_check(actor.global_position.distance_to(point) < 1.9 and not game.has_sight(actor.target_point(), point + Vector3.UP * 1.65), "real architecture fixture blocks sight while actor remains in reach")
	_check(not game.trial_world.perform(actor, "vault_pickup", target), "close but occluded pickup is rejected")
	_check(game.director.trial_set.carried_relic(actor.get_instance_id()) == -1, "occluded rejection cannot grant cargo")
	wall.queue_free()
	await physics_frame
	await physics_frame
	option = game.trial_world.nearest(actor)
	_check(option.get("kind", "") == "vault_pickup" and int(option.get("index", -1)) == target, "nearest identifies the unobstructed physical relic")
	_check(game.trial_world.interact(actor) and game.director.trial_set.carried_relic(actor.get_instance_id()) == target, "ordinary interaction collects the intended relic")


func _test_relic_release_and_recovery() -> void:
	cases += 1
	await _start_isolated("second", "eye")
	var owner: EyesSurvivor = game.actors[0]
	var other: EyesSurvivor = game.actors[1]
	var state: Rules = game.director.trial_set
	var target: int = state.vault_targets[0]
	_place(owner, Props.RELIC_POSITIONS[target])
	_place(other, Props.RELIC_POSITIONS[target], Vector3(0.4, 0.05, 0.8))
	_check(game.trial_world.perform(owner, "vault_pickup", target), "required relic can be collected through world authority")
	_check(not game.trial_world.perform(other, "vault_pickup", target), "second nearby actor cannot duplicate cargo")
	game.trial_world.release(owner)
	game.apparatus.refresh(0.0)
	_check(state.carried_relic(owner.get_instance_id()) == -1 and state.relic_available(target) and game.apparatus.relic_nodes[target].visible, "release restores required relic to its visible shelf")
	_check(game.trial_world.perform(other, "vault_pickup", target), "another actor can physically recover the released required relic")
	_place(other, Props.CRADLE_POSITIONS[1])
	_check(not game.trial_world.perform(other, "vault_deposit", 1) and state.carried_relic(other.get_instance_id()) == target, "wrong nearby cradle preserves cargo")
	game.director.step(0.35)
	_place(other, Props.CRADLE_POSITIONS[0])
	_check(game.trial_world.perform(other, "vault_deposit", 0), "recovered relic banks in its matching cradle")
	_check(state.vault_cradles[0] == target and not state.relic_available(target) and not game.director.seals.silent, "one physical deposit cannot complete all four cradles")


func _test_actor_membership_and_elimination() -> void:
	cases += 1
	await _start_isolated("second", "eye")
	var actor: EyesSurvivor = game.actors[0]
	var target: int = game.director.trial_set.vault_targets[0]
	_place(actor, Props.RELIC_POSITIONS[target])
	game.trial_world.perform(actor, "vault_pickup", target)
	actor.respawn_shield = 0.0
	actor.invulnerability = 0.0
	game._hurt(actor, 100.0, "World command elimination fixture")
	_check(actor.eliminated and game.director.alive_count == 3, "real lethal damage retires a participating actor")
	_check(game.director.trial_set.relic_available(target), "elimination releases required relic cargo")
	_check(not game.trial_world.perform(actor, "vault_pickup", target) and game.trial_world.nearest(actor).is_empty(), "eliminated actor cannot issue nearby world commands")
	var stranger: EyesSurvivor = Survivor.new()
	game.add_child(stranger)
	stranger.active = false
	_place(stranger, Props.EMBER_POSITION)
	_check(not game.trial_world.perform(stranger, "ember_pickup") and game.trial_world.nearest(stranger).is_empty(), "a body outside the match actor roster cannot take shared cargo")
	stranger.queue_free()
	await process_frame


func _test_legacy_cargo_exclusion() -> void:
	cases += 1
	var chosen: int = -1
	var mixed: Dictionary = _mixed_seeds()
	for mapping: String in mixed:
		if mapping.begins_with("silent/ritual/"):
			chosen = int(mixed[mapping])
			break
	_check(chosen >= 0, "Mix contains a real Silent plus Ritual contract")
	if chosen < 0:
		return
	await _start_isolated("mix", "survivor", chosen)
	var actor: EyesSurvivor = game.player
	_place(actor, game._mote_position(0))
	_check(game._pickup(actor, 0), "legacy mote is collected through its ordinary world pickup")
	_place(actor, Props.EMBER_POSITION)
	_check(not game.trial_world.perform(actor, "ember_pickup") and game.director.trial_set.ember_owner == 0, "legacy mote carrier cannot also take the shared ember")
	game.trial_world.release(actor)
	_check(actor.carrying == -1 and game.motes_state[0] == 0, "common release returns legacy cargo safely")
	_check(game.trial_world.perform(actor, "ember_pickup"), "free hands can now take shared ember")
	_place(actor, game._mote_position(1))
	_check(not game._pickup(actor, 1) and actor.carrying == -1, "ember ownership also blocks ordinary legacy mote pickup")
	game.trial_world.release(actor)
	_check(game.director.trial_set.ember_owner == 0 and not game.trial_world.has_cargo(actor), "release clears shared ember ownership")


func _test_physical_ritual_occupancy() -> void:
	cases += 1
	await _start_isolated()
	var actor: EyesSurvivor = game.player
	var state: Rules = game.director.trial_set
	_place(actor, Props.RITUAL_CENTER)
	game.trial_world.step(8.0)
	_near(state.ritual_hold, 0.0, "standing inside the ring cannot bypass the five vessels")
	_place(actor, Props.EMBER_POSITION)
	_check(game.trial_world.perform(actor, "ember_pickup"), "ritual begins with physical shared ember pickup")
	for vessel: int in state.ritual_sequence:
		_place(actor, Props.VESSEL_POSITIONS[vessel])
		_check(game.trial_world.perform(actor, "ritual_light", vessel), "ordered physical vessel accepts ember")
		game.director.step(0.35)
	_check(state.ritual_index == 5 and state.ember_owner == 0 and not game.director.seals.echoes, "five vessels ready the ring without awarding the seal")
	_place(actor, Props.RITUAL_CENTER, Vector3(0, 0.05, 1.9))
	game.trial_world.step(3.0)
	_near(state.ritual_hold, 3.0, "eligible physical ring occupant charges final hold")
	_place(actor, Props.RITUAL_CENTER, Vector3(0, 0.05, 2.81))
	game.trial_world.step(0.1)
	_near(state.ritual_hold, 0.0, "leaving the actual floor-ring radius resets partial hold")
	_check(state.ritual_index == 5 and state.ritual_bank == 4, "ring exit preserves lit vessels and pair checkpoints")
	_place(actor, Props.RITUAL_CENTER, Vector3(0, 1.0, 0))
	game.trial_world.step(1.0)
	_near(state.ritual_hold, 0.0, "airborne actor above the ring is not eligible occupancy")
	_place(actor, Props.RITUAL_CENTER, Vector3(0, 0.05, 0))
	game.punishment = true
	game.trial_world.step(1.0)
	_near(state.ritual_hold, 0.0, "punishment state cannot count as live ring occupancy")
	game.punishment = false
	for tick: int in range(480):
		game.trial_world.step(1.0 / 60.0)
	_check(game.director.seals.echoes and state.ritual_hold == 8.0, "eight seconds of eligible physical occupancy bank the Ritual seal")
	_place(actor, Props.EMBER_POSITION)
	_check(not game.trial_world.perform(actor, "ember_pickup"), "completed Ritual cannot produce another ember")
	game.trial_world.step(1.0)
	_near(state.ritual_hold, 8.0, "completed Ritual remains banked after leaving")


func _test_physical_clock_controls() -> void:
	cases += 1
	await _start_isolated()
	var actor: EyesSurvivor = game.player
	var state: Rules = game.director.trial_set
	var initial: Array[int] = state.clock_hands.duplicate()
	_place(actor, Props.CLOCK_LEVERS[0])
	var nearest: Dictionary = game.trial_world.nearest(actor)
	_check(nearest.get("kind", "") == "clock_turn" and int(nearest.get("index", -1)) == 0, "nearest selects the physical A lever")
	_check(game.trial_world.interact(actor) and state.clock_hands != initial, "ordinary interaction performs a forward gear move")
	game.director.step(0.25)
	_check(game.trial_world.interact(actor, -1) and state.clock_hands == initial, "reverse interaction undoes that coupled move")
	game.director.step(0.25)
	game.trial_world.perform(actor, "clock_turn", 0)
	game.director.step(0.25)
	_place(actor, Props.CLOCK_CENTER, Vector3(0, 0.05, 0.8))
	_check(game.trial_world.interact(actor, 1, true) and state.clock_hands == initial, "central reset uses the real interaction dispatcher")
	game.director.step(0.25)
	for move: Vector2i in state.clock_solution():
		_place(actor, Props.CLOCK_LEVERS[move.x])
		_check(game.trial_world.perform(actor, "clock_turn", move.x, move.y), "legal solution move requires arrival at its actual lever")
		game.director.step(0.25)
	_check(state.clock_hands == state.clock_target and not game.director.seals.relay, "world alignment still requires a separate centre press")
	_place(actor, Vector3(-24, 0, 0), Vector3(0, 0.05, 0))
	_check(not game.trial_world.perform(actor, "clock_confirm") and not game.director.seals.relay, "distant aligned-clock confirmation cannot bank a seal")
	_place(actor, Props.CLOCK_CENTER)
	_check(game.trial_world.interact(actor) and game.director.seals.relay, "nearby centre interaction confirms the aligned clock")
	_check(game.director.phase == "hunt", "Clock completion alone keeps the shared exit gated")


func _test_bot_route(contract: String, seed_value: int) -> void:
	cases += 1
	Input.action_release("interact")
	game.start_match("eye", "Veil", "story", seed_value, contract)
	game.soundscape.set_enabled(false)
	game.set_physics_process(true)
	# A human Eye may look out of the chamber. No survivor, trial, cooldown,
	# timer, path, speed or damage authority is modified during these routes.
	game.eye_forward = Vector3(0, 0.25, -1).normalized()
	game.eye_camera.rotation = Vector3(atan(0.25), 0, 0)
	var mapping: String = _mapping(game.director.trial_set)
	var early_escape: bool = false
	var frames: int = 0
	while game.director.phase != "ended" and frames < 60 * ROUTE_LIMIT_SECONDS:
		await physics_frame
		frames += 1
		if game.director.phase == "escape" and game.director.seals.values().count(true) != 3:
			early_escape = true
	var elapsed: float = game.elapsed
	var won: bool = game.director.phase == "ended" and game.director.winner == "survivors"
	var result: Dictionary = {"contract": contract, "seed": seed_value, "mapping": mapping, "elapsed": snappedf(elapsed, 0.01), "winner": game.director.winner, "seals": game.director.seals.duplicate(), "wounds": game.metrics.wounds}
	route_results.append(result)
	print("SECOND_BOT_ROUTE " + JSON.stringify(result))
	_check(elapsed >= 8.0 and frames >= 480, "route advances real preparation and physics: " + mapping)
	_check(not early_escape and game.director.seals.values().count(true) == 3, "route requires all three selected seals: " + mapping)
	_check(won, "physical bots complete and escape within 450 seconds: " + mapping)
	_check(game.director.escaped_count == 1, "route records exactly the first successful escape: " + mapping)
	_check(game.metrics.wounds == 0 and game.director.alive_count + game.director.escaped_count == 4, "idle Eye route keeps ordinary survivors unopposed: " + mapping)
	var state: Rules = game.director.trial_set
	if state.trial_for_slot("silent") == "vault":
		_check(state.vault_cradles == state.vault_targets, "route banks four exact physical relics: " + mapping)
	elif state.trial_for_slot("silent") == "silent":
		_check(game.motes_state == [2, 2, 2], "route delivers three distinct physical motes: " + mapping)
	else:
		_check(state.third.light_lit == [true, true, true], "route lights three permanent physical refuges: " + mapping)
	if state.trial_for_slot("echoes") == "ritual":
		_check(state.ritual_index == 5 and state.ritual_hold == 8.0, "route completes physical vessels and continuous ring hold: " + mapping)
	if state.trial_for_slot("relay") == "clock":
		_check(state.clock_moves > 0 and state.clock_hands == state.clock_target, "route moves real gears into their target before confirmation: " + mapping)
	if state.trial_for_slot("echoes") == "strings":
		_check(state.third.strings_stage == 3, "route banks all three physical cage stages: " + mapping)
	if state.trial_for_slot("relay") == "chimes":
		_check(state.third.chimes_phrase == 2, "route banks both physical bell phrases: " + mapping)
	if not won:
		print("SECOND_ROUTE_AUTHORITY phase=%s ritual=%d bank=%d hold=%.2f ember=%d clock=%s target=%s cooldown=%.3f cradles=%s targets=%s" % [game.director.phase, state.ritual_index, state.ritual_bank, state.ritual_hold, state.ember_owner, str(state.clock_hands), str(state.clock_target), state.clock_cooldown, str(state.vault_cradles), str(state.vault_targets)])
		for data in game.bots:
			print("SECOND_BOT_STALL role=%s task=%s position=%s target=%s path_index=%d carrying=%d relic=%d action=%.2f index=%d direction=%d health=%.1f gaze=%.1f" % [data.actor.archetype, data.task, str(data.actor.global_position), str(data.target), data.path_index, data.actor.carrying, state.carried_relic(data.actor.get_instance_id()), data.action_time, int(data.get("trial_index", -1)), int(data.get("trial_direction", 0)), data.actor.health, data.actor.gaze])
