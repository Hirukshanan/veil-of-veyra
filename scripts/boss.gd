extends CharacterBody3D

signal health_changed(value: int, maximum: int)
signal defeated
signal enraged_started

enum AttackState { APPROACH, WINDUP, BREATH, CHARGE, RECOVER }

const MAX_HEALTH := 34
const GRAVITY := 22.0

var target: Node3D
var health := MAX_HEALTH
var max_health := MAX_HEALTH
var _state := AttackState.APPROACH
var _state_time := 0.0
var _attack_direction := Vector3.ZERO
var _attack_hit := false
var _use_breath := false
var _warning_ring: MeshInstance3D
var _fire_cone: MeshInstance3D
var enraged := false
var _attack_enraged := false
var _core_material: StandardMaterial3D
var _attack_label: Label3D


func _ready() -> void:
	add_to_group("lock_targets")
	collision_layer = 2
	collision_mask = 1
	_build_body()
	_build_warning_ring()
	_build_fire_cone()
	_attack_label = Label3D.new()
	_attack_label.position.y = 3.1
	_attack_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_attack_label.font_size = 40
	add_child(_attack_label)
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or health <= 0:
		return

	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.01 else Vector3.ZERO

	match _state:
		AttackState.APPROACH:
			_warning_ring.visible = false
			_fire_cone.visible = false
			if distance > 5.8:
				var speed := 2.6 if enraged else 2.0
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
				rotation.y = atan2(-direction.x, -direction.z)
			else:
				_attack_direction = direction
				rotation.y = atan2(-direction.x, -direction.z)
				_use_breath = distance > 3.6
				# A phase change must not shorten an attack already being telegraphed.
				_attack_enraged = enraged
				_state = AttackState.WINDUP
				_state_time = 0.65 if _attack_enraged else 0.85
				_attack_label.text = "FIRE BREATH — MOVE ASIDE" if _use_breath else "CHARGE — DODGE SIDEWAYS"
				_warning_ring.visible = true
		AttackState.WINDUP:
			_state_time -= delta
			velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
			if _state_time <= 0.0:
				_warning_ring.visible = false
				_attack_hit = false
				if _use_breath:
					_state = AttackState.BREATH
					_state_time = 0.55
					_fire_cone.visible = true
				else:
					_state = AttackState.CHARGE
					_state_time = 0.48
		AttackState.BREATH:
			if not _attack_hit:
				_attack_hit = true
				var breath_offset := target.global_position - global_position
				breath_offset.y = 0.0
				var breath_direction := breath_offset.normalized()
				var forward := Vector3(0, 0, -1).rotated(Vector3.UP, rotation.y)
				if breath_offset.length() < 6.2 and forward.dot(breath_direction) > 0.72:
					target.call("take_damage", 16)
			_state_time -= delta
			if _state_time <= 0.0:
				_fire_cone.visible = false
				_state = AttackState.RECOVER
				_state_time = 0.6 if _attack_enraged else 0.8
				_attack_label.text = "ENRAGED" if enraged else ""
		AttackState.CHARGE:
			var charge_speed := 11.0 if _attack_enraged else 9.0
			velocity.x = _attack_direction.x * charge_speed
			velocity.z = _attack_direction.z * charge_speed
			_state_time -= delta
			if not _attack_hit and distance < 2.6:
				_attack_hit = true
				target.call("take_damage", 18)
			if _state_time <= 0.0:
				_state = AttackState.RECOVER
				_state_time = 0.6 if _attack_enraged else 0.8
				_attack_label.text = "ENRAGED" if enraged else ""
		AttackState.RECOVER:
			_state_time -= delta
			velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
			if _state_time <= 0.0:
				_state = AttackState.APPROACH

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health > 0 and health * 2 <= max_health and not enraged:
		enraged = true
		_core_material.albedo_color = Color(1.0, 0.05, 0.02)
		_core_material.emission = Color(1.0, 0.02, 0.01)
		if _state == AttackState.APPROACH or _state == AttackState.RECOVER:
			_attack_label.text = "ENRAGED"
		enraged_started.emit()
	if health == 0:
		defeated.emit()
		queue_free()


func _build_body() -> void:
	var torso := SphereMesh.new()
	torso.radius = 1.0
	torso.height = 1.8
	_add_piece(torso, Vector3(0, 1.05, 0.15), Vector3(0.95, 0.82, 1.5), Color(0.19, 0.16, 0.31))

	var chest := SphereMesh.new()
	chest.radius = 1.0
	chest.height = 1.5
	_add_piece(chest, Vector3(0, 1.15, -0.72), Vector3(0.78, 0.72, 0.78), Color(0.28, 0.2, 0.37))

	var neck := CapsuleMesh.new()
	neck.radius = 0.43
	neck.height = 1.8
	_add_piece(neck, Vector3(0, 1.55, -1.42), Vector3.ONE, Color(0.24, 0.19, 0.34), Vector3(PI / 2.0, 0, 0))

	var head := SphereMesh.new()
	head.radius = 0.68
	head.height = 1.15
	_add_piece(head, Vector3(0, 1.7, -2.25), Vector3(1.0, 0.88, 1.0), Color(0.27, 0.2, 0.36))

	var snout := SphereMesh.new()
	snout.radius = 0.42
	snout.height = 0.6
	_add_piece(snout, Vector3(0, 1.4, -2.78), Vector3(1.1, 0.7, 1.35), Color(0.33, 0.23, 0.34))

	var horn := CylinderMesh.new()
	horn.top_radius = 0.025
	horn.bottom_radius = 0.18
	horn.height = 0.8
	horn.radial_segments = 6
	_add_piece(horn, Vector3(-0.43, 2.22, -2.18), Vector3.ONE, Color(0.14, 0.11, 0.19), Vector3(0, 0, 0.42))
	_add_piece(horn, Vector3(0.43, 2.22, -2.18), Vector3.ONE, Color(0.14, 0.11, 0.19), Vector3(0, 0, -0.42))

	var spine_spike := CylinderMesh.new()
	spine_spike.top_radius = 0.02
	spine_spike.bottom_radius = 0.12
	spine_spike.height = 0.36
	spine_spike.radial_segments = 5
	for index in range(5):
		_add_piece(spine_spike, Vector3(0, 1.72, -0.15 + index * 0.42), Vector3.ONE, Color(0.49, 0.29, 0.34))

	var tail := CapsuleMesh.new()
	tail.radius = 0.34
	tail.height = 1.6
	_add_piece(tail, Vector3(0, 0.76, 1.72), Vector3(0.85, 0.75, 1.0), Color(0.2, 0.16, 0.29), Vector3(PI / 2.0, 0, 0))
	var tail_tip := CylinderMesh.new()
	tail_tip.top_radius = 0.025
	tail_tip.bottom_radius = 0.31
	tail_tip.height = 0.9
	tail_tip.radial_segments = 6
	_add_piece(tail_tip, Vector3(0, 0.74, 2.85), Vector3.ONE, Color(0.45, 0.18, 0.24), Vector3(PI / 2.0, 0, 0))

	var leg := CapsuleMesh.new()
	leg.radius = 0.24
	leg.height = 0.82
	_add_piece(leg, Vector3(-0.62, 0.38, 0.25), Vector3.ONE, Color(0.17, 0.14, 0.25), Vector3(0, 0, 0.32))
	_add_piece(leg, Vector3(0.62, 0.38, 0.25), Vector3.ONE, Color(0.17, 0.14, 0.25), Vector3(0, 0, -0.32))

	var wing_material := _material(Color(0.12, 0.1, 0.2, 0.92))
	wing_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-1, 1]:
		var wing := MeshInstance3D.new()
		wing.mesh = _make_wing(side)
		wing.material_override = wing_material
		add_child(wing)

	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.12
	eye_mesh.height = 0.24
	var eye_material := _material(Color(1.0, 0.34, 0.09))
	eye_material.emission_enabled = true
	eye_material.emission = Color(0.95, 0.12, 0.02)
	_add_piece(eye_mesh, Vector3(-0.35, 1.72, -2.82), Vector3.ONE, Color.WHITE, Vector3.ZERO, eye_material)
	_add_piece(eye_mesh, Vector3(0.35, 1.72, -2.82), Vector3.ONE, Color.WHITE, Vector3.ZERO, eye_material)

	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.22
	core_mesh.height = 0.44
	var core_material := _material(Color(0.96, 0.27, 0.06))
	_core_material = core_material
	core_material.emission_enabled = true
	core_material.emission = Color(0.85, 0.12, 0.02)
	_add_piece(core_mesh, Vector3(0, 1.18, -1.25), Vector3.ONE, Color.WHITE, Vector3.ZERO, core_material)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.9
	shape.height = 2.3
	collision.shape = shape
	collision.position.y = 1.1
	add_child(collision)


func _make_wing(side: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shoulder := Vector3(side * 0.5, 1.72, 0.05)
	var outer_tip := Vector3(side * 2.7, 2.05, 0.22)
	var rear_tip := Vector3(side * 2.1, 0.82, 0.9)
	var inner_tip := Vector3(side * 0.78, 1.02, 0.72)
	_add_triangle(surface, shoulder, outer_tip, inner_tip)
	_add_triangle(surface, outer_tip, rear_tip, inner_tip)
	_add_triangle(surface, shoulder, inner_tip, Vector3(side * 1.12, 1.4, 0.58))
	surface.generate_normals()
	return surface.commit()


func _build_warning_ring() -> void:
	_warning_ring = MeshInstance3D.new()
	var ring := CylinderMesh.new()
	ring.top_radius = 2.4
	ring.bottom_radius = 2.4
	ring.height = 0.035
	ring.radial_segments = 32
	_warning_ring.mesh = ring
	_warning_ring.position.y = 0.045
	var warning_material := _material(Color(0.85, 0.1, 0.035, 0.5))
	warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_warning_ring.material_override = warning_material
	_warning_ring.visible = false
	add_child(_warning_ring)


func _build_fire_cone() -> void:
	_fire_cone = MeshInstance3D.new()
	var flame := CylinderMesh.new()
	flame.top_radius = 0.025
	flame.bottom_radius = 1.0
	flame.height = 4.2
	flame.radial_segments = 8
	_fire_cone.mesh = flame
	_fire_cone.position = Vector3(0, 1.42, -4.25)
	_fire_cone.rotation.x = -PI / 2.0
	var flame_material := _material(Color(1.0, 0.25, 0.04, 0.58))
	flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_material.emission_enabled = true
	flame_material.emission = Color(0.85, 0.12, 0.01)
	_fire_cone.material_override = flame_material
	_fire_cone.visible = false
	add_child(_fire_cone)


func _add_piece(mesh: Mesh, local_position: Vector3, local_scale: Vector3, color: Color, local_rotation: Vector3 = Vector3.ZERO, material: StandardMaterial3D = null) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = local_position
	instance.scale = local_scale
	instance.rotation = local_rotation
	instance.material_override = material if material != null else _material(color)
	add_child(instance)


func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	return material
