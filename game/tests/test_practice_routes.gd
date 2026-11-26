extends "res://tests/test_third_survivor_route.gd"
## Nine complete drills through ordinary movement, input and world admission.
## No actor positions, health, objective states, speeds or elapsed times are set.
## The informed driver reads the same physical clues as the competitive routes.

const PracticeState = preload("res://scripts/practice_state.gd")

func _run() -> void:
	Engine.physics_ticks_per_second = 60
	game = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.qa_capture = "test-only-no-file"
	game.qa_done = true
	var failures: int = 0
	var results: Array[Dictionary] = []
	for trial_id: String in PracticeState.TRIAL_IDS:
		frames = 0
		previous_health = 100.0
		route_failures.clear()
		observed_targets.clear()
		_reset_third_observations()
		third_human_actions = 0
		game.start_practice(trial_id,"Keeper",271126)
		game.soundscape.set_enabled(false)
		while _live():
			match trial_id:
				"silent": await _silent_practice_step()
				"echoes": await _complete_echoes()
				"relay": await _complete_relay()
				"vault": await _vault_step()
				"ritual": await _ritual_step()
				"clock": await _clock_step()
				"light": await _light_step()
				"strings": await _strings_step()
				"chimes": await _chimes_step()
			if not route_failures.is_empty():
				break
		_release_movement()
		_action("interact",false)
		var completion_events: int = 0
		var match_results: int = 0
		for event: Dictionary in game.event_log:
			completion_events += 1 if event.kind == "practice_completed" else 0
			match_results += 1 if event.kind == "result" else 0
		var exact_seal: bool = game.director.seals.values().count(true) == 1 and bool(game.director.seals[game.director.practice.slot_id])
		var success: bool = game.director.phase == "ended" and game.director.practice.completed and exact_seal and completion_events == 1 and match_results == 0 and game.director.winner.is_empty() and game.director.escaped_count == 0 and game.player.health == 100.0 and int(game.metrics.wounds) == 0 and game.bots.is_empty() and game.shadows.is_empty() and game.metrics.distance > 1.0 and route_failures.is_empty()
		var result: Dictionary = {"trial_id":trial_id,"archetype":"Keeper","seed":271126,"elapsed":snappedf(game.director.practice.elapsed,0.01),"distance":snappedf(game.metrics.distance,0.01),"health":game.player.health,"completion_events":completion_events,"match_results":match_results,"seals":game.director.seals.duplicate(),"success":success,"failures":route_failures.duplicate()}
		results.append(result)
		print("PRACTICE_ROUTE_RESULT " + JSON.stringify(result))
		if not success:
			failures += 1
			printerr("FAIL: ordinary-input practice did not complete " + trial_id)
		await process_frame
	game.soundscape.stop_all()
	game.queue_free()
	await process_frame
	await process_frame
	print("Practice ordinary-input routes: %d sessions, %d failures" % [results.size(),failures])
	quit(1 if failures > 0 else 0)

func _silent_practice_step() -> void:
	if game.player.carrying >= 0:
		if await _walk_to(Arena.STATIONS.silent+Vector3(0,0,2.3)):
			await _tap("interact")
		return
	var nearest: float = INF
	var chosen: int = -1
	for index: int in range(3):
		if game.motes_state[index] == 0:
			var distance: float = game.player.global_position.distance_to(game._mote_position(index))
			if distance < nearest:
				nearest = distance
				chosen = index
	if chosen < 0:
		route_failures.append("No available practice mote before completion")
	elif await _walk_to(game._mote_position(chosen)+Vector3(0,0,1.7)):
		await _tap("interact")
