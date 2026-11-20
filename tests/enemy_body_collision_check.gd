extends SceneTree

const CANDIDATE := preload("res://scenes/island_candidate.tscn")
const GROVE := preload("res://scripts/chapter_one_region.gd").GROVE_CENTER

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var game := CANDIDATE.instantiate()
	root.add_child(game)
	while not game.placement_ready:
		await physics_frame
	game._resume()
	var hero: CharacterBody3D = game.player
	hero.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):
		enemy.set_physics_process(false)
	var center: Vector3 = game.landscape.ground_point(GROVE) + Vector3.UP * .18
	var across := Vector3(0, 0, -6.0)
	for id in ["CampDemon3", "CampDemon2", "DemonFox", "DemonBoar"]:
		var enemy := game.get_node(id) as CharacterBody3D
		assert(enemy != null and enemy.health > 0)
		enemy.rotation.y = 0.0
		hero.global_position = center + Vector3.BACK * 3.0
		enemy.global_position = center
		await physics_frame
		await physics_frame
		_check_blocking(hero, enemy, across)

		hero.global_position = center
		enemy.global_position = center + Vector3.BACK * 3.0
		await physics_frame
		await physics_frame
		_check_blocking(enemy, hero, across)

		if id == "CampDemon2":
			await _check_weapon_hurtbox(enemy, hero, center)
		elif id == "DemonBoar":
			await _check_charge(enemy, hero, center)
		var corpse_position := enemy.global_position
		enemy.take_damage(10000)
		await physics_frame
		await physics_frame
		var step := corpse_position - hero.global_position
		assert(hero.move_and_collide(step) == null, "Defeated enemy left a blocking body: " + id)
		print("PASS: ", id, " blocks the hero in both directions and clears on death")
	game.queue_free()
	await process_frame
	await create_timer(.25).timeout
	quit()

func _check_blocking(mover: CharacterBody3D, blocker: CharacterBody3D, travel: Vector3) -> void:
	var anchor := blocker.global_position
	var hit := mover.move_and_collide(travel)
	assert(hit != null and hit.get_collider() == blocker, "Expected a real contact with " + blocker.name)
	var stopped := mover.global_position
	assert(anchor.is_equal_approx(blocker.global_position), "Body contact must not push the other actor")
	for repeat in range(8):
		mover.move_and_collide(travel.normalized() * .08)
	assert(stopped.distance_to(mover.global_position) < .02, "Repeated contact must stay stable")

func _check_weapon_hurtbox(warg, hero, center: Vector3) -> void:
	warg.global_position = center
	hero.global_position = center + Vector3.BACK * 2.35
	hero.rotation.y = 0.0
	await physics_frame
	await physics_frame
	var health: int = warg.health
	hero.attack()
	await create_timer(.22, false, true).timeout
	assert(warg.health == health - 1)
	hero._attack_cooldown = 0.0
	hero.heavy_attack()
	await create_timer(.70, false, true).timeout
	assert(warg.health == health - 5)
	hero._perform_spirit_burst()
	assert(warg.health == health - 8)
	print("PASS: Warg body changes preserve light, heavy, and Spirit Burst weapon hits")

func _check_charge(boar, hero, center: Vector3) -> void:
	hero.global_position = center
	boar.global_position = center + Vector3.BACK * 5.0
	boar._home = boar.global_position
	boar.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame
	var health: int = hero.health
	boar._enter(boar.State.WARNING)
	boar.set_physics_process(true)
	for frame in range(160):
		await physics_frame
		if boar.state == boar.State.RECOVERY:
			break
	assert(boar.state == boar.State.RECOVERY and hero.health == health - 18,
		"Charge body contact must preserve the single approved damage hit")
	assert(boar.global_position.z > hero.global_position.z + 1.6)
	boar.set_physics_process(false)
	print("PASS: Elite Boar charge blocks at the hero, deals 18 damage once, and enters recovery")
