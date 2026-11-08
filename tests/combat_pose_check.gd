extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var world := Node3D.new()
	root.add_child(world)
	var enemy = load("res://scripts/enemy.gd").new()
	world.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.set_process(false)
	var collision: CollisionShape3D
	for child in enemy.get_children():
		if child is CollisionShape3D:
			collision = child
	var collision_transform := collision.transform
	enemy._windup = enemy.windup_duration * 0.5
	enemy._process(0.1)
	assert(enemy._visual.rotation.x > 0.0)
	enemy._windup = 0.0
	enemy._strike_time = 0.2
	enemy._process(0.1)
	assert(enemy._visual.rotation.x < 0.0 and enemy._visual.position.z < 0.0)
	enemy.take_damage(1)
	enemy._process(0.01)
	assert(enemy._strike_time == 0.0 and enemy._visual.rotation.x > 0.0)
	assert(collision.transform == collision_transform and collision.get_parent() == enemy)
	enemy._hit_time = 0.0
	enemy.velocity = Vector3.ZERO
	enemy._process(0.1)
	assert(enemy._visual.transform.is_equal_approx(Transform3D.IDENTITY))
	for kind in range(3):
		var demon = load("res://scripts/enemy.gd").new()
		demon.kind = kind
		world.add_child(demon)
		demon.set_physics_process(false)
		demon.set_process(false)
		assert(demon.display_name == ["EMBER WOLF", "ASH STALKER", "DIRE WARG"][kind])
		var wolf = demon._visual
		assert(wolf.animator != null, "Install licensed wolf before validating release art")
		assert(is_equal_approx(wolf._model.rotation.y, PI))
		demon.velocity = Vector3(2, 0, 0)
		demon._process(0.1)
		assert(wolf._clip == "walk")
		demon.velocity = Vector3(3, 0, 0)
		demon._process(0.1)
		assert(wolf._clip == "run")
		demon._windup = demon.windup_duration * 0.5
		demon._process(0.1)
		assert(wolf._clip == "bite" and not wolf.animator.is_playing())
		assert(is_equal_approx(wolf.animator.current_animation_position, 0.325))
		demon._windup = 0.0
		demon._strike_time = 0.2
		demon._process(0.1)
		assert(is_equal_approx(wolf.animator.current_animation_position, 0.65))
		demon.take_damage(1)
		demon._process(0.01)
		assert(wolf._clip == "idle" and demon._strike_time == 0.0)
		demon._hit_time = 0.0
		demon.velocity = Vector3.ZERO
		demon._process(0.1)
		assert(wolf.animator.is_playing())
		paused = true
		var playback: float = wolf.animator.current_animation_position
		await create_timer(0.05, true).timeout
		assert(is_equal_approx(wolf.animator.current_animation_position, playback))
		paused = false
	var boss = load("res://scripts/boss.gd").new()
	world.add_child(boss)
	boss.set_physics_process(false)
	boss.set_process(false)
	boss._state = boss.AttackState.WINDUP
	boss._state_time = 0.2
	boss._use_breath = true
	boss._process(0.1)
	assert(boss._visual._clip == "windup")
	assert(boss._visual.animator.current_animation_position > 0.5)
	boss._state = boss.AttackState.CHARGE
	boss._process(0.1)
	assert(boss._visual._clip == "charge")
	assert(boss._fire_cone.get_parent() == boss and boss._warning_ring.get_parent() == boss)
	boss.set_process(true)
	paused = true
	var frozen: float = boss._visual.animator.current_animation_position
	await create_timer(0.1, true).timeout
	assert(boss._visual.animator.current_animation_position == frozen, "Combat visuals must freeze with pause")
	paused = false
	world.queue_free()
	await process_frame
	print("PASS: enemy anticipation, strike, interrupted recoil, reset, dragon poses, collider isolation and pause")
	quit()
