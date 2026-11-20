extends CharacterBody3D

signal defeated
signal state_changed(previous: int, current: int)

enum State { IDLE, PATROL, ALERT, CHASE, WINDUP, FLIGHT, STRIKE, RECOVER, EVADE, REPOSITION, STAGGER, RETURN, DEATH }
enum Attack { NONE, BITE, LEAP }

const WORLD_MASK := 1 | 4 | 8
const GROUND_MASK := 16
const GRAVITY := 22.0
const HIT_NUMBERS := preload("res://scripts/damage_number.gd")

@export_group("Sensing and movement")
@export var sense_range := 8.3
@export var leash_range := 13.0
@export var patrol_speed := .66
@export var chase_speed := 2.35
@export_group("Bite")
@export var bite_damage := 8
@export var bite_reach := 1.28
@export_range(.10, 2.0, .01) var bite_windup := .31
@export_range(.05, .5, .01) var bite_active := .12
@export_range(.15, 3.0, .01) var bite_recovery := .43
@export_group("Leap")
@export var leap_damage := 13
@export var leap_min_range := 2.65
@export var leap_max_range := 4.55
@export var leap_radius := .94
@export_range(.20, 2.0, .01) var leap_windup := .35
@export_range(.24, 1.2, .01) var leap_flight := .46
@export_range(.05, .5, .01) var leap_active := .12
@export_range(.20, 3.0, .01) var leap_recovery := .65
@export var leap_cooldown := 4.7
@export_group("Evade")
@export_range(0.0, 1.0) var evade_chance := .55
@export var evade_cooldown := 5.4

var health := 19
var target: Node3D
var navigation: Node
var state := State.IDLE
var action := Attack.NONE
var animator: AnimationPlayer

var _home: Vector3
var _goal: Vector3
var _elapsed := 0.0
var _sight_timer := 0.0
var _lost_sight := 0.0
var _visible_target := false
var _leap_cooldown := 0.6
var _evade_cooldown := 0.0
var _reaction := -1.0
var _observed_swing := -1
var _hit_time := 0.0
var _stagger_length := 0.0
var _hit_spent := false
var _bite_count := 0
var _patrol_index := 0
var _locked_direction := Vector3.FORWARD
var _launch: Vector3
var _landing: Vector3
var _blocked_flight := false
var _flight_contact := false
var _evade_direction: Vector3
var _recover_clip_start := 0.0
var _clip := ""
var _rng := RandomNumberGenerator.new()

@onready var _collider: CollisionShape3D = $Body
@onready var _model: Node3D = $Model
@onready var _feedback: Node3D = $Feedback

func _ready() -> void:
	_home = global_position
	_goal = _home
	_rng.randomize()
	if target is PhysicsBody3D and not target.get_collision_mask_value(2):
		add_collision_exception_with(target)
	add_to_group("combat_enemies")
	animator = _model.find_children("*", "AnimationPlayer", true, false).front() as AnimationPlayer
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_feedback.update_health(health)
	_play("Idle")

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if state == State.DEATH:
		animator.advance(delta)
		if _elapsed >= 5.0:
			queue_free()
		return
	if _hit_time > 0.0:
		# The existing hero writes this field on a successful melee parry.
		var parry := _hit_time
		_hit_time = 0.0
		stagger(parry)
	var target_alive := is_instance_valid(target) and int(target.get("health")) > 0
	var offset := _flat(target.global_position - global_position) if target_alive else Vector3.ZERO
	var distance := offset.length() if target_alive else INF
	if state == State.IDLE and distance > 27.0 and _flat(_home - global_position).length_squared() < .09:
		return
	_leap_cooldown = maxf(0.0, _leap_cooldown - delta)
	_evade_cooldown = maxf(0.0, _evade_cooldown - delta)
	_update_sight(delta, distance)
	if state in [State.ALERT, State.CHASE, State.REPOSITION, State.EVADE] and _should_return(distance):
		_enter(State.RETURN)
	var started_in := state
	var order := _think(delta, offset, distance)
	var before := global_position
	_move(order, delta)
	_advance_pose(delta, _flat(global_position - before).length() / delta)
	if started_in == state:
		_finish_step()

func _update_sight(delta: float, distance: float) -> void:
	_sight_timer -= delta
	if _sight_timer <= 0.0:
		_sight_timer = .19
		_visible_target = distance <= leash_range + 2.0 and _clear_sight()
	_lost_sight = 0.0 if _visible_target else _lost_sight + delta

func _should_return(distance: float) -> bool:
	return distance > leash_range + 2.0 or _flat(global_position - _home).length() > leash_range or _lost_sight > 1.35

func _think(delta: float, offset: Vector3, distance: float) -> Vector3:
	var heading := offset.normalized()
	match state:
		State.IDLE:
			if _visible_target and distance <= sense_range:
				_enter(State.ALERT)
			elif _elapsed >= 1.45 and distance < 22.0:
				_patrol_index += 1
				var candidate := _home + Vector3.FORWARD.rotated(Vector3.UP, _patrol_index * 2.39) * 2.6
				var path := _flat(candidate - global_position)
				if _path_clear(path.normalized(), path.length()):
					_goal = candidate
					_enter(State.PATROL)
				else:
					_elapsed = .5
		State.PATROL, State.REPOSITION, State.RETURN:
			var to_goal := _flat(_goal - global_position)
			var timeout := 8.0 if state == State.RETURN else (6.0 if state == State.PATROL else 2.0)
			if state == State.PATROL and _visible_target and distance <= sense_range:
				_enter(State.ALERT)
			elif state == State.REPOSITION and _observe_swing(delta, distance):
				return Vector3.ZERO
			elif to_goal.length() < .32 or _elapsed > timeout:
				if state == State.RETURN and to_goal.length() >= .32:
					_elapsed = 0.0
				else:
					_enter(State.CHASE if state == State.REPOSITION else State.IDLE)
			else:
				var direction := _route(_goal) if state == State.RETURN else to_goal.normalized()
				_face(direction, delta)
				var speed := chase_speed * .82 if state == State.RETURN else patrol_speed
				if state == State.REPOSITION:
					speed = maxf(patrol_speed, 1.85)
				return direction * minf(speed, to_goal.length() / delta)
		State.ALERT:
			_face(heading, delta)
			if _elapsed >= .50:
				_enter(State.CHASE)
		State.CHASE:
			if _observe_swing(delta, distance):
				return Vector3.ZERO
			if _reaction >= 0.0:
				_face(heading, delta)
				return Vector3.ZERO
			if _visible_target and distance <= leap_max_range:
				_face(heading, delta)
				if _aligned(heading) and is_on_floor():
					if distance <= bite_reach * .93:
						_begin_attack(Attack.BITE, heading)
						return Vector3.ZERO
					if distance >= leap_min_range and _leap_cooldown <= 0.0:
						var travel := distance - .50
						if _inside_leash(global_position + heading * travel) and _path_clear(heading, travel):
							_begin_attack(Attack.LEAP, heading, travel)
							return Vector3.ZERO
						_leap_cooldown = .40
				if distance <= bite_reach * .86:
					return Vector3.ZERO
			var steer := _route(target.global_position) if distance < INF else Vector3.ZERO
			if not _visible_target or distance > leap_max_range:
				_face(steer, delta)
			return steer * (patrol_speed if distance < 1.7 else chase_speed)
		State.FLIGHT:
			if not _blocked_flight and not _flight_contact:
				var fraction := clampf(_elapsed / maxf(leap_flight, .01), 0.0, 1.0)
				# Cover the lane once, with a brief rise in speed and a soft landing brake.
				fraction = lerpf(fraction, smoothstep(0.0, 1.0, fraction), .32)
				var expected := _launch.lerp(_landing, fraction)
				var remaining := maxf(0.0, _flat(expected - global_position).dot(_locked_direction))
				return _locked_direction * remaining / delta
		State.EVADE:
			_face(_evade_direction, delta, 10.0)
			var pulse := smoothstep(0.0, .075, _elapsed) * (1.0 - smoothstep(.23, .39, _elapsed))
			return _evade_direction * (4.1 * pulse) if not _blocked_flight else Vector3.ZERO
		State.STAGGER:
			if _elapsed >= _stagger_length:
				_enter(State.RETURN if _should_return(distance) else State.CHASE)
	return Vector3.ZERO

func _finish_step() -> void:
	match state:
		State.WINDUP:
			if _elapsed >= (bite_windup if action == Attack.BITE else leap_windup):
				_enter(State.STRIKE if action == Attack.BITE else State.FLIGHT)
		State.FLIGHT:
			if _elapsed >= leap_flight:
				if _blocked_flight or not is_on_floor() or (not _flight_contact and _flat(global_position - _landing).length() > .33):
					_enter(State.RECOVER)
				else:
					_feedback.land(global_position)
					_enter(State.STRIKE)
		State.STRIKE:
			_try_hit()
			if state == State.STRIKE and _elapsed >= (bite_active if action == Attack.BITE else leap_active):
				_enter(State.RECOVER)
		State.RECOVER:
			if _elapsed >= (bite_recovery if action == Attack.BITE else leap_recovery):
				var retreat := action == Attack.LEAP or _bite_count % 2 == 1
				action = Attack.NONE
				if retreat:
					_reposition()
				else:
					_enter(State.CHASE)
		State.EVADE:
			if _elapsed >= .40:
				_reposition()

func _move(order: Vector3, delta: float) -> void:
	var horizontal := order
	if state not in [State.FLIGHT, State.EVADE]:
		if state in [State.PATROL, State.CHASE, State.REPOSITION, State.RETURN] and not order.is_zero_approx():
			# Let the paws turn into the path before accelerating through a sharp corner.
			var alignment := _flat(-global_basis.z).normalized().dot(order.normalized())
			order *= smoothstep(.24, .90, alignment)
		horizontal = _flat(velocity).move_toward(order, (24.0 if order.is_zero_approx() else 16.0) * delta)
	velocity = horizontal + Vector3.UP * (minf(0.0, velocity.y) - GRAVITY * delta)
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0
	if state in [State.FLIGHT, State.EVADE] and is_on_wall():
		for index in range(get_slide_collision_count()):
			var contact := get_slide_collision(index)
			if absf(contact.get_normal().y) >= .65:
				continue
			if state == State.FLIGHT and contact.get_collider() == target:
				_flight_contact = true
			else:
				_blocked_flight = true
	var pitch_roll := Vector3.ZERO
	if is_on_floor():
		var normal := global_basis.inverse() * get_floor_normal()
		pitch_roll.x = clampf(atan2(normal.z, normal.y), -.19, .19)
		pitch_roll.z = clampf(-atan2(normal.x, normal.y), -.16, .16)
	_model.rotation = _model.rotation.lerp(pitch_roll, minf(1.0, delta * 9.0))

func _enter(next: State) -> void:
	var previous := state
	state = next
	_elapsed = 0.0
	if previous == State.FLIGHT:
		velocity = Vector3.ZERO
	if next != State.WINDUP and next != State.FLIGHT:
		_feedback.hide_warning()
	match next:
		State.ALERT:
			_play("Alert")
			_feedback.alert()
		State.WINDUP:
			_play("Bite" if action == Attack.BITE else "Quick Leap", .06)
		State.FLIGHT, State.EVADE:
			_blocked_flight = false
			_flight_contact = false
		State.RECOVER:
			_recover_clip_start = .54 if action == Attack.BITE else (.78 if previous == State.FLIGHT else .89)
		State.STAGGER:
			action = Attack.NONE
			_reaction = -1.0
			_play("Hit Reaction", .06, true)
		State.RETURN:
			_goal = _home
			_reaction = -1.0
		State.DEATH:
			velocity = Vector3.ZERO
			remove_from_group("combat_enemies")
			collision_layer = 0
			collision_mask = 0
			_collider.set_deferred("disabled", true)
			_feedback.defeat()
			_play("Death", .09)
			defeated.emit()
	state_changed.emit(previous, next)

func _begin_attack(kind: Attack, direction: Vector3, travel := 0.0) -> void:
	action = kind
	_hit_spent = false
	_reaction = -1.0
	_locked_direction = -global_basis.z if direction.is_zero_approx() else direction
	velocity = Vector3.ZERO
	if kind == Attack.LEAP:
		_leap_cooldown = leap_cooldown
		_launch = global_position
		_landing = _launch + direction * travel
		_feedback.warn_landing(_landing, leap_radius)
	else:
		_bite_count += 1
	_enter(State.WINDUP)

func _try_hit() -> void:
	if _hit_spent or not is_instance_valid(target) or int(target.get("health")) <= 0:
		return
	var difference := target.global_position - global_position
	var offset := _flat(difference)
	var reach := bite_reach if action == Attack.BITE else leap_radius
	if action == Attack.LEAP and _flight_contact:
		# The torso stops at body contact. The leap still strikes ahead of it.
		var forward_gap := (_landing - global_position).dot(_locked_direction)
		offset -= _locked_direction * clampf(forward_gap, 0.0, .65)
	if offset.length_squared() > reach * reach or absf(difference.y) > .85 or not _clear_sight():
		return
	if action == Attack.BITE and offset.length_squared() > .04 and offset.normalized().dot(_locked_direction) < .68:
		return
	_hit_spent = true
	var before := int(target.get("health"))
	target.take_melee_damage(bite_damage if action == Attack.BITE else leap_damage, self)
	if int(target.get("health")) < before:
		_feedback.impact()
	if _hit_time > 0.0:
		var parry := _hit_time
		_hit_time = 0.0
		stagger(parry)

func _observe_swing(delta: float, distance: float) -> bool:
	if not is_instance_valid(target) or not is_on_floor() or _evade_cooldown > 0.0:
		_reaction = -1.0
		return false
	var swing := int(target.get("_swing_id"))
	var remaining := float(target.get("_heavy_time"))
	if remaining > 0.0 and swing != _observed_swing:
		_observed_swing = swing
		# Only read the visible heavy wind-up, with time for a physical sidestep.
		_reaction = .20 if remaining >= .93 and _visible_target and distance >= .72 and distance <= 2.60 and _rng.randf() < evade_chance else -1.0
	if _reaction < 0.0 or remaining < .63:
		_reaction = -1.0
		return false
	_reaction -= delta
	if _reaction > 0.0:
		return false
	_reaction = -1.0
	if distance < .72 or distance > 2.60 or not _visible_target:
		return false
	var away := _flat(global_position - target.global_position).normalized()
	if away.dot(-target.global_basis.z) < .60:
		return false
	var side := _flat(target.global_basis.x).normalized()
	if _rng.randf() < .5:
		side = -side
	for option in [side, -side]:
		var escape: Vector3 = (option + away * .34).normalized()
		var destination := global_position + escape * 1.12
		var relative := _flat(destination - target.global_position)
		var leaves_arc := relative.length() > 2.62 or relative.normalized().dot(-target.global_basis.z) < .50
		if leaves_arc and _inside_leash(destination) and _path_clear(escape, 1.23):
			_evade_direction = escape
			_evade_cooldown = evade_cooldown
			_enter(State.EVADE)
			return true
	return false

func _reposition() -> void:
	if not is_instance_valid(target) or _should_return(_flat(target.global_position - global_position).length()):
		_enter(State.RETURN)
		return
	var away := _flat(global_position - target.global_position).normalized()
	var angle := .64 if away != Vector3.ZERO and _flat(global_position - target.global_position).length() < 2.0 else 1.17
	var side := 1.0 if _rng.randf() < .5 else -1.0
	for turn in [angle * side, -angle * side, 0.0]:
		var direction := away.rotated(Vector3.UP, turn)
		var point := global_position + direction * 1.35
		if _inside_leash(point) and _path_clear(direction, 1.35):
			_goal = point
			_enter(State.REPOSITION)
			return
	_enter(State.CHASE)

func _advance_pose(delta: float, speed: float) -> void:
	if state in [State.WINDUP, State.FLIGHT, State.STRIKE, State.RECOVER]:
		var phase := 0.0
		var bite := action == Attack.BITE
		match state:
			State.WINDUP:
				phase = lerpf(0.0, .39 if bite else .32, _part(bite_windup if bite else leap_windup))
			State.FLIGHT:
				phase = lerpf(.32, .78, _part(leap_flight))
			State.STRIKE:
				phase = lerpf(.39 if bite else .78, .54 if bite else .89, _part(bite_active if bite else leap_active))
			State.RECOVER:
				phase = lerpf(_recover_clip_start, 1.0, _part(bite_recovery if bite else leap_recovery))
		animator.seek(animator.current_animation_length * phase, true, true)
		return
	if state not in [State.ALERT, State.STAGGER]:
		_play("Run" if speed > 1.14 else ("Walk" if speed > .17 else "Idle"))
	var before := animator.current_animation_position
	var rate := clampf(speed / 1.17, .85, 2.1) if _clip == "Run" else 1.0
	if _clip == "Walk":
		rate = clampf(speed / .44, .72, 1.85)
	animator.advance(delta * rate)
	if is_on_floor() and speed > .28:
		_feedback.steps(_clip, before, animator.current_animation_position, animator.current_animation_length)

func _play(clip: String, blend := .12, restart := false) -> void:
	if _clip == clip and not restart:
		return
	_clip = clip
	if restart:
		animator.stop(true)
	animator.play(clip, blend)
	animator.advance(0.0)

func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	HIT_NUMBERS.show_hit(self, mini(amount, health), 1.19)
	health = maxi(0, health - amount)
	_feedback.update_health(health)
	if health == 0:
		_enter(State.DEATH)
	else:
		_feedback.hurt()
		# Light strikes interrupt preparation. The airborne leap keeps momentum.
		if state not in [State.FLIGHT, State.STAGGER] and (state != State.RECOVER or _elapsed > .20):
			stagger(.26)

func stagger(duration: float) -> void:
	if health <= 0:
		return
	if state == State.STAGGER:
		var until := maxf(_stagger_length, _elapsed + duration)
		_stagger_length = until
		return
	_stagger_length = duration
	velocity = Vector3.ZERO
	_enter(State.STAGGER)

func _route(destination: Vector3) -> Vector3:
	if is_instance_valid(navigation):
		return navigation.direction(self, destination)
	return _flat(destination - global_position).normalized()

func _face(direction: Vector3, delta: float, speed := 6.8) -> void:
	if not direction.is_zero_approx():
		rotation.y = rotate_toward(rotation.y, atan2(-direction.x, -direction.z), delta * speed)

func _aligned(direction: Vector3) -> bool:
	return direction.is_zero_approx() or -global_basis.z.dot(direction) > .962

func _inside_leash(point: Vector3) -> bool:
	return _flat(point - _home).length_squared() <= leash_range * leash_range

func _clear_sight() -> bool:
	if not is_instance_valid(target):
		return false
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * .63,
		target.global_position + Vector3.UP * .76, WORLD_MASK, _excluded())
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _path_clear(direction: Vector3, distance: float) -> bool:
	if direction.is_zero_approx() or distance <= .01:
		return false
	var space := get_world_3d().direct_space_state
	var excluded := _excluded()
	var sweep := PhysicsShapeQueryParameters3D.new()
	sweep.shape = _collider.shape
	sweep.collision_mask = WORLD_MASK
	sweep.exclude = excluded
	sweep.margin = .009
	var facing := Basis(Vector3.UP, atan2(-direction.x, -direction.z))
	var orientation := facing * _collider.basis
	var count := maxi(1, ceili(distance / .65))
	var previous := Vector3.ZERO
	for index in range(count + 1):
		var point := global_position + direction * distance * float(index) / count
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.65, point - Vector3.UP * 1.65, GROUND_MASK)
		var ground := space.intersect_ray(ray)
		if ground.is_empty() or ground.normal.y < .80:
			return false
		var supported: Vector3 = ground.position + facing * _collider.position + Vector3.UP * .15
		sweep.transform = Transform3D(orientation, supported)
		if not space.intersect_shape(sweep, 1).is_empty():
			return false
		if index != 0:
			if absf(supported.y - previous.y) > .37:
				return false
			sweep.transform.origin = previous
			sweep.motion = supported - previous
			if space.cast_motion(sweep)[0] < .985:
				return false
			sweep.motion = Vector3.ZERO
		previous = supported
	return true

func _excluded() -> Array[RID]:
	var out: Array[RID] = [get_rid()]
	if target is CollisionObject3D:
		out.push_back(target.get_rid())
	return out

func _part(length: float) -> float:
	return clampf(_elapsed / maxf(length, .01), 0.0, 1.0)

static func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
