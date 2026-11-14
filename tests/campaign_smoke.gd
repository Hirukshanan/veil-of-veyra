extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1", "Run only with an isolated test APPDATA directory")
	if FileAccess.file_exists("user://campaign.cfg"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://campaign.cfg"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://campaign.cfg.bak"))
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(paused, "Campaign must begin at camp")
	scene._resume()
	assert(not paused)
	scene.player.set("health", 40)
	scene._heal()
	assert(scene.player.get("health") == 90)
	assert(scene.potions == 2)
	scene._pause_game()
	assert(paused)
	scene._resume()
	scene.shards = 0
	for enemy in get_nodes_in_group("combat_enemies"): enemy.take_damage(1000)
	await process_frame
	scene.player.position = scene.lantern.position
	scene.seal_fragments.restore([0,1,2])
	scene._interact_lantern()
	scene.get_node("Tidewraith Dragon").take_damage(10000)
	assert(scene.completed and not scene.game_finished)
	assert(scene.shards == 80)
	assert(paused)
	scene._upgrade(true)
	assert(scene.blade_level == 1)
	assert(scene.shards == 60)
	scene._load_progress()
	assert(scene.completed and scene.blade_level == 1)
	print("PASS: camp, resume, healing, pause, rewards, upgrades, and save reload")
	paused = false
	scene.queue_free()
	quit()
