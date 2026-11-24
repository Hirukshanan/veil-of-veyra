extends CharacterBody3D

signal bite_connected(point: Vector3)
signal defeated
signal health_changed(value: int, maximum: int)
signal state_changed

enum State { IDLE, ALERT, CHASE, WINDUP, EXECUTE, RECOVER, STAGGER, RAGE, DEAD }
enum Attack { CLAWS, SLAM, CHARGE, ROAR, BITE }

const CLIPS := ["Light_Claw_Left", "Ground_Slam", "Charge_Start", "Roar", "Forward_Bite"]
const COOLDOWNS := [3.8, 6.5, 7.0, 8.0, 2.4]
const RAGE_ATTACK_SPEED := 1.10
const RAGE_REACH := 1.10
const REACH := [3.35, 4.35, 11.0, 5.15, 3.10]
const WINDUP := [.41, 1.24, 1.0, .76, .46]
const ACTIVE := [.17, .20, 1.70, .22, .16]
const DAMAGE := [8, 21, 18, 5, 10]
const WORLD := 13
const MAX_HEALTH := 90
const CHARGE_SPEED := 5.2
const REVIEW_CHARGE_SPEED := 6.35
const CHARGE_AIM_TIME := .62
const CHARGE_AIM_LIMIT := .67

var target: CharacterBody3D
var playtest_combat := false
var health := MAX_HEALTH
var state := State.IDLE
var attack := Attack.BITE
var enraged := false
var _phase := 0.0
var _duration := 0.0
var _clock := 0.0
var _available := PackedFloat32Array([0, 0, 0, 0, 0])
var _last_attack := -1
var _strike := 0
var _spent := false
var _hit_time := 0.0 # Set by Aru's successful parry.
var _stagger_ready := 0.0
var _plan_time := 0.0
var _steering := Vector3.ZERO
var _waypoints: Array[Vector3] = []
var _next_detour := 0.0
var _wall_stagger := false
var _charge_dir := Vector3.ZERO
var _charge_start_yaw := 0.0
var _clip := ""
var _pace := 1.0
var _exclude: Array[RID] = []
@onready var animator: AnimationPlayer = $Model.find_children("*", "AnimationPlayer", true, false)[0]
@onready var warning: MeshInstance3D = $Warning

func _ready() -> void:
	add_to_group("combat_enemies")
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_exclude.append(get_rid())
	_play("Idle_Breathing_Loop")

func _play(clip: String, pace := 1.0, start := 0.0) -> void:
	_pace = pace
	if _clip != clip or start > 0.0 or not animator.is_playing():
		_clip = clip
		animator.play(clip, .07)
		animator.seek(start, true)

func _enter(next: State, duration := 0.0) -> void:
	state = next
	_duration = duration
	_phase = 0.0
	warning.visible = state == State.WINDUP
	state_changed.emit()

func _physics_process(delta: float) -> void:
	animator.advance(delta * _pace)
	if state == State.DEAD:
		if not animator.is_playing():
			if playtest_combat:
				_build_corpse_collision()
			set_physics_process(false)
		return
	_clock += delta
	_phase += delta
	var motion := Vector3.ZERO
	if not is_instance_valid(target) or target.get("health") <= 0:
		if state != State.IDLE:
			_enter(State.IDLE)
			_play("Idle_Breathing_Loop")
	else:
		if _exclude.size() == 1:
			_exclude.append(target.get_rid())
		else:
			_exclude[1] = target.get_rid()
		if _hit_time > 0.0:
			_hit_time = 0.0
			stagger(.55)
		motion = _tick(delta)
	velocity.x = motion.x
	velocity.z = motion.z
	velocity.y = minf(velocity.y, 0.0) - 22.0 * delta
	move_and_slide()
	if state == State.EXECUTE and attack == Attack.CHARGE:
		for i in get_slide_collision_count():
			var hit := get_slide_collision(i)
			if hit.get_collider() == target:
				_try_hit()
				_finish_charge(false)
				break
			if absf(hit.get_normal().y) < .65:
				_finish_charge(true)
				break

func _tick(delta: float) -> Vector3:
	var offset := target.global_position - global_position
	offset.y = 0
	var distance := offset.length()
	var direction := offset.normalized()
	match state:
		State.IDLE:
			if distance <= 16 and _clock >= _plan_time:
				_plan_time = _clock + .18
				if _clear_sight():
					_enter(State.ALERT, 1.06)
					_play("Alert_Aggro")
		State.ALERT, State.RAGE:
			_face(direction, delta)
			if _phase >= _duration:
				_enter(State.CHASE)
				_plan_time = 0
		State.CHASE:
			if distance > 21:
				_enter(State.IDLE)
				_play("Idle_Breathing_Loop")
				return Vector3.ZERO
			if _clock >= _plan_time:
				_plan_time = _clock + .12
				if playtest_combat and distance <= 3.35 and direction.dot(-global_basis.z) < .30 \
					and _last_attack != Attack.SLAM and _clock >= _available[Attack.SLAM] and _clear_sight() \
					and _supported(global_position, target.global_position):
					_begin(Attack.SLAM)
					return Vector3.ZERO
				if direction.dot(-global_basis.z) > .83 and _clear_sight():
					var choice := _choose(distance)
					if choice >= 0 and _supported(global_position, target.global_position):
						_begin(choice)
						return Vector3.ZERO
				_steering = _route(direction) if distance > 2.1 else Vector3.ZERO
			_face(_steering if _steering != Vector3.ZERO else direction, delta)
			if _steering == Vector3.ZERO:
				_play("Idle_Breathing_Loop")
			else:
				var fast := distance > 5.0
				var speed := 2.65 if fast else .94
				_play("Run_Loop" if fast else "Walk_Loop", 1.39 if fast else 1.55)
				return -global_basis.z * speed if _steering.dot(-global_basis.z) > .91 else Vector3.ZERO
		State.WINDUP:
			if attack == Attack.CHARGE:
				if playtest_combat and _phase < CHARGE_AIM_TIME and distance > 1.6 and direction != Vector3.ZERO:
					var offset_yaw := angle_difference(_charge_start_yaw, atan2(-direction.x, -direction.z))
					var desired := _charge_start_yaw + clampf(offset_yaw, -CHARGE_AIM_LIMIT, CHARGE_AIM_LIMIT)
					rotation.y = rotate_toward(rotation.y, desired, 1.65 * delta)
				elif not playtest_combat and _phase < .40:
					_face(direction, delta)
			if _phase >= _duration:
				if attack == Attack.CHARGE:
					_charge_dir = -global_basis.z
					_play("Charge_Loop", 2.07)
				_enter(State.EXECUTE, ACTIVE[attack] if attack == Attack.CHARGE else ACTIVE[attack] / _pace)
				_try_hit()
		State.EXECUTE:
			_try_hit()
			if attack == Attack.CHARGE:
				if _phase >= _duration or not _supported(global_position, global_position + _charge_dir * 1.6):
					_finish_charge(false)
				else:
					var speed := CHARGE_SPEED
					if playtest_combat:
						speed = lerpf(3.6, REVIEW_CHARGE_SPEED, smoothstep(0.0, .24, _phase))
					return _charge_dir * speed
			elif _phase >= _duration:
				if attack == Attack.CLAWS and _strike < 2:
					_strike += 1
					_windup()
				else:
					var remaining := animator.get_animation(_clip).length - animator.current_animation_position
					_pace = 1.18 if enraged else 1.0
					_enter(State.RECOVER, maxf(.38, remaining / _pace + (.08 if enraged else .28)))
		State.RECOVER, State.STAGGER:
			if _phase >= _duration:
				if state == State.RECOVER and _clip == "Charge_Impact_Stop" and _wall_stagger:
					_wall_stagger = false
					_stagger(.8, true)
				else:
					_enter(State.CHASE)
					_plan_time = 0
	return Vector3.ZERO

func _reach_scale() -> float:
	return RAGE_REACH if enraged else 1.0

func _choose(distance: float) -> int:
	var choices: Array[int] = []
	for candidate in Attack.size():
		if _clock < _available[candidate] or candidate == _last_attack:
			continue
		if distance <= REACH[candidate] * (1.0 if candidate == Attack.CHARGE else _reach_scale()) and (candidate != Attack.CHARGE or distance >= 4.4):
			choices.append(candidate)
	if choices.is_empty():
		return -1
	if not playtest_combat and enraged and Attack.CLAWS in choices:
		return Attack.CLAWS
	return choices.pick_random()

func _begin(choice: int) -> void:
	attack = choice as Attack
	_charge_start_yaw = rotation.y
	_last_attack = choice
	_waypoints.clear()
	_available[choice] = _clock + COOLDOWNS[choice] * (.78 if enraged else 1.0)
	_strike = 0
	_windup()

func _windup() -> void:
	_spent = false
	var clip: String = CLIPS[attack]
	var duration: float = WINDUP[attack]
	var start := 0.0
	if attack == Attack.CLAWS and _strike == 1:
		clip = "Light_Claw_Right"
		duration = .47
	elif attack == Attack.CLAWS and _strike == 2:
		clip = "Heavy_Double_Claw"
		start = .85
		duration = .45
	var pace := RAGE_ATTACK_SPEED if enraged else 1.0
	_play(clip, pace, start)
	_draw_warning()
	_enter(State.WINDUP, duration / pace)

func _face(direction: Vector3, delta: float) -> void:
	if direction.length_squared() > .01:
		rotation.y = rotate_toward(rotation.y, atan2(-direction.x, -direction.z), 2.4 * delta)

func _clear_sight() -> bool:
	return _ray(global_position + Vector3.UP, target.global_position + Vector3.UP).is_empty()

func _ray(a: Vector3, b: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(a, b, WORLD, _exclude)
	return get_world_3d().direct_space_state.intersect_ray(query)

func _supported(a: Vector3, b: Vector3) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) / .7))
	var previous := a.y
	for i in range(1, steps + 1):
		var point := a.lerp(b, float(i) / steps)
		var hit := _ray(point + Vector3.UP * .8, point + Vector3.DOWN * .85)
		if hit.is_empty() or hit.normal.y < .74 or absf(hit.position.y - previous) > .55:
			return false
		previous = hit.position.y
	return true

func _route(direction: Vector3) -> Vector3:
	while not _waypoints.is_empty() and global_position.distance_to(_waypoints.front()) < .52:
		_waypoints.pop_front()
	if _waypoints.is_empty() and _clock >= _next_detour:
		_next_detour = _clock + .65
		_plan_detour(direction)
	if not _waypoints.is_empty():
		var toward: Vector3 = _waypoints.front() - global_position
		toward.y = 0
		direction = toward.normalized()
	for angle: float in [0.0, .7, -.7, 1.32, -1.32]:
		var step := direction.rotated(Vector3.UP, angle)
		var end := global_position + step * 1.9
		var clear := true
		for side: float in [-1.0, 0.0, 1.0]:
			var lateral := step.cross(Vector3.UP) * side
			var from := global_position + lateral
			var to := end + lateral
			if not _ray(from + Vector3.UP, to + Vector3.UP).is_empty() or not _supported(from, to):
				clear = false
				break
		if clear:
			return step
	return Vector3.ZERO

func _plan_detour(direction: Vector3) -> void:
	var lift := Vector3.UP
	var obstruction := _ray(global_position + lift, target.global_position + lift)
	if obstruction.is_empty():
		return
	var center: Vector3 = obstruction.position - lift
	var side := direction.cross(Vector3.UP)
	for width: float in [3.8, 5.6, 7.5]:
		for sign_: float in [1.0, -1.0]:
			var corner := center + side * width * sign_
			var near_corner := corner - direction * 2.55
			var far_corner := corner + direction * 2.55
			if _corridor_clear(global_position, near_corner) and _corridor_clear(near_corner, far_corner) and _corridor_clear(far_corner, target.global_position):
				_waypoints.assign([near_corner, far_corner])
				return

func _corridor_clear(a: Vector3, b: Vector3) -> bool:
	var side := (b - a).normalized().cross(Vector3.UP) * 1.35
	for offset: Vector3 in [Vector3.ZERO, side, -side]:
		if not _ray(a + offset + Vector3.UP, b + offset + Vector3.UP).is_empty() or not _supported(a + offset, b + offset):
			return false
	return true

func _try_hit() -> void:
	if _spent or not is_instance_valid(target):
		return
	var point := to_local(target.global_position)
	if absf(point.y) > 1.45:
		return
	var flat := Vector2(point.x, -point.z)
	if attack == Attack.CHARGE:
		if absf(flat.x) > 1.33 * _reach_scale() or flat.y < 0 or flat.y > 2.45 * _reach_scale():
			return
	elif flat.length() > REACH[attack] * _reach_scale():
		return
	elif attack in [Attack.BITE, Attack.CLAWS] and flat.normalized().y < cos(_half_angle()):
		return
	if not _clear_sight() or not _supported(global_position, target.global_position):
		return
	_spent = true
	var amount: int = DAMAGE[attack]
	if attack == Attack.CHARGE:
		target.call("take_charge_damage", amount, _charge_dir)
	else:
		if attack == Attack.CLAWS and _strike == 2:
			amount += 5
		var previous_health: int = target.health
		target.call("take_melee_damage", amount, self)
		if attack == Attack.BITE and target.health < previous_health:
			bite_connected.emit(target.global_position + Vector3.UP)

func _finish_charge(wall: bool) -> void:
	_wall_stagger = wall
	_play("Charge_Impact_Stop", 1.2 if wall else 1.0)
	_enter(State.RECOVER, .32 if wall else (1.02 if playtest_combat else 1.2))

func _build_corpse_collision() -> void:
	var skeleton := $Model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var hip := to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Pelvis")).origin))
	var chest := to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("Chest")).origin))
	var axis := Vector3(chest.x - hip.x, 0.0, chest.z - hip.z)
	var body := StaticBody3D.new()
	body.name = "CorpseCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var collider := CollisionShape3D.new()
	var hull := CapsuleShape3D.new()
	hull.radius = .69
	hull.height = axis.length() + 1.52
	collider.shape = hull
	collider.position = (hip + chest) * .5
	collider.position.y = .70
	if axis.length_squared() > .01:
		collider.basis = Basis(Quaternion(Vector3.UP, axis.normalized()))
	body.add_child(collider)

func take_damage(amount: int) -> void:
	take_weapon_hit(amount, false, global_position)

func take_weapon_hit(amount: int, heavy: bool, _source: Vector3) -> void:
	if health <= 0 or amount <= 0:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		_enter(State.DEAD)
		collision_layer = 0
		collision_mask = 0
		_play("Death")
		defeated.emit()
	elif not enraged and health * 100 <= MAX_HEALTH * 40:
		enraged = true
		_wall_stagger = false
		_enter(State.RAGE, 1.55)
		_play("Roar", 1.45)
	elif heavy:
		stagger(.65)

func stagger(seconds: float) -> void:
	if state in [State.DEAD, State.RAGE, State.STAGGER] or _clock < _stagger_ready:
		return
	_stagger(seconds, state == State.RECOVER)

func _stagger(seconds: float, heavy: bool) -> void:
	_wall_stagger = false
	_stagger_ready = _clock + 2.5
	_enter(State.STAGGER, maxf(seconds, 1.05 if heavy else .55))
	_play("Heavy_Stagger" if heavy else "Hurt_Stagger")

func _half_angle() -> float:
	return deg_to_rad(39 if attack == Attack.BITE else 61)

func _draw_warning() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius: float = REACH[attack] * _reach_scale()
	if attack == Attack.CHARGE:
		var left := Vector3(-1.33 * _reach_scale(), 0, 0)
		var right := Vector3(1.33 * _reach_scale(), 0, 0)
		var speed := REVIEW_CHARGE_SPEED if playtest_combat else CHARGE_SPEED
		var end: Vector3 = Vector3.FORWARD * (speed * ACTIVE[attack] + 2.45 * _reach_scale())
		for vertex: Vector3 in [left, right, left + end, right, right + end, left + end]:
			mesh.surface_add_vertex(vertex)
	else:
		var arc := PI if attack in [Attack.ROAR, Attack.SLAM] else _half_angle()
		for i in 32:
			mesh.surface_add_vertex(Vector3.ZERO)
			for edge in [i, i + 1]:
				mesh.surface_add_vertex(Vector3.FORWARD.rotated(Vector3.UP, lerpf(-arc, arc, edge / 32.0)) * radius)
	mesh.surface_end()
	warning.mesh = mesh
