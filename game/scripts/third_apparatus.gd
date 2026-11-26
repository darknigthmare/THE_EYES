class_name EyesThirdApparatus
extends Node3D
## Readable physical apparatus for the Third Observance prototype subsets.
## Meshes display domain state; they never award objective progress.

const BASE_REFUGE: Vector3 = Vector3(-17, 0, -13)
const CELL_POSITIONS: Array[Vector3] = [Vector3(-22, 0, -17), Vector3(-21, 0, 4), Vector3(-14, 0, 14)]
const LAMP_POSITIONS: Array[Vector3] = [Vector3(-23, 0, -10), Vector3(-23, 0, 2), Vector3(-21, 0, 12)]
const STRINGS_DESK: Vector3 = Vector3(17, 0, -13)
const ROPE_POSITIONS: Array[Vector3] = [Vector3(13.5, 0, -10), Vector3(15.8, 0, -9), Vector3(18.2, 0, -9), Vector3(20.5, 0, -10)]
const CHIMES_DESK: Vector3 = Vector3(0, 0, 14)
const BELL_POSITIONS: Array[Vector3] = [Vector3(-4.5, 0, 14), Vector3(-2, 0, 18), Vector3(2, 0, 18), Vector3(4.5, 0, 14)]
const TAG_NAMES: Array[String] = ["CIRCLE", "CRESCENT", "TRIANGLE", "DIAMOND"]
const BELL_NAMES: Array[String] = ["CROWN", "SPIRE", "HALO", "VESSEL"]

var arena: EyesArena
var state
var selection
var age: float = 0.0
var cell_nodes: Array[Node3D] = []
var lamp_cores: Array[MeshInstance3D] = []
var lamp_rings: Array[MeshInstance3D] = []
var lamp_lights: Array[OmniLight3D] = []
var lamp_labels: Array[Label3D] = []
var light_board: Label3D
var strings_board: Label3D
var ropes: Array[MeshInstance3D] = []
var rope_tags: Array[Node3D] = []
var rope_labels: Array[Label3D] = []
var last_rope_layout: Array[int] = []
var cage: Node3D
var catches: Array[MeshInstance3D] = []
var chimes_board: Label3D
var bell_pivots: Array[Node3D] = []
var bell_shutters: Array[Node3D] = []
var bell_labels: Array[Label3D] = []
var bell_swing: Array[float] = [0.0, 0.0, 0.0, 0.0]
var carry_nodes: Dictionary = {}


func configure(p_arena: EyesArena, p_selection) -> void:
	arena = p_arena
	selection = p_selection
	state = p_selection.third
	name = "ThirdObservanceApparatus"
	if selection.trial_for_slot("silent") == "light":
		_build_light()
	if selection.trial_for_slot("echoes") == "strings":
		_build_strings()
	if selection.trial_for_slot("relay") == "chimes":
		_build_chimes()


func _root(point: Vector3, label_name: String = "") -> Node3D:
	var node: Node3D = Node3D.new()
	node.position = point
	if not label_name.is_empty():
		node.name = label_name
	add_child(node)
	return node


func _label(value: String, point: Vector3, color: Color, size_value: int, parent: Node3D) -> Label3D:
	var label: Label3D = arena.inscription(value, point, color, size_value, parent)
	label.pixel_size = 0.009
	label.outline_size = 3
	return label


func _lantern(parent: Node3D, index: int, height: float = 1.0) -> Node3D:
	var lantern: Node3D = Node3D.new()
	lantern.name = "CellLantern"
	lantern.position.y = height
	parent.add_child(lantern)
	arena.cylinder(Vector3(0, -0.28, 0), 0.28, 0.12, arena.mats.brass, lantern)
	arena.cylinder(Vector3(0, 0.28, 0), 0.28, 0.12, arena.mats.brass, lantern)
	var core: MeshInstance3D = arena.sphere(Vector3.ZERO, 0.18, arena.mats.amber, lantern)
	core.scale.y = 1.35
	for side: int in range(4):
		var angle: float = side * TAU / 4.0
		arena.cylinder(Vector3(cos(angle) * 0.22, 0, sin(angle) * 0.22), 0.035, 0.56, arena.mats.brass, lantern)
	var handle: MeshInstance3D = arena.ring(Vector3(0, 0.48, 0), 0.13, 0.17, arena.mats.brass, lantern)
	handle.rotation_degrees.x = 90
	var identity: Label3D = _label(str(index + 1), Vector3(0, 0.0, 0.28), Color("fff1c7"), 21, lantern)
	identity.name = "CellIdentity"
	return lantern


func _build_light() -> void:
	var base: Node3D = _root(BASE_REFUGE, "PermanentRefuge")
	arena.ring(Vector3(0, 0.09, 0), 2.9, 3.0, arena.mats.cyan, base)
	_label("PERMANENT REFUGE\nRECHARGE YOUR LANTERN HERE", Vector3(0, 2.2, 1.3), Color("b0e8d9"), 16, base)
	light_board = _label("", Vector3(0, 3.75, 0), Color("e4dfc8"), 18, base)
	for index: int in range(3):
		var shelf: Node3D = _root(CELL_POSITIONS[index], "PowerCell%d" % [index + 1])
		arena.cylinder(Vector3(0, 0.33, 0), 0.46, 0.66, arena.mats.dark, shelf)
		arena.ring(Vector3(0, 0.7, 0), 0.34, 0.46, arena.mats.brass, shelf)
		cell_nodes.append(_lantern(shelf, index, 1.15))
		_label("CELL %d → REFUGE %d" % [index + 1, index + 1], Vector3(0, 2.15, 0), Color("e7cc9c"), 15, shelf)
		var lamp: Node3D = _root(LAMP_POSITIONS[index], "RefugeLamp%d" % [index + 1])
		arena.cylinder(Vector3(0, 0.18, 0), 0.65, 0.36, arena.mats.dark, lamp)
		arena.cylinder(Vector3(0, 1.1, 0), 0.12, 2.0, arena.mats.brass, lamp)
		arena.cylinder(Vector3(0, 2.2, 0), 0.4, 0.15, arena.mats.brass, lamp)
		var top: MeshInstance3D = arena.cylinder(Vector3(0, 3.0, 0), 0.55, 0.4, arena.mats.brass, lamp)
		(top.mesh as CylinderMesh).top_radius = 0.05
		for side: int in range(4):
			var angle: float = side * TAU / 4.0
			arena.cylinder(Vector3(cos(angle) * 0.32, 2.55, sin(angle) * 0.32), 0.035, 0.7, arena.mats.brass, lamp)
		lamp_cores.append(arena.sphere(Vector3(0, 2.55, 0), 0.26, arena.mats.dark, lamp))
		lamp_rings.append(arena.ring(Vector3(0, 0.1, 0), 2.88, 3.0, arena.mats.dark, lamp))
		lamp_lights.append(arena.light(Vector3(0, 2.5, 0), Color("90e1bf"), 0, 5.5, lamp))
		lamp_labels.append(_label("", Vector3(0, 3.65, 0), Color("d8e5d7"), 16, lamp))


func _shape_tag(index: int, parent: Node3D) -> Node3D:
	var tag: Node3D = Node3D.new()
	parent.add_child(tag)
	match index:
		0:
			var ring: MeshInstance3D = arena.ring(Vector3.ZERO, 0.19, 0.28, arena.mats.bone, tag)
			ring.rotation_degrees.x = 90
		1:
			for side: int in range(12):
				var angle: float = (-135.0 + side * 22.5) * PI / 180.0
				var bar: MeshInstance3D = arena.box(Vector3(sin(angle) * 0.23, cos(angle) * 0.23, 0), Vector3(0.07, 0.12, 0.07), arena.mats.bone, false, tag)
				bar.rotation.z = -angle + PI / 2
		2:
			for side: int in range(3):
				var bar: MeshInstance3D = arena.box(Vector3.ZERO, Vector3(0.07, 0.52, 0.07), arena.mats.bone, false, tag)
				bar.position = Vector3(sin(side * TAU / 3.0) * 0.16, cos(side * TAU / 3.0) * 0.16, 0)
				bar.rotation.z = -side * TAU / 3.0 + PI / 2
		3:
			for side: int in range(4):
				var bar: MeshInstance3D = arena.box(Vector3.ZERO, Vector3(0.07, 0.46, 0.07), arena.mats.bone, false, tag)
				bar.position = Vector3(sin(side * TAU / 4.0) * 0.23, cos(side * TAU / 4.0) * 0.23, 0)
				bar.rotation.z = -side * TAU / 4.0 + PI / 2
			tag.rotation.z = PI / 4
	return tag


func _build_strings() -> void:
	var frame: Node3D = _root(STRINGS_DESK, "SafetyFrame")
	for x: float in [-4.0, 4.0]:
		arena.box(Vector3(x, 2.8, -0.4), Vector3(0.24, 5.6, 0.24), arena.mats.brass, false, frame)
	arena.box(Vector3(0, 5.6, -0.4), Vector3(8.3, 0.28, 0.3), arena.mats.brass, false, frame)
	strings_board = _label("", Vector3(0, 4.7, 0.6), Color("e0d1ed"), 18, frame)
	cage = Node3D.new()
	cage.position = Vector3(0, 3.0, -0.4)
	frame.add_child(cage)
	for height: float in [0.0, 1.3]:
		arena.box(Vector3(0, height, 0), Vector3(2.5, 0.12, 1.65), arena.mats.dark, false, cage)
		arena.box(Vector3(0, height + 0.075, 0), Vector3(2.6, 0.025, 1.75), arena.mats.brass, false, cage)
	for x: float in [-1.2, 1.2]:
		for z: float in [-0.75, 0.75]:
			arena.cylinder(Vector3(x, 0.65, z), 0.045, 1.3, arena.mats.brass, cage)
	for index: int in range(3):
		catches.append(arena.box(Vector3(-0.65 + index * 0.65, 0.35, 0.9), Vector3(0.35, 0.2, 0.18), arena.mats.dark, false, frame))
	for index: int in range(4):
		var control: Node3D = _root(ROPE_POSITIONS[index], "RopeControl%d" % [index + 1])
		arena.cylinder(Vector3(0, 0.32, 0), 0.36, 0.64, arena.mats.dark, control)
		var rope: MeshInstance3D = arena.cylinder(Vector3(0, 2.8, 0), 0.065, 4.7, arena.mats.bone, control)
		ropes.append(rope)
		var shape: int = state.strings_layout[index]
		var tag: Node3D = _shape_tag(shape, control)
		tag.position = Vector3(0, 1.4, 0.15)
		rope_tags.append(tag)
		rope_labels.append(_label("%d  %s" % [index + 1, TAG_NAMES[shape]], Vector3(0, 1.95, 0.25), Color("dfd2e8"), 14, control))
		_label("HOLD E TO CUT", Vector3(0, 0.8, 0.25), Color("aebbc5"), 12, control)
	last_rope_layout.assign(state.strings_layout)


func _build_chimes() -> void:
	var console: Node3D = _root(CHIMES_DESK, "ChimesScore")
	chimes_board = _label("", Vector3(0, 3.7, 0.2), Color("e7d2ae"), 19, console)
	for index: int in range(4):
		var root_node: Node3D = _root(BELL_POSITIONS[index], "Bell%d" % [index + 1])
		for x: float in [-0.65, 0.65]:
			arena.box(Vector3(x, 1.65, 0), Vector3(0.13, 3.3, 0.16), arena.mats.brass, false, root_node)
		arena.box(Vector3(0, 3.25, 0), Vector3(1.5, 0.15, 0.25), arena.mats.brass, false, root_node)
		var pivot: Node3D = Node3D.new()
		pivot.position = Vector3(0, 2.8, 0)
		root_node.add_child(pivot)
		bell_pivots.append(pivot)
		var bell: MeshInstance3D = arena.cylinder(Vector3(0, -0.45, 0), 0.47, 0.8, arena.mats.brass, pivot)
		(bell.mesh as CylinderMesh).top_radius = 0.18 + index * 0.035
		arena.ring(Vector3(0, -0.85, 0), 0.42, 0.52, arena.mats.bone, pivot)
		arena.sphere(Vector3(0, -0.9, 0), 0.1, arena.mats.dark, pivot)
		var icon: Node3D = _shape_tag(index, root_node)
		icon.position = Vector3(0, 1.5, 0.3)
		var shutter: Node3D = Node3D.new()
		shutter.position = Vector3(0, 2.4, -0.1)
		root_node.add_child(shutter)
		arena.box(Vector3(-0.62, 0, 0), Vector3(0.16, 1.15, 0.85), arena.mats.dark, false, shutter)
		arena.box(Vector3(0.62, 0, 0), Vector3(0.16, 1.15, 0.85), arena.mats.dark, false, shutter)
		arena.box(Vector3(0, 0, -0.42), Vector3(1.4, 1.15, 0.15), arena.mats.dark, false, shutter)
		bell_shutters.append(shutter)
		bell_labels.append(_label("", Vector3(0, 3.75, 0), Color("edddbe"), 15, root_node))


func strike(index: int) -> void:
	if index >= 0 and index < 4:
		bell_swing[index] = 1.0


func show_carry(actor: EyesSurvivor, cell: int) -> void:
	var id: int = actor.get_instance_id()
	if cell < 0:
		if carry_nodes.has(id):
			carry_nodes[id].hide()
		return
	if not carry_nodes.has(id):
		var node: Node3D = _root(Vector3.ZERO, "CarriedLight%d" % id)
		_lantern(node, cell, 0.0)
		node.scale = Vector3.ONE * 0.6
		carry_nodes[id] = node
	var visual: Node3D = carry_nodes[id]
	var identity: Label3D = visual.get_node("CellLantern/CellIdentity")
	var number: String = str(cell + 1)
	if identity.text != number:
		identity.text = number
	visual.show()
	visual.global_position = actor.global_position + actor.global_basis * Vector3(0.48, 0.85, -0.4)
	visual.rotation.y = actor.rotation.y


func refresh(delta: float) -> void:
	age += maxf(0.0, delta)
	if light_board != null:
		light_board.text = "THREE CELLS / THREE REFUGES\nMATCH THEIR NUMBERS / HOLD E TWO SECONDS\nLANTERN REFILLS IN PERMANENT OR LIT REFUGES"
		for index: int in range(3):
			cell_nodes[index].visible = state.cell_available(index)
			cell_nodes[index].rotation.y = sin(age * 0.8 + index) * 0.12
			var lit: bool = state.light_lit[index]
			lamp_cores[index].material_override = arena.mats.cyan if lit else arena.mats.dark
			lamp_rings[index].material_override = arena.mats.cyan if lit else arena.mats.dark
			lamp_lights[index].light_energy = 2.0 if lit else 0.0
			lamp_labels[index].text = "REFUGE %d\n%s" % [index + 1, "LIT / RECHARGE" if lit else "NEEDS CELL %d" % [index + 1]]
	if strings_board != null:
		strings_board.text = "THREE SAFETY CATCHES LOCKED" if state.strings_stage >= 3 else "STAGE %d / %s\nLEFT = ROPES 1–2 / RIGHT = ROPES 3–4\nCURVED: CIRCLE, CRESCENT / ANGULAR: TRIANGLE, DIAMOND" % [state.strings_stage + 1, state.strings_clue()]
		if state.strings_cooldown > 0.0:
			strings_board.text += "\nSAFETY CATCH / %.1f s" % state.strings_cooldown
		cage.position.y = lerpf(cage.position.y, 3.0 - state.strings_stage * 0.45, minf(1.0, maxf(0.0, delta) * 3.5))
		for index: int in range(3):
			catches[index].material_override = arena.mats.cyan if index < state.strings_stage else arena.mats.dark
		if last_rope_layout != state.strings_layout:
			for index: int in range(4):
				var previous: Node3D = rope_tags[index]
				var parent: Node3D = previous.get_parent()
				parent.remove_child(previous)
				previous.queue_free()
				var tag: Node3D = _shape_tag(state.strings_layout[index], parent)
				tag.position = Vector3(0, 1.4, 0.15)
				rope_tags[index] = tag
				rope_labels[index].text = "%d  %s" % [index + 1, TAG_NAMES[state.strings_layout[index]]]
			last_rope_layout.assign(state.strings_layout)
	if chimes_board != null:
		if state.chimes_phrase >= 2:
			chimes_board.text = "TWO PHRASES LOCKED\nTHE CHIMES FALL SILENT"
		else:
			var notes: Array[String] = []
			for bell: int in state.chimes_sequences[state.chimes_phrase]:
				notes.append(str(bell + 1))
			chimes_board.text = "PHRASE %d / %s\n%d OF 4 NOTES / FIRST PHRASE BANKS\nE STRIKES / R DAMPENS ONE BELL" % [state.chimes_phrase + 1, " → ".join(notes), state.chimes_index]
	for index: int in range(bell_pivots.size()):
		bell_swing[index] = maxf(0.0, bell_swing[index] - delta * 1.8)
		bell_pivots[index].rotation.z = sin(age * 18.0) * bell_swing[index] * 0.22
		bell_shutters[index].visible = state.damper == index
		bell_labels[index].text = "BELL %d / %s\n%s" % [index + 1, BELL_NAMES[index], "DAMPED" if state.damper == index else "LOUD"]
