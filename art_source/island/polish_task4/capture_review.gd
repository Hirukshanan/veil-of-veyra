extends SceneTree
var scene
var camera:Camera3D
var output:String
var rows:Array[Dictionary]=[]
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	scene=load("res://.validation/island_polish_task4/baseline_candidate.gd").new() if "--baseline" in OS.get_cmdline_user_args() else load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	scene.shadows_enabled=false;scene._apply_settings();Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.msaa_3d=Viewport.MSAA_DISABLED;root.screen_space_aa=Viewport.SCREEN_SPACE_AA_DISABLED
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	camera=Camera3D.new();camera.near=.06;camera.far=700;camera.fov=62;scene.add_child(camera);camera.make_current()
	await view("01_island_overview",Vector3(0,180,0),Vector3.ZERO,true)
	await ground_view("02_forest_interior",Vector3(-64,0,12),Vector3(-68,0,-5))
	await ground_view("03_forest_approach",Vector3(-27,0,12),Vector3(-64,0,-8))
	await ground_view("04_grassy_hills",Vector3(3,0,33),Vector3(-8,0,-20))
	await view("05_mountain_landscape",Vector3(34,22,-24),Vector3(0,6,-68))
	await view("06_river_waterfall",Vector3(19,9,-43),Vector3(0,5,-68))
	await view("07_cave_exterior",Vector3(76,3.8,-19),Vector3(76,3,-4))
	await ground_view("08_sandy_shoreline",Vector3(-28,0,77),Vector3(0,0,91))
	await view("09_forest_landmark",scene.landscape.ground_point(Vector3(-28,0,20))+Vector3.UP*5,scene.landscape.ground_point(Vector3(-34,0,15))+Vector3.UP*.1)
	await view("10_river_landmark",scene.landscape.ground_point(Vector3(7,0,26))+Vector3.UP*5,scene.landscape.ground_point(Vector3(12,0,31))+Vector3.UP*.1)
	scene.shadows_enabled=true;scene._apply_settings()
	await ground_view("11_optional_shadow_hills",Vector3(3,0,33),Vector3(-8,0,-20))
	await ground_view("12_optional_shadow_forest",Vector3(-64,0,12),Vector3(-68,0,-5))
	var file:=FileAccess.open(output+"/metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"views":rows,"quality":{"renderer":"GL Compatibility","resolution":[1280,720],"msaa":false,"screen_space_aa":false,"main_views_shadows":false,"optional_shadow_views":[11,12],"scope":"Desktop Intel Iris Xe using low mobile-quality settings; not Android performance","warmup_frames":30,"sample_frames":90},"memory":{"static":Performance.get_monitor(Performance.MEMORY_STATIC),"video":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"texture":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}},"  "))
	print("PASS: twelve matched native Task 4 views, low quality and optional shadow counters saved");quit()
func ground_view(label:String,p:Vector3,target:Vector3):
	await view(label,scene.landscape.ground_point(p)+Vector3.UP*2.4,scene.landscape.ground_point(target)+Vector3.UP*2.1)
func view(label:String,p:Vector3,target:Vector3,overhead:bool=false):
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL if overhead else Camera3D.PROJECTION_PERSPECTIVE
	camera.size=245
	camera.position=p;camera.look_at(target,Vector3.FORWARD if overhead else Vector3.UP);camera.make_current()
	var visibility:Array=[]
	if overhead:
		for mesh in scene.landscape.find_children("*","GeometryInstance3D",true,false):
			visibility.append([mesh,mesh.visibility_range_begin,mesh.visibility_range_end]);mesh.visibility_range_begin=0;mesh.visibility_range_end=0
		scene.landscape.get_node("CandidateVegetation").set_review_overview(true)
	scene.player.position=scene.landscape.ground_point(Vector3(-24,0,12) if overhead else Vector3(p.x,0,p.z))
	for frame in range(30):await process_frame
	var calls:=0.0;var primitives:=0.0;var times:Array[float]=[];var previous:=Time.get_ticks_usec()
	for frame in range(90):
		await process_frame;var now:=Time.get_ticks_usec();times.append((now-previous)/1000.0);previous=now
		calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME);primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	times.sort();await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"/"+label+".png")==OK)
	rows.append({"name":label,"camera_position":p,"camera_rotation":camera.rotation,"draw_calls":calls/90,"primitives":primitives/90,"median_ms":times[45],"p95_ms":times[85],"median_interval_fps":1000.0/times[45],"shadows":scene.shadows_enabled,"overview":overhead})
	print("NATIVE_VIEW ",label," calls ",calls/90," primitives ",primitives/90)
	if overhead:
		scene.landscape.get_node("CandidateVegetation").set_review_overview(false)
		for row in visibility:row[0].visibility_range_begin=row[1];row[0].visibility_range_end=row[2]
