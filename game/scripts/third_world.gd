class_name EyesThirdWorld
extends RefCounted
## Physical admission, continuous actions and informed bots for three new trials.
## Both control types use the same range, sight, cargo and lifecycle guards.

const Props = preload("res://scripts/third_apparatus.gd")
const INTERACTION_RADIUS: float = 1.8
const REFUGE_RADIUS: float = 3.0
const OBSERVATION_SECONDS: float = 2.0
const STILL_SPEED: float = 0.18

var _host: WeakRef
var host:
	get:
		return _host.get_ref() if _host != null else null
var game
var selection
var state
var apparatus: Props
var strings_operator: int = 0
var chimes_operator: int = 0
var bot_holds: Dictionary = {}


func configure(p_host, p_apparatus: Props) -> void:
	_host = weakref(p_host)
	game = host.game
	selection = host.state
	state = selection.third
	apparatus = p_apparatus


func _valid(actor: EyesSurvivor) -> bool:
	return is_instance_valid(actor) and host._valid(actor) and not game.get_tree().paused


func _within(actor: EyesSurvivor, point: Vector3, radius: float = INTERACTION_RADIUS) -> bool:
	return _valid(actor) and host._within(actor, point, radius)


func _active(slot: String, trial: String) -> bool:
	return selection.live and selection.trial_for_slot(slot) == trial and not bool(game.director.seals[slot])


func _empty_hands(actor: EyesSurvivor) -> bool:
	var id: int = actor.get_instance_id()
	return actor.carrying < 0 and selection.carried_relic(id) < 0 and selection.ember_owner != id and state.carried_cell(id) < 0


func has_cargo(actor: EyesSurvivor) -> bool:
	return state.carried_cell(actor.get_instance_id()) >= 0


func release(actor: EyesSurvivor) -> void:
	var id: int = actor.get_instance_id()
	state.release_actor(id)
	cancel_actor(actor)
	if strings_operator == id:
		strings_operator = 0
	if chimes_operator == id:
		chimes_operator = 0
	apparatus.show_carry(actor, -1)


func cancel_actor(actor: EyesSurvivor) -> void:
	if not is_instance_valid(actor):
		return
	var id: int = actor.get_instance_id()
	state.interrupt_actor(id)
	bot_holds.erase(id)


func cancel_all() -> void:
	state.interrupt_all()
	bot_holds.clear()


func options(actor: EyesSurvivor) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _valid(actor):
		return result
	var id: int = actor.get_instance_id()
	if _active("silent", "light"):
		var cell: int = state.carried_cell(id)
		if cell >= 0:
			for index: int in range(3):
				if not state.light_lit[index]:
					var message: String = "[ HOLD E ]  Align CELL %d with refuge %d / two still seconds" % [cell + 1, index + 1]
					if cell != index:
						message = "CELL %d belongs to REFUGE %d / this is refuge %d" % [cell + 1, cell + 1, index + 1]
					elif state.charge_for(id) <= 0.0:
						message = "LANTERN EMPTY / recharge at the permanent refuge or a lit lamp"
					result.append(host._command("light_align", index, Props.LAMP_POSITIONS[index], INTERACTION_RADIUS, message))
		elif _empty_hands(actor):
			for index: int in range(3):
				if state.cell_available(index):
					result.append(host._command("light_pickup", index, Props.CELL_POSITIONS[index], INTERACTION_RADIUS, "[ E ]  Carry cell %d to refuge %d / G returns it" % [index + 1, index + 1]))
	if _active("echoes", "strings"):
		result.append(host._command("strings_read", 0, Props.STRINGS_DESK, 2.7, "[ E ]  Inspect the evidence / choose one of four tagged ropes"))
		for index: int in range(4):
			var shape: int = state.strings_layout[index]
			var message: String = "[ HOLD E ]  Cut rope %d / %s / two still seconds" % [index + 1, state.SHAPE_NAMES[shape]]
			if state.strings_cooldown > 0.0:
				message = "SAFETY CATCH / %.1f seconds / previous stages remain locked" % state.strings_cooldown
			result.append(host._command("strings_cut", index, Props.ROPE_POSITIONS[index], INTERACTION_RADIUS, message))
	if _active("relay", "chimes"):
		result.append(host._command("chimes_read", 0, Props.CHIMES_DESK, 2.7, "[ E ]  Read the score / two banked phrases / physical bells 1–4"))
		for index: int in range(4):
			var damping: String = "DAMPED" if state.damper == index else "LOUD"
			result.append(host._command("chimes_strike", index, Props.BELL_POSITIONS[index], INTERACTION_RADIUS, "[ E ]  Strike bell %d  /  [ R ]  Toggle damper  /  %s" % [index + 1, damping]))
	return result


func perform(actor: EyesSurvivor, kind: String, index: int = 0) -> bool:
	if not _valid(actor):
		return false
	var id: int = actor.get_instance_id()
	match kind:
		"light_pickup":
			if not _active("silent", "light") or index < 0 or index >= 3 or not _empty_hands(actor) or not _within(actor, Props.CELL_POSITIONS[index]):
				return false
			return state.pickup_cell(id, index)
		"light_align":
			# No instantaneous action can award held progress. step() owns time.
			return _active("silent", "light") and index >= 0 and index < 3 and _within(actor, Props.LAMP_POSITIONS[index]) and state.carried_cell(id) == index
		"strings_read":
			if not _active("echoes", "strings") or not _within(actor, Props.STRINGS_DESK, 2.7):
				return false
			if actor == game.player:
				game.ui.toast(state.strings_clue(), 6.0)
			return true
		"strings_cut":
			return _active("echoes", "strings") and index >= 0 and index < 4 and _within(actor, Props.ROPE_POSITIONS[index])
		"chimes_read":
			if not _active("relay", "chimes") or not _within(actor, Props.CHIMES_DESK, 2.7):
				return false
			if actor == game.player:
				game.ui.toast("PHRASE %d / %s / walk to each bell; R dampens it before E strikes." % [state.chimes_phrase + 1, score_text()], 6.0)
			return true
		"chimes_damp", "chimes_strike":
			if not _active("relay", "chimes") or index < 0 or index >= 4 or not _within(actor, Props.BELL_POSITIONS[index]):
				return false
			if kind == "chimes_damp":
				return state.toggle_damper(id, index)
			return state.strike_bell(id, index)
	return false


func score_text() -> String:
	if state.chimes_phrase >= 2:
		return "TWO PHRASES LOCKED"
	var values: Array[String] = []
	for bell: int in state.chimes_sequences[state.chimes_phrase]:
		values.append(str(bell + 1))
	return " → ".join(values)


func _still(actor: EyesSurvivor) -> bool:
	return Vector2(actor.velocity.x, actor.velocity.z).length() <= STILL_SPEED and absf(actor.velocity.y) <= 0.35 and absf(actor.global_position.y) <= 0.5


func in_refuge(actor: EyesSurvivor) -> bool:
	if not _active("silent", "light"):
		return false
	if _within(actor, Props.BASE_REFUGE, REFUGE_RADIUS):
		return true
	for index: int in range(3):
		if state.light_lit[index] and _within(actor, Props.LAMP_POSITIONS[index], REFUGE_RADIUS):
			return true
	return false


func _bot_hold(actor: EyesSurvivor) -> Dictionary:
	for data: Dictionary in game.bots:
		if data.actor == actor and data.task in ["light_align", "strings_cut"]:
			if data.task == "strings_cut" and int(data.get("strings_seen_stage", -1)) != state.strings_stage:
				data.think = 0.0
				return {}
			# Reaching a route waypoint is not enough: the actual object must be in
			# reach, clear and the actor must remain still throughout the hold.
			return {"kind": data.task, "index": int(data.get("trial_index", -1))}
	return {}


func step(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or not selection.live or game.get_tree().paused:
		return
	for actor: EyesSurvivor in game.actors:
		var id: int = actor.get_instance_id()
		if not _valid(actor):
			state.interrupt_actor(id)
			apparatus.show_carry(actor, -1)
			continue
		if _active("silent", "light"):
			state.update_light_charge(id, delta, in_refuge(actor))
		apparatus.show_carry(actor, state.carried_cell(id))
		var command: Dictionary = {}
		if actor == game.player and game.mode == "survivor":
			var rescue_priority: bool = game.squad_world != null and (game.squad_world.player_rescuing or game.squad_world.nearby_downed(actor) != null)
			if Input.is_action_pressed("interact") and not game.echo_open and not rescue_priority:
				command = host.nearest(actor)
		else:
			command = _bot_hold(actor)
		var kind: String = str(command.get("kind", ""))
		var index: int = int(command.get("index", -1))
		var light_valid: bool = kind == "light_align" and index >= 0 and index < 3 and _active("silent", "light") and _still(actor) and _within(actor, Props.LAMP_POSITIONS[index])
		var strings_valid: bool = kind == "strings_cut" and index >= 0 and index < 4 and _active("echoes", "strings") and _still(actor) and _within(actor, Props.ROPE_POSITIONS[index])
		var lit: bool = state.update_light_hold(id, index, delta, light_valid)
		var cut: bool = state.update_strings_hold(id, index, delta, strings_valid)
		if lit or cut:
			for data: Dictionary in game.bots:
				if data.actor == actor:
					data.think = 0.0
					data.action_time = 0.0
					# A banked stage is a distinct operation. Bots physically return
					# to the new clue instead of keeping a cut held across stages.
					if cut:
						data.strings_seen_stage = -1
						data.task = "strings_observe"
						data.target = Props.STRINGS_DESK + Vector3(0, 0, 2.2)
						data.repath = 0.0
						state.interrupt_actor(id)


func hint(actor: EyesSurvivor) -> String:
	if not _valid(actor):
		return ""
	var id: int = actor.get_instance_id()
	var option: Dictionary = host.nearest(actor)
	var kind: String = str(option.get("kind", ""))
	if kind == "light_align" and state.light_holds.has(id):
		return "ALIGNING REFUGE %d / %.1f of 2 seconds / lantern %.0f%%" % [int(option.index) + 1, float(state.light_holds[id].get("progress", 0.0)), state.charge_for(id)]
	if kind == "strings_cut" and state.strings_holds.has(id):
		return "CUTTING ROPE %d / %.1f of 2 seconds / moving or damage interrupts" % [int(option.index) + 1, float(state.strings_holds[id].get("progress", 0.0))]
	if _active("silent", "light") and state.carried_cell(id) >= 0 and option.is_empty():
		return "CELL %d → REFUGE %d / LANTERN %.0f%% / G returns cell" % [state.carried_cell(id) + 1, state.carried_cell(id) + 1, state.charge_for(id)]
	return ""


func _operator_available(id: int, current: int) -> bool:
	if current == 0 or current == id:
		return true
	for actor: EyesSurvivor in game.actors:
		if actor.get_instance_id() == current:
			return not _valid(actor)
	return true


func nearest_refuge(actor: EyesSurvivor) -> Vector3:
	var best: Vector3 = Props.BASE_REFUGE
	var distance: float = actor.global_position.distance_to(best)
	for index: int in range(3):
		if state.light_lit[index] and actor.global_position.distance_to(Props.LAMP_POSITIONS[index]) < distance:
			best = Props.LAMP_POSITIONS[index]
			distance = actor.global_position.distance_to(best)
	return best + Vector3(0, 0, 2.1)


func cargo_goal(data: Dictionary) -> bool:
	var actor: EyesSurvivor = data.actor
	var id: int = actor.get_instance_id()
	var cell: int = state.carried_cell(id)
	if cell < 0:
		return false
	var recharging: bool = data.task == "light_recharge" and state.charge_for(id) < 90.0
	if state.charge_for(id) < 25.0 or recharging:
		return host._assign(data, "light_recharge", nearest_refuge(actor))
	return host._assign(data, "light_align", Props.LAMP_POSITIONS[cell] + Vector3(0, 0, 0.9), cell)


func assign_slot(data: Dictionary, slot: String) -> bool:
	var actor: EyesSurvivor = data.actor
	var id: int = actor.get_instance_id()
	match selection.trial_for_slot(slot):
		"light":
			if not _empty_hands(actor):
				return false
			if state.charge_for(id) < 60.0:
				return host._assign(data, "light_recharge", nearest_refuge(actor))
			var chosen: int = -1
			var distance: float = INF
			for index: int in range(3):
				if not state.cell_available(index):
					continue
				var reserved: bool = false
				for other: Dictionary in game.bots:
					if other != data and other.task == "light_pickup" and int(other.get("trial_index", -1)) == index and _valid(other.actor):
						reserved = true
				if not reserved and actor.global_position.distance_to(Props.CELL_POSITIONS[index]) < distance:
					distance = actor.global_position.distance_to(Props.CELL_POSITIONS[index])
					chosen = index
			if chosen >= 0:
				return host._assign(data, "light_pickup", Props.CELL_POSITIONS[chosen] + Vector3(0, 0, 0.9), chosen)
		"strings":
			if not _operator_available(id, strings_operator):
				return false
			strings_operator = id
			if int(data.get("strings_seen_stage", -1)) != state.strings_stage:
				return host._assign(data, "strings_observe", Props.STRINGS_DESK + Vector3(0, 0, 2.2))
			var answer: int = state.strings_answer()
			if answer >= 0:
				return host._assign(data, "strings_cut", Props.ROPE_POSITIONS[answer] + Vector3(0, 0, 0.85), answer)
		"chimes":
			if not _operator_available(id, chimes_operator):
				return false
			chimes_operator = id
			if int(data.get("chimes_seen_phrase", -1)) != state.chimes_phrase:
				return host._assign(data, "chimes_observe", Props.CHIMES_DESK + Vector3(0, 0, 2.2))
			if state.chimes_phrase < 2:
				var bell: int = state.chimes_sequences[state.chimes_phrase][state.chimes_index]
				var task: String = "chimes_strike" if state.damper == bell else "chimes_damp"
				return host._assign(data, task, Props.BELL_POSITIONS[bell] + Vector3(0, 0, 0.85), bell)
	return false


func bot_arrived(data: Dictionary, _delta: float) -> void:
	var actor: EyesSurvivor = data.actor
	var task: String = data.task
	if task == "strings_observe":
		if int(data.get("strings_observing_stage", -1)) != state.strings_stage:
			data.strings_observing_stage = state.strings_stage
			data.action_time = 0.0
		if not perform(actor, "strings_read"):
			data.action_time = 0.0
		elif data.action_time >= OBSERVATION_SECONDS:
			data.strings_seen_stage = state.strings_stage
			data.think = 0.0
			data.action_time = 0.0
			state.interrupt_actor(actor.get_instance_id())
		return
	if task == "chimes_observe":
		if int(data.get("chimes_observing_phrase", -1)) != state.chimes_phrase:
			data.chimes_observing_phrase = state.chimes_phrase
			data.action_time = 0.0
		if not perform(actor, "chimes_read"):
			data.action_time = 0.0
		elif data.action_time >= OBSERVATION_SECONDS:
			data.chimes_seen_phrase = state.chimes_phrase
			data.think = 0.0
			data.action_time = 0.0
		return
	if task == "light_recharge":
		if state.charge_for(actor.get_instance_id()) >= 90.0:
			data.think = 0.0
		return
	if task in ["light_pickup", "chimes_damp", "chimes_strike"] and data.action_time >= 0.4:
		if task.begins_with("chimes_"):
			if state.chimes_phrase >= 2 or int(data.get("chimes_seen_phrase", -1)) != state.chimes_phrase:
				data.think = 0.0
				data.action_time = 0.0
				return
			if int(data.get("trial_index", -1)) != int(state.chimes_sequences[state.chimes_phrase][state.chimes_index]):
				data.think = 0.0
				data.action_time = 0.0
				return
		if perform(actor, task, int(data.get("trial_index", 0))):
			data.think = 0.0
		data.action_time = 0.0


func event_position(payload: Dictionary) -> Vector3:
	var bell: int = int(payload.get("bell", -1))
	if bell >= 0 and bell < 4:
		return Props.BELL_POSITIONS[bell]
	var id: int = int(payload.get("actor_id", 0))
	for actor: EyesSurvivor in game.actors:
		if actor.get_instance_id() == id:
			return actor.global_position
	return Props.STRINGS_DESK
