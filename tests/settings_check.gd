extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.cfg"))
	var scene = preload("res://tests/legacy_campaign_fixture.gd").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.camera_sensitivity == 1.0 and scene.sound_volume == 0.7)
	scene._show_settings(scene._show_camp)
	assert(paused)
	assert(scene.frame_limit == 60 and Engine.max_fps == 60)
	scene.settings_screen.select_tab("Graphics & Sound")
	var frame_choice = scene.settings_screen.find_child("FrameLimitChoice",true,false)
	frame_choice.select(0)
	frame_choice.item_selected.emit(0)
	assert(scene.frame_limit == 30 and Engine.max_fps == 30)
	var sun: DirectionalLight3D = scene.find_children("*", "DirectionalLight3D", true, false)[0]
	assert(sun.shadow_enabled and scene.shadows_enabled)
	var toggle = scene.settings_screen.find_child("ShadowsToggle",true,false)
	toggle.button_pressed = false
	assert(not sun.shadow_enabled and not scene.shadows_enabled)
	scene.settings_screen.sliders.sound_volume.value=0
	scene.settings_screen.select_tab("Camera")
	scene.settings_screen.sliders.camera_sensitivity.value=1.5
	scene.settings_screen.sliders.camera_distance.value=8
	assert(scene.player._camera_arm.spring_length == 8.0)
	assert(scene.player.camera_sensitivity == 1.5)
	assert(AudioServer.is_bus_mute(0))
	var yaw := float(scene.player._camera_pivot.rotation.y)
	scene.player._rotate_camera(Vector2(100, 0))
	assert(is_equal_approx(scene.player._camera_pivot.rotation.y, yaw - 0.75))
	assert(scene._save_settings() == OK)
	scene.queue_free()
	await process_frame
	scene = preload("res://tests/legacy_campaign_fixture.gd").instantiate()
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
	config.set_value("settings", "hud_scale", 999)
	config.set_value("settings", "invert_y", "invalid")
	config.set_value("settings", "left_handed", 1)
	assert(config.save(scene.SETTINGS_PATH) == OK)
	scene._load_settings()
	assert(scene.camera_sensitivity == 1.0 and scene.sound_volume == 1.0)
	assert(scene.hud_scale == 1.2 and not scene.invert_y and not scene.left_handed, "Invalid control settings must clamp/fall back safely")
	assert(scene.camera_distance == 4.0)
	assert(scene.frame_limit == 60 and Engine.max_fps == 60, "Invalid limits must not remove the cap")
	assert(scene.shadows_enabled and sun.shadow_enabled, "Invalid shadow settings must use default")
	_check_android_graphics(scene, sun)
	print("PASS: settings controls, pause, camera scaling, save/reload, discard, mute, sound streams, invalid values")
	paused = false
	await create_timer(0.4).timeout
	scene.queue_free()
	await process_frame
	quit()

func _check_android_graphics(scene, sun: DirectionalLight3D) -> void:
	var settings_path: String = scene.SETTINGS_PATH
	var backup_path := settings_path + ".bak"
	scene._load_settings(true)
	assert(scene.frame_limit == 30 and Engine.max_fps == 30)
	assert(not scene.shadows_enabled and not sun.shadow_enabled)
	assert(DirAccess.remove_absolute(settings_path) == OK)
	if FileAccess.file_exists(backup_path):
		assert(DirAccess.remove_absolute(backup_path) == OK)

	scene._load_settings(true)
	assert(scene.frame_limit == 30 and Engine.max_fps == 30, "Fresh Android installs use 30 FPS")
	assert(not scene.shadows_enabled and not sun.shadow_enabled, "Fresh Android installs start with shadows off")
	assert(not FileAccess.file_exists(settings_path), "Loading defaults must not write a settings file")

	scene._show_settings(scene._show_camp)
	scene.settings_screen.select_tab("Graphics & Sound")
	var frame_choice: OptionButton = scene.settings_screen.find_child("FrameLimitChoice", true, false)
	frame_choice.select(1)
	frame_choice.item_selected.emit(1)
	assert(scene.frame_limit == 60 and Engine.max_fps == 60)
	assert(not scene.shadows_enabled and not sun.shadow_enabled, "Selecting 60 FPS must leave shadows off")
	assert(scene._save_settings() == OK)

	scene.shadows_enabled = true
	assert(scene._save_settings() == OK)
	var saved_hash := FileAccess.get_sha256(settings_path)
	scene._load_settings(true)
	assert(scene.frame_limit == 60 and Engine.max_fps == 60)
	assert(scene.shadows_enabled and sun.shadow_enabled, "Existing shadow preferences must be applied")
	assert(FileAccess.get_sha256(settings_path) == saved_hash)

	assert(DirAccess.remove_absolute(settings_path) == OK)
	scene._load_settings(true)
	assert(scene.frame_limit == 60 and Engine.max_fps == 60)
	assert(not scene.shadows_enabled and not sun.shadow_enabled, "The saved backup must take precedence over defaults")
	assert(DirAccess.remove_absolute(backup_path) == OK)
	print("PASS: Android defaults, 60 FPS option, and saved graphics preferences")
