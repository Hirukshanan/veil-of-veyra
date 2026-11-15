extends SceneTree
var scene
func _initialize():call_deferred("run")
func touch(at:Vector2,pressed:bool,index:int):
	var event:=InputEventScreenTouch.new();event.position=at;event.pressed=pressed;event.index=index;root.push_input(event)
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	root.content_scale_size=Vector2i.ZERO;root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(1280,720)
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.player.set_physics_process(false)
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	var rows:=[]
	for mode in ["camera_drag","joystick_drag","pinch_drag"]:
		if mode=="pinch_drag" and scene.player.get("_camera_touches")==null:continue
		var start:Vector2=Vector2(900,260) if mode!="joystick_drag" else get_first_node_in_group("movement_joysticks").get_global_rect().get_center()
		var samples:Array[float]=[]
		for trial in range(5):
			touch(start,true,1)
			if mode=="pinch_drag":touch(Vector2(650,260),true,2)
			var event:=InputEventScreenDrag.new();event.index=1
			for i in range(100):event.position=start+Vector2(i%2,0);event.relative=Vector2(1 if i%2 else -1,0);root.push_input(event)
			var begin:=Time.get_ticks_usec()
			for i in range(5000):
				event.position=start+Vector2(i%2,0);event.relative=Vector2(1 if i%2 else -1,0);root.push_input(event)
			samples.append(float(Time.get_ticks_usec()-begin)/5000.0)
			touch(start,false,1)
			if mode=="pinch_drag":touch(Vector2(650,260),false,2)
			await process_frame
		samples.sort();rows.append({"mode":mode,"median_cpu_us_per_event":samples[2],"five_trial_us_per_event":samples})
	var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	FileAccess.open(out+"/input_cost.json",FileAccess.WRITE).store_string(JSON.stringify({"platform":OS.get_name(),"method":"Synthetic burst through actual Viewport.push_input. Five trials of5000 drag events after100 warmup events. Actors held; measures dispatch CPU microseconds/event, not touch-to-photon latency, Android input cost or gameplay FPS.","rows":rows},"  "))
	print("PASS: local input-dispatch cost observed; not Android latency")
	scene.queue_free();paused=false;await process_frame;await create_timer(.25,true,false,true).timeout;quit()
