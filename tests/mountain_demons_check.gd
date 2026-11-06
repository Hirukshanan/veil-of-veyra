extends SceneTree
func _initialize():
	call_deferred("_run")
func _run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	await physics_frame
	var rim = scene.get_node("IslandExploration/MountainRim")
	assert(rim.get_child_count() == 13)
	var space = scene.get_world_3d().direct_space_state
	for peak in rim.PEAKS:
		var position := Vector3(peak.x + peak.z * 0.18, 0, peak.y)
		var hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(position + Vector3.UP * 40, position + Vector3.DOWN * 3, 1))
		assert(not hit.is_empty() and hit.position.y > 8.0, "Every peak must have matching physical terrain")
		assert(hit.collider.collision_layer & 4, "Mountain must block camera")
	for route in preload("res://scripts/island_terrain.gd").trails():
		for point in route:
			var hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 40, point + Vector3.DOWN * 3, 1))
			assert(not hit.is_empty() and absf(hit.position.y) < 0.1, "Mountains must not cover trails")
	for kind in range(3):
		var demon = scene.ENEMY_SCRIPT.new()
		demon.kind = kind
		demon.health = 10
		scene.add_child(demon)
		demon.set_physics_process(false)
		demon.set_process(false)
		assert(is_equal_approx(demon._visual._model.scale.x, [1.25, 1.05, 1.7][kind]))
		assert(demon.body_radius >= 0.6)
		demon._alert_time = 0.7
		demon._process(0.1)
		assert(demon._visual._clip == "bite" and not demon._visual.animator.is_playing())
		assert(demon._growl.stream != null and demon._growl.max_distance == 24.0)
		demon._alert_time = 0
		demon._process(0.1)
		assert(demon._visual._clip == "idle")
	scene.queue_free()
	await process_frame
	paused = false
	print("PASS: seven solid camera-blocking peaks, unobstructed trails, larger demon scale/colliders, snarl transition and bounded growl")
	quit()
