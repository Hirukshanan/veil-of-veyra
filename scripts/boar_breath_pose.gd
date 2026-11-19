extends SkeletonModifier3D

# An additive render pose. The imported rest pose, animation tracks and foot IK stay intact.
const BONES := ["head", "neck", "shoulder.L", "shoulder.R"]
const AMPLITUDE := [1.35, .74, .34, -.34]
var drive := 0.0
var _bones := PackedInt32Array()
var _axes := PackedVector3Array()

func bind_rig(rig: Skeleton3D) -> void:
	for index in range(BONES.size()):
		var bone := rig.find_bone(BONES[index])
		assert(bone >= 0)
		_bones.append(bone)
		var axis := Vector3.FORWARD if index >= 2 else Vector3.RIGHT
		_axes.append((rig.get_bone_global_rest(bone).basis.inverse() * axis).normalized())

func _process_modification_with_delta(_delta: float) -> void:
	if absf(drive) < .001:
		return
	var rig := get_skeleton()
	for index in range(_bones.size()):
		var bone := _bones[index]
		var rotation := rig.get_bone_pose_rotation(bone)
		rotation *= Quaternion(_axes[index], deg_to_rad(AMPLITUDE[index] * drive))
		rig.set_bone_pose_rotation(bone, rotation.normalized())
