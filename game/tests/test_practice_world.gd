extends "res://tests/test_third_world.gd"
## Admission and lifecycle fixtures deliberately position actors. Complete
## ordinary-input practice runs are kept in test_practice_routes.gd.

const PracticeState = preload("res://scripts/practice_state.gd")
const EyesPracticeGuide = preload("res://scripts/practice_guide.gd")

func _run() -> void:
	Engine.physics_ticks_per_second = 60
	game = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	game.qa_capture = "test-only-no-file"
	game.qa_done = true
	await _test_single_bays()
	await _test_invalid_selection()
	await _test_training_has_no_hostile_authority()
	await _test_practice_physical_admission()
	await _test_manual_and_focus_lifecycle()
	await _test_practice_hold_pause()
	await _test_restart_and_normal_return()
	await _test_practice_completion_journal()
	game._return_to_menu()
	game.soundscape.stop_all()
	game.queue_free()
	await process_frame
	await process_frame
	print("Practice world integration: %d cases, %d assertions, %d failures" % [cases,assertions,failures])
	quit(1 if failures > 0 else 0)

func _practice_start(trial_id: String, role: String = "Keeper", seed_value: int = 271126) -> void:
	paused = false
	_check(game.start_practice(trial_id,role,seed_value),"valid practice starts: " + trial_id)
	game.soundscape.set_enabled(false)
	game.set_physics_process(false)
	game.player.active = false
	await physics_frame
	await physics_frame

func _test_single_bays() -> void:
	for trial_id: String in PracticeState.TRIAL_IDS:
		cases += 1
		await _practice_start(trial_id)
		var selection: Dictionary = game.director.trial_set.slot_trials
		_check(selection.values().count("") == 2 and selection.values().count(trial_id) == 1,"exactly one active bay: " + trial_id)
		_check(game.session_mode == "practice" and game.contract == "practice" and game.director.phase == "practice","dedicated session and authority: " + trial_id)
		_check(game.actors.size() == 1 and game.bots.is_empty() and game.squad_world == null,"single real survivor: " + trial_id)
		_check(game.director.seals.values().count(true) == 0,"inactive bays are not pre-completed: " + trial_id)
		_check(game.ui.practice_enabled and game.ui.practice_view.catalogue.size() == 9,"direct start supplies workshop UI: " + trial_id)
		for slot: String in selection:
			if str(selection[slot]).is_empty():
				_check(game.arena.station_titles[slot].text.contains("INACTIVE BAY"),"inactive station retains visible geometry and label")
		_check(game.arena.motes[0].get_parent().visible == (trial_id == "silent"),"motes only in Silent practice")
		_check(not game.apparatus.relic_nodes.is_empty() == (trial_id == "vault"),"relics only in Vault practice")
		_check(not game.apparatus.third.cell_nodes.is_empty() == (trial_id == "light"),"cells only in Light practice")
		_check(not game.apparatus.third.rope_tags.is_empty() == (trial_id == "strings"),"ropes only in Strings practice")
		_check(not game.apparatus.third.bell_pivots.is_empty() == (trial_id == "chimes"),"bells only in Chimes practice")
		for eye in game.arena.eyes:
			_check(not eye.visible,"Eye presentation disabled in practice")

func _test_invalid_selection() -> void:
	cases += 1
	await _practice_start("relay")
	var original = game.director
	for invalid: Array in [["missing","Keeper",123],["relay","missing",123],["relay","Keeper",0],["relay","Keeper",1000000]]:
		_check(not game.start_practice(invalid[0],invalid[1],invalid[2]),"invalid practice request rejected")
		_check(game.director == original and original.phase == "practice","invalid request leaves current attempt intact")

func _test_training_has_no_hostile_authority() -> void:
	cases += 1
	await _practice_start("clock")
	var start_energy: float = game.director.energy
	var start_terror: float = game.director.terror
	game.director.step(86400.0)
	for unused: int in range(60):
		game._physics_process(1.0/60.0)
	game._hurt(game.player,1000.0,"test damage")
	_check(game.director.phase == "practice" and game.director.practice.elapsed >= 86401.0-0.01,"practice has elapsed time without match deadline")
	_check(game.player.health == 100.0 and game.player.gaze == 0.0 and not game.punishment,"no gaze, wounds or Second Sight")
	_check(game.director.energy == start_energy and game.director.terror == start_terror,"Eye resources do not regenerate")
	_check(game.shadows.is_empty() and int(game.metrics.shadows_called) == 0,"no hidden AI summons")
	game.director.register_escape()
	_check(not game.director.switch_socket(1) and game.director.escaped_count == 0,"Eye sockets and escape reject practice")
	_check(not game._pickup(game.player,0) and not game.director.deliver_mote(),"inactive legacy trial rejects actions")
	_check(not game.trial_world.perform(game.player,"chimes_strike",0),"inactive third trial rejects actions")

func _test_practice_physical_admission() -> void:
	cases += 1
	await _practice_start("light")
	_check(not game.trial_world.perform(game.player,"light_pickup",0),"practice does not bypass pickup range")
	_place(game.player,Props.CELL_POSITIONS[0])
	var wall: StaticBody3D = _wall(Props.CELL_POSITIONS[0])
	await physics_frame
	await physics_frame
	_check(not game.trial_world.perform(game.player,"light_pickup",0),"practice does not bypass occlusion")
	wall.queue_free()
	await physics_frame
	await physics_frame
	_check(game.trial_world.perform(game.player,"light_pickup",0),"visible in-range cargo is admitted")
	var guide: Dictionary = EyesPracticeGuide.snapshot(game,{})
	_check(guide.guide_text.contains("Cell 1") and not guide.has("solution"),"guide reflects public cargo without hidden answers")

func _test_manual_and_focus_lifecycle() -> void:
	cases += 1
	await _practice_start("echoes")
	_place(game.player,EyesArena.STATIONS.echoes,Vector3(0,0.05,2.3))
	game._interact_player()
	_check(game.echo_open,"Echo modal opens normally")
	Input.action_press("move_forward")
	Input.action_press("interact")
	game._open_field_manual()
	_check(paused and game.ui.help_panel.visible and game.ui.pause_panel.visible,"manual from Echo pauses and retains resume screen")
	_check(not game.ui.echo_panel.visible,"Echo buttons are hidden behind pause/manual")
	_check(not Input.is_action_pressed("move_forward") and not Input.is_action_pressed("interact"),"opening manual releases held movement and interaction")
	var echo_before: int = game.director.echo_index
	game._echo_input(game.director.echo_sequence[0])
	_check(game.director.echo_index == echo_before,"paused Echo does not accept answers")
	var replay_before: float = game.echo_play_time
	game._replay_echo()
	_check(game.echo_play_time == replay_before,"paused Echo cannot restart its demonstration")
	game._resume()
	_check(paused,"cannot resume through an open manual")
	game.ui.close_field_manual()
	_check(paused and game.ui.pause_panel.visible,"closing manual remains paused")
	game._resume()
	_check(not paused and game.echo_open and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,"resume restores Echo pointer without losing the panel")
	_check(game.ui.echo_panel.visible,"explicit resume restores Echo controls")
	game._close_echo()
	Input.action_press("sprint")
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(paused and not Input.is_action_pressed("sprint"),"focus loss pauses and releases input")
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	_check(paused,"focus gain never auto-resumes")
	game._resume()
	_check(not paused and not game.ui.pause_panel.visible,"explicit resume leaves pause")
	if DisplayServer.get_name() != "headless":
		_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED,"native resume restores mouse capture")

func _test_practice_hold_pause() -> void:
	cases += 1
	await _practice_start("strings")
	var state = game.director.trial_set.third
	var rope: int = state.strings_answer()
	_place(game.player,Props.ROPE_POSITIONS[rope])
	Input.action_press("interact")
	game.trial_world.step(1.0)
	_check(not state.strings_holds.is_empty(),"practice cut uses real continuous hold")
	game._pause()
	_check(state.strings_holds.is_empty(),"pause cancels unfinished cut")
	_check(not game.trial_world.perform(game.player,"strings_read"),"paused world rejects commands")
	game._resume()
	game.trial_world.step(2.1)
	_check(state.strings_stage == 0,"resume without a fresh press cannot complete old hold")

func _test_restart_and_normal_return() -> void:
	cases += 1
	await _practice_start("vault","Tinker",12345)
	var old_director = game.director
	var old_world = game.trial_world
	var targets: Array = old_director.trial_set.vault_targets.duplicate()
	Input.action_press("move_forward")
	game._restart_practice()
	game.set_physics_process(false)
	game.player.active = false
	_check(game.seed_value == 12345 and game.player.archetype == "Tinker" and game.director.trial_set.vault_targets == targets,"retry keeps role, seed and puzzle")
	_check(not old_director.is_live() and not old_director.trial_set.live and not old_world.perform(game.player,"vault_read"),"replaced attempt has no live authority")
	_check(not Input.is_action_pressed("move_forward"),"restart releases old key state")
	game._new_practice_seed()
	_check(game.seed_value != 12345 and game.seed_value >= 1 and game.seed_value <= 999999,"new seed is valid and different")
	game._next_practice()
	_check(game.director.practice.trial_id == "ritual","next drill follows catalogue order")
	game._show_practice_catalog()
	_check(game.mode == "menu" and game.ui.practice_view.catalog_panel.visible and not paused,"return to workshop leaves no active match")
	game.start_match("survivor","Keeper","story",271126,"third")
	game.set_physics_process(false)
	game.player.active = false
	_check(not game.director.is_practice() and game.director.phase == "preparation" and not game.ui.practice_enabled,"normal match restores competitive authority and HUD")
	_check(game.director.trial_set.slot_trials == {"silent":"light","echoes":"strings","relay":"chimes"},"normal contract restores all three trials")
	for eye in game.arena.eyes:
		_check(eye.visible,"Eye presentation restored")
	old_world = null
	old_director = null

func _test_practice_completion_journal() -> void:
	cases += 1
	var ledger_before: String = FileAccess.get_sha256("user://last_observance.json") if FileAccess.file_exists("user://last_observance.json") else "missing"
	await _practice_start("relay")
	var prior: int = int(game.practice_journal.trials.relay.completions)
	_place(game.player,EyesArena.STATIONS.relay,Vector3(0,0.05,2.3))
	Input.action_press("interact")
	for unused: int in range(800):
		if game.director.phase == "ended":
			break
		game._physics_process(1.0/60.0)
	_check(game.director.practice.completed and game.director.phase == "ended","physical held relay completes practice")
	_check(game.director.seals.values().count(true) == 1 and game.director.seals.relay,"completion awards only the selected seal")
	_check(game.director.winner.is_empty() and game.director.escaped_count == 0,"practice creates neither winner nor escape")
	_check(int(game.practice_journal.trials.relay.completions) == prior+1,"completion updates separate journal once")
	_check(game.ui.practice_view.result_panel.visible and not game.ui.result_panel.visible,"practice uses its own completion screen")
	game.director.step(100.0)
	game.director.charge_relay(100.0,true)
	var completed_events: int = 0
	var results: int = 0
	for event: Dictionary in game.event_log:
		completed_events += 1 if event.kind == "practice_completed" else 0
		results += 1 if event.kind == "result" else 0
	_check(completed_events == 1 and results == 0,"practice completion emits exactly one dedicated event")
	var ledger_after: String = FileAccess.get_sha256("user://last_observance.json") if FileAccess.file_exists("user://last_observance.json") else "missing"
	_check(ledger_before == ledger_after,"practice never replaces the competitive match ledger")
