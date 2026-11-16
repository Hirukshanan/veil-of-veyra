extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var output: String = OS.get_cmdline_user_args()[0]
	var scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:
		await physics_frame
	var space: PhysicsDirectSpaceState3D = scene.get_world_3d().direct_space_state
	var points := [Vector3(76, 1.5, -5), Vector3(76, 1.5, 5), Vector3(75, 1.65, 10), Vector3(71, 2, 15), Vector3(68, 2.2, 19), Vector3(66, 2.35, 25)]
	var rows: Array = []
	for point in points:
		var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * .8, point - Vector3.UP * 2, 16)
		var floor_hit := space.intersect_ray(query)
		assert(not floor_hit.is_empty(), "Every retained waypoint must have floor support")
		var ceiling_query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.9, point + Vector3.UP * 24, 4 | 8)
		var ceiling_hit := space.intersect_ray(ceiling_query)
		assert(not ceiling_hit.is_empty(), "Every interior waypoint must have a solid ceiling")
		assert(ceiling_hit.position.y - floor_hit.position.y > 3.5)
		var capsule_query := PhysicsShapeQueryParameters3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = .42
		capsule.height = 1.8
		capsule_query.shape = capsule
		capsule_query.transform.origin = floor_hit.position + Vector3.UP * .96
		capsule_query.collision_mask = 4 | 8
		assert(space.intersect_shape(capsule_query).is_empty(), "Retained path must provide hero headroom")
		rows.append({"point": point, "floor": floor_hit.position, "ceiling": ceiling_hit.position, "hero_headroom_clear": true})
	var shape_count: int = scene.landscape.find_children("*", "CollisionShape3D", true, false).size()
	FileAccess.open(output + "/cave_geometry.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": true, "waypoints": rows, "static_shapes": shape_count, "reserved_hall_gameplay_tested": false}, "  "))
	print("PASS: six retained cave waypoints have solid floor, ceiling and capsule headroom")
	scene.queue_free()
	await process_frame
	await create_timer(.3, true, false, true).timeout
	quit()
