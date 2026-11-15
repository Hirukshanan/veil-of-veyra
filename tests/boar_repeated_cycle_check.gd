extends SceneTree
var scene
var boar
var hero
var output:String
var clock:=0.0
var label:=""
var transitions:Array=[]
var cases:Array=[]
var hits:Array=[]
var last_health:=10000
var warnings:=0
var charges:=0
var recoveries:=0
var completed:=0
func _initialize():call_deferred("run")
func tick(frames:int=1):
	for frame in frames:
		await physics_frame;clock+=1.0/15
		if hero.health<last_health:
			hits.append({"case":label,"time_s":clock,"state":boar.State.keys()[boar.state],"damage":last_health-hero.health})
		last_health=hero.health
func transition(previous:int,current:int):
	var row:={"case":label,"time_s":clock,"from":boar.State.keys()[previous],"to":boar.State.keys()[current],"position":boar.position,"hero":hero.position,"attack_delay":boar._attack_delay,"clip":boar._clip,"line_clear":boar._line_clear}
	transitions.append(row);print("AI_STATE ",JSON.stringify(row))
	if current==boar.State.WARNING:warnings+=1
	if current==boar.State.CHARGE:charges+=1
	if current==boar.State.RECOVERY:recoveries+=1
	if previous==boar.State.RECOVERY and current==boar.State.CHASE:completed+=1
func reset_case(name:String,origin:Vector3,use_navigation:bool=true):
	label=name;boar.set_physics_process(false);hero.set_physics_process(false)
	boar.position=scene.landscape.ground_point(origin)+Vector3.UP*.08;boar.velocity=Vector3.ZERO;boar.rotation=Vector3.ZERO;boar._home=boar.position
	boar.navigation=scene.enemy_navigation if use_navigation else null
	boar._attack_delay=0;boar._reposition_time=0;boar._sense_time=0;boar._steering=Vector3.ZERO
	hero.position=scene.landscape.ground_point(boar.position+Vector3.FORWARD*4.2)+Vector3.UP*.08;hero.velocity=Vector3.ZERO
	hero.health=10000;last_health=10000;hero._invulnerability_time=0;hero._charge_knockback=Vector3.ZERO
	hero.set_move_input(Vector2.ZERO);hero._camera_pivot.rotation=Vector3.ZERO
	boar._enter(boar.State.IDLE);warnings=0;charges=0;recoveries=0;completed=0
	await tick(2);boar.set_physics_process(true)
func until_state(state:int,frames:int=450):
	for frame in frames:
		if boar.state==state:return true
		await tick()
	return false
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	Engine.time_scale=4;scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	boar=scene.get_node("DemonBoar");hero=scene.player;boar.state_changed.connect(transition)
	for fixture in [["new_border_spawn",Vector3(-36,0,12),true],["hillside_charge_cycle",Vector3(-40,0,-28),true]]:
		await reset_case(fixture[0],fixture[1],fixture[2]);var start:=clock
		for frame in range(1350):
			if completed>=5:break
			await tick()
		cases.append({"case":label,"five_completed_cycles":completed,"warnings":warnings,"charges":charges,"recoveries":recoveries,"elapsed_s":clock-start,"hero_health":hero.health,"boar_health":boar.health})
		FileAccess.open(output+"/cycle_progress.json",FileAccess.WRITE).store_string(JSON.stringify(cases,"  "))
		assert(completed>=5 and warnings>=5 and charges>=5 and hero.health>0,"Five uninterrupted cycles must complete without forcing AI transitions or relocating either actor")
	# Normal hero health and actual dodge/movement; no test invulnerability here.
	await reset_case("three_real_dodges",Vector3(-36,0,12));hero.health=100;last_health=100;hero._invulnerability_time=0;hero.set_physics_process(true)
	var dodges:=0;var dodged_warning:=-1;var move_until:=0.0
	for frame in range(1200):
		if completed>=3:break
		if boar.state==boar.State.WARNING and boar._elapsed>.9 and dodged_warning!=warnings:
			dodged_warning=warnings
			var side:Vector3=boar._charge_direction.cross(Vector3.UP).normalized()
			hero._camera_pivot.rotation.y=0;hero.set_move_input(Vector2(side.x,side.z));hero.dodge();move_until=clock+.5;dodges+=1
		if clock>move_until:hero.set_move_input(Vector2.ZERO)
		await tick()
	cases.append({"case":label,"completed":completed,"real_dodges":dodges,"health":hero.health})
	assert(completed>=3 and dodges>=3 and hero.health==100,"Existing dodge plus movement must avoid repeated fully telegraphed charges")
	hero.set_physics_process(false)
	# Player runs away while remaining inside the encounter leash.
	await reset_case("moving_target_pursuit",Vector3(-36,0,12));assert(await until_state(boar.State.CHASE))
	hero.position=scene.landscape.ground_point(Vector3(-27,0,12))+Vector3.UP*.08
	var first_distance:float=boar.position.distance_to(hero.position)
	await tick(60)
	var last_distance:float=boar.position.distance_to(hero.position)
	cases.append({"case":label,"start_distance":first_distance,"after_4s_distance":last_distance,"state":boar.State.keys()[boar.state]})
	assert(last_distance<first_distance-2,"Boar must resume pursuing a player who changes position")
	# Static obstacle inserted after the warning has committed the attack lane.
	await reset_case("interrupted_charge",Vector3(-36,0,12));assert(await until_state(boar.State.WARNING))
	var wall:=StaticBody3D.new();wall.collision_layer=1|4|8;wall.collision_mask=0
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(3.0,2.8,.35);shape.shape=box;wall.add_child(shape)
	wall.position=boar.position+boar._charge_direction*2.6+Vector3.UP*1.1;wall.rotation.y=boar.rotation.y;scene.add_child(wall)
	var contact_start:int=hero.health;assert(await until_state(boar.State.CHARGE));assert(await until_state(boar.State.RECOVERY))
	var stopped:Vector3=boar.position
	assert(hero.health==contact_start,"Obstacle must block a charge and any tusk damage")
	wall.queue_free();await tick(2);assert(await until_state(boar.State.CHASE))
	assert(await until_state(boar.State.CHARGE),"Interrupted charge must recover and charge again after the path is clear")
	cases.append({"case":label,"stopped_position":stopped,"next_charge":true,"health_preserved":hero.health==contact_start})
	# Leave sensing/leash range, then return to normal patrol without teleporting boar.
	label="escape_return_patrol";hero.position=Vector3(20,2,60)
	assert(await until_state(boar.State.RETURN));var return_start:Vector3=boar.position
	assert(await until_state(boar.State.IDLE,900),"Escaped target must let boar return naturally to its home")
	assert(await until_state(boar.State.PATROL,120))
	cases.append({"case":label,"return_start":return_start,"home":boar._home,"end":boar.position,"returned_to_patrol":true})
	await reset_case("target_death_stops_attack",Vector3(-36,0,12));assert(await until_state(boar.State.WARNING));var old_charges:=charges
	hero.health=0;last_health=0;await tick(80)
	assert(charges==old_charges and not boar._warning.visible and boar.state in [boar.State.RETURN,boar.State.IDLE,boar.State.PATROL])
	cases.append({"case":label,"extra_charges":charges-old_charges,"state":boar.State.keys()[boar.state]})
	await reset_case("boar_death_stops_attack",Vector3(-36,0,12));assert(await until_state(boar.State.WARNING));old_charges=charges
	boar.take_damage(1000);await tick(90)
	assert(boar.state==boar.State.DEAD and charges==old_charges and not boar._warning.visible)
	cases.append({"case":label,"extra_charges":charges-old_charges,"reward_shards":scene.shards,"dead":true})
	for hit in hits:assert(hit.state=="CHARGE" and hit.damage==18,"Damage only once per valid charge contact at the unchanged 18 damage")
	var start_clock:=0.0;var duration_checks:=[]
	for row in transitions:
		if row.to=="WARNING":start_clock=row.time_s
		if row.from=="WARNING" and row.to=="CHARGE":
			assert(row.time_s-start_clock>=1.7);duration_checks.append(row.time_s-start_clock)
	var file:=FileAccess.open(output+"/boar_cycle_results.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":true,"platform":"automated Godot controller tests; not Android","cases":cases,"damage_events":hits,"warning_durations_s":duration_checks,"transitions":transitions},"  "))
	print("PASS: 5 consecutive cycles at border and hillside, three real dodges, pursuit, interrupted charge recovery, return, target/boar death and valid damage windows")
	scene.queue_free();paused=false;await process_frame;await create_timer(.25,true,false,true).timeout;quit()
