extends CharacterBody3D

signal defeated

const GRAVITY := 22.0

var target: Node3D
var health := 3
var _attack_cooldown := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_build_body()


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if not is_instance_valid(target) or health <= 0:
		return

	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.01 else Vector3.ZERO
	if distance > 1.55:
		velocity.x = direction.x * 2.15
		velocity.z = direction.z * 2.15
		rotation.y = atan2(-direction.x, -direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		if _attack_cooldown <= 0.0 and target.has_method("take_damage"):
			_attack_cooldown = 1.15
			target.call("take_damage", 8)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
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
