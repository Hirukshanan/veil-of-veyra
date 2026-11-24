extends SceneTree
var scene
var output:String
var number:=0
func _initialize():call_deferred("run")
func frames(count:int):
	for i in range(count):
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/frame%03d.png"%number)
		number+=1
func tap(caption:String):
	for b in scene.journal_view.find_children("*","Button",true,false):
		if b.text==caption:
			var point:Vector2=b.get_global_rect().get_center()
			for down in [true,false]:
				var e:=InputEventScreenTouch.new()
				e.index=0
				e.position=point
				e.pressed=down
				root.push_input(e,true)
				await process_frame
			return
	assert(false,"Button missing "+caption)
func run():
	output=OS.get_cmdline_user_args()[0]
	root.size=Vector2i(1280,720)
	scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	scene._show_journal()
	await frames(12)
	root.get_texture().get_image().save_png(output+"/after.png")
	await tap("Side")
	await frames(8)
	assert(scene.journal_view.section=="Side")
	await tap("Accept bounty")
	await frames(6)
	assert(scene.keeper.accepted)
	await tap("Moonleaf Grove")
	await frames(6)
	await tap("Track quest")
	assert(scene.tracked_quest=="grove")
	await frames(8)
	await tap("Completed")
	await frames(8)
	await tap("Return to hunt")
	await frames(8)
	assert(not paused and scene.tracked_hint({}).get("title","")=="MOONLEAF GROVE")
	scene._show_journal()
	var safe=scene.menu_scroll.get_parent()
	safe.test_safe_rect=Rect2(40,16,740,308)
	safe.refresh()
	await process_frame
	await process_frame
	var scroll=scene.journal_view.find_child("*",true,false)
	for sc in scene.journal_view.find_children("*","ScrollContainer",true,false): scroll=sc
	var point:Vector2=scroll.get_global_rect().get_center()
	var touch:=InputEventScreenTouch.new()
	touch.position=point
	touch.pressed=true
	root.push_input(touch,true)
	for step in range(5):
		var drag:=InputEventScreenDrag.new()
		point.y-=12
		drag.position=point
		drag.relative=Vector2(0,-12)
		root.push_input(drag,true)
		await process_frame
	touch.position=point
	touch.pressed=false
	root.push_input(touch,true)
	await process_frame
	assert(scroll.scroll_vertical>0,"Finger swipe must scroll the quest details")
	assert(scene.journal_view.get_global_rect()==safe.get_global_rect())
	scene._resume()
	scene.queue_free()
	await process_frame
	scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	assert(scene.tracked_quest=="grove" and scene.keeper.accepted)
	print("PASS: swipe, safe area, tracking and bounty survive reload")
	print("PASS: touch tabs, acceptance, selection, tracking, completed page and return to gameplay")
	scene.queue_free()
	await process_frame
	await create_timer(.75,true,false,true).timeout
	quit()
