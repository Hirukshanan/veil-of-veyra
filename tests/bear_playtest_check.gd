extends "res://tests/cursed_bear_combat_check.gd"

var output := ""

func _check() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	Engine.physics_ticks_per_second = 60
	arena = ARENA.instantiate()
	root.add_child(arena)
	hero = arena.player
	if not output.is_empty():
		var camera := Camera3D.new()
		arena.add_child(camera)
		camera.position = Vector3(11, 10, -11)
		camera.look_at(Vector3(0, .8, -3.5))
		camera.fov = 52
		camera.make_current()
	hero.health_changed.connect(func(_hp, _max_hp): hits += 1)
	bear = arena.bear
	var improved := not args.has("baseline")
	await prepare(7)
	bear.health_changed.connect(arena._boss_health)
	bear.playtest_combat = improved
	bear._begin(bear.Attack.CHARGE)
	await capture("01_charge_tell", 12)
	hero.position.x = 3.5
	await ticks(28)
	var heading: float = bear.rotation.y
	assert(absf(heading) > .12 and absf(heading) <= bear.CHARGE_AIM_LIMIT)
	hero.position.x = -3
	assert(await until(bear.State.EXECUTE, 35))
	assert(await until(bear.State.RECOVER, 140))
	assert(is_equal_approx(heading,bear.rotation.y) and hits == 0,
		"Locked heading %f -> %f, damage events %d" % [heading,bear.rotation.y,hits])
	await capture("02_charge_recovery", 24)
	if improved:
		# The player moves to the rear before the next chase decision.
		hero.position = bear.position + bear.global_basis.z * 2.7
		hero.velocity = Vector3.ZERO
		assert(await until(bear.State.WINDUP, 110))
		assert(bear.attack == bear.Attack.SLAM and bear.warning.visible)
		await capture("03_flank_slam", 22)
		assert(await until(bear.State.EXECUTE, 90))
		assert(100-hero.health == bear.DAMAGE[bear.Attack.SLAM])
		assert(await until(bear.State.RECOVER, 50))
	await prepare(5)
	bear.health_changed.connect(arena._boss_health)
	bear.playtest_combat = improved
	bear.take_damage(bear.health)
	await ticks(230)
	await capture("04_corpse", 24)
	if improved:
		var corpse: StaticBody3D = bear.get_node("CorpseCollision")
		var center: Vector3 = corpse.get_child(0).global_position
		hero.position = Vector3(center.x, .03, center.z + 3.2)
		hero._camera_pivot.rotation.y = 0.0
		hero.set_move_input(Vector2(0,-1))
		await ticks(65)
		assert(hero.position.z > center.z + .70, "Aru crossed into the torso")
		await capture("05_blocked", 15)
		hero.set_move_input(Vector2(-1,0))
		await ticks(37)
		hero.set_move_input(Vector2(0,-1))
		await ticks(85)
		assert(hero.position.z < center.z - 1.0, "Aru could not go around the corpse: %s / %s" % [hero.position, center])
		hero.set_move_input(Vector2.ZERO)
	print("PASS: charge tracking and locked dodge lane, flank slam and corpse clearance" if improved else "PASS: baseline captured")
	arena.queue_free()
	await process_frame
	quit()

func capture(label: String, hold: int) -> void:
	await ticks(hold)
	if not output.is_empty():
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(output+"/"+label+".png") == OK)
