extends SceneTree
const STORE = preload("res://scripts/campaign_store.gd")

class SlowCampaign:
	extends "res://scripts/campaign.gd"
	var slow_save := false
	var reload_requested := false
	func _write_progress(data: Dictionary) -> Error:
		if slow_save: OS.delay_msec(180)
		return CAMPAIGN_STORE.save_progress(data)
	func _reload() -> void:
		reload_requested = true

var scene
func _initialize(): call_deferred("run")
func open_world():
	scene = SlowCampaign.new()
	root.add_child(scene)
	await process_frame
	scene._resume()
	for enemy in get_nodes_in_group("combat_enemies"): enemy.set_physics_process(false)
	scene.get_node("IslandExploration").bind_waystone(0)
	scene.set_process(false)
func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	for path in [STORE.PATH, STORE.BACKUP, STORE.TEMP]: DirAccess.remove_absolute(path)
	await open_world()
	scene.slow_save = true
	scene.player.health = 73
	var before := Time.get_ticks_usec()
	scene._process(5.1)
	var dispatch_ms := (Time.get_ticks_usec() - before) / 1000.0
	assert(dispatch_ms < 90, "A slow disk write must not stall the gameplay frame")
	assert(scene._autosave_thread != null)
	var first_thread: Thread = scene._autosave_thread
	scene._start_autosave()
	assert(scene._autosave_thread == first_thread, "Do not run two file writers at once")
	# Mutate the live world while the old snapshot is waiting to be written.
	scene.player.health = 62
	scene.world_data.cleared.append(0)
	scene.player.set_move_input(Vector2(0, -1))
	var origin: Vector3 = scene.player.position
	for index in range(4): await physics_frame
	assert(scene.player.position.distance_to(origin) > 0.1, "Movement must continue during a slow autosave")
	scene.player.set_move_input(Vector2.ZERO)
	scene.player.set_physics_process(false)
	scene._finish_autosave(true)
	var saved: Dictionary = STORE.load_progress().data
	assert(saved.world_data.health == 73 and saved.world_data.cleared == [5], "Worker snapshots must not share live mutable arrays")
	assert(not scene._save_failed)

	# A manual/quest save must win over an earlier pending periodic snapshot.
	scene._start_autosave()
	scene.player.health = 51
	assert(scene._save_progress())
	assert(scene._autosave_thread == null and STORE.load_progress().data.world_data.health == 51)
	scene.slow_save = false
	# Error status is returned to the main thread, and a later save can recover.
	assert(DirAccess.make_dir_absolute(STORE.TEMP) == OK)
	scene._start_autosave()
	scene._finish_autosave(true)
	assert(scene._save_failed and "Save failed" in scene.notice)
	assert(STORE.load_progress().data.world_data.health == 51)
	assert(DirAccess.remove_absolute(STORE.TEMP) == OK)
	assert(scene._save_progress() and not scene._save_failed)
	scene.progress_unreadable = true
	scene._start_autosave()
	assert(scene._autosave_thread == null, "Protected corrupt saves must never be overwritten in the background")
	scene.progress_unreadable = false

	# Reset waits for the old writer; old progress cannot return after New journey.
	scene.slow_save = true
	scene._start_autosave()
	scene._reset_world()
	assert(scene.reload_requested and scene._autosave_thread == null)
	assert(STORE.load_progress().data.shards == 0 and STORE.load_progress().data.world_data.cleared.is_empty())
	scene.queue_free()
	await process_frame
	paused = false

	# Leaving the tree joins an active writer before the next scene can load.
	await open_world()
	scene.slow_save = true
	scene.player.health = 41
	scene._start_autosave()
	scene.queue_free()
	await process_frame
	paused = false
	assert(STORE.load_progress().data.world_data.health == 41)
	print("PASS: 180ms disk latency without movement stall (dispatch %.2fms), immutable snapshots, serialized writes, errors/retry, corrupt-save protection, reset and scene exit" % dispatch_ms)
	quit()
