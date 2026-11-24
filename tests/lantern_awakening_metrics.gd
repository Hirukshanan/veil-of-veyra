extends SceneTree
const STORE=preload("res://scripts/campaign_store.gd")
var scene
var rows:Array=[]
var probe:Camera3D

func _initialize():call_deferred("run")

func sample(label:String,frames:int):
	var intervals:Array=[];var draws:Array=[];var triangles:Array=[];var cpus:Array=[];var gpus:Array=[]
	var spikes:Array=[]
	var previous:=Time.get_ticks_usec()
	for index in range(frames):
		await process_frame
		var now:=Time.get_ticks_usec();intervals.append((now-previous)/1000.0);previous=now
		if intervals[-1]>100 and scene.get("awakening")!=null:
			spikes.append({"ms":intervals[-1],"stage":scene.awakening.stage,"event_clock":scene.awakening.clock})
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		triangles.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		cpus.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
		gpus.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
	intervals.sort();cpus.sort();gpus.sort()
	rows.append({"name":label,"frames":frames,"median_frame_ms":intervals[frames/2],"p95_frame_ms":intervals[int(frames*.95)],"max_frame_ms":intervals[-1],"draw_calls_mean":draws.reduce(func(a,b):return a+b,0.0)/frames,"submitted_primitives_mean":triangles.reduce(func(a,b):return a+b,0.0)/frames,"render_cpu_ms_median":cpus[frames/2],"gpu_ms_median":gpus[frames/2],"engine_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"spikes":spikes})

func inspection():
	probe.make_current()
	probe.position=Vector3(66,4.5,26);probe.look_at(Vector3(67,5.1,32))
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()

func run():
	var output:String=OS.get_cmdline_user_args()[0]
	var baseline:bool=OS.get_cmdline_user_args()[1]=="baseline"
	var data:=STORE.DEFAULTS.duplicate(true);data.world_data=STORE.fresh_world()
	data.completed=true;data.shards=80
	data.world_data.merge({"cleared":[0,1,2,3,4,5],"seal_fragments":[0,1,2],"lantern":true,"position":Vector3(62.5,2.4,23)},true)
	assert(STORE.save_progress(data)==OK)
	root.size=Vector2i(1280,720);root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.frame_limit=30;scene.shadows_enabled=false;scene._apply_settings()
	scene.player.set_physics_process(false)
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	probe=Camera3D.new();probe.near=.08;probe.fov=58;scene.add_child(probe)
	var environment:=Environment.new();environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color.BLACK;environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color(.72,.65,.54);environment.ambient_light_energy=.8
	probe.environment=null
	inspection()
	for frame in range(60):await process_frame
	await sample("baseline_cave" if baseline else "sealed_cave",90)
	if not baseline:
		scene.player._camera_arm.get_child(0).make_current()
		assert(scene.awakening.start())
		await sample("live_cinematic",540)
		while scene.awakening.active:await process_frame
		inspection()
		for frame in range(40):await process_frame
		await sample("opened_cave",90)
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"platform":"Windows Intel Iris Xe / Godot Compatibility","configuration":"1280x720, native HUD, 720-high 3D, shadows off, 30 FPS cap, actors held; live timing, no movie writer","Android_measured":false,"rows":rows},"  "))
	scene.queue_free();paused=false
	await process_frame;await create_timer(1.0,true,false,true).timeout
	quit()
