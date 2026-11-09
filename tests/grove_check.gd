extends SceneTree
const STORE = preload("res://scripts/campaign_store.gd")
var scene
func _initialize():
	call_deferred("run")
func open_world():
	scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("lock_targets"): enemy.set_physics_process(false)
func close_world():
	scene.queue_free()
	await process_frame
	paused=false
func harvest(id: int):
	var locations: Array=scene.herbs.LOCATIONS+scene.herbs.GROVE.HERBS
	scene.player.position=locations[id]
	scene._update_objective()
	assert(scene.interact_button.text.is_empty() and scene.interact_button.accessibility_name == "Collect herb" and scene.interact_button.icon != null)
	scene._interact_world()
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	for path in [STORE.PATH,STORE.BACKUP,STORE.TEMP]: DirAccess.remove_absolute(path)
	# Simulate an existing v2 island with three herbs and a bound waystone.
	var legacy:=ConfigFile.new()
	legacy.set_value("campaign","version",2)
	legacy.set_value("campaign","shards",55)
	legacy.set_value("campaign","blade_level",1)
	var old_world:Dictionary=STORE.fresh_world()
	old_world.erase("grove_reward")
	old_world.herbs=[0,1,2]
	old_world.potions=6
	old_world.cleared=[0,5]
	old_world.discovered=[true,true,false]
	old_world.checkpoint=1
	legacy.set_value("campaign","world",old_world)
	assert(legacy.save(STORE.PATH)==OK)
	await open_world()
	assert(scene.shards==55 and scene.blade_level==1 and scene.herbs.collected==3)
	assert(scene.remaining_enemies==4 and scene.get_node("IslandExploration").checkpoint_index==1)
	assert(not scene.world_data.grove_reward and scene.herbs.grove_count()==0)
	var grove=scene.get_node("IslandExploration/MoonleafGrove")
	assert(grove.position==scene.herbs.GROVE.CENTER)
	await physics_frame
	var space=scene.get_world_3d().direct_space_state
	var route=preload("res://scripts/island_terrain.gd").trails()[3]
	for point in route:
		var ground=space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*40,point+Vector3.DOWN*3,1))
		assert(not ground.is_empty() and absf(ground.position.y)<0.1,"Grove route must stay on flat walkable ground")
	for index in range(route.size()-1):
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(route[index]+Vector3.UP,route[index+1]+Vector3.UP,8))
		if not hit.is_empty(): print("BLOCK ", route[index], " -> ",route[index+1]," at ",hit.position," collider ",hit.collider.get_path())
		assert(hit.is_empty(),"New route must not pass through tree trunks/rocks")
	for point in scene.herbs.GROVE.HERBS:
		var blocker=space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*2,point+Vector3.UP*0.1,8))
		assert(blocker.is_empty(),"Grove plants must be accessible")
	harvest(8)
	harvest(9)
	assert(scene.shards==55 and scene.herbs.grove_count()==2)
	await close_world()
	await open_world()
	assert(scene.herbs.grove_count()==2 and scene.potions==8)
	harvest(10)
	assert(scene.shards==80 and scene.world_data.grove_reward)
	assert("COMPLETE" in scene.herbs.grove_journal(true))
	scene._interact_world()
	assert(scene.shards==80 and scene.potions==9)
	harvest(11)
	harvest(12)
	assert(scene.shards==80 and scene.potions==11)
	assert(scene._save_progress())
	await close_world()
	await open_world()
	assert(scene.world_data.grove_reward and scene.shards==80 and scene.herbs.grove_count()==5)
	assert(scene.herbs.plants.size()==5,"Old and new harvested plants must stay gone")
	# Reward flags cannot be forged without three distinct grove IDs.
	var invalid:Dictionary=STORE.load_progress().data.world_data.duplicate(true)
	invalid.herbs=[0,1,2,8,9]
	assert(not STORE.valid_world(invalid,false,0))
	var capped:Dictionary=STORE.load_progress().data.world_data.duplicate(true)
	capped.herbs=range(13)
	capped.potions=16
	assert(STORE.valid_world(capped,false,0), "All finite herb pickups must fit the potion save limit")
	var config:=ConfigFile.new()
	assert(config.load(STORE.PATH)==OK)
	var missing:Dictionary=capped.duplicate(true)
	missing.erase("grove_reward")
	config.set_value("campaign","world",missing)
	assert(config.save("user://invalid_grove.cfg")==OK)
	assert(STORE.read_file("user://invalid_grove.cfg").error==ERR_INVALID_DATA,"Current format must require its reward flag")
	await close_world()
	print("PASS: v2 migration, grove trail/plant accessibility, quest persistence across reopen, third-flower reward, no duplicate payout and valid reward flags")
	quit()
