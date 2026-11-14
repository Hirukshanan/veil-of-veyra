extends CharacterBody3D

signal defeated

const MODEL = preload("res://assets/characters/demon_boar/demon_boar.glb")
const SPAWN := Vector3(26.5, 0.05, -19.5)
const REWARD_SHARDS := 20
const CHARGE_SPEED := 3.12
const CHARGE_DISTANCE := 6.24
const WARNING_SECONDS := 1.8
const RECOVERY_SECONDS := 1.4
const HIT_SECONDS := 0.8
const WORLD_MASK := 1 | 4 | 8
enum State { IDLE, PATROL, CHASE, FACE, WARNING, CHARGE, RECOVERY, HURT, RETURN, DEAD }

var target: Node3D
var health := 24
var state := State.IDLE
var animator: AnimationPlayer
var _home := Vector3.ZERO
var _maximum_health := 24
var _elapsed := 0.0
var _attack_delay := 0.0
var _hit_time := 0.0
var _flinch_cooldown := 0.0
var _hurt_duration := HIT_SECONDS
var _sense_time := 0.0
var _line_clear := false
var _sleep_time := 0.0
var _patrol_step := 0
var _patrol_goal := Vector3.ZERO
var _charge_direction := Vector3.FORWARD
var _charge_limit := CHARGE_DISTANCE
var _charge_travel := 0.0
var _hit_victim := false
var _recovery_speed := 0.0
var _steering := Vector3.ZERO
var _model: Node3D
var _body_collision: CollisionShape3D
var _contact_area: Area3D
var _warning: MeshInstance3D
var _warning_material: StandardMaterial3D
var _health_label: Label3D
var _materials: Array[StandardMaterial3D] = []
var _clip := ""

func _ready() -> void:
	add_to_group("combat_enemies")
	collision_layer = 2
	collision_mask = WORLD_MASK
	floor_snap_length = 0.3
	_home = global_position
	_patrol_goal = _home
	_maximum_health = health
	_build_body()
	if target is PhysicsBody3D:
		# Damage uses the tusk area; the charge must not slide around its victim.
		add_collision_exception_with(target)
	_play("idle", 0.0)

func _build_body() -> void:
	_model = MODEL.instantiate()
	_model.name = "ApprovedDemonBoar"
	add_child(_model)
	animator = _model.find_children("*", "AnimationPlayer", true, false)[0]
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip in animator.get_animation_list():
		animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if clip in ["idle", "walk", "run", "charge_attack"] else Animation.LOOP_NONE
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material: StandardMaterial3D = mesh.get_active_material(surface).duplicate()
			mesh.set_surface_override_material(surface, material)
			_materials.append(material)
	_body_collision = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 2.7
	_body_collision.shape = capsule
	_body_collision.rotation.x = PI * 0.5
	_body_collision.position.y = capsule.radius
	add_child(_body_collision)
	_contact_area = Area3D.new()
	_contact_area.name = "TuskContact"
	_contact_area.collision_layer = 0
	_contact_area.collision_mask = 1
	_contact_area.monitorable = false
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.05, 1.05, 1.1)
	collision.shape = shape
	collision.position = Vector3(0, 0.85, -0.95)
	_contact_area.add_child(collision)
	add_child(_contact_area)
	_warning = MeshInstance3D.new()
	_warning.name = "CommittedChargeLane"
	_warning.mesh = QuadMesh.new()
	_warning.rotation.x = -PI * 0.5
	_warning.position.y = 0.035
	_warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_warning_material = StandardMaterial3D.new()
	_warning_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_warning_material.albedo_color = Color(0.9, 0.24, 0.08, 0.22)
	_warning.material_override = _warning_material
	_warning.hide()
	add_child(_warning)
	_health_label = Label3D.new()
	_health_label.position.y = 1.95
	_health_label.font_size = 25
	_health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_health_label)
	_update_label()

func _physics_process(delta: float) -> void:
	_elapsed += delta
	_attack_delay = maxf(0.0, _attack_delay - delta)
	_hit_time = maxf(0.0, _hit_time - delta)
	_flinch_cooldown = maxf(0.0, _flinch_cooldown - delta)
	for material in _materials:
		material.emission_enabled = _hit_time > 0.0
		material.emission = Color(0.20, 0.08, 0.025)
	if state == State.DEAD:
		animator.advance(delta)
		if _elapsed > 14.0:
			queue_free()
		return
	var valid_target := is_instance_valid(target) and int(target.get("health")) > 0
	var offset := _flat(target.global_position - global_position) if valid_target else Vector3.ZERO
	var distance := offset.length() if valid_target else INF
	_model.visible = distance < 45.0
	_health_label.visible = distance < 18.0
	if distance > 36.0 and state in [State.IDLE, State.PATROL]:
		# One optional boar; far-away AI ticks twice a second and poses do not advance.
		_sleep_time += delta
		if _sleep_time < 0.5:
			return
		delta = _sleep_time
		_sleep_time = 0.0
	_sense_time -= delta
	if _sense_time <= 0.0:
		_sense_time = 0.2
		_line_clear = valid_target and distance < 22.0 and _clear_line(target)
		var wanted := offset.normalized() if valid_target else Vector3.ZERO
		_steering = _steer(wanted) if state == State.CHASE else Vector3.ZERO
	if state not in [State.IDLE, State.PATROL, State.RETURN] and (not valid_target or distance > 23.0 or _flat(global_position - _home).length() > 18.0):
		_enter(State.RETURN)
	var direction := offset.normalized() if distance > 0.01 and valid_target else Vector3.ZERO
	velocity.x = 0.0
	velocity.z = 0.0
	match state:
		State.IDLE, State.PATROL:
			if distance < 10.0 and _line_clear:
				_enter(State.CHASE)
			elif state == State.IDLE and _elapsed >= 1.4:
				_patrol_step += 1
				var angle := _patrol_step * 2.4
				_patrol_goal = _home + Vector3(cos(angle), 0, sin(angle)) * 2.2
				_enter(State.PATROL)
			elif state == State.PATROL:
				var home_offset := _flat(_patrol_goal - global_position)
				if home_offset.length() < 0.35 or _elapsed > 5.0:
					_enter(State.IDLE)
				else:
					_walk(_steer(home_offset.normalized()), 0.65, delta)
		State.CHASE:
			if distance < 6.4 and _line_clear and _attack_delay <= 0.0:
				_enter(State.FACE)
			else:
				_walk(_steering, 2.6, delta)
		State.FACE:
			if distance < 2.6 and _elapsed < 0.65:
				_walk(_steer(-direction), 0.65, delta)
			else:
				_turn(direction, delta)
				if _elapsed >= 0.25 and _line_clear and (-global_basis.z).dot(direction) > 0.995:
					_enter(State.WARNING)
		State.WARNING:
			_warning_material.albedo_color.a = 0.20 + sin(_elapsed * 8.0) * 0.06
			if _elapsed >= WARNING_SECONDS:
				_enter(State.CHARGE)
		State.CHARGE:
			velocity.x = _charge_direction.x * CHARGE_SPEED
			velocity.z = _charge_direction.z * CHARGE_SPEED
			_contact()
		State.RECOVERY:
			var speed := _recovery_speed * maxf(0.0, 1.0 - _elapsed / 0.5)
			velocity.x = _charge_direction.x * speed
			velocity.z = _charge_direction.z * speed
			if _elapsed >= RECOVERY_SECONDS:
				_attack_delay = 0.4
				_enter(State.CHASE if valid_target else State.RETURN)
		State.HURT:
			if _elapsed >= _hurt_duration:
				_enter(State.CHASE if valid_target else State.RETURN)
		State.RETURN:
			var home_offset := _flat(_home - global_position)
			if home_offset.length() < 0.4:
				_enter(State.IDLE)
			else:
				_walk(_steer(home_offset.normalized()), 0.65, delta)
	velocity.y = velocity.y - 22.0 * delta if not is_on_floor() else -0.1
	var before := global_position
	move_and_slide()
	if state == State.CHARGE:
		_charge_travel += _flat(global_position - before).length()
		_contact()
		if _charge_travel >= _charge_limit or _elapsed >= _charge_limit / CHARGE_SPEED or _blocked_by_wall():
			_enter(State.RECOVERY)
	elif state == State.RECOVERY and _blocked_by_wall():
		_recovery_speed = 0.0
	var speed := Vector2(velocity.x, velocity.z).length()
	if state in [State.IDLE, State.PATROL, State.CHASE, State.FACE, State.RETURN]:
		_play("run" if speed > 1.0 else ("walk" if speed > 0.05 else "idle"))
	animator.advance(delta)

func _enter(next: State) -> void:
	var previous := state
	state = next
	_elapsed = 0.0
	_warning.hide()
	match state:
		State.WARNING:
			_charge_direction = -global_basis.z.normalized()
			# Include the 0.78 m stopping path in obstacle clearance, but never damage in recovery.
			_charge_limit = maxf(0.0, (CHARGE_DISTANCE + 0.78) * _cast(_charge_direction * (CHARGE_DISTANCE + 0.78)) - 0.78)
			if _charge_limit < 1.2:
				_attack_delay = 1.0
				_enter(State.CHASE)
				return
			var lane_length := _charge_limit + 1.45
			_warning.mesh.size = Vector2(1.25, lane_length)
			_warning.position.z = -lane_length * 0.5
			_warning.show()
			_play("charge_warning")
		State.CHARGE:
			_charge_travel = 0.0
			_hit_victim = false
			_play("charge_attack")
		State.RECOVERY:
			_recovery_speed = CHARGE_SPEED if previous == State.CHARGE else 0.0
			_play("charge_recovery")
		State.HURT:
			_flinch_cooldown = 1.2
			_play("hit_reaction")
		State.DEAD:
			velocity = Vector3.ZERO
			collision_layer = 0
			collision_mask = 0
			_body_collision.set_deferred("disabled", true)
			_health_label.hide()
			_contact_area.set_deferred("monitoring", false)
			remove_from_group("combat_enemies")
			_play("death")
			defeated.emit()

func _walk(direction: Vector3, speed: float, delta: float) -> void:
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	_turn(direction, delta)

func _turn(direction: Vector3, delta: float) -> void:
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 7.0))

func _play(clip: String, blend := 0.12) -> void:
	if _clip != clip:
		_clip = clip
		animator.play(clip, blend)
		animator.advance(0.0)

func _excluded() -> Array[RID]:
	var result: Array[RID] = [get_rid()]
	if target is CollisionObject3D:
		result.append(target.get_rid())
	return result

func _cast(motion: Vector3) -> float:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _body_collision.shape
	query.transform = _body_collision.global_transform
	# Clearance casts start just above the floor; actual motion keeps full collision.
	query.transform.origin.y += 0.04
	query.margin = 0.01
	query.motion = motion
	query.collision_mask = WORLD_MASK
	query.exclude = _excluded()
	return get_world_3d().direct_space_state.cast_motion(query)[0]

func _steer(direction: Vector3) -> Vector3:
	if direction == Vector3.ZERO:
		return direction
	if _cast(direction * 1.3) > 0.98:
		return direction
	for angle in [PI / 3.0, -PI / 3.0, PI * 0.5, -PI * 0.5]:
		var alternative := direction.rotated(Vector3.UP, angle)
		if _cast(alternative * 1.3) > 0.98:
			return alternative
	return Vector3.ZERO

func _clear_line(body: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.85, body.global_position + Vector3.UP * 0.85, WORLD_MASK, _excluded())
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _blocked_by_wall() -> bool:
	for index in range(get_slide_collision_count()):
		if absf(get_slide_collision(index).get_normal().y) < 0.65:
			return true
	return false

func _contact() -> void:
	if state != State.CHARGE or _hit_victim or not is_instance_valid(target):
		return
	for body in _contact_area.get_overlapping_bodies():
		if body != target or _flat(body.global_position - global_position).dot(_charge_direction) <= 0.0 or not _clear_line(body):
			continue
		_hit_victim = true
		if body.has_method("take_charge_damage"):
			body.call("take_charge_damage", 18, _charge_direction)
		else:
			body.call("take_damage", 18)

func take_damage(amount: int) -> void:
	if health <= 0 or amount <= 0:
		return
	preload("res://scripts/damage_number.gd").show_hit(self, mini(amount, health), 1.7)
	health = maxi(0, health - amount)
	_hit_time = 0.12
	_update_label()
	if health == 0:
		_enter(State.DEAD)
	elif state not in [State.WARNING, State.CHARGE, State.RECOVERY, State.HURT] and _flinch_cooldown <= 0.0:
		_hurt_duration = HIT_SECONDS
		_enter(State.HURT)

func stagger(duration: float) -> void:
	if health <= 0:
		return
	# Existing heavy attacks can break charge poise; ordinary hits still deal full damage.
	_hurt_duration = maxf(HIT_SECONDS, duration)
	_enter(State.HURT)

func _update_label() -> void:
	_health_label.text = "DEMON BOAR  %d / %d" % [health, _maximum_health]

static func _flat(value: Vector3) -> Vector3:
	return Vector3(value.x, 0, value.z)
