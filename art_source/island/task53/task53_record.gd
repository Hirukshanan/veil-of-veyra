extends SceneTree
var scene
var output:String
var frame_index:=0
var completed:=0
var charges:=0
var clock:=0.0
var events:Array=[]
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output+"/frames")
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.shadows_enabled=false;scene._apply_settings();Engine.max_fps=0;Engine.time_scale=1
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true);DisplayServer.window_set_size(Vector2i(1280,720));DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	var boar=scene.get_node("DemonBoar");var hero=scene.player
	hero.position=scene.landscape.ground_point(boar.position+Vector3.FORWARD*4.2)+Vector3.UP*.08;hero.set_physics_process(false);hero.health=100;hero._invulnerability_time=1000
	var camera:=Camera3D.new();camera.fov=62;camera.near=.06;scene.add_child(camera)
	camera.position=Vector3(-25,5.3,19);camera.look_at(Vector3(-36,1,9));camera.make_current()
	for frame in range(40):
		if paused:scene._resume()
		await process_frame
	root.scaling_3d_scale=minf(1,720.0/DisplayServer.window_get_size().y)
	boar.state_changed.connect(func(previous:int,current:int):
		if current==boar.State.CHARGE:charges+=1
		if previous==boar.State.RECOVERY and current==boar.State.CHASE:completed+=1
		events.append({"frame":frame_index,"seconds":clock,"from":boar.State.keys()[previous],"to":boar.State.keys()[current],"boar":boar.position})
	)
	boar.set_physics_process(true)
	for frame in range(1500):
		if paused:scene._resume()
		await process_frame;await RenderingServer.frame_post_draw
		var image:Image=root.get_texture().get_image();assert(image.save_jpg(output+"/frames/%05d.jpg"%frame_index,.94)==OK)
		if boar.state==boar.State.WARNING and not FileAccess.file_exists(output+"/charge_warning.png"):image.save_png(output+"/charge_warning.png")
		if boar.state==boar.State.CHARGE and not FileAccess.file_exists(output+"/charge_attack.png"):image.save_png(output+"/charge_attack.png")
		if boar.state==boar.State.RECOVERY and not FileAccess.file_exists(output+"/charge_recovery.png"):image.save_png(output+"/charge_recovery.png")
		frame_index+=1;clock+=1.0/30
		if completed>=5:break
	assert(completed>=5 and charges>=5,"Recorded footage must demonstrate at least five actual charge/recovery cycles")
	FileAccess.open(output+"/recording.json",FileAccess.WRITE).store_string(JSON.stringify({"platform":"Godot Windows gameplay; not Android benchmark","fixed_capture_fps":30,"frames":frame_index,"duration_s":clock,"completed_cycles":completed,"charges":charges,"controlled_player":"actual unchanged player, health100 with test-only invulnerability and physics held; no normal gameplay rules changed","events":events},"  "))
	print("PASS: actual Godot footage captured ",completed," full charge/recovery cycles in ",clock," seconds")
	scene.queue_free();paused=false;await process_frame;await create_timer(.25,true,false,true).timeout;quit()
