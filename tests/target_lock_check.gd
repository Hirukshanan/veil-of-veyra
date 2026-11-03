extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for frame in range(4):
		await physics_frame

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var hero = scene.player
	var enemies: Array = []
	for child in scene.get_children():
		if child.get_script() == scene.ENEMY_SCRIPT:
			child.set_physics_process(false)
			child.position = Vector3(30, 0, 0)
			enemies.append(child)
	hero.toggle_target_lock()
	assert(not is_instance_valid(hero.locked_target), "Camp must not enable target lock")
	scene._resume()
	hero.position = Vector3.ZERO
	enemies[0].position = Vector3(0.8, 0, 0)
	enemies[0].health = 0
	var target = enemies[1]
	target.position = Vector3(1.2, 0, 0)
	target.health = 100
	enemies[2].position = Vector3(5, 0, 0)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_TAB
	event.pressed = true
	Input.parse_input_event(event)
	await _settle()
	event = InputEventKey.new()
	event.physical_keycode = KEY_TAB
	event.pressed = false
	Input.parse_input_event(event)
	assert(hero.locked_target == target, "Nearest living enemy must be selected")
	assert(hero._lock_marker.visible)
	assert(absf(angle_difference(hero.rotation.y, -PI / 2.0)) < 0.01)
	assert(hero._camera_pivot.rotation.y < 0, "Camera must turn toward the target")
	hero.attack()
	await _settle()
	assert(target.health == 100 - hero.attack_damage, "Locked facing must produce a real sword overlap hit")
	hero.toggle_target_lock()
	assert(not is_instance_valid(hero.locked_target) and not hero._lock_marker.visible)
	var button = scene.find_child("TargetLockButton", true, false)
	button.pressed.emit()
	assert(hero.locked_target == target)
	hero._rotate_camera(Vector2(10, 0))
	assert(not is_instance_valid(hero.locked_target), "Manual camera input must release lock")
	hero.toggle_target_lock()
	target.position = Vector3(20, 0, 0)
	await _settle()
	assert(not is_instance_valid(hero.locked_target), "Out-of-range target must release lock")
	target.position = Vector3(1.2, 0, 0)
	hero.toggle_target_lock()
	target.queue_free()
	await _settle()
	assert(not is_instance_valid(hero.locked_target), "Freed target must be safely released")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.position = Vector3(30, 0, 0)
	hero.toggle_target_lock()
	assert(not is_instance_valid(hero.locked_target), "No eligible target must leave lock off")
	scene._spawn_boss()
	var boss = scene.get_node("Tidewraith Dragon")
	boss.set_physics_process(false)
	boss.position = Vector3(0, 0, -4)
	hero.toggle_target_lock()
	assert(hero.locked_target == boss)
	scene._pause_game()
	assert(not is_instance_valid(hero.locked_target))
	scene._resume()
	hero.toggle_target_lock()
	hero._invulnerability_time = 0
	hero.take_damage(1000)
	assert(not is_instance_valid(hero.locked_target) and not hero._lock_marker.visible)
	print("PASS: keyboard/button lock, nearest living target, facing/camera, real sword hit, toggle/manual camera/range/free/menu/death release, no target and boss lock")
	paused = false
	await create_timer(0.4).timeout
	scene.queue_free()
	await process_frame
	quit()
