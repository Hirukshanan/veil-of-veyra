extends Node3D

const MODEL = preload("res://assets/characters/pigcraft/charcoal_dragon.glb")
var animator: AnimationPlayer
var skeleton: Skeleton3D
var _materials: Array[StandardMaterial3D] = []
var _clip := ""
var _clock := 0.0
var flying := false
var look_direction := Vector3.FORWARD
var _flight_blend := 0.0
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
	# Eye highlights belong to the skinned surface, never separate rigid objects.
	var eye_shader := Shader.new()
	eye_shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never;
void fragment() {
 float mask = COLOR.r;
 if (mask < 0.05) { discard; }
 ALBEDO = vec3(1.0, 0.24, 0.008) * mask;
 ALPHA = mask;
}
"""
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var original := mesh.mesh as ArrayMesh
		var marked := ArrayMesh.new()
		for shape_index in range(original.get_blend_shape_count()):
			marked.add_blend_shape(original.get_blend_shape_name(shape_index))
		marked.blend_shape_mode = original.blend_shape_mode
		for surface in range(original.get_surface_count()):
			var arrays := original.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var colors := PackedColorArray()
			for vertex in vertices:
				var eye := Vector3(signf(vertex.x) * 0.1405, 2.3004, -2.1986)
				var mask := 1.0 - smoothstep(0.018, 0.065, vertex.distance_to(eye))
				colors.append(Color(mask, 0, 0, 1))
			arrays[Mesh.ARRAY_COLOR] = colors
			marked.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, original.surface_get_blend_shape_arrays(surface))
			marked.surface_set_material(surface, original.surface_get_material(surface))
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			var eye_pass := ShaderMaterial.new()
			eye_pass.shader = eye_shader
			material.next_pass = eye_pass
		mesh.mesh = marked
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
	_flight_blend = move_toward(_flight_blend, 1.0 if flying else 0.0, delta * 1.8)
	var amplitude := lerpf(0.025, 0.38, _flight_blend)
	if clip in ["windup", "breath"]:
		amplitude = 0.12
	for side in ["L", "R"]:
		var sign_value := 1.0 if side == "L" else -1.0
		var wing := skeleton.find_bone("wing_" + side)
		var tip := skeleton.find_bone("wing_tip_" + side)
		skeleton.set_bone_pose_rotation(wing, skeleton.get_bone_pose_rotation(wing) * Quaternion(Vector3.FORWARD, sign_value * beat * amplitude))
		skeleton.set_bone_pose_rotation(tip, skeleton.get_bone_pose_rotation(tip) * Quaternion(Vector3.FORWARD, -sign_value * sin(_clock * TAU / 1.25 - 0.45) * amplitude * 0.45))
	position.y = lerpf(-0.65, 0.5, _flight_blend) + sin(_clock * TAU / 1.25 - 0.6) * lerpf(0.025, 0.12, _flight_blend)
	var stride := sin(_clock * 6.0) * (1.0 - _flight_blend) * (1.0 if moving else 0.0)
	for side in ["L", "R"]:
		var sign_value := 1.0 if side == "L" else -1.0
		for limb in ["leg_", "arm_"]:
			var bone := skeleton.find_bone(limb + side)
			skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone) * Quaternion(Vector3.RIGHT, sign_value * stride * (0.3 if limb == "leg_" else -0.22)))
	var chest := skeleton.find_bone("chest")
	skeleton.set_bone_pose_rotation(chest, skeleton.get_bone_pose_rotation(chest) * Quaternion(Vector3.UP, stride * 0.045))
	if clip in ["idle", "hover", "hit"]:
		var yaw := clampf(atan2(-look_direction.x, -look_direction.z), -0.55, 0.55)
		for name in ["neck", "head"]:
			var bone := skeleton.find_bone(name)
			var rest_basis := skeleton.get_bone_global_rest(bone).basis
			var axis := rest_basis.inverse() * Vector3.UP
			skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone) * Quaternion(axis.normalized(), yaw * 0.5))
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
