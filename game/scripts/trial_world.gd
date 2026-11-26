class_name EyesTrialWorld
extends RefCounted
## Shared spatial command path: humans and bots use exactly these validations.

const Props = preload("res://scripts/trial_apparatus.gd")
var game
var state
var apparatus: EyesTrialApparatus
var clock_operator: int = 0

func configure(p_game, p_state, p_apparatus: EyesTrialApparatus) -> void:
	game = p_game
	state = p_state
	apparatus = p_apparatus
	clock_operator = 0

func _valid(actor: EyesSurvivor) -> bool:
	return actor in game.actors and not actor.eliminated and not actor.downed and state.live and not (actor == game.player and game.punishment)

func _within(actor: EyesSurvivor, point: Vector3, radius: float) -> bool:
	return _valid(actor) and actor.global_position.distance_to(point) <= radius and game.has_sight(actor.target_point(),point+Vector3.UP*1.65)

func has_cargo(actor: EyesSurvivor) -> bool:
	var id = actor.get_instance_id()
	return state.carried_relic(id) >= 0 or state.ember_owner == id

func release(actor: EyesSurvivor) -> void:
	state.release_actor(actor.get_instance_id())
	if actor.carrying >= 0:
		game._drop_mote(actor)
	if clock_operator == actor.get_instance_id():
		clock_operator = 0

func _command(kind: String, index: int, point: Vector3, radius: float, title: String) -> Dictionary:
	return {"kind":kind,"index":index,"point":point,"radius":radius,"title":title}

func nearest(actor: EyesSurvivor) -> Dictionary:
	if not _valid(actor):
		return {}
	var options: Array[Dictionary] = []
	var id = actor.get_instance_id()
	if state.trial_for_slot("silent") == "vault" and not game.director.seals.silent:
		options.append(_command("vault_read",0,Props.VAULT_DESK,2.7,"[ E ]  Read the four relics / eight-second display"))
		var relic: int = state.carried_relic(id)
		if relic >= 0:
			for i in range(4):
				if state.vault_cradles[i] < 0:
					options.append(_command("vault_deposit",i,Props.CRADLE_POSITIONS[i],1.85,"[ E ]  Place %s in cradle %d" % [Props.RELIC_NAMES[relic],i+1]))
		elif actor.carrying < 0 and state.ember_owner != id:
			for i in range(6):
				if state.relic_available(i):
					options.append(_command("vault_pickup",i,Props.RELIC_POSITIONS[i],1.9,"[ E ]  Carry %s / G returns it to its shelf" % Props.RELIC_NAMES[i]))
	if state.trial_for_slot("echoes") == "ritual" and not game.director.seals.echoes:
		if state.ember_owner == 0 and state.ritual_index < 5 and not has_cargo(actor) and actor.carrying < 0:
			options.append(_command("ember_pickup",0,Props.EMBER_POSITION,1.8,"[ E ]  Take the shared ember"))
		if state.ember_owner == id:
			for i in range(5):
				if not state.ritual_vessel_lit(i):
					options.append(_command("ritual_light",i,Props.VESSEL_POSITIONS[i],1.8,"[ E ]  Light vessel %d / read the engraved order" % [i+1]))
	if state.trial_for_slot("relay") == "clock" and not game.director.seals.relay:
		for i in range(3):
			options.append(_command("clock_turn",i,Props.CLOCK_LEVERS[i],1.9,"[ E ]  Turn %s +1    [ R ]  Reverse -1" % ["A","B","C"][i]))
		options.append(_command("clock_confirm",0,Props.CLOCK_CENTER,2.7,"[ E ]  Press the clock seal    [ X ]  Reset hands"))
	var best: Dictionary = {}
	var distance: float = INF
	for option in options:
		var d = actor.global_position.distance_to(option.point)
		if d < distance and _within(actor,option.point,option.radius):
			best = option
			distance = d
	return best

func interact(actor: EyesSurvivor, direction: int = 1, reset: bool = false) -> bool:
	var option = nearest(actor)
	if option.is_empty():
		return false
	if reset:
		if option.kind == "clock_confirm":
			perform(actor,"clock_reset",0)
			return true
		return false
	if direction < 0 and option.kind != "clock_turn":
		return false
	perform(actor,option.kind,option.index,direction)
	return true

func perform(actor: EyesSurvivor, kind: String, index: int = 0, direction: int = 1) -> bool:
	if not _valid(actor):
		return false
	var id = actor.get_instance_id()
	match kind:
		"vault_read":
			if state.trial_for_slot("silent") != "vault" or not _within(actor,Props.VAULT_DESK,2.7):
				return false
			apparatus.show_vault_reference()
			if actor == game.player:
				game.ui.toast("The target relics are shown above the vault. Four cradles, four exact identities.",4)
			return true
		"vault_pickup":
			if index < 0 or index >= 6 or actor.carrying >= 0 or not _within(actor,Props.RELIC_POSITIONS[index],1.9):
				return false
			return state.pickup_relic(id,index)
		"vault_deposit":
			if index < 0 or index >= 4 or not _within(actor,Props.CRADLE_POSITIONS[index],1.85):
				return false
			return state.deposit_relic(id,index)
		"ember_pickup":
			if actor.carrying >= 0 or not _within(actor,Props.EMBER_POSITION,1.8):
				return false
			return state.take_ember(id)
		"ritual_light":
			if index < 0 or index >= 5 or not _within(actor,Props.VESSEL_POSITIONS[index],1.8):
				return false
			return state.light_vessel(id,index)
		"clock_turn":
			if index < 0 or index >= 3 or not _within(actor,Props.CLOCK_LEVERS[index],1.9):
				return false
			return state.turn_clock(index,direction)
		"clock_reset":
			if not _within(actor,Props.CLOCK_CENTER,2.7):
				return false
			return state.reset_clock()
		"clock_confirm":
			if not _within(actor,Props.CLOCK_CENTER,2.7):
				return false
			return state.confirm_clock()
	return false

func step(delta: float) -> void:
	if state.trial_for_slot("echoes") != "ritual":
		return
	var occupied = false
	for actor in game.actors:
		if not _valid(actor) or absf(actor.global_position.y) > 0.5:
			continue
		var offset = Vector2(actor.global_position.x-Props.RITUAL_CENTER.x,actor.global_position.z-Props.RITUAL_CENTER.z)
		if offset.length() <= 2.8:
			occupied = true
			break
	state.charge_ritual(delta,occupied)

func hint(actor: EyesSurvivor) -> String:
	if state.trial_for_slot("echoes") == "ritual" and state.ritual_index >= 5 and not game.director.seals.echoes and actor.global_position.distance_to(Props.RITUAL_CENTER) < 4.5:
		return "RITUAL  /  Keep moving inside the ring  /  %.1f of 8 seconds" % state.ritual_hold
	var option = nearest(actor)
	return option.title if not option.is_empty() else ""

func _assign(data: Dictionary, task: String, point: Vector3, index: int = 0, direction: int = 1) -> bool:
	data.task = task
	data.target = point
	data.trial_index = index
	data.trial_direction = direction
	data.mote = -1
	return true

func cargo_goal(data: Dictionary) -> bool:
	var actor: EyesSurvivor = data.actor
	var id = actor.get_instance_id()
	var relic: int = state.carried_relic(id)
	if relic >= 0:
		var cradle: int = state.vault_targets.find(relic)
		if cradle >= 0 and state.vault_cradles[cradle] < 0:
			return _assign(data,"vault_deposit",Props.CRADLE_POSITIONS[cradle]+Vector3(0,0,1.0),cradle)
		state.release_actor(id)
	if state.ember_owner == id:
		if state.ritual_index < 5:
			var next: int = state.ritual_sequence[state.ritual_index]
			return _assign(data,"ritual_light",Props.VESSEL_POSITIONS[next]+Vector3(0,0,0.85),next)
	return false

func assign_slot(data: Dictionary, slot: String) -> bool:
	var actor: EyesSurvivor = data.actor
	var id = actor.get_instance_id()
	match state.trial_for_slot(slot):
		"vault":
			if not bool(data.get("vault_seen",false)):
				return _assign(data,"vault_observe",Props.VAULT_DESK+Vector3(0,0,2.1))
			var nearest_relic: int = -1
			var distance: float = INF
			for i in range(4):
				var relic: int = state.vault_targets[i]
				if state.vault_cradles[i] >= 0 or not state.relic_available(relic):
					continue
				var reserved = false
				for other in game.bots:
					if other != data and other.task == "vault_pickup" and other.get("trial_index",-1) == relic and not other.actor.eliminated and not other.actor.downed:
						reserved = true
				if reserved:
					continue
				var d = actor.global_position.distance_to(Props.RELIC_POSITIONS[relic])
				if d < distance:
					distance = d
					nearest_relic = relic
			if nearest_relic < 0:
				return false
			return _assign(data,"vault_pickup",Props.RELIC_POSITIONS[nearest_relic]+Vector3(0,0,1.0),nearest_relic)
		"ritual":
			if state.ritual_index >= 5:
				return _assign(data,"ritual_hold",Props.RITUAL_CENTER+Vector3(0,0,2.0))
			if state.ember_owner == 0 and not has_cargo(actor):
				return _assign(data,"ember_pickup",Props.EMBER_POSITION+Vector3(0,0,0.9))
			return false
		"clock":
			if clock_operator != 0 and clock_operator != id:
				var alive = false
				for candidate in game.actors:
					if candidate.get_instance_id() == clock_operator and not candidate.eliminated and not candidate.downed:
						alive = true
				if alive:
					return false
			clock_operator = id
			if state.clock_hands == state.clock_target:
				return _assign(data,"clock_confirm",Props.CLOCK_CENTER+Vector3(0,0,2.1))
			var solution: Array[Vector2i] = state.clock_solution()
			if solution.is_empty():
				return false
			var move: Vector2i = solution[0]
			return _assign(data,"clock_turn",Props.CLOCK_LEVERS[move.x]+Vector3(0,0,0.8),move.x,move.y)
	return false

func bot_arrived(data: Dictionary, delta: float) -> void:
	var actor: EyesSurvivor = data.actor
	var task: String = data.task
	if task == "vault_observe":
		if not bool(data.get("vault_observing",false)):
			data.vault_observing = perform(actor,"vault_read")
		if data.action_time >= 8.0 and bool(data.get("vault_observing",false)):
			data.vault_seen = true
			data.think = 0.0
			data.action_time = 0.0
		return
	if task in ["vault_pickup","vault_deposit","ember_pickup","ritual_light","clock_turn","clock_confirm"]:
		if data.action_time >= 0.4:
			if perform(actor,task,int(data.get("trial_index",0)),int(data.get("trial_direction",1))):
				data.think = 0.0
			data.action_time = 0.0

var _advice_state: String = ""
var _advice_text: String = ""

func clock_hint() -> String:
	var key = str(state.clock_hands)+str(state.clock_target)
	if key != _advice_state:
		_advice_state = key
		if state.clock_hands == state.clock_target:
			_advice_text = "Aligned. Press E at the central seal."
		else:
			var solution: Array[Vector2i] = state.clock_solution()
			_advice_text = "Read the gear diagram." if solution.is_empty() else "Next lever %s / %s" % [["A","B","C"][solution[0].x],"E forward" if solution[0].y > 0 else "R reverse"]
	return _advice_text
