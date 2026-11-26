extends SceneTree
## Reproducible native-renderer screenshots. Requires an actual display/GPU.
## -- --capture-path=/absolute/image.png --capture-view=menu|eye|manual|echo|contracts|vault|ritual|clock|eye_second

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
	if view == "contracts":
		scene.ui.contract_select.select(1)
		scene.ui.contract_select.item_selected.emit(1)
	elif view == "manual":
		scene.ui.help_panel.show()
	elif view == "eye_second":
		scene.start_match("eye","Veil","standard",271126,"second")
	elif view in ["squad","rescue","spectator"]:
		# Explicit presentation fixtures, not completion/playthrough evidence.
		scene.start_match("squad","Keeper","story",271126,"second")
		if view == "squad":
			scene.player.global_position = Vector3(-5,0,21)
			scene.player.rotation.y = -0.35
		else:
			scene.set_physics_process(false)
			for actor: EyesSurvivor in scene.actors:
				actor.active = false
			scene.director.step(8.0)
			if view == "rescue":
				var victim: EyesSurvivor = scene.bots[0].actor
				victim.global_position = Vector3(-0.75,0,18.8)
				scene.player.global_position = Vector3(-0.75,0,20.5)
				for index in range(1,4):
					scene.bots[index].actor.global_position = Vector3(-6+index*4,0,16.5)
				victim.respawn_shield = 0.0
				scene._hurt(victim,100.0,"Presentation fixture")
				victim.body_mesh.scale.y = 0.35
				scene.player.head.look_at(victim.target_point())
				scene.squad_world._hold_rescue(scene.player,victim,3.0)
				scene._update_player_objectives(0.0,false)
			else:
				scene.player.respawn_shield = 0.0
				scene._hurt(scene.player,100.0,"Presentation fixture")
				scene.squad_world.state.step(35.0)
				scene._switch_spectator(1)
	elif view in ["vault","ritual","clock"]:
		# Staged presentation only. Full movement completion is tested separately.
		scene.start_match("survivor","Keeper","story",271126,"second")
		var positions = {"vault":Vector3(-17,0,-6.5),"ritual":Vector3(17,0,-6.0),"clock":Vector3(0,0,22)}
		scene.player.global_position = positions[view]
		scene.player.rotation.y = 0.0
		scene.player.pitch = 0.16
		scene.player.head.rotation.x = 0.16
		if view == "vault":
			scene.apparatus.show_vault_reference()
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
