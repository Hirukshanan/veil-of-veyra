extends SceneTree

var scene
var camera: Camera3D
var rows: Array = []
var output: String

func _initialize():
	call_deferred("run")

func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(1600, 720)
	root.scaling_3d_scale = 1.0
	scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:
		await physics_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for actor in get_nodes_in_group("combat_enemies"):
		actor.set_physics_process(false)
	scene.shadows_enabled = false
	scene._apply_settings()
	Engine.max_fps = 30
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	camera = Camera3D.new()
	camera.near = .06
	camera.fov = 65
	scene.add_child(camera)
	camera.make_current()
	await capture("01_entrance_hero", Vector3(76, 3.4, -25), Vector3(76, 3.5, -6), true)
	await capture("02_exterior_side", Vector3(105, 12, 4), Vector3(75, 6, 8))
	await capture("03_elevated_three_quarter", Vector3(108, 47, -39), Vector3(71, 5, 19))
	await capture("04_top_down", Vector3(70, 93, 22), Vector3(70, 0, 22.1))
	await capture("05_waterfall_owner_west", Vector3(12, 8, -65), Vector3(0, 2, -67), true)
	await capture("06_river_owner_east", Vector3(4, 5, -55), Vector3(19, 1, -54), true)
	await capture("07_waterfall_crest", Vector3(9, 12, -67), Vector3(0, 8.5, -71))
	await capture("08_waterfall_base", Vector3(7, 5, -60), Vector3(.5, 2.5, -68))
	await capture("09_passage_preserved", Vector3(76, 3, 7), Vector3(70, 3, 16))
	await capture("10_inner_chamber", Vector3(70, 3.4, 17), Vector3(66, 4, 25))
	await capture("11_reserved_hall", Vector3(66, 4, 32), Vector3(64, 5, 44))
	var file := FileAccess.open(output + "/metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"views": rows, "quality": "Windows Godot GL Compatibility, 1600x720 native canvas and 720-high 3D, shadows off, 30 FPS cap; 40 warmup and 90 measured frames; actors held; not Android measurements"}, "  "))
	file.close()
	scene.queue_free()
	await process_frame
	await create_timer(.3, true, false, true).timeout
	print("PASS: actual matched candidate views")
	quit()

func capture(label: String, eye: Vector3, target: Vector3, hud: bool = false):
	scene._resume()
	for layer in scene.find_children("*", "CanvasLayer", true, false):
		layer.visible = hud and layer != scene.overlay and layer != scene.camp_menu
	camera.position = eye
	camera.look_at(target)
	scene.player.position = Vector3(76, 1.4, -16) if label.begins_with("01") else Vector3(150, -5, 150)
	for frame in range(40):
		await process_frame
	var intervals: Array[float] = []
	var cpu: Array[float] = []
	var gpu: Array[float] = []
	var calls := 0.0
	var primitives := 0.0
	var previous := Time.get_ticks_usec()
	for frame in range(90):
		await process_frame
		var now := Time.get_ticks_usec()
		intervals.append((now - previous) / 1000.0)
		previous = now
		calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
	intervals.sort()
	cpu.sort()
	gpu.sort()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output + "/" + label + ".png") == OK)
	rows.append({"name": label, "eye": eye, "target": target, "draw_calls": calls / 90, "submitted_primitives": primitives / 90, "median_frame_ms": intervals[45], "p95_frame_ms": intervals[85], "render_cpu_ms": cpu[45], "gpu_ms": gpu[45], "static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC), "video_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), "texture_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	print("CAPTURE ", label)
