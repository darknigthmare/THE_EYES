extends "res://tests/test_survivor_route.gd"
## Same ordinary input/physics driver as the original route, now using all three
## Second Observance trials against active Story Eye AI. No state/health/position
## overrides. The informed driver reads the visible clues and plans legal turns.

const Props = preload("res://scripts/trial_apparatus.gd")
const SECOND_MAX_FRAMES: int = 60 * 570
var observed_targets: Array[int] = []

func _live() -> bool:
	return game.director.phase != "ended" and frames < SECOND_MAX_FRAMES

func _run() -> void:
	Engine.physics_ticks_per_second = 60
	game = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.start_match("survivor","Keeper","story",271126,"second")
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
		if not game.director.seals.relay:
			await _clock_step()
		elif not game.director.seals.silent:
			await _vault_step()
		elif not game.director.seals.echoes:
			await _ritual_step()
		else:
			if await _walk_to(Arena.EXIT_POSITION+Vector3(0,0,1)):
				_action("interact",true)
				for tick in range(100):
					if not await _frame():
						break
				_action("interact",false)
		if not route_failures.is_empty():
			break
	_release_movement()
	_action("interact",false)
	var won: bool = game.director.phase == "ended" and game.director.winner == "survivors"
	print("SECOND_SURVIVOR_RESULT winner=%s phase=%s elapsed=%.2f vitality=%.1f wounds=%d punishments=%d seals=%s cradles=%s clock_moves=%d" % [game.director.winner,game.director.phase,game.elapsed,game.player.health,game.metrics.wounds,game.metrics.punishments_survived,str(game.director.seals),str(game.director.trial_set.vault_cradles),game.director.trial_set.clock_moves])
	for failure in route_failures:
		printerr("ROUTE_FAILURE: ",failure)
	if not won:
		printerr("FAIL: normal-input Second survivor did not escape active Story Eye AI within570simulatedseconds; position=",game.player.global_position)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if won and route_failures.is_empty() else 1)

func _clock_step() -> void:
	var state = game.director.trial_set
	if state.clock_hands == state.clock_target:
		if await _walk_to(Props.CLOCK_CENTER+Vector3(0,0,2.1)):
			await _tap("interact")
			print("SECOND_STAGE clock=",game.director.seals.relay," time=",snappedf(game.elapsed,0.01)," health=",game.player.health)
		return
	var solution: Array[Vector2i] = state.clock_solution()
	if solution.is_empty():
		route_failures.append("Clock lacks a legal route to its visible target")
		return
	var move = solution[0]
	if await _walk_to(Props.CLOCK_LEVERS[move.x]+Vector3(0,0,0.8)):
		await _tap("interact" if move.y > 0 else "reverse")
		for tick in range(18):
			if not await _frame():
				break

func _vault_step() -> void:
	var state = game.director.trial_set
	if observed_targets.is_empty():
		if await _walk_to(Props.VAULT_DESK+Vector3(0,0,2.1)):
			await _tap("interact")
			for tick in range(60*8):
				if not _live() or game.punishment:
					return
				await _heal_if_needed()
				await _frame()
			observed_targets.assign(state.vault_targets)
			print("SECOND_STAGE observed four relics at the actual reference desk")
		return
	var relic: int = state.carried_relic(game.player.get_instance_id())
	if relic >= 0:
		var cradle: int = observed_targets.find(relic)
		if cradle < 0:
			route_failures.append("Unexpected distractor in informed driver's inventory")
			return
		if await _walk_to(Props.CRADLE_POSITIONS[cradle]+Vector3(0,0,1.0)):
			await _tap("interact")
			print("SECOND_STAGE vault=",state.vault_cradles," time=",snappedf(game.elapsed,0.01)," health=",game.player.health)
		return
	var nearest: int = -1
	var distance: float = INF
	for i in range(4):
		if state.vault_cradles[i] >= 0:
			continue
		var candidate: int = observed_targets[i]
		if state.relic_available(candidate):
			var d = game.player.global_position.distance_to(Props.RELIC_POSITIONS[candidate])
			if d < distance:
				distance = d
				nearest = candidate
	if nearest < 0:
		route_failures.append("Required vault relic is unavailable with empty hands")
		return
	if await _walk_to(Props.RELIC_POSITIONS[nearest]+Vector3(0,0,1.0)):
		await _tap("interact")

func _reached_target(target: Vector3) -> bool:
	if game.director.trial_set.ritual_index >= 5 and not game.director.seals.echoes and target.distance_to(Props.RITUAL_CENTER+Vector3(0,0,2)) < 0.1:
		return Vector2(game.player.global_position.x-Props.RITUAL_CENTER.x,game.player.global_position.z-Props.RITUAL_CENTER.z).length() <= 2.6
	return super._reached_target(target)

func _ritual_step() -> void:
	var state = game.director.trial_set
	if state.ritual_index >= 5:
		if not await _walk_to(Props.RITUAL_CENTER+Vector3(0,0,2.0)):
			return
		while _live() and not game.punishment and not game.director.seals.echoes:
			# Occupancy allows movement. Circle the real pedestal inside the ring,
			# outrunning shadows with the normal controller instead of standing still.
			var radial = game.player.global_position-Props.RITUAL_CENTER
			radial.y = 0.0
			var next = Props.RITUAL_CENTER+radial.normalized().rotated(Vector3.UP,0.65)*2.0
			var direction = next-game.player.global_position
			direction.y = 0.0
			game.player.rotation.y = atan2(-direction.x,-direction.z)
			Input.action_release("crouch")
			Input.action_release("sprint")
			Input.action_press("move_forward")
			await _heal_if_needed()
			await _frame()
		_release_movement()
		print("SECOND_STAGE ritual=",game.director.seals.echoes," time=",snappedf(game.elapsed,0.01)," health=",game.player.health)
		return
	if state.ember_owner == 0:
		if await _walk_to(Props.EMBER_POSITION+Vector3(0,0,0.9)):
			await _tap("interact")
	else:
		var vessel: int = state.ritual_sequence[state.ritual_index]
		if await _walk_to(Props.VESSEL_POSITIONS[vessel]+Vector3(0,0,0.85)):
			await _tap("interact")
			print("SECOND_STAGE vessel=",state.ritual_index," time=",snappedf(game.elapsed,0.01)," health=",game.player.health)
