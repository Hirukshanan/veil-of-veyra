extends SceneTree
var scene
var camera:Camera3D
var output:String
var rows:Array[Dictionary]=[]
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	scene.shadows_enabled=false;scene._apply_settings();Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.msaa_3d=Viewport.MSAA_DISABLED;root.screen_space_aa=Viewport.SCREEN_SPACE_AA_DISABLED
	camera=Camera3D.new();camera.near=.05;camera.fov=62;scene.add_child(camera)
	await view("01_forest_interior",Vector3(-64,0,12),Vector3(-66,0,-4))
	await view("02_forest_edge",Vector3(-35,0,13),Vector3(-64,0,-3))
	var vegetation:Node=scene.landscape.get_node("CandidateVegetation")
	var anchor:Vector3=vegetation.tree_positions[3]
	await detail("03_bark_detail",anchor+Vector3(1.5,1.7,1.8),anchor+Vector3(0,2.0,0))
	await detail("04_canopy_branches",anchor+Vector3(8,9,6),anchor+Vector3(0,10,0))
	await view("05_approach_grassland",Vector3(-15,0,12),Vector3(-64,0,-8))
	var grass_point:Vector3=vegetation.grass_positions[0]
	var best:float=INF
	for point in vegetation.grass_positions:
		var distance:float=Vector2(point.x+38,point.z-12).length_squared()
		if distance<best:best=distance;grass_point=point
	await detail("06_grass_close",grass_point+Vector3(.65,.45,.8),grass_point+Vector3.UP*.18)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=96;camera.position=Vector3(-64,115,-8);camera.rotation_degrees=Vector3(-90,0,0)
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	for mesh in scene.landscape.find_children("*","GeometryInstance3D",true,false):mesh.visibility_range_begin=0;mesh.visibility_range_end=0
	vegetation.set_review_overview(true);await capture("07_forest_top_down",true)
	var file:=FileAccess.open(output+"/metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"views":rows,"quality":{"renderer":"GL Compatibility","resolution":[1280,720],"msaa":false,"shadows":false,"aa":false,"scope":"matched mobile-quality settings on desktop Intel Iris Xe; not Android measurement; actors held for review"},"memory":{"static":Performance.get_monitor(Performance.MEMORY_STATIC),"video":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"texture":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}},"  "))
	print("PASS: seven matched native forest/grass inspection views and rendering counters saved")
	scene.queue_free();await process_frame;await RenderingServer.frame_post_draw;quit()
func view(label:String,p:Vector3,t:Vector3):
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=62
	var ground:Vector3=scene.landscape.ground_point(p)
	var target:Vector3=scene.landscape.ground_point(t)+Vector3.UP*2
	camera.position=ground+Vector3.UP*2.3;camera.look_at(target);camera.make_current()
	var direction:Vector3=(target-camera.position).normalized()
	scene.player.position=scene.landscape.ground_point(p+Vector3(direction.x,0,direction.z)*3)+Vector3.UP*.08
	scene.player.rotation.y=atan2(p.x-t.x,p.z-t.z)
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.show()
	scene._resume();await capture(label,false)
func detail(label:String,p:Vector3,target:Vector3):
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=55;camera.position=p;camera.look_at(target);camera.make_current()
	scene.player.position=scene.landscape.ground_point(p)
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	await capture(label,false)
func capture(label:String,overhead:bool):
	camera.make_current()
	for frame in range(30):await process_frame
	var calls:=0.0;var primitives:=0.0;var times:Array[float]=[];var previous:=Time.get_ticks_usec()
	for frame in range(90):
		await process_frame;var now:=Time.get_ticks_usec();times.append((now-previous)/1000.0);previous=now
		calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME);primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	times.sort();await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"/"+label+".png")==OK)
	rows.append({"name":label,"camera_position":camera.global_position,"camera_rotation":camera.global_rotation,"draw_calls":calls/90,"primitives":primitives/90,"median_ms":times[45],"p95_ms":times[85],"review_overview_culling_override":overhead})
	print("NATIVE_VIEW ",label," calls ",calls/90," primitives ",primitives/90)
