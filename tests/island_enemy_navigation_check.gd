extends SceneTree
var scene
var rows:Array=[]
var output:String
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume();Engine.time_scale=4
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	scene.player.set_physics_process(false);scene.player.health=10000
	var navigation=scene.enemy_navigation;var landscape=scene.landscape
	var expected:={"CampDemon0":0,"CampDemon1":1,"CampDemon2":2,"CampDemon3":0,"CampDemon4":1}
	var fox = scene.get_node("DemonFox")
	assert(scene.remaining_enemies==5 and get_nodes_in_group("combat_enemies").size()==7 and scene.get_node_or_null("CampDemon5")==null)
	assert(fox.navigation == navigation and fox.target == scene.player and fox.health == 19)
	var warg: Node3D = scene.get_node("CampDemon2")
	var grassland_wolf: Node3D = scene.get_node("CampDemon3")
	var boar = scene.get_node("DemonBoar")
	assert(warg.position.x > 30 and warg.position.z < -40 and grassland_wolf.position.x > 20 and grassland_wolf.position.z > 30)
	assert(fox.position.x > 40 and fox.position.z > -30 and boar.position.x > -25 and boar.position.z < -25)
	assert(scene.get_node("CampDemon4").position.x < -55 and scene.get_node("CampDemon4").position.z > 20)
	var residents := get_nodes_in_group("combat_enemies")
	for i in range(residents.size()):
		for j in range(i + 1, residents.size()):
			var first: Node3D = residents[i]
			var second: Node3D = residents[j]
			var offset := first.position - second.position
			assert(Vector2(offset.x, offset.z).length() > _alert_radius(first) + _alert_radius(second),
				"Encounter spawn detection zones overlap: %s and %s" % [first.name, second.name])
	var fox_spawn: Vector3 = fox.position
	var support: Vector3 = landscape.ground_point(fox_spawn)
	assert(absf(fox_spawn.y - support.y) <= .04 and fox_spawn.z < -12.0)
	for actor in residents:
		var ground: Dictionary = landscape.ground_hit(actor.global_position)
		assert(not ground.is_empty() and ground.normal.y > .86 and ground.position.y > .25)
		var collider := actor.find_children("*", "CollisionShape3D", false, false)[0] as CollisionShape3D
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collider.shape
		query.transform = collider.global_transform.translated(Vector3.UP * .04)
		query.collision_mask = 4 | 8
		assert(scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),
			"Encounter has an overlapping body at spawn: " + str(actor.name))
	var spawn_rows:=[]
	for row in scene.encounter_log:
		var actor=scene.get_node(row.id)
		var separation: Vector3 = actor.position - fox_spawn
		assert(Vector2(separation.x, separation.z).length() > 20.0, "Fox should start outside the wolf and boar encounter areas")
		if expected.has(row.id):
			assert(actor.kind==expected[row.id] and actor.health==[18,17,21][actor.kind])
			assert(actor.attack_damage==[8,5,16][actor.kind])
		else:assert(actor.health==24 and actor.REWARD_SHARDS==20)
		spawn_rows.append({"id":row.id,"position":actor.position,"shape_clear":true,"health":actor.health,"display_name":actor.display_name if "display_name" in actor else "DEMON BOAR"})
	# A full stopped pose and charge path must have room at the boar's new border.
	var clear_lanes:=0
	for index in range(12):
		boar.rotation.y=index*TAU/12
		if boar._cast(-boar.global_basis.z*7.02)>.98:clear_lanes+=1
	assert(clear_lanes>=8,"The border encounter must have several unobstructed charging directions")
	boar.rotation=Vector3.ZERO
	# Graph is derived from actual terrain/collision, with no collider or scenery edits.
	assert(navigation.graph.get_point_count()>800 and navigation.graph.get_point_count()<2700)
	for actor in residents:
		var original: Vector3 = actor.position
		var target:Vector3=original+Vector3(4,0,3)
		var end_id:int=navigation.graph.get_closest_point(target);var start_id:int=navigation.graph.get_closest_point(original)
		assert(navigation.graph.get_point_position(start_id).distance_to(original) < 3.0)
		assert(navigation.graph.get_id_path(start_id,end_id).size()>1,"Encounter needs a connected local pursuit route: " + str(actor.name))
		rows.append({"case":"spawn_local_path","actor":actor.name,"points":navigation.graph.get_id_path(start_id,end_id).size()})
	# Real wolf controller follows an A* detour around an existing mature tree.
	var trunks:Node3D=landscape.get_node("MatureTreeTrunks")
	var selected:CollisionShape3D
	for child in trunks.get_children():
		var center:Vector3=child.position
		var a:Vector3=landscape.ground_point(center+Vector3.RIGHT*3)+Vector3.UP*.08
		var b:Vector3=landscape.ground_point(center-Vector3.RIGHT*4)+Vector3.UP*.08
		var first:int=navigation.graph.get_closest_point(a);var last:int=navigation.graph.get_closest_point(b)
		if navigation.graph.get_point_position(first).distance_to(a)<1.6 and navigation.graph.get_point_position(last).distance_to(b)<1.6 and navigation.graph.get_id_path(first,last).size()>=4:selected=child;break
	assert(selected!=null)
	var center:Vector3=selected.position;var wolf=scene.get_node("CampDemon0")
	wolf.position=landscape.ground_point(center+Vector3.RIGHT*3)+Vector3.UP*.08;wolf._home=wolf.position;wolf._patrol_goal=wolf.position;wolf.velocity=Vector3.ZERO
	scene.player.position=landscape.ground_point(center-Vector3.RIGHT*4)+Vector3.UP*.08
	var contacts:=0;var min_distance:=INF;var path_trace:=[]
	wolf.set_physics_process(true)
	for frame in range(360):
		await physics_frame
		var distance:float=Vector2(wolf.position.x-center.x,wolf.position.z-center.z).length();min_distance=minf(min_distance,distance)
		for i in wolf.get_slide_collision_count():
			if absf(wolf.get_slide_collision(i).get_normal().y)<.5:contacts+=1
		if frame%15==0:path_trace.append(wolf.position)
		if wolf.position.x<center.x-1.4:break
	FileAccess.open(output+"/tree_detour_diagnostic.json",FileAccess.WRITE).store_string(JSON.stringify({"center":center,"wolf":wolf.position,"hero":scene.player.position,"nav_direction":navigation.direction(wolf,scene.player.position),"contacts":contacts,"path":path_trace},"  "))
	assert(wolf.position.x<center.x-1.4,"Existing wolf chase must route around the tree rather than stay pinned at its trunk")
	assert(min_distance>selected.shape.radius+.3,"Physical wolf body may not clip through the trunk")
	rows.append({"case":"real_wolf_tree_detour","center":center,"end":wolf.position,"min_trunk_distance_m":min_distance,"contacts":contacts,"path":path_trace})
	wolf.set_physics_process(false)
	# Existing boar also navigates a static tree obstruction during chase.
	boar.position=landscape.ground_point(center+Vector3.RIGHT*4)+Vector3.UP*.08;boar.velocity=Vector3.ZERO;boar._home=boar.position
	boar._attack_delay=60;boar._sense_time=0;boar._enter(boar.State.CHASE);boar.set_physics_process(true)
	for frame in range(450):
		await physics_frame
		if boar.position.x<center.x-1.4:break
	assert(boar.position.x<center.x-1.4,"Boar must reposition around the solid tree without a permanent blocked state")
	rows.append({"case":"real_boar_tree_detour","center":center,"end":boar.position})
	boar.set_physics_process(false)
	# The Fox uses the same graph and a smaller real capsule when it returns home.
	fox.position = landscape.ground_point(center + Vector3.RIGHT * 4) + Vector3.UP * .08
	fox.velocity = Vector3.ZERO
	fox._home = landscape.ground_point(center - Vector3.RIGHT * 4) + Vector3.UP * .08
	fox._enter(fox.State.RETURN)
	scene.player.position = landscape.ground_point(center - Vector3.RIGHT * 15)
	fox.set_physics_process(true)
	var closest := INF
	for frame in range(260):
		await physics_frame
		closest = minf(closest, Vector2(fox.position.x - center.x, fox.position.z - center.z).length())
		if fox.state == fox.State.IDLE:
			break
	assert(fox.state == fox.State.IDLE and fox.position.distance_to(fox._home) < .45 and fox.is_on_floor(),
		"Fox should reach its home around the real woodland obstacle")
	assert(closest > selected.shape.radius + .20, "Fox should stay outside the trunk")
	rows.append({"case":"real_fox_return_detour","center":center,"end":fox.position,"min_trunk_distance_m":closest})
	fox.set_physics_process(false)
	var before := [scene.remaining_enemies, scene.shards, scene.world_data.cleared.duplicate(), scene.lantern_lit]
	fox.take_damage(100)
	assert(before == [scene.remaining_enemies, scene.shards, scene.world_data.cleared, scene.lantern_lit])
	# Both actual enemy body shapes remain supported at representative regional paths.
	var original_wolf:Vector3=wolf.position
	for point in [Vector3(-56,0,12),Vector3(-36,0,-28),Vector3(0,0,-37),Vector3(76,1.58,0),Vector3(-20,0,82)]:
		for actor in [wolf,boar]:
			actor.position=point if point.x==76 else landscape.ground_point(point)+Vector3.UP*.08;actor.velocity=Vector3.ZERO
			var start:Vector3=actor.position
			for frame in range(30):
				actor.velocity=Vector3(0,-.8,0);actor.move_and_slide();await physics_frame
			assert(actor.position.y>start.y-.25,"Enemy bodies must not fall through regional support")
			rows.append({"case":"five_region_body_support","actor":str(actor.name),"start":start,"end":actor.position})
	FileAccess.open(output+"/navigation_results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"new_enemy_count":1,"fox_spawn":fox_spawn,"retired_ID_5_absent":true,"spawn_checks":spawn_rows,"boar_clear_full_length_lanes":clear_lanes,"nav_points":navigation.graph.get_point_count(),"nav_build_ms":navigation.build_ms,"path_requests":navigation.path_requests,"cases":rows},"  "))
	print("PASS: seven supported spawns and local paths across five regions, separate aggro zones and real navigation detours")
	scene.queue_free();paused=false;await process_frame;await create_timer(.25,true,false,true).timeout;quit()

func _alert_radius(actor: Node3D) -> float:
	if actor.name == "DemonFox":
		return actor.sense_range
	return 11.6 if actor.name == "DemonBoar" else 11.0
