extends SceneTree
class Target extends Node3D:
	func take_damage(_amount):
		pass
func _initialize():
	call_deferred("_run")
func _run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var world := Node3D.new()
	root.add_child(world)
	var target := Target.new()
	world.add_child(target)
	target.position = Vector3(40, 0, 0)
	var enemy = load("res://scripts/enemy.gd").new()
	enemy.target = target
	world.add_child(enemy)
	enemy.set_physics_process(false)
	enemy._patrol_wait = 0.0
	enemy._physics_process(0.1)
	assert(not enemy._alert and enemy._patrol_goal.distance_to(enemy._home) < 3.0)
	enemy._physics_process(2.0)
	assert(Vector2(enemy.velocity.x, enemy.velocity.z).length() > 0.0)
	assert(Vector2(enemy.velocity.x, enemy.velocity.z).length() < enemy.move_speed)
	target.position = enemy.position + Vector3(0, 0, 5)
	enemy._physics_process(0.01)
	assert(enemy._alert and enemy._alert_label.visible)
	enemy._physics_process(1.1)
	assert(not enemy._alert_label.visible)
	enemy.position = Vector3(21, 0, 0)
	target.position = Vector3(22, 0, 0)
	enemy._physics_process(0.01)
	assert(enemy._returning and not enemy._alert)
	enemy._physics_process(0.01)
	assert(enemy._returning and not enemy._alert, "Nearby player must not repeatedly retrigger the leash")
	enemy.position = enemy._home
	target.position = Vector3(40, 0, 0)
	enemy._physics_process(0.01)
	assert(not enemy._returning and not enemy._alert)
	enemy.set_physics_process(true)
	paused = true
	var position_before: Vector3 = enemy.position
	await create_timer(0.1, true).timeout
	assert(enemy.position == position_before)
	paused = false
	world.queue_free()
	await process_frame
	print("PASS: bounded patrol goal, slower patrol, alert cue expiry, chase leash hysteresis, home return and pause")
	quit()
