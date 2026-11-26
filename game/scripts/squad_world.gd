class_name EyesSquadWorld
extends RefCounted
## Local physical team coordination. The state machine never supplies positions;
## this boundary validates the same range, sight and uninterrupted hold for everyone.

const RESCUE_RADIUS: float = 1.8
const HEAL_RADIUS: float = 4.0
var game
var state: EyesSquadState
var order: String = "work"
var roster: Dictionary = {}
var assignments: Dictionary = {}
var approaches: Dictionary = {}
var hold_points: Dictionary = {}
var interrupted: Dictionary = {}
var assignment_left: float = 0.0
var player_rescuing: bool = false
var counters: Dictionary = {"downs":0,"revives":0,"eliminations":0,"orders":0,"heals":0}

func configure(p_game) -> void:
	game = p_game
	state = EyesSquadState.new()
	var ids: Array[int] = []
	for actor: EyesSurvivor in game.actors:
		var id = actor.get_instance_id()
		ids.append(id)
		roster[id] = actor
		actor.team_id = game.player.get_instance_id()
	state.configure(ids,game.player.get_instance_id())
	state.event_raised.connect(_on_state_event)

func shutdown() -> void:
	state.set_live(false)
	if state.event_raised.is_connected(_on_state_event):
		state.event_raised.disconnect(_on_state_event)
	assignments.clear()
	approaches.clear()

func eligible(actor: EyesSurvivor) -> bool:
	return is_instance_valid(actor) and roster.has(actor.get_instance_id()) and not actor.eliminated and not actor.downed and state.is_active(actor.get_instance_id())

func set_order(value: String) -> bool:
	if value not in ["work","follow","hold"] or value == order or not eligible(game.player) or game.director.phase not in ["preparation","hunt","escape"]:
		return false
	order = value
	counters.orders += 1
	hold_points.clear()
	for data: Dictionary in game.bots:
		hold_points[data.actor.get_instance_id()] = data.actor.global_position
		data.think = 0.0
		data.repath = 0.0
		data.action_time = 0.0
	game._on_squad_event("squad_order",{"order":order})
	return true

func step(delta: float) -> void:
	state.set_live(game.director.phase in ["hunt","escape"])
	player_rescuing = false
	if not state.live:
		return
	for id in interrupted.keys():
		interrupted[id] = maxf(0.0,float(interrupted[id])-delta)
		if interrupted[id] <= 0:
			interrupted.erase(id)
	state.step(delta)
	if not state.live:
		return
	_update_player_rescue(delta)
	assignment_left -= delta
	if assignment_left <= 0:
		assignment_left = 0.6
		_assign_rescuers()

func interrupt_actor(actor: EyesSurvivor) -> void:
	var id = actor.get_instance_id()
	state.cancel_revive(id)
	interrupted[id] = 0.3

func in_rescue_range(helper: EyesSurvivor, subject: EyesSurvivor) -> bool:
	return eligible(helper) and is_instance_valid(subject) and roster.has(subject.get_instance_id()) and state.is_downed(subject.get_instance_id()) and helper.global_position.distance_to(subject.global_position) <= RESCUE_RADIUS and game.has_sight(helper.target_point(),subject.target_point())

func nearby_downed(helper: EyesSurvivor) -> EyesSurvivor:
	var best: EyesSurvivor = null
	var distance: float = INF
	for subject: EyesSurvivor in game.actors:
		if in_rescue_range(helper,subject):
			var owner: int = int(state.member(subject.get_instance_id()).reviver)
			if owner == helper.get_instance_id():
				return subject
			if owner != 0:
				continue
			var d = helper.global_position.distance_to(subject.global_position)
			if d < distance:
				best = subject
				distance = d
	return best

func _stationary(actor: EyesSurvivor) -> bool:
	if Vector2(actor.velocity.x,actor.velocity.z).length() > 0.35 or absf(actor.velocity.y) > 0.5:
		return false
	if actor == game.player and (Input.get_vector("move_left","move_right","move_forward","move_back").length() > 0.0 or Input.is_action_pressed("jump")):
		return false
	return true

func _hold_rescue(helper: EyesSurvivor, subject: EyesSurvivor, delta: float) -> bool:
	var id = helper.get_instance_id()
	if not state.live or interrupted.has(id) or not in_rescue_range(helper,subject) or not _stationary(helper):
		state.cancel_revive(id)
		return false
	if not state.begin_revive(id,subject.get_instance_id()):
		state.cancel_revive(id)
		return false
	return state.advance_revive(id,subject.get_instance_id(),delta)

func _update_player_rescue(delta: float) -> void:
	var helper: EyesSurvivor = game.player
	if not eligible(helper) or game.echo_open or not Input.is_action_pressed("interact"):
		state.cancel_revive(helper.get_instance_id())
		return
	var subject = nearby_downed(helper)
	if subject == null:
		state.cancel_revive(helper.get_instance_id())
		return
	# Even a moving/blocked rescuer cannot also operate the wheel or exit with E.
	player_rescuing = true
	_hold_rescue(helper,subject,delta)

func _approach(helper: EyesSurvivor, subject: EyesSurvivor) -> Dictionary:
	if in_rescue_range(helper,subject):
		return {"point":helper.global_position,"cost":0.0}
	var best: Dictionary = {}
	var best_cost: float = INF
	for i in range(12):
		var angle = float(i)*TAU/12.0
		var point = subject.global_position+Vector3(cos(angle),0,sin(angle))*1.15
		var cell = Vector2i(roundi(point.x),roundi(point.z))
		if not game.navigation.is_in_boundsv(cell) or game.navigation.is_point_solid(cell) or not game.has_sight(point+Vector3.UP*1.2,subject.target_point()):
			continue
		var path: PackedVector2Array = game._path(helper.global_position,point)
		if path.is_empty():
			continue
		var cost: float = 0.0
		for index in range(1,path.size()):
			cost += path[index-1].distance_to(path[index])
		cost += Vector2(point.x,point.z).distance_to(path[path.size()-1])
		if cost < best_cost:
			best_cost = cost
			best = {"point":point,"cost":cost}
	return best

func _assign_rescuers() -> void:
	var old = assignments.duplicate()
	assignments.clear()
	approaches.clear()
	var used: Array[int] = []
	# Existing valid channels own their helper before new casualties are assigned.
	# A new down must never steal a rescuer six seconds into another hold.
	for subject: EyesSurvivor in game.actors:
		var subject_id = subject.get_instance_id()
		if not state.is_downed(subject_id):
			continue
		var owner: int = int(state.member(subject_id).reviver)
		if owner == 0 or owner == game.player.get_instance_id() or not roster.has(owner):
			continue
		var helper: EyesSurvivor = roster[owner]
		if in_rescue_range(helper,subject):
			assignments[subject_id] = owner
			approaches[subject_id] = helper.global_position
			used.append(owner)
	for subject: EyesSurvivor in game.actors:
		var subject_id = subject.get_instance_id()
		if not state.is_downed(subject_id) or assignments.has(subject_id):
			continue
		var row = state.member(subject_id)
		# A human who has begun a valid hold keeps the exclusive reservation.
		if int(row.reviver) == game.player.get_instance_id():
			continue
		var helper_id: int = 0
		var approach: Dictionary = {}
		var best_cost: float = INF
		for data: Dictionary in game.bots:
			var helper: EyesSurvivor = data.actor
			var id = helper.get_instance_id()
			if not eligible(helper) or used.has(id) or (int(row.reviver) != 0 and int(row.reviver) != id):
				continue
			var candidate = _approach(helper,subject)
			if candidate.is_empty():
				continue
			# Keep a travelling rescuer unless another is substantially closer.
			var cost: float = candidate.cost-(2.0 if old.get(subject_id,0) == id else 0.0)
			if cost < best_cost:
				best_cost = cost
				helper_id = id
				approach = candidate
		if helper_id != 0:
			assignments[subject_id] = helper_id
			approaches[subject_id] = approach.point
			used.append(helper_id)
	for subject_id in old:
		if assignments.get(subject_id,0) != old[subject_id]:
			state.cancel_revive(int(old[subject_id]))

func _move(data: Dictionary, point: Vector3, delta: float, sprint: bool) -> void:
	var actor: EyesSurvivor = data.actor
	if data.target.distance_to(point) > 0.3:
		data.repath = 0.0
		data.action_time = 0.0
	data.target = point
	data.repath -= delta
	if data.repath <= 0:
		data.repath = 0.6
		data.path = game._path(actor.global_position,point)
		data.path_index = 0
	var direction: Vector3 = game._path_direction(actor.global_position,data)
	actor.move_target = actor.global_position+direction*2.0
	actor.bot_sprint = sprint
	actor.bot_crouch = false
	if actor.global_position.distance_to(point) < 0.45:
		actor.move_target = actor.global_position
	# Real trap telegraphs interrupt a stationary hold and make allies move away.
	for index in range(game.traps.size()):
		if game.traps[index].state == "warning" and actor.global_position.distance_to(EyesArena.TRAP_POSITIONS[index]) < 2.6:
			var away = actor.global_position-EyesArena.TRAP_POSITIONS[index]
			away.y = 0.0
			if away.length() < 0.1:
				away = Vector3.RIGHT
			actor.move_target = actor.global_position+away.normalized()*2.8
			actor.bot_sprint = true
			interrupt_actor(actor)

func drive_bot(data: Dictionary, number: int, delta: float) -> bool:
	var actor: EyesSurvivor = data.actor
	var id = actor.get_instance_id()
	if not eligible(actor) or not state.live:
		return true
	for subject_id in assignments:
		if assignments[subject_id] != id or not state.is_downed(subject_id):
			continue
		var subject: EyesSurvivor = roster[subject_id]
		data.task = "rescue"
		data.rescue_id = subject_id
		data.hiding = 0.0
		var target: Vector3 = approaches[subject_id]
		if in_rescue_range(actor,subject):
			target = actor.global_position
		_move(data,target,delta,actor.global_position.distance_to(subject.global_position) > 4.0)
		_hold_rescue(actor,subject,delta)
		auto_ability(actor)
		return true
	state.cancel_revive(id)
	var follow = order == "follow" and eligible(game.player)
	if game.director.phase != "escape" and (follow or order == "hold"):
		var point: Vector3 = hold_points.get(id,actor.global_position)
		data.task = "follow" if follow else "hold"
		if follow:
			var offsets = [Vector3(-2.0,0,2.5),Vector3(2.0,0,2.5),Vector3(-2.0,0,4.5),Vector3(2.0,0,4.5)]
			var desired: Vector3 = game.player.global_position+offsets[number].rotated(Vector3.UP,game.player.rotation.y)
			var cell: Vector2i = game._nearest_cell(desired)
			point = Vector3(cell.x,actor.global_position.y,cell.y)
		_move(data,point,delta,follow and actor.global_position.distance_to(point) > 6.0)
		auto_ability(actor)
		return true
	if data.task in ["rescue","follow","hold"]:
		data.think = 0.0
		data.repath = 0.0
		data.action_time = 0.0
		data.hiding = 0.0
	return false

func avoid_threat(data: Dictionary) -> bool:
	var actor: EyesSurvivor = data.actor
	var threats: Array[Vector3] = []
	for shadow: Dictionary in game.shadows:
		var at: Vector3 = shadow.node.global_position
		if shadow.warmup < 0.7 and actor.global_position.distance_to(at) < 4.5 and game.has_sight(actor.target_point(),at+Vector3.UP):
			threats.append(at)
	if threats.is_empty():
		if data.task == "evade":
			data.think = 0.0
			data.repath = 0.0
		return false
	var best: Vector3 = actor.global_position
	var best_score: float = -INF
	for i in range(16):
		var direction = Vector3(sin(i*TAU/16.0),0,cos(i*TAU/16.0))
		var endpoint = actor.global_position+direction*2.8
		var cell = Vector2i(roundi(endpoint.x),roundi(endpoint.z))
		if not game.navigation.is_in_boundsv(cell) or game.navigation.is_point_solid(cell) or not game.has_sight(actor.target_point(),endpoint+Vector3.UP):
			continue
		var score: float = 0.0
		for point in threats:
			score += endpoint.distance_to(point)-actor.global_position.distance_to(point)
		# Prefer progress toward the current legitimate destination among safe steps.
		score += direction.dot((data.target-actor.global_position).normalized())*0.45
		if score > best_score:
			best_score = score
			best = endpoint
	state.cancel_revive(actor.get_instance_id())
	actor.move_target = best
	actor.bot_sprint = true
	actor.bot_crouch = false
	data.task = "evade"
	data.action_time = 0.0
	data.think = 0.0
	data.repath = 0.0
	auto_ability(actor)
	return true

func healing_target(actor: EyesSurvivor) -> EyesSurvivor:
	var target: EyesSurvivor = actor
	var lowest: float = actor.health
	for other: EyesSurvivor in game.actors:
		if other == actor or not eligible(other) or other.health >= lowest or actor.global_position.distance_to(other.global_position) > HEAL_RADIUS or not game.has_sight(actor.target_point(),other.target_point()):
			continue
		target = other
		lowest = other.health
	return target

func try_ability(actor: EyesSurvivor) -> bool:
	if not eligible(actor) or not state.live:
		return false
	var target = healing_target(actor) if actor.archetype == "Keeper" else actor
	var before = target.health
	if not actor.use_ability(target):
		return false
	if actor.archetype == "Keeper":
		counters.heals += 1
		game._on_squad_event("squad_heal",{"actor_id":actor.get_instance_id(),"target_id":target.get_instance_id(),"amount":target.health-before})
	return true

func auto_ability(actor: EyesSurvivor) -> void:
	if actor.archetype == "Keeper":
		if healing_target(actor).health <= 70.0:
			try_ability(actor)
	elif actor.gaze > 50:
		try_ability(actor)

func _on_state_event(kind: String, payload: Dictionary) -> void:
	var actor: EyesSurvivor = roster.get(int(payload.actor_id))
	if actor == null:
		return
	assignment_left = 0.0
	if kind == "squad_downed":
		counters.downs += 1
		game.trial_world.release(actor)
		actor.set_downed(true)
		actor.health = 0.0
		if actor == game.player and game.echo_open:
			game._close_echo()
	elif kind == "squad_revived":
		counters.revives += 1
		actor.set_downed(false)
		actor.health = float(payload.health)
		actor.respawn_shield = float(payload.protection)
		actor.invulnerability = 1.35
		actor.active = true
		for data: Dictionary in game.bots:
			if data.actor == actor:
				data.think = 0.0
				data.repath = 0.0
				data.hiding = 0.0
	elif kind == "squad_eliminated":
		counters.eliminations += 1
		game.trial_world.release(actor)
		actor.set_downed(false)
		actor.eliminated = true
		actor.active = false
		actor.visible = false
		game._on_squad_event(kind,payload)
		game.director.register_elimination()
		return
	game._on_squad_event(kind,payload)

func hud_data() -> Dictionary:
	var rows: Array[Dictionary] = []
	for actor: EyesSurvivor in game.actors:
		var row = state.member(actor.get_instance_id())
		var task: String = "Your survivor"
		for data: Dictionary in game.bots:
			if data.actor == actor:
				task = str(data.task).replace("_"," ").capitalize()
		rows.append({"name":actor.display_name,"archetype":actor.archetype,"state":row.state,"health":actor.health,"bleed_left":row.bleed_left,"revive_progress":float(row.revive_progress)/EyesSquadState.REVIVE_SECONDS,"task":task,"is_player":actor == game.player})
	var text: String = "Rescue takes priority. One escape wins for everyone."
	var human = state.member(game.player.get_instance_id())
	if human.state == "downed":
		var helper_id: int = int(human.reviver) if int(human.reviver) != 0 else int(assignments.get(game.player.get_instance_id(),0))
		text = "%s is coming to help." % roster[helper_id].display_name if helper_id != 0 else "Downed — waiting for a reachable ally."
	elif human.state == "eliminated":
		text = "SPECTATING  /  1–4 or wheel switches allies."
	elif game.director.phase == "escape":
		text = "The door is open. Allies rescue, then evacuate."
	return {"order":order,"leader_state":human.state,"members":rows,"rescue_text":text}

func summary() -> Dictionary:
	var result = counters.duplicate(true)
	result.order = order
	result.members = []
	for actor: EyesSurvivor in game.actors:
		var row = state.member(actor.get_instance_id())
		result.members.append({"name":actor.display_name,"archetype":actor.archetype,"state":row.state,"recoveries":row.recoveries})
	return result
