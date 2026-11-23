extends Node

const ASSET_DIR := "res://assets/characters/aru/equipment/"
var hero
var rig: Skeleton3D
var sword: Node3D
var shield: Node3D
var plates: Array[Node3D] = []
var guard_pose: ShieldPose

func bind_hero(actor) -> void:
	hero = actor
	rig = hero._visual.hand.get_parent()
	var blade: Node3D = hero._weapon
	sword = _asset("ember_sword")
	blade.get_parent().add_child(sword)
	sword.transform = blade.transform
	shield = _attach("ward_shield", "lowerarm_l",
		Transform3D(Basis(Vector3.FORWARD, PI*.47).scaled(Vector3.ONE * .87), Vector3(.56,1.472,.080)))
	guard_pose = ShieldPose.new()
	guard_pose.actor = hero
	guard_pose.upper = rig.find_bone("upperarm_l")
	guard_pose.forearm = rig.find_bone("lowerarm_l")
	rig.add_child(guard_pose)
	for pair in [
		["ranger_chest","spine_03"],
		["ranger_shoulder_l","upperarm_l"],["ranger_shoulder_r","upperarm_r"],
		["ranger_bracer_l","lowerarm_l"],["ranger_bracer_r","lowerarm_r"],
	]:
		plates.append(_attach(pair[0],pair[1],Transform3D.IDENTITY))

func apply(selection: Dictionary) -> void:
	hero._weapon.visible = selection.blade == 0
	sword.visible = selection.blade == 1
	shield.visible = selection.shield == 0
	guard_pose.active = shield.visible
	for piece in plates:
		piece.visible = selection.armor == 1

func _attach(asset: String, bone: String, rest: Transform3D) -> Node3D:
	var mount := BoneAttachment3D.new()
	mount.name = asset.to_pascal_case() + "Mount"
	mount.bone_name = bone
	rig.add_child(mount)
	var model := _asset(asset)
	mount.add_child(model)
	model.transform = rig.get_bone_global_rest(rig.find_bone(bone)).affine_inverse() * rest
	return model

func _asset(id: String) -> Node3D:
	return load(ASSET_DIR + id + ".glb").instantiate()

class ShieldPose extends SkeletonModifier3D:
	# A visual layer on the shield arm. The existing guard input owns all timing,
	# stamina and damage rules. Walk, strike and dodge remain on the authored clips.
	var actor
	var upper: int
	var forearm: int
	var amount := 0.0

	func _process_modification_with_delta(delta: float) -> void:
		amount = move_toward(amount, 1.0 if actor.guarding else 0.0, delta * 10.0)
		if amount <= 0.0:
			return
		var skeleton := get_skeleton()
		_aim(skeleton, upper, Vector3(.30,-.39,.87))
		_aim(skeleton, forearm, Vector3(-.91,.23,.34))

	func _aim(skeleton: Skeleton3D, bone: int, direction: Vector3) -> void:
		var y := direction.normalized()
		var x := y.cross(Vector3.BACK).normalized()
		var target := Basis(x, y, x.cross(y))
		var parent := skeleton.get_bone_global_pose(skeleton.get_bone_parent(bone)).basis
		var rotation := (parent.inverse() * target).orthonormalized().get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone).slerp(rotation, amount))
