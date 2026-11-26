extends SceneTree
## Reproducible native-renderer screenshots. Requires an actual display/GPU.
## -- --capture-path=/absolute/image.png --capture-view=menu|eye|manual|echo

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var capture_path: String = ""
	var view: String = "menu"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-path="):
			capture_path = arg.get_slice("=",1)
		elif arg.begins_with("--capture-view="):
			view = arg.get_slice("=",1)
	if capture_path.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Native renderer and --capture-path are required.")
		quit(1)
		return
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	if view == "manual":
		scene.ui.help_panel.show()
	elif view == "eye":
		scene.start_match("eye","Veil","standard",271126)
	elif view == "echo":
		# A staged UI inspection, explicitly not a claimed movement playthrough.
		scene.start_match("survivor","Keeper","story",271126)
		await create_timer(8.2).timeout
		scene.player.global_position = Vector3(17,0,-10.6)
		scene._interact_player()
	elif view == "survivor":
		scene.start_match("survivor","Veil","standard",271126)
	scene.qa_capture = capture_path
	scene.qa_age = -9.0 if view == "eye" else 0.0
