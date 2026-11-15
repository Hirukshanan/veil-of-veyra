extends SceneTree
var rows:Array=[]
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var output:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	Engine.time_scale=4
	var scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	var boar=scene.get_node("DemonBoar");var hero=scene.player
	hero.position=scene.landscape.ground_point(boar.position+Vector3.FORWARD*4.2)+Vector3.UP*.08
	hero.health=10000;hero._invulnerability_time=1000;hero.set_physics_process(false)
	boar.set_physics_process(true)
	var previous:=-1;var charges:=0;var clock:=0.0
	for frame in range(1200):
		await physics_frame;clock+=1.0/15
		if boar.state!=previous or frame%60==0:
			var direction:Vector3=boar._flat(hero.position-boar.position).normalized()
			var row:={"time_s":clock,"state":boar.State.keys()[boar.state],"elapsed":boar._elapsed,"attack_delay":boar._attack_delay,"line_clear":boar._line_clear,"position":boar.position,"hero":hero.position,"steer":boar._steering,"cast_forward":boar._cast(-boar.global_basis.z*7.02),"facing_dot":(-boar.global_basis.z).dot(direction),"velocity":boar.velocity,"clip":boar._clip,"animation_position":boar.animator.current_animation_position}
			rows.append(row);print("BOAR_BASELINE ",JSON.stringify(row))
			if boar.state==boar.State.CHARGE and previous!=boar.state:charges+=1
			previous=boar.state
	FileAccess.open(output+"/baseline_boar_trace.json",FileAccess.WRITE).store_string(JSON.stringify({"charges":charges,"seconds":clock,"rows":rows},"  "))
	print("RESULT: baseline charges ",charges);scene.queue_free();paused=false;await process_frame;await create_timer(.25,true,false,true).timeout;quit()
