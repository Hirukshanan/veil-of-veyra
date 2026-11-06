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
	for chapter in range(3):
		var config := ConfigFile.new()
		config.set_value("campaign", "chapter", chapter)
		assert(config.save("user://campaign.cfg") == OK)
		var scene = load("res://scenes/main.tscn").instantiate()
		root.add_child(scene)
		await process_frame
		var keeper = scene.keeper
		scene.player.set_physics_process(false)
		assert(not keeper.accepted and keeper.reward() == 0)
		scene._interact_world()
		assert(not keeper.accepted, "Cannot accept from initial camp menu")
		scene._resume()
		scene.player.position = Vector3.ZERO
		scene._interact_world()
		assert(not paused, "Dialogue needs proximity")
		scene.player.position = keeper.HOME + Vector3(0, 0, 2)
		scene._update_objective()
		assert(scene.interact_button.visible and scene.interact_button.text == "TALK [E]" and not scene.interact_button.disabled)
		scene.player._attack_buffer = 0.1
		scene.interact_button.pressed.emit()
		assert(paused and scene.pause_menu_open and scene.player._attack_buffer == 0)
		_press(scene, "Accept: The Western Watch")
		assert(keeper.accepted and not paused and not keeper.report())
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
		scene._interact_world()
		_press(scene, "Report: the western camp is clear")
		assert(keeper.reported and keeper.reward() == 15 and scene.shards == 0)
		assert(not keeper.report(), "Reporting twice must not grant another bonus")
		scene._interact_world()
		_press(scene, "Ask about the scattered relics")
		assert(paused and scene.pause_menu_open)
		_press(scene, "Back to the Keeper")
		scene._toggle_pause()
		assert(not paused)
		scene._on_boss_defeated()
		var reward := 40 + chapter * 20 + 15
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
		assert(not retry.keeper.accepted and not retry.keeper.reported and retry.shards == reward)
		retry.queue_free()
		await process_frame
		paused = false
	print("PASS: Keeper proximity, touch dialogue, combat pause, acceptance, camp identity, report guards, single victory payout, saved shards and hunt reset in all chapters")
	quit()
