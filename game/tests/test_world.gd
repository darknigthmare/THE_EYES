extends SceneTree
## World-level regression checks using the actual scene and real 3D physics.
## Run with --headless --fixed-fps 60; no rendering assertions are made here.

const MAIN_SCENE = preload("res://scenes/main.tscn")
const Arena = preload("res://scripts/arena.gd")
var game
var failures: int = 0
var assertions: int = 0
var cases: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Engine.physics_ticks_per_second = 60
	game = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	game.soundscape.set_enabled(false)
	# Suppress persistence during automated results without triggering a capture.
	game.qa_capture = "test-only-no-file"
	game.qa_done = true
	await _test_world_sight()
	await _test_trap_validation_and_telegraph()
	await _test_mote_and_exit_authority()
	await _test_dead_survivor_damage()
	await _test_shadow_wall_collision()
	await _test_unopposed_bot_routes()
	Input.action_release("interact")
	game.queue_free()
	await process_frame
	await process_frame
	print("World integration: %d cases, %d assertions, %d failures" % [cases, assertions, failures])
	quit(1 if failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)


func _near(actual: float, expected: float, description: String) -> void:
	_check(absf(actual - expected) < 0.001, description + " (%.4f vs %.4f)" % [actual, expected])


func _start_isolated(role: String = "survivor") -> void:
	Input.action_release("interact")
	game.start_match(role, "Veil", "standard", 271126)
	game.soundscape.set_enabled(false)
	game.set_physics_process(false)
	await physics_frame
	await physics_frame
	game.director.step(8.0)


func _test_world_sight() -> void:
	cases += 1
	await _start_isolated()
	_check(not game.has_sight(Vector3(0, 1.2, -12), Vector3(0, 1.2, 12)), "the central obelisk blocks a real physics ray")
	_check(game.has_sight(Vector3(-23, 1.2, -12), Vector3(-23, 1.2, 12)), "the west circulation lane has clear physical sight")
	_check(not game.has_sight(Vector3(0, 1.2, 20), Vector3(0, 1.2, 28)), "the south perimeter blocks sight outside the arena")
	_check(game.player.camera.current, "survivor mode activates the player's first-person camera")


func _test_trap_validation_and_telegraph() -> void:
	cases += 1
	await _start_isolated("eye")
	_check(game.actors.size() == 4 and game.eye_camera.current, "Eye mode creates four survivors and activates its own camera")
	var hidden_index: int = -1
	for socket_index: int in range(4):
		game._set_socket(socket_index, true)
		for trap_index: int in range(Arena.TRAP_POSITIONS.size()):
			var point: Vector3 = Arena.TRAP_POSITIONS[trap_index] + Vector3.UP * 0.18
			var direction: Vector3 = (point - game.eye_origin()).normalized()
			if game.eye_forward.dot(direction) > cos(deg_to_rad(43.0)) and not game.has_sight(game.eye_origin(), point):
				hidden_index = trap_index
				break
		if hidden_index >= 0:
			break
	_check(hidden_index >= 0, "a trap is geometrically occluded inside the Eye's cone")
	if hidden_index >= 0:
		var previous_energy: float = game.director.energy
		_check(not game._activate_trap(hidden_index), "occluded trap activation is rejected by the world")
		_near(game.director.energy, previous_energy, "occluded trap does not consume energy")
		_check(game.traps[hidden_index].state == "idle", "occluded trap remains inert")
	var visible_index: int = -1
	for socket_index: int in range(4):
		game._set_socket(socket_index, true)
		for trap_index: int in range(Arena.TRAP_POSITIONS.size()):
			if game.eye_sees(Arena.TRAP_POSITIONS[trap_index] + Vector3.UP * 0.18):
				visible_index = trap_index
				break
		if visible_index >= 0:
			break
	_check(visible_index >= 0, "at least one floor trap is legitimately targetable")
	if visible_index >= 0:
		var victim = game.actors[0]
		victim.active = false
		victim.global_position = Arena.TRAP_POSITIONS[visible_index] + Vector3.UP * 0.1
		victim.respawn_shield = 0.0
		victim.invulnerability = 0.0
		_check(game._activate_trap(visible_index), "visible ready trap activates")
		game._update_traps(1.49)
		_near(victim.health, 100.0, "warning interval does not inflict damage")
		game._update_traps(0.02)
		_check(game.traps[visible_index].state == "active", "trap becomes active after its warning")
		game._update_traps(0.01)
		_near(victim.health, 65.0, "active floor trap inflicts its specified damage")
		victim.invulnerability = 0.0
		game._update_traps(0.5)
		_near(victim.health, 65.0, "one trap activation cannot repeatedly hit the same survivor")


func _test_mote_and_exit_authority() -> void:
	cases += 1
	await _start_isolated()
	var survivor = game.player
	survivor.active = false
	_check(not game._pickup(survivor, 0), "a distant mote cannot be collected")
	_near(float(game.motes_state[0]), 0.0, "rejected pickup leaves the mote available")
	survivor.global_position = Arena.EXIT_POSITION + Vector3(0, 0.1, 1)
	Input.action_press("interact")
	game._update_player_objectives(2.0)
	_check(game.director.phase == "hunt" and game.director.escaped_count == 0, "interacting at the closed exit cannot win")
	Input.action_release("interact")
	for mote_index: int in range(3):
		survivor.global_position = game._mote_position(mote_index) + Vector3(0, 0.1, 1)
		_check(game._pickup(survivor, mote_index), "nearby unclaimed mote can be collected")
		_check(not game._pickup(survivor, mote_index), "carried mote cannot be collected twice")
		_check(game.motes_state[mote_index] == 1 and survivor.carrying == mote_index, "world tracks the carried mote identity")
		if mote_index == 0:
			var gaze_before_noise: float = survivor.gaze
			game._player_step(0.9)
			_near(survivor.gaze, gaze_before_noise, "a noisy carried mote cannot add gaze damage through walls")
			_check(game.noise_memory > 0.0, "a noisy carried mote still provides an audible location clue")
		_check(not game._deliver(survivor), "delivery from the pickup location is rejected")
		survivor.global_position = Arena.STATIONS.silent + Vector3(0, 0.1, 2)
		_check(game._deliver(survivor), "physical arrival at Silent Countdown permits delivery")
		_check(game.motes_state[mote_index] == 2 and survivor.carrying == -1, "delivered mote is consumed and hands become free")
		_check(not game._deliver(survivor), "empty-handed delivery cannot duplicate progress")
	_check(game.director.motes_delivered == 3 and game.director.seals.silent, "three distinct world motes complete the Silent seal")
	_check(game.director.phase == "hunt", "Silent seal alone keeps the exit locked")
	survivor.global_position = Arena.STATIONS.echoes + Vector3(0, 0.1, 2)
	game._interact_player()
	_check(game.echo_open, "nearby Echo interaction opens the real sequence panel")
	game._update_echo(5.0)
	for symbol: int in game.director.echo_sequence:
		game._echo_input(symbol)
	_check(game.director.seals.echoes and not game.echo_open, "correct world inputs complete Echoes and close its panel")
	_check(game.director.phase == "hunt", "two seals keep the exit locked")
	survivor.active = false
	survivor.global_position = Arena.STATIONS.relay + Vector3(0, 0.1, 2)
	Input.action_press("interact")
	game._update_player_objectives(12.0)
	_check(game.director.seals.relay and game.director.phase == "escape", "holding the actual relay completes the third seal and arms escape")
	survivor.global_position = Arena.EXIT_POSITION + Vector3(0, 0.1, 1)
	game._update_player_objectives(1.6)
	Input.action_release("interact")
	_check(game.director.phase == "ended" and game.director.winner == "survivors", "a held physical exit interaction wins after all three seals")


func _test_dead_survivor_damage() -> void:
	cases += 1
	await _start_isolated("eye")
	var victim = game.actors[0]
	victim.active = false
	victim.respawn_shield = 0.0
	victim.invulnerability = 0.0
	game._hurt(victim, 100.0, "Integration test")
	_check(victim.eliminated and game.director.alive_count == 3, "lethal world damage eliminates one survivor")
	var wounds_before: int = game.metrics.wounds
	victim.invulnerability = 0.0
	game._hurt(victim, 100.0, "Repeated integration damage")
	_check(game.director.alive_count == 3 and game.metrics.wounds == wounds_before, "dead survivors cannot be damaged or counted twice")
	_check(not game._mark(victim), "dead survivors cannot be marked")


func _test_shadow_wall_collision() -> void:
	cases += 1
	await _start_isolated()
	game._set_socket(0, true)
	_check(game._summon(Vector3(0, 0, -5)), "a valid visible floor position can summon a shadow")
	if game.shadows.is_empty():
		return
	var shadow: CharacterBody3D = game.shadows[0].node
	_check(shadow.collision_mask & 1 != 0, "shadow uses the real architecture collision layer")
	for tick: int in range(120):
		await physics_frame
		shadow.velocity = Vector3(0, 0, 10)
		shadow.move_and_slide()
	_check(shadow.global_position.z <= -2.95 and shadow.global_position.z > -3.2, "a shadow moving directly toward the obelisk stops at its physical wall: " + str(shadow.global_position))
	_check(shadow.get_slide_collision_count() > 0, "shadow collision is reported by Godot physics")


func _test_unopposed_bot_routes() -> void:
	cases += 1
	game.start_match("eye", "Veil", "standard", 271126)
	game.soundscape.set_enabled(false)
	game.set_physics_process(true)
	# An idle human Eye can look away. This removes gaze pressure without changing
	# bot health, speed, task logic, paths, physical collisions or objective rules.
	game.eye_forward = Vector3(0, 0.25, -1).normalized()
	game.eye_camera.rotation = Vector3(atan(0.25), 0, 0)
	var elapsed_before: float = game.elapsed
	var frames: int = 0
	while game.director.phase != "ended" and frames < 60 * 200:
		await physics_frame
		frames += 1
	var simulated_seconds: float = game.elapsed - elapsed_before
	print("BOT_ROUTE_RESULT phase=%s winner=%s time=%.2f seals=%s deliveries=%d" % [game.director.phase, game.director.winner, simulated_seconds, str(game.director.seals), game.director.motes_delivered])
	for data in game.bots:
		print("BOT_STATE role=%s task=%s position=%s target=%s path_index=%s carrying=%d action=%.2f" % [data.actor.archetype, data.task, str(data.actor.global_position), str(data.target), str(data.path_index), data.actor.carrying, data.action_time])
	_check(simulated_seconds >= 8.0, "bot route test actually advances the running physics simulation")
	_check(game.director.seals.silent and game.director.seals.echoes and game.director.seals.relay, "unopposed bots physically reach and complete all three trials within 200 seconds")
	_check(game.motes_state == [2, 2, 2], "bot completion consumes all three physical motes")
	_check(game.director.phase == "ended" and game.director.winner == "survivors", "unopposed bots navigate to the real exit and win within 200 seconds")
	_check(game.director.escaped_count == 1, "bot exit records the first successful escape")
