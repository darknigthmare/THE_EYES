extends SceneTree
## Native-renderer presentation fixtures for v0.4, NOT playthrough evidence.
## Actors, cameras, inventory and checkpoint state are deliberately staged.
## Gameplay physics stays frozen; ordinary apparatus/UI renders the fixture.
## godot --path game --script res://tests/capture_third.gd --
##   --capture-path=/absolute/image.png --capture-view=menu|squad|light|strings|chimes|manual

const Props = preload("res://scripts/third_apparatus.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var capture_path: String = ""
	var view: String = "menu"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-path="):
			capture_path = argument.get_slice("=", 1)
		elif argument.begins_with("--capture-view="):
			view = argument.get_slice("=", 1)
	if capture_path.is_empty() or not capture_path.is_absolute_path() or DisplayServer.get_name() == "headless":
		push_error("An actual native renderer and absolute --capture-path are required.")
		quit(1)
		return
	if view not in ["menu", "squad", "light", "strings", "chimes", "manual"]:
		push_error("Unsupported Third Observance capture view.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
	root.gui_embed_subwindows = true
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.start_match("squad" if view == "squad" else "survivor", "Keeper", "story", 271126, "third")
	scene.set_physics_process(false)
	for actor: EyesSurvivor in scene.actors:
		actor.active = false
	scene.director.step(8.0)
	scene.elapsed = 0.0
	var rules = scene.director.trial_set.third
	match view:
		"menu", "manual":
			scene._return_to_menu()
			scene.ui.contract_select.select(3)
			scene.ui.contract_select.item_selected.emit(3)
			if view == "manual":
				scene.ui.help_panel.show()
				await process_frame
				await process_frame
				var scrolls: Array[Node] = scene.ui.help_panel.find_children("*", "ScrollContainer", true, false)
				if not scrolls.is_empty():
					(scrolls[0] as ScrollContainer).scroll_vertical = 430
			else:
				await process_frame
				if scene.ui.contract_select.has_method("show_popup"):
					scene.ui.contract_select.call("show_popup")
		"light":
			# One lit checkpoint and one carried, partly charged cell show both
			# the permanent refuge feedback and the actual cargo/charge HUD.
			rules.light_lit[0] = true
			rules.pickup_cell(scene.player.get_instance_id(), 1)
			rules.light_charge[scene.player.get_instance_id()] = 62.0
			scene.player.global_position = Vector3(-20, 0, -6)
			_aim(scene.player, Vector3(-21.0, 2.1, -12))
			scene.apparatus.third.show_carry(scene.player, 1)
			scene.active_hint = "CELL 2 / Recharge in the lit refuge, then align its matching lamp."
		"strings":
			scene.player.global_position = Props.STRINGS_DESK + Vector3(0, 0, 8.5)
			_aim(scene.player, Props.STRINGS_DESK + Vector3(0, 2.7, 0))
			scene.active_hint = "Read the pair and shape family. Hold E at the matching rope."
		"chimes":
			# A banked first phrase and one shared damper are staged state,
			# not a claimed sequence completed by a human route.
			rules.chimes_phrase = 1
			rules.chimes_index = 1
			rules.damper = 1
			scene.player.global_position = Props.CHIMES_DESK + Vector3(-6.0, 0, 8.7)
			_aim(scene.player, Props.CHIMES_DESK + Vector3(0, 2.7, 2.0))
			scene.active_hint = "PHRASE 1 BANKED / Walk to each bell. R dampens; E strikes."
		"squad":
			scene.player.global_position = Vector3(-1.8, 0, 23.2)
			_aim(scene.player, Vector3(-2.4, 1.4, 17.0))
			var tasks: Array[String] = ["light_pickup", "strings_observe", "chimes_damp", "light_align"]
			for index: int in range(scene.bots.size()):
				var actor: EyesSurvivor = scene.bots[index].actor
				actor.global_position = Vector3(-5.4 + index * 1.75, 0, 18.0 + (index % 2) * 0.4)
				actor.rotation.y = PI
				scene.bots[index].task = tasks[index]
			scene.active_hint = "B / WORK      F / FOLLOW      V / HOLD"
	if scene.mode != "menu":
		scene.apparatus.third.refresh(1.0)
		scene._update_hud()
	scene.ui.toast("", 0.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if scene.mode == "menu" else Input.MOUSE_MODE_CAPTURED
	print("THE_EYES_VISUAL_FIXTURE view=%s contract=third physics_frozen=true; staged inspection, not playthrough" % view)
	scene.qa_capture = capture_path
	scene.qa_age = 0.0


func _aim(actor: EyesSurvivor, target: Vector3) -> void:
	# Preserve the ordinary yaw-on-body / pitch-on-head camera relationship,
	# including carried-object placement, while staging a stationary viewpoint.
	actor.look_at(Vector3(target.x, actor.global_position.y, target.z))
	actor.head.look_at(target)
	actor.pitch = actor.head.rotation.x
