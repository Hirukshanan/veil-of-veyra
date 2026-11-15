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
	assert(scene.remaining_enemies==5 and get_nodes_in_group("combat_enemies").size()==6 and scene.get_node_or_null("CampDemon5")==null)
	var spawn_rows:=[]
	for row in scene.encounter_log:
		var actor=scene.get_node(row.id);var collision:CollisionShape3D
		for child in actor.get_children():
			if child is CollisionShape3D:collision=child;break
		var q:=PhysicsShapeQueryParameters3D.new();q.shape=collision.shape;q.transform=collision.global_transform.translated(Vector3.UP*.04);q.collision_mask=4|8
		assert(scene.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"Exact unchanged actor collision must be clear at its new spawn")
		if expected.has(row.id):
			assert(actor.kind==expected[row.id] and actor.health==[18,17,21][actor.kind])
			assert(actor.attack_damage==[8,5,16][actor.kind])
		else:assert(actor.health==24 and actor.REWARD_SHARDS==20)
		spawn_rows.append({"id":row.id,"position":actor.position,"shape_clear":true,"health":actor.health,"display_name":actor.display_name if "display_name" in actor else "DEMON BOAR"})
	# A full stopped pose and charge path must have room at the boar's new border.
	var boar=scene.get_node("DemonBoar");var clear_lanes:=0
	for index in range(12):
		boar.rotation.y=index*TAU/12
		if boar._cast(-boar.global_basis.z*7.02)>.98:clear_lanes+=1
	assert(clear_lanes>=8,"The border encounter must have several unobstructed charging directions")
	boar.rotation=Vector3.ZERO
	# Graph is derived from actual terrain/collision, with no collider or scenery edits.
	assert(navigation.graph.get_point_count()>800 and navigation.graph.get_point_count()<2500)
	for actor_name in expected:
		var actor=scene.get_node(actor_name);var original:Vector3=actor.position
		var target:Vector3=original+Vector3(4,0,3)
		var end_id:int=navigation.graph.get_closest_point(target);var start_id:int=navigation.graph.get_closest_point(original)
		assert(navigation.graph.get_id_path(start_id,end_id).size()>1,"Existing woodland encounter needs a connected local pursuit route")
		rows.append({"case":"spawn_local_path","actor":actor_name,"points":navigation.graph.get_id_path(start_id,end_id).size()})
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
	FileAccess.open(output+"/navigation_results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"new_enemy_count":0,"retired_ID_5_absent":true,"spawn_checks":spawn_rows,"boar_clear_full_length_lanes":clear_lanes,"nav_points":navigation.graph.get_point_count(),"nav_build_ms":navigation.build_ms,"path_requests":navigation.path_requests,"cases":rows},"  "))
	print("PASS: six stable encounter identities/spawns, charge clearance, connected local routes, actual wolf/boar tree detours and five-region physics support")
	scene.queue_free();paused=false;await process_frame;await create_timer(.25,true,false,true).timeout;quit()
