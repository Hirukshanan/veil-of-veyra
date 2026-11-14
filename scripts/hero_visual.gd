extends Node3D

# Quaternius CC0 art. Gameplay movement remains on the CharacterBody3D.
const MODEL = preload("res://assets/characters/quaternius/Superhero_Male_FullBody.gltf")
const MOTIONS = preload("res://assets/characters/quaternius/UAL1_Standard.glb")
# Godot imports the source Jump_Loop animation as Jump.
const CLIPS := ["Sword_Idle", "Walk", "Sprint", "Sword_Attack", "Roll", "Hit_Chest", "Death01", "Spell_Simple_Shoot", "Jump_Start", "Jump", "Jump_Land"]

var animator: AnimationPlayer
var hand: BoneAttachment3D
var _action_time := 0.0
var _dead := false
var _grounded := true
var _meshes: Array[Node] = []
var _flash: StandardMaterial3D


func _ready() -> void:
	rotation.y = PI # Source characters face +Z; gameplay faces -Z.
	var model := MODEL.instantiate()
	add_child(model)
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var source := MOTIONS.instantiate()
	var source_rig: Skeleton3D = source.find_children("*", "Skeleton3D", true, false)[0]
	var source_player: AnimationPlayer = source.find_children("*", "AnimationPlayer", true, false)[0]
	animator = AnimationPlayer.new()
	model.add_child(animator)
	var library := AnimationLibrary.new()
	for clip in CLIPS:
		var animation: Animation = source_player.get_animation(clip).duplicate(true)
		animation.loop_mode = Animation.LOOP_LINEAR if clip in ["Sword_Idle", "Walk", "Sprint", "Jump"] else Animation.LOOP_NONE
		for track in range(animation.get_track_count() - 1, -1, -1):
			var bone_name := animation.track_get_path(track).get_subname(0)
			var target_bone := skeleton.find_bone(bone_name)
			var source_bone := source_rig.find_bone(bone_name)
			if target_bone < 0 or source_bone < 0:
				animation.remove_track(track)
				continue
			var target_rest := skeleton.get_bone_rest(target_bone)
			var source_rest := source_rig.get_bone_rest(source_bone)
			for key in range(animation.track_get_key_count(track)):
				var value = animation.track_get_key_value(track, key)
				if animation.track_get_type(track) == Animation.TYPE_ROTATION_3D:
					value = (target_rest.basis.get_rotation_quaternion() * source_rest.basis.get_rotation_quaternion().inverse() * value).normalized()
				elif animation.track_get_type(track) == Animation.TYPE_POSITION_3D:
					value = target_rest.origin + (value - source_rest.origin)
				animation.track_set_key_value(track, key, value)
		library.add_animation(clip, animation)
	animator.add_animation_library("", library)
	source.free()
	hand = BoneAttachment3D.new()
	hand.bone_name = "hand_r"
	skeleton.add_child(hand)
	_build_traveler_gear(skeleton)
	_meshes = model.find_children("*", "MeshInstance3D", true, false)
	_flash = StandardMaterial3D.new()
	_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.albedo_color = Color(1, 0.15, 0.1, 0.55)
	animator.play("Sword_Idle")

func _build_traveler_gear(rig: Skeleton3D) -> void:
	# Original low-cost starter clothing; existing skin, rig and action timing stay intact.
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color("354b45")
	cloth.roughness = 0.95
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color("503b2b")
	leather.roughness = 0.9
	_build_fitted_trousers(rig, cloth)
	for piece in [
		["Tunic", "spine_02", Vector3(0,1.19,0), 0.24,0.19,0.43,0.67,cloth],
		["Hem", "pelvis", Vector3(0,0.97,-0.015), 0.20,0.24,0.22,0.72,cloth],
		["Belt", "pelvis", Vector3(0,1.04,-0.01), 0.216,0.216,0.045,0.72,leather],
		["LeftBoot", "calf_l", Vector3(0.1143,0.25,-0.04), 0.086,0.075,0.27,1.0,leather],
		["RightBoot", "calf_r", Vector3(-0.1143,0.25,-0.04), 0.086,0.075,0.27,1.0,leather]
	]:
		var mesh := CylinderMesh.new()
		mesh.top_radius = piece[3]
		mesh.bottom_radius = piece[4]
		mesh.height = piece[5]
		mesh.radial_segments = 12
		mesh.rings = 1
		mesh.material = piece[7]
		var bone: int = rig.find_bone(piece[1])
		if bone < 0: continue
		var attachment := BoneAttachment3D.new()
		attachment.name = piece[0]
		attachment.bone_name = piece[1]
		rig.add_child(attachment)
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.transform = rig.get_bone_global_rest(bone).affine_inverse() * Transform3D(Basis().scaled(Vector3(1,1,piece[6])),piece[2])
		attachment.add_child(visual)
	for piece in [
		["LeftStrap","spine_03",Vector3(0.15,1.395,0),Vector3(0.07,0.20,0.27),cloth],
		["RightStrap","spine_03",Vector3(-0.15,1.395,0),Vector3(0.07,0.20,0.27),cloth],
		["LeftShoe","foot_l",Vector3(0.1143,0.075,0.045),Vector3(0.17,0.14,0.32),leather],
		["RightShoe","foot_r",Vector3(-0.1143,0.075,0.045),Vector3(0.17,0.14,0.32),leather]
	]:
		var bone: int = rig.find_bone(piece[1])
		if bone < 0: continue
		var attachment := BoneAttachment3D.new()
		attachment.name=piece[0]
		attachment.bone_name=piece[1]
		rig.add_child(attachment)
		var mesh:=BoxMesh.new()
		mesh.size=piece[3]
		mesh.material=piece[4]
		var visual:=MeshInstance3D.new()
		visual.mesh=mesh
		visual.transform=rig.get_bone_global_rest(bone).affine_inverse()*Transform3D(Basis.IDENTITY,piece[2])
		attachment.add_child(visual)

func _build_fitted_trousers(rig: Skeleton3D, material: Material) -> void:
	# A thin derivative of the CC0 body retains its exact skin weights during poses.
	for original in rig.get_parent().find_children("*","MeshInstance3D",true,false):
		if original.skin == null: continue
		var mesh := ArrayMesh.new()
		for surface in range(original.mesh.get_surface_count()):
			var arrays: Array = original.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var source_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var selected := PackedInt32Array()
			var to_rig: Transform3D = rig.global_transform.affine_inverse() * original.global_transform
			for i in range(0,source_indices.size(),3):
				var center := to_rig * ((vertices[source_indices[i]]+vertices[source_indices[i+1]]+vertices[source_indices[i+2]])/3.0)
				if center.y > 0.12 and center.y < 1.045 and absf(center.x) < 0.35:
					selected.append_array(source_indices.slice(i,i+3))
			if selected.is_empty(): continue
			for i in range(vertices.size()): vertices[i] += normals[i]*0.007
			arrays[Mesh.ARRAY_VERTEX]=vertices
			arrays[Mesh.ARRAY_INDEX]=selected
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			mesh.surface_set_material(mesh.get_surface_count()-1,material)
		if mesh.get_surface_count()==0: continue
		var clothing := MeshInstance3D.new()
		clothing.name="FittedTrousers"
		clothing.mesh=mesh
		clothing.skin=original.skin
		original.get_parent().add_child(clothing)
		clothing.transform=original.transform
		clothing.skeleton=clothing.get_path_to(rig)


func update_motion(delta: float, speed: float, hurt: bool, grounded := true) -> void:
	for mesh in _meshes:
		mesh.material_overlay = _flash if hurt else null
	_action_time = maxf(0, _action_time - delta)
	var landed := grounded and not _grounded
	_grounded = grounded
	if landed and not _dead and not hurt and _action_time <= 0.0:
		action("Jump_Land", 0.12)
		return
	if _dead or _action_time > 0:
		return
	var clip := "Jump" if not grounded else ("Sword_Idle" if speed <= 0.2 else ("Walk" if speed < 3.0 else "Sprint"))
	if animator.current_animation != clip:
		animator.play(clip, 0.12)
	animator.speed_scale = 1.0 if clip in ["Sword_Idle", "Jump"] else clampf(speed / (2.0 if clip == "Walk" else 5.2), 0.25, 1.5)


func action(clip: String, duration: float) -> void:
	if _dead:
		return
	_dead = clip == "Death01"
	_action_time = duration
	animator.speed_scale = 1.0
	if _dead:
		for mesh in _meshes:
			mesh.material_overlay = null
	# Preserve the outgoing pose for blending; only repeated clips need a restart.
	if animator.current_animation == clip:
		animator.seek(0.0)
	animator.play(clip, 0.04, animator.get_animation(clip).length / duration)
