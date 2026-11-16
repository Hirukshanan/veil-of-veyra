extends SceneTree

var scene
var output:String
var frame_number := 0
var recording := true
var checks:Array[String] = []

func _initialize():
	call_deferred("run")

func frames(count:int):
	for index in range(count):
		await process_frame
		await RenderingServer.frame_post_draw
		if recording:
			assert(root.get_texture().get_image().save_png(output+"/frames/frame%04d.png"%frame_number)==OK)
			frame_number += 1

func shot(name:String):
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"/"+name+".png")==OK)
	print("SCREEN ",name)

func open_journal():
	scene._show_journal()
	scene.journal_view.mobile_prompts = true
	scene.journal_view.render()

func tap(caption:String):
	assert(is_instance_valid(scene.journal_view))
	for item in scene.journal_view.find_children("*","Button",true,false):
		if item.text==caption and item.is_visible_in_tree():
			assert(item.size.y>=48)
			var point:Vector2=item.get_global_rect().get_center()
			for down in [true,false]:
				var event := InputEventScreenTouch.new()
				event.position = point
				event.pressed = down
				event.index = 4
				root.push_input(event,true)
				await process_frame
			if is_instance_valid(scene.journal_view) and not scene.journal_view.mobile_prompts:
				scene.journal_view.mobile_prompts = true
				scene.journal_view.render()
			return
	assert(false,"Missing touch action "+caption)

func open_world():
	scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:
		await physics_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for actor in get_nodes_in_group("combat_enemies"):
		actor.set_physics_process(false)
	scene.shadows_enabled=false
	scene._apply_settings()

func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output+"/frames")
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size=Vector2i(1280,720)
	await open_world()
	await frames(10)
	open_journal()
	await frames(2)
	assert(scene.journal_view.unroll>0 and scene.journal_view.unroll<1)
	await shot("01_opening")
	await frames(20)
	assert(scene.journal_view.unroll==1)
	await shot("02_main_android")
	var copy := ""
	for item in scene.journal_view.find_children("*","Label",true,false):
		copy += item.text
	assert("Pick / Interact" in copy and not "COLLECT / E" in copy)
	assert(scene.journal_view.prompt_text("LIGHT / E")=="Interact")
	checks.append("Opening uses moving rollers and a clipped paper reveal; Android-style text uses existing Pick / Interact")
	await tap("Side")
	await frames(20)
	await shot("03_side_reward")
	await tap("Accept bounty")
	await frames(10)
	assert(scene.keeper.accepted and not scene.keeper.reported)
	await tap("Keeper's Relics")
	await frames(15)
	await tap("Track quest")
	await frames(15)
	assert(scene.tracked_quest=="relic")
	await shot("04_tracked_relic")
	await tap("Return to hunt")
	assert(paused and scene.journal_view.closing)
	await frames(2)
	await shot("05_closing")
	await frames(18)
	assert(not paused and not is_instance_valid(scene.journal_view))
	assert(scene.mobile_hud.chrome.quest_content().title=="KEEPER'S RELICS")
	await shot("06_tracked_hud")
	checks.append("Touch Main/Side navigation, bounty acceptance, selected relic tracking and closing animation update the HUD")
	# Use existing plant interactions to show an actually completed optional reward.
	for id in [8,9,10]:
		for herb in scene.herbs.plants.duplicate():
			if int(herb.get_meta("pickup_id"))==id:
				scene.player.position=herb.global_position
				scene._interact_world()
	assert(scene.world_data.grove_reward and scene.shards==25)
	open_journal()
	await frames(10)
	await tap("Completed")
	await frames(22)
	assert(scene.journal_view.selected=="grove")
	await shot("07_completed_stamp")
	await tap("Main")
	await frames(20)
	await shot("08_main_selected")
	await tap("Side")
	await frames(12)
	for id in [0,1]:
		scene.get_node("CampDemon%d"%id).take_damage(10000)
	scene.journal_view.render()
	await frames(12)
	await tap("Report bounty")
	await frames(15)
	assert(scene.keeper.reported and scene.shards==25)
	await shot("09_bounty_secured")
	checks.append("Existing grove collection pays 25 once and shows completion stamp; bounty report retains deferred payment")
	recording=false
	# Check a small safe landscape rectangle, including swipe on overflowing text.
	var safe = scene.menu_scroll.get_parent()
	safe.test_safe_rect=Rect2(34,12,732,360)
	safe.refresh()
	await frames(8)
	await tap("Keeper's Relics")
	await frames(8)
	var scroll = scene.journal_view.detail_scroll
	var point:Vector2=scroll.get_global_rect().get_center()
	var touch := InputEventScreenTouch.new()
	touch.index=3
	touch.position=point
	touch.pressed=true
	root.push_input(touch,true)
	for index in range(6):
		point.y-=10
		var drag := InputEventScreenDrag.new()
		drag.index=3
		drag.position=point
		drag.relative=Vector2(0,-10)
		root.push_input(drag,true)
		await process_frame
	touch.position=point
	touch.pressed=false
	root.push_input(touch,true)
	await frames(5)
	assert(scroll.scroll_vertical>0)
	assert(scene.journal_view.get_global_rect()==safe.get_global_rect())
	await shot("10_small_safe_area")
	scene._resume()
	await frames(12)
	assert(not paused)
	assert(scene._save_progress())
	scene.queue_free()
	await process_frame
	await create_timer(.75,true,false,true).timeout
	await open_world()
	assert(scene.tracked_quest=="relic" and scene.keeper.reported)
	assert(scene.world_data.grove_reward and scene.shards==25)
	open_journal()
	await frames(12)
	await shot("11_reload_persistence")
	checks.append("Safe-area swipe, tracking preference, bounty report and 25-shard grove reward survive reload")
	for resolution in [Vector2i(1600,720),Vector2i(800,450)]:
		root.size=resolution
		await frames(8)
		assert(scene.journal_view.get_global_rect()==scene.menu_scroll.get_parent().get_global_rect())
		await shot("layout_%dx%d"%[resolution.x,resolution.y])
	scene._toggle_journal()
	await frames(12)
	assert(not paused)
	open_journal()
	await frames(8)
	scene._toggle_pause()
	scene._toggle_pause()
	await frames(12)
	assert(not paused and not is_instance_valid(scene.journal_view))
	checks.append("Wide/compact landscapes and journal/pause shortcuts close safely through the matching animation")
	FileAccess.open(output+"/interaction_results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"checks":checks,"captured_frames":frame_number,"playback_fps":20,"platform":"Windows Godot Compatibility","mobile_prompt_simulation":true,"Android_device_measured":false,"actors_held_for_capture":true,"grove_collection_and_bounty_use_existing_APIs":true},"  "))
	scene.queue_free()
	paused=false
	await process_frame
	await create_timer(.75,true,false,true).timeout
	print("PASS: ornate opening/closing, touch selection, mobile prompts, tracking, rewards, swipe, safe areas and persistence")
	quit()
