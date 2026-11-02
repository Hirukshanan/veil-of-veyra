extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.cfg"))
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.camera_sensitivity == 1.0 and scene.sound_volume == 0.7)
	scene._show_settings(scene._show_camp)
	assert(paused)
	var sliders: Array = []
	for child in scene.menu_box.get_children():
		if child is HSlider:
			sliders.append(child)
	sliders[0].value = 1.5
	sliders[1].value = 0.0
	assert(scene.player.camera_sensitivity == 1.5)
	assert(AudioServer.is_bus_mute(0))
	var yaw := float(scene.player._camera_pivot.rotation.y)
	scene.player._rotate_camera(Vector2(100, 0))
	assert(is_equal_approx(scene.player._camera_pivot.rotation.y, yaw - 0.75))
	assert(scene._save_settings() == OK)
	scene.queue_free()
	await process_frame
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.camera_sensitivity == 1.5 and scene.sound_volume == 0.0)
	scene.sound_volume = 0.5
	scene._apply_settings()
	assert(not AudioServer.is_bus_mute(0))
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.5))
	scene._load_settings()
	assert(scene.sound_volume == 0.0, "Discard must restore saved settings")
	for cue in ["sword", "dodge", "hurt"]:
		scene.player.play_sound(cue)
		assert(scene.player._sound.stream.get_length() > 0.0)
	var config := ConfigFile.new()
	config.set_value("settings", "camera_sensitivity", "invalid")
	config.set_value("settings", "sound_volume", 30)
	assert(config.save(scene.SETTINGS_PATH) == OK)
	scene._load_settings()
	assert(scene.camera_sensitivity == 1.0 and scene.sound_volume == 1.0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.SETTINGS_PATH))
	print("PASS: settings controls, pause, camera scaling, save/reload, discard, mute, sound streams, invalid values")
	paused = false
	await create_timer(0.4).timeout
	scene.queue_free()
	await process_frame
	quit()
