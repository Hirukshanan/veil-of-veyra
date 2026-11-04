extends SceneTree
var defeats := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var world := Node3D.new()
	root.add_child(world)
	var enemy = load("res://scripts/enemy.gd").new()
	world.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.defeated.connect(func(): defeats += 1)
	var visual = enemy._visual
	assert(visual.animator != null)
	enemy.take_damage(1)
	enemy._process(0.01)
	assert(visual._materials[0].emission_enabled)
	enemy._hit_time = 0.0
	enemy._process(0.01)
	assert(not visual._materials[0].emission_enabled)
	enemy.take_damage(100)
	enemy.take_damage(100)
	assert(defeats == 1 and visual.get_parent() == world)
	assert(visual.find_children("*", "CollisionObject3D", true, false).is_empty())
	await process_frame
	await process_frame
	assert(not is_instance_valid(enemy))
	assert(is_instance_valid(visual) and visual.is_in_group("enemy_remains"))
	paused = true
	var pose: Transform3D = visual.transform
	await create_timer(0.15, true).timeout
	assert(visual.transform == pose)
	paused = false
	await create_timer(0.95).timeout
	assert(not is_instance_valid(visual), "Defeat visuals must expire")
	for index in range(10):
		var extra = load("res://scripts/enemy.gd").new()
		world.add_child(extra)
		extra.take_damage(100)
	assert(get_nodes_in_group("enemy_remains").size() <= 8)
	world.queue_free()
	await process_frame
	await process_frame
	assert(get_nodes_in_group("enemy_remains").is_empty())
	print("PASS: wolf flash/reset, single defeat, immediate enemy removal, non-colliding remains, pause, expiry, cap and scene cleanup")
	quit()
