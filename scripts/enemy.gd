extends CharacterBody3D

signal defeated

const GRAVITY := 22.0
const BODY_LAYER := 6
const STRIKE_DURATION := 0.24
const CONTACT_TIME := 0.10
const BITE_ARC := 0.69
const WORLD_SOLIDS := 1 | 4 | 8 | 16
enum Kind { SHORE, SCOUT, BRUTE }

var navigation: Node
var target: Node3D
var health := 12
var kind := Kind.SHORE
var move_speed := 4.4
var patrol_speed := 1.18
var attack_damage := 8
var attack_range := 1.8
var windup_duration := 0.55
var recovery_duration := 0.8
var body_color := Color(0.48, 0.14, 0.055)
var body_radius := 0.72
var body_height := 2.1
var display_name := "EMBER WOLF"
var _maximum_health := 12
var _health_label: Label3D
var _attack_cooldown := 0.0
var _windup := 0.0
var _hit_time := 0.0
var _material: StandardMaterial3D
var _warning: MeshInstance3D
var _visual: Node3D
var _weapon_hurtbox: Area3D
var _strike_time := 0.0
var _home := Vector3.ZERO
var _alert := false
var _returning := false
var _patrol_goal := Vector3.ZERO
var _patrol_step := 0
var _patrol_wait := 0.0
var _alert_time := 0.0
var _alert_label: Label3D
var _growl: AudioStreamPlayer3D
static var _growl_stream: AudioStreamWAV
var _feedback: Node3D
var _bite_origin := Vector3.ZERO
var _bite_heading := Vector3.FORWARD
var _bite_pending := false
var _ground_speed := 0.0
var _patrol_stall := 0.0




func _ready() -> void:
	add_to_group("combat_enemies")
	collision_layer = 2
	collision_mask = 1
	match kind:
		Kind.SCOUT:
			display_name = "ASH STALKER"
			health = maxi(2, health - 1)
			move_speed = 5.8
			patrol_speed = 1.7
			attack_damage = 5
			attack_range = 1.6
			windup_duration = 0.4
			recovery_duration = 0.9
			body_color = Color(0.13, 0.4, 0.4)
			body_radius = 0.6
			body_height = 1.85
		Kind.BRUTE:
			display_name = "DIRE WARG"
			health += 3
			move_speed = 3.8
			patrol_speed = 0.8
			attack_damage = 16
			windup_duration = 0.95
			recovery_duration = 1.2
			body_color = Color(0.24, 0.1, 0.13)
	_home = position
	_patrol_goal = _home
	_patrol_wait = 1.0 + absf(sin(_home.x + _home.z)) * 2.0
	_maximum_health = health
	floor_snap_length = 0.28
	_build_body()
	_feedback = preload("res://scripts/wolf_attack_feedback.gd").new()
	_feedback.name = "AttackFeedback"
	add_child(_feedback)
	_build_growl()
	_alert_label = Label3D.new()
	_alert_label.text = "!"
	_alert_label.font_size = 48
	_alert_label.position.y = body_height + 0.95
	_alert_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_alert_label.modulate = Color(1, 0.8, 0.2)
	_alert_label.hide()
	add_child(_alert_label)


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_hit_time = maxf(0.0, _hit_time - delta)
	if not is_instance_valid(target) or health <= 0:
		return

	var offset := _flat_offset(global_position, target.global_position)
	var distance := offset.length()
	var direction := offset.normalized()
	_update_alert(distance, delta)
	var desired := Vector3.ZERO
	if _hit_time > 0.0:
		_cancel_bite()
	elif _strike_time > 0.0:
		_strike_time = maxf(0.0, _strike_time - delta)
		if _bite_pending:
			desired = _bite_heading * (4.4 if kind == Kind.SCOUT else 4.0)
	elif _windup > 0.0:
		if _windup > windup_duration * 0.42:
			_turn_toward(direction, 7.0 * delta)
		_windup = maxf(0.0, _windup - delta)
		if _windup == 0.0:
			_begin_lunge()
	elif not _alert:
		desired = _patrol_velocity(delta)
	else:
		var has_approach := distance < attack_range + 0.9 and _bite_path_clear()
		var approach_distance := distance - (attack_range - .08)
		if approach_distance <= 0.0 and has_approach:
			_turn_toward(direction, 8.0 * delta)
			if _attack_cooldown == 0.0 and _ground_speed < 0.75 and is_on_floor() and _forward().dot(direction) >= 0.87:
				_windup = windup_duration
				_bite_origin = global_position
				_warning.show()
		else:
			var approach_speed := clampf(approach_distance * 6.0 + .55, .55, move_speed) if has_approach else move_speed
			desired = _steer(target.global_position, approach_speed, delta)

	var planar := Vector3(velocity.x, 0, velocity.z)
	var rate := 23.0 if desired.is_zero_approx() else 13.0
	if _strike_time > 0.0:
		rate = 55.0
	planar = planar.move_toward(desired, rate * delta)
	velocity = Vector3(planar.x, velocity.y - GRAVITY * delta if not is_on_floor() else 0.0, planar.z)
	move_and_slide()
	_ground_speed = _flat_offset(Vector3.ZERO, get_position_delta()).length() / delta
	if _bite_pending and _strike_time <= STRIKE_DURATION - CONTACT_TIME:
		_resolve_bite()

func _update_alert(distance: float, delta: float) -> void:
	_alert_time = maxf(0.0, _alert_time - delta)
	if _returning and _flat_offset(position, _home).length() < 0.8:
		_returning = false
		_patrol_goal = _home
		_patrol_wait = 1.5
	if not _returning and not _alert and distance < 11.0 and absf(target.global_position.y - global_position.y) < 3.5:
		_alert = true
		_alert_time = 1.0
		_growl.play()
	if _alert and (position.distance_to(_home) > 20.0 or distance > 24.0):
		_alert = false
		_returning = true
		_alert_time = 0.0
		_cancel_bite()
	_alert_label.visible = _alert_time > 0.0

func _patrol_velocity(delta: float) -> Vector3:
	if _returning:
		return _steer(_home, move_speed, delta)
	if _flat_offset(position, _patrol_goal).length() < 0.55 or _patrol_stall > 1.25:
		_patrol_wait = maxf(0.0, _patrol_wait - delta)
		if _patrol_wait > 0.0:
			return Vector3.ZERO
		_patrol_step += 1
		var angle := _patrol_step * PI * 0.5 + _home.x * 0.1
		_patrol_goal = _home + Vector3(cos(angle), 0, sin(angle)) * 2.5
		_patrol_wait = 1.5
		_patrol_stall = 0.0
	elif _ground_speed < 0.15:
		_patrol_stall += delta
	else:
		_patrol_stall = 0.0
	return _steer(_patrol_goal, patrol_speed, delta)

func _steer(goal: Vector3, speed: float, delta: float) -> Vector3:
	var offset := _flat_offset(global_position, goal)
	var direction: Vector3 = navigation.direction(self, goal) if is_instance_valid(navigation) else offset.normalized()
	if direction.is_zero_approx():
		return Vector3.ZERO
	_turn_toward(direction, 7.0 * delta)
	var forward := _forward()
	var alignment := maxf(0.0, forward.dot(direction))
	return forward * minf(speed, offset.length() * 7.0) * alignment

func _flat_offset(from: Vector3, to: Vector3) -> Vector3:
	return Vector3(to.x - from.x, 0, to.z - from.z)

func _forward() -> Vector3:
	return -global_basis.z.normalized()

func _turn_toward(direction: Vector3, amount: float) -> void:
	if not direction.is_zero_approx():
		rotation.y = rotate_toward(rotation.y, atan2(-direction.x, -direction.z), amount)

func _begin_lunge() -> void:
	_warning.hide()
	_strike_time = STRIKE_DURATION
	_attack_cooldown = STRIKE_DURATION + recovery_duration
	_bite_heading = _forward()
	_bite_pending = true
	if is_on_floor():
		_feedback.kick(global_position - _bite_heading * 0.35, -_bite_heading)

func _bite_path_clear() -> bool:
	var delta_y := target.global_position.y - global_position.y
	if absf(delta_y) > 1.2:
		return false
	var exclude: Array[RID] = [get_rid()]
	if target is CollisionObject3D:
		exclude.append(target.get_rid())
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.65,
		target.global_position + Vector3.UP * 0.68, WORLD_SOLIDS, exclude)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _resolve_bite() -> void:
	_bite_pending = false
	var from_wolf := _flat_offset(global_position, target.global_position)
	var from_tell := _flat_offset(_bite_origin, target.global_position)
	_feedback.slash(global_position + Vector3.UP * 0.88 + _bite_heading * (attack_range * 0.73), _bite_heading)
	if from_tell.length() > attack_range or from_wolf.length() > attack_range or from_wolf.normalized().dot(_bite_heading) < BITE_ARC:
		return
	if not target.has_method("take_damage") or not _bite_path_clear():
		return
	var before: Variant = target.get("health")
	if target.has_method("take_melee_damage"):
		target.call("take_melee_damage", attack_damage, self)
	else:
		target.call("take_damage", attack_damage)
	if before != null and target.get("health") < before:
		_feedback.impact((target.global_position + global_position) * 0.5 + Vector3.UP * .92, _bite_heading)

func _cancel_bite() -> void:
	_windup = 0.0
	_strike_time = 0.0
	_bite_pending = false
	_warning.hide()

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	if amount <= 0:
		return
	preload("res://scripts/damage_number.gd").show_hit(self, mini(amount, health), body_height + 0.65)
	health -= amount
	_health_label.text = "%s  %d / %d" % [display_name, maxi(0, health), _maximum_health]
	_hit_time = 0.18
	_cancel_bite()
	_attack_cooldown = maxf(_attack_cooldown, 0.35)
	if health <= 0:
		collision_layer = 0
		collision_mask = 0
		if _weapon_hurtbox != null:
			_weapon_hurtbox.collision_layer = 0
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
	if target is PhysicsBody3D and target.get_collision_mask_value(BODY_LAYER):
		_fit_candidate_body(collision)
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

func _fit_candidate_body(collision: CollisionShape3D) -> void:
	# Keep the authored weapon target while fitting the physical capsule to the torso.
	_weapon_hurtbox = Area3D.new()
	_weapon_hurtbox.name = "WeaponHurtbox"
	_weapon_hurtbox.collision_layer = collision_layer
	_weapon_hurtbox.collision_mask = 0
	_weapon_hurtbox.monitoring = false
	var weapon_shape := CollisionShape3D.new()
	weapon_shape.shape = collision.shape
	weapon_shape.transform = collision.transform
	_weapon_hurtbox.add_child(weapon_shape)
	_weapon_hurtbox.add_to_group("weapon_hurtboxes")
	add_child(_weapon_hurtbox)

	collision_layer = 0
	set_collision_layer_value(BODY_LAYER, true)
	var torso := CapsuleShape3D.new()
	torso.radius = [.37, .31, .37][kind]
	torso.height = [1.92, 1.62, 1.92][kind]
	collision.shape = torso
	collision.position.y = torso.radius
	collision.rotation.x = PI * .5


func _process(delta: float) -> void:
	if health <= 0:
		return
	var anticipation := 1.0 - _windup / windup_duration if _windup > 0.0 else 0.0
	var strike := _strike_time / STRIKE_DURATION
	var hurt := clampf(_hit_time / 0.18, 0.0, 1.0)
	_material.albedo_color = Color(1, 0.85, 0.65) if hurt > 0.0 else body_color
	var terrain := global_basis.inverse() * get_floor_normal() if is_on_floor() else Vector3.UP
	_visual.rotation.x = lerpf(_visual.rotation.x, clampf(atan2(terrain.z, terrain.y), -.23, .23), delta * 9.0)
	_visual.rotation.z = lerpf(_visual.rotation.z, clampf(-atan2(terrain.x, terrain.y), -.23, .23), delta * 9.0)
	_visual.animate(delta, _ground_speed, anticipation, strike, hurt, clampf((_alert_time - 0.35) / 0.65, 0.0, 1.0))

func stagger(duration: float) -> void:
	if health <= 0:
		return
	_hit_time = maxf(_hit_time, duration)
	_attack_cooldown = maxf(_attack_cooldown, duration)
	_cancel_bite()

func _build_growl() -> void:
	if _growl_stream == null:
		# Original low, breathy growl; no external audio dependency.
		var samples := 8268
		var data := PackedByteArray()
		data.resize(samples * 2)
		var random := RandomNumberGenerator.new()
		random.seed = 7193
		for index in range(samples):
			var progress := float(index) / samples
			var time := float(index) / 11025.0
			var envelope := sin(progress * PI) * (1.0 - progress * 0.45)
			var voice := sin(TAU * (72.0 - progress * 18.0) * time) * 0.55 + sin(TAU * 43.0 * time) * 0.25 + random.randf_range(-0.2, 0.2)
			data.encode_s16(index * 2, int(voice * envelope * 10000))
		_growl_stream = AudioStreamWAV.new()
		_growl_stream.format = AudioStreamWAV.FORMAT_16_BITS
		_growl_stream.mix_rate = 11025
		_growl_stream.data = data
	_growl = AudioStreamPlayer3D.new()
	_growl.stream = _growl_stream
	_growl.max_distance = 24.0
	_growl.unit_size = 4.0
	_growl.volume_db = -8.0
	_growl.pitch_scale = [0.95, 1.12, 0.75][kind]
	add_child(_growl)

func _exit_tree() -> void:
	if is_instance_valid(_growl):
		_growl.stop()
		_growl.stream = null
