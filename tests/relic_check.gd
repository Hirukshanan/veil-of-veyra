extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	for chapter in range(3):
		var config := ConfigFile.new()
		config.set_value("campaign", "chapter", chapter)
		assert(config.save("user://campaign.cfg") == OK)
		var scene = load("res://scenes/main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		await process_frame
		var hunt = scene.relic_hunt
		var hero = scene.player
		hero.set_physics_process(false)
		for child in scene.get_children():
			if child.get_script() == scene.ENEMY_SCRIPT:
				child.set_physics_process(false)
		assert(hunt.collected == 0 and hunt.relics.size() == 3)
		for relic in hunt.relics:
			assert(relic.position.length() < 12.0, "Relics must be reachable on the island")
		hero.position = hunt.relics[0].global_position
		await physics_frame
		await physics_frame
		assert(hunt.collected == 0, "Camp must not collect relics")
		scene._resume()
		await physics_frame
		await physics_frame
		assert(hunt.collected == 1 and hunt.reward() == 0)
		assert(scene.shards == 0, "Collection alone must not award currency")
		await physics_frame
		assert(hunt.collected == 1, "A relic must only count once")
		scene._pause_game()
		hero.position = hunt.relics[0].global_position
		await physics_frame
		await physics_frame
		assert(hunt.collected == 1, "Pause must freeze collection")
		scene._resume()
		if chapter == 0:
			hero.position = Vector3.ZERO
		else:
			for relic in hunt.relics.duplicate():
				hero.position = relic.global_position
				await physics_frame
				await physics_frame
			assert(hunt.collected == 3 and hunt.reward() == 20)
			await process_frame
			assert("3/3" in scene.relic_status.text)
		var reward := 40 + chapter * 20 + (20 if chapter > 0 else 0)
		scene._on_boss_defeated()
		assert(scene.shards == reward)
		scene._on_boss_defeated()
		assert(scene.shards == reward, "Victory must not award the bonus twice")
		assert(config.load("user://campaign.cfg") == OK)
		assert(config.get_value("campaign", "shards") == reward)
		scene._reload()
		await process_frame
		await process_frame
		assert(current_scene.relic_hunt.collected == 0)
		assert(current_scene.relic_hunt.relics.size() == 3)
		assert(current_scene.shards == reward)
		current_scene.queue_free()
		await process_frame
		paused = false
	print("PASS: relic placement, proximity pickup, camp/pause guards, single collection, optional/full rewards, persistence and reset")
	quit()
