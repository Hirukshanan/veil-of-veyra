extends SceneTree

const STORE = preload("res://scripts/campaign_store.gd")

func _initialize() -> void:
	call_deferred("_run")

func _invalid(path: String) -> void:
	var config := ConfigFile.new()
	config.set_value("campaign", "chapter", "not a chapter")
	assert(config.save(path) == OK)

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	for path in [STORE.PATH, STORE.BACKUP, STORE.TEMP]:
		DirAccess.remove_absolute(path)
	var initial: Dictionary = STORE.DEFAULTS.duplicate()
	assert(STORE.load_progress().data == initial)
	initial.shards = 40
	assert(STORE.save_progress(initial) == OK)
	var latest := initial.duplicate()
	latest.shards = 80
	latest.chapter = 1
	assert(STORE.save_progress(latest) == OK)
	assert(STORE.load_progress().data == latest)
	assert(STORE.read_file(STORE.BACKUP).data == initial)
	_invalid(STORE.PATH)
	var recovered: Dictionary = STORE.load_progress()
	assert(recovered.recovered and recovered.data == initial)
	assert(STORE.save_progress(initial) == OK)
	assert(STORE.read_file(STORE.BACKUP).data == initial, "Corrupt primary must not replace good backup")
	assert(STORE.load_progress().data == initial)
	# Simulate interruption after the old primary has moved to backup.
	assert(DirAccess.rename_absolute(STORE.PATH, STORE.BACKUP) == OK)
	_invalid(STORE.TEMP)
	assert(STORE.load_progress().data == initial)
	assert(STORE.load_progress().recovered)
	assert(STORE.save_progress(latest) == OK)
	# A blocked temporary path must leave both existing snapshots readable.
	assert(DirAccess.make_dir_absolute(STORE.TEMP) == OK)
	assert(STORE.save_progress(initial) != OK)
	assert(STORE.load_progress().data == latest)
	assert(STORE.read_file(STORE.BACKUP).data == initial)
	assert(DirAccess.remove_absolute(STORE.TEMP) == OK)
	# Invalid values must not be silently converted into plausible progress.
	for value in [-1, 99, true, 1.5]:
		var config := ConfigFile.new()
		config.set_value("campaign", "chapter", value)
		assert(config.save(STORE.PATH) == OK)
		assert(STORE.read_file(STORE.PATH).error == ERR_INVALID_DATA)
	_invalid(STORE.PATH)
	_invalid(STORE.BACKUP)
	assert(STORE.load_progress().error != OK)
	var before := FileAccess.get_file_as_string(STORE.PATH)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.progress_unreadable)
	scene.shards = 500
	assert(not scene._save_progress())
	assert(FileAccess.get_file_as_string(STORE.PATH) == before)
	scene.queue_free()
	await process_frame
	paused = false
	# Leave a clean valid save for other tests, not the intentionally bad fixture.
	assert(STORE.save_progress(initial) == OK)
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene._resume()
	assert(DirAccess.make_dir_absolute(STORE.TEMP) == OK)
	scene._on_boss_defeated()
	assert(scene.shards == 80 and scene.chapter == 1)
	assert("Save failed" in scene.notice)
	assert(STORE.load_progress().data.shards == 40)
	assert(scene.menu_box.get_child(2).text == "Retry save and return")
	assert(DirAccess.remove_absolute(STORE.TEMP) == OK)
	scene._retry_save_and_return()
	await process_frame
	await process_frame
	assert(current_scene.shards == 80 and current_scene.chapter == 1)
	assert(paused and not current_scene.game_finished)
	current_scene.queue_free()
	await process_frame
	paused = false
	print("PASS: complete saves, backup recovery, interrupted/failed writes, invalid values, overwrite protection and victory save retry without duplicate rewards")
	quit()
