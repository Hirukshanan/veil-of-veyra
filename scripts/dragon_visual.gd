extends Node3D

const MODEL = preload("res://assets/characters/pigcraft/charcoal_dragon.glb")
var animator: AnimationPlayer
var skeleton: Skeleton3D
var _materials: Array[StandardMaterial3D] = []
var _clip := ""
var _clock := 0.0
var _hurt_time := 0.0
var _dead := false
var _death_time := 0.0
var _blend_time := 0.0
var _blend_rotations: Array[Quaternion] = []
var _blend_positions: Array[Vector3] = []

func _ready() -> void:
	var model := MODEL.instantiate()
	add_child(model)
	animator = model.find_children("*", "AnimationPlayer", true, false)[0]
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material: StandardMaterial3D = mesh.get_active_material(surface).duplicate()
			mesh.set_surface_override_material(surface, material)
			_materials.append(material)
	pose("idle", 0.0)
	set_process(false)

func pose(clip: String, time: float) -> void:
	if clip != _clip:
		animator.play(clip)
		_clip = clip
	animator.seek(clampf(time, 0.0, animator.get_animation(clip).length), true)
	animator.pause()

func animate(delta: float, clip: String, progress: float, moving: bool, enraged: bool) -> void:
	if _dead:
		return
	var previous_clip := _clip
	var rotations: Array[Quaternion] = []
	var positions: Array[Vector3] = []
	for index in range(skeleton.get_bone_count()):
		rotations.append(skeleton.get_bone_pose_rotation(index))
		positions.append(skeleton.get_bone_pose_position(index))
	_clock += delta
	_hurt_time = maxf(0.0, _hurt_time - delta)
	if clip == "idle":
		clip = "hover" if moving else "idle"
		if _hurt_time > 0.0:
			pose("hit", (0.24 - _hurt_time))
		else:
			pose(clip, fmod(_clock, animator.get_animation(clip).length))
	else:
		pose(clip, progress * animator.get_animation(clip).length)
	# Flap across the shoulder instead of twisting along the wing bone.
	var beat := sin(_clock * TAU / 1.25)
	var amplitude := 0.28 if moving else 0.20
	if clip in ["windup", "breath"]:
		amplitude = 0.12
	for side in ["L", "R"]:
		var sign_value := 1.0 if side == "L" else -1.0
		var wing := skeleton.find_bone("wing_" + side)
		var tip := skeleton.find_bone("wing_tip_" + side)
		skeleton.set_bone_pose_rotation(wing, skeleton.get_bone_pose_rotation(wing) * Quaternion(Vector3.FORWARD, sign_value * beat * amplitude))
		skeleton.set_bone_pose_rotation(tip, skeleton.get_bone_pose_rotation(tip) * Quaternion(Vector3.FORWARD, -sign_value * sin(_clock * TAU / 1.25 - 0.45) * amplitude * 0.45))
	position.y = 0.12 + sin(_clock * TAU / 1.25 - 0.6) * 0.08
	if previous_clip != _clip:
		_blend_rotations = rotations
		_blend_positions = positions
		_blend_time = 0.10
	if _blend_time > 0.0:
		_blend_time = maxf(0.0, _blend_time - delta)
		var weight := 1.0 - _blend_time / 0.10
		for index in range(skeleton.get_bone_count()):
			skeleton.set_bone_pose_rotation(index, _blend_rotations[index].slerp(skeleton.get_bone_pose_rotation(index), weight))
			skeleton.set_bone_pose_position(index, _blend_positions[index].lerp(skeleton.get_bone_pose_position(index), weight))
	for material in _materials:
		material.emission_enabled = enraged or _hurt_time > 0.0
		material.emission = Color(0.12, 0.015, 0.003) if enraged else Color(0.20, 0.10, 0.04)

func show_hit() -> void:
	_hurt_time = 0.24

func show_defeat(world: Node3D) -> void:
	_dead = true
	reparent(world, true)
	# The victory menu pauses gameplay immediately; only the detached visual finishes.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for material in _materials:
		material.emission_enabled = false
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	pose("death", 0.0)
	set_process(true)

func _process(delta: float) -> void:
	_death_time += delta
	pose("death", _death_time)
	for material in _materials:
		material.albedo_color.a = 1.0 - clampf((_death_time - 1.2) / 0.6, 0.0, 1.0)
	if _death_time >= 1.8:
		queue_free()

func mouth_position() -> Vector3:
	var index := skeleton.find_bone("head")
	var rest := skeleton.get_bone_global_rest(index)
	# Fixed point at the original sculpt's muzzle, carried by the animated head.
	var local_muzzle := rest.affine_inverse() * Vector3(0, 1.85, -2.05)
	return skeleton.to_global(skeleton.get_bone_global_pose(index) * local_muzzle)
