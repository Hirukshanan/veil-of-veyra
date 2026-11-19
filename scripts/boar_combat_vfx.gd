extends Node3D

signal breath_released(strength: float)
signal effect_emitted(kind: StringName, count: int)

const MAX_PUFFS := 28
const MAX_DISTANCE_SQUARED := 17.0 * 17.0
const DUST := Color(.64, .50, .36, .43)
const BREATH := Color(.65, .57, .49, .46)
const EMBER := Color(.90, .43, .18, .74)
const HOOF_NAMES := ["front_hoof.L", "rear_hoof.R", "front_hoof.R", "rear_hoof.L"]
const BREATH_POSE := preload("res://scripts/boar_breath_pose.gd")

class Puff:
	var origin: Vector3
	var velocity: Vector3
	var tint: Color
	var size: float
	var growth: float
	var stretch: float
	var age: float
	var lifetime := 0.0

var _actor
var _rig: Skeleton3D
var _head := -1
var _nostrils := PackedVector3Array()
var _snout_forward: Vector3
var _snout_side: Vector3
var _hooves := PackedInt32Array()
var _pose
var _batch: MultiMeshInstance3D
var _pool: Array[Puff] = []
var _active_count := 0
var _snort_due := -1.0
var _snort_strength := 0.0
var _snort_pose := 0.0
var _last_idle_phase := 0.0
var _random := RandomNumberGenerator.new()

func setup(actor: Node3D, rig: Skeleton3D) -> void:
	_actor = actor
	_rig = rig
	_head = rig.find_bone("head")
	assert(_head >= 0)
	var head_rest := rig.get_bone_global_rest(_head).affine_inverse()
	# Muzzle landmarks measured in the approved rest mesh's model coordinates.
	_nostrils = PackedVector3Array([head_rest * Vector3(-.064, .644, -1.47),
		head_rest * Vector3(.064, .644, -1.47)])
	_snout_forward = head_rest.basis * Vector3.FORWARD
	_snout_side = head_rest.basis * Vector3.RIGHT
	for bone_name in HOOF_NAMES:
		var index := rig.find_bone(bone_name)
		assert(index >= 0)
		_hooves.append(index)
	_pose = BREATH_POSE.new()
	_pose.name = "SnortPose"
	_pose.bind_rig(rig)
	rig.add_child(_pose)
	_random.seed = 63841
	for index in range(MAX_PUFFS):
		_pool.append(Puff.new())
	_build_batch()
	actor.state_changed.connect(_on_state_change)
	set_process(false)

func _build_batch() -> void:
	_batch = MultiMeshInstance3D.new()
	_batch.name = "AirAndDust"
	_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_batch.multimesh = MultiMesh.new()
	var data := _batch.multimesh
	data.transform_format = MultiMesh.TRANSFORM_3D
	data.use_colors = true
	data.mesh = QuadMesh.new()
	data.mesh.size = Vector2.ONE
	data.instance_count = MAX_PUFFS
	data.visible_instance_count = 0
	data.custom_aabb = AABB(Vector3(-5, -2, -5), Vector3(10, 6, 10))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.render_priority = 1
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.billboard_keep_scale = true
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = _puff_mask()
	_batch.material_override = material
	add_child(_batch)
	_batch.top_level = true
	_batch.global_transform = Transform3D(Basis.IDENTITY, global_position)

func _puff_mask() -> Texture2D:
	# One small reusable soft mask for the smoke, dust and tiny warm specks.
	var image := Image.create_empty(48, 48, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 782
	noise.frequency = .102
	for y in range(48):
		for x in range(48):
			var radius := (Vector2(x + .5, y + .5) / 24.0 - Vector2.ONE).length()
			var porous := .82 + .27 * noise.get_noise_2d(x, y)
			var alpha := (1.0 - smoothstep(.09, .97, radius)) * porous
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)

func _on_state_change(previous: int, current: int) -> void:
	_snort_due = -1.0
	var states: Dictionary = _actor.State
	if current == states.CHASE and (previous == states.IDLE or previous == states.PATROL):
		_schedule_snort(.08, .69)
	elif current == states.WARNING:
		_schedule_snort(.13, 1.0)
	elif current == states.SWEEP_PREP:
		_schedule_snort(.10, .87)
	elif current == states.STOMP_PREP:
		_schedule_snort(.15, 1.04)
	elif current == states.IDLE:
		_last_idle_phase = 0.0
	elif current == states.DEAD:
		_pose.drive = 0.0

func _schedule_snort(delay: float, strength: float) -> void:
	_snort_due = delay
	_snort_strength = strength

func animate_breath(delta: float) -> void:
	if not _near_camera():
		_pose.drive = 0.0
		_snort_due = -1.0
		return
	if _snort_due >= 0.0:
		_snort_due -= delta
		if _snort_due <= 0.0:
			_snort_due = -1.0
			_exhale(_snort_strength)
	_snort_pose = move_toward(_snort_pose, 0.0, delta * 3.8)
	var idle_wave := 0.0
	if _actor.state == _actor.State.IDLE:
		var phase := fposmod(_actor._elapsed, 1.46)
		if _last_idle_phase < .49 and phase >= .49:
			_exhale(.39)
		_last_idle_phase = phase
		idle_wave = sin(phase * TAU / 1.46) * .33
	var wanted := idle_wave + _snort_pose
	_pose.drive = lerpf(_pose.drive, wanted, minf(delta * 16.0, 1.0))

func _exhale(strength: float) -> void:
	_snort_pose = strength
	var snout := _rig.global_transform * _rig.get_bone_global_pose(_head)
	var forward := (snout.basis * _snout_forward).normalized()
	var across := (snout.basis * _snout_side).normalized()
	var strong := strength >= .65
	var count := 0
	for side in range(2):
		var muzzle := snout * _nostrils[side]
		var splay := across * (-1.0 if side == 0 else 1.0)
		var plume_count := 2 if strong else 1
		for detail in range(plume_count):
			var drift := forward * (.45 + strength * .67 + detail * .24) + splay * (.10 + detail * .05) + Vector3.UP * (.10 + detail * .09)
			var tint := BREATH.lerp(Color(.39, .35, .33, .40), float(detail) * .44)
			tint.a *= .78 + strength * .25
			count += _spawn(muzzle + forward * (.026 + detail * .095), drift, tint,
				.17 + strength * .08, .26 + strength * .10, .39 + strength * .10, 1.32)
		if strong:
			count += _spawn(muzzle + forward * .045, forward * 1.2 + splay * .30 + Vector3.UP * .27,
				EMBER, .027, -.010, .22, 1.0)
	breath_released.emit(strength)
	effect_emitted.emit(&"snort" if strong else &"idle_breath", count)

func hoof(index: int) -> void:
	if not _near_camera():
		return
	var point := _floor(_rig.to_global(_rig.get_bone_global_pose(_hooves[index % _hooves.size()]).origin))
	var count := _spawn(point, global_basis.z * .32 + Vector3.UP * .22, DUST, .115, .24, .31, 1.27)
	effect_emitted.emit(&"hoof", count)

func scrape() -> void:
	if not _near_camera():
		return
	var at := _floor(_rig.to_global(_rig.get_bone_global_pose(_hooves[0]).origin))
	var count := 0
	for index in range(3):
		count += _spawn(at + global_basis.z * index * .095, global_basis.z * (.52 + index * .20) + Vector3.UP * .21,
			DUST, .145, .25, .32, 1.5)
	effect_emitted.emit(&"scrape", count)

func charge_kick() -> void:
	if not _near_camera():
		return
	var count := 0
	for index in range(5):
		var bone := _hooves[1 if index % 2 == 0 else 3]
		var at := _floor(_rig.to_global(_rig.get_bone_global_pose(bone).origin))
		var speed := global_basis.z * _random.randf_range(1.0, 1.75) + Vector3.UP * _random.randf_range(.30, .55)
		count += _spawn(at + global_basis.z * index * .07, speed, DUST, .17, .32, .37, 1.36)
	effect_emitted.emit(&"charge_kick", count)

func ground_impact(point: Vector3, stomp: bool) -> void:
	if not _near_camera():
		return
	var total := 8 if stomp else 4
	var count := 0
	var tint := Color(.67, .54, .41, .58) if stomp else DUST
	for index in range(total):
		var angle := TAU * float(index) / total
		var radial := Vector3(cos(angle), 0, sin(angle))
		var at := _floor(point + radial * (.51 if stomp else .18))
		var speed := radial * (1.87 if stomp else .81) + Vector3.UP * .27
		count += _spawn(at, speed, tint, .30 if stomp else .15, .38, .41 if stomp else .32, 1.44)
	effect_emitted.emit(&"stomp_ring" if stomp else &"charge_stop", count)

func contact(at: Vector3, received_heavy: bool) -> void:
	if not _near_camera():
		return
	var count := 0
	for index in range(4 if received_heavy else 3):
		var side := global_basis.x * _random.randf_range(-.77, .77)
		var tint := Color(.62, .33, .22, .47) if received_heavy else Color(.67, .55, .44, .49)
		count += _spawn(at + side * .12, side + Vector3.UP * _random.randf_range(.21, .54),
			tint, .13, .19, .25, 1.31)
	effect_emitted.emit(&"heavy_reaction" if received_heavy else &"confirmed_contact", count)

func _near_camera() -> bool:
	var camera := get_viewport().get_camera_3d()
	return _actor.visible and is_instance_valid(camera) and camera.global_position.distance_squared_to(global_position) <= MAX_DISTANCE_SQUARED

func _floor(at: Vector3) -> Vector3:
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP, at - Vector3.UP * 2, 16)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return (at if hit.is_empty() else Vector3(hit.position)) + Vector3.UP * .07

func _spawn(at: Vector3, velocity: Vector3, tint: Color, size: float, growth: float, lifetime: float, stretch: float) -> int:
	if _active_count >= MAX_PUFFS:
		return 0
	var puff := _pool[_active_count]
	_active_count += 1
	puff.origin = at
	puff.velocity = velocity
	puff.tint = tint
	puff.size = size
	puff.growth = growth
	puff.lifetime = lifetime
	puff.stretch = stretch
	puff.age = 0.0
	set_process(true)
	return 1

func _process(delta: float) -> void:
	if not _near_camera():
		_active_count = 0
		_batch.multimesh.visible_instance_count = 0
		set_process(false)
		return
	var origin := global_position
	_batch.global_position = origin
	var data := _batch.multimesh
	var index := 0
	while index < _active_count:
		var puff := _pool[index]
		puff.age += delta
		if puff.age >= puff.lifetime:
			_active_count -= 1
			_pool[index] = _pool[_active_count]
			_pool[_active_count] = puff
			continue
		var fraction := puff.age / puff.lifetime
		var extent := puff.size + puff.growth * fraction
		var size := Vector3(extent * puff.stretch, extent, extent)
		var point := puff.origin + puff.velocity * puff.age * (1.0 - fraction * .24) - origin
		data.set_instance_transform(index, Transform3D(Basis.from_scale(size), point))
		var tint := puff.tint
		tint.a *= smoothstep(0.0, .12, fraction) * (1.0 - smoothstep(.19, 1.0, fraction))
		data.set_instance_color(index, tint)
		index += 1
	data.visible_instance_count = _active_count
	if _active_count == 0:
		set_process(false)
