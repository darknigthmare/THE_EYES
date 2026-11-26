extends SceneTree
## v0.5 native presentation fixtures, deliberately staged, NOT playthroughs.
## The fixture freezes physics and may supply illustrative notebook entries.
## --capture-path=/absolute/image.png --capture-view=menu|workshop|practice|practice_clear|manual|result|save_error|result_save_error

const Practice = preload("res://scripts/practice_state.gd")
const Guide = preload("res://scripts/practice_guide.gd")
const Props = preload("res://scripts/third_apparatus.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var capture_path: String = ""
	var view: String = "workshop"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-path="):
			capture_path = argument.get_slice("=",1)
		elif argument.begins_with("--capture-view="):
			view = argument.get_slice("=",1)
	if capture_path.is_empty() or not capture_path.is_absolute_path() or DisplayServer.get_name() == "headless" or view not in ["menu","workshop","practice","practice_clear","manual","result","save_error","result_save_error"]:
		push_error("Workshop capture requires a native renderer, absolute path and supported view.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
	root.gui_embed_subwindows = true
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.qa_capture = "fixture-only"
	scene.qa_done = true
	scene.start_practice("strings","Keeper",271126)
	scene.soundscape.set_enabled(false)
	scene.set_physics_process(false)
	scene.process_mode = Node.PROCESS_MODE_ALWAYS
	scene.player.active = false
	scene.player.global_position = Props.STRINGS_DESK+Vector3(0,0,8.5)
	var target: Vector3 = Props.STRINGS_DESK+Vector3(0,2.7,0)
	scene.player.look_at(Vector3(target.x,scene.player.global_position.y,target.z))
	scene.player.head.look_at(target)
	scene.player.pitch = scene.player.head.rotation.x
	scene.director.practice.elapsed = 47.5
	scene.active_hint = "Read the pair and shape family. Hold E at the matching rope."
	scene._update_hud()
	match view:
		"menu":
			scene._return_to_menu()
		"workshop","save_error":
			scene._show_practice_catalog()
			if view == "save_error":
				var journal: Dictionary = scene.practice_journal.duplicate(true)
				journal["_storage_error"] = "A newer notebook schema was found. It has been preserved; these attempts stay in memory only."
				scene.ui.show_practice_catalog(Practice.catalogue(),journal,"Keeper",271126)
		"manual":
			scene._open_field_manual()
			# Keep this presentation-only fixture rendering while scene gameplay
			# is frozen; the real pause boundary is covered by world/UI tests.
			scene.process_mode = Node.PROCESS_MODE_ALWAYS
		"result","result_save_error":
			scene.director.practice.completed = true
			scene.director.practice.active = false
			scene.director.phase = "ended"
			scene.director.seals.echoes = true
			scene.director.trial_set.third.strings_stage = 3
			scene.practice_records.complete_attempt(47.5)
			scene.practice_journal = scene.practice_records.snapshot()
			if view == "result_save_error":
				scene.practice_journal["_storage_error"] = "The notebook could not be saved. Your completion is available for this session only."
			scene.ui.show_practice_result(Guide.snapshot(scene,scene.practice_journal))
		"practice_clear":
			scene.ui.set_practice_guide_collapsed(true)
		"practice":
			pass
	scene.ui.toast("",0.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if view in ["menu","workshop","manual","result","save_error","result_save_error"] else Input.MOUSE_MODE_CAPTURED
	print("THE_EYES_VISUAL_FIXTURE view=%s contract=practice physics_frozen=true; staged inspection, not playthrough" % view)
	scene.qa_capture = capture_path
	scene.qa_done = false
	scene.qa_age = 0.0
