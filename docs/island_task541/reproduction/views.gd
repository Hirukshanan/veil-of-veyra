extends SceneTree
var scene
var camera:Camera3D
var rows:Array[Dictionary]=[]
var output:String
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
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	camera=Camera3D.new();camera.near=.06;camera.fov=60;scene.add_child(camera);camera.make_current()
	await capture("01_south_cave",Vector3(75,5,24),Vector3(76,3,3))
	await capture("02_west_waterfall",Vector3(12,8,-65),Vector3(0,2,-67))
	await capture("03_east_bank",Vector3(4,5,-55),Vector3(19,1,-54))
	await capture("04_cave_entrance",Vector3(76,3.8,-19),Vector3(76,3,-4))
	await capture("05_cave_interior",Vector3(76,2.9,-2),Vector3(76,3,8))
	await capture("06_waterfall_distance",Vector3(19,9,-43),Vector3(0,5,-68))
	await capture("07_waterfall_river",Vector3(7,5,-60),Vector3(.5,2.5,-68))
	await capture("08_bend",Vector3(76,3,7),Vector3(70,3,16))
	await capture("09_chamber",Vector3(70,3,17),Vector3(66,4,25))
	await capture("10_dragon",Vector3(66,4,32),Vector3(64,5,44))
	await capture("11_ridge_overview",Vector3(85,60,22),Vector3(70,1,22))
	var file:=FileAccess.open(output+"/metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"views":rows,"quality":{"renderer":"GL Compatibility","resolution":[1280,720],"shadows":false,"msaa":false,"screen_space_aa":false,"scope":"matched low mobile-quality configuration on desktop Intel Iris Xe; not Android performance"},"memory":{"static":Performance.get_monitor(Performance.MEMORY_STATIC),"video":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"texture":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}},"  "))
	print("PASS: seven native Task 3 views and mobile-quality desktop counters captured")
	quit()
func capture(label:String,p:Vector3,target:Vector3):
	camera.position=p;camera.look_at(target);camera.make_current()
	scene.player.position=Vector3(76,1.58,3) if label=="05_cave_interior" else scene.landscape.ground_point(Vector3(p.x,0,p.z))
	for frame in range(30):await process_frame
	var calls:=0.0;var triangles:=0.0;var times:Array[float]=[];var previous:=Time.get_ticks_usec()
	for frame in range(90):
		await process_frame;var now:=Time.get_ticks_usec();times.append((now-previous)/1000.0);previous=now
		calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME);triangles+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	times.sort();await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"/"+label+".png")==OK)
	rows.append({"name":label,"camera_position":p,"camera_rotation":camera.rotation,"draw_calls":calls/90,"primitives":triangles/90,"median_ms":times[45],"p95_ms":times[85]})
	print("NATIVE_VIEW ",label," calls ",calls/90," primitives ",triangles/90)
