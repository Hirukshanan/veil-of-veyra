extends SceneTree
const BOSS = preload("res://scripts/boss.gd")

func _initialize():
	call_deferred("_run")

func _run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var world := Node3D.new()
	root.add_child(world)
	var boss = BOSS.new()
	world.add_child(boss)
	boss.set_physics_process(false)
	boss.set_process(false)
	var visual = boss._visual
	assert(visual.skeleton.get_bone_count() == 21)
	for clip in ["idle", "hover", "windup", "breath", "charge", "recover", "hit", "death"]:
		assert(visual.animator.has_animation(clip))
		visual.pose(clip, visual.animator.get_animation(clip).length * 0.5)
		for index in range(visual.skeleton.get_bone_count()):
			assert(visual.skeleton.get_bone_pose(index).is_finite(), "Every animated bone must stay finite")
	# Repeated procedural offsets must never accumulate on unkeyed GLB channels.
	visual.flying = false
	visual.movement_speed = 2.0
	for frame in range(1200):
		visual.animate(1.0 / 60.0, "idle", 0.0, true, false)
		for bone in range(visual.skeleton.get_bone_count()):
			var translation: Vector3 = visual.skeleton.get_bone_pose_position(bone)
			var baseline: Vector3 = visual.skeleton.get_bone_rest(bone).origin
			assert(translation.distance_to(baseline) < 1.5, "Procedural pose drift at frame %d bone %s" % [frame, visual.skeleton.get_bone_name(bone)])
	var triangles := 0
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		assert(mesh.skin != null, "Dragon must have a weighted skin")
		for surface in range(mesh.mesh.get_surface_count()):
			triangles += mesh.mesh.surface_get_array_index_len(surface) / 3
	assert(triangles > 10000 and triangles <= 40000, "Dragon must stay within its mesh budget")
	assert(visual.find_children("*", "BoneAttachment3D", true, false).is_empty(), "Eye highlights must use skinned face geometry")
	visual.flying = true
	visual._flight_blend = 1.0
	visual._clock = 0.3
	visual.animate(0.01, "idle", 0.0, true, false)
	var wing: int = visual.skeleton.find_bone("wing_L")
	var up: Quaternion = visual.skeleton.get_bone_pose_rotation(wing)
	visual._clock = 0.9
	visual.animate(0.11, "idle", 0.0, true, false)
	assert(up.angle_to(visual.skeleton.get_bone_pose_rotation(wing)) > 0.25, "Hover must have a visible wingbeat")
	boss._state = BOSS.AttackState.BREATH
	boss._state_time = 0.25
	boss._fire_cone.visible = true
	boss._process(0.016)
	assert(boss._fire_cone.global_position.distance_to(visual.mouth_position()) < 0.01, "Flames must follow animated mouth")
	assert(boss._fire_cone._cloud.multimesh.instance_count == 48)
	var fire_clock: float = boss._fire_cone._clock
	boss._process(0.05)
	assert(boss._fire_cone._clock > fire_clock, "Fire simulation must advance")
	var head: int = visual.skeleton.find_bone("head")
	visual.pose("idle", 0.0)
	var rest: Quaternion = visual.skeleton.get_bone_pose_rotation(head)
	visual.pose("breath", 0.2)
	assert(not visual.skeleton.get_bone_pose_rotation(head).is_equal_approx(rest), "Breath must animate the head")
	boss._state = BOSS.AttackState.WINDUP
	boss._state_time = 0.425
	boss._process(0.016)
	assert(visual._clip == "windup")
	assert(absf(visual.animator.current_animation_position / visual.animator.get_animation("windup").length - 0.5) < 0.01)
	boss.set_process(true)
	paused = true
	var sample: float = visual.animator.current_animation_position
	await create_timer(0.08, true).timeout
	assert(visual.animator.current_animation_position == sample, "Pause freezes living dragon animation")
	paused = false
	boss.set_process(false)
	boss.take_damage(10000)
	await process_frame
	assert(not is_instance_valid(boss) and is_instance_valid(visual))
	assert(visual._clip == "death" and visual.get_parent() == world)
	paused = true
	await create_timer(2.0, true).timeout
	assert(not is_instance_valid(visual), "Detached death visual must finish behind the victory menu")
	paused = false
	world.queue_free()
	await process_frame
	print("PASS: dragon mesh budget, weighted rig, eight finite clips, head motion, synchronized warning, pause and death cleanup")
	quit()
