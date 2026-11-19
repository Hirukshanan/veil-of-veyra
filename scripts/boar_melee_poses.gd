extends RefCounted

# Additive poses authored against the existing skinned boar, in model axes.
# The hindquarters stay in the imported idle pose during both attacks.
static func build(model: Node3D, animator: AnimationPlayer, sweep_windup: float, stomp_windup: float) -> void:
	var rig: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var root := animator.get_node(animator.root_node)
	var library := AnimationLibrary.new()
	library.add_animation("tusk_sweep", _clip(rig, root.get_path_to(rig), 1.62, {
		"neck": [[0.0, 0.0, 0.0], [.23, -5.0, -16.0], [sweep_windup, -7.0, -25.0],
			[sweep_windup + .15, -8.0, 25.0], [1.12, -2.0, 15.0], [1.62, 0.0, 0.0]],
		"head": [[0.0, 0.0, 0.0], [.18, 3.0, 9.0], [sweep_windup, 1.0, -30.0],
			[sweep_windup + .15, 3.0, 32.0], [1.13, 2.0, 12.0], [1.62, 0.0, 0.0]],
		"spine_02": [[0.0, 0.0, 0.0], [sweep_windup, -2.0, -5.0],
			[sweep_windup + .15, -1.0, 7.0], [1.62, 0.0, 0.0]],
	}))
	library.add_animation("ground_stomp", _clip(rig, root.get_path_to(rig), 2.06, {
		"spine_01": [[0.0, 0.0, 0.0], [.30, 8.0, 0.0], [stomp_windup - .13, 21.0, 0.0],
			[stomp_windup, 0.0, 0.0], [2.06, 0.0, 0.0]],
		"neck": [[0.0, 0.0, 0.0], [.30, 7.0, 0.0], [stomp_windup - .13, 10.0, 0.0],
			[stomp_windup, -12.0, 0.0], [stomp_windup + .15, -7.0, 0.0], [2.06, 0.0, 0.0]],
		"front_lower.L": [[0.0, 0.0, 0.0], [stomp_windup - .13, -19.0, 0.0], [stomp_windup, 0.0, 0.0]],
		"front_lower.R": [[0.0, 0.0, 0.0], [stomp_windup - .13, -19.0, 0.0], [stomp_windup, 0.0, 0.0]],
	}))
	animator.add_animation_library(&"elite", library)

static func _clip(rig: Skeleton3D, rig_path: NodePath, length: float, offsets: Dictionary) -> Animation:
	var clip := Animation.new()
	clip.length = length
	for bone in range(rig.get_bone_count()):
		var bone_name := rig.get_bone_name(bone)
		var path := NodePath("%s:%s" % [rig_path, bone_name])
		var position_track := clip.add_track(Animation.TYPE_POSITION_3D)
		clip.track_set_path(position_track, path)
		clip.position_track_insert_key(position_track, 0.0, rig.get_bone_pose_position(bone))
		var rotation_track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(rotation_track, path)
		var rest := rig.get_bone_pose_rotation(bone)
		var axes := rig.get_bone_global_rest(bone).basis.orthonormalized().inverse()
		for key in offsets.get(bone_name, [[0.0, 0.0, 0.0]]):
			var yaw := Quaternion((axes * Vector3.UP).normalized(), deg_to_rad(key[2]))
			var pitch := Quaternion((axes * Vector3.RIGHT).normalized(), deg_to_rad(key[1]))
			clip.rotation_track_insert_key(rotation_track, key[0], (rest * yaw * pitch).normalized())
		var scale_track := clip.add_track(Animation.TYPE_SCALE_3D)
		clip.track_set_path(scale_track, path)
		clip.scale_track_insert_key(scale_track, 0.0, rig.get_bone_pose_scale(bone))
	return clip
