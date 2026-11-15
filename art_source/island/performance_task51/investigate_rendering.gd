extends SceneTree
var scene
var camera:Camera3D
var rows:Array=[]
var output:String
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	var start:=Time.get_ticks_usec()
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	var startup_ms:float=(Time.get_ticks_usec()-start)/1000.0
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true);DisplayServer.window_set_size(Vector2i(1920,1080))
	for frame in range(10):await process_frame
	scene._resume();scene.shadows_enabled=false;scene._apply_settings();Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	scene.player.set_physics_process(false)
	camera=Camera3D.new();camera.fov=62;camera.near=.06;scene.add_child(camera);camera.make_current()
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var poses=[['forest',Vector3(-64,4.23,12),Vector3(-68,4,-5)],['hills',Vector3(3,5.1,33),Vector3(-8,5,-20)],['mountain',Vector3(34,22,-24),Vector3(0,6,-68)]]
	for pose in poses:
		camera.position=pose[1];camera.look_at(pose[2]);scene.player.position=scene.landscape.ground_point(Vector3(pose[1].x,0,pose[1].z))
		for condition in ['native_a','cap720_a','cap720_b','native_b','no_vegetation_diagnostic','ai_active_diagnostic']:
			root.scaling_3d_scale=minf(1.0,720.0/DisplayServer.window_get_size().y) if condition.begins_with('cap720') else 1.0
			scene.landscape.get_node('CandidateVegetation').visible=condition!='no_vegetation_diagnostic'
			for enemy in get_nodes_in_group('combat_enemies'):enemy.set_physics_process(condition=='ai_active_diagnostic')
			await sample(pose[0],condition)
	var f:=FileAccess.open(output+'/investigation.json',FileAccess.WRITE)
	f.store_string(JSON.stringify({'platform':OS.get_name(),'device':'Desktop Intel Iris Xe (not Samsung)','android_measurement':false,'window_pixels':DisplayServer.window_get_size(),'viewport_pixels':root.size,'screenshot_pixels':root.get_texture().get_image().get_size(),'logical_visible_rect':root.get_visible_rect(),'startup_to_placement_ready_ms':startup_ms,'method':'60 warm-up + 120 sampled frames. ABBA resolution-only trials, then isolated diagnostic hiding/AI cases. Uncapped, requested VSync off; GPU/CPU render timers when backend supplies them. No vegetation or AI change is retained. Player and enemy physics held during render-only ABBA trials; AI re-enabled only in a separately labeled diagnostic. Animated visuals and HUD remain active. Borderless 1920x1080 physical window requested and actual output recorded.','rows':rows},'  '))
	print('PASS: controlled desktop Task 5.1 investigation complete; not Android performance');quit()
func sample(zone:String,condition:String):
	for frame in range(60):await process_frame
	var intervals:Array[float]=[];var gpu:Array[float]=[];var cpu:Array[float]=[];var physics:Array[float]=[];var process:Array[float]=[];var calls:=0.0;var primitives:=0.0;var last:=Time.get_ticks_usec()
	for frame in range(120):
		await process_frame;var now:=Time.get_ticks_usec();intervals.append((now-last)/1000.0);last=now
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()));cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())+RenderingServer.get_frame_setup_time_cpu())
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000);process.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
		calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME);primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	for values in [intervals,gpu,cpu,physics,process]:values.sort()
	var row:={'zone':zone,'condition':condition,'scale_3d':root.scaling_3d_scale,'estimated_3d_buffer_pixels':Vector2i(Vector2(DisplayServer.window_get_size())*root.scaling_3d_scale),'median_frame_ms':intervals[60],'p95_frame_ms':intervals[114],'gpu_median_ms':gpu[60] if gpu[60]>0 else null,'render_cpu_median_ms':cpu[60] if cpu[60]>0 else null,'engine_process_median_ms':process[60],'physics_median_ms':physics[60],'draw_calls':calls/120,'submitted_primitives':primitives/120,'static_bytes':Performance.get_monitor(Performance.MEMORY_STATIC),'video_bytes':Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
	rows.append(row);print('MEASURE ',zone,' ',condition,' median_ms=',intervals[60],' gpu_ms=',gpu[60],' cpu_render_ms=',cpu[60])
	if condition in ['native_a','cap720_a']:
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(output+'/'+zone+'_'+condition+'.png')==OK)
