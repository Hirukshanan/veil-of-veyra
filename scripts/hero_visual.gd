extends Node3D

# Quaternius CC0 art. Gameplay movement remains on the CharacterBody3D.
const MODEL = preload("res://assets/characters/quaternius/Superhero_Male_FullBody.gltf")
const MOTIONS = preload("res://assets/characters/quaternius/UAL1_Standard.glb")
const CLIPS := ["Sword_Idle", "Walk", "Sprint", "Sword_Attack", "Roll", "Hit_Chest", "Death01", "Spell_Simple_Shoot"]

var animator: AnimationPlayer
var hand: BoneAttachment3D
var _action_time := 0.0
var _dead := false
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
		animation.loop_mode = Animation.LOOP_LINEAR if clip in ["Sword_Idle", "Walk", "Sprint"] else Animation.LOOP_NONE
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
	_meshes = model.find_children("*", "MeshInstance3D", true, false)
	_flash = StandardMaterial3D.new()
	_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.albedo_color = Color(1, 0.15, 0.1, 0.55)
	animator.play("Sword_Idle")


func update_motion(delta: float, speed: float, hurt: bool) -> void:
	for mesh in _meshes:
		mesh.material_overlay = _flash if hurt else null
	_action_time = maxf(0, _action_time - delta)
	if _dead or _action_time > 0:
		return
	var clip := "Sword_Idle" if speed <= 0.2 else ("Walk" if speed < 3.0 else "Sprint")
	if animator.current_animation != clip:
		animator.play(clip, 0.12)
	animator.speed_scale = 1.0 if clip == "Sword_Idle" else clampf(speed / (2.0 if clip == "Walk" else 5.2), 0.25, 1.5)


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
