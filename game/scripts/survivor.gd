class_name EyesSurvivor
extends CharacterBody3D

signal footstep(loudness: float)

const ARCHETYPES: Dictionary = {
	"Veil":{"name":"Mara Vale","speed":4.4,"sprint":7.0,"noise":0.55,"stamina":100.0,"color":Color("7bcbbd")},
	"Tinker":{"name":"Nadiya Sayegh","speed":4.2,"sprint":6.6,"noise":0.9,"stamina":100.0,"color":Color("d4ad68")},
	"Runner":{"name":"June Arlen","speed":4.6,"sprint":8.0,"noise":1.0,"stamina":135.0,"color":Color("c296c9")},
	"Keeper":{"name":"Ada Fen","speed":4.3,"sprint":6.9,"noise":0.85,"stamina":100.0,"color":Color("89b9da")}
}

var active: bool = false
var controls_locked: bool = false
var is_bot: bool = false
var archetype: String = "Veil"
var health: float = 100.0
var stamina: float = 100.0
var gaze: float = 0.0
var noise: float = 0.0
var crouching: bool = false
var carrying: int = -1
var eliminated: bool = false
var invulnerability: float = 0.0
var ability_left: float = 0.0
var ability_cooldown: float = 0.0
var respawn_shield: float = 0.0
var facing: float = 0.0
var move_target: Vector3 = Vector3.ZERO
var bot_sprint: bool = false
var bot_crouch: bool = false
var bot_hold: bool = false
var mouse_sensitivity: float = 0.0022
var invert_y: bool = false
var motion_reduced: bool = false
var head: Node3D
var camera: Camera3D
var body_mesh: Node3D
var collider: CollisionShape3D
var pitch: float = 0.0
var step_accumulator: float = 0.0
var bob_time: float = 0.0
var params: Dictionary = ARCHETYPES.Veil

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	collider = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.7
	collider.shape = capsule
	collider.position.y = 0.85
	add_child(collider)
	head = Node3D.new()
	head.position.y = 1.6
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 79
	camera.near = 0.05
	camera.far = 170
	head.add_child(camera)
	_visual_body()

func _visual_body() -> void:
	body_mesh = Node3D.new()
	add_child(body_mesh)
	var torso = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.05
	torso.mesh = capsule
	torso.position.y = 1.0
	torso.material_override = EyesArena.material(Color("29444e"),0.8)
	body_mesh.add_child(torso)
	var face = MeshInstance3D.new()
	var mask_mesh = SphereMesh.new()
	mask_mesh.radius = 0.23
	mask_mesh.height = 0.46
	face.mesh = mask_mesh
	face.position.y = 1.69
	face.scale = Vector3(0.84,1.05,0.85)
	face.material_override = EyesArena.material(Color("c7c0a8"),0.6)
	body_mesh.add_child(face)
	for x in [-0.16,0.16]:
		var leg = MeshInstance3D.new()
		var leg_mesh = CapsuleMesh.new()
		leg_mesh.radius = 0.11
		leg_mesh.height = 0.65
		leg.mesh = leg_mesh
		leg.position = Vector3(x,0.33,0)
		leg.material_override = EyesArena.material(Color("17252e"))
		body_mesh.add_child(leg)
	var marker = MeshInstance3D.new()
	var marker_mesh = TorusMesh.new()
	marker_mesh.inner_radius = 0.39
	marker_mesh.outer_radius = 0.44
	marker_mesh.rings = 24
	marker_mesh.ring_segments = 6
	marker.mesh = marker_mesh
	marker.position.y = 0.045
	marker.material_override = EyesArena.material(params.color,0.4,0.2,1.2)
	body_mesh.add_child(marker)
	var label = Label3D.new()
	label.name = "NameTag"
	label.text = archetype.to_upper()
	label.font_size = 22
	label.pixel_size = 0.009
	label.position.y = 2.17
	label.modulate = params.color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	body_mesh.add_child(label)

func reset_body(at: Vector3, role: String, bot: bool) -> void:
	global_position = at
	archetype = role if ARCHETYPES.has(role) else "Veil"
	params = ARCHETYPES[archetype]
	is_bot = bot
	health = 100.0
	stamina = params.stamina
	gaze = 0.0
	carrying = -1
	eliminated = false
	invulnerability = 0.0
	respawn_shield = 4.0
	ability_left = 0.0
	ability_cooldown = 0.0
	velocity = Vector3.ZERO
	move_target = at
	pitch = 0.0
	rotation.y = 0.0
	body_mesh.visible = bot
	(body_mesh.get_node("NameTag") as Label3D).text = archetype.to_upper()
	(body_mesh.get_node("NameTag") as Label3D).modulate = params.color
	(body_mesh.get_child(0) as MeshInstance3D).material_override = EyesArena.material(params.color.darkened(0.65),0.8)
	(body_mesh.get_child(4) as MeshInstance3D).material_override = EyesArena.material(params.color,0.4,0.2,1.2)
	camera.current = not bot
	controls_locked = false
	active = true
	visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not active or is_bot or eliminated or controls_locked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x*mouse_sensitivity
		pitch = clampf(pitch-event.relative.y*mouse_sensitivity*(-1.0 if invert_y else 1.0),-1.35,1.35)
		head.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if not active or eliminated:
		return
	invulnerability = maxf(0.0,invulnerability-delta)
	respawn_shield = maxf(0.0,respawn_shield-delta)
	ability_left = maxf(0.0,ability_left-delta)
	ability_cooldown = maxf(0.0,ability_cooldown-delta)
	var movement = Vector3.ZERO
	var sprinting = false
	crouching = bot_crouch if is_bot else Input.is_action_pressed("crouch")
	if is_bot:
		movement = move_target-global_position
		movement.y = 0
		if movement.length() > 0.25:
			movement = movement.normalized()
			rotation.y = lerp_angle(rotation.y,atan2(-movement.x,-movement.z),delta*7)
		else:
			movement = Vector3.ZERO
		sprinting = bot_sprint
	elif not controls_locked:
		var input_dir = Input.get_vector("move_left","move_right","move_forward","move_back")
		movement = (transform.basis*Vector3(input_dir.x,0,input_dir.y)).normalized()
		sprinting = Input.is_action_pressed("sprint")
	sprinting = sprinting and stamina > 0.5 and not crouching and movement.length() > 0.1
	var speed: float = params.speed
	if crouching:
		speed = 2.25
	elif sprinting:
		speed = params.sprint
	if archetype == "Runner" and ability_left > 0:
		speed *= 1.25
	if carrying >= 0:
		speed *= 0.90
	if gaze >= 70:
		speed *= 0.85
	if sprinting:
		stamina = maxf(0.0,stamina-delta*19.0)
	else:
		stamina = minf(params.stamina,stamina+delta*13.0)
	velocity.x = move_toward(velocity.x,movement.x*speed,delta*25.0)
	velocity.z = move_toward(velocity.z,movement.z*speed,delta*25.0)
	if not is_on_floor():
		velocity.y -= 21.0*delta
	elif not is_bot and not controls_locked and Input.is_action_just_pressed("jump") and stamina >= 8.0:
		velocity.y = 6.2
		stamina -= 8.0
	move_and_slide()
	# Crouching changes both the physical profile and the target used by gaze rays.
	var h: float = 1.0 if crouching else 1.7
	(collider.shape as CapsuleShape3D).height = h
	collider.position.y = h/2.0
	var actual_speed = Vector2(velocity.x,velocity.z).length()
	noise = (0.12 if crouching else (0.95 if sprinting else 0.42))*params.noise if actual_speed > 0.3 else 0.0
	if archetype == "Veil" and ability_left > 0:
		noise *= 0.15
	step_accumulator += actual_speed*delta
	if step_accumulator > (2.4 if crouching else 2.0):
		step_accumulator = 0.0
		footstep.emit(noise)
	bob_time += delta*actual_speed*1.8
	var bob = sin(bob_time)*0.025 if not motion_reduced and is_on_floor() else 0.0
	head.position.y = lerpf(head.position.y,(0.9 if crouching else 1.6)+bob,delta*10.0)
	if is_bot:
		body_mesh.scale.y = lerpf(body_mesh.scale.y,0.67 if crouching else 1.0,delta*10)

func target_point() -> Vector3:
	return global_position+Vector3(0,0.65 if crouching else 1.2,0)

func damage(amount: float) -> bool:
	if eliminated or invulnerability > 0 or respawn_shield > 0:
		return false
	health = maxf(0.0,health-amount)
	invulnerability = 1.35
	return true

func use_ability() -> bool:
	if ability_cooldown > 0 or eliminated:
		return false
	ability_cooldown = {"Veil":25.0,"Tinker":25.0,"Runner":22.0,"Keeper":35.0}[archetype]
	ability_left = {"Veil":5.0,"Tinker":8.0,"Runner":5.0,"Keeper":1.0}[archetype]
	if archetype == "Keeper":
		health = minf(100.0,health+30.0)
	return true
