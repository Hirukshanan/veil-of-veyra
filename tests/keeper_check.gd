extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _press(scene: Node, caption: String) -> void:
	for button in scene.menu_box.get_children():
		if button is Button and button.text == caption:
			button.pressed.emit()
			return
	assert(false, "Missing dialogue choice: " + caption)

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	for chapter in range(1):
		var config := ConfigFile.new()
		config.set_value("campaign", "chapter", chapter)
		assert(config.save("user://campaign.cfg") == OK)
		var scene = load("res://scenes/main.tscn").instantiate()
		root.add_child(scene)
		await process_frame
		var keeper = scene.keeper
		assert(not keeper is Node3D and keeper.get_child_count() == 0, "Quest must not spawn an NPC or visual children")
		scene.player.set_physics_process(false)
		assert(not keeper.accepted and keeper.reward() == 0)
		scene._interact_world()
		assert(not keeper.accepted, "Cannot accept from initial camp menu")
		scene._resume()
		scene.player.position = Vector3(0, 0, -10)
		scene.player._attack_buffer = 0.1
		scene.find_child("QuestScrollButton", true, false).pressed.emit()
		assert(paused and scene.journal_open and scene.player._attack_buffer == 0)
		_press(scene, "Accept: The Western Watch (+15 shards)")
		assert(keeper.accepted and paused and not keeper.report())
		assert("ACTIVE" in scene._journal_text())
		var expected: int = keeper.remaining()
		assert(expected > 0)
		for enemy in get_nodes_in_group("lock_targets"):
			if enemy.get_script() == scene.ENEMY_SCRIPT and enemy._home.distance_to(keeper.CAMP) < 6:
				enemy.position = Vector3(0, 0, 10)
		assert(keeper.remaining() == expected, "Bounty follows home camp, not current chase position")
		for enemy in get_nodes_in_group("lock_targets"):
			if enemy.get_script() == scene.ENEMY_SCRIPT and enemy._home.distance_to(keeper.CAMP) < 6:
				enemy.take_damage(10000)
		assert(keeper.remaining() == 0 and "RETURN" in keeper.journal_text())
		scene._show_journal()
		_press(scene, "Complete: The Western Watch")
		assert(keeper.reported and keeper.reward() == 15 and scene.shards == 0)
		assert(not keeper.report(), "Reporting twice must not grant another bonus")

		scene._toggle_pause()
		assert(not paused)
		for enemy in get_nodes_in_group("lock_targets"):
			if enemy.get_script() == scene.ENEMY_SCRIPT: enemy.take_damage(10000)
		scene.player.position = scene.lantern.position
		scene._resume()
		scene._interact_lantern()
		scene._on_boss_defeated()
		var reward := 80 + 15
		assert(scene.shards == reward)
		scene._on_boss_defeated()
		assert(scene.shards == reward)
		assert(config.load("user://campaign.cfg") == OK)
		assert(config.get_value("campaign", "shards") == reward)
		scene.queue_free()
		await process_frame
		paused = false
		var retry = load("res://scenes/main.tscn").instantiate()
		root.add_child(retry)
		await process_frame
		assert(retry.keeper.accepted and retry.keeper.reported and retry.shards == reward)
		retry.queue_free()
		await process_frame
		paused = false
	print("PASS: Remote quest scroll, touch acceptance/completion, combat pause, acceptance, camp identity, report guards, single victory payout, saved shards and persisted bounty")
	quit()
