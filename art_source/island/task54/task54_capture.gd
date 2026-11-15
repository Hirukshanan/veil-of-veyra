extends SceneTree
var scene
var output:String
var rows:Array=[]
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.shadows_enabled=false;scene._apply_settings()
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	scene.player.set_physics_process(false)
	scene.player.position=scene.landscape.ground_point(Vector3(-30,0,20))+Vector3.UP*.08
	scene.player._camera_pivot.global_position=scene.player.position+Vector3.UP*1.2
	scene.player._camera_pivot.rotation=Vector3(-.1,.3,0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	for dimensions in [Vector2i(1280,720),Vector2i(1600,720),Vector2i(960,540)]:
		root.size=dimensions
		for frame in range(10):await process_frame
		root.scaling_3d_scale=minf(1,720.0/DisplayServer.window_get_size().y)
		scene._resume()
		await capture("gameplay_%dx%d"%[dimensions.x,dimensions.y])
		scene._show_settings(scene._pause_game)
		await capture("settings_%dx%d"%[dimensions.x,dimensions.y])
		if scene.get("settings_screen")!=null:
			for tab in ["Camera","Graphics & Sound"]:
				scene.settings_screen.select_tab(tab)
				await capture("settings_%s_%dx%d"%[tab.replace(" & ","_").to_lower(),dimensions.x,dimensions.y])
	FileAccess.open(output+"/capture_metrics.json",FileAccess.WRITE).store_string(JSON.stringify({"platform":"Godot Windows; not Android","quality":"accepted 720p 3D cap, native window HUD, shadows off; actor physics held for matched visual comparison","views":rows},"  "))
	print("PASS: actual Task 5.4 HUD/settings captures saved")
	scene.queue_free();paused=false;await process_frame;await create_timer(.25,true,false,true).timeout;quit()
func capture(label:String):
	for frame in range(40):
		if not label.begins_with("settings") and paused:scene._resume()
		await process_frame
	var times:Array[float]=[];var gpu:Array[float]=[];var calls:=0.0;var primitives:=0.0;var last:=Time.get_ticks_usec()
	for frame in range(90):
		await process_frame;var now:=Time.get_ticks_usec();times.append((now-last)/1000.0);last=now
		calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME);primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
	times.sort();gpu.sort();await RenderingServer.frame_post_draw
	var image:Image=root.get_texture().get_image();assert(image.save_png(output+"/"+label+".png")==OK)
	assert(image.get_size()==DisplayServer.window_get_size(),"Capture must include the full landscape viewport, not a letterboxed render target")
	rows.append({"name":label,"physical_pixels":image.get_size(),"logical_viewport":root.get_visible_rect().size,"render_scale":root.scaling_3d_scale,"draw_calls":calls/90,"submitted_primitives":primitives/90,"frame_median_ms":times[45],"frame_p95_ms":times[85],"gpu_median_ms":gpu[45] if gpu[45]>0 else null,"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})
	print("CAPTURE ",label)
