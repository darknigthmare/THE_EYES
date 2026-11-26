class_name EyesTrialApparatus
extends Node3D
## Physical, spatial presentation for the three Second Observance trials.
## Match rules live in TrialSet; this node never awards progress by itself.

const ThirdApparatus = preload("res://scripts/third_apparatus.gd")

const RELIC_NAMES: Array[String] = ["ORB", "SPIRE", "CUBE", "RING", "CROWN", "DIAMOND"]
const RELIC_POSITIONS: Array[Vector3] = [Vector3(-22,0,10),Vector3(-17,0,14),Vector3(-12,0,11),Vector3(12,0,11),Vector3(17,0,14),Vector3(22,0,10)]
const CRADLE_POSITIONS: Array[Vector3] = [Vector3(-21.2,0,-12),Vector3(-19.5,0,-9.2),Vector3(-15.5,0,-9.2),Vector3(-13.2,0,-12)]
const VAULT_DESK: Vector3 = Vector3(-17,0,-13)
const RITUAL_CENTER: Vector3 = Vector3(17,0,-13)
const EMBER_POSITION: Vector3 = Vector3(17,0,-9.3)
const VESSEL_POSITIONS: Array[Vector3] = [Vector3(13.2,0,-11),Vector3(13.5,0,-15.4),Vector3(17,0,-17.3),Vector3(20.5,0,-15.4),Vector3(20.8,0,-11)]
const CLOCK_CENTER: Vector3 = Vector3(0,0,14)
const CLOCK_LEVERS: Array[Vector3] = [Vector3(-3.5,0,16),Vector3(0,0,18.2),Vector3(3.5,0,16)]
const TRIAL_NAMES: Dictionary = {"silent":"SILENT COUNTDOWN","echoes":"TRIAL OF THE ECHOES","relay":"CLOCKWORK RELAY","vault":"THE MEMORY VAULT","ritual":"THE RITUAL CIRCLE","clock":"THE CLOCK ROOM","light":"LIGHT IN THE DARKNESS","strings":"STRINGS OF DESPAIR","chimes":"CHIMES OF DOOM"}

var arena: EyesArena
var state
var relic_nodes: Array[Node3D] = []
var cradle_objects: Array[Node3D] = []
var vessel_flames: Array[MeshInstance3D] = []
var clock_hands: Array[Node3D] = []
var clock_readout: Label3D
var vault_reference: Label3D
var ritual_reference: Label3D
var ember: Node3D
var hold_ring: MeshInstance3D
var reveal_left: float = 0.0
var age: float = 0.0
var _last_vault: String = ""
var _last_ritual: String = ""
var _last_clock: String = ""
var third: ThirdApparatus

func configure(p_arena: EyesArena, p_state) -> void:
	arena = p_arena
	state = p_state
	for child in get_children():
		remove_child(child)
		child.queue_free()
	relic_nodes.clear()
	cradle_objects.clear()
	vessel_flames.clear()
	clock_hands.clear()
	clock_readout = null
	vault_reference = null
	ritual_reference = null
	ember = null
	hold_ring = null
	reveal_left = 0.0
	_last_vault = ""
	_last_ritual = ""
	_last_clock = ""
	if state.trial_for_slot("silent") == "vault":
		_build_vault()
	if state.trial_for_slot("echoes") == "ritual":
		_build_ritual()
	if state.trial_for_slot("relay") == "clock":
		_build_clock()
	third = ThirdApparatus.new()
	add_child(third)
	third.configure(arena,state)
	refresh(0.0)

func _root_at(point: Vector3) -> Node3D:
	var node = Node3D.new()
	node.position = point
	add_child(node)
	return node

func _relic(index: int, parent: Node3D, height: float = 1.15) -> Node3D:
	var object = Node3D.new()
	object.position.y = height
	parent.add_child(object)
	var mat: Material = [arena.mats.cyan,arena.mats.amber,arena.mats.violet,arena.mats.bone,arena.mats.brass,arena.mats.red][index]
	match index:
		0:
			arena.sphere(Vector3.ZERO,0.32,mat,object)
		1:
			var spire = arena.cylinder(Vector3.ZERO,0.3,0.8,mat,object)
			(spire.mesh as CylinderMesh).top_radius = 0.025
		2:
			arena.box(Vector3.ZERO,Vector3(0.53,0.53,0.53),mat,false,object)
		3:
			var hoop = arena.ring(Vector3.ZERO,0.25,0.39,mat,object)
			hoop.rotation_degrees.x = 90
		4:
			arena.cylinder(Vector3(0,-0.12,0),0.32,0.16,mat,object)
			for i in range(5):
				var angle = i*TAU/5
				var tooth = arena.cylinder(Vector3(cos(angle)*0.25,0.12,sin(angle)*0.25),0.07,0.45,mat,object)
				(tooth.mesh as CylinderMesh).top_radius = 0.01
		5:
			var gem = arena.box(Vector3.ZERO,Vector3(0.45,0.45,0.45),mat,false,object)
			gem.rotation_degrees = Vector3(0,45,45)
	return object

func _build_vault() -> void:
	for i in range(RELIC_POSITIONS.size()):
		var shelf = _root_at(RELIC_POSITIONS[i])
		arena.cylinder(Vector3(0,0.4,0),0.58,0.8,arena.mats.dark,shelf)
		arena.ring(Vector3(0,0.83,0),0.4,0.58,arena.mats.brass,shelf)
		relic_nodes.append(_relic(i,shelf))
		arena.inscription("%02d  /  %s" % [i+1,RELIC_NAMES[i]],Vector3(0,2.0,0),Color("d6d8ca"),20,shelf)
	for i in range(4):
		var cradle = _root_at(CRADLE_POSITIONS[i])
		arena.cylinder(Vector3(0,0.35,0),0.68,0.7,arena.mats.dark,cradle)
		arena.ring(Vector3(0,0.76,0),0.4,0.6,arena.mats.cyan,cradle)
		arena.inscription("CRADLE %d" % [i+1],Vector3(0,1.3,0),Color("b9e2d3"),14,cradle)
		var object = _relic(state.vault_targets[i],cradle)
		object.hide()
		cradle_objects.append(object)
	vault_reference = arena.inscription("",VAULT_DESK+Vector3(0,4.0,0.15),Color("d4eddf"),18,self)

func _build_ritual() -> void:
	hold_ring = arena.ring(RITUAL_CENTER+Vector3(0,0.11,0),2.65,2.82,arena.mats.violet,self)
	for i in range(5):
		var vessel = _root_at(VESSEL_POSITIONS[i])
		arena.cylinder(Vector3(0,0.65,0),0.32,1.3,arena.mats.brass,vessel)
		arena.ring(Vector3(0,1.32,0),0.27,0.46,arena.mats.bone,vessel)
		var flame = arena.sphere(Vector3(0,1.5,0),0.23,arena.mats.dark,vessel)
		flame.scale.y = 1.7
		vessel_flames.append(flame)
		arena.inscription("VESSEL %d" % [i+1],Vector3(0,2.0,0),Color("dcd2e7"),16,vessel)
	var cradle = _root_at(EMBER_POSITION)
	arena.cylinder(Vector3(0,0.4,0),0.5,0.8,arena.mats.dark,cradle)
	ember = Node3D.new()
	cradle.add_child(ember)
	arena.sphere(Vector3(0,1.0,0),0.23,arena.mats.amber,ember)
	arena.ring(Vector3(0,1.0,0),0.3,0.4,arena.mats.brass,ember)
	arena.inscription("SHARED EMBER",Vector3(0,1.3,0),Color("e7c99d"),14,cradle)
	ritual_reference = arena.inscription("",RITUAL_CENTER+Vector3(0,4.0,0.15),Color("e0cfeb"),19,self)

func _build_clock() -> void:
	var face = _root_at(CLOCK_CENTER+Vector3(0,2.9,-0.1))
	var rim = arena.ring(Vector3.ZERO,1.3,1.44,arena.mats.brass,face)
	rim.rotation_degrees.x = 90
	for i in range(6):
		var angle = -i*TAU/6.0
		arena.inscription(str(i),Vector3(-sin(angle)*1.62,cos(angle)*1.62,0.02),Color("d9c9ab"),22,face)
	var colors = [arena.mats.cyan,arena.mats.amber,arena.mats.violet]
	for i in range(3):
		var pivot = Node3D.new()
		pivot.position.z = 0.08+i*0.08
		face.add_child(pivot)
		var length_value = 1.12-i*0.22
		arena.box(Vector3(0,length_value/2,0),Vector3(0.09+i*0.025,length_value,0.06),colors[i],false,pivot)
		clock_hands.append(pivot)
		var lever = _root_at(CLOCK_LEVERS[i])
		arena.cylinder(Vector3(0,0.35,0),0.55,0.7,arena.mats.dark,lever)
		arena.box(Vector3(0,1.0,0),Vector3(0.12,1.0,0.12),arena.mats.brass,false,lever)
		arena.sphere(Vector3(0,1.5,0),0.2,colors[i],lever)
		arena.inscription("%s  /  %s" % [["A","B","C"][i],["A+B","B+C","C+A"][i]],Vector3(0,1.4,0.7),Color("d7d6c7"),16,lever)
	clock_readout = arena.inscription("",CLOCK_CENTER+Vector3(0,5.1,0),Color("dfd5b8"),21,self)

func show_vault_reference() -> void:
	if state != null and state.trial_for_slot("silent") == "vault":
		reveal_left = 8.0
		refresh(0.0)

func _process(delta: float) -> void:
	if state == null or get_tree().paused:
		return
	refresh(delta)

func refresh(delta: float) -> void:
	age += delta
	if third != null:
		third.refresh(delta)
	reveal_left = maxf(0.0,reveal_left-delta)
	if vault_reference != null:
		var value = "[ E ]  REPLAY THE FOUR RELICS\nG drops a carried relic safely"
		if reveal_left > 0:
			var parts: Array[String] = []
			for i in range(4):
				parts.append("%d  %s" % [i+1,RELIC_NAMES[state.vault_targets[i]]])
			value = "%s   /   %s\n%s   /   %s\nMEMORIZE FOUR CRADLES" % parts
		if value != _last_vault:
			vault_reference.text = value
			_last_vault = value
		for i in range(relic_nodes.size()):
			relic_nodes[i].visible = state.relic_available(i)
			relic_nodes[i].rotation.y = age*0.35
		for i in range(cradle_objects.size()):
			cradle_objects[i].visible = state.vault_cradles[i] >= 0
	if ritual_reference != null:
		var parts: Array[String] = []
		for id in state.ritual_sequence:
			parts.append(str(id+1))
		var value = "ORDER  "+" → ".join(parts)+"\nPAIRS BANK / FINISH INSIDE THE RING"
		if value != _last_ritual:
			ritual_reference.text = value
			_last_ritual = value
		for i in range(5):
			vessel_flames[i].material_override = arena.mats.amber if state.ritual_vessel_lit(i) else arena.mats.dark
		ember.visible = state.ember_owner == 0 and state.ritual_index < 5
		hold_ring.material_override = arena.mats.cyan if state.ritual_index >= 5 else arena.mats.violet
	if clock_readout != null:
		var value = "TARGET   A %d   B %d   C %d\nNOW      A %d   B %d   C %d" % [state.clock_target[0],state.clock_target[1],state.clock_target[2],state.clock_hands[0],state.clock_hands[1],state.clock_hands[2]]
		if value != _last_clock:
			clock_readout.text = value
			_last_clock = value
		for i in range(3):
			clock_hands[i].rotation.z = lerp_angle(clock_hands[i].rotation.z,-state.clock_hands[i]*TAU/6.0,minf(1.0,delta*8.0))
