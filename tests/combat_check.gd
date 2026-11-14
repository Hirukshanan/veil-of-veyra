extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	var hero = scene.player
	hero.set_physics_process(false)
	var enemy
	for child in scene.get_children():
		if child.get_script() == scene.ENEMY_SCRIPT:
			child.set_physics_process(false)
			if enemy == null:
				enemy = child
	hero.position = Vector3(0, 0, 4)
	hero.rotation = Vector3.ZERO
	enemy.position = Vector3(0, 0, 2.8)
	# This fixture tests contact timing, not the distant camp's return-home leash.
	enemy._home = enemy.position
	enemy.health = 100
	await physics_frame
	await physics_frame
	var initial_health := int(hero.health)
	enemy._physics_process(0.01)
	assert(enemy._warning.visible and hero.health == initial_health, "Attack must warn before damage")
	hero.position.x = 4
	enemy._physics_process(0.6)
	assert(hero.health == initial_health, "Leaving the warning must avoid damage")
	hero.position.x = 0
	enemy._physics_process(1.0)
	enemy._physics_process(0.6)
	assert(hero.health == initial_health - 8, "Staying in range must take damage")
	enemy._physics_process(1.0)
	assert(enemy._warning.visible)
	enemy.take_damage(1)
	assert(not enemy._warning.visible and enemy._windup == 0, "Sword hit must interrupt windup")
	enemy.health = 100
	await physics_frame
	await physics_frame
	hero.attack()
	await physics_frame
	assert(enemy.health == 100, "Sword must not hit during windup")
	hero.dodge()
	await create_timer(0.3).timeout
	assert(enemy.health == 100, "Dodge must cancel pending sword contact")
	hero._attack_cooldown = 0
	hero.attack()
	hero._invulnerability_time = 0
	hero.take_damage(1)
	await create_timer(0.3).timeout
	assert(enemy.health == 100, "Taking damage must cancel pending contact")
	hero._attack_cooldown = 0
	hero.attack()
	scene._show_camp()
	scene._resume()
	await create_timer(0.3).timeout
	assert(enemy.health == 100, "Opening a menu must cancel pending contact")
	hero.combo_step = 0
	for step in range(1, 4):
		hero._attack_cooldown = 0
		hero.attack()
		await create_timer(0.25).timeout
		await physics_frame
		await physics_frame
		assert(hero.combo_step == step)
	assert(enemy.health == 100 - hero.attack_damage * 4, "Third hit must deal double damage")
	hero._physics_process(1.0)
	assert(hero.combo_step == 0, "Waiting must reset combo")
	hero.attack()
	await create_timer(0.25).timeout
	await physics_frame
	await physics_frame
	assert(hero.combo_step == 1)
	print("PASS: attack warning, range escape, delayed damage, hit interruption, combo damage and timeout")
	paused = false
	await create_timer(0.4).timeout
	quit()
