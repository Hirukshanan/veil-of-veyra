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
var _flying := false
var _use_breath := false
var _warning_ring: MeshInstance3D
var _fire_cone: Node3D
var enraged := false
var _attack_enraged := false

var _attack_label: Label3D
var _visual: Node3D




func _ready() -> void:
	add_to_group("lock_targets")
	collision_layer = 2
	collision_mask = 1
	_build_body()
	_build_warning_ring()
	_build_fire_cone()
	_attack_label = Label3D.new()
	_attack_label.position.y = 4.6
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
				if distance > 11.0:
					_flying = true
				elif distance < 7.0:
					_flying = false
				var speed := (5.0 if enraged else 4.2) if _flying else (2.6 if enraged else 2.0)
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
				rotation.y = atan2(-direction.x, -direction.z)
			else:
				_flying = false
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
	if amount <= 0:
		return
	preload("res://scripts/damage_number.gd").show_hit(self, mini(amount, health), 3.0)
	_visual.show_hit()
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health > 0 and health * 2 <= max_health and not enraged:
		enraged = true
		if _state == AttackState.APPROACH or _state == AttackState.RECOVER:
			_attack_label.text = "ENRAGED"
		enraged_started.emit()
	if health == 0:
		_visual.show_defeat(get_parent())
		defeated.emit()
		queue_free()


func _build_body() -> void:
	_visual = preload("res://scripts/dragon_visual.gd").new()
	_visual.name = "Visual"
	add_child(_visual)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.9
	shape.height = 2.3
	collision.shape = shape
	collision.position.y = 1.1
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


func _build_fire_cone() -> void:
	_fire_cone = preload("res://scripts/dragon_fire.gd").new()
	_fire_cone.visible = false
	add_child(_fire_cone)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	return material


func _process(delta: float) -> void:
	if health <= 0:
		return
	var clip := "idle"
	var progress := 0.0
	match _state:
		AttackState.WINDUP:
			clip = "windup"
			progress = 1.0 - _state_time / (0.65 if _attack_enraged else 0.85)
		AttackState.BREATH:
			clip = "breath"
			progress = 1.0 - _state_time / 0.55
		AttackState.CHARGE:
			clip = "charge"
			progress = 1.0 - _state_time / 0.48
		AttackState.RECOVER:
			clip = "recover"
			progress = 1.0 - _state_time / (0.6 if _attack_enraged else 0.8)
	_visual.flying = _flying
	if is_instance_valid(target):
		_visual.look_direction = global_basis.inverse() * (target.global_position - global_position)
	_visual.animate(delta, clip, clampf(progress, 0.0, 1.0), Vector2(velocity.x, velocity.z).length() > 0.1, enraged)
	if _fire_cone.visible:
		_fire_cone.position = to_local(_visual.mouth_position())
		_fire_cone.animate(delta)
