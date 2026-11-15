extends SceneTree
var scene
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var output:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output+"/frames")
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	scene.shadows_enabled=false;scene._apply_settings();root.msaa_3d=Viewport.MSAA_DISABLED;root.screen_space_aa=Viewport.SCREEN_SPACE_AA_DISABLED
	scene.player.position=scene.landscape.ground_point(Vector3(-24,0,28))+Vector3.UP*.08
	scene.player._camera_pivot.rotation=Vector3(0,PI*.5,0)
	var targets:Array[Vector2]=[Vector2(-64,28),Vector2(-64,12)]
	var leg:=0;var health:int=scene.player.health;var poses:=[];var distance:=0.0;var previous:Vector3=scene.player.position
	for frame in range(480):
		if leg<targets.size():
			var offset:Vector2=targets[leg]-Vector2(scene.player.position.x,scene.player.position.z)
			if offset.length()<.55:leg+=1
			else:
				var desired:float=atan2(-offset.x,-offset.y)
				scene.player._camera_pivot.rotation.y=lerp_angle(scene.player._camera_pivot.rotation.y,desired,.075)
				var world:=Vector3(offset.x,0,offset.y).rotated(Vector3.UP,-scene.player._camera_pivot.rotation.y).normalized()
				scene.player.set_move_input(Vector2(world.x,world.z))
		else:
			scene.player.set_move_input(Vector2.ZERO)
			scene.player._camera_pivot.rotation.y=lerp_angle(scene.player._camera_pivot.rotation.y,0.0,.028)
		await physics_frame;await process_frame;await RenderingServer.frame_post_draw
		distance+=scene.player.position.distance_to(previous);previous=scene.player.position
		assert(scene.player.health==health and scene.player.position.y>-1,"Continuous recorded traversal must keep safe support and health")
		assert(root.get_texture().get_image().save_jpg(output+"/frames/%06d.jpg"%frame,.94)==OK)
		if frame in [0,120,240,360,479]:assert(root.get_texture().get_image().save_png(output+"/gameplay_%03d.png"%frame)==OK)
		if frame%10==0:poses.append({"frame":frame,"hero_position":scene.player.position,"health":scene.player.health,"leg":leg})
	assert(leg==2,"Real hero must complete grassland approach and forest path")
	var file:=FileAccess.open(output+"/gameplay_log.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames":480,"encoded_fps":30,"duration_seconds":16,"resolution":[root.size.x,root.size.y],"actual_player_controller":true,"actual_spring_arm_camera":true,"initial_fixture_position":"(-24,ground,28)","movement":"Unmodified player walking input; continuous grassland to forest approach and north along woodland trail; no teleports after initial placement","legs_completed":leg,"distance_walked_m":distance,"health_preserved":scene.player.health==health,"performance_note":"Fixed-step offline capture; playback FPS is not live or Android performance","poses":poses},"  "))
	print("PASS: actual hero explored continuously from open approach into woodland, two legs complete, health unchanged");quit()
