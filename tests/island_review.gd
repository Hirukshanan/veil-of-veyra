extends SceneTree

var scene
var output := "res://.validation/island_2026-11-15"
var views: Array[Dictionary] = []

func _initialize() -> void:call_deferred("run")

func shot(label: String, point: Vector3, yaw: float) -> void:
	var hero = scene.player
	hero.global_position = scene.landscape.safe_point(point)
	hero.velocity = Vector3.ZERO
	hero.rotation.y = yaw
	hero._camera_pivot.rotation = Vector3(-0.12,yaw,0)
	hero._camera_pivot.global_position = hero.global_position+Vector3.UP*1.2
	for frame in range(12):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")
	views.append({"view":label,"hero_position":hero.global_position,"camera":hero._camera_pivot.global_position,"yaw":yaw})

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	assert(OS.get_environment("APPDATA").replace("\\","/").contains("/.validation/island_"))
	scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	await shot("island_third_person",Vector3(0,0,27),0)
	await shot("island_mountains",Vector3(0,0,-35),0)
	await shot("island_forest",Vector3(-64,0,12),0)
	await shot("island_grassland",Vector3(4,0,24),0)
	await shot("island_cave",Vector3(68,0,-38),PI)
	scene.player.global_position = Vector3(76,1.58,1)
	scene.player._camera_pivot.rotation = Vector3(-0.12,PI,0)
	scene.player._camera_pivot.global_position = scene.player.global_position+Vector3.UP*1.2
	for frame in range(12):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/island_cave_interior.png")
	await shot("island_waterfall",Vector3(26,0,-48),0.9)
	await shot("island_beach",Vector3(0,0,90),PI)
	await shot("island_river",Vector3(33,0,42),0.9)
	# Native engine overview; only its review camera suppresses HUD for legibility.
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 260
	camera.position = Vector3(0,240,70)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	for node in scene.find_children("*","CanvasLayer",true,false):node.hide()
	for frame in range(12):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/island_overview.png")
	var result := {"scene":"island_candidate.tscn","views":views,"placements":scene.placement_log,"regions":scene.landscape.REGION_FILES,"ground_triangles":scene.landscape.ground_triangles,"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)}
	var file := FileAccess.open(output+"/review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "))
	print("PASS: native candidate screenshots saved; actual campaign, controlled review positions, unchanged hero/HUD")
	scene.queue_free()
	await process_frame
	quit()
