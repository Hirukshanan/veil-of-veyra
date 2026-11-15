extends SceneTree
var scene
var out:String
func _initialize():call_deferred("run")
func touch(point:Vector2,pressed:bool,index:int):
	var event:=InputEventScreenTouch.new();event.index=index;event.position=point;event.pressed=pressed;root.push_input(event)
func drag(point:Vector2,index:int):
	var event:=InputEventScreenDrag.new();event.index=index;event.position=point;root.push_input(event)
func shot(name:String):
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(out+"/"+name+".png")==OK)
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true);DisplayServer.window_set_size(Vector2i(1280,720))
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.shadows_enabled=false;scene._apply_settings()
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	scene.player.set_physics_process(false)
	scene.player.position=scene.landscape.ground_point(Vector3(-30,0,20))+Vector3.UP*.08
	scene.player._camera_pivot.global_position=scene.player.position+Vector3.UP*1.2;scene.player._camera_pivot.rotation=Vector3(-.1,.3,0)
	for i in range(30):await process_frame
	var stick=get_first_node_in_group("movement_joysticks");var center:Vector2=stick.get_global_rect().get_center();var radius:float=stick.size.x*.34
	touch(center,true,0);drag(center+Vector2.UP*radius*1.45,0)
	await create_timer(.32,true,false,true).timeout
	assert(scene.player.sprint_enabled and not stick.auto_sprint);await shot("sprint_held")
	drag(center+Vector2.UP*radius*2.05,0)
	var deadline:=Time.get_ticks_msec()+6000
	while not stick.auto_sprint and Time.get_ticks_msec()<deadline:await process_frame
	print("AUTO capture raw=",stick._raw," hold=",stick._auto_hold," requested=",stick._requested," enabled=",scene.player.sprint_enabled)
	touch(center,false,0);assert(stick.auto_sprint);await shot("sprint_auto_released")
	touch(center,true,0);touch(center,false,0)
	touch(Vector2(650,250),true,2);touch(Vector2(850,250),true,3);drag(Vector2(1000,250),3)
	await create_timer(.4,true,false,true).timeout;touch(Vector2(650,250),false,2);touch(Vector2(1000,250),false,3)
	await shot("pinch_spread_closer")
	touch(Vector2(650,250),true,2);touch(Vector2(1000,250),true,3);drag(Vector2(760,250),3)
	await create_timer(.4,true,false,true).timeout;touch(Vector2(650,250),false,2);touch(Vector2(760,250),false,3)
	await shot("pinch_together_farther")
	print("PASS: actual Godot feedback captures from dispatched touch gestures; actors held, not a phone recording")
	scene.queue_free();paused=false;await process_frame;await create_timer(.25,true,false,true).timeout;quit()
