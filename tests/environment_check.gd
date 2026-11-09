extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var palettes: Array[Color] = []
	for chapter in range(3):
		var config := ConfigFile.new()
		config.set_value("campaign", "chapter", chapter)
		assert(config.save("user://campaign.cfg") == OK)
		var scene = load("res://scenes/main.tscn").instantiate()
		root.add_child(scene)
		await process_frame
		for frame in range(3):
			await physics_frame
		var decor = scene.get_node("ChapterEnvironment")
		assert(decor.chapter == 0)
		assert(decor.landmarks.size() == 10)
		var palette: Color = scene.get_node("Island/Surface").material_override.get_shader_parameter("chapter_tint")
		assert(palettes.is_empty() or palettes[0] == palette, "Legacy chapter saves must use the same island")
		palettes.append(palette)
		var space: PhysicsDirectSpaceState3D = scene.get_world_3d().direct_space_state
		for landmark in decor.landmarks:
			assert(landmark.position.length() > 12.0, "Keep the inner arena clear")
			for mesh in landmark.find_children("*", "MeshInstance3D", true, false):
				var bounds: AABB = mesh.mesh.get_aabb()
				for corner in range(8):
					var point: Vector3 = mesh.global_transform * (bounds.position + bounds.size * Vector3(corner & 1, (corner >> 1) & 1, (corner >> 2) & 1))
					assert(Vector2(point.x, point.z).length() < 35.5, "Scenery must fit on the island")
			var from: Vector3 = landmark.global_position + Vector3(0, 1.5, 2)
			var to: Vector3 = landmark.global_position + Vector3(0, 1.5, -2)
			var query := PhysicsRayQueryParameters3D.create(from, to, 4)
			assert(not space.intersect_ray(query).is_empty(), "Trunks and pillars must block the camera")
			query.collision_mask = 8
			assert(not space.intersect_ray(query).is_empty(), "Decor must block the player")
		var objectives: Array[Vector3] = [scene.lantern.global_position]
		for relic in scene.relic_hunt.relics:
			objectives.append(relic.global_position)
		for point in objectives:
			var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 5, point + Vector3.DOWN * 5, 1))
			assert(not ground.is_empty() and absf(ground.position.y) < 0.1, "Objectives must stay on walkable ground")
		scene.queue_free()
		await process_frame
		paused = false
	print("PASS: one world across legacy chapter migrations, island bounds, clear arena, player/camera collision and grounded objectives")
	quit()
