extends SceneTree
const STORE = preload("res://scripts/campaign_store.gd")
var scene
func _initialize(): call_deferred("run")
func open_world():
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("lock_targets"): enemy.set_physics_process(false)
func close_world():
	scene.queue_free()
	await process_frame
	paused=false
func key_e():
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_E
	key.pressed=true
	root.push_input(key)
	key=InputEventKey.new()
	key.physical_keycode=KEY_E
	root.push_input(key)
func write_legacy(version: int, lit: bool, completed: bool):
	var config:=ConfigFile.new()
	config.set_value("campaign","version",version)
	config.set_value("campaign","shards",123)
	config.set_value("campaign","blade_level",2)
	config.set_value("campaign","completed",completed)
	var world:Dictionary=STORE.fresh_world()
	world.erase("seal_fragments")
	world.herbs=[0,8]
	world.potions=5
	world.relics=[1]
	world.lantern=lit
	if lit: world.cleared=[0,1,2,3,4,5]
	config.set_value("campaign","world",world)
	assert(config.save(STORE.PATH)==OK)
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	for path in [STORE.PATH,STORE.BACKUP,STORE.TEMP]: DirAccess.remove_absolute(path)
	await open_world()
	assert(scene.seal_fragments.fragments.size()==3)
	var initial_potions:int=scene.potions
	var initial_shards:int=scene.shards
	var seals=scene.seal_fragments
	await physics_frame
	var space=scene.get_world_3d().direct_space_state
	var route=preload("res://scripts/island_terrain.gd").trails()[4]
	for point in route:
		var ground=space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*40,point+Vector3.DOWN*4,1))
		assert(not ground.is_empty() and absf(ground.position.y)<0.15,"Beach trail must remain walkable")
	for index in range(route.size()-1):
		var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(route[index]+Vector3.UP,route[index+1]+Vector3.UP,8))
		if not hit.is_empty(): print("BLOCKED ROUTE ",hit.position," ",hit.collider.get_path())
		assert(hit.is_empty(),"Beach trail must avoid trunks and ruin pillars")
	for point in seals.LOCATIONS:
		var ground=space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*10,point+Vector3.DOWN*3,1))
		assert(not ground.is_empty() and absf(ground.position.y)<0.15,"Fragments must stay above sea on land")
		assert(space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*2,point+Vector3.UP*0.1,8)).is_empty(),"Fragment cannot be inside scenery")
	scene.player.position=seals.LOCATIONS[0]
	scene._pause_game()
	key_e()
	assert(seals.collected_ids.is_empty())
	scene._resume()
	scene._update_objective()
	assert(scene.interact_button.text.is_empty() and scene.interact_button.accessibility_name=="Collect seal fragment")
	key_e()
	key_e()
	assert(seals.collected_ids==[0] and scene.potions==initial_potions and scene.shards==initial_shards)
	await close_world()
	await open_world()
	assert(scene.seal_fragments.collected_ids==[0] and scene.seal_fragments.fragments.size()==2)
	# All fragments alone cannot bypass uncleared camps.
	for id in [1,2]:
		scene.player.position=scene.seal_fragments.LOCATIONS[id]
		scene._interact_world()
	assert(scene.seal_fragments.complete())
	scene.player.position=scene.lantern.position
	scene._interact_lantern()
	assert(not scene.lantern_lit and not scene.boss_spawned)
	# Cleared camps alone cannot bypass missing fragments.
	for enemy in get_nodes_in_group("lock_targets"): enemy.take_damage(10000)
	await process_frame
	scene.seal_fragments.collected_ids.assign([0,1])
	scene._interact_lantern()
	assert(not scene.lantern_lit and not scene.boss_spawned)
	scene.seal_fragments.collected_ids.assign([0,1,2])
	scene.player.position=Vector3.ZERO
	scene._interact_lantern()
	assert(not scene.boss_spawned,"Range guard remains")
	scene.player.position=scene.lantern.position
	scene._pause_game()
	scene._interact_lantern()
	assert(not scene.boss_spawned)
	scene._resume()
	key_e()
	assert(scene.lantern_lit and scene.boss_spawned)
	key_e()
	assert(scene.find_children("Tidewraith Dragon*","",false,false).size()==1)
	assert(STORE.load_progress().data.world_data.seal_fragments==[0,1,2])
	await close_world()
	await open_world()
	assert(scene.lantern_lit and scene.boss_spawned and scene.seal_fragments.fragments.is_empty())
	await close_world()
	# Existing players retain lit/completed lanterns; unfinished saves get the new quest.
	for version in [2,3]:
		for state in [[false,false],[true,false],[true,true]]:
			var lit:bool=state[0]
			var won:bool=state[1]
			write_legacy(version,lit,won)
			await open_world()
			assert(not scene.progress_unreadable and scene.shards==123 and scene.blade_level==2)
			assert(scene.herbs.collected_ids==[0,8] and scene.relic_hunt.collected_ids==[1])
			assert(scene.lantern_lit==lit and scene.completed==won)
			assert(scene.seal_fragments.complete()==lit)
			assert(scene.boss_spawned==(lit and not won))
			assert(scene.seal_fragments.fragments.size()==(0 if lit else 3))
			assert(scene._save_progress())
			await close_world()
	var bad:Dictionary=STORE.load_progress().data.world_data.duplicate(true)
	bad.seal_fragments=[0,0,2]
	assert(not STORE.valid_world(bad,true,0))
	bad.seal_fragments=[0,1]
	assert(not STORE.valid_world(bad,true,0),"Lit lantern requires the full seal in current saves")
	var config:=ConfigFile.new()
	assert(config.load(STORE.PATH)==OK)
	var missing:Dictionary=STORE.load_progress().data.world_data.duplicate(true)
	missing.erase("seal_fragments")
	config.set_value("campaign","world",missing)
	assert(config.save("user://missing_seals.cfg")==OK)
	assert(STORE.read_file("user://missing_seals.cfg").error==ERR_INVALID_DATA,"Current save format must require fragment state")
	print("PASS: beach accessibility, E/icon collection, pause/range/duplicate guards, fragment persistence, both lantern gates and v2/v3 lit/completed-save migration")
	quit()
