extends Node3D
## The playable local slice. TrialDirector owns match authority; this scene
## verifies world interactions, simulates physical actors and presents feedback.

var arena: EyesArena
var apparatus: EyesTrialApparatus
var trial_world: EyesTrialWorld
var contract: String = "first"
var qa_contract: String = "first"
var ui: EyesInterface
var soundscape: EyesSoundscape
var director: TrialDirector
var player: EyesSurvivor
var actors: Array[EyesSurvivor] = []
var bots: Array[Dictionary] = []
var eye_camera: Camera3D
var menu_camera: Camera3D
var mode: String = "menu"
var seed_value: int = 271126
var elapsed: float = 0.0
var menu_elapsed: float = 0.0
var eye_forward: Vector3 = Vector3.FORWARD
var eye_yaw: float = 0.0
var eye_pitch: float = -0.25
var eye_switch_left: float = 0.0
var ai_decision_left: float = 0.0
var last_noise: Vector3 = Vector3.ZERO
var noise_memory: float = 0.0
var last_seen: Vector3 = Vector3.ZERO
var sight_memory: float = 0.0
var socket_warning_left: float = 0.0
var mote_notice_left: float = 0.0
var traps: Array[Dictionary] = []
var shadows: Array[Dictionary] = []
var motes_state: Array[int] = [0,0,0]
var echo_open: bool = false
var echo_showing: bool = false
var echo_play_time: float = 0.0
var echo_last_step: int = -1
var escape_hold: float = 0.0
var navigation: AStarGrid2D
var punishment: bool = false
var punishment_used: bool = false
var punishment_left: float = 25.0
var punishment_hits: int = 0
var punishment_beat: float = 0.0
var punishment_room: Node3D
var punishment_ring: MeshInstance3D
var active_hint: String = ""
var marked_until: Dictionary = {}
var metrics: Dictionary = {}
var event_log: Array[Dictionary] = []
var qa_capture: String = ""
var qa_view: String = "menu"
var qa_age: float = 0.0
var qa_done: bool = false
var mute_requested: bool = false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_register_input()
	_build_navigation()
	arena = EyesArena.new()
	add_child(arena)
	apparatus = EyesTrialApparatus.new()
	add_child(apparatus)
	soundscape = EyesSoundscape.new()
	add_child(soundscape)
	menu_camera = Camera3D.new()
	menu_camera.position = Vector3(-13,5.8,19)
	menu_camera.fov = 68
	menu_camera.far = 200
	add_child(menu_camera)
	menu_camera.look_at(Vector3(3,6,-16))
	menu_camera.current = true
	eye_camera = Camera3D.new()
	eye_camera.fov = 85
	eye_camera.near = 0.1
	eye_camera.far = 180
	add_child(eye_camera)
	player = EyesSurvivor.new()
	add_child(player)
	player.active = false
	player.visible = false
	ui = EyesInterface.new()
	add_child(ui)
	ui.start_requested.connect(start_match)
	ui.resume_requested.connect(_resume)
	ui.menu_requested.connect(_return_to_menu)
	ui.echo_pressed.connect(_echo_input)
	ui.echo_replay_requested.connect(_replay_echo)
	ui.echo_close_requested.connect(_close_echo)
	ui.settings_changed.connect(_apply_settings)
	_load_settings()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-capture="):
			qa_capture = arg.get_slice("=",1)
		elif arg.begins_with("--qa-view="):
			qa_view = arg.get_slice("=",1)
		elif arg.begins_with("--contract="):
			qa_contract = arg.get_slice("=",1)
		elif arg == "--mute":
			mute_requested = true
	if mute_requested:
		soundscape.set_enabled(false)
	if qa_view != "menu":
		start_match(qa_view,"Veil","standard",271126,qa_contract)
		print("THE_EYES_QA_READY role=%s contract=%s" % [mode,contract])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if mode == "menu" else Input.MOUSE_MODE_CAPTURED

func _register_input() -> void:
	var keys: Dictionary = {"move_forward":[KEY_W,KEY_UP],"move_back":[KEY_S,KEY_DOWN],"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"sprint":[KEY_SHIFT],"crouch":[KEY_CTRL,KEY_C],"jump":[KEY_SPACE],"interact":[KEY_E],"ability":[KEY_Q],"map":[KEY_TAB],"pause":[KEY_ESCAPE],"drop":[KEY_G],"reverse":[KEY_R],"reset_trial":[KEY_X]}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in keys[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)

func _build_navigation() -> void:
	navigation = AStarGrid2D.new()
	navigation.region = Rect2i(-25,-22,51,45)
	navigation.cell_size = Vector2.ONE
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.update()
	_block_rect(Vector2.ZERO,Vector2(6.1,6.1))
	for x in [-9,9]:
		for z in [-6.5,6.5]:
			_block_rect(Vector2(x,z),Vector2(8.6,2.0))
	for p in [Vector2(-18,-3),Vector2(18,-3),Vector2(-7,17),Vector2(7,17),Vector2(-7,-17),Vector2(7,-17)]:
		_block_rect(p,Vector2(3.4,2.2))
	for key in EyesArena.STATIONS:
		var p: Vector3 = EyesArena.STATIONS[key]
		_block_rect(Vector2(p.x,p.z),Vector2(2.0,2.0))

func _block_rect(center: Vector2, size_value: Vector2) -> void:
	for x in range(int(floor(center.x-size_value.x/2)),int(ceil(center.x+size_value.x/2))+1):
		for z in range(int(floor(center.y-size_value.y/2)),int(ceil(center.y+size_value.y/2))+1):
			if navigation.is_in_boundsv(Vector2i(x,z)):
				navigation.set_point_solid(Vector2i(x,z))

func start_match(requested_mode: String, archetype: String, difficulty: String, match_seed: int, selected_contract: String = "first") -> void:
	get_tree().paused = false
	_cleanup_match()
	mode = requested_mode
	seed_value = match_seed
	elapsed = 0.0
	metrics = {"wounds":0,"traps_triggered":0,"shadows_called":0,"times_seen":0,"distance":0.0,"punishments_survived":0}
	event_log.clear()
	motes_state.assign([0,0,0])
	for i in range(3):
		arena.motes[i].get_parent().position = EyesArena.MOTE_POSITIONS[i]
		arena.motes[i].visible = true
	for key in EyesArena.STATIONS:
		arena.set_seal(key,false)
	arena.open_exit(false)
	arena.show_echo(-1)
	for i in range(EyesArena.TRAP_POSITIONS.size()):
		traps.append({"state":"idle","left":0.0,"hit":[]})
		arena.set_trap(i,"idle")
	director = TrialDirector.new()
	director.event_raised.connect(_on_event)
	director.configure(mode,difficulty,match_seed,4 if mode == "eye" else 1,selected_contract)
	contract = director.trial_set.contract
	arena.configure_trials(director.trial_set.slot_trials,EyesTrialApparatus.TRIAL_NAMES)
	apparatus.configure(arena,director.trial_set)
	trial_world = EyesTrialWorld.new()
	trial_world.configure(self,director.trial_set,apparatus)
	punishment = false
	punishment_used = false
	echo_open = false
	escape_hold = 0.0
	eye_switch_left = 5.0
	ai_decision_left = 2.5
	noise_memory = 0.0
	sight_memory = 0.0
	marked_until.clear()
	if mode == "survivor":
		player.reset_body(EyesArena.SPAWN,archetype,false)
		actors.append(player)
		if not player.footstep.is_connected(_player_step):
			player.footstep.connect(_player_step)
	else:
		player.active = false
		player.visible = false
		var roles = ["Veil","Tinker","Runner","Keeper"]
		for i in range(4):
			var bot = EyesSurvivor.new()
			add_child(bot)
			bot.reset_body(Vector3(-3+i*2,0.1,20),roles[i],true)
			actors.append(bot)
			bots.append({"actor":bot,"task":"","target":Vector3.ZERO,"path":PackedVector2Array(),"path_index":0,"repath":0.0,"think":0.0,"action_time":0.0,"hiding":0.0,"mote":-1})
			eye_camera.current = true
	_set_socket(0,true)
	_apply_settings(ui.settings,false)
	ui.show_game(mode == "eye")
	ui.set_trial_names(director.trial_set.slot_trials,contract)
	ui.toast("Eight seconds of grace. Learn the chamber.",6.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _cleanup_match() -> void:
	for a in actors:
		if is_instance_valid(a) and a != player:
			a.queue_free()
	actors.clear()
	bots.clear()
	traps.clear()
	for s in shadows:
		if is_instance_valid(s.node):
			s.node.queue_free()
	shadows.clear()
	if is_instance_valid(punishment_room):
		punishment_room.queue_free()
		punishment_room = null
	player.active = false
	player.visible = false

func _return_to_menu() -> void:
	get_tree().paused = false
	mode = "menu"
	_cleanup_match()
	ui.show_menu()
	menu_camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _resume() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if mode == "menu" or echo_open else Input.MOUSE_MODE_CAPTURED

func _pause() -> void:
	get_tree().paused = true
	ui.pause_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if mode == "menu" or director == null or director.phase == "ended":
		return
	if event.is_action_pressed("pause"):
		if echo_open:
			_close_echo()
		else:
			_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("map"):
		ui.minimap.visible = not ui.minimap.visible
		get_viewport().set_input_as_handled()
	if mode == "eye":
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			eye_yaw -= event.relative.x*0.0022*ui.settings.sensitivity
			eye_pitch = clampf(eye_pitch-event.relative.y*0.0022*ui.settings.sensitivity*(-1 if ui.settings.invert_y else 1),-1.4,0.35)
			_update_eye_rotation()
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
				_set_socket(event.physical_keycode-KEY_1)
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_set_socket((director.eye_socket+1)%4)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_set_socket((director.eye_socket+3)%4)
			elif event.button_index == MOUSE_BUTTON_LEFT:
				_eye_trap_input()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_eye_mark_input()
		if event.is_action_pressed("ability"):
			_eye_summon_input()
	elif mode == "survivor":
		if punishment:
			if event.is_action_pressed("interact"):
				_punishment_input()
			return
		if echo_open:
			if event is InputEventKey and event.pressed and not event.echo:
				if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
					_echo_input(event.physical_keycode-KEY_1)
				elif event.physical_keycode == KEY_R:
					_replay_echo()
				elif event.physical_keycode == KEY_E:
					_close_echo()
			return
		if event.is_action_pressed("drop"):
			trial_world.release(player)
			ui.toast("Hands free. Dropped relics return safely to their shelves.",3)
		elif event.is_action_pressed("reverse"):
			trial_world.interact(player,-1)
		elif event.is_action_pressed("reset_trial"):
			trial_world.interact(player,1,true)
		if event.is_action_pressed("interact"):
			_interact_player()
		if event.is_action_pressed("ability") and player.use_ability():
			ui.toast({"Veil":"Quiet Step — your presence fades.","Tinker":"Overclock — the mechanism answers.","Runner":"Second Wind — keep moving.","Keeper":"Mend — thirty vitality restored."}[player.archetype],3)
			soundscape.play("pickup",0.8)

func _physics_process(delta: float) -> void:
	if mode == "menu" or director == null or director.phase == "ended" or get_tree().paused:
		return
	elapsed += delta
	director.step(delta)
	if director.phase == "ended":
		return
	noise_memory = maxf(0.0,noise_memory-delta)
	sight_memory = maxf(0.0,sight_memory-delta)
	socket_warning_left = maxf(0.0,socket_warning_left-delta)
	mote_notice_left = maxf(0.0,mote_notice_left-delta)
	if mode == "survivor":
		_update_eye_ai(delta)
	_update_gaze(delta)
	_update_traps(delta)
	_update_shadows(delta)
	if director.phase == "ended":
		return
	if punishment:
		_update_punishment(delta)
	elif mode == "survivor":
		_update_player_objectives(delta)
	else:
		_update_bots(delta)
	trial_world.step(delta)
	if echo_open:
		_update_echo(delta)
	if mode == "survivor":
		metrics.distance += Vector2(player.velocity.x,player.velocity.z).length()*delta
	arena.eyes[director.eye_socket].look_at(EyesArena.SOCKETS[director.eye_socket]+eye_forward*15.0)

func _process(delta: float) -> void:
	if mode == "menu":
		menu_elapsed += delta
		menu_camera.position = Vector3(-13+sin(menu_elapsed*0.10)*1.2,5.8,19)
		menu_camera.look_at(Vector3(3,6,-16))
	elif director != null:
		_update_hud()
	if not qa_capture.is_empty() and not qa_done:
		qa_age += delta
		if qa_age > 2.5:
			qa_done = true
			_capture.call_deferred()

func _capture() -> void:
	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	var result = image.save_png(qa_capture)
	print("QA_CAPTURE ",qa_capture," result=",result)
	soundscape.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if result == OK else 1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_shutdown.call_deferred()

func _shutdown() -> void:
	get_tree().paused = false
	soundscape.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()

func _set_socket(index: int, initial: bool = false) -> bool:
	if not initial and not director.switch_socket(index):
		if mode == "eye":
			ui.toast("Blink needs 8 energy and a ready cooldown.",2.0)
		return false
	director.eye_socket = index
	var target = Vector3(0,1,0)-EyesArena.SOCKETS[index]
	eye_yaw = atan2(-target.x,-target.z)
	eye_pitch = atan2(target.y,Vector2(target.x,target.z).length())
	_update_eye_rotation()
	arena.set_socket(index)
	if not initial:
		socket_warning_left = 0.85
		soundscape.play("blink",1,-15)
		ui.toast("The Eye opens at the %s socket." % ["north","east","south","west"][index],2.5)
	return true

func _update_eye_rotation() -> void:
	eye_camera.rotation = Vector3(eye_pitch,eye_yaw,0)
	eye_forward = -eye_camera.transform.basis.z
	eye_camera.position = EyesArena.SOCKETS[director.eye_socket]+eye_forward*2.8

func eye_origin() -> Vector3:
	return EyesArena.SOCKETS[director.eye_socket]+eye_forward*2.65

func has_sight(origin: Vector3, target: Vector3) -> bool:
	var query = PhysicsRayQueryParameters3D.create(origin,target,1)
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func eye_sees(point: Vector3, check_cone: bool = true) -> bool:
	var direction = point-eye_origin()
	if direction.length() > 62.0 or direction.length() < 0.1:
		return false
	if check_cone and eye_forward.dot(direction.normalized()) < cos(deg_to_rad(43.0)):
		return false
	return has_sight(eye_origin(),point)

func _update_eye_ai(delta: float) -> void:
	if punishment or director.phase == "preparation":
		return
	var visible_player = eye_sees(player.target_point()) and not player.eliminated
	if visible_player:
		last_seen = player.target_point()
		sight_memory = 3.0
	var look_target = Vector3(sin(elapsed*0.27)*18,1.0,cos(elapsed*0.21)*17)
	if sight_memory > 0:
		look_target = last_seen
	elif noise_memory > 0:
		look_target = last_noise
	var desired = (look_target-EyesArena.SOCKETS[director.eye_socket]).normalized()
	var tracking_speed: float = 0.65 if director.difficulty == "story" else 1.15
	eye_forward = eye_forward.slerp(desired,minf(1.0,delta*tracking_speed)).normalized()
	eye_camera.position = EyesArena.SOCKETS[director.eye_socket]+eye_forward*2.8
	eye_camera.look_at(eye_camera.position+eye_forward)
	eye_switch_left -= delta
	if eye_switch_left <= 0:
		eye_switch_left = 10.0 if director.difficulty == "story" else 6.0
		var next_socket: int = (director.eye_socket+1)%4
		if noise_memory > 0 or sight_memory > 0:
			var remembered = last_seen if sight_memory > 0 else last_noise
			var best_distance: float = INF
			for i in range(4):
				if i == director.eye_socket:
					continue
				if has_sight(EyesArena.SOCKETS[i],remembered) and EyesArena.SOCKETS[i].distance_to(remembered) < best_distance:
					best_distance = EyesArena.SOCKETS[i].distance_to(remembered)
					next_socket = i
		_set_socket(next_socket)
	ai_decision_left -= delta
	if ai_decision_left > 0 or not visible_player:
		return
	ai_decision_left = 3.0 if director.difficulty == "story" else 1.45
	for i in range(EyesArena.TRAP_POSITIONS.size()):
		if player.global_position.distance_to(EyesArena.TRAP_POSITIONS[i]) < 3.3 and traps[i].state == "idle":
			if _activate_trap(i):
				return
	var mark_threshold: float = 60.0 if director.difficulty == "story" else 30.0
	if player.gaze > mark_threshold and not marked_until.has(player.get_instance_id()):
		if _mark(player):
			return
	if elapsed > 28 and shadows.size() < 2 and director.can_use("summon"):
		var spawn_point = player.global_position+Vector3(sin(elapsed)*4.5,0,cos(elapsed)*4.5)
		_summon(spawn_point)

func _update_gaze(delta: float) -> void:
	if director.phase == "preparation" or socket_warning_left > 0:
		return
	for a in actors:
		if a.eliminated or (a == player and punishment):
			continue
		var seen = eye_sees(a.target_point()) and a.respawn_shield <= 0
		var gain = {"story":8.0,"standard":20.0,"ruthless":27.0}[director.difficulty]
		if a.crouching:
			gain *= 0.6
		if a.archetype == "Veil" and a.ability_left > 0:
			gain *= 0.25
		var id = a.get_instance_id()
		if marked_until.has(id):
			if elapsed > marked_until[id]:
				marked_until.erase(id)
			else:
				gain *= 1.25 if director.difficulty == "story" else 1.7
		if seen:
			if a.gaze <= 0.1:
				metrics.times_seen += 1
			a.gaze = minf(100.0,a.gaze+gain*delta)
		else:
			a.gaze = maxf(0.0,a.gaze-27.0*delta)
		if a.gaze >= 100.0:
			a.gaze = 35.0
			_hurt(a,{"story":22.0,"standard":30.0,"ruthless":40.0}[director.difficulty],"The gaze found you. Break line of sight.")

func _player_step(loudness: float) -> void:
	if mode != "survivor" or punishment:
		return
	soundscape.play("step",0.92+sin(elapsed)*0.08,-30.0+loudness*9.0)
	if loudness > 0.35:
		last_noise = player.target_point()+Vector3(sin(elapsed)*1.2,0,cos(elapsed)*1.2)
		noise_memory = 4.0
	if player.carrying >= 0 and loudness > 0.7:
		# Noise gives the AI a temporary location clue, never damage through walls.
		last_noise = player.target_point()+Vector3(sin(elapsed),0,cos(elapsed))
		noise_memory = 6.0
		if mote_notice_left <= 0:
			mote_notice_left = 5.0
			ui.toast("The whisper mote rings when you sprint.",1.8)

func _activate_trap(index: int) -> bool:
	if index < 0 or index >= traps.size() or traps[index].state != "idle":
		return false
	if not director.try_use("trap",eye_sees(EyesArena.TRAP_POSITIONS[index]+Vector3.UP*0.18)):
		return false
	traps[index] = {"state":"warning","left":1.5,"hit":[]}
	arena.set_trap(index,"warning")
	metrics.traps_triggered += 1
	soundscape.play("warning",1.0,-13)
	return true

func _update_traps(delta: float) -> void:
	for i in range(traps.size()):
		var t: Dictionary = traps[i]
		if t.state == "idle":
			continue
		t.left -= delta
		if t.state == "warning" and t.left <= 0:
			t.state = "active"
			t.left = 1.2
			arena.set_trap(i,"active")
		elif t.state == "active":
			for a in actors:
				if a.eliminated or t.hit.has(a.get_instance_id()):
					continue
				var offset = a.global_position-EyesArena.TRAP_POSITIONS[i]
				if Vector2(offset.x,offset.z).length() < 1.85 and a.global_position.y < 1.25:
					_hurt(a,35.0,"The floor was marked. Leave the warning ring.")
					t.hit.append(a.get_instance_id())
			if t.left <= 0:
				t.state = "cooling"
				t.left = 3.0
				arena.set_trap(i,"idle")
		elif t.state == "cooling" and t.left <= 0:
			t.state = "idle"

func _aimed_trap() -> int:
	var result = -1
	var best: float = 0.975
	for i in range(EyesArena.TRAP_POSITIONS.size()):
		var p = EyesArena.TRAP_POSITIONS[i]+Vector3.UP*0.2
		var alignment = eye_forward.dot((p-eye_origin()).normalized())
		if alignment > best and eye_sees(p):
			best = alignment
			result = i
	return result

func _aimed_actor() -> EyesSurvivor:
	var result: EyesSurvivor = null
	var best: float = 0.975
	for a in actors:
		if a.eliminated:
			continue
		var alignment = eye_forward.dot((a.target_point()-eye_origin()).normalized())
		if alignment > best and eye_sees(a.target_point()):
			best = alignment
			result = a
	return result

func _eye_trap_input() -> void:
	var index = _aimed_trap()
	if index < 0:
		ui.toast("Aim at a visible brass floor trap.",2.0)
	elif not _activate_trap(index):
		ui.toast("Trap unavailable: wait for its cooldown or energy.",2.0)

func _eye_mark_input() -> void:
	var target = _aimed_actor()
	if target == null:
		ui.toast("Focus a visible survivor to mark them.",2)
	elif not _mark(target):
		ui.toast("Mark needs 20 energy and a ready cooldown.",2)

func _mark(actor: EyesSurvivor) -> bool:
	if actor.eliminated or not director.try_use("mark",eye_sees(actor.target_point())):
		return false
	marked_until[actor.get_instance_id()] = elapsed+6.0
	soundscape.play("warning",0.72,-14)
	if actor == player:
		ui.toast("MARKED — the gaze grows faster. Find cover.",4)
	return true

func _eye_summon_input() -> void:
	var query = PhysicsRayQueryParameters3D.create(eye_camera.global_position,eye_camera.global_position+eye_forward*62.0,1)
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.y < 0.8:
		ui.toast("Aim at an open floor area to call a shadow.",2.5)
		return
	if not _summon(hit.position):
		ui.toast("Need 45 energy, open ground and 3 m from survivors.",2.5)

func _summon(point: Vector3) -> bool:
	if shadows.size() >= 2 or absf(point.x) > 24 or absf(point.z) > 21 or point.y > 0.3:
		return false
	var cell = Vector2i(roundi(point.x),roundi(point.z))
	if not navigation.is_in_boundsv(cell) or navigation.is_point_solid(cell):
		return false
	for a in actors:
		if not a.eliminated and a.global_position.distance_to(point) < 3.0:
			return false
	if not director.try_use("summon",eye_sees(point+Vector3.UP*0.25)):
		return false
	var node = CharacterBody3D.new()
	node.collision_layer = 0
	node.collision_mask = 1
	node.position = Vector3(point.x,0.1,point.z)
	var col = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	col.shape = capsule
	col.position.y = 0.9
	node.add_child(col)
	add_child(node)
	var mesh = arena.cylinder(Vector3(0,0.9,0),0.38,1.6,arena.mats.dark,node)
	(mesh.mesh as CylinderMesh).top_radius = 0.15
	arena.sphere(Vector3(0,1.85,0),0.24,arena.mats.black,node)
	arena.sphere(Vector3(-0.08,1.9,-0.22),0.045,arena.mats.red,node)
	arena.sphere(Vector3(0.08,1.9,-0.22),0.045,arena.mats.red,node)
	arena.ring(Vector3(0,0.05,0),0.65,0.74,arena.mats.red,node)
	shadows.append({"node":node,"warmup":2.0,"life":20.0,"path":PackedVector2Array(),"index":0,"think":0.0,"target":point})
	metrics.shadows_called += 1
	soundscape.play("warning",0.6,-12)
	return true

func _update_shadows(delta: float) -> void:
	for i in range(shadows.size()-1,-1,-1):
		var s: Dictionary = shadows[i]
		s.life -= delta
		if s.life <= 0:
			s.node.queue_free()
			shadows.remove_at(i)
			continue
		s.warmup -= delta
		if s.warmup > 0:
			continue
		s.think -= delta
		if s.think <= 0:
			s.think = 0.6
			var nearest: float = 14.0
			for a in actors:
				if a.eliminated or (a == player and punishment):
					continue
				var distance = a.global_position.distance_to(s.node.global_position)
				if distance < nearest and has_sight(s.node.global_position+Vector3.UP,a.target_point()):
					nearest = distance
					s.target = a.global_position
			s.path = _path(s.node.global_position,s.target)
			s.index = 0
		var desired = _path_direction(s.node.global_position,s)
		s.node.velocity = desired*3.15+Vector3(0,-2,0)
		s.node.move_and_slide()
		if desired.length() > 0.1:
			s.node.rotation.y = atan2(-desired.x,-desired.z)
		for a in actors:
			if not a.eliminated and a.global_position.distance_to(s.node.global_position) < 1.0:
				_hurt(a,25.0,"A shadow reached you. Break its sight and keep moving.")

func _hurt(actor: EyesSurvivor, amount: float, reason: String) -> void:
	if director.phase == "ended" or not actor.damage(amount):
		return
	metrics.wounds += 1
	soundscape.play("fail",0.75,-10)
	if actor == player:
		ui.toast(reason,3)
	if actor.health <= 0:
		trial_world.release(actor)
		if actor == player and not punishment_used:
			_start_punishment()
		else:
			actor.eliminated = true
			actor.active = false
			actor.visible = false
			director.register_elimination()
			if mode == "eye":
				ui.toast("%s has fallen. %d remain." % [actor.params.name,director.alive_count],3)

func _mote_position(index: int) -> Vector3:
	return arena.motes[index].get_parent().global_position

func _pickup(actor: EyesSurvivor, index: int) -> bool:
	if director == null or director.phase not in ["hunt","escape"] or actor.eliminated or index < 0 or index >= 3 or director.trial_for_slot("silent") != "silent" or trial_world.has_cargo(actor):
		return false
	if actor.carrying >= 0 or motes_state[index] != 0 or actor.global_position.distance_to(_mote_position(index)) > 2.8:
		return false
	actor.carrying = index
	motes_state[index] = 1
	arena.motes[index].hide()
	soundscape.play("pickup",1.15,-12)
	return true

func _deliver(actor: EyesSurvivor) -> bool:
	if actor.carrying < 0 or actor.global_position.distance_to(EyesArena.STATIONS.silent) > 3.0:
		return false
	if not director.deliver_mote():
		return false
	motes_state[actor.carrying] = 2
	actor.carrying = -1
	return true

func _drop_mote(actor: EyesSurvivor) -> void:
	if actor.carrying < 0:
		return
	var index = actor.carrying
	actor.carrying = -1
	motes_state[index] = 0
	arena.motes[index].get_parent().global_position = Vector3(clampf(actor.global_position.x,-24,24),0,clampf(actor.global_position.z,-21,21))
	arena.motes[index].show()

func _interact_player() -> void:
	if director.phase == "preparation":
		ui.toast("The trials awaken when the grace ends.",2)
		return
	if trial_world.interact(player):
		return
	for i in range(3):
		if _pickup(player,i):
			ui.toast("Whisper collected. Deliver it to Silent Countdown.",3)
			return
	if _deliver(player):
		return
	if director.trial_for_slot("echoes") == "echoes" and player.global_position.distance_to(EyesArena.STATIONS.echoes) < 3.0 and not director.seals.echoes:
		echo_open = true
		ui.echo_panel.show()
		player.controls_locked = true
		player.velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_replay_echo()

func _update_player_objectives(delta: float) -> void:
	active_hint = ""
	if director.phase == "preparation":
		active_hint = "PREPARATION  /  Find cover and plan your route."
		return
	var holding_relay = false
	if not echo_open:
		for i in range(3):
			if director.trial_for_slot("silent") == "silent" and motes_state[i] == 0 and player.carrying < 0 and not trial_world.has_cargo(player) and player.global_position.distance_to(_mote_position(i)) < 2.8:
				active_hint = "[ E ]  Pick up whisper mote"
		if director.trial_for_slot("silent") == "silent" and player.global_position.distance_to(EyesArena.STATIONS.silent) < 3.0:
			active_hint = "[ E ]  Deliver whisper mote" if player.carrying >= 0 else "SILENT COUNTDOWN  /  %d of 3 whispers delivered" % director.motes_delivered
		if director.trial_for_slot("echoes") == "echoes" and player.global_position.distance_to(EyesArena.STATIONS.echoes) < 3.0:
			active_hint = "ECHOES  /  Seal broken" if director.seals.echoes else "[ E ]  Observe and repeat the four symbols"
		if director.trial_for_slot("relay") == "relay" and player.global_position.distance_to(EyesArena.STATIONS.relay) < 3.0:
			active_hint = "RELAY  /  Seal broken" if director.seals.relay else "[ HOLD E ]  Charge the wheel  /  %d%%" % int(director.relay_progress*100)
			holding_relay = Input.is_action_pressed("interact") and not director.seals.relay
		if player.global_position.distance_to(EyesArena.EXIT_POSITION) < 3.2:
			if director.phase == "escape":
				active_hint = "[ HOLD E ]  Leave the observance  /  %d%%" % int(escape_hold/1.5*100)
				if Input.is_action_pressed("interact"):
					escape_hold += delta
					if escape_hold >= 1.5:
						director.register_escape()
				else:
					escape_hold = 0.0
			else:
				active_hint = "THE UNSEEN DOOR  /  Three seals keep it closed."
		else:
			escape_hold = 0.0
	var extended_hint = trial_world.hint(player)
	if not extended_hint.is_empty() and not echo_open:
		active_hint = extended_hint
	var rate: float = 1.4 if player.archetype == "Tinker" else 1.0
	if player.archetype == "Tinker" and player.ability_left > 0:
		rate *= 1.6
	director.charge_relay(delta*(rate if holding_relay else 1.0),holding_relay)
	if holding_relay:
		arena.relay_wheel.rotation.z += delta*2.0

func _replay_echo() -> void:
	if not echo_open or director.seals.echoes:
		return
	echo_showing = true
	echo_play_time = -0.65
	echo_last_step = -1
	ui.show_echo_step(-1,"Watch the sequence. The Eye is still watching you.",false)

func _update_echo(delta: float) -> void:
	if not echo_showing:
		return
	echo_play_time += delta
	var index = int(floor(echo_play_time/0.9))
	if index < 0:
		return
	if index >= 4:
		echo_showing = false
		arena.show_echo(-1)
		ui.show_echo_step(-1,"Repeat with 1–4. R replays. E steps away.",true)
		return
	var lit = fmod(echo_play_time,0.9) < 0.67
	var symbol: int = director.echo_sequence[index] if lit else -1
	ui.show_echo_step(symbol,"OBSERVE  %d / 4" % (index+1),false)
	arena.show_echo(symbol)
	if index != echo_last_step:
		echo_last_step = index
		soundscape.play("echo",1.0+director.echo_sequence[index]*0.16,-12)

func _echo_input(symbol: int) -> void:
	if not echo_open or echo_showing or director.phase == "ended":
		return
	var correct = director.input_echo(symbol)
	if director.seals.echoes:
		_close_echo()
	elif correct:
		ui.show_echo_step(symbol,"Correct  %d / 4" % director.echo_index,true)
		soundscape.play("echo",1.0+symbol*0.16,-12)
	else:
		ui.show_echo_step(-1,"Wrong symbol. Start again, or press R to replay.",true)
		player.gaze = minf(90.0,player.gaze+18.0)
		soundscape.play("fail",1,-14)

func _close_echo() -> void:
	echo_open = false
	echo_showing = false
	ui.echo_panel.hide()
	arena.show_echo(-1)
	player.controls_locked = false
	player.active = mode == "survivor" and director.phase != "ended"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _nearest_cell(at: Vector3) -> Vector2i:
	var center = Vector2i(clampi(roundi(at.x),-25,25),clampi(roundi(at.z),-22,22))
	if not navigation.is_point_solid(center):
		return center
	for radius in range(1,8):
		for x in range(-radius,radius+1):
			for y in range(-radius,radius+1):
				var c = center+Vector2i(x,y)
				if navigation.is_in_boundsv(c) and not navigation.is_point_solid(c):
					return c
	return Vector2i(0,20)

func _path(from: Vector3, to: Vector3) -> PackedVector2Array:
	return navigation.get_point_path(_nearest_cell(from),_nearest_cell(to))

func _path_direction(at: Vector3, data: Dictionary) -> Vector3:
	var path: PackedVector2Array = data.path
	var key: String = "index" if data.has("index") else "path_index"
	while data[key] < path.size():
		var p: Vector2 = path[data[key]]
		var direction = Vector3(p.x,at.y,p.y)-at
		if direction.length() < 0.5:
			data[key] += 1
		else:
			return direction.normalized()
	# Grid cells route around walls; the last metre still targets the real device.
	# Fractional apparatus coordinates must not stall at a rounded cell centre.
	if data.has("path_index") and data.has("target") and data.target is Vector3:
		var finish = Vector3(data.target.x,at.y,data.target.z)-at
		if finish.length() > 0.12 and has_sight(at+Vector3.UP,Vector3(data.target.x,at.y+1.0,data.target.z)):
			return finish.normalized()
	return Vector3.ZERO

func _choose_bot_goal(data: Dictionary, number: int) -> void:
	var a: EyesSurvivor = data.actor
	if director.phase == "escape":
		data.task = "escape"
		data.target = EyesArena.EXIT_POSITION+Vector3(0,0,1)
		return
	if a.carrying >= 0:
		data.task = "deliver"
		data.target = EyesArena.STATIONS.silent+Vector3(0,0,2.3)
		return
	if trial_world.cargo_goal(data):
		return
	var preferred: String = ["silent","echoes","relay","silent"][number]
	var priorities: Array[String] = [preferred]
	for slot: String in ["silent","relay","echoes"]:
		if not priorities.has(slot):
			priorities.append(slot)
	for slot: String in priorities:
		if director.seals[slot]:
			continue
		if director.trial_for_slot(slot) != slot:
			if trial_world.assign_slot(data,slot):
				return
			continue
		if slot == "silent":
			var nearest: float = INF
			var chosen = -1
			for i in range(3):
				if motes_state[i] != 0:
					continue
				var reserved = false
				for other in bots:
					if other != data and other.mote == i and other.task == "pickup" and not other.actor.eliminated:
						reserved = true
				if reserved:
					continue
				var distance = a.global_position.distance_to(_mote_position(i))
				if distance < nearest:
					nearest = distance
					chosen = i
			if chosen >= 0:
				data.task = "pickup"
				data.mote = chosen
				data.target = _mote_position(chosen)+Vector3(0,0,1.7)
				return
		else:
			data.mote = -1
			data.task = slot
			data.target = EyesArena.STATIONS[slot]+Vector3(0,0,2.4)
			return
	data.task = "trial_wait"
	data.mote = -1
	data.target = Vector3(-4+number*2,0,20)

func _safe_point(a: EyesSurvivor) -> Vector3:
	var candidates: Array[Vector3] = [Vector3(-4.2,0,0),Vector3(4.2,0,0),Vector3(0,0,-4.2),Vector3(0,0,4.2),Vector3(-9,0,-8.5),Vector3(-9,0,8.5),Vector3(9,0,-8.5),Vector3(9,0,8.5)]
	var best = a.global_position
	var distance: float = INF
	for p in candidates:
		if not has_sight(eye_origin(),p+Vector3.UP) and p.distance_to(a.global_position) < distance:
			best = p
			distance = p.distance_to(a.global_position)
	return best

func _update_bots(delta: float) -> void:
	var relay_rate: float = 0.0
	for i in range(bots.size()):
		var data: Dictionary = bots[i]
		var a: EyesSurvivor = data.actor
		if a.eliminated:
			continue
		if director.phase == "preparation":
			a.move_target = a.global_position
			continue
		data.think -= delta
		data.repath -= delta
		data.hiding = maxf(0.0,data.hiding-delta)
		if a.gaze > 58 and data.hiding <= 0:
			data.hiding = 3.0
			data.target = _safe_point(a)
			data.task = "hide"
			data.repath = 0.0
		if data.think <= 0 and data.hiding <= 0:
			data.think = 1.5
			var previous: Vector3 = data.target
			_choose_bot_goal(data,i)
			if previous.distance_to(data.target) > 0.2:
				data.repath = 0.0
				data.action_time = 0.0
		if data.repath <= 0:
			data.repath = 1.0
			data.path = _path(a.global_position,data.target)
			data.path_index = 0
		var dir = _path_direction(a.global_position,data)
		a.move_target = a.global_position+dir*2.0
		a.bot_sprint = data.task == "escape" or data.task == "hide"
		a.bot_crouch = a.carrying >= 0 or trial_world.has_cargo(a) or (a.gaze > 25 and data.task != "hide")
		# Avoid a warned trap by taking a perpendicular step into open navigation.
		for t in range(traps.size()):
			if traps[t].state == "warning" and a.global_position.distance_to(EyesArena.TRAP_POSITIONS[t]) < 2.6:
				var away = (a.global_position-EyesArena.TRAP_POSITIONS[t]).normalized()
				var escape_to = a.global_position+away*2.8
				a.move_target = escape_to
				a.bot_sprint = true
		if a.global_position.distance_to(data.target) < 0.55:
			a.move_target = a.global_position
			data.action_time += delta
			if data.task == "pickup":
				if _pickup(a,data.mote):
					data.think = 0
			elif data.task == "deliver":
				if _deliver(a):
					data.think = 0
			elif data.task == "echoes" and not director.seals.echoes:
				# Bots visibly observe before entering one symbol every 1.2 seconds.
				if data.action_time > 5.0:
					data.action_time = 3.8
					var symbol: int = director.echo_sequence[director.echo_index]
					arena.show_echo(symbol)
					director.input_echo(symbol)
			elif data.task == "relay" and not director.seals.relay:
				relay_rate += 1.4 if a.archetype == "Tinker" else 1.0
			elif data.task == "escape" and data.action_time >= 1.5:
				director.register_escape()
			else:
				trial_world.bot_arrived(data,delta)
		if a.archetype == "Keeper" and a.health < 60:
			a.use_ability()
		elif a.gaze > 50:
			a.use_ability()
	director.charge_relay(delta*minf(1.8,relay_rate) if relay_rate > 0 else delta,relay_rate > 0)
	if relay_rate > 0:
		arena.relay_wheel.rotation.z += delta*2.0

func _start_punishment() -> void:
	_close_echo()
	punishment = true
	punishment_used = true
	punishment_left = 25.0
	punishment_hits = 0
	punishment_beat = 0.0
	player.health = 1
	player.gaze = 0
	player.respawn_shield = 30
	player.global_position = Vector3(72,0,3)
	player.velocity = Vector3.ZERO
	player.rotation.y = 0
	player.pitch = 0
	player.head.rotation.x = 0
	punishment_room = Node3D.new()
	punishment_room.position = Vector3(72,0,0)
	add_child(punishment_room)
	arena.box(Vector3(0,-0.3,0),Vector3(10,0.6,10),arena.mats.dark,true,punishment_room)
	for x in [-5,5]:
		arena.box(Vector3(x,3,0),Vector3(0.4,6,10),arena.mats.stone,true,punishment_room)
	for z in [-5,5]:
		arena.box(Vector3(0,3,z),Vector3(10,6,0.4),arena.mats.stone,true,punishment_room)
	punishment_ring = arena.ring(Vector3(0,2.1,-3.8),1.15,1.35,arena.mats.amber,punishment_room)
	punishment_ring.rotation_degrees.x = 90
	arena.inscription("SECOND SIGHT",Vector3(0,4,-3.7),Color("d7c5a6"),31,punishment_room)
	arena.light(Vector3(0,3,0),Color("8fc4b3"),3,10,punishment_room)
	ui.toast("One reprieve. Match three green beats before time runs out.",6)

func _update_punishment(delta: float) -> void:
	punishment_left -= delta
	punishment_beat += delta
	var safe = fmod(punishment_beat,2.0) >= 1.2 and fmod(punishment_beat,2.0) <= 1.8
	punishment_ring.material_override = arena.mats.cyan if safe else arena.mats.amber
	active_hint = "SECOND SIGHT  /  %d of 3\n%s  ·  %ds remaining" % [punishment_hits,"[ E ]  NOW — GREEN" if safe else "Wait for the green ring",ceili(punishment_left)]
	if punishment_left <= 0:
		player.eliminated = true
		player.active = false
		punishment = false
		director.register_elimination()

func _punishment_input() -> void:
	var beat = fmod(punishment_beat,2.0)
	if beat >= 1.2 and beat <= 1.8:
		punishment_hits += 1
		punishment_beat = 0
		soundscape.play("echo",1.0+punishment_hits*0.1,-10)
		if punishment_hits >= 3:
			punishment = false
			player.health = 50
			player.respawn_shield = 5.0
			player.invulnerability = 2.0
			player.gaze = 0
			player.global_position = EyesArena.SPAWN
			metrics.punishments_survived += 1
			ui.toast("A second chance. Your next fall is final.",4)
	else:
		punishment_left = maxf(0,punishment_left-2.0)
		soundscape.play("fail",1,-12)

func _on_event(kind: String, payload: Dictionary) -> void:
	event_log.append({"time":snappedf(elapsed,0.01),"kind":kind,"data":payload.duplicate(true)})
	if kind == "phase":
		if payload.phase == "hunt":
			ui.toast("The observance begins. Stay out of its gaze.",4)
		elif payload.phase == "escape":
			arena.open_exit(true)
			ui.toast("THREE SEALS BROKEN — the north door is open.",6)
			soundscape.play("seal",0.7,-7)
			for data in bots:
				data.think = 0
				data.hiding = 0
	elif kind == "seal":
		arena.set_seal(payload.seal,true)
		ui.toast("%s — seal broken." % EyesTrialApparatus.TRIAL_NAMES[director.trial_for_slot(payload.seal)],4)
		soundscape.play("seal",1,-10)
	elif kind == "delivery":
		ui.toast("Whisper delivered  /  %d of 3" % payload.delivered,3)
		soundscape.play("pickup",0.85,-12)
	elif kind in ["vault_pickup","vault_deposit","ember_taken","ritual_vessel"]:
		soundscape.play("pickup",1.0,-14)
		if kind == "vault_deposit":
			ui.toast("Vault cradle locked / %d of 4" % payload.deposited,3)
		elif kind == "ritual_vessel":
			ui.toast("Ritual vessel lit / %d of 5 / %d banked" % [payload.progress,payload.bank],3)
	elif kind == "ritual_ready":
		ui.toast("All five vessels are lit. Keep moving inside the ring for eight continuous seconds.",5)
	elif kind in ["vault_error","ritual_error","clock_error"]:
		soundscape.play("fail",1.0,-17)
		var messages = {"vault_error":"Wrong relic for this cradle. It remains in your hands; G returns it safely.","ritual_error":"Wrong vessel. Banked pairs remain lit; the ember returns to its cradle.","clock_error":"The constellation is not aligned. Reverse with R, or reset at the centre with X."}
		ui.toast(messages[kind],4)
		for actor in actors:
			if actor.get_instance_id() == int(payload.get("actor_id",0)):
				last_noise = actor.global_position
				noise_memory = 6.0
	elif kind == "result":
		_end_match(payload)

func _end_match(payload: Dictionary) -> void:
	for a in actors:
		a.active = false
		# Physics states freeze on a result; no additional wounds or terminal events.
	if echo_open:
		_close_echo()
	player.active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var reasons = {"first_escape":"A survivor reached the Unseen Door. The entire team wins.","all_eliminated":"Every survivor has fallen. The chamber belongs to the Eye.","hunt_timeout":"The hunt clock expired before the three seals were broken.","escape_timeout":"The open door closed before any survivor could escape."}
	var won = (payload.winner == "eye") == (mode == "eye")
	ui.show_result(won,reasons.get(payload.reason,"The observance has ended."),"TIME  %02d:%02d    SEALS  %d/3    WOUNDS  %d\nSEED  %d    DIFFICULTY  %s" % [int(elapsed)/60,int(elapsed)%60,director.seals.values().count(true),metrics.wounds,seed_value,director.difficulty.to_upper()])
	if qa_capture.is_empty():
		var file = FileAccess.open("user://last_observance.json",FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify({"schema_version":2,"game_version":"0.2.0","mode":mode,"contract":contract,"trials":director.trial_set.slot_trials,"seed":seed_value,"difficulty":director.difficulty,"result":payload,"elapsed":elapsed,"metrics":metrics,"events":event_log},"\t"))

func _update_hud() -> void:
	var eye_mode = mode == "eye"
	var display_time: float = director.escape_left if director.phase == "escape" else director.time_left
	if director.phase == "preparation":
		display_time = director.grace_left
	var phase_text = {"preparation":"PREPARATION  /  THE EYE CANNOT STRIKE YET","hunt":"THE OBSERVANCE  /  THREE SEALS REQUIRED","escape":"THE FINAL PASSAGE  /  REACH THE NORTH DOOR","ended":"OBSERVANCE COMPLETE"}.get(director.phase,"")
	var bot_positions: Array[Vector3] = []
	if eye_mode:
		for a in actors:
			if not a.eliminated and eye_sees(a.target_point()):
				bot_positions.append(a.global_position)
	var objective = "Three active trials / %s\nUse TAB to read the chamber." % {"first":"FIRST OBSERVANCE","second":"SECOND OBSERVANCE","mix":"SEEDED MIX"}[contract]
	if player.carrying >= 0:
		objective = "CARRYING A WHISPER\nCrouch to keep it quiet. Deliver northwest."
	var carried_relic: int = director.trial_set.carried_relic(player.get_instance_id())
	if carried_relic >= 0:
		objective = "CARRYING %s\nFind its numbered cradle. G returns it safely." % EyesTrialApparatus.RELIC_NAMES[carried_relic]
	elif director.trial_set.ember_owner == player.get_instance_id():
		objective = "CARRYING THE SHARED EMBER\nFollow the engraved vessel order in the northeast."
	if not eye_mode and player.archetype == "Tinker" and player.ability_left > 0 and director.trial_for_slot("relay") == "clock" and not director.seals.relay:
		objective += "\nOVERCLOCK / " + trial_world.clock_hint()
	if director.phase == "escape":
		objective = "THE UNSEEN DOOR IS OPEN\nNorth side. Hold E at the doorway."
	if eye_mode:
		objective = "%d SURVIVORS REMAIN\nVisible survivors appear on your map." % director.alive_count
	var ability = ""
	if eye_mode:
		ability = "TRAP %02d  MARK %02d  CALL %02d" % [ceili(director.cooldowns.trap),ceili(director.cooldowns.mark),ceili(director.cooldowns.summon)]
	else:
		ability = "Q  %s  /  %s" % [{"Veil":"QUIET STEP","Tinker":"OVERCLOCK","Runner":"SECOND WIND","Keeper":"MEND"}[player.archetype],"READY" if player.ability_cooldown <= 0 else "%ds" % ceili(player.ability_cooldown)]
	var hint = active_hint
	if eye_mode:
		var target = _aimed_actor()
		var trap = _aimed_trap()
		hint = "[ RMB ]  Mark %s" % target.params.name if target != null else ("[ LMB ]  Trigger floor trap  /  25 energy" if trap >= 0 else "Look for movement. Switch sockets with 1–4.")
		if director.phase == "preparation":
			hint = "PREPARATION  /  The survivors have eight seconds of grace."
	var gaze_text = "UNSEEN"
	if player.gaze > 0:
		gaze_text = "BREAK THE GAZE  /  %d%%" % int(player.gaze)
	if punishment:
		gaze_text = "SECOND SIGHT"
	if eye_mode:
		gaze_text = "TERROR  /  %d%%" % int(director.terror)
	var direction = "NORTH  /  THE UNSEEN DOOR"
	if not eye_mode:
		var angle = fposmod(player.rotation_degrees.y+45,360)
		direction = ["NORTH  /  THE UNSEEN DOOR","WEST  /  "+EyesTrialApparatus.TRIAL_NAMES[director.trial_for_slot("silent")],"SOUTH  /  "+EyesTrialApparatus.TRIAL_NAMES[director.trial_for_slot("relay")],"EAST  /  "+EyesTrialApparatus.TRIAL_NAMES[director.trial_for_slot("echoes")]][int(angle/90)%4]
	ui.update_hud({"time":display_time,"phase":phase_text,"health_text":"INFLUENCE  %d / 100" % int(director.energy) if eye_mode else "%s  /  VITALITY  %d" % [player.archetype.to_upper(),int(player.health)],"health":director.energy if eye_mode else player.health,"stamina":100 if eye_mode else player.stamina/player.params.stamina*100,"gaze":director.terror if eye_mode else player.gaze,"gaze_text":gaze_text,"ability":ability,"objective":objective,"hint":hint,"socket":director.eye_socket,"compass":direction,"seals":director.seals,"progress":{"silent":director.progress_for_slot("silent"),"echoes":director.progress_for_slot("echoes"),"relay":director.progress_for_slot("relay")},"position":player.global_position,"bots":bot_positions})
	ui.flash_label.text = "MARKED" if marked_until.has(player.get_instance_id()) and not eye_mode else ""

func _apply_settings(values: Dictionary, save: bool = true) -> void:
	soundscape.set_enabled(values.audio and not mute_requested)
	player.mouse_sensitivity = 0.0022*values.sensitivity
	player.invert_y = values.invert_y
	player.motion_reduced = values.reduced_motion
	player.camera.fov = values.fov
	if save:
		var config = ConfigFile.new()
		for key in values:
			config.set_value("accessibility",key,values[key])
		config.save("user://settings.cfg")

func _load_settings() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for key in ui.settings:
			var value = config.get_value("accessibility",key,ui.settings[key])
			if typeof(value) == typeof(ui.settings[key]):
				ui.settings[key] = value
		ui.settings.sensitivity = clampf(ui.settings.sensitivity,0.3,2.5)
		ui.settings.fov = clampf(ui.settings.fov,65,100)
	ui.sync_settings_controls()
	_apply_settings(ui.settings,false)
