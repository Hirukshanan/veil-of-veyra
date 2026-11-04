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
	assert(scene.frame_limit == 60 and Engine.max_fps == 60)
	var frame_choice = scene.menu_box.get_node("FrameLimitChoice")
	frame_choice.select(0)
	frame_choice.item_selected.emit(0)
	assert(scene.frame_limit == 30 and Engine.max_fps == 30)
	var sun: DirectionalLight3D = scene.find_children("*", "DirectionalLight3D", true, false)[0]
	assert(sun.shadow_enabled and scene.shadows_enabled)
	var toggle = scene.menu_box.get_node("ShadowsToggle")
	toggle.button_pressed = false
	assert(not sun.shadow_enabled and not scene.shadows_enabled)
	var sliders: Array = []
	for child in scene.menu_box.get_children():
		if child is HSlider:
			sliders.append(child)
	sliders[0].value = 1.5
	sliders[1].value = 0.0
	sliders[2].value = 8.0
	assert(scene.player._camera_arm.spring_length == 8.0)
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
	assert(scene.camera_distance == 8.0 and scene.player._camera_arm.spring_length == 8.0)
	assert(not scene.shadows_enabled, "Graphics setting must survive reload")
	sun = scene.find_children("*", "DirectionalLight3D", true, false)[0]
	assert(not sun.shadow_enabled)
	assert(scene.frame_limit == 30 and Engine.max_fps == 30, "Frame limit must survive reload")
	scene.frame_limit = 60
	scene.shadows_enabled = true
	scene.sound_volume = 0.5
	scene._apply_settings()
	assert(not AudioServer.is_bus_mute(0))
	assert(sun.shadow_enabled)
	assert(Engine.max_fps == 60)
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.5))
	scene._load_settings()
	assert(scene.sound_volume == 0.0, "Discard must restore saved settings")
	assert(scene.frame_limit == 30 and Engine.max_fps == 30)
	assert(not scene.shadows_enabled and not sun.shadow_enabled)
	for cue in ["sword", "dodge", "hurt"]:
		scene.player.play_sound(cue)
		assert(scene.player._sound.stream.get_length() > 0.0)
	var config := ConfigFile.new()
	config.set_value("settings", "camera_sensitivity", "invalid")
	config.set_value("settings", "sound_volume", 30)
	config.set_value("settings", "camera_distance", -100)
	config.set_value("settings", "shadows_enabled", "invalid")
	config.set_value("settings", "frame_limit", 0)
	assert(config.save(scene.SETTINGS_PATH) == OK)
	scene._load_settings()
	assert(scene.camera_sensitivity == 1.0 and scene.sound_volume == 1.0)
	assert(scene.camera_distance == 4.0)
	assert(scene.frame_limit == 60 and Engine.max_fps == 60, "Invalid limits must not remove the cap")
	assert(scene.shadows_enabled and sun.shadow_enabled, "Invalid shadow settings must use default")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.SETTINGS_PATH))
	print("PASS: settings controls, pause, camera scaling, save/reload, discard, mute, sound streams, invalid values")
	paused = false
	await create_timer(0.4).timeout
	scene.queue_free()
	await process_frame
	quit()
