extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	scene._resume()
	Engine.time_scale=4
	var hero=scene.player
	hero._camera_pivot.rotation=Vector3.ZERO
	var trunk: CollisionShape3D
	for body in scene.landscape.get_children():
		if body is StaticBody3D and body.get_child_count()>0 and body.get_child(0) is CollisionShape3D and body.get_child(0).shape is CylinderShape3D:
			trunk=body.get_child(0)
			break
	assert(trunk!=null)
	var center:=trunk.global_position
	var start:Vector3=scene.landscape.safe_point(center+Vector3.RIGHT*2.5)
	hero.global_position=start
	hero.velocity=Vector3.ZERO
	var before:float=Vector2(hero.position.x-center.x,hero.position.z-center.z).length()
	for frame in range(60):
		hero.set_move_input(Vector2(center.x-hero.position.x,center.z-hero.position.z).normalized())
		await physics_frame
	var after:float=Vector2(hero.position.x-center.x,hero.position.z-center.z).length()
	assert(after>=trunk.shape.radius+.28 and after<before,"Physical tree collision must stop the moving hero")
	hero.set_move_input(Vector2.ZERO)
	hero.position=Vector3(76,1.58,0)
	hero.velocity=Vector3.ZERO
	hero._camera_pivot.rotation=Vector3(-.12,PI,0)
	hero._camera_pivot.global_position=hero.position+Vector3.UP*1.2
	for frame in range(15):await physics_frame
	var camera:Camera3D=hero._camera_arm.get_child(0)
	var camera_query:=PhysicsShapeQueryParameters3D.new()
	var sphere:=SphereShape3D.new()
	sphere.radius=.12
	camera_query.shape=sphere
	camera_query.transform.origin=camera.global_position
	camera_query.collision_mask=4|8
	assert(scene.get_world_3d().direct_space_state.intersect_shape(camera_query).is_empty(),"Spring arm must keep camera out of the cave rock")
	var health:int=hero.health
	hero.position=Vector3(110,scene.landscape.height_at(Vector2(110,0))+.1,0)
	hero.velocity=Vector3.ZERO
	hero._camera_pivot.rotation=Vector3.ZERO
	for frame in range(120):
		hero.set_move_input(Vector2.RIGHT)
		await physics_frame
	assert(hero.position.x<118 and hero.health==health,"Shallow-water wall prevents sea escape without resetting progress or health")
	hero.set_move_input(Vector2.ZERO)
	scene.queue_free()
	paused=false
	await process_frame
	print("PASS: actual moving-player tree collision, cave spring-arm camera clearance and coastal wading boundary without health penalty")
	quit()
