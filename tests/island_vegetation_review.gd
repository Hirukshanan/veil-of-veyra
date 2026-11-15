extends SceneTree
var scene
var camera:Camera3D
var views:Array[Dictionary]=[]
var output:String
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	# Representative low mobile-quality rendering, held identical before and after.
	# Desktop timings under this configuration are not Android measurements.
	scene.shadows_enabled=false
	scene._apply_settings()
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.msaa_3d=Viewport.MSAA_DISABLED
	root.screen_space_aa=Viewport.SCREEN_SPACE_AA_DISABLED
	root.scaling_3d_scale=1.0
	camera=Camera3D.new();camera.near=.1;camera.fov=62
	scene.add_child(camera)
	await view("01_forest_interior",Vector3(-64,0,12),Vector3(-66,0,-4),false)
	await view("02_forest_edge",Vector3(-35,0,13),Vector3(-64,0,-3),false)
	await view("03_open_grasslands",Vector3(4,0,24),Vector3(4,0,-2),false)
	await view("04_hillside",Vector3(-22,0,38),Vector3(-40,0,12),false)
	await view("05_riverbank",Vector3(33,0,16),Vector3(24,0,-1),false)
	await view("06_sandy_shoreline",Vector3(0,0,91),Vector3(0,0,108),false)
	await view("07_top_down",Vector3(0,240,0),Vector3.ZERO,true)
	var f:=FileAccess.open(output+"/review_metrics.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"views":views,"resolution":[root.size.x,root.size.y],"quality":{"renderer":"GL Compatibility","resolution":"1280x720","shadows":false,"msaa":false,"screen_space_aa":false,"scale_3d":1,"grass_distance":"runtime mobile vegetation limits","actors":"held static for repeatable environment comparison","timings":"desktop CPU/GPU, not Android performance"},"memory":{"static":Performance.get_monitor(Performance.MEMORY_STATIC),"video":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"texture":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}},"  "))
	print("PASS: seven native Task 2 review screenshots and mobile-quality rendering cost captured")
	scene.queue_free();await process_frame;await RenderingServer.frame_post_draw
	quit()
func view(label:String,point:Vector3,target:Vector3,overhead:bool):
	# Camera heights use immutable terrain support so poses match after vegetation.
	if overhead:
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=270
		camera.global_position=point;camera.rotation_degrees=Vector3(-90,0,0)
		for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
		# Overview only: show vegetation from altitude; not a gameplay cost sample.
		for visual in scene.landscape.find_children("*","GeometryInstance3D",true,false):visual.visibility_range_end=0;visual.visibility_range_begin=0
		var vegetation:Node=scene.landscape.get_node_or_null("CandidateVegetation")
		if vegetation!=null:vegetation.set_review_overview(true)
	else:
		camera.projection=Camera3D.PROJECTION_PERSPECTIVE
		var ground:Vector3=scene.landscape.ground_point(point)
		camera.global_position=ground+Vector3.UP*2.3
		var look:Vector3=scene.landscape.ground_point(target)+Vector3.UP*2
		camera.look_at(look)
		# Show the unchanged hero/HUD from an actual campaign viewpoint.
		var forward:Vector3=(look-camera.global_position).normalized()
		scene.player.global_position=scene.landscape.ground_point(point+Vector3(forward.x,0,forward.z)*3)+Vector3.UP*.08
		scene.player.rotation.y=atan2(point.x-target.x,point.z-target.z)
		for layer in scene.find_children("*","CanvasLayer",true,false):layer.show()
		scene._resume()
	camera.make_current()
	for frame in range(30):await process_frame
	var samples:Array[float]=[]
	var previous:=Time.get_ticks_usec()
	var calls:=0.0;var primitives:=0.0
	for frame in range(90):
		await process_frame
		var now:=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now
		calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	samples.sort()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"/"+label+".png")==OK)
	views.append({"name":label,"position":camera.global_position,"rotation":camera.global_rotation,"draw_calls_mean":calls/90,"rendered_primitives_mean":primitives/90,"median_frame_ms":samples[45],"p95_frame_ms":samples[85]})
	print("NATIVE_VIEW ",label," calls ",calls/90," primitives ",primitives/90)
