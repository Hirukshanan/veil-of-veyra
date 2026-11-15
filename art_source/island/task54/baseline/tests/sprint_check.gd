extends SceneTree
func _initialize():
	call_deferred("_run")
func _run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var hero = scene.player
	hero.set_physics_process(false)
	hero.toggle_sprint()
	assert(not hero.sprint_enabled)
	scene._resume()
	scene.find_child("SprintButton", true, false).pressed.emit()
	assert(hero.sprint_enabled)
	assert(hero._sprint_speed(1.0, 1.0) == hero.SPRINT_SPEED and hero.stamina == 75.0)
	assert(hero._sprint_speed(3.0, 1.0) == hero.MOVE_SPEED and hero.stamina == 0.0 and not hero.sprint_enabled)
	hero.toggle_sprint()
	assert(not hero.sprint_enabled)
	hero._sprint_speed(2.0, 0.0)
	assert(hero.stamina == 36.0)
	hero.toggle_sprint()
	hero.attack()
	assert(not hero.sprint_enabled)
	hero.cancel_swing()
	hero._attack_cooldown = 0.0
	hero.toggle_sprint()
	hero.dodge()
	assert(not hero.sprint_enabled)
	hero._dodge_time = 0.0
	hero.toggle_sprint()
	scene._pause_game()
	assert(not hero.sprint_enabled)
	var value: float = hero.stamina
	await create_timer(0.1, true).timeout
	assert(hero.stamina == value)
	scene.queue_free()
	await process_frame
	paused = false
	print("PASS: sprint speed, depletion, restart threshold, recovery, attack/dodge/menu cancellation and paused stamina")
	quit()
