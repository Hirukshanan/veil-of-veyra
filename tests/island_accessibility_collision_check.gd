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
	scene._resume();Engine.time_scale=2
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	var hero=scene.player;hero._camera_pivot.rotation=Vector3.ZERO
	var landscape=scene.landscape
	var trunks:Node3D=landscape.get_node("MatureTreeTrunks")
	assert(trunks.get_child_count()==35)
	# The newly supplied colliders align with the same approved visual anchors.
	var vegetation:Node3D=landscape.get_node("CandidateVegetation")
	for i in range(35):
		var c:CollisionShape3D=trunks.get_child(i)
		assert(Vector2(c.position.x,c.position.z).distance_to(Vector2(vegetation.tree_positions[i].x,vegetation.tree_positions[i].z))<.001)
	var shape_count:=0
	for c in landscape.find_children("*","CollisionShape3D",true,false):
		shape_count+=1
		assert(not c.disabled and (c.get_parent().collision_layer&1)!=0,"All candidate solids must be detected by the existing wolf mask")
	assert(shape_count==82)
	var test_trunk:CollisionShape3D=trunks.get_child(0)
	var p:Vector3=test_trunk.position;p.y-=test_trunk.shape.height*.5
	await hero_walk("original_tree_trunk",landscape.ground_point(p+Vector3.RIGHT*2.4)+Vector3.UP*.08,Vector2(-1,0),90)
	await hero_walk("cave_wall",Vector3(76,1.58,0),Vector2.RIGHT,100)
	assert(hero.position.x<78.5 and hero.position.x>77,"Hero must stop at the visible cave wall")
	# A new isolated fixture enemy uses the real unmodified wolf chase controller.
	hero.position=landscape.ground_point(p-Vector3.RIGHT*3)+Vector3.UP*.08;hero.set_physics_process(false)
	var wolf=load("res://scripts/enemy.gd").new();wolf.position=landscape.ground_point(p+Vector3.RIGHT*2.4)+Vector3.UP*.08;wolf.target=hero;scene.add_child(wolf)
	var contacts:=0
	for frame in range(150):
		await physics_frame
		for i in wolf.get_slide_collision_count():
			if absf(wolf.get_slide_collision(i).get_normal().y)<.5:contacts+=1
	var distance:float=Vector2(wolf.position.x-p.x,wolf.position.z-p.z).length()
	rows.append({"case":"wolf_AI_tree","contacts":contacts,"end":wolf.position,"trunk_distance_m":distance})
	assert(contacts>0 and distance>test_trunk.shape.radius+wolf.body_radius-.15,"Existing wolf AI must not walk through an instanced tree")
	wolf.queue_free();await physics_frame
	# Physical sweeps use the actual enemy CharacterBody and shape, without altering AI.
	# Select exposed steep faces with clear supported approach positions.
	var walls:Array=[]
	for region_name in ["WaterfallMountains","EasternCaves"]:
		var found:=0
		for mesh in landscape.get_node(region_name).find_children("*","MeshInstance3D",true,false):
			if str(mesh.name).contains("GradedTerrain"):continue
			var faces:PackedVector3Array=mesh.mesh.get_faces()
			for index in range(0,faces.size(),3):
				var a:Vector3=mesh.global_transform*faces[index];var b:Vector3=mesh.global_transform*faces[index+1];var c:Vector3=mesh.global_transform*faces[index+2]
				var center:Vector3=(a+b+c)/3;var normal:Vector3=(b-a).cross(c-a).normalized()
				if absf(normal.y)>.35 or center.y<1 or center.y>8:continue
				var flat:Vector3=Vector3(normal.x,0,normal.z).normalized()
				for sign_value in [-1,1]:
					var start:Vector3=landscape.ground_point(center+flat*sign_value*2.2)+Vector3.UP*.08
					if absf(center.y-start.y-.9)>1:continue
					var ray:=PhysicsRayQueryParameters3D.create(start+Vector3.UP*.9,start-flat*sign_value*4+Vector3.UP*.9,13)
					var hit:Dictionary=scene.get_world_3d().direct_space_state.intersect_ray(ray)
					if hit.is_empty() or absf(hit.normal.y)>.5:continue
					var q:=PhysicsShapeQueryParameters3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.8;capsule.height=2.1;q.shape=capsule;q.transform.origin=start+Vector3.UP*1.1;q.collision_mask=13
					if not scene.get_world_3d().direct_space_state.intersect_shape(q).is_empty():continue
					walls.append({"name":region_name+"_solid_"+str(found),"start":start,"direction":-flat*sign_value});found+=1;break
				if found>=2:break
			if found>=2:break
		assert(found>=1,"Need an actual supported approach to a visible regional solid")
	walls.append({"name":"cave_wall","start":Vector3(76,1.58,0),"direction":Vector3.RIGHT})
	for wall in walls:
		for kind in ["wolf","boar"]:
			var actor=load("res://scripts/enemy.gd" if kind=="wolf" else "res://scripts/demon_boar.gd").new();actor.position=wall.start;scene.add_child(actor);actor.set_physics_process(false)
			var contacts_count:=0
			for frame in range(90):
				actor.velocity=wall.direction*3.0+Vector3.DOWN*.5;actor.move_and_slide()
				for i in actor.get_slide_collision_count():
					if absf(actor.get_slide_collision(i).get_normal().y)<.6:contacts_count+=1
				await physics_frame
			rows.append({"case":wall.name+"_"+kind,"start":wall.start,"end":actor.position,"contacts":contacts_count,"method":"real enemy body/shape move_and_slide; AI held to isolate collision"})
			assert(contacts_count>0,"Enemy body must collide with visible solid scenery")
			actor.queue_free();await physics_frame
	# Existing spawns remain fixed and free of scenery penetrations after settling.
	var spawn_rows:=[]
	for enemy in get_nodes_in_group("combat_enemies"):
		var c:CollisionShape3D
		for child in enemy.get_children():
			if child is CollisionShape3D:c=child;break
		if c==null:continue
		var q:=PhysicsShapeQueryParameters3D.new();q.shape=c.shape;q.transform=c.global_transform.translated(Vector3.UP*.04);q.collision_mask=13;q.exclude=[enemy.get_rid()]
		var hits:Array=scene.get_world_3d().direct_space_state.intersect_shape(q)
		var hit_names:=[]
		for hit in hits:hit_names.append(str(hit.collider.get_parent().name))
		spawn_rows.append({"enemy":str(enemy.name),"position":enemy.position,"overlaps":hits.size(),"solids":hit_names})
	var camera_checks:=[]
	for location in [Vector3(76,1.58,0),Vector3(0,0,-40),Vector3(10,0,-55),Vector3(-14,0,-8)]:
		for yaw in [0.,PI*.5,PI,PI*1.5]:
			hero.position=location if location.x==76 else landscape.ground_point(location)+Vector3.UP*.08
			hero._camera_pivot.global_position=hero.position+Vector3.UP*1.2;hero._camera_pivot.rotation=Vector3(-.15,yaw,0)
			for frame in range(12):await physics_frame
			var camera:Camera3D=hero._camera_arm.get_child(0)
			var q:=PhysicsShapeQueryParameters3D.new();var sphere:=SphereShape3D.new();sphere.radius=.12;q.shape=sphere;q.transform.origin=camera.global_position;q.collision_mask=4|8
			var clear:bool=scene.get_world_3d().direct_space_state.intersect_shape(q).is_empty()
			camera_checks.append({"hero":hero.position,"yaw":yaw,"camera":camera.global_position,"clear":clear})
			assert(clear,"Spring arm must keep the camera outside corrected rock/bank/cave collision")
	FileAccess.open(output+"/collision_tests.json",FileAccess.WRITE).store_string(JSON.stringify({"static_shapes":shape_count,"new_original_root_proxies":35,"all_solids_on_existing_enemy_mask":true,"cases":rows,"spawn_checks":spawn_rows,"camera_checks":camera_checks},"  "))
	assert(spawn_rows.all(func(row):return row.overlaps==0),"Preserved enemy spawn must not overlap solid terrain")
	print("PASS: actual hero/wolf movement, wolf/boar body sweeps, 82 layer-compatible shapes, unchanged spawn clearance")
	scene.queue_free();await process_frame;await create_timer(.25,true,false,true).timeout;quit()
func hero_walk(label:String,start:Vector3,input:Vector2,frames:int):
	var hero=scene.player;hero.position=start;hero.velocity=Vector3.ZERO;var contacts:=0
	for frame in range(frames):
		hero.set_move_input(input);await physics_frame
		for i in hero.get_slide_collision_count():
			if absf(hero.get_slide_collision(i).get_normal().y)<.6:contacts+=1
	hero.set_move_input(Vector2.ZERO)
	rows.append({"case":label,"contacts":contacts,"start":start,"end":hero.position,"method":"unmodified player controller"})
	assert(contacts>0,"Hero must physically contact the visible solid")
