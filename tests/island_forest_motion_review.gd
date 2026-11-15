extends SceneTree
var scene
func _initialize():call_deferred("run")
func weights(distance:float)->Vector3:
	var a:float=1-smoothstep(32,44,distance);var c:float=smoothstep(72,84,distance)
	return Vector3(a,(1-a)*(1-c),c)*(1-smoothstep(145,162,distance))
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var output:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output+"/frames")
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	scene.shadows_enabled=false;scene._apply_settings();root.msaa_3d=Viewport.MSAA_DISABLED;root.screen_space_aa=Viewport.SCREEN_SPACE_AA_DISABLED
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	var camera:=Camera3D.new();camera.fov=62;camera.near=.1;scene.add_child(camera);camera.make_current()
	var vegetation:Node=scene.landscape.get_node("CandidateVegetation")
	var previous:Dictionary={};var max_delta:=0.0;var crossed:Dictionary={};var samples:=[]
	for frame in range(360):
		var progress:float=frame/359.0
		var x:float=lerpf(16,-72,progress/.75) if progress<=.75 else lerpf(-72,-40,(progress-.75)/.25)
		var ground:Vector3=scene.landscape.ground_point(Vector3(x,0,12))
		camera.position=ground+Vector3.UP*3.0
		camera.look_at(scene.landscape.ground_point(Vector3(-85,0,-4))+Vector3.UP*5)
		scene.player.position=ground+Vector3.UP*.08
		vegetation._update_density()
		for tree in vegetation.trees:
			if int(tree.get_meta("tree_lod"))!=0:continue
			var distance:float=Vector2(camera.position.x-tree.position.x,camera.position.z-tree.position.z).length()
			var w:Vector3=weights(distance);var key:String=str(tree.name)
			if previous.has(key):max_delta=maxf(max_delta,maxf(absf(w.x-previous[key].x),maxf(absf(w.y-previous[key].y),absf(w.z-previous[key].z))))
			previous[key]=w
			if w.x>0 and w.y>0:crossed["near_mid"]=true
			if w.y>0 and w.z>0:crossed["mid_far"]=true
		await process_frame;await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_jpg(output+"/frames/%06d.jpg"%frame,.94)==OK)
		if frame%10==0:samples.append({"frame":frame,"camera_position":camera.position,"hero_position":scene.player.position})
	var file:=FileAccess.open(output+"/motion_log.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames":360,"encoded_fps":30,"duration_seconds":12,"resolution":[root.size.x,root.size.y],"camera_rail":"accelerated inspection sweep toward and back from forest, not real player speed","coverage_bands_crossed":crossed,"max_reference_weight_change_per_frame":max_delta,"weights_note":"CPU reference of shader coverage, not a pixel-level popping measurement","performance_note":"Fixed-step offline capture; playback FPS is not Android or live performance","poses":samples},"  "))
	assert(crossed.has("near_mid") and crossed.has("mid_far"));print("PASS: native 12-second LOD camera sweep; both tree transition bands crossed, reference max delta ",max_delta)
	scene.queue_free();await process_frame;await RenderingServer.frame_post_draw;quit()
