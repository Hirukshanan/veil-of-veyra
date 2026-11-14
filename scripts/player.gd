extends CharacterBody3D

signal health_changed(value: int, maximum: int)
signal defeated

const MOVE_SPEED := 5.2
const SPRINT_SPEED := 8.3
var stamina := 100.0
var sprint_enabled := false
const DODGE_SPEED := 12.0
const GRAVITY := 22.0
const JUMP_SPEED := 7.2
var _jumping := false
const ATTACK_DURATION := 0.22
const HEAVY_COST := 40.0
const HEAVY_WINDUP := 0.6
const HEAVY_DURATION := 1.1
var _heavy_time := 0.0
var _heavy_warning: MeshInstance3D
var rescue_position := Vector3(0, 1, 27)

const ATTACK_BUFFER_WINDOW := 0.18
const LOCK_RANGE := 14.0
const SPIRIT_MAX := 100
const BURST_RADIUS := 3.0

var health := 100
var max_health := 100
var attack_damage := 1
var _touch_move := Vector2.ZERO
var _dodge_direction := Vector3.ZERO
var _dodge_time := 0.0
var _dodge_cooldown := 0.0
var _attack_cooldown := 0.0
var _attack_time := 0.0
var _invulnerability_time := 0.0
var _camera_pivot: Node3D
var _camera_arm: SpringArm3D
var _attack_area: Area3D
var _weapon: Node3D
var _blade_material: StandardMaterial3D
var _visual: Node3D
var _hit_time := 0.0
var combo_step := 0
var _combo_window := 0.0
var camera_sensitivity := 1.0
var invert_y := false
var left_handed_controls := false
var _camera_pointer := -1
var level := 1
var guarding := false
var _parry_window := 0.0
var _sound: AudioStreamPlayer
var _sounds: Dictionary = {}
var locked_target: Node3D
var _lock_marker: Label3D
var spirit := 0
var _burst_requested := false
var _swing_id := 0
var _attack_buffer := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1 | 8
	_build_character()
	_build_camera()
	_build_attack_area()
	_build_heavy_warning()
	_build_sounds()
	_lock_marker = Label3D.new()
	_lock_marker.text = "◆"
	_lock_marker.modulate = Color(1.0, 0.85, 0.3)
	_lock_marker.font_size = 48
	_lock_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_lock_marker)
	_lock_marker.top_level = true
	_lock_marker.hide()
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	_parry_window=maxf(0,_parry_window-delta)
	if health <= 0:
		return
	if position.y < -8:
		position = rescue_position
		velocity = Vector3.ZERO
		take_damage(20)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_heavy_time = maxf(0.0, _heavy_time - delta)
	if _attack_buffer > 0.0:
		if _attack_cooldown <= 0.0 and _dodge_time <= 0.0:
			_attack_buffer = 0.0
			attack()
		else:
			_attack_buffer = maxf(0.0, _attack_buffer - delta)
	_combo_window = maxf(0.0, _combo_window - delta)
	if _combo_window == 0.0:
		combo_step = 0
	_hit_time = maxf(0.0, _hit_time - delta)
	_attack_time = maxf(0.0, _attack_time - delta)
	_dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)
	_invulnerability_time = maxf(0.0, _invulnerability_time - delta)
	_blade_material.emission_enabled = _attack_time > 0.0
	_blade_material.emission = Color(1.0, 0.4, 0.06) if _heavy_time > 0.0 else Color(0.12, 0.56, 0.39)

	var input_vector := _touch_move
	var keyboard_vector := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if keyboard_vector.length_squared() > 0.01:
		input_vector = keyboard_vector
	if Input.is_action_just_pressed(&"sprint"):
		toggle_sprint()
	if Input.is_action_just_pressed(&"attack"):
		attack()
	if Input.is_action_just_pressed(&"heavy_attack"):
		heavy_attack()
	if Input.is_action_just_pressed(&"dodge"):
		dodge()
	if Input.is_action_just_pressed(&"target_lock"):
		toggle_target_lock()
	if Input.is_action_just_pressed(&"spirit_burst"):
		spirit_burst()
	if _burst_requested:
		_burst_requested = false
		if spirit >= SPIRIT_MAX and _attack_cooldown <= 0.0:
			_perform_spirit_burst()
	_update_target_lock(delta)

	var direction := Vector3(input_vector.x, 0, input_vector.y).rotated(Vector3.UP, _camera_pivot.global_rotation.y)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	var move_speed := _sprint_speed(delta, direction.length())
	if _heavy_time > 0.0:
		move_speed *= 0.35
	if _dodge_time > 0.0:
		_dodge_time -= delta
		velocity.x = _dodge_direction.x * DODGE_SPEED
		velocity.z = _dodge_direction.z * DODGE_SPEED
	else:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		if direction.length_squared() > 0.01 and not is_instance_valid(locked_target):
			rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 12.0)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif not _jumping:
		velocity.y = 0.0
	move_and_slide()
	if is_on_floor():
		_jumping = false
	_visual.update_motion(delta, Vector2(velocity.x, velocity.z).length(), _hit_time > 0, is_on_floor())
	_camera_pivot.global_position = global_position + Vector3(0, 1.2, 0)


func can_jump() -> bool:
	return health > 0 and not get_tree().paused and is_on_floor() and not _jumping and _dodge_time <= 0.0 and _attack_cooldown <= 0.0 and _hit_time <= 0.0

func jump() -> void:
	if not can_jump():
		return
	_jumping = true
	velocity.y = JUMP_SPEED
	_visual.action("Jump_Start", 0.12)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action(&"guard") and not event.echo:
		if event.pressed: start_guard()
		else: end_guard()
	if event is InputEventScreenTouch and not event.pressed and event.index == _camera_pointer:
		_camera_pointer = -1
	if event is InputEventScreenDrag and event.index == _camera_pointer:
		if not get_tree().paused and health > 0:
			_rotate_camera(event.relative)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed(&"jump"):
		jump()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or health <= 0:
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_rotate_camera(event.relative)
	elif event is InputEventScreenTouch and event.pressed and not event.canceled and _camera_pointer == -1:
		var width := get_viewport().get_visible_rect().size.x
		var in_camera_zone: bool = (event.position.x <= width * 0.58) if left_handed_controls else (event.position.x >= width * 0.42)
		if in_camera_zone:
			_camera_pointer = event.index

func cancel_touch_camera() -> void:
	_camera_pointer = -1


func _rotate_camera(relative: Vector2) -> void:
	clear_target_lock()
	_camera_pivot.rotation.y -= relative.x * 0.005 * camera_sensitivity
	_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x - relative.y * 0.003 * camera_sensitivity * (-1.0 if invert_y else 1.0), -0.32, 0.5)


func set_move_input(value: Vector2) -> void:
	_touch_move = value


func _can_lock(candidate: Node3D) -> bool:
	if not is_instance_valid(candidate) or candidate.is_queued_for_deletion() or int(candidate.get("health")) <= 0 or global_position.distance_to(candidate.global_position) > LOCK_RANGE:
		return false
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, candidate.global_position + Vector3.UP, 1|4)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func toggle_target_lock() -> void:
	if health <= 0 or get_tree().paused:
		return
	if is_instance_valid(locked_target):
		clear_target_lock()
		return
	var nearest := LOCK_RANGE + 0.01
	var boss_selected := false
	for candidate in get_tree().get_nodes_in_group("lock_targets"):
		if _can_lock(candidate):
			var distance := global_position.distance_to(candidate.global_position)
			var boss: bool = candidate.is_in_group("boss_targets")
			if (boss and not boss_selected) or (boss == boss_selected and distance < nearest):
				nearest = distance
				locked_target = candidate
				boss_selected = boss
	_update_target_lock(0.0)

func switch_target_lock() -> void:
	if health <= 0 or get_tree().paused:
		return
	if not is_instance_valid(locked_target):
		toggle_target_lock()
		return
	var candidates: Array[Node3D] = []
	for candidate in get_tree().get_nodes_in_group("lock_targets"):
		if _can_lock(candidate): candidates.append(candidate)
	candidates.sort_custom(func(a: Node3D, b: Node3D):
		var pa := a.global_position - global_position
		var pb := b.global_position - global_position
		var aa := atan2(pa.x, -pa.z)
		var ab := atan2(pb.x, -pb.z)
		return a.get_instance_id() < b.get_instance_id() if is_equal_approx(aa,ab) else aa < ab)
	if candidates.is_empty():
		clear_target_lock()
	else:
		locked_target = candidates[(candidates.find(locked_target) + 1) % candidates.size()]
		_update_target_lock(0.0)


func clear_target_lock() -> void:
	locked_target = null
	if is_instance_valid(_lock_marker):
		_lock_marker.hide()


func _update_target_lock(delta: float) -> void:
	if not _can_lock(locked_target):
		clear_target_lock()
		return
	var offset := locked_target.global_position - global_position
	if Vector2(offset.x, offset.z).length_squared() > 0.01:
		var yaw := atan2(-offset.x, -offset.z)
		rotation.y = yaw
		_camera_pivot.rotation.y = lerp_angle(_camera_pivot.rotation.y, yaw, 1.0 - exp(-6.0 * delta))
	_lock_marker.global_position = locked_target.global_position + Vector3(0, 3.7, 0)
	_lock_marker.show()


func attack() -> void:
	end_guard()
	if get_tree().paused or health <= 0:
		return
	if _attack_cooldown > 0.0:
		if _attack_cooldown <= ATTACK_BUFFER_WINDOW:
			_attack_buffer = ATTACK_BUFFER_WINDOW
		return
	sprint_enabled = false
	_attack_buffer = 0.0
	combo_step = combo_step % 3 + 1
	_combo_window = 0.95
	_attack_cooldown = 0.55 if combo_step == 3 else 0.32
	_attack_time = ATTACK_DURATION
	_visual.action("Sword_Attack", _attack_cooldown)
	play_sound("sword")
	var damage := attack_damage * (2 if combo_step == 3 else 1)
	_swing_id += 1
	var swing_id := _swing_id
	# Resolve contact after the visible windup; pausing freezes this timer.
	await get_tree().create_timer(0.20 if combo_step == 3 else 0.12, false, true).timeout
	await get_tree().physics_frame
	if health <= 0 or swing_id != _swing_id:
		return
	var connected := false
	for body in _attack_area.get_overlapping_bodies():
		if body.has_method("take_damage") and int(body.get("health")) > 0:
			var before := int(body.get("health"))
			body.call("take_damage", damage)
			connected = connected or int(body.get("health")) < before
	if connected:
		spirit = mini(SPIRIT_MAX, spirit + 25)


func spirit_burst() -> void:
	end_guard()
	if get_tree().paused or health <= 0 or spirit < SPIRIT_MAX or _attack_cooldown > 0.0:
		return
	_burst_requested = true


func _perform_spirit_burst() -> void:
	sprint_enabled = false
	spirit = 0
	_visual.action("Spell_Simple_Shoot", 0.65)
	_attack_cooldown = 0.65
	combo_step = 0
	_combo_window = 0.0
	var sphere := SphereShape3D.new()
	sphere.radius = BURST_RADIUS
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP)
	query.collision_mask = 2
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 32):
		var body: Node3D = hit.collider
		if body.has_method("take_damage") and int(body.get("health")) > 0:
			body.call("take_damage", attack_damage * 3)
	play_sound("sword")
	var pulse := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = BURST_RADIUS
	disc.bottom_radius = BURST_RADIUS
	disc.height = 0.04
	pulse.mesh = disc
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.2, 0.9, 1.0, 0.6)
	pulse.material_override = material
	add_child(pulse)
	pulse.top_level = true
	pulse.global_position = global_position + Vector3(0, 0.08, 0)
	pulse.scale = Vector3(0.15, 1, 0.15)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(pulse, "scale", Vector3.ONE, 0.3)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.35)
	tween.chain().tween_callback(pulse.queue_free)


func dodge() -> void:
	end_guard()
	if get_tree().paused or _dodge_cooldown > 0.0 or health <= 0:
		return
	var input_vector := _touch_move
	var keyboard_vector := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if keyboard_vector.length_squared() > 0.01:
		input_vector = keyboard_vector
	_dodge_direction = Vector3(input_vector.x, 0, input_vector.y).rotated(Vector3.UP, _camera_pivot.global_rotation.y)
	if _dodge_direction.length_squared() < 0.01:
		_dodge_direction = Vector3(0, 0, -1).rotated(Vector3.UP, _camera_pivot.global_rotation.y)
	_dodge_direction = _dodge_direction.normalized()
	_dodge_time = 0.2
	cancel_swing()
	_visual.action("Roll", 0.4)
	play_sound("dodge")
	_dodge_cooldown = 0.65
	_invulnerability_time = 0.35


func start_guard() -> void:
	if get_tree().paused or health<=0 or stamina<20 or _attack_cooldown>0 or _dodge_time>0: return
	if not guarding:
		guarding=true
		_parry_window=0.18
		sprint_enabled=false

func end_guard() -> void:
	guarding=false
	_parry_window=0.0

func take_damage(amount: int, attacker: Node3D=null) -> void:
	if _invulnerability_time > 0.0 or health <= 0:
		return
	if guarding and is_instance_valid(attacker) and stamina>=20:
		var direction:=attacker.global_position-global_position
		direction.y=0
		if direction.normalized().dot(-global_basis.z)>=0.15:
			stamina-=20
			if _parry_window>0:
				_parry_window=0
				attacker.set("_hit_time",0.4)
				play_sound("sword")
				return
			amount=maxi(1,ceili(amount*0.3))
	cancel_swing()
	health = maxi(0, health - amount)
	play_sound("hurt")
	_hit_time = 0.18
	_visual.action("Death01" if health == 0 else "Hit_Chest", 1.2 if health == 0 else 0.18)
	_invulnerability_time = 0.45
	health_changed.emit(health, max_health)
	if health == 0:
		_burst_requested = false
		clear_target_lock()
		_touch_move = Vector2.ZERO
		defeated.emit()

func take_melee_damage(amount: int, attacker: Node3D) -> void:
	take_damage(amount,attacker)


func _build_sounds() -> void:
	_sound = AudioStreamPlayer.new()
	_sound.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sound)
	# Original synthesized placeholder cues; replace with final sound design later.
	for cue in ["sword", "dodge", "hurt"]:
		var data := PackedByteArray()
		var samples := 6615
		data.resize(samples * 2)
		var frequency := 660.0 if cue == "sword" else (330.0 if cue == "dodge" else 110.0)
		for index in range(samples):
			var progress := float(index) / samples
			var phase := TAU * frequency * (float(index) / 22050.0) * (1.0 - 0.4 * progress)
			var envelope := minf(progress * 40.0, 1.0) * pow(1.0 - progress, 3)
			data.encode_s16(index * 2, int(sin(phase) * envelope * 8000.0))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		stream.data = data
		_sounds[cue] = stream


func play_sound(cue: String) -> void:
	_sound.stream = _sounds[cue]
	_sound.play()


func _exit_tree() -> void:
	if is_instance_valid(_sound):
		_sound.stop()


func _build_character() -> void:
	_visual = preload("res://scripts/hero_visual.gd").new()
	add_child(_visual)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

	_build_weapon()


func _build_weapon() -> void:
	_weapon = Node3D.new()
	_visual.hand.add_child(_weapon)
	_weapon.position = Vector3(0, 0.08, 0.18)
	_weapon.rotation.x = PI / 2.0

	var blade_instance := MeshInstance3D.new()
	blade_instance.mesh = _make_curved_blade()
	_blade_material = StandardMaterial3D.new()
	_blade_material.albedo_color = Color(0.59, 0.87, 0.78)
	_blade_material.metallic = 0.55
	_blade_material.roughness = 0.28
	_blade_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_blade_material.emission = Color(0.12, 0.56, 0.39)
	blade_instance.material_override = _blade_material
	_weapon.add_child(blade_instance)

	var guard := MeshInstance3D.new()
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.34, 0.07, 0.13)
	guard.mesh = guard_mesh
	guard.position.y = -0.035
	guard.material_override = _weapon_material(Color(0.73, 0.49, 0.19), 0.5, 0.35)
	_weapon.add_child(guard)

	var grip := MeshInstance3D.new()
	var grip_mesh := CylinderMesh.new()
	grip_mesh.top_radius = 0.055
	grip_mesh.bottom_radius = 0.065
	grip_mesh.height = 0.34
	grip_mesh.radial_segments = 8
	grip.mesh = grip_mesh
	grip.position.y = -0.21
	grip.material_override = _weapon_material(Color(0.19, 0.12, 0.1), 0.0, 0.82)
	_weapon.add_child(grip)


func _make_curved_blade() -> ArrayMesh:
	var left_edge := PackedVector2Array([
		Vector2(-0.045, 0.025),
		Vector2(-0.045, 0.27),
		Vector2(-0.03, 0.52),
		Vector2(0.015, 0.77),
		Vector2(0.1, 1.03)
	])
	var right_edge := PackedVector2Array([
		Vector2(0.065, 0.025),
		Vector2(0.1, 0.27),
		Vector2(0.14, 0.52),
		Vector2(0.17, 0.77),
		Vector2(0.1, 1.03)
	])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var thickness := 0.025
	for index in range(left_edge.size() - 1):
		var lf0 := _blade_point(left_edge[index], thickness)
		var rf0 := _blade_point(right_edge[index], thickness)
		var lf1 := _blade_point(left_edge[index + 1], thickness)
		var rf1 := _blade_point(right_edge[index + 1], thickness)
		var lb0 := _blade_point(left_edge[index], -thickness)
		var rb0 := _blade_point(right_edge[index], -thickness)
		var lb1 := _blade_point(left_edge[index + 1], -thickness)
		var rb1 := _blade_point(right_edge[index + 1], -thickness)
		_add_triangle(surface, lf0, rf0, lf1)
		_add_triangle(surface, rf0, rf1, lf1)
		_add_triangle(surface, lb0, lb1, rb0)
		_add_triangle(surface, rb0, lb1, rb1)
		_add_triangle(surface, lf0, lf1, lb0)
		_add_triangle(surface, lb0, lf1, lb1)
		_add_triangle(surface, rf0, rb0, rf1)
		_add_triangle(surface, rb0, rb1, rf1)
	surface.generate_normals()
	return surface.commit()


func _blade_point(point: Vector2, depth: float) -> Vector3:
	return Vector3(point.x, point.y, depth)


func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)


func _weapon_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _build_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.position.y = 1.2
	add_child(_camera_pivot)
	_camera_pivot.top_level = true
	_camera_pivot.global_position = global_position + Vector3(0, 1.2, 0)
	_camera_arm = SpringArm3D.new()
	_camera_arm.rotation.x = -atan(2.0 / 6.0)
	_camera_arm.spring_length = 6.3
	_camera_arm.collision_mask = 1 | 4
	_camera_arm.margin = 0.2
	var camera_shape := SphereShape3D.new()
	camera_shape.radius = 0.25
	_camera_arm.shape = camera_shape
	_camera_pivot.add_child(_camera_arm)
	_camera_arm.add_excluded_object(get_rid())
	var camera := Camera3D.new()
	camera.near = 0.1
	camera.position.z = _camera_arm.spring_length
	_camera_arm.add_child(camera)
	camera.make_current()


func set_camera_distance(value: float) -> void:
	_camera_arm.spring_length = clampf(value, 4.0, 9.0)


func _build_attack_area() -> void:
	_attack_area = Area3D.new()
	_attack_area.position = Vector3(0, 0.9, -1.05)
	_attack_area.collision_layer = 0
	_attack_area.collision_mask = 2
	_attack_area.monitoring = true
	add_child(_attack_area)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0
	collision.shape = shape
	_attack_area.add_child(collision)


func cancel_swing() -> void:
	get_tree().call_group("attack_gestures", "cancel_hold")
	sprint_enabled = false
	_attack_buffer = 0.0
	_swing_id += 1
	_attack_time = 0.0
	_heavy_time = 0.0
	if is_instance_valid(_heavy_warning):
		_heavy_warning.hide()

func toggle_sprint() -> void:
	end_guard()
	if get_tree().paused or health <= 0 or _attack_cooldown > 0.0 or _dodge_time > 0.0:
		return
	if sprint_enabled:
		sprint_enabled = false
	elif stamina >= 20.0:
		sprint_enabled = true

func _sprint_speed(delta: float, input_strength: float) -> float:
	if guarding:
		stamina=maxf(0,stamina-6*delta)
		if stamina<20: end_guard()
		return MOVE_SPEED*0.45
	if _heavy_time > 0.0:
		return MOVE_SPEED
	if sprint_enabled and input_strength > 0.1 and _attack_cooldown <= 0.0 and _dodge_time <= 0.0 and _hit_time <= 0.0:
		stamina = maxf(0.0, stamina - 25.0 * delta)
		if stamina > 0.0:
			return SPRINT_SPEED
		sprint_enabled = false
	else:
		stamina = minf(100.0, stamina + 18.0 * delta)
	return MOVE_SPEED
func heavy_attack() -> void:
	end_guard()
	if get_tree().paused or health <= 0 or stamina < HEAVY_COST or _attack_cooldown > 0.0 or _dodge_time > 0.0 or _hit_time > 0.0:
		return
	stamina -= HEAVY_COST
	sprint_enabled = false
	_attack_buffer = 0.0
	_burst_requested = false
	combo_step = 0
	_combo_window = 0.0
	_attack_cooldown = HEAVY_DURATION
	_heavy_time = HEAVY_DURATION
	_attack_time = HEAVY_DURATION
	_swing_id += 1
	var swing_id := _swing_id
	_visual.action("Sword_Attack", HEAVY_DURATION)
	_heavy_warning.show()
	await get_tree().create_timer(HEAVY_WINDUP, false, true).timeout
	await get_tree().physics_frame
	if health <= 0 or swing_id != _swing_id:
		return
	_heavy_warning.hide()
	play_sound("sword")
	var shape := SphereShape3D.new()
	shape.radius = 2.6
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP)
	query.collision_mask = 2
	var connected := false
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 32):
		var body: Node3D = hit.collider
		if not body.has_method("take_damage") or int(body.get("health")) <= 0:
			continue
		var offset := body.global_position - global_position
		var flat := Vector3(offset.x, 0, offset.z)
		if flat.length() > 2.6 or absf(offset.y) > 1.8 or flat.normalized().dot(-global_basis.z) < 0.5:
			continue
		var before := int(body.get("health"))
		body.call("take_damage", attack_damage * 4)
		if int(body.get("health")) < before:
			connected = true
			if int(body.get("health")) > 0 and body.has_method("stagger"):
				body.call("stagger", 0.65)
	if connected:
		spirit = mini(SPIRIT_MAX, spirit + 25)

func _build_heavy_warning() -> void:
	_heavy_warning = MeshInstance3D.new()
	_heavy_warning.name = "HeavyAttackArc"
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(24):
		var a := -PI / 3.0 + index * (2.0 * PI / 3.0) / 24.0
		var b := -PI / 3.0 + (index + 1) * (2.0 * PI / 3.0) / 24.0
		for point in [Vector3.ZERO, Vector3(sin(a), 0, -cos(a)) * 2.6, Vector3(sin(b), 0, -cos(b)) * 2.6]:
			surface.add_vertex(point)
	surface.generate_normals()
	_heavy_warning.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(1.0, 0.55, 0.12, 0.32)
	_heavy_warning.material_override = material
	_heavy_warning.position.y = 0.06
	_heavy_warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_heavy_warning)
	_heavy_warning.hide()
