extends SceneTree

const ARENA := preload("res://scenes/previews/cursed_bear_combat_preview.tscn")
const BOSS := preload("res://scenes/enemies/cursed_bear_boss.tscn")
const BOAR := preload("res://assets/characters/demon_boar/demon_boar.glb")
var arena
var bear
var hero
var hits := 0
var deaths := 0

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	Engine.physics_ticks_per_second = 30
	arena = ARENA.instantiate()
	root.add_child(arena)
	bear = arena.bear
	hero = arena.player
	hero.health_changed.connect(func(_hp, _max_hp): hits += 1)
	await ticks(2)
	var comparison := BOAR.instantiate() as Node3D
	comparison.scale *= 1.32
	arena.add_child(comparison)
	var reference := bounds(comparison)
	var size := bounds(bear.get_node("Model"))
	assert(size.y > reference.y * 1.15 and maxf(size.x, size.z) > maxf(reference.x, reference.z))
	print("SIZE bear ", size, " elite boar ", reference)
	comparison.queue_free()
	assert(bear.animator.get_animation_list().size() == 16)
	assert(await until(bear.State.WINDUP, 100))
	assert(bear.attack == bear.Attack.CHARGE)
	for move in [bear.Attack.CLAWS, bear.Attack.SLAM, bear.Attack.ROAR, bear.Attack.BITE]:
		await prepare(2.55)
		bear._begin(move)
		assert(bear.warning.visible and hits == 0)
		assert(await until(bear.State.EXECUTE, 100))
		assert(hits == 1)
		assert(hero._hit_time > 0.0)
		assert(await until(bear.State.RECOVER, 150))
		assert(hits == (3 if move == bear.Attack.CLAWS else 1))
		assert(hero.health == 100 - (29 if move == bear.Attack.CLAWS else int(bear.DAMAGE[move])))
		assert(bear._choose(2.5) != move)
	await prepare(2.55)
	bear._begin(bear.Attack.SLAM)
	await ticks(32)
	hero.dodge()
	assert(await until(bear.State.RECOVER, 30))
	assert(hero.health == 100)
	hero.position = Vector3(0, .03, -2.25)
	hero.rotation.y = PI
	await ticks(2)
	hero.attack()
	await ticks(8)
	assert(bear.health < bear.MAX_HEALTH, "Actual sword must connect during recovery")
	await prepare(7)
	bear._begin(bear.Attack.CHARGE)
	assert(await until(bear.State.EXECUTE, 45))
	var heading: float = bear.rotation.y
	assert(await until(bear.State.RECOVER, 80))
	assert(hits == 1 and hero.health == 82 and is_equal_approx(heading, bear.rotation.y))
	await prepare(8)
	bear._begin(bear.Attack.CHARGE)
	assert(await until(bear.State.EXECUTE, 45))
	hero.position.x = 5
	arena.get_node("Pillar").position = Vector3(0, 1.5, -4)
	assert(await until(bear.State.STAGGER, 70))
	assert(hits == 0 and bear.position.z > -4 and is_equal_approx(bear.rotation.y, heading))
	assert(await until(bear.State.CHASE, 55))
	await prepare(3.7)
	arena.get_node("Pillar").position = Vector3(0, 1.5, -2.3)
	await ticks(3)
	assert(not bear._clear_sight())
	bear._begin(bear.Attack.SLAM)
	assert(await until(bear.State.RECOVER, 90))
	assert(hero.health == 100)
	arena.get_node("Pillar").position = Vector3(5, 1.5, 1)
	assert(not bear._supported(Vector3(0, 0, 16),Vector3(0, 0, 20)))
	await prepare(10)
	bear._enter(bear.State.CHASE)
	arena.get_node("Pillar").position = Vector3(0, 1.5, -4.8)
	assert(await until(bear.State.WINDUP, 300), "Bear should go around the pillar and reacquire a clear attack")
	assert(bear._clear_sight())
	await prepare(14)
	var start: Vector3 = bear.position
	await ticks(70)
	assert(bear.position.distance_to(start) > .7 and bear.is_on_floor())
	await prepare(2.2)
	hero.rotation.y = PI
	hero.heavy_attack()
	assert(await until(bear.State.STAGGER, 45))
	assert(bear.health == bear.MAX_HEALTH - hero.attack_damage * 4)
	bear.take_damage(bear.health - 37)
	assert(not bear.enraged)
	bear.take_damage(1)
	assert(bear.enraged and bear.state == bear.State.RAGE)
	bear.stagger(.65)
	assert(bear.state == bear.State.RAGE)
	assert(await until(bear.State.CHASE, 70))
	bear.defeated.connect(func(): deaths += 1)
	bear.take_damage(bear.health)
	bear.take_damage(9)
	assert(deaths == 1 and bear.collision_layer == 0 and bear.animator.current_animation == "Death")
	await ticks(120)
	assert(not bear.is_physics_processing() and bear.state == bear.State.DEAD)
	arena.queue_free()
	await process_frame
	await create_timer(.45, true, false, true).timeout
	print("PASS: detection, chase, range and repeat rules, four melee patterns, three claw hits, dodge, sword counter, charge hit and wall stagger, occlusion, ledge, heavy stagger, rage and death")
	quit()

func bounds(model: Node3D) -> Vector3:
	var box := AABB()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var part: AABB = node.global_transform * node.get_aabb()
		box = box.merge(part) if box.has_volume() else part
	return box.size

func prepare(distance: float) -> void:
	bear.free()
	arena.get_node("Pillar").position = Vector3(5, 1.5, 1)
	hero.position = Vector3(0, .03, -distance)
	hero.velocity = Vector3.ZERO
	hero.health = 100
	hero.stamina = 100
	hero._invulnerability_time = 0
	hero._charge_knockback = Vector3.ZERO
	hero._attack_cooldown = 0
	hero._dodge_time = 0
	hero._hit_time = 0
	hero.end_guard()
	bear = BOSS.instantiate()
	arena.add_child(bear)
	bear.target = hero
	await ticks(2)
	hits = 0

func until(expected: int, limit: int) -> bool:
	for tick in limit:
		if bear.state == expected:
			return true
		await physics_frame
	return bear.state == expected

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
