extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://campaign.cfg"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://campaign.cfg.bak"))
	for chapter in range(3):
		var scene = load("res://scenes/main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		await process_frame
		assert(scene.chapter == chapter)
		assert(scene.remaining_enemies == 3 + chapter * 2)
		scene._resume()
		var hero = scene.player
		var spawn: Vector3 = hero.position
		hero.position = scene.lantern.position
		scene._interact_lantern()
		assert(not scene.boss_spawned, "Enemies must be cleared before lighting")
		hero.position = spawn
		var enemies: Array = []
		for child in scene.get_children():
			if child.get_script() == scene.ENEMY_SCRIPT:
				assert(child.position.distance_to(hero.position) >= 5.0, "Enemies must spawn clear of the player")
				enemies.append(child)
				child.set_physics_process(false)
		var enemy = enemies[0]
		var kinds: Array = []
		for mob in enemies:
			kinds.append(mob.kind)
		assert(kinds.has(scene.ENEMY_SCRIPT.Kind.SCOUT))
		assert(kinds.has(scene.ENEMY_SCRIPT.Kind.BRUTE) == (chapter > 0))
		hero.position = Vector3(0, 0, 4)
		hero.rotation = Vector3.ZERO
		enemy.position = Vector3(0, 0, 2.8)
		await physics_frame
		await physics_frame
		var before := int(enemy.health)
		hero.attack()
		await physics_frame
		await physics_frame
		assert(enemy.health == before - 1, "Sword must damage overlapping enemy")
		var yaw := float(hero._camera_pivot.global_rotation.y)
		hero.rotation.y = 1.0
		await physics_frame
		assert(absf(hero._camera_pivot.global_rotation.y - yaw) < 0.01, "Camera must not inherit body turn")
		hero.dodge()
		var hp := int(hero.health)
		hero.take_damage(8)
		assert(hero.health == hp, "Dodge must protect against damage")
		for mob in enemies:
			mob.take_damage(100)
		await process_frame
		assert(not scene.boss_spawned, "Clearing enemies must unlock the lantern, not auto-spawn the boss")
		hero.set_physics_process(false)
		hero.position = Vector3(0, 0, -10)
		scene._interact_lantern()
		assert(not scene.boss_spawned, "Lantern interaction must require proximity")
		hero.position = scene.lantern.position
		scene._pause_game()
		scene._interact_lantern()
		assert(not scene.boss_spawned, "Paused interaction must not spawn a boss")
		scene._resume()
		assert(not scene.interact_button.disabled and scene.interact_button.visible)
		if chapter == 1:
			scene.interact_button.pressed.emit()
		var interact := InputEventKey.new()
		interact.physical_keycode = KEY_E
		interact.pressed = true
		Input.parse_input_event(interact)
		await process_frame
		await process_frame
		interact = InputEventKey.new()
		interact.physical_keycode = KEY_E
		interact.pressed = false
		Input.parse_input_event(interact)
		assert(scene.boss_spawned)
		assert(scene.lantern_lit and scene.lantern_flame.visible)
		scene._interact_lantern()
		assert(scene.find_children("Tidewraith Dragon*", "", false, false).size() == 1, "Repeated interaction must not duplicate the boss")
		var boss = scene.get_node("Tidewraith Dragon")
		assert(boss.health == 34 + chapter * 14)
		boss.set_physics_process(false)
		boss.position = Vector3.ZERO
		hero.position = Vector3(0, 0, -5)
		hero.set_physics_process(false)
		hero._invulnerability_time = 0
		boss._physics_process(0.01)
		assert(boss._state == boss.AttackState.WINDUP)
		boss._physics_process(1.0)
		assert(boss._state == boss.AttackState.BREATH)
		boss._physics_process(0.01)
		assert(hero.health == hp - 16, "Breath must damage player in cone")
		boss.take_damage(int(boss.max_health / 2))
		assert(boss.enraged and "ENRAGED" in scene.boss_name_label.text)
		boss.take_damage(1000)
		await process_frame
		assert(scene.game_finished and paused)
		assert(scene.chapter == mini(chapter + 1, 2))
		assert(scene.completed == (chapter == 2))
		paused = false
		scene.queue_free()
		await process_frame
	print("PASS: three waves, sword hits, dodge, camera, lantern gates, keyboard/button interaction, single boss spawn, boss combat and ending")
	var retry = load("res://scenes/main.tscn").instantiate()
	root.add_child(retry)
	current_scene = retry
	await process_frame
	retry._resume()
	retry.player.take_damage(1000)
	assert(retry.game_finished and paused)
	retry._reload()
	await process_frame
	await process_frame
	assert(current_scene.player.health == current_scene.player.max_health)
	assert(current_scene.potions == 3)
	assert(not current_scene.lantern_lit and not current_scene.boss_spawned)
	print("PASS: death and actual scene retry restore health and consumables")
	paused = false
	await create_timer(0.4).timeout
	quit()
