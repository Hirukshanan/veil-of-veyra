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
var body_color := Color(0.48, 0.14, 0.055)
var body_radius := 0.5
var body_height := 1.5
var display_name := "EMBER WOLF"
var _maximum_health := 3
var _health_label: Label3D
var _attack_cooldown := 0.0
var _windup := 0.0
var _hit_time := 0.0
var _material: StandardMaterial3D
var _warning: MeshInstance3D
var _visual: Node3D
var _strike_time := 0.0
var _home := Vector3.ZERO
var _alert := false
var _returning := false
var _patrol_goal := Vector3.ZERO
var _patrol_step := 0
var _patrol_wait := 0.0
var _alert_time := 0.0
var _alert_label: Label3D




func _ready() -> void:
	add_to_group("lock_targets")
	collision_layer = 2
	collision_mask = 1
	match kind:
		Kind.SCOUT:
			display_name = "ASH STALKER"
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
			display_name = "DIRE WARG"
			health += 3
			move_speed = 1.45
			attack_damage = 16
			attack_range = 2.3
			windup_duration = 0.95
			recovery_duration = 1.2
			body_color = Color(0.24, 0.1, 0.13)
			body_radius = 0.68
			body_height = 2.1
	_home = position
	_patrol_goal = _home
	_patrol_wait = 1.0 + absf(sin(_home.x + _home.z)) * 2.0
	_maximum_health = health
	_build_body()
	_alert_label = Label3D.new()
	_alert_label.text = "!"
	_alert_label.font_size = 48
	_alert_label.position.y = body_height + 0.95
	_alert_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_alert_label.modulate = Color(1, 0.8, 0.2)
	_alert_label.hide()
	add_child(_alert_label)


func _physics_process(delta: float) -> void:
	_strike_time = maxf(0.0, _strike_time - delta)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_hit_time = maxf(0.0, _hit_time - delta)
	_material.albedo_color = Color(1, 0.85, 0.65) if _hit_time > 0.0 else body_color
	if not is_instance_valid(target) or health <= 0:
		return

	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	_alert_time = maxf(0.0, _alert_time - delta)
	if _returning and position.distance_to(_home) < 1.0:
		_returning = false
		_patrol_goal = _home
		_patrol_wait = 1.5
	if not _returning and distance < 11.0 and not _alert:
		_alert = true
		_alert_time = 1.0
	if _alert and (position.distance_to(_home) > 20.0 or distance > 24.0):
		_alert = false
		_returning = true
		_alert_time = 0.0
	_alert_label.visible = _alert_time > 0.0
	if not _alert:
		_windup = 0.0
		_warning.hide()
		if not _returning:
			_patrol_wait = maxf(0.0, _patrol_wait - delta)
			if position.distance_to(_patrol_goal) < 0.5 and _patrol_wait == 0.0:
				_patrol_step += 1
				var angle := _patrol_step * PI * 0.5 + _home.x * 0.1
				_patrol_goal = _home + Vector3(cos(angle), 0, sin(angle)) * 2.5
				_patrol_wait = 1.5
		var destination := _home if _returning else _patrol_goal
		var home_offset := destination - position
		home_offset.y = 0.0
		var moving := home_offset.length() > 0.5 and (_returning or _patrol_wait == 0.0)
		var home_direction := home_offset.normalized() if moving else Vector3.ZERO
		var speed := move_speed if _returning else move_speed * 0.55
		velocity.x = home_direction.x * speed
		velocity.z = home_direction.z * speed
		if home_direction != Vector3.ZERO:
			rotation.y = lerp_angle(rotation.y, atan2(-home_direction.x, -home_direction.z), minf(1.0, delta * 6.0))
		velocity.y = velocity.y - GRAVITY * delta if not is_on_floor() else 0.0
		move_and_slide()
		return
	var direction := offset.normalized() if distance > 0.01 else Vector3.ZERO
	if _windup > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		_windup = maxf(0.0, _windup - delta)
		if _windup == 0.0:
			_warning.hide()
			_attack_cooldown = recovery_duration
			_strike_time = 0.2
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
	_strike_time = 0.0
	_windup = 0.0
	_warning.hide()
	_attack_cooldown = maxf(_attack_cooldown, 0.35)
	if health <= 0:
		_visual.show_defeat(get_parent())
		defeated.emit()
		queue_free()


func _build_body() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = body_color
	_material.roughness = 0.8
	_visual = preload("res://scripts/wolf_visual.gd").new()
	_visual.name = "Visual"
	_visual.kind = kind
	_visual.skin = _material
	add_child(_visual)
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


func _process(delta: float) -> void:
	if health <= 0:
		return
	var anticipation := 1.0 - _windup / windup_duration if _windup > 0.0 else 0.0
	var strike := _strike_time / 0.2
	var hurt := _hit_time / 0.18
	var speed := Vector2(velocity.x, velocity.z).length()
	_visual.position = Vector3(0, -anticipation * 0.06, -strike * 0.12 + hurt * 0.04)
	_visual.rotation.x = anticipation * 0.08 - strike * 0.12 + hurt * 0.12
	_visual.animate(delta, speed, anticipation, strike, hurt)