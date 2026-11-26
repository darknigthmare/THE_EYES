extends "res://tests/test_second_survivor_route.gd"
## Two complete Third Observance sessions through ordinary input and physics.
## Eye AI stays active. The informed driver visits the public clue stands before
## reading their visible data; it never sets health, positions, clocks or seals.

const ThirdProps = preload("res://scripts/third_apparatus.gd")
const THIRD_MAX_FRAMES: int = 60 * 570
var third_route_results: Array[Dictionary] = []
var seen_strings_stage: int = -1
var seen_strings_rope: int = -1
var seen_chimes_phrase: int = -1
var seen_chimes_score: Array[int] = []
var third_human_actions: int = 0
var third_evasions: int = 0
var third_observation_restarts: int = 0


func _live() -> bool:
	return game.director.phase != "ended" and frames < THIRD_MAX_FRAMES


func _run() -> void:
	Engine.physics_ticks_per_second = 60
	game = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	game.qa_capture = "test-only-no-file"
	game.qa_done = true
	var failures: int = 0
	for role: String in ["survivor", "squad"]:
		frames = 0
		previous_health = 100.0
		route_failures.clear()
		_reset_third_observations()
		third_human_actions = 0
		third_evasions = 0
		third_observation_restarts = 0
		game.start_match(role, "Keeper", "story", 271126, "third")
		game.soundscape.set_enabled(false)
		if role == "squad":
			await _tap("squad_follow")
			await _walk_to(Vector3(4, 0, 19))
			await _tap("squad_hold")
			for tick: int in range(30):
				await _frame()
			await _tap("squad_work")
		while game.director.phase == "preparation" and _live():
			await _frame()
		while _live():
			if game.punishment:
				await _complete_punishment()
				continue
			await _heal_if_needed()
			if game.player.downed or game.player.eliminated:
				_release_movement()
				_action("interact", false)
				await _frame()
			elif role == "survivor" and not game.director.seals.silent:
				# Establish the numbered western refuges before the noisy bells.
				# These are visible route checkpoints, not a seed-dependent shortcut.
				await _light_step()
			elif not game.director.seals.relay:
				await _chimes_step()
			elif not game.director.seals.silent:
				await _light_step()
			elif not game.director.seals.echoes:
				await _strings_step()
			elif game.director.phase == "escape":
				if await _walk_to(Arena.EXIT_POSITION + Vector3(0, 0, 1)):
					await _hold_interact(1.8)
			if not route_failures.is_empty():
				break
		_release_movement()
		_action("interact", false)
		var state = game.director.trial_set.third
		var own_events: Dictionary = {"light_deposit":0, "strings_cut":0, "chime_strike":0}
		for entry: Dictionary in game.event_log:
			if own_events.has(entry.kind) and int(entry.data.get("actor_id", 0)) == game.player.get_instance_id():
				own_events[entry.kind] += 1
		var won: bool = game.director.phase == "ended" and game.director.winner == "survivors"
		var entry: Dictionary = {"role":role, "contract":"third", "seed":271126, "difficulty":"story", "winner":game.director.winner, "elapsed":snappedf(game.elapsed,0.01), "human_health":game.player.health, "human_distance":snappedf(float(game.metrics.distance),0.01), "human_inputs":third_human_actions, "human_trial_events":own_events, "visible_threat_retreats":third_evasions, "observation_epoch_restarts":third_observation_restarts, "wounds":game.metrics.wounds, "punishments":game.metrics.punishments_survived, "lamps":state.light_lit.duplicate(), "cage_stages":state.strings_stage, "bell_phrases":state.chimes_phrase, "seals":game.director.seals.duplicate(), "failures":route_failures.duplicate()}
		if game.squad_world != null:
			entry.squad = game.squad_world.summary()
		third_route_results.append(entry)
		print("THIRD_SURVIVOR_RESULT " + JSON.stringify(entry))
		var exact_trials: bool = state.light_lit == [true,true,true] and state.strings_stage == 3 and state.chimes_phrase == 2
		var own_work: bool = own_events.light_deposit == 3 and own_events.strings_cut == 3 and own_events.chime_strike >= 8 if role == "survivor" else own_events.chime_strike > 0
		if not won or not exact_trials or not own_work or not route_failures.is_empty() or game.metrics.distance < 20.0:
			failures += 1
			printerr("FAIL: ordinary-input Third %s did not meet its complete-session gates" % role)
			for data: Dictionary in game.bots:
				printerr("THIRD_BOT_STALL ",data.actor.display_name," task=",data.task," point=",data.actor.global_position," target=",data.target," health=",data.actor.health)
		await process_frame
	game.soundscape.stop_all()
	game.queue_free()
	await process_frame
	await process_frame
	print("Third pressured routes: %d sessions, %d failures" % [third_route_results.size(),failures])
	quit(1 if failures > 0 else 0)


func _reset_third_observations() -> void:
	seen_strings_stage = -1
	seen_strings_rope = -1
	seen_chimes_phrase = -1
	seen_chimes_score.clear()


func _tap(action: String) -> void:
	third_human_actions += 1
	await super._tap(action)


func _frame() -> bool:
	# The original route driver only knew legacy whisper-mote carrying. Give
	# the new visible cell the same cautious movement input, without changing
	# an inventory field, speed, controller or actor transform.
	if game.director != null and game.director.trial_set.third.carried_cell(game.player.get_instance_id()) >= 0 and Input.is_action_pressed("move_forward") and not Input.is_action_pressed("sprint") and not _third_hold_danger():
		Input.action_press("crouch")
	await super._frame()
	if game.squad_world != null and (game.player.downed or game.player.eliminated):
		_release_movement()
		_action("interact", false)
		while _live() and (game.player.downed or game.player.eliminated):
			await physics_frame
			frames += 1
	return _live()


func _hold_interact(seconds: float) -> void:
	_release_movement()
	if _third_hold_danger():
		await _retreat_from_hold()
		return
	third_human_actions += 1
	var initial_option: Dictionary = game.trial_world.nearest(game.player)
	var held_kind: String = str(initial_option.get("kind", ""))
	var initial_stage: int = game.director.trial_set.third.strings_stage
	var previous_vitality: float = game.player.health
	_action("interact", true)
	for tick: int in range(ceili(seconds * 60)):
		if not _live() or game.punishment or game.player.downed or game.player.eliminated:
			break
		if held_kind == "strings_cut" and game.director.trial_set.third.strings_stage != initial_stage:
			break
		if held_kind == "light_align" and game.director.trial_set.third.carried_cell(game.player.get_instance_id()) < 0:
			break
		# A hit resets the production hold. Continuing to stand beside a visible
		# shadow cannot complete two uninterrupted seconds; retreat and retry
		# through the same movement controller used by the earlier route tests.
		if _third_hold_danger() or game.player.health < previous_vitality:
			_action("interact", false)
			await _retreat_from_hold()
			return
		await _heal_if_needed()
		previous_vitality = game.player.health
		await _frame()
	_action("interact", false)
	await _frame()


func _third_hold_danger() -> bool:
	if game.player.gaze > 65.0:
		return true
	# Only nearby telegraphs/shadows with an unobstructed ray justify this
	# extra reaction. No hidden position is used to schedule the commitment.
	for point: Vector3 in _threat_positions():
		if game.player.global_position.distance_to(point) < 4.8 and game.has_sight(game.player.target_point(), point + Vector3.UP):
			return true
	return false


func _retreat_from_hold() -> void:
	_release_movement()
	_action("interact", false)
	third_evasions += 1
	if not _live() or game.punishment or game.player.downed or game.player.eliminated:
		return
	var shelter: Vector3 = _physical_shelter()
	if shelter.distance_to(game.player.global_position) > 0.7:
		await _walk_to(shelter, false)
	await _break_gaze()
	_release_movement()


func _walk_to(target: Vector3, allow_cover: bool = true) -> bool:
	if game.contract != "third":
		return await super._walk_to(target, allow_cover)
	if not _live() or game.punishment:
		return false
	var path: PackedVector2Array = game._path(game.player.global_position, target)
	var index: int = 0
	var ticks: int = 0
	var last_progress: Vector3 = game.player.global_position
	var stuck_ticks: int = 0
	while _live() and not game.punishment:
		if not allow_cover and game.has_sight(game.eye_origin(), target + Vector3(0, 0.65, 0)):
			_release_movement()
			return false
		var distance: float = Vector2(game.player.global_position.x - target.x, game.player.global_position.z - target.z).length()
		if _reached_target(target):
			_release_movement()
			for unused: int in range(5):
				await _frame()
			return true
		# A visible, nearby objective offers a short commitment. Repeatedly
		# abandoning it at 50 gaze drains a carried cell on long detours. Accept
		# that bounded gaze risk while healthy; keep the existing cover response
		# for long traversals, low health and actual nearby attacks.
		var short_commitment: bool = distance <= 9.0 and game.player.health > 30.0
		if allow_cover and game.player.gaze > 50.0 and not short_commitment:
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
			game.player.rotation.y = atan2(-direction.x, -direction.z)
		Input.action_press("move_forward")
		var carrying: bool = game.player.carrying >= 0 or game.trial_world.has_cargo(game.player)
		var exposed_commitment: bool = short_commitment and game.player.gaze > 30.0
		if not danger and allow_cover and not exposed_commitment and (carrying or game.player.gaze > 35.0):
			Input.action_press("crouch")
			Input.action_release("sprint")
		else:
			Input.action_release("crouch")
			if (danger or not allow_cover or exposed_commitment) and game.player.stamina > 10.0:
				Input.action_press("sprint")
			else:
				Input.action_release("sprint")
		await _heal_if_needed()
		if not await _frame():
			break
		ticks += 1
		if ticks % 120 == 0:
			stuck_ticks = stuck_ticks + 120 if last_progress.distance_to(game.player.global_position) < 0.1 else 0
			last_progress = game.player.global_position
		if stuck_ticks > 60 * 8:
			route_failures.append("Movement stalled at %s while navigating to %s" % [str(game.player.global_position), str(target)])
			break
	_release_movement()
	return false


func _observe_third_epoch(kind: String, desk: Vector3) -> int:
	var state = game.director.trial_set.third
	var observed: int = state.strings_stage if kind == "strings" else state.chimes_phrase
	var stable_frames: int = 0
	while _live() and not game.punishment and not game.player.downed and not game.player.eliminated:
		var current: int = state.strings_stage if kind == "strings" else state.chimes_phrase
		if current >= (3 if kind == "strings" else 2):
			return -1
		if current != observed:
			observed = current
			stable_frames = 0
			third_observation_restarts += 1
		if game.player.global_position.distance_to(desk) > 2.7 or not game.has_sight(game.player.target_point(), desk + Vector3.UP * 1.65):
			return -1
		if _third_hold_danger():
			await _retreat_from_hold()
			return -1
		if stable_frames >= 120:
			return observed
		await _heal_if_needed()
		await _frame()
		# The next loop checks that the same epoch was visible throughout the
		# interval. A teammate's transition on the final frame resets the count.
		stable_frames += 1
	return -1


func _light_step() -> void:
	var state = game.director.trial_set.third
	var id: int = game.player.get_instance_id()
	var cell: int = state.carried_cell(id)
	if cell >= 0:
		if state.charge_for(id) < _cell_trip_charge(cell, game.player.global_position):
			var refuge: Vector3 = ThirdProps.BASE_REFUGE
			for i: int in range(3):
				if state.light_lit[i] and game.player.global_position.distance_to(ThirdProps.LAMP_POSITIONS[i]) < game.player.global_position.distance_to(refuge):
					refuge = ThirdProps.LAMP_POSITIONS[i]
			if await _walk_to(refuge + Vector3(0,0,2.1)):
				var target_charge: float = _cell_trip_charge(cell, game.player.global_position)
				var previous_vitality: float = game.player.health
				for tick: int in range(60 * 8):
					if not _live() or game.punishment or game.player.downed or state.charge_for(id) >= target_charge:
						break
					if _third_hold_danger() or game.player.health < previous_vitality:
						await _retreat_from_hold()
						return
					await _heal_if_needed()
					previous_vitality = game.player.health
					await _frame()
			return
		if await _walk_to(ThirdProps.LAMP_POSITIONS[cell] + Vector3(0,0,0.9)):
			await _hold_interact(2.3)
		return
	var next_cell: int = -1
	# The printed refuge numbers define a connected west-side progression.
	# Starting with 1 creates the northern recharge point before taking 2/3.
	for i: int in range(3):
		if state.cell_available(i):
			next_cell = i
			break
	if next_cell >= 0:
		if await _walk_to(ThirdProps.CELL_POSITIONS[next_cell] + Vector3(0,0,0.9)):
			await _tap("interact")
	else:
		await _frame()


func _cell_trip_charge(cell: int, origin: Vector3) -> float:
	var destination: Vector3 = ThirdProps.LAMP_POSITIONS[cell] + Vector3(0, 0, 0.9)
	var path: PackedVector2Array = game._path(origin, destination)
	var length: float = 0.0
	for index: int in range(1, path.size()):
		length += path[index - 1].distance_to(path[index])
	# Budget the visible route at normal crouch speed, the two-second hold,
	# and two seconds of margin. Recharge is not forced to an unnecessary full
	# battery while a shadow approaches an otherwise exposed lamp pedestal.
	return clampf((length / 2.25 + 4.0) * 4.0, 32.0, 95.0)


func _strings_step() -> void:
	var state = game.director.trial_set.third
	if seen_strings_stage != state.strings_stage:
		if not await _walk_to(ThirdProps.STRINGS_DESK + Vector3(0,0,2.1)):
			return
		await _tap("interact")
		var observed: int = await _observe_third_epoch("strings", ThirdProps.STRINGS_DESK)
		if observed < 0 or state.strings_stage != observed:
			return
		seen_strings_stage = observed
		seen_strings_rope = -1
		# Solve only the two public observations: side and shape family. This
		# deliberately does not call a hidden-answer or completion shortcut.
		for rope: int in range(4):
			var in_half: bool = rope / 2 == state.strings_half
			var curved: bool = int(state.strings_layout[rope]) < 2
			if in_half and curved == state.strings_curved:
				if seen_strings_rope >= 0:
					route_failures.append("Public rope clues admit more than one answer")
					return
				seen_strings_rope = rope
		return
	if seen_strings_rope < 0:
		route_failures.append("Public rope clues have no valid answer")
		return
	var observed_stage: int = seen_strings_stage
	if await _walk_to(ThirdProps.ROPE_POSITIONS[seen_strings_rope] + Vector3(0,0,0.9)):
		if state.strings_stage == observed_stage:
			await _hold_interact(2.3)


func _chimes_step() -> void:
	var state = game.director.trial_set.third
	if state.chimes_phrase >= 2:
		return
	if seen_chimes_phrase != state.chimes_phrase:
		if not await _walk_to(ThirdProps.CHIMES_DESK + Vector3(0,0,2.1)):
			return
		await _tap("interact")
		var observed: int = await _observe_third_epoch("chimes", ThirdProps.CHIMES_DESK)
		if observed >= 0 and state.chimes_phrase == observed:
			seen_chimes_phrase = observed
			seen_chimes_score.assign(state.chimes_sequences[seen_chimes_phrase])
		return
	var phrase: int = state.chimes_phrase
	var note_index: int = state.chimes_index
	var bell: int = seen_chimes_score[note_index]
	if await _walk_to(ThirdProps.BELL_POSITIONS[bell] + Vector3(0,0,0.9)):
		if state.chimes_phrase != phrase or state.chimes_index != note_index:
			return
		if state.damper != bell:
			await _tap("reverse")
		if state.chimes_phrase != phrase or state.chimes_index != note_index:
			return
		await _tap("interact")
		for tick: int in range(28):
			if not await _frame():
				break
