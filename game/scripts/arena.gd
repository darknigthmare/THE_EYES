class_name EyesArena
extends Node3D
## Original, reproducible greybox art. All playable geometry has real collision.

const SOCKETS: Array[Vector3] = [Vector3(0,8,-21),Vector3(23,8,0),Vector3(0,8,21),Vector3(-23,8,0)]
const STATIONS: Dictionary = {"silent":Vector3(-17,0,-13),"echoes":Vector3(17,0,-13),"relay":Vector3(0,0,14)}
const MOTE_POSITIONS: Array[Vector3] = [Vector3(-21,0,9),Vector3(20,0,9),Vector3(14,0,-3)]
const TRAP_POSITIONS: Array[Vector3] = [Vector3(-14,0,-13),Vector3(14,0,-13),Vector3(-5,0,14),Vector3(5,0,14),Vector3(-16,0,5),Vector3(16,0,5),Vector3(-7,0,-18),Vector3(7,0,-18)]
const EXIT_POSITION: Vector3 = Vector3(0,0,-22)
const SPAWN: Vector3 = Vector3(0,0,20)

var mats: Dictionary = {}
var eyes: Array[Node3D] = []
var iris_materials: Array[StandardMaterial3D] = []
var stations: Dictionary = {}
var motes: Array[Node3D] = []
var trap_meshes: Array[MeshInstance3D] = []
var trap_materials: Array[StandardMaterial3D] = []
var trap_spikes: Array[Node3D] = []
var portal: MeshInstance3D
var portal_material: StandardMaterial3D
var relay_wheel: Node3D
var echo_lights: Array[StandardMaterial3D] = []
var beacon_lights: Dictionary = {}
var eye_beam: MeshInstance3D
var elapsed: float = 0.0

func _ready() -> void:
	_materials()
	_environment()
	_architecture()
	_build_stations()
	_build_eyes()
	_build_traps()
	_build_motes()
	_build_exit()
	set_socket(0)

func _materials() -> void:
	mats.stone = material(Color("303d44"),0.88)
	mats.dark = material(Color("17232c"),0.8)
	mats.floor = material(Color("28363b"),0.7)
	mats.bone = material(Color("b3b09b"),0.35)
	mats.brass = material(Color("ad8c53"),0.28,0.65)
	mats.black = material(Color("090e13"),0.15)
	mats.cyan = material(Color("6bd9c5"),0.28,0.2,1.5)
	mats.amber = material(Color("e0ac5a"),0.35,0.2,1.2)
	mats.red = material(Color("ed7869"),0.45,0.1,1.0)
	mats.violet = material(Color("ad99cf"),0.4,0.2,1.2)

static func material(color: Color, roughness: float = 0.7, metallic: float = 0.0, emission: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if emission > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

func _environment() -> void:
	var world = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0b131c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8bafbd")
	env.ambient_light_energy = 0.58
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("15252d")
	env.fog_light_energy = 0.5
	env.fog_density = 0.008
	world.environment = env
	add_child(world)
	var moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55,-28,0)
	moon.light_color = Color("96b4cb")
	moon.light_energy = 0.85
	moon.shadow_enabled = true
	add_child(moon)
	for p in [Vector3(-17,4,-13),Vector3(17,4,-13),Vector3(0,4,14)]:
		light(p,Color("60c8b8"),3.4,13)
	light(Vector3(0,7,0),Color("bd7b46"),2.4,24)

func box(pos: Vector3, size: Vector3, mat: Material, solid: bool = false, parent: Node3D = null) -> MeshInstance3D:
	var owner_node: Node3D = self if parent == null else parent
	var mesh = MeshInstance3D.new()
	var shape = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.position = pos
	owner_node.add_child(mesh)
	if solid:
		var body = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 2
		var col = CollisionShape3D.new()
		var bs = BoxShape3D.new()
		bs.size = size
		col.shape = bs
		body.add_child(col)
		mesh.add_child(body)
	return mesh

func cylinder(pos: Vector3, radius: float, height: float, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	var shape = CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 24
	m.mesh = shape
	m.material_override = mat
	m.position = pos
	(self if parent == null else parent).add_child(m)
	return m

func sphere(pos: Vector3, radius: float, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	var shape = SphereMesh.new()
	shape.radius = radius
	shape.height = radius*2
	shape.radial_segments = 24
	shape.rings = 12
	m.mesh = shape
	m.material_override = mat
	m.position = pos
	(self if parent == null else parent).add_child(m)
	return m

func ring(pos: Vector3, inner: float, outer: float, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	var shape = TorusMesh.new()
	shape.inner_radius = inner
	shape.outer_radius = outer
	shape.rings = 40
	shape.ring_segments = 8
	m.mesh = shape
	m.material_override = mat
	m.position = pos
	(self if parent == null else parent).add_child(m)
	return m

func light(pos: Vector3, color: Color, energy: float, radius: float, parent: Node3D = null) -> OmniLight3D:
	var l = OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = radius
	(self if parent == null else parent).add_child(l)
	return l

func inscription(text_value: String, pos: Vector3, color: Color, size: int = 40, parent: Node3D = null) -> Label3D:
	var label = Label3D.new()
	label.text = text_value
	label.font_size = size
	label.pixel_size = 0.012
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color("101a20")
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	(self if parent == null else parent).add_child(label)
	return label

func _architecture() -> void:
	box(Vector3(0,-0.65,0),Vector3(54,1.3,48),mats.dark,true)
	for x in range(-24,25,6):
		for z in range(-21,22,6):
			box(Vector3(x,0.005,z),Vector3(5.92,0.05,5.92),mats.floor)
	# Perimeter walls; the exit is a real aperture in the north wall.
	box(Vector3(-15,4,-24),Vector3(24,8,1),mats.stone,true)
	box(Vector3(15,4,-24),Vector3(24,8,1),mats.stone,true)
	box(Vector3(0,4,24),Vector3(54,8,1),mats.stone,true)
	for x in [-27,27]:
		box(Vector3(x,4,0),Vector3(1,8,48),mats.stone,true)
	for x in [-24,-18,-12,-6,6,12,18,24]:
		for z in [-23,23]:
			box(Vector3(x,5,z),Vector3(0.85,10,1.3),mats.dark)
			box(Vector3(x,3.2,z),Vector3(0.1,5.5,1.4),mats.brass)
	for z in [-18,-10,0,10,18]:
		for x in [-26,26]:
			box(Vector3(x,5,z),Vector3(1.3,10,0.85),mats.dark)
			box(Vector3(x,3,z),Vector3(1.4,5.6,0.1),mats.brass)
	# Top cornice and floating observatory ribs.
	box(Vector3(0,9,-23.5),Vector3(54,0.5,1.6),mats.brass)
	box(Vector3(0,9,23.5),Vector3(54,0.5,1.6),mats.brass)
	for x in [-26.5,26.5]:
		box(Vector3(x,9,0),Vector3(1.6,0.5,48),mats.brass)
	for i in range(3):
		var r = ring(Vector3(0,12+i*1.8,0),11.9+i*2,12.12+i*2,mats.brass)
		r.rotation_degrees.z = 9*i
	# Central monument provides a tall, reliable line-of-sight break.
	box(Vector3(0,3.3,0),Vector3(5.3,6.6,5.3),mats.stone,true)
	box(Vector3(0,6.8,0),Vector3(6.2,0.5,6.2),mats.brass)
	for x in [-2.7,2.7]:
		box(Vector3(x,3.3,0),Vector3(0.07,4.8,3.4),mats.brass)
	for z in [-2.7,2.7]:
		box(Vector3(0,3.3,z),Vector3(3.4,4.8,0.07),mats.brass)
	inscription("THE FIRST\nOBSERVANCE",Vector3(0,4.5,2.78),Color("dfd0ae"),38)
	# Four high partitions; side openings maintain one connected circulation ring.
	for x in [-9,9]:
		for z in [-6.5,6.5]:
			box(Vector3(x,2.2,z),Vector3(7.2,4.4,0.8),mats.stone,true)
			box(Vector3(x,4.5,z),Vector3(7.6,0.2,1),mats.brass)
			for end_x in [-3.6,3.6]:
				box(Vector3(x+end_x,2.35,z),Vector3(0.65,4.7,1.2),mats.dark,true)
	# Lower covers permit crouch counterplay and safe observation.
	for p in [Vector3(-18,0,-3),Vector3(18,0,-3),Vector3(-7,0,17),Vector3(7,0,17),Vector3(-7,0,-17),Vector3(7,0,-17)]:
		box(p+Vector3(0,0.8,0),Vector3(2.5,1.6,1.3),mats.dark,true)
		box(p+Vector3(0,1.62,0),Vector3(2.6,0.1,1.4),mats.brass)
	# Ground inlays are directional and never mistaken for lethal hazards.
	for x in [-24,24]:
		box(Vector3(x,0.05,0),Vector3(0.045,0.025,44),mats.brass)
	for z in [-21,21]:
		box(Vector3(0,0.05,z),Vector3(47,0.025,0.045),mats.brass)
	for z in range(8,21,3):
		box(Vector3(0,0.08,z),Vector3(0.8,0.03,0.05),mats.cyan)

func _build_stations() -> void:
	var titles = {"silent":"I   /   SILENT COUNTDOWN","echoes":"II   /   TRIAL OF THE ECHOES","relay":"III   /   CLOCKWORK RELAY"}
	var colors = {"silent":mats.cyan,"echoes":mats.violet,"relay":mats.amber}
	for key in STATIONS:
		var p: Vector3 = STATIONS[key]
		var s = Node3D.new()
		s.position = p
		add_child(s)
		stations[key] = s
		cylinder(Vector3(0,0.18,0),2.15,0.36,mats.dark,s)
		ring(Vector3(0,0.4,0),1.9,2.02,colors[key],s)
		box(Vector3(0,0.65,0),Vector3(1.3,1.3,1.1),mats.stone,true,s)
		box(Vector3(0,1.35,0),Vector3(1.7,0.15,1.4),mats.brass,false,s)
		var sigil = ring(Vector3(0,2.5,0),0.65,0.8,colors[key],s)
		sigil.rotation_degrees.x = 90
		beacon_lights[key] = sigil
		inscription(titles[key],Vector3(0,3.8,0),Color("e9e1ce"),32,s)
		var subtitle = {"silent":"DELIVER THREE WHISPER MOTES","echoes":"OBSERVE. REMEMBER. REPEAT.","relay":"HOLD THE WHEEL. BREAK THE GAZE."}
		inscription(subtitle[key],Vector3(0,3.25,0),Color("9cbbb8"),18,s)
	var e: Node3D = stations.echoes
	for i in range(4):
		var em = material(Color("716485"),0.3,0.3,0.2)
		echo_lights.append(em)
		box(Vector3(-0.62+i*0.41,1.55,0),Vector3(0.28,0.12,0.8),em,false,e)
	relay_wheel = Node3D.new()
	relay_wheel.position = Vector3(0,2,0)
	stations.relay.add_child(relay_wheel)
	var wheel = ring(Vector3.ZERO,0.78,0.98,mats.brass,relay_wheel)
	wheel.rotation_degrees.x = 90
	for i in range(8):
		var spoke = box(Vector3.ZERO,Vector3(0.07,1.8,0.08),mats.brass,false,relay_wheel)
		spoke.rotation.z = i*PI/4
	sphere(Vector3.ZERO,0.2,mats.amber,relay_wheel)

func _build_motes() -> void:
	for i in range(MOTE_POSITIONS.size()):
		var root = Node3D.new()
		root.position = MOTE_POSITIONS[i]
		add_child(root)
		cylinder(Vector3(0,0.35,0),0.65,0.7,mats.stone,root)
		var orb = sphere(Vector3(0,1.5,0),0.27,mats.cyan,root)
		motes.append(orb)
		var r = ring(Vector3(0,1.5,0),0.42,0.46,mats.brass,root)
		r.rotation_degrees.x = 60
		inscription("WHISPER  %02d" % (i+1),Vector3(0,2.3,0),Color("8cddd1"),19,root)

func _build_eyes() -> void:
	for i in range(4):
		var eye = Node3D.new()
		eye.position = SOCKETS[i]
		add_child(eye)
		eye.look_at(Vector3(0,1.5,0))
		var base = ring(Vector3(0,0,0.75),2.5,3.05,mats.brass,eye)
		base.rotation_degrees.x = 90
		var outer = ring(Vector3(0,0,0.9),3.25,3.35,mats.brass,eye)
		outer.rotation_degrees.x = 90
		var globe = sphere(Vector3.ZERO,2.5,mats.bone,eye)
		globe.scale = Vector3(1,0.85,0.55)
		var im = material(Color("b78d4c"),0.3,0.35,0.4)
		iris_materials.append(im)
		var iris = sphere(Vector3(0,0,-1.21),1.35,im,eye)
		iris.scale = Vector3(1,1,0.21)
		var pupil = sphere(Vector3(0,0,-1.52),0.66,mats.black,eye)
		pupil.scale = Vector3(0.46,1.68,0.13)
		for j in range(24):
			var angle: float = float(j)*TAU/24.0
			var ray = box(Vector3(cos(angle)*1.02,sin(angle)*1.02,-1.4),Vector3(0.035,0.45,0.05),mats.brass,false,eye)
			ray.rotation.z = angle-PI/2
		var lid = ring(Vector3(0,0,-0.9),2.05,2.25,mats.dark,eye)
		lid.rotation_degrees.x = 90
		lid.scale = Vector3(1,1,0.82)
		light(Vector3(0,0,-2),Color("e6b270"),1.6,14,eye)
		eyes.append(eye)
		inscription("%02d" % (i+1),SOCKETS[i]+Vector3(0,-3.8,0),Color("b5a68a"),30)

func _build_traps() -> void:
	for p in TRAP_POSITIONS:
		var tm = material(Color("4b4442"),0.55,0.4,0.0)
		trap_materials.append(tm)
		var mesh = cylinder(p+Vector3(0,0.06,0),1.65,0.1,tm)
		trap_meshes.append(mesh)
		ring(p+Vector3(0,0.12,0),1.55,1.65,mats.brass)
		var spikes = Node3D.new()
		spikes.position = p+Vector3(0,-2,0)
		add_child(spikes)
		for k in range(5):
			var a: float = k*TAU/5
			var spike = cylinder(Vector3(cos(a)*0.75,0.8,sin(a)*0.75),0.15,1.6,mats.brass,spikes)
			(spike.mesh as CylinderMesh).top_radius = 0.01
		trap_spikes.append(spikes)

func _build_exit() -> void:
	for x in [-2.8,2.8]:
		box(Vector3(x,3.6,-22.8),Vector3(1,7.2,1.6),mats.dark,true)
		box(Vector3(x,3.6,-21.95),Vector3(0.15,5.9,0.1),mats.brass)
	box(Vector3(0,7.4,-22.8),Vector3(6.8,0.9,1.6),mats.brass)
	portal_material = material(Color("253b3d"),0.4,0.2,0.3)
	portal = box(Vector3(0,3.4,-23.3),Vector3(4.5,6.8,0.15),portal_material)
	inscription("THE UNSEEN DOOR",Vector3(0,8.2,-22),Color("d6c5a1"),33)
	for i in range(3):
		sphere(Vector3(-0.8+i*0.8,6.2,-22.9),0.17,mats.amber)

func set_socket(index: int) -> void:
	for i in range(eyes.size()):
		iris_materials[i].emission_energy_multiplier = 2.8 if i == index else 0.1
		iris_materials[i].albedo_color = Color("edb864") if i == index else Color("6c695d")

func open_exit(opened: bool) -> void:
	portal_material.albedo_color = Color("79cbb9") if opened else Color("253b3d")
	portal_material.emission = Color("79cbb9") if opened else Color("253b3d")
	portal_material.emission_energy_multiplier = 2.1 if opened else 0.15

func set_seal(key: String, completed: bool) -> void:
	if beacon_lights.has(key):
		beacon_lights[key].material_override = mats.cyan if completed else {"silent":mats.cyan,"echoes":mats.violet,"relay":mats.amber}[key]
		beacon_lights[key].scale = Vector3.ONE* (1.18 if completed else 1.0)

func show_echo(index: int) -> void:
	for i in range(echo_lights.size()):
		echo_lights[i].emission_enabled = true
		echo_lights[i].emission = Color("c4aef1")
		echo_lights[i].emission_energy_multiplier = 3.0 if i == index else 0.1

func set_trap(index: int, state: String, amount: float = 0.0) -> void:
	var m: StandardMaterial3D = trap_materials[index]
	m.emission_enabled = state != "idle"
	m.albedo_color = Color("ed7869") if state == "active" else (Color("e5b057") if state == "warning" else Color("4b4442"))
	m.emission = m.albedo_color
	m.emission_energy_multiplier = 1.5 if state != "idle" else 0.0
	trap_spikes[index].position.y = 0.0 if state == "active" else -2.0

func _process(delta: float) -> void:
	elapsed += delta
	for i in range(motes.size()):
		motes[i].position.y = 1.55+sin(elapsed*1.7+i)*0.15
