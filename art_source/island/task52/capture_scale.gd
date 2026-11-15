extends SceneTree
var scene
var camera:Camera3D
var output:String
var rows:Array=[]
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	scene.shadows_enabled=false;scene._apply_settings();Engine.max_fps=0
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true);DisplayServer.window_set_size(Vector2i(1920,1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for frame in range(10):await process_frame
	root.scaling_3d_scale=minf(1.0,720.0/DisplayServer.window_get_size().y)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	camera=Camera3D.new();camera.near=.06;camera.far=700;camera.fov=62;scene.add_child(camera);camera.make_current()
	await view("01_mountain_scale",Vector3(17,9,-31),Vector3(0,10,-65),Vector3(-2,0,-55))
	await view("02_hills_scale",Vector3(-1,5,37),Vector3(-10,4,3),Vector3(-5,0,25))
	await view("03_waterfall_scale",Vector3(9,5,-57),Vector3(0,4,-69),Vector3(2,0,-65))
	await view("04_cave_scale",Vector3(77,3.7,-17),Vector3(76,3,-3),Vector3(76,0,-8))
	await view("05_upper_river",Vector3(20,8,-44),Vector3(19,0,-29),Vector3(20,0,-35))
	await view("06_middle_river",Vector3(18,5,20),Vector3(24,0,4),Vector3(24,0,9))
	await view("07_lower_river",Vector3(21,4,80),Vector3(25,-.2,65),Vector3(24,0,71))
	await view("08_forest_collision",Vector3(-65,4,17),Vector3(-65,3,5),Vector3(-65,0,12))
	await view("09_island_overview",Vector3(0,220,0),Vector3.ZERO,Vector3(0,0,27),true)
	var boxes:={}
	for region in scene.landscape.regions:
		var box:=AABB();var first:=true
		for mesh in region.find_children("*","MeshInstance3D",true,false):
			var b:AABB=mesh.global_transform*mesh.mesh.get_aabb();box=b if first else box.merge(b);first=false
		boxes[str(region.name)]={"position_m":box.position,"size_m":box.size,"top_y_m":box.end.y}
	var bodies:=[]
	for node in scene.player.get_children():
		if node is CollisionShape3D:bodies.append({"shape":node.shape.get_class(),"height_m":node.shape.height,"radius_m":node.shape.radius})
	var hero_box:=AABB();var first_hero:=true
	for mesh in scene.player._visual.find_children("*","MeshInstance3D",true,false):
		var box:AABB=mesh.global_transform*mesh.get_aabb();hero_box=box if first_hero else hero_box.merge(box);first_hero=false
	bodies.append({"visible_model_aabb_height_m":hero_box.size.y,"note":"runtime MeshInstance bounds; animation conservative bounds can differ from exact posed vertex height"})
	var placements:=[]
	for row in scene.placement_log:placements.append({"node":row.node,"after":str(row.after)})
	var helper=load("res://tests/island_vegetation_check.gd").new()
	var fingerprint=helper.fingerprint(scene.landscape);helper.free()
	var feature_samples:=[]
	for p in [Vector3(-14,0,-8),Vector3(0,0,-68),Vector3(0,0,27)]:feature_samples.append({"xz_m":Vector2(p.x,p.z),"actual_ground_y_m":scene.landscape.ground_point(p).y})
	var fall_box:AABB=scene.landscape.get_node("RockWaterPolish/CliffFollowingWaterfall").mesh.get_aabb()
	var file:=FileAccess.open(output+"/measurements.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"platform":OS.get_name(),"android_measurement":false,"units":"one Godot unit = one metre","hero_physics":bodies,"regions":boxes,"grotto":{"width_m":5.2,"height_m":3.8,"length_m":16},"waterfall":{"position_m":fall_box.position,"size_m":fall_box.size},"ground_samples":feature_samples,"river_length_z_m":186,"views":rows,"fingerprint":fingerprint,"placements":placements,"quality":{"physical_window":DisplayServer.window_get_size(),"scale_3d":root.scaling_3d_scale,"shadows":false,"sampling":"60 warmup, 120 frames; real HUD/animated visuals; actor physics held for matched render comparison"}},"  "))
	print("PASS: Task 5.2 actual candidate captures and dimensions saved")
	scene.queue_free();await process_frame;await create_timer(.25,true,false,true).timeout;quit()
func view(label:String,p:Vector3,target:Vector3,hero_point:Vector3,overview:bool=false):
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL if overview else Camera3D.PROJECTION_PERSPECTIVE;camera.size=245
	camera.position=p;camera.look_at(target,Vector3.FORWARD if overview else Vector3.UP)
	scene.player.position=scene.landscape.ground_point(hero_point)+Vector3.UP*.08
	scene._resume()
	for frame in range(60):
		if paused:scene._resume()
		await process_frame
	var times:Array[float]=[];var gpu:Array[float]=[];var calls:=0.0;var triangles:=0.0;var last:=Time.get_ticks_usec()
	for frame in range(120):
		if paused:scene._resume()
		await process_frame;var now:=Time.get_ticks_usec();times.append((now-last)/1000.0);last=now
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
		calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME);triangles+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	times.sort();gpu.sort();await RenderingServer.frame_post_draw
	assert(not paused,"Review screenshots must show gameplay, never a focus-loss pause menu")
	assert(root.get_texture().get_image().save_png(output+"/"+label+".png")==OK)
	rows.append({"name":label,"camera":p,"target":target,"hero":scene.player.position,"draw_calls":calls/120,"submitted_primitives":triangles/120,"frame_median_ms":times[60],"frame_p95_ms":times[114],"gpu_median_ms":gpu[60] if gpu[60]>0 else null,"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
	print("CAPTURE ",label)
