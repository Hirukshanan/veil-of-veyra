extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	var hero = scene.player
	hero.set_physics_process(false)
	var visual = hero._visual
	var rig: Skeleton3D = visual.hand.get_parent()
	assert(rig.get_bone_count() == 65)
	assert(hero._weapon.get_parent() == visual.hand and visual.hand.bone_name == "hand_r")
	for clip in visual.CLIPS:
		var animation: Animation = visual.animator.get_animation(clip)
		assert(animation != null and animation.get_track_count() > 0)
		for track in range(animation.get_track_count()):
			assert(rig.find_bone(animation.track_get_path(track).get_subname(0)) >= 0)
	visual.update_motion(1, 5.2, false)
	assert(visual.animator.current_animation == "Sprint")
	visual.update_motion(1, 0.0, false)
	assert(visual.animator.current_animation == "Sword_Idle")
	visual.update_motion(1, 1.0, false)
	assert(visual.animator.current_animation == "Walk")
	assert(is_equal_approx(visual.animator.speed_scale, 0.5))
	var start: Vector3 = hero.position
	hero.attack()
	assert(visual.animator.current_animation == "Sword_Attack")
	assert(visual.animator.speed_scale == 1.0, "Slow walking must not slow combat playback")
	await physics_frame
	await physics_frame
	visual.animator.advance(0.1)
	assert(hero.position == start, "Animation must not move the gameplay body")
	visual.update_motion(0.01, 5.2, false)
	assert(visual.animator.current_animation == "Sword_Attack", "Locomotion must not interrupt attacks")
	visual.update_motion(1, 0.0, false)
	assert(visual.animator.current_animation == "Sword_Idle")
	hero.dodge()
	assert(visual.animator.current_animation == "Roll")
	hero._invulnerability_time = 0
	hero.take_damage(1)
	assert(visual.animator.current_animation == "Hit_Chest")
	hero._invulnerability_time = 0
	hero.take_damage(999)
	assert(visual.animator.current_animation == "Death01")
	visual.update_motion(3, 5.2, false)
	visual.action("Sword_Attack", 0.32)
	assert(visual.animator.current_animation == "Death01", "Death must remain terminal")
	paused = false
	hero._sound.stop()
	scene.queue_free()
	await process_frame
	await create_timer(0.4).timeout
	print("PASS: hero rig, valid animation targets, hand attachment, action priority and visual-only movement")
	quit()
