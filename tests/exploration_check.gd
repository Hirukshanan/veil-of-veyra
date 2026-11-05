extends SceneTree
func _initialize():
	call_deferred("_run")
func _run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var exploration = scene.get_node("IslandExploration")
	var hero = scene.player
	hero.set_physics_process(false)
	scene._resume()
	await physics_frame
	var space = scene.get_world_3d().direct_space_state
	for point in exploration.CAMPS + exploration.CHECKPOINTS:
		var result = space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 4, point + Vector3.DOWN * 4, 1))
		assert(not result.is_empty() and absf(result.position.y) < 0.1)
	var terrain = preload("res://scripts/island_terrain.gd")
	for index in range(32):
		var angle := index * TAU / 32.0
		var point := Vector3(cos(angle), 0, sin(angle)) * terrain.coast_radius(angle, 42.0)
		var shore = space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 4, point + Vector3.DOWN * 4, 1))
		assert(not shore.is_empty() and absf(shore.position.y + 0.8) < 0.1, "Entire irregular beach must have matching collision")
	for route in terrain.trails():
		for point in route:
			var ground = space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 4, point + Vector3.DOWN * 4, 1))
			assert(not ground.is_empty() and absf(ground.position.y) < 0.1, "Curved trails must stay on the combat plateau")
	var beach = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(42, 4, 0), Vector3(42, -4, 0), 1))
	assert(not beach.is_empty() and beach.position.y < -0.5 and beach.position.y > -1.2)
	hero.position = exploration.CHECKPOINTS[1]
	exploration._physics_process(0.1)
	assert(exploration.checkpoint_index == 1)
	var health = hero.health
	hero.position = Vector3(47, -1.3, 0)
	hero._invulnerability_time = 0
	exploration._physics_process(0.1)
	assert(hero.position == hero.rescue_position and hero.health == health - 20)
	var enemy = scene.ENEMY_SCRIPT.new()
	enemy.position = Vector3(-18, 0, 12)
	enemy.target = hero
	scene.add_child(enemy)
	enemy.set_physics_process(false)
	hero.position = Vector3(0, 0, 27)
	enemy._physics_process(0.01)
	assert(not enemy._alert)
	hero.position = enemy.position + Vector3(0, 0, 5)
	enemy._physics_process(0.01)
	assert(enemy._alert)
	hero.position = Vector3(0, 0, -30)
	enemy._physics_process(0.01)
	assert(not enemy._alert and enemy._windup == 0.0)
	scene.queue_free()
	await process_frame
	paused = false
	print("PASS: expanded camp/checkpoint ground, sloped beach, bound water rescue, health penalty, local aggro and leash")
	quit()
