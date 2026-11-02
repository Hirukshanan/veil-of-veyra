extends CharacterBody3D

signal defeated

const GRAVITY := 22.0

var target: Node3D
var health := 3
var _attack_cooldown := 0.0
var _windup := 0.0
var _hit_time := 0.0
var _material: StandardMaterial3D
var _warning: MeshInstance3D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_build_body()


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_hit_time = maxf(0.0, _hit_time - delta)
	_material.albedo_color = Color(1, 0.85, 0.65) if _hit_time > 0.0 else Color(0.25, 0.15, 0.27)
	if not is_instance_valid(target) or health <= 0:
		return

	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.01 else Vector3.ZERO
	if _windup > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		_windup = maxf(0.0, _windup - delta)
		if _windup == 0.0:
			_warning.hide()
			_attack_cooldown = 0.8
			if distance <= 1.8 and absf(target.global_position.y - global_position.y) <= 2.0 and target.has_method("take_damage"):
				target.call("take_damage", 8)
	elif _hit_time > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
	elif distance > 1.55:
		velocity.x = direction.x * 2.15
		velocity.z = direction.z * 2.15
		rotation.y = atan2(-direction.x, -direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		if _attack_cooldown <= 0.0 and target.has_method("take_damage"):
			_windup = 0.55
			_warning.show()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	_hit_time = 0.18
	_windup = 0.0
	_warning.hide()
	_attack_cooldown = maxf(_attack_cooldown, 0.35)
	if health <= 0:
		defeated.emit()
		queue_free()


func _build_body() -> void:
	var body_mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.5
	capsule.height = 1.5
	body_mesh.mesh = capsule
	body_mesh.position.y = 0.75
	var material := StandardMaterial3D.new()
	_material = material
	material.albedo_color = Color(0.25, 0.15, 0.27)
	material.roughness = 0.72
	body_mesh.material_override = material
	add_child(body_mesh)

	var eye_mesh := MeshInstance3D.new()
	var eyes := BoxMesh.new()
	eyes.size = Vector3(0.45, 0.1, 0.08)
	eye_mesh.mesh = eyes
	eye_mesh.position = Vector3(0, 1.05, -0.43)
	var eye_material := StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.95, 0.54, 0.23)
	eye_material.emission_enabled = true
	eye_material.emission = Color(0.8, 0.18, 0.04)
	eye_mesh.material_override = eye_material
	add_child(eye_mesh)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.5
	collision.shape = shape
	collision.position.y = 0.75
	add_child(collision)

	_warning = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.8
	disc.bottom_radius = 1.8
	disc.height = 0.025
	_warning.mesh = disc
	_warning.position.y = 0.04
	var warning_material := StandardMaterial3D.new()
	warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	warning_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	warning_material.albedo_color = Color(1.0, 0.25, 0.08, 0.45)
	_warning.material_override = warning_material
	_warning.hide()
	add_child(_warning)
