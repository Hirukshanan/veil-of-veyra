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
	scene.player.position=Vector3(76,1.58,-10)
	scene.player._camera_pivot.rotation=Vector3(0,PI,0)
	var health:int=scene.player.health;var poses:=[];var minimum_y:=100.0;var maximum_y:=-100.0
	for frame in range(360):
		# Existing hero controller, physics, spring-arm camera, relic and HUD remain active.
		scene.player.set_move_input(Vector2.UP if scene.player.position.z<7.1 else Vector2.ZERO)
		await physics_frame;await process_frame;await RenderingServer.frame_post_draw
		minimum_y=minf(minimum_y,scene.player.position.y);maximum_y=maxf(maximum_y,scene.player.position.y)
		assert(root.get_texture().get_image().save_jpg(output+"/frames/%06d.jpg"%frame,.94)==OK)
		if frame in [0,90,180,270,359]:assert(root.get_texture().get_image().save_png(output+"/gameplay_%03d.png"%frame)==OK)
		if frame%10==0:poses.append({"frame":frame,"hero_position":scene.player.position,"health":scene.player.health})
	assert(scene.player.position.z>6.0 and scene.player.health==health)
	assert(minimum_y>1.3 and maximum_y<2.2)
	assert(1 in scene.relic_hunt.collected_ids)
	var file:=FileAccess.open(output+"/gameplay_log.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames":360,"encoded_fps":30,"duration_seconds":12,"resolution":[root.size.x,root.size.y],"actual_player_controller":true,"actual_spring_arm_camera":true,"initial_fixture_position":"(76,1.58,-10)","movement":"Unmodified hero walking input; no teleports after initial placement","ended_inside_cave":scene.player.position.z>6.0,"relic_collected":1 in scene.relic_hunt.collected_ids,"health_preserved":scene.player.health==health,"height_range":[minimum_y,maximum_y],"performance_note":"Fixed-step offline capture; playback FPS is not live or Android performance","poses":poses},"  "))
	print("PASS: actual hero walked into and across connected cave, existing relic collected, health unchanged")
	quit()
