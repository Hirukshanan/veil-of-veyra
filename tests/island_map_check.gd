extends SceneTree
func _initialize():
	call_deferred("_run")
func _run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._show_island_map()
	assert(scene.menu_box.find_child("IslandMap", false, false) == null, "Map must not bypass camp")
	scene._resume()
	scene._pause_game()
	assert(scene.menu_box.find_children("*", "Button", false, false).any(func(button): return button.text == "Island Map"))
	scene._show_island_map()
	var map = scene.menu_box.get_node("IslandMap")
	assert(paused and scene.pause_menu_open)
	assert(map.camps_cleared == [false, false, false])
	assert(map.player_position == scene.player.global_position)
	for enemy in get_nodes_in_group("combat_enemies"):
		if enemy.get_script() == scene.ENEMY_SCRIPT and enemy._home.distance_to(load("res://scripts/island_exploration.gd").CAMPS[0]) < 6.0:
			enemy.take_damage(1000)
	scene._show_island_map()
	map = scene.menu_box.get_node("IslandMap")
	assert(map.camps_cleared == [true, false, false])
	assert(scene.menu_box.get_child(1) is Button and scene.menu_box.get_child(2) == map)
	scene._toggle_pause()
	assert(not paused)
	scene.queue_free()
	await process_frame
	print("PASS: map access guard, pause entry, player snapshot, cleared camp state, return placement and Escape resume")
	quit()
