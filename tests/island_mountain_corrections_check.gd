extends SceneTree

var scene
var hero
var landscape
var output: String
var recording := false
var frame := 0
var tick := 0
var walked: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var arguments := OS.get_cmdline_user_args()
	output = arguments[0]
	recording = arguments.has("--record")
	if recording:
		DirAccess.make_dir_recursive_absolute(output.path_join("frames"))
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:
		await physics_frame
	scene._resume()
	scene.shadows_enabled = false
	scene._apply_settings()
	if recording:
		scene.overlay.hide()
		scene.awakening.overlay.hide()
	for actor in get_nodes_in_group("combat_enemies"):
		actor.set_physics_process(false)
	landscape = scene.landscape
	hero = scene.player
	_check_surface()
	if not recording:
		await _check_cliff_contact()
	await _walk("western_mountain_passage", Vector2(-30, -61.5), [
		Vector2(-28, -63.5), Vector2(-24, -64.2), Vector2(-19, -64.1), Vector2(-14, -63.9),
		Vector2(-9, -63), Vector2(-7, -59), Vector2(-5, -57.5), Vector2(-3, -64)
	], -PI / 2.0)
	await _walk("eastern_hillside", Vector2(55, -31), [
		Vector2(55.5, -24), Vector2(55.5, -17), Vector2(54, -10),
		Vector2(51, -5), Vector2(47.5, -5), Vector2(44, -9)
	], PI)
	await _walk("preserved_cave", Vector2(76, -17), [
		Vector2(76, 5), Vector2(75, 10), Vector2(71, 15), Vector2(68, 19), Vector2(66, 25),
		Vector2(68, 19), Vector2(71, 15), Vector2(75, 10), Vector2(76, 5), Vector2(76, -17)
	], PI)
	var report := FileAccess.open(output.path_join("mountain_routes.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({"passed": true, "route_waypoints": walked, "video_frames": frame,
		"video_fps": 20}, "  "))
	report.close()
	print("PASS: mountain passage, eastern hillside and cave walked with the original controller and spring arm")
	scene.queue_free()
	await process_frame
	await create_timer(.25, true, false, true).timeout
	quit()

func _check_surface() -> void:
	var ground: MeshInstance3D = landscape.get_node("ConnectedTerrain")
	var ledge: MeshInstance3D = landscape.get_node("RockWaterPolish/CascadeLedge")
	for surface in [ground, ledge]:
		var shape: ConcavePolygonShape3D = surface.get_child(0).get_child(0).shape
		assert(surface.mesh.get_faces() == shape.get_faces(), "Rendered terrain and rock use their real triangle collision")
	assert(landscape.get_node("WaterfallMountains").get_child_count() == 0, "Old fractured overlays cannot intersect the new surface")
	var slope_x := 53.75
	for z in [-12.5, -10.0, -7.5, -5.0, -3.75, 0.0, 2.5, 5.0]:
		var ridge: float = landscape.height_at(Vector2(slope_x, z))
		var right: float = landscape.height_at(Vector2(slope_x + 1.25, z))
		var left: float = landscape.height_at(Vector2(slope_x - 1.25, z))
		assert(absf(ridge - right) < 1.25 and absf(ridge - left) < 1.25, "Eastern spike has no metre-scale step across the seam")
	var space: PhysicsDirectSpaceState3D = landscape.get_world_3d().direct_space_state
	var contact := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-16, 28, -75), Vector3(-16, 1, -75), 13))
	assert(not contact.is_empty() and contact.collider.get_parent() == ground and contact.position.y > 13.0,
		"The main rocky crest remains solid to hero and enemies")

func _check_cliff_contact() -> void:
	var start := Vector3(-15.5, 0, -64.0)
	hero.position = landscape.ground_point(start) + Vector3.UP * .08
	hero.velocity = Vector3.ZERO
	hero._camera_pivot.rotation.y = 0.0
	var contacts := 0
	for n in range(140):
		hero.set_move_input(Vector2(0, -1))
		await physics_frame
		for i in hero.get_slide_collision_count():
			var hit: KinematicCollision3D = hero.get_slide_collision(i)
			if hit.get_normal().y < .65 and hit.get_collider().get_parent().name == "ConnectedTerrain":
				contacts += 1
	hero.set_move_input(Vector2.ZERO)
	assert(contacts > 0 and hero.position.z > -71,
		"Normal walking must contact the steep mountain face before its crest")
	walked.append({"route": "north_cliff_contact", "player": str(hero.position), "body_contacts": contacts})

func _walk(route: String, start: Vector2, waypoints: Array, yaw: float) -> void:
	hero.position = landscape.ground_point(Vector3(start.x, 0, start.y)) + Vector3.UP * .08
	hero.velocity = Vector3.ZERO
	hero._camera_pivot.rotation = Vector3(-.09, yaw, 0)
	hero._camera_pivot.global_position = hero.position + Vector3.UP * 1.2
	var initial_health: int = hero.health
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = .08
	query.shape = sphere
	query.collision_mask = 1 | 4 | 8
	for destination in waypoints:
		var elapsed := 0
		var delta := _direction_to(destination)
		while delta.length() > .58 and elapsed < 420:
			var unit := Vector3(delta.x, 0.0, delta.y).normalized()
			var bearing := atan2(-unit.x, -unit.z)
			hero._camera_pivot.rotation.y = lerp_angle(hero._camera_pivot.rotation.y, bearing, .05)
			var input := unit.rotated(Vector3.UP, -hero._camera_pivot.rotation.y)
			hero.set_move_input(Vector2(input.x, input.z))
			await physics_frame
			elapsed += 1
			tick += 1
			if elapsed % 3 == 0:
				var camera: Camera3D = hero._camera_arm.get_child(0)
				query.transform.origin = camera.global_position
				assert(landscape.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),
					"Spring-arm camera entered terrain on %s at %s" % [route, hero.position])
			if recording and tick % 3 == 0:
				await RenderingServer.frame_post_draw
				assert(root.get_texture().get_image().save_jpg(output.path_join("frames/%05d.jpg" % frame), .93) == OK)
				frame += 1
			delta = _direction_to(destination)
		assert(elapsed < 420, "Hero blocked along %s at %s heading to %s" % [route, hero.position, destination])
		assert(hero.health == initial_health and hero.position.y > -1.0)
		walked.append({"route": route, "goal": str(destination), "player": str(hero.position), "ticks": elapsed})
	hero.set_move_input(Vector2.ZERO)
	await physics_frame
	print("PASS: ", route)

func _direction_to(destination: Vector2) -> Vector2:
	return destination - Vector2(hero.position.x, hero.position.z)
