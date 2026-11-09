extends SceneTree
func _initialize():
	call_deferred("_run")
func _run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var world = scene.get_node("IslandExploration")
	var hero = scene.player
	hero.set_physics_process(false)
	assert(world.discovered == [true, false, false])
	assert(not world.travel_to(-1) and not world.travel_to(3))
	assert(not world.travel_to(1))
	scene._resume()
	hero.position = world.CHECKPOINTS[1]
	world._physics_process(0)
	assert(world.discovered == [true, true, false])
	for enemy in get_nodes_in_group("lock_targets"):
		enemy.set_physics_process(false)
		enemy.position = Vector3(-30, 0, -30)
	var enemy = get_nodes_in_group("lock_targets")[0]
	hero.health = 70
	hero.stamina = 55
	hero.velocity = Vector3(2, 0, 3)
	var potions: int = scene.potions
	enemy.position = hero.position + Vector3(3, 0, 0)
	assert(world.travel_block_reason(0) == "Enemies are too close")
	enemy.position = world.CHECKPOINTS[0]
	assert(world.travel_block_reason(0) == "Destination is unsafe")
	enemy.position = Vector3(-30, 0, -30)
	hero._attack_cooldown = 0.3
	assert(not world.travel_to(0))
	hero._attack_cooldown = 0
	scene._pause_game()
	scene._show_island_map()
	var travel_button: Button
	for child in scene.menu_box.get_children():
		if child is Button and child.text == "Travel to Beach":
			travel_button = child
	assert(travel_button != null and not travel_button.disabled)
	travel_button.pressed.emit()
	assert(not paused and hero.position.distance_to(world.CHECKPOINTS[0]) < 0.2)
	assert(hero.velocity == Vector3.ZERO and world.checkpoint_index == 0)
	assert(hero.health == 70 and hero.stamina == 55 and scene.potions == potions)
	assert(not world.travel_to(0))
	assert(hero.rescue_position == world.CHECKPOINTS[0] + Vector3.UP)
	var boss = scene.BOSS_SCRIPT.new()
	boss.position = Vector3(0, 0, -25)
	boss.target = hero
	scene.add_child(boss)
	boss.set_physics_process(false)
	assert(world.travel_block_reason(1) == "Defeat the dragon before travelling")
	scene.queue_free()
	await process_frame
	paused = false
	var retry = load("res://scenes/main.tscn").instantiate()
	root.add_child(retry)
	await process_frame
	assert(retry.get_node("IslandExploration").discovered == [true, true, false])
	retry.queue_free()
	await process_frame
	paused = false
	print("PASS: persistent discovery, invalid/locked destinations, combat/source/destination/boss gates, touch travel, rescue binding and no resource refill")
	quit()
