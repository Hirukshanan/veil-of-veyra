extends SceneTree
const TERRAIN=preload("res://scripts/island_terrain.gd")
const STORE=preload("res://scripts/campaign_store.gd")
var scene
func _initialize(): call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	for path in [STORE.PATH,STORE.BACKUP,STORE.TEMP]: DirAccess.remove_absolute(path)
	scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	var hero=scene.player
	hero.set_physics_process(false)
	for enemy in get_nodes_in_group("lock_targets"): enemy.set_physics_process(false)
	await physics_frame
	var space=scene.get_world_3d().direct_space_state
	assert(TERRAIN.OUTER_RADIUS==120 and TERRAIN.WATERLINE_BASE==114.5)
	var forest=scene.get_node("IslandExploration/TallForests")
	# New trails, the grove and its vista deliberately reduce tree density.
	assert(forest.tree_positions.size()>=32 and forest.tree_positions.size()<=65)
	for woodland in TERRAIN.FORESTS:
		var trees := 0
		for point in forest.tree_positions:
			if ((Vector2(point.x,point.z)-Vector2(woodland.x,woodland.y))/Vector2(woodland.z,woodland.w)).length()<1.0:
				trees += 1
		assert(trees>=12,"Both woodland areas must retain a substantial canopy")
	assert(forest.tree_heights.min()>12.0 and forest.tree_heights.max()<17.0)
	var mesh: Mesh=forest.TREE_MESH
	var triangles:=0
	for surface in range(mesh.get_surface_count()):
		assert(mesh.surface_get_material(surface)!=null,"Reduced tree surfaces must keep their textured materials")
		triangles+=mesh.surface_get_array_index_len(surface)/3
	assert(triangles<3000,"Forest trunks/branches must stay within their mobile geometry budget")
	var instances:=0
	var batches:=0
	for node in forest.get_children():
		if node is MultiMeshInstance3D and not str(node.name).ends_with("_Canopy"):
			instances+=node.multimesh.instance_count
			batches+=1
	assert(instances==forest.tree_positions.size() and batches<instances)
	for point in forest.tree_positions:
		assert(TERRAIN.contour(Vector2(point.x,point.z))<TERRAIN.GRASS_RADIUS-6.0)
		var trunk=space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3(-2,1,0),point+Vector3(2,1,0),8))
		assert(not trunk.is_empty(),"Every visible forest tree needs a matching trunk collider")
	# No tree trunks on any part of the outer sandy beach.
	for index in range(64):
		var angle:=index*TAU/64.0
		var radial:=Vector3(cos(angle),0,sin(angle))
		var inside:=radial*TERRAIN.coast_radius(angle,TERRAIN.INNER_RADIUS+1)+Vector3.UP
		var outside:=radial*TERRAIN.coast_radius(angle,TERRAIN.WATERLINE_BASE)+Vector3.UP
		assert(space.intersect_ray(PhysicsRayQueryParameters3D.create(inside,outside,8)).is_empty(),"Sandy coastline must remain clear of trees")
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(inside+Vector3.UP*3,inside+Vector3.DOWN*5,1))
		assert(not hit.is_empty(),"Expanded beach must have continuous physical ground")
	# The old continuous mountain wall is gone; hills have broad, separated footprints.
	for hill in TERRAIN.HILLS.PEAKS:
		assert(hill.z>=18 and hill.w<=10)
		assert(hill.w*PI/(2.0*hill.z)<tan(deg_to_rad(40.0)),"Hill slopes must remain walkable")
		var point:=Vector2(hill.x,hill.y)
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(point.x,20,point.y),Vector3(point.x,-3,point.y),1))
		assert(not hit.is_empty() and absf(hit.position.y-TERRAIN.height_at(point))<0.3)
	# Walk up two open hills using the real player controller.
	var ticks_before:=Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second=30
	for hill in [TERRAIN.HILLS.PEAKS[2],TERRAIN.HILLS.PEAKS[4]]:
		hero.position=Vector3(hill.x,0,hill.y+hill.z*0.85)
		hero.position.y=TERRAIN.height_at(Vector2(hero.position.x,hero.position.z))+0.2
		hero.velocity=Vector3.ZERO
		hero._camera_pivot.rotation=Vector3.ZERO
		hero.set_move_input(Vector2.ZERO)
		hero.set_physics_process(true)
		for index in range(12): await physics_frame
		var start_height: float=hero.position.y
		hero.set_move_input(Vector2(0,-1))
		for index in range(54): await physics_frame
		assert(hero.position.y>start_height+2.0 and hero.health==100,"Real movement must climb the new hills without rescue/damage")
		hero.set_move_input(Vector2.ZERO)
		hero.set_physics_process(false)
	Engine.physics_ticks_per_second=ticks_before
	# Newly reachable land saves, and old below-ground positions relocate without resource loss.
	hero.position=Vector3(0,-0.8,108)
	hero.health=63
	scene.potions=5
	scene.shards=27
	assert(scene._save_progress())
	assert(STORE.load_progress().data.world_data.position==hero.position)
	for point in [Vector3(0,-1.7,91.8),Vector3(8,0,67)]:
		scene.world_data.position=point
		scene._restore_world()
		assert(hero.position.y>=TERRAIN.height_at(Vector2(point.x,point.z)))
		assert(hero.health==63 and scene.potions==5 and scene.shards==27)
	scene.queue_free()
	await process_frame
	paused=false
	print("PASS: expanded terrain, tall batched forests/colliders, clear sandy coast, scattered walkable hills, real climbing and safe legacy-height restoration")
	quit()
