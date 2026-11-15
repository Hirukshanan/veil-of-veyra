extends SceneTree
func _initialize():call_deferred("run")
func run():
	var scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	var points := []
	for z in range(-34,8,2):
		for x in range(48,90,2):
			var query := PhysicsRayQueryParameters3D.create(Vector3(x,4.5,z),Vector3(x,-3,z),16)
			var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or hit.normal.y<0.8:continue
			var shape := PhysicsShapeQueryParameters3D.new()
			var capsule := CapsuleShape3D.new()
			capsule.radius=.42
			capsule.height=1.8
			shape.shape=capsule
			shape.transform.origin=hit.position+Vector3.UP*.97
			shape.collision_mask=4|8
			if not scene.get_world_3d().direct_space_state.intersect_shape(shape).is_empty():continue
			query=PhysicsRayQueryParameters3D.create(hit.position+Vector3.UP*1.9,hit.position+Vector3.UP*15,16)
			query.hit_back_faces=true
			var roof: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(query)
			if not roof.is_empty():points.append({"floor":hit.position,"roof":roof.position,"normal":roof.normal})
	var f:=FileAccess.open("res://.validation/island_2026-11-15/cave_probe.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(points,"  "))
	print("CAVE_CLEAR_HEADROOM_POINTS ",points.size())
	scene.queue_free()
	await process_frame
	quit()
