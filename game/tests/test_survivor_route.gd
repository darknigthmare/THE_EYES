extends SceneTree
## A deterministic input driver for one normal Story/Keeper survivor match.
## The Eye AI remains active. No health, speed, clock, objective, or position
## overrides are used. The driver knows the map and correctly reads puzzle cues.

const MAIN_SCENE = preload("res://scenes/main.tscn")
const Arena = preload("res://scripts/arena.gd")
const MAX_FRAMES: int = 60 * 300
var game
var frames: int = 0
var route_failures: Array[String] = []
var previous_health: float = 100.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Engine.physics_ticks_per_second = 60
	game = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.start_match("survivor", "Keeper", "story", 271126)
	game.soundscape.set_enabled(false)
	game.qa_capture = "test-only-no-file"
	game.qa_done = true
	while game.director.phase == "preparation":
		if not await _frame():
			break
	while _live():
		if game.punishment:
			await _complete_punishment()
			continue
		await _heal_if_needed()
		if game.player.carrying >= 0:
			if await _walk_to(Arena.STATIONS.silent + Vector3(0, 0, 2.3)):
				await _tap("interact")
				print("SURVIVOR_STAGE delivered=", game.director.motes_delivered, " time=", snappedf(game.elapsed, 0.01), " health=", game.player.health)
		elif not game.director.seals.relay:
			await _complete_relay()
		elif not game.director.seals.silent:
			var nearest: float = INF
			var chosen: int = -1
			for index: int in range(3):
				if game.motes_state[index] == 0:
					var distance: float = game.player.global_position.distance_to(game._mote_position(index))
					if distance < nearest:
						nearest = distance
						chosen = index
			if chosen < 0:
				route_failures.append("No available mote while Silent remains incomplete")
				break
			if await _walk_to(game._mote_position(chosen) + Vector3(0, 0, 1.7)):
				await _tap("interact")
				print("SURVIVOR_STAGE pickup=", game.player.carrying, " time=", snappedf(game.elapsed, 0.01), " health=", game.player.health)
		elif not game.director.seals.echoes:
			await _complete_echoes()
		else:
			if await _walk_to(Arena.EXIT_POSITION + Vector3(0, 0, 1)):
				_action("interact", true)
				for tick: int in range(100):
					if not await _frame():
						break
				_action("interact", false)
		if not route_failures.is_empty():
			break
	_release_movement()
	_action("interact", false)
	var won: bool = game.director.phase == "ended" and game.director.winner == "survivors"
	print("SURVIVOR_ROUTE_RESULT winner=%s phase=%s elapsed=%.2f vitality=%.1f wounds=%d punishments=%d seals=%s deliveries=%d" % [game.director.winner, game.director.phase, game.elapsed, game.player.health, game.metrics.wounds, game.metrics.punishments_survived, str(game.director.seals), game.director.motes_delivered])
	print("SURVIVOR_FINAL_POSITION ", game.player.global_position, " gaze=", game.player.gaze, " carrying=", game.player.carrying)
	for failure: String in route_failures:
		printerr("ROUTE_FAILURE: ", failure)
	if not won:
		printerr("FAIL: normal-input survivor did not escape active Story Eye AI within 300 simulated seconds")
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if won and route_failures.is_empty() else 1)


func _live() -> bool:
	return game.director.phase != "ended" and frames < MAX_FRAMES


func _frame() -> bool:
	await physics_frame
	frames += 1
	if game.player.health != previous_health:
		print("SURVIVOR_HEALTH t=%.2f hp=%.1f from=%.1f position=%s gaze=%.1f eye=%d shadows=%d ability=%.1f" % [game.elapsed, game.player.health, previous_health, str(game.player.global_position), game.player.gaze, game.director.eye_socket, game.shadows.size(), game.player.ability_cooldown])
		previous_health = game.player.health
	return _live()


func _action(action: String, pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _tap(action: String) -> void:
	_action(action, true)
	await _frame()
	_action(action, false)
	await _frame()


func _release_movement() -> void:
	Input.action_release("move_forward")
	Input.action_release("sprint")
	Input.action_release("crouch")


func _heal_if_needed() -> void:
	var should_use: bool = game.player.health <= 70.0 if game.player.archetype == "Keeper" else game.player.gaze >= 35.0
	if should_use and game.player.ability_cooldown <= 0.0 and not game.echo_open and not game.punishment:
		await _tap("ability")


func _reached_target(target: Vector3) -> bool:
	return Vector2(game.player.global_position.x-target.x,game.player.global_position.z-target.z).length() < 0.6


func _walk_to(target: Vector3, allow_cover: bool = true) -> bool:
	if not _live() or game.punishment:
		return false
	var path: PackedVector2Array = game._path(game.player.global_position, target)
	var index: int = 0
	var ticks: int = 0
	var start: Vector3 = game.player.global_position
	var last_progress: Vector3 = start
	var stuck_ticks: int = 0
	while _live() and not game.punishment:
		if not allow_cover and game.has_sight(game.eye_origin(), target + Vector3(0, 0.65, 0)):
			_release_movement()
			return false
		var flat_distance: float = Vector2(game.player.global_position.x - target.x, game.player.global_position.z - target.z).length()
		if _reached_target(target):
			_release_movement()
			for unused: int in range(5):
				await _frame()
			return true
		if allow_cover and game.player.gaze > 50.0:
			_release_movement()
			await _break_gaze()
			path = game._path(game.player.global_position, target)
			index = 0
		if ticks % 60 == 0:
			path = game._path(game.player.global_position, target)
			index = 0
		while index < path.size() and Vector2(game.player.global_position.x, game.player.global_position.z).distance_to(path[index]) < 0.45:
			index += 1
		var waypoint: Vector3 = target
		if index < path.size():
			waypoint = Vector3(path[index].x, game.player.global_position.y, path[index].y)
		var direction: Vector3 = waypoint - game.player.global_position
		direction.y = 0.0
		var danger: bool = _near_threat(5.0)
		if danger:
			direction = _avoid_threats(direction)
		if direction.length() > 0.01:
			# Normal view steering only; CharacterBody movement and collisions remain
			# entirely in the production input-driven survivor controller.
			game.player.rotation.y = atan2(-direction.x, -direction.z)
		Input.action_press("move_forward")
		var carrying: bool = game.player.carrying >= 0
		if not danger and allow_cover and (carrying or game.player.gaze > 35.0):
			Input.action_press("crouch")
			Input.action_release("sprint")
		else:
			Input.action_release("crouch")
			if (danger or not allow_cover) and game.player.stamina > 10.0:
				Input.action_press("sprint")
			else:
				Input.action_release("sprint")
		await _heal_if_needed()
		if not await _frame():
			break
		ticks += 1
		if ticks % 120 == 0:
			if last_progress.distance_to(game.player.global_position) < 0.1:
				stuck_ticks += 120
			else:
				stuck_ticks = 0
			last_progress = game.player.global_position
		if stuck_ticks > 60 * 8:
			route_failures.append("Movement stalled at %s while navigating to %s" % [str(game.player.global_position), str(target)])
			break
	_release_movement()
	return false


func _break_gaze() -> void:
	if not _live() or game.punishment:
		return
	_action("interact", false)
	var waited: int = 0
	while _live() and not game.punishment and game.player.gaze > 12.0 and waited < 600:
		if game.has_sight(game.eye_origin(), game.player.global_position + Vector3(0, 0.65, 0)) or _near_threat(4.5):
			Input.action_release("crouch")
			var shelter: Vector3 = _physical_shelter()
			if shelter.distance_to(game.player.global_position) > 0.7:
				await _walk_to(shelter, false)
		_release_movement()
		Input.action_press("crouch")
		await _heal_if_needed()
		await _frame()
		waited += 1
	Input.action_release("crouch")


func _physical_shelter() -> Vector3:
	var candidates: Array[Vector3] = [Vector3(-5, 0, 0), Vector3(5, 0, 0), Vector3(0, 0, -5), Vector3(0, 0, 5), Vector3(-9, 0, -9), Vector3(-9, 0, 9), Vector3(9, 0, -9), Vector3(9, 0, 9)]
	var best: Vector3 = game.player.global_position
	var best_length: float = INF
	for candidate: Vector3 in candidates:
		if game.has_sight(game.eye_origin(), candidate + Vector3(0, 0.65, 0)):
			continue
		var path: PackedVector2Array = game._path(game.player.global_position, candidate)
		var length: float = 0.0
		for index: int in range(1, path.size()):
			length += path[index - 1].distance_to(path[index])
		for threat: Vector3 in _threat_positions():
			if threat.distance_to(candidate) < 5.0:
				length += 30.0
		if length < best_length:
			best_length = length
			best = candidate
	return best


func _threat_positions() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for index: int in range(game.traps.size()):
		if game.traps[index].state == "warning" or game.traps[index].state == "active":
			points.append(Arena.TRAP_POSITIONS[index])
	for shadow in game.shadows:
		if shadow.warmup < 0.7:
			points.append(shadow.node.global_position)
	return points


func _near_threat(distance: float) -> bool:
	for point: Vector3 in _threat_positions():
		if game.player.global_position.distance_to(point) < distance:
			return true
	return false


func _avoid_threats(planned: Vector3) -> Vector3:
	var best: Vector3 = planned.normalized()
	var best_score: float = -INF
	var at: Vector3 = game.player.global_position
	for option: int in range(16):
		var direction: Vector3 = Vector3(sin(option * TAU / 16.0), 0, cos(option * TAU / 16.0))
		var endpoint: Vector3 = at + direction * 2.2
		var cell: Vector2i = Vector2i(roundi(endpoint.x), roundi(endpoint.z))
		if not game.navigation.is_in_boundsv(cell) or game.navigation.is_point_solid(cell):
			continue
		if not game.has_sight(at + Vector3.UP, endpoint + Vector3.UP):
			continue
		var score: float = direction.dot(planned.normalized()) * 2.0
		for threat: Vector3 in _threat_positions():
			var before: float = at.distance_to(threat)
			if before < 7.0:
				score += (endpoint.distance_to(threat) - before) * (2.5 if before < 3.5 else 1.2)
		if score > best_score:
			best_score = score
			best = direction
	return best


func _complete_relay() -> void:
	if not await _walk_to(Arena.STATIONS.relay + Vector3(0, 0, 2.3)):
		return
	_action("interact", true)
	while _live() and not game.punishment and not game.director.seals.relay:
		if game.player.gaze > 65.0 or _near_threat(4.5):
			_action("interact", false)
			await _break_gaze()
			return
		await _heal_if_needed()
		await _frame()
	_action("interact", false)
	print("SURVIVOR_STAGE relay=", game.director.seals.relay, " time=", snappedf(game.elapsed, 0.01), " health=", game.player.health)


func _complete_echoes() -> void:
	if not await _walk_to(Arena.STATIONS.echoes + Vector3(0, 0, 2.3)):
		return
	if game.player.gaze > 25.0:
		await _break_gaze()
		return
	await _tap("interact")
	if not game.echo_open:
		route_failures.append("Echo panel did not open after a valid interaction")
		return
	while _live() and game.echo_open and game.echo_showing:
		await _frame()
	while _live() and game.echo_open and not game.echo_showing and not game.director.seals.echoes:
		var symbol: int = game.director.echo_sequence[game.director.echo_index]
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = KEY_1 + symbol
		event.keycode = KEY_1 + symbol
		event.pressed = true
		Input.parse_input_event(event)
		await _frame()
		event = event.duplicate()
		event.pressed = false
		Input.parse_input_event(event)
		for tick: int in range(12):
			await _frame()
	print("SURVIVOR_STAGE echoes=", game.director.seals.echoes, " time=", snappedf(game.elapsed, 0.01), " health=", game.player.health)


func _complete_punishment() -> void:
	_release_movement()
	_action("interact", false)
	while _live() and game.punishment:
		var beat: float = fmod(game.punishment_beat, 2.0)
		if beat >= 1.35 and beat <= 1.65:
			await _tap("interact")
		else:
			await _frame()
	print("SURVIVOR_STAGE second_sight=", game.metrics.punishments_survived, " time=", snappedf(game.elapsed, 0.01), " health=", game.player.health)
