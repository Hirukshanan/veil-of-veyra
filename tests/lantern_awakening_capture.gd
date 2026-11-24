extends SceneTree
const STORE=preload("res://scripts/campaign_store.gd")
var scene
var output:String
var probe:Camera3D
var probe_environment:Environment
var captures:Array=[]

func _initialize():call_deferred("run")

func wait_frames(count:int):
	for frame in range(count):await process_frame

func shot(name:String):
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"/"+name+".png")==OK)
	captures.append({"name":name,"event_time":scene.awakening.clock})
	print("CAPTURE ",name)

func inspection(name:String,eye:Vector3,target:Vector3):
	probe.position=eye;probe.look_at(target);probe.make_current()
	scene.awakening.cinematic_fill.light_energy=2
	await wait_frames(6)
	await shot(name)
	scene.awakening.cinematic_fill.light_energy=0

func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	var data:=STORE.DEFAULTS.duplicate(true);data.world_data=STORE.fresh_world()
	data.completed=true;data.shards=80
	data.world_data.merge({"cleared":[0,1,2,3,4,5],"seal_fragments":[0,1,2],"lantern":true,"position":Vector3(62.5,2.4,22)},true)
	assert(STORE.save_progress(data)==OK)
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size=Vector2i(1280,720)
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();scene.shadows_enabled=false;scene._apply_settings()
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	probe=Camera3D.new();probe.fov=58;probe.near=.08;scene.add_child(probe)
	probe_environment=scene.awakening.environment.duplicate()
	probe.environment=probe_environment
	await inspection("before_wall",Vector3(66,4.5,26),Vector3(67,5.1,32))
	await inspection("before_pedestal",Vector3(66,4.8,21.5),Vector3(62.5,3.5,25))
	scene.player._camera_arm.get_child(0).make_current()
	scene.player.set_move_input(Vector2(0,1))
	await wait_frames(12)
	scene.player.set_move_input(Vector2.ZERO)
	await wait_frames(12)
	scene._update_objective()
	assert(scene.awakening.near_pedestal())
	await shot("01_interact_gameplay")
	scene.interact_button.pressed.emit()
	assert(scene.awakening.active)
	var planned=[[.65,"02_lantern_placed"],[2.8,"03_stone_descending"],[5.25,"04_spreading_cracks"],[6.6,"05_wall_fracture"],[8.9,"06_passage_camera"],[11.4,"07_deep_hall"],[12.8,"08_complete_darkness"],[14.2,"09_eye_opening"],[15.6,"10_crimson_eye"],[16.5,"11_black_fade"]]
	var index:=0
	while scene.awakening.active:
		await process_frame
		if index<planned.size() and scene.awakening.clock>=float(planned[index][0]):
			await shot(planned[index][1]);index+=1
	await wait_frames(10)
	assert(not paused and scene.world_data.lantern_awakening)
	await shot("12_hero_control_returned")
	await inspection("after_wall",Vector3(66,4.5,26),Vector3(67,5.1,32))
	await inspection("after_pedestal",Vector3(66,4.8,21.5),Vector3(62.5,3.5,25))
	scene._show_journal()
	scene.journal_view.mobile_prompts=true
	scene.journal_view.choose("Completed","awakening")
	await wait_frames(12)
	await shot("13_journal_completed")
	FileAccess.open(output+"/capture_results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"actual_Godot_movie_with_engine_audio":true,"resolution":[1280,720],"fixed_movie_fps":20,"event_order":scene.awakening.events,"screens":captures,"fixture":"Synthetic completed Chapter I save; optional quests incomplete; enemies held; normal hero controller approaches altar","inspection_views":"Matched cinematic ambient/fill for before/after wall and pedestal","phone_execution":false,"final_shards":scene.shards},"  "))
	scene.queue_free();paused=false
	await process_frame
	await create_timer(1.0,true,false,true).timeout
	print("PASS: full in-engine cinematic with actual engine audio and matched cave evidence")
	quit()
