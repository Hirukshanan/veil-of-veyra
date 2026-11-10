extends SceneTree
func _initialize():
	call_deferred("_run")
func _run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var nav = load("res://scripts/island_exploration.gd")
	assert(nav.direction_hint(Vector3.ZERO, Vector3(0, 0, -10), Basis.IDENTITY) == "Ahead 10m")
	assert(nav.direction_hint(Vector3.ZERO, Vector3(10, 0, 0), Basis.IDENTITY) == "Right 10m")
	assert(nav.direction_hint(Vector3.ZERO, Vector3(0, 0, 10), Basis.IDENTITY) == "Behind 10m")
	assert(nav.direction_hint(Vector3.ZERO, Vector3(-10, 0, 0), Basis.IDENTITY) == "Left 10m")
	assert(nav.direction_hint(Vector3.ZERO, Vector3(0, 0, -10), Basis(Vector3.UP, PI)) == "Behind 10m")
	assert(nav.direction_hint(Vector3.ZERO, Vector3(0, 100, 1), Basis.IDENTITY) == "Nearby")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._update_objective()
	assert("Wolves" in scene.status_label.text and "m" in scene.status_label.text)
	for enemy in get_nodes_in_group("lock_targets"):
		enemy.take_damage(1000)
	scene._update_objective()
	assert("Seal fragments" in scene.status_label.text)
	scene.seal_fragments.restore([0,1,2])
	scene._update_objective()
	assert("Lantern" in scene.status_label.text)
	assert("Water rescue: Beach" in scene._journal_text())
	var map = scene.get_node("IslandExploration")
	map.player.position = map.CHECKPOINTS[1]
	map._physics_process(0.01)
	assert("Water rescue: Forest" in scene._journal_text())
	scene._spawn_boss()
	scene._update_objective()
	assert("Dragon" in scene.status_label.text)
	scene.queue_free()
	await process_frame
	paused = false
	print("PASS: camera-relative bearings, vertical distance exclusion, objective progression and bound-waystone journal")
	quit()
