extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var out:String=OS.get_cmdline_user_args()[0];var expected:int=int(OS.get_cmdline_user_args()[1])
	DirAccess.make_dir_recursive_absolute(out)
	var wrapper=load("res://mobile_test/main.tscn").instantiate();root.add_child(wrapper)
	while wrapper.get_node_or_null("MobilePerformanceProbe")==null:await process_frame
	var probe=wrapper.get_node("MobilePerformanceProbe");var game=probe.game
	assert(game.placement_ready and game.frame_limit==30 and not game.shadows_enabled)
	assert(int(wrapper.performance_config.render_height)==expected)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true)
	var resolution_checks:=[]
	for dimensions in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1600,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size=dimensions
		for frame in range(5):await process_frame
		var physical:Vector2i=DisplayServer.window_get_size();var desired:float=minf(1.0,720.0/physical.y) if expected>0 else 1.0
		assert(absf(root.scaling_3d_scale-desired)<.001)
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().get_size()==physical,"HUD render target must span the native landscape window")
		if float(physical.x)/physical.y>1.8:assert(root.get_visible_rect().size.x>1280)
		var bounds:Vector2=game.mobile_hud.control("MovementJoystick").get_parent().size
		var controls_before:Dictionary=game.mobile_hud.rectangles(bounds)
		root.scaling_3d_scale=1.0
		assert(game.mobile_hud.rectangles(bounds)==controls_before,"3D scaling must never modify HUD/input rectangles")
		wrapper._apply_render_scale()
		resolution_checks.append({'physical':physical,'scale':root.scaling_3d_scale,'hud_rectangles_preserved':true,'native_canvas_pixels':root.get_texture().get_image().get_size(),'full_landscape_width':true})
	probe._metadata();game._resume()
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	for frame in range(185):await process_frame
	probe._notification(NOTIFICATION_APPLICATION_PAUSED)
	var path:String="user://"+probe.session
	var meta:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path+"/session.json"))
	assert(meta.schema==2 and int(meta.experiment.render_height)==expected)
	assert(FileAccess.get_file_as_string(path+"/frames.csv").split("\n").size()>150)
	var csv:String=FileAccess.get_file_as_string(path+"/counters.csv")
	assert(csv.split("\n").size()>2 and "render_cpu_ms,gpu_ms,physics_ms" in csv)
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(out+"/DESKTOP_ONLY_packaged_gameplay.png")==OK)
	var result:={'passed':true,'phone_execution':false,'platform':OS.get_name(),'schema':2,'render_height':expected,'resolution_and_hud_checks':resolution_checks,'local_counter_csv_verified':true,'profile_directory':ProjectSettings.globalize_path(path)}
	var f:=FileAccess.open(out+"/bootstrap_check.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
	game.frame_limit=60;game.shadows_enabled=false;game.camera_distance=8.2;game.hud_scale=1.05;game.sound_volume=.4;game._apply_settings();assert(game._save_settings()==OK)
	wrapper.queue_free();await process_frame;await create_timer(.3,true,false,true).timeout
	var reloaded=load("res://mobile_test/main.tscn").instantiate();root.add_child(reloaded)
	while reloaded.get_node_or_null("MobilePerformanceProbe")==null:await process_frame
	var loaded_game=reloaded.get_node("MobilePerformanceProbe").game
	assert(loaded_game.frame_limit==60 and not loaded_game.shadows_enabled)
	assert(absf(loaded_game.camera_distance-8.2)<.001 and absf(loaded_game.hud_scale-1.05)<.001 and absf(loaded_game.sound_volume-.4)<.001)
	assert(absf(root.scaling_3d_scale-minf(1,720.0/DisplayServer.window_get_size().y))<.001)
	result.saved_preferences_retained_on_boot=true;result.separate_test_package_preserved=true
	FileAccess.open(out+"/bootstrap_check.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("PASS: exported Task 5.4 candidate; saved camera/HUD/volume/frame preferences, 720p cap and native HUD; desktop functional check only")
	reloaded.queue_free();await process_frame;await create_timer(.3,true,false,true).timeout;quit()
