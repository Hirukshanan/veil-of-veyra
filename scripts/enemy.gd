extends CharacterBody3D

signal defeated

const GRAVITY := 22.0
enum Kind { SHORE, SCOUT, BRUTE }

var target: Node3D
var health := 3
var kind := Kind.SHORE
var move_speed := 2.15
var attack_damage := 8
var attack_range := 1.8
var windup_duration := 0.55
var recovery_duration := 0.8
var body_color := Color(0.25, 0.15, 0.27)
var body_radius := 0.5
var body_height := 1.5
var display_name := "SHORE DEMON"
var _maximum_health := 3
var _health_label: Label3D
var _attack_cooldown := 0.0
var _windup := 0.0
var _hit_time := 0.0
var _material: StandardMaterial3D
var _warning: MeshInstance3D


func _ready() -> void:
	add_to_group("lock_targets")
	collision_layer = 2
	collision_mask = 1
	match kind:
		Kind.SCOUT:
			display_name = "SCOUT"
			health = maxi(2, health - 1)
			move_speed = 3.1
			attack_damage = 5
			attack_range = 1.6
			windup_duration = 0.4
			recovery_duration = 0.9
			body_color = Color(0.13, 0.4, 0.4)
			body_radius = 0.38
			body_height = 1.35
		Kind.BRUTE:
			display_name = "BRUTE"
			health += 3
			move_speed = 1.45
			attack_damage = 16
			attack_range = 2.3
			windup_duration = 0.95
			recovery_duration = 1.2
			body_color = Color(0.48, 0.16, 0.1)
			body_radius = 0.68
			body_height = 2.1
	_maximum_health = health
	_build_body()


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_hit_time = maxf(0.0, _hit_time - delta)
	_material.albedo_color = Color(1, 0.85, 0.65) if _hit_time > 0.0 else body_color
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
			_attack_cooldown = recovery_duration
			if distance <= attack_range and absf(target.global_position.y - global_position.y) <= 2.0 and target.has_method("take_damage"):
				target.call("take_damage", attack_damage)
	elif _hit_time > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
	elif distance > attack_range - 0.25:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		rotation.y = atan2(-direction.x, -direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		if _attack_cooldown <= 0.0 and target.has_method("take_damage"):
			_windup = windup_duration
			_warning.show()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	if amount <= 0:
		return
	preload("res://scripts/damage_number.gd").show_hit(self, mini(amount, health), body_height + 0.65)
	health -= amount
	_health_label.text = "%s  %d / %d" % [display_name, maxi(0, health), _maximum_health]
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
	capsule.radius = body_radius
	capsule.height = body_height
	body_mesh.mesh = capsule
	body_mesh.position.y = body_height * 0.5
	var material := StandardMaterial3D.new()
	_material = material
	material.albedo_color = body_color
	material.roughness = 0.72
	body_mesh.material_override = material
	add_child(body_mesh)

	var eye_mesh := MeshInstance3D.new()
	var eyes := BoxMesh.new()
	eyes.size = Vector3(0.45, 0.1, 0.08)
	eye_mesh.mesh = eyes
	eye_mesh.position = Vector3(0, body_height * 0.7, -body_radius * 0.86)
	var eye_material := StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.95, 0.54, 0.23)
	eye_material.emission_enabled = true
	eye_material.emission = Color(0.8, 0.18, 0.04)
	eye_mesh.material_override = eye_material
	add_child(eye_mesh)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = body_radius
	shape.height = body_height
	collision.shape = shape
	collision.position.y = body_height * 0.5
	add_child(collision)
	_health_label = Label3D.new()
	_health_label.position.y = body_height + 0.4
	_health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_health_label.font_size = 28
	_health_label.text = "%s  %d / %d" % [display_name, health, _maximum_health]
	add_child(_health_label)

	_warning = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = attack_range
	disc.bottom_radius = attack_range
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
