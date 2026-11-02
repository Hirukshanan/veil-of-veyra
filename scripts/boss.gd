extends CharacterBody3D

signal health_changed(value: int, maximum: int)
signal defeated

enum AttackState { APPROACH, WINDUP, CHARGE, RECOVER }

const MAX_HEALTH := 28
const GRAVITY := 22.0

var target: Node3D
var health := MAX_HEALTH
var _state := AttackState.APPROACH
var _state_time := 0.0
var _attack_direction := Vector3.ZERO
var _attack_hit := false
var _warning_ring: MeshInstance3D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_build_body()
	_build_warning_ring()
	health_changed.emit(health, MAX_HEALTH)


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
			if distance > 3.6:
				velocity.x = direction.x * 1.8
				velocity.z = direction.z * 1.8
				rotation.y = atan2(-direction.x, -direction.z)
			else:
				_attack_direction = direction
				_state = AttackState.WINDUP
				_state_time = 0.85
				_warning_ring.visible = true
		AttackState.WINDUP:
			_state_time -= delta
			velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
			if _state_time <= 0.0:
				_state = AttackState.CHARGE
				_state_time = 0.5
				_attack_hit = false
				_warning_ring.visible = false
		AttackState.CHARGE:
			velocity.x = _attack_direction.x * 9.0
			velocity.z = _attack_direction.z * 9.0
			_state_time -= delta
			if not _attack_hit and distance < 2.4:
				_attack_hit = true
				target.call("take_damage", 18)
			if _state_time <= 0.0:
				_state = AttackState.RECOVER
				_state_time = 0.8
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
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		defeated.emit()
		queue_free()


func _build_body() -> void:
	var shell := SphereMesh.new()
	shell.radius = 1.0
	shell.height = 1.7
	_add_mesh(shell, Vector3(0, 1.0, 0), Vector3(1.45, 0.88, 1.25), Color(0.36, 0.18, 0.12))

	var carapace := SphereMesh.new()
	carapace.radius = 1.0
	carapace.height = 1.5
	_add_mesh(carapace, Vector3(0, 1.6, 0.22), Vector3(1.35, 0.78, 1.1), Color(0.53, 0.25, 0.14))

	var claw_mesh := BoxMesh.new()
	claw_mesh.size = Vector3(0.82, 0.62, 0.9)
	_add_mesh(claw_mesh, Vector3(-1.25, 0.82, -0.55), Vector3(1, 1, 1), Color(0.62, 0.29, 0.13))
	_add_mesh(claw_mesh, Vector3(1.25, 0.82, -0.55), Vector3(1, 1, 1), Color(0.62, 0.29, 0.13))

	var pincer_mesh := BoxMesh.new()
	pincer_mesh.size = Vector3(0.52, 0.2, 0.38)
	_add_mesh(pincer_mesh, Vector3(-1.3, 0.52, -1.02), Vector3(1, 1, 1), Color(0.8, 0.43, 0.18))
	_add_mesh(pincer_mesh, Vector3(1.3, 0.52, -1.02), Vector3(1, 1, 1), Color(0.8, 0.43, 0.18))

	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.14
	eye_mesh.height = 0.28
	var eye_material := _material(Color(1.0, 0.71, 0.25))
	eye_material.emission_enabled = true
	eye_material.emission = Color(0.85, 0.2, 0.03)
	_add_mesh(eye_mesh, Vector3(-0.38, 1.2, -1.05), Vector3.ONE, Color(1, 1, 1), eye_material)
	_add_mesh(eye_mesh, Vector3(0.38, 1.2, -1.05), Vector3.ONE, Color(1, 1, 1), eye_material)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 1.05
	shape.height = 2.1
	collision.shape = shape
	collision.position.y = 1.05
	add_child(collision)


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


func _add_mesh(mesh: Mesh, local_position: Vector3, local_scale: Vector3, color: Color, material: StandardMaterial3D = null) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = local_position
	instance.scale = local_scale
	instance.material_override = material if material != null else _material(color)
	add_child(instance)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	return material
