extends CharacterBody3D

signal health_changed(value: int, maximum: int)
signal defeated

const MOVE_SPEED := 5.2
const DODGE_SPEED := 12.0
const GRAVITY := 22.0
const ATTACK_DURATION := 0.22
const LOCK_RANGE := 14.0

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
var _body_material: StandardMaterial3D
var _hit_time := 0.0
var combo_step := 0
var _combo_window := 0.0
var camera_sensitivity := 1.0
var _sound: AudioStreamPlayer
var _sounds: Dictionary = {}
var locked_target: Node3D
var _lock_marker: Label3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	_build_character()
	_build_camera()
	_build_attack_area()
	_build_sounds()
	_lock_marker = Label3D.new()
	_lock_marker.text = "▼ LOCKED"
	_lock_marker.modulate = Color(1.0, 0.85, 0.3)
	_lock_marker.font_size = 32
	_lock_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_lock_marker)
	_lock_marker.top_level = true
	_lock_marker.hide()
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	if position.y < -8:
		position = Vector3(0, 1, 4)
		velocity = Vector3.ZERO
		take_damage(20)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_combo_window = maxf(0.0, _combo_window - delta)
	if _combo_window == 0.0:
		combo_step = 0
	_hit_time = maxf(0.0, _hit_time - delta)
	_body_material.albedo_color = Color(1, 0.25, 0.2) if _hit_time > 0.0 else Color(0.76, 0.65, 0.39)
	_attack_time = maxf(0.0, _attack_time - delta)
	_dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)
	_invulnerability_time = maxf(0.0, _invulnerability_time - delta)
	var swing := sin((1.0 - _attack_time / ATTACK_DURATION) * PI) if _attack_time > 0.0 else 0.0
	_weapon.rotation.z = -0.12 + swing * 0.9
	_weapon.rotation.y = swing * (-0.65 if combo_step == 2 else 0.65)
	_blade_material.emission_enabled = _attack_time > 0.0

	var input_vector := _touch_move
	var keyboard_vector := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if keyboard_vector.length_squared() > 0.01:
		input_vector = keyboard_vector
	if Input.is_action_just_pressed(&"attack"):
		attack()
	if Input.is_action_just_pressed(&"dodge"):
		dodge()
	if Input.is_action_just_pressed(&"target_lock"):
		toggle_target_lock()
	_update_target_lock(delta)

	var direction := Vector3(input_vector.x, 0, input_vector.y).rotated(Vector3.UP, _camera_pivot.global_rotation.y)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	if _dodge_time > 0.0:
		_dodge_time -= delta
		velocity.x = _dodge_direction.x * DODGE_SPEED
		velocity.z = _dodge_direction.z * DODGE_SPEED
	else:
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
		if direction.length_squared() > 0.01 and not is_instance_valid(locked_target):
			rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 12.0)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	_camera_pivot.global_position = global_position + Vector3(0, 1.2, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_rotate_camera(event.relative)
	elif event is InputEventScreenDrag:
		_rotate_camera(event.relative)


func _rotate_camera(relative: Vector2) -> void:
	clear_target_lock()
	_camera_pivot.rotation.y -= relative.x * 0.005 * camera_sensitivity
	_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x - relative.y * 0.003 * camera_sensitivity, -0.32, 0.5)


func set_move_input(value: Vector2) -> void:
	_touch_move = value


func _can_lock(candidate: Node3D) -> bool:
	return is_instance_valid(candidate) and not candidate.is_queued_for_deletion() and int(candidate.get("health")) > 0 and global_position.distance_to(candidate.global_position) <= LOCK_RANGE


func toggle_target_lock() -> void:
	if health <= 0 or get_tree().paused:
		return
	if is_instance_valid(locked_target):
		clear_target_lock()
		return
	var nearest := LOCK_RANGE + 0.01
	for candidate in get_tree().get_nodes_in_group("lock_targets"):
		if _can_lock(candidate):
			var distance := global_position.distance_to(candidate.global_position)
			if distance < nearest:
				nearest = distance
				locked_target = candidate
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
	if _attack_cooldown > 0.0 or health <= 0:
		return
	combo_step = combo_step % 3 + 1
	_combo_window = 0.95
	_attack_cooldown = 0.55 if combo_step == 3 else 0.32
	_attack_time = ATTACK_DURATION
	play_sound("sword")
	var damage := attack_damage * (2 if combo_step == 3 else 1)
	await get_tree().physics_frame
	if health <= 0:
		return
	for body in _attack_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.call("take_damage", damage)


func dodge() -> void:
	if _dodge_cooldown > 0.0 or health <= 0:
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
	play_sound("dodge")
	_dodge_cooldown = 0.65
	_invulnerability_time = 0.35


func take_damage(amount: int) -> void:
	if _invulnerability_time > 0.0 or health <= 0:
		return
	health = maxi(0, health - amount)
	play_sound("hurt")
	_hit_time = 0.18
	_invulnerability_time = 0.45
	health_changed.emit(health, max_health)
	if health == 0:
		clear_target_lock()
		_touch_move = Vector2.ZERO
		defeated.emit()


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
	var body_mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	body_mesh.mesh = capsule
	body_mesh.position.y = 0.9
	var body_material := StandardMaterial3D.new()
	_body_material = body_material
	body_material.albedo_color = Color(0.76, 0.65, 0.39)
	body_material.roughness = 0.82
	body_mesh.material_override = body_material
	add_child(body_mesh)

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
	_weapon.position = Vector3(0.48, 0.78, -0.32)
	_weapon.rotation.z = -0.12
	add_child(_weapon)

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
