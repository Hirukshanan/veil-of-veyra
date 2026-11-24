extends SceneTree
const STORE=preload("res://scripts/campaign_store.gd")
var scene
var rows:Array=[]
var previous:=0
var phase:="startup"
var sequence:=""
var output:=""
var saved_frames:=0
var clock_start:=0
var render_begin:=0
var render_us:=0
func pre_draw():render_begin=Time.get_ticks_usec()
func post_draw():render_us=Time.get_ticks_usec()-render_begin
func _initialize():call_deferred("run")
func frame():
	var now:=Time.get_ticks_usec()
	if previous>0:
		rows.append({"ms":(now-previous)/1000.0,"render_wall_ms":render_us/1000.0,"frame":Engine.get_process_frames(),"phase":phase,"stage":scene.awakening.stage if scene!=null and scene.awakening!=null else "loading","clock":scene.awakening.clock if scene!=null and scene.awakening!=null else 0,"music_seconds":scene.awakening.music.get_playback_position() if scene!=null and scene.awakening!=null and scene.awakening.active and scene.awakening.music.playing else -1,"audio_since_mix":AudioServer.get_time_since_last_mix(),"cpu_ms":RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()),"gpu_ms":RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()),"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"compilations_draw":Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW),"compilations_specialization":Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION)})
	previous=now
func wait_seconds(seconds:float):
	var end:=Time.get_ticks_usec()+int(seconds*1000000)
	while Time.get_ticks_usec()<end:await process_frame
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0];sequence=OS.get_cmdline_user_args()[1]
	root.size=Vector2i(1280,720)
	var data:=STORE.DEFAULTS.duplicate(true);data.world_data=STORE.fresh_world()
	data.completed=true;data.shards=80
	data.world_data.merge({"cleared":[0,1,2,3,4,5],"seal_fragments":[0,1,2],"lantern":true,"position":Vector3(62.5,2.4,23)},true)
	assert(STORE.save_progress(data)==OK)
	var settings:=ConfigFile.new()
	settings.set_value("settings","shadows_enabled",false)
	settings.set_value("settings","frame_limit",30)
	assert(settings.save("user://settings.cfg")==OK)
	var loading:=Time.get_ticks_usec()
	previous=loading
	RenderingServer.frame_pre_draw.connect(pre_draw)
	RenderingServer.frame_post_draw.connect(post_draw)
	process_frame.connect(frame)
	scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	var init_ms:=(Time.get_ticks_usec()-loading)/1000.0
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.frame_limit=30 if "cap30" in sequence else 0;scene.shadows_enabled=false;scene._apply_settings()
	Engine.max_fps=scene.frame_limit
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	scene.player.set_physics_process(false)
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	phase="settle"
	for initial_frame in range(60):await process_frame
	await wait_seconds(2)
	var preparation:Array=scene.awakening.get("preparation_steps") if scene.awakening.get("preparation_steps")!=null else []
	phase="start";clock_start=Time.get_ticks_usec()
	scene._resume() # A focus change during settling must not invalidate this controlled test.
	assert(scene.awakening.start())
	phase="cinematic"
	while scene.awakening.active:await process_frame
	var event_end:=Time.get_ticks_usec()
	phase="after";await wait_seconds(1)
	process_frame.disconnect(frame)
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"mode":sequence,"fps_cap":Engine.max_fps,"controller_sha256":FileAccess.get_sha256("res://scripts/lantern_awakening.gd"),"configuration":"1280x720; approved 720-high 3D/native HUD; shadows off from scene creation; VSYNC disabled; cap recorded separately; no movie writer","initialization_ms":init_ms,"preparation":preparation,"event_wall_ms":(event_end-clock_start)/1000.0,"frames":rows,"operations":scene.awakening.get("trace") if scene.awakening.get("trace")!=null else [],"events":scene.awakening.events,"headless":DisplayServer.get_name()=="headless","Android_measured":false},"  "))
	scene.queue_free();paused=false;await process_frame
	await create_timer(.5,true,false,true).timeout
	quit()
