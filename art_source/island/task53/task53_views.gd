extends SceneTree
var scene
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var output:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.shadows_enabled=false;scene._apply_settings();Engine.max_fps=0
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true);DisplayServer.window_set_size(Vector2i(1280,720))
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	scene.player.set_physics_process(false)
	var camera:=Camera3D.new();camera.near=.06;camera.fov=62;scene.add_child(camera);camera.make_current()
	var views:=[]
	for name in ["CampDemon0","CampDemon1","CampDemon2","CampDemon3","CampDemon4","DemonBoar"]:
		var actor=scene.get_node(name);var point:Vector3=actor.position
		camera.position=scene.landscape.ground_point(point+Vector3(6,0,8))+Vector3.UP*3;camera.look_at(point+Vector3.UP)
		scene.player.position=scene.landscape.ground_point(point+Vector3(4,0,3))+Vector3.UP*.08
		for frame in range(25):
			if paused:scene._resume()
			await process_frame
		root.scaling_3d_scale=minf(1,720.0/DisplayServer.window_get_size().y)
		await RenderingServer.frame_post_draw;assert(root.get_texture().get_image().save_png(output+"/"+name+".png")==OK)
		views.append({"enemy_id":name,"position":point,"camera":camera.position})
	FileAccess.open(output+"/views.json",FileAccess.WRITE).store_string(JSON.stringify(views,"  "))
	print("PASS: six actual candidate encounter gameplay views captured")
	scene.queue_free();paused=false;await process_frame;await create_timer(.25,true,false,true).timeout;quit()
