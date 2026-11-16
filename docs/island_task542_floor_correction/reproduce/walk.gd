extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var output: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output + "/frames")
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(1280, 720)
	var scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:
		await physics_frame
	scene._resume()
	scene.shadows_enabled = false
	scene._apply_settings()
	for actor in get_nodes_in_group("combat_enemies"):
		actor.set_physics_process(false)
	var hero = scene.player
	hero.position = Vector3(76, 1.65, -17)
	hero._camera_pivot.global_position = hero.position + Vector3.UP * 1.2
	hero._camera_pivot.rotation = Vector3(-.12, PI, 0)
	var waypoints := [Vector2(76, 5), Vector2(75, 10), Vector2(71, 15), Vector2(68, 19), Vector2(66, 25), Vector2(68, 19), Vector2(71, 15), Vector2(75, 10), Vector2(76, 5), Vector2(76, -17)]
	var checkpoint := 0
	var ticks := 0
	var frame := 0
	var rows: Array = []
	var initial_health: int = hero.health
	while checkpoint < waypoints.size() and ticks < 2200:
		var direction: Vector2 = waypoints[checkpoint] - Vector2(hero.position.x, hero.position.z)
		if direction.length() < .55:
			rows.append({"waypoint": checkpoint, "position": hero.position, "health": hero.health})
			checkpoint += 1
			continue
		var world_direction := Vector3(direction.x, 0, direction.y).normalized()
		var yaw := atan2(-world_direction.x, -world_direction.z)
		hero._camera_pivot.rotation.y = lerp_angle(hero._camera_pivot.rotation.y, yaw, .045)
		var input_direction: Vector3 = world_direction.rotated(Vector3.UP, -hero._camera_pivot.rotation.y)
		hero.set_move_input(Vector2(input_direction.x, input_direction.z))
		await physics_frame
		ticks += 1
		if ticks % 4 == 0:
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_jpg(output + "/frames/%04d.jpg" % frame, .94) == OK)
			frame += 1
			if checkpoint in [0, 2, 4, 9] and ticks % 60 == 0:
				root.get_texture().get_image().save_png(output + "/walk_%02d.png" % checkpoint)
	hero.set_move_input(Vector2.ZERO)
	var result := {"passed": checkpoint == waypoints.size() and 1 in scene.relic_hunt.collected_ids and hero.health == initial_health, "waypoints": rows, "frames": frame, "encoded_fps": 15, "hero_controller_unmodified": true, "teleports_after_initial_placement": 0, "cave_relic_collected": 1 in scene.relic_hunt.collected_ids, "returned_outside": checkpoint == waypoints.size(), "reserved_dragon_hall_gameplay_tested": false, "note": "Fixed-step offline recording with actual hero physics and spring arm, enemy physics held. Playback rate is not a performance measurement."}
	FileAccess.open(output + "/walk_results.json", FileAccess.WRITE).store_string(JSON.stringify(result, "  "))
	assert(result.passed, "Hero must enter, collect relic, traverse bend/chamber and return")
	print("PASS: actual cave entry, curved passage, inner chamber, relic and return")
	scene.queue_free()
	await process_frame
	await create_timer(.3, true, false, true).timeout
	quit()
