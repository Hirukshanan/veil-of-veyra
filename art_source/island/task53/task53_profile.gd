extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var output:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	var start:=Time.get_ticks_usec();var scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	var ready_ms:float=(Time.get_ticks_usec()-start)/1000.0
	scene._resume();scene.player.set_physics_process(false);scene.player.health=10000;scene.player._invulnerability_time=1000
	Engine.max_fps=60;Engine.time_scale=1
	var rows:=[]
	for fixture in [["far_patrol",Vector3(0,0,27)],["boar_combat",scene.get_node("DemonBoar").position+Vector3.FORWARD*4.2]]:
		scene.player.position=scene.landscape.ground_point(fixture[1])+Vector3.UP*.08
		for frame in range(120):await physics_frame
		var times:Array[float]=[];var active:=0.0;var pairs:=0.0
		for frame in range(600):
			await physics_frame;times.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
			active+=Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS);pairs+=Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS)
		times.sort();rows.append({"case":fixture[0],"physics_median_ms":times[300],"physics_p95_ms":times[570],"active_physics_objects_mean":active/600,"collision_pairs_mean":pairs/600,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})
	var nav=scene.get_node_or_null("CandidateEnemyNavigation")
	var data:={"platform":OS.get_name(),"renderer":"headless physics-only observation; not Android and not a rendering FPS test","warmup_physics_ticks":120,"sample_physics_ticks":600,"physics_rate":60,"placement_ready_ms":ready_ms,"nav_build_ms":nav.build_ms if nav!=null else 0,"nav_nodes":nav.graph.get_point_count() if nav!=null else 0,"rows":rows}
	FileAccess.open(output+"/physics_profile.json",FileAccess.WRITE).store_string(JSON.stringify(data,"  "))
	print("PASS: local physics cost observation saved; no Android performance claim")
	scene.queue_free();paused=false;await process_frame;await create_timer(.25,true,false,true).timeout;quit()
