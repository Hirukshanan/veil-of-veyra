extends SceneTree
var scene
var taps:=0
var evidence:Array=[]
func _initialize():call_deferred("run")
func touch(at:Vector2,pressed:bool,index:int,canceled:bool=false):
	var event:=InputEventScreenTouch.new();event.position=at;event.pressed=pressed;event.index=index;event.canceled=canceled;root.push_input(event)
func drag(at:Vector2,relative:Vector2,index:int):
	var event:=InputEventScreenDrag.new();event.position=at;event.relative=relative;event.index=index;root.push_input(event)
func wait(seconds:float):await create_timer(seconds,false,true).timeout
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	root.content_scale_size=Vector2i.ZERO;root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1280,720)
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	var hero=scene.player;hero.set_physics_process(false)
	var joystick=scene.mobile_hud.control("MovementJoystick");var center:Vector2=joystick.get_global_rect().get_center();var radius:float=joystick.size.x*.34
	assert(scene.find_child("SprintButton",true,false)==null)
	touch(center,true,0);drag(center+Vector2.UP*radius*.95,Vector2.UP*20,0);await wait(.35)
	assert(not hero.sprint_enabled and hero._touch_move.y< -.9,"Normal full-forward movement must not trigger sprint")
	drag(center+Vector2.UP*radius*1.45,Vector2.UP*35,0);await wait(.32)
	assert(hero.sprint_enabled and not joystick.auto_sprint,"Deliberate upper-rim hold activates held sprint")
	var stamina:float=hero.stamina;assert(hero._sprint_speed(1,1)==hero.SPRINT_SPEED and hero.stamina==stamina-25)
	touch(center,false,0);assert(not hero.sprint_enabled and hero._touch_move==Vector2.ZERO)
	evidence.append({"case":"normal_walk_held_sprint_release","passed":true,"normal_speed":hero.MOVE_SPEED,"sprint_speed":hero.SPRINT_SPEED,"stamina_cost_per_s":25})
	hero.stamina=100
	touch(center,true,0);drag(center+Vector2.UP*radius*2.05,Vector2.UP*100,0);await wait(.85)
	assert(hero.sprint_enabled and joystick.auto_sprint,"Farther upward hold explicitly confirms AUTO")
	touch(center,false,0);await wait(.05);assert(joystick.auto_sprint and hero._touch_move==Vector2.UP)
	touch(center,true,0);assert(not joystick.auto_sprint and not hero.sprint_enabled);touch(center,false,0)
	evidence.append({"case":"auto_release_continues_new_stick_touch_cancels","passed":true})
	hero.stamina=19
	touch(center,true,0);drag(center+Vector2.UP*radius*2.05,Vector2.UP*100,0);await wait(.85)
	assert(not hero.sprint_enabled and not joystick.auto_sprint,"Existing20 stamina start threshold remains authoritative")
	touch(center,false,0);hero.stamina=100;hero._attack_cooldown=1
	touch(center,true,0);drag(center+Vector2.UP*radius*1.5,Vector2.UP*100,0);await wait(.4);assert(not hero.sprint_enabled)
	touch(center,false,0);hero._attack_cooldown=0
	touch(center,true,0);drag(center+Vector2.UP*radius*2.05,Vector2.UP*100,0);await wait(.85);touch(center,false,0)
	assert(joystick.auto_sprint);hero.stamina=0;hero._sprint_speed(.01,1);await wait(.05)
	assert(not joystick.auto_sprint and hero._touch_move==Vector2.ZERO)
	evidence.append({"case":"stamina_attack_and_depletion_restrictions","passed":true})
	hero.stamina=100
	touch(center,true,0);drag(center+Vector2.UP*radius*2.05,Vector2.UP*100,0);await wait(.85);touch(center,false,0)
	joystick._notification(NOTIFICATION_APPLICATION_FOCUS_OUT);assert(not joystick.auto_sprint and hero._touch_move==Vector2.ZERO and not hero.sprint_enabled)
	evidence.append({"case":"focus_loss_cancels_auto","passed":true})
	# Only two unhandled view fingers qualify; GUI pointers stay independent.
	hero.set_camera_distance(6.3)
	var yaw:float=hero._camera_pivot.rotation.y
	touch(Vector2(750,260),true,4);touch(Vector2(980,260),true,5)
	assert(hero._pinching and hero._camera_touches.size()==2)
	drag(Vector2(720,260),Vector2(-30,0),4);drag(Vector2(1010,260),Vector2(30,0),5)
	var close_goal:float=hero._camera_distance_target
	assert(close_goal<6.3 and hero._camera_arm.spring_length>close_goal,"Spread moves closer with a smoothed spring-length target")
	await wait(.25);assert(hero._camera_arm.spring_length<6.3 and absf(hero._camera_arm.spring_length-close_goal)<.2)
	assert(hero._camera_pivot.rotation.y==yaw,"A pinch must not orbit the camera")
	touch(Vector2(720,260),false,4);touch(Vector2(1010,260),false,5)
	assert(is_equal_approx(scene.camera_distance,close_goal))
	var settings:=ConfigFile.new();assert(settings.load(scene.SETTINGS_PATH)==OK and is_equal_approx(settings.get_value("settings","camera_distance"),close_goal))
	touch(Vector2(750,260),true,4);touch(Vector2(980,260),true,5)
	drag(Vector2(810,260),Vector2(60,0),4);drag(Vector2(850,260),Vector2(-130,0),5)
	assert(hero._camera_distance_target==9);touch(Vector2(810,260),false,4);touch(Vector2(850,260),false,5)
	touch(Vector2(750,260),true,4);touch(Vector2(980,260),true,5)
	drag(Vector2(550,260),Vector2(-200,0),4);drag(Vector2(1180,260),Vector2(200,0),5)
	assert(hero._camera_distance_target==4);touch(Vector2(550,260),false,4);touch(Vector2(1180,260),false,5)
	evidence.append({"case":"spread_closer_pinch_farther_smooth_bounds_and_persistence","passed":true,"min_distance":4,"max_distance":9})
	hero._attack_cooldown=0;hero.stamina=100;hero.set_camera_distance(6.3)
	touch(center,true,0);drag(center+Vector2(30,0),Vector2(30,0),0)
	touch(Vector2(750,260),true,8);touch(Vector2(980,260),true,9)
	var attack:Button=scene.mobile_hud.control("AttackButton");attack.tap_requested.connect(func():taps+=1)
	touch(attack.get_global_rect().get_center(),true,7);touch(attack.get_global_rect().get_center(),false,7)
	assert(taps==1 and hero._touch_move.x>.1 and hero._camera_touches.size()==2 and not hero._camera_touches.has(0) and not hero._camera_touches.has(7))
	var before:float=hero._camera_distance_target;drag(center+Vector2(45,0),Vector2(15,0),0);assert(hero._camera_distance_target==before)
	drag(Vector2(1020,260),Vector2(40,0),9);assert(hero._camera_distance_target<=before)
	touch(center,false,0);touch(Vector2(750,260),false,8);touch(Vector2(1020,260),false,9)
	evidence.append({"case":"four_pointer_joystick_pinch_and_sword","passed":true,"attack_taps":taps})
	touch(Vector2(750,260),true,4);touch(Vector2(980,260),true,5);scene._pause_game()
	assert(hero._camera_touches.is_empty() and not hero._pinching and hero._touch_move==Vector2.ZERO)
	scene._resume();yaw=hero._camera_pivot.rotation.y;drag(Vector2(1000,260),Vector2(20,0),5);assert(hero._camera_pivot.rotation.y==yaw)
	evidence.append({"case":"pause_cancels_camera_and_stale_drags","passed":true})
	hero.position=Vector3(76,1.58,0);hero._camera_pivot.global_position=hero.position+Vector3.UP*1.2
	var cameras:=[]
	for distance in [4.,6.3,9.]:
		hero.set_camera_distance(distance);hero._camera_pivot.rotation=Vector3(-.12,PI,0)
		for frame in range(15):await physics_frame
		var camera:Camera3D=hero._camera_arm.get_child(0);var q:=PhysicsShapeQueryParameters3D.new();var sphere:=SphereShape3D.new();sphere.radius=.12;q.shape=sphere;q.transform.origin=camera.global_position;q.collision_mask=4|8
		assert(scene.get_world_3d().direct_space_state.intersect_shape(q).is_empty());cameras.append({"distance_setting":distance,"camera":camera.global_position,"clear":true})
	var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	FileAccess.open(out+"/gesture_results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"platform":"automated real Godot touch dispatch; not physical Android","cases":evidence,"cave_camera_collision":cameras},"  "))
	print("PASS: deliberate upward sprint, auto/cancellation/stamina, pinch bounds/smoothing/save, four-pointer combat isolation and spring-arm collision")
	scene.queue_free();paused=false;await process_frame;await create_timer(.25,true,false,true).timeout;quit()
