extends "res://tests/test_third_survivor_route.gd"
## Full local Squad sessions through ordinary inputs and real physics. The Eye
## stays active. No damage, health, speed, clock, positions, or seals are injected.
## The informed human works on the south mechanism while four allies do real work.

const SQUAD_ROUTE_LIMIT: int = 60*450
var route_results: Array[Dictionary] = []
var human_actions: int = 0

func _live() -> bool:
	return game.director.phase != "ended" and frames < SQUAD_ROUTE_LIMIT

func _run() -> void:
	Engine.physics_ticks_per_second = 60
	game = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.qa_capture = "test-only-no-file"
	game.qa_done = true
	var failures: int = 0
	for selected_contract: String in ["first","second","mix"]:
		frames = 0
		human_actions = 0
		previous_health = 100.0
		observed_targets.clear()
		_reset_third_observations()
		route_failures.clear()
		game.start_match("squad","Keeper","story",271126,selected_contract)
		game.soundscape.set_enabled(false)
		await _tap("squad_follow")
		await _walk_to(Vector3(4,0,19))
		await _tap("squad_hold")
		for tick in range(30):
			await _frame()
		await _tap("squad_work")
		while game.director.phase == "preparation" and _live():
			await _frame()
		while _live():
			await _heal_if_needed()
			if game.player.downed or game.player.eliminated:
				await _frame()
			elif not game.director.seals.relay:
				if game.director.trial_for_slot("relay") == "clock":
					await _clock_step()
				elif game.director.trial_for_slot("relay") == "chimes":
					await _chimes_step()
				else:
					await _complete_relay()
			elif game.director.phase == "escape":
				if await _walk_to(Arena.EXIT_POSITION+Vector3(0,0,1)):
					_action("interact",true)
					for tick in range(100):
						if not await _frame():
							break
					_action("interact",false)
			else:
				# Work with allies in the north, using real movement and cover. The
				# squad's other specialists retain puzzle ownership and reservations.
				var next: Vector3 = Vector3(-5,0,-12) if game.player.global_position.z > -8 else Vector3(5,0,-12)
				await _walk_to(next)
				for tick in range(60):
					if not await _frame():
						break
			if not route_failures.is_empty():
				break
		_release_movement()
		_action("interact",false)
		var summary: Dictionary = game.squad_world.summary()
		var won: bool = game.director.phase == "ended" and game.director.winner == "survivors"
		var entry = {"contract":selected_contract,"seed":271126,"difficulty":"story","winner":game.director.winner,"elapsed":snappedf(game.elapsed,0.01),"human_health":game.player.health,"human_distance":snappedf(float(game.metrics.distance),0.01),"human_actions":human_actions,"wounds":game.metrics.wounds,"seals":game.director.seals.duplicate(),"squad":summary,"failures":route_failures.duplicate()}
		route_results.append(entry)
		print("SQUAD_ROUTE_RESULT "+JSON.stringify(entry))
		if not won or not route_failures.is_empty() or summary.orders < 3 or game.metrics.distance < 5.0 or game.metrics.punishments_survived != 0:
			failures += 1
			printerr("FAIL: ordinary-input Squad %s did not meet its complete-session gates" % selected_contract)
			for data: Dictionary in game.bots:
				printerr("SQUAD_BOT ",data.actor.display_name," task=",data.task," point=",data.actor.global_position," target=",data.target," health=",data.actor.health)
		await process_frame
	game.soundscape.stop_all()
	await process_frame
	await process_frame
	game.queue_free()
	await process_frame
	await process_frame
	print("Squad routes: %d sessions, %d failures" % [route_results.size(),failures])
	quit(1 if failures > 0 else 0)

func _tap(action: String) -> void:
	human_actions += 1
	await super._tap(action)

func _frame() -> bool:
	await physics_frame
	frames += 1
	if game.player.downed or game.player.eliminated:
		_release_movement()
		_action("interact",false)
		while _live() and (game.player.downed or game.player.eliminated):
			await physics_frame
			frames += 1
	return _live()

func _heal_if_needed() -> void:
	if game.player.downed or game.player.eliminated:
		return
	var target: EyesSurvivor = game.squad_world.healing_target(game.player)
	if target.health <= 70.0 and game.player.ability_cooldown <= 0 and not game.echo_open:
		await _tap("ability")
