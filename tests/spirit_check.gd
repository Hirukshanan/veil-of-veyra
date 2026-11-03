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
	current_scene = scene
	await process_frame
	scene._resume()
	var hero = scene.player
	hero.set_physics_process(false)
	hero.position = Vector3.ZERO
	hero.rotation = Vector3.ZERO
	var enemies: Array = []
	for child in scene.get_children():
		if child.get_script() == scene.ENEMY_SCRIPT:
			child.set_physics_process(false)
			child.position = Vector3(30, 0, 0)
			child.health = 100
			enemies.append(child)
	await _settle()
	hero.attack()
	await create_timer(0.25).timeout
	await _settle()
	assert(hero.spirit == 0, "Missing must not charge spirit")
	hero.spirit_burst()
	assert(not hero._burst_requested)
	enemies[0].position = Vector3(0, 0, -1.2)
	enemies[1].position = Vector3(0.35, 0, -1.2)
	enemies[2].position = Vector3(6, 0, 0)
	await _settle()
	for swing in range(5):
		hero._attack_cooldown = 0
		hero.attack()
		await create_timer(0.25).timeout
		await _settle()
		assert(hero.spirit == mini(100, (swing + 1) * 25), "Crowd hits grant once per swing and charge caps at 100")
	hero._attack_cooldown = 0
	hero.spirit_burst()
	scene._pause_game()
	assert(not hero._burst_requested and hero.spirit == 100)
	hero.spirit_burst()
	assert(not hero._burst_requested, "Menus must reject bursts")
	scene._resume()
	var before := [int(enemies[0].health), int(enemies[1].health), int(enemies[2].health)]
	for enemy in enemies.slice(0, 2):
		enemy._windup = 0.4
		enemy._warning.show()
	var hp := int(hero.health)
	hero.set_physics_process(true)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_L
	event.pressed = true
	Input.parse_input_event(event)
	await _settle()
	event = InputEventKey.new()
	event.physical_keycode = KEY_L
	event.pressed = false
	Input.parse_input_event(event)
	hero.set_physics_process(false)
	assert(hero.spirit == 0 and hero.health == hp)
	for index in range(2):
		assert(enemies[index].health == before[index] - hero.attack_damage * 3)
		assert(enemies[index]._windup == 0 and not enemies[index]._warning.visible)
	assert(enemies[2].health == before[2], "Out-of-range enemies must not take burst damage")
	hero.spirit_burst()
	assert(not hero._burst_requested, "Spent charge must prevent repeat bursts")
	for enemy in enemies:
		enemy.position = Vector3(30, 0, 0)
	await _settle()
	hero.spirit = 100
	hero._attack_cooldown = 0
	scene.find_child("SpiritBurstButton", true, false).pressed.emit()
	hero._physics_process(0.01)
	assert(hero.spirit == 0, "An empty burst must still consume charge")
	hero.health = 0
	hero.spirit = 100
	hero._attack_cooldown = 0
	hero.spirit_burst()
	assert(not hero._burst_requested, "Dead players cannot burst")
	hero.health = 100
	await create_timer(0.4).timeout
	scene._reload()
	await process_frame
	await process_frame
	assert(current_scene.player.spirit == 0)
	print("PASS: miss/crowd/capped charge, pause cancellation, keyboard/button burst, area damage, interruption, no self-hit, resource/death guards and restart reset")
	current_scene.queue_free()
	await process_frame
	paused = false
	quit()
