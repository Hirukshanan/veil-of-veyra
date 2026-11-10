extends SceneTree
const STORE = preload("res://scripts/campaign_store.gd")
func _initialize():
	call_deferred("run")
func fresh() -> Dictionary:
	var data := STORE.DEFAULTS.duplicate()
	data.world_data = STORE.fresh_world()
	return data
func clear_files():
	for path in [STORE.PATH,STORE.BACKUP,STORE.TEMP]: DirAccess.remove_absolute(path)
func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	clear_files()
	assert(STORE.load_progress().data == fresh())
	for chapter in range(3):
		for completed in [false,true]:
			var legacy := ConfigFile.new()
			legacy.set_value("campaign","chapter",chapter)
			legacy.set_value("campaign","shards",123)
			legacy.set_value("campaign","blade_level",2)
			legacy.set_value("campaign","armor_level",3)
			legacy.set_value("campaign","completed",completed)
			assert(legacy.save(STORE.PATH)==OK)
			var migrated:Dictionary=STORE.load_progress()
			assert(migrated.migrated and migrated.data.shards==123 and migrated.data.blade_level==2 and migrated.data.armor_level==3)
			assert(migrated.data.completed==completed and migrated.data.world_data.lantern==completed)
			assert(migrated.data.world_data.health==175)
	clear_files()
	var initial := fresh()
	initial.shards=40
	assert(STORE.save_progress(initial)==OK)
	var latest:=initial.duplicate(true)
	latest.shards=80
	latest.world_data.herbs=[0,2]
	latest.world_data.potions=5
	assert(STORE.save_progress(latest)==OK)
	assert(STORE.load_progress().data==latest)
	assert(STORE.read_file(STORE.BACKUP).data==initial)
	# Future, malformed and inconsistent world snapshots must fall back, not be coerced.
	for bad in [{"herbs":[0,0]}, {"discovered":[true,"yes",false]}, {"checkpoint":2}, {"position":Vector3(NAN,0,0)}, {"health":1000}, {"potions":-1}, {"lantern":true}, {"bounty_reward":true}]:
		var broken:=latest.duplicate(true)
		broken.world_data.merge(bad,true)
		var config:=ConfigFile.new()
		config.set_value("campaign","version",2)
		for key in STORE.DEFAULTS: config.set_value("campaign",key,broken[key])
		config.set_value("campaign","world",broken.world_data)
		assert(config.save(STORE.PATH)==OK)
		assert(STORE.read_file(STORE.PATH).error==ERR_INVALID_DATA)
		assert(STORE.load_progress().recovered and STORE.load_progress().data==initial)
	assert(STORE.save_progress(latest)==OK)
	assert(STORE.read_file(STORE.BACKUP).data==initial)
	assert(DirAccess.rename_absolute(STORE.PATH,STORE.BACKUP)==OK)
	assert(STORE.load_progress().recovered and STORE.load_progress().data==latest)
	assert(STORE.save_progress(latest)==OK)
	assert(DirAccess.make_dir_absolute(STORE.TEMP)==OK)
	assert(STORE.save_progress(initial)!=OK and STORE.load_progress().data==latest)
	assert(DirAccess.remove_absolute(STORE.TEMP)==OK)
	# Two invalid snapshots must remain protected until explicit New journey.
	for path in [STORE.PATH,STORE.BACKUP]:
		var invalid:=ConfigFile.new()
		invalid.set_value("campaign","version",999)
		assert(invalid.save(path)==OK)
	var before:=FileAccess.get_file_as_string(STORE.PATH)
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	assert(scene.progress_unreadable and not scene._save_progress())
	assert(FileAccess.get_file_as_string(STORE.PATH)==before)
	scene.queue_free()
	await process_frame
	paused=false
	clear_files()
	scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene._resume()
	for enemy in get_nodes_in_group("lock_targets"): enemy.take_damage(1000)
	await process_frame
	scene.player.position=scene.lantern.position
	scene.seal_fragments.restore([0,1,2])
	scene._interact_lantern()
	assert(DirAccess.make_dir_absolute(STORE.TEMP)==OK)
	scene.get_node("Tidewraith Dragon").take_damage(10000)
	assert(scene.completed and scene.shards==80 and scene._save_failed)
	assert(not STORE.load_progress().data.completed)
	scene._on_boss_defeated()
	assert(scene.shards==80)
	assert(DirAccess.remove_absolute(STORE.TEMP)==OK)
	scene._retry_save_and_return()
	assert(STORE.load_progress().data.completed and STORE.load_progress().data.shards==80)
	# Failed New journey leaves the in-memory and disk world intact.
	assert(DirAccess.make_dir_absolute(STORE.TEMP)==OK)
	scene._reset_world()
	assert(scene.completed and scene.shards==80)
	assert(STORE.load_progress().data.completed)
	assert(DirAccess.remove_absolute(STORE.TEMP)==OK)
	scene._reset_world()
	await process_frame
	await process_frame
	assert(not current_scene.completed and current_scene.shards == 0 and current_scene.remaining_enemies == 5)
	assert(STORE.load_progress().data.world_data.herbs.is_empty())
	# This test did not set current_scene, so clean the old scene and any reload.
	for child in root.get_children(): child.queue_free()
	await process_frame
	paused=false
	print("PASS: legacy migration, world validation, backup/interruption recovery, failed writes, corrupt-save protection, one-time victory retry and transactional reset")
	quit()
