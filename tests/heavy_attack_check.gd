extends SceneTree
func _initialize():
	call_deferred("_run")

func _reset(hero):
	hero.cancel_swing()
	hero._attack_cooldown = 0.0
	hero._dodge_time = 0.0
	hero._dodge_cooldown = 0.0
	hero._hit_time = 0.0
	hero._invulnerability_time = 0.0
	hero.stamina = 100.0

func _run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var hero = scene.player
	hero.set_physics_process(false)
	hero.heavy_attack()
	assert(hero.stamina == 100, "Menus must reject attacks")
	scene._resume()
	hero.position = Vector3.ZERO
	hero.rotation = Vector3.ZERO
	for enemy in get_nodes_in_group("lock_targets"):
		enemy.set_physics_process(false)
		enemy.position = Vector3(20, 0, 20)
	var targets: Array = []
	for point in [Vector3(0, 0, -1.5), Vector3(2, 0, 0), Vector3(0, 0, 1.5), Vector3(0, 0, -3.2), Vector3(0, 2, -1.5)]:
		var enemy = scene.ENEMY_SCRIPT.new()
		enemy.health = 100
		enemy.position = point
		enemy.target = hero
		scene.add_child(enemy)
		enemy.set_physics_process(false)
		targets.append(enemy)
	await physics_frame
	await physics_frame
	var front = targets[0]
	hero.stamina = 39
	hero.heavy_attack()
	assert(hero.stamina == 39 and hero._heavy_time == 0)
	hero.stamina = 100
	hero.attack_damage = 2
	scene.find_child("HeavyAttackButton", true, false).pressed.emit()
	assert(hero.stamina == 60 and hero._heavy_warning.visible and hero.combo_step == 0)
	hero.heavy_attack()
	assert(hero.stamina == 60, "No repeat spend during recovery")
	hero._sprint_speed(1, 0)
	assert(hero.stamina == 60, "Heavy attack must suspend stamina recovery")
	await create_timer(0.15).timeout
	assert(front.health == 100, "Charge must not deal early damage")
	await create_timer(0.6).timeout
	assert(front.health == 92 and front._hit_time >= 0.6)
	assert(not hero._heavy_warning.visible and hero.spirit == 25)
	for target in targets.slice(1):
		assert(target.health == 100, "Side, rear, distant and elevated targets must be excluded")
	for cancellation in ["dodge", "hurt", "menu"]:
		_reset(hero)
		hero.heavy_attack()
		if cancellation == "dodge":
			hero.dodge()
		elif cancellation == "hurt":
			hero.take_damage(1)
		else:
			scene._pause_game()
			scene._resume()
		assert(not hero._heavy_warning.visible and hero._heavy_time == 0 and hero.stamina == 60)
		await create_timer(0.75).timeout
		assert(front.health == 92, "Cancelled attack must never resolve later")
	_reset(hero)
	hero.heavy_attack()
	paused = true
	await create_timer(0.75, true).timeout
	assert(front.health == 92, "Pause must freeze contact")
	paused = false
	await create_timer(0.75).timeout
	assert(front.health == 84)
	_reset(hero)
	hero.health = 0
	hero.heavy_attack()
	assert(hero.stamina == 100)
	scene.queue_free()
	await process_frame
	print("PASS: heavy touch input, stamina cost/gating, delayed 4x damage, forward arc, stagger, spirit, repeat guard, dodge/hit/menu cancellation, pause and death")
	quit()
