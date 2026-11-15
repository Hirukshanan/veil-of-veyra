extends SceneTree

func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	scene.player.set_physics_process(false)
	Engine.max_fps=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var rows:=[]
	for position in [Vector3(0,0,27),Vector3(-64,0,12),Vector3(26,0,-48),Vector3(68,0,-38)]:
		scene.player.position=scene.landscape.safe_point(position)
		scene.player._camera_pivot.global_position=scene.player.position+Vector3.UP*1.2
		scene.player._camera_pivot.rotation=Vector3(-.12,PI if position.x>60 else 0.0,0)
		for frame in range(20):await process_frame
		var times:Array[float]=[]
		var previous:=Time.get_ticks_usec()
		for frame in range(120):
			await process_frame
			var now:=Time.get_ticks_usec()
			times.append((now-previous)/1000.0)
			previous=now
		times.sort()
		var total:=0.0
		for time in times:total+=time
		rows.append({"position":scene.player.position,"average_fps":120000.0/total,"median_frame_ms":times[60],"p95_frame_ms":times[114],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	var result:={"renderer":"GL Compatibility","resolution":root.size,"scope":"Uncapped native desktop environment review, no Movie Maker; enemies held static for repeatability. Not Android or full-combat FPS acceptance.","views":rows,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}
	var file:=FileAccess.open("res://.validation/island_2026-11-15/performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "))
	print("PASS: native desktop environment measurements saved")
	scene.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	await create_timer(0.3).timeout
	quit()
