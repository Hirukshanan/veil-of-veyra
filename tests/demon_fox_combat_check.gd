extends SceneTree

const PREVIEW := preload("res://scenes/previews/demon_fox_combat_preview.tscn")
const FOX := preload("res://scenes/enemies/demon_fox_combat.tscn")

var _arena
var _hero
var _fox
var _hero_hits := 0
var _health_before := 100
var _obstacles: Array[StaticBody3D] = []

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	Engine.physics_ticks_per_second = 30
	_arena = PREVIEW.instantiate()
	root.add_child(_arena)
	_hero = _arena.player
	_hero.health_changed.connect(_count_hit)
	await _bite(false)
	await _bite(true)
	await _parry()
	await _leap(false)
	await _leap(true)
	await _blocked_leap()
	await _evade(false)
	await _evade(true)
	await _heavy_stagger_and_death()
	_arena.queue_free()
	await process_frame
	await create_timer(.20, true, false, true).timeout
	print("PASS: Demon Fox combat at 30 physics ticks per second")
	quit()

func _reset(distance: float, evade_chance := 0.0) -> void:
	var old = _arena.fox if not is_instance_valid(_fox) else _fox
	if is_instance_valid(old):
		old.queue_free()
	for wall in _obstacles:
		wall.queue_free()
	_obstacles.clear()
	await process_frame
	_hero.cancel_swing()
	_hero.end_guard()
	_hero.health = 100
	_hero.stamina = 100
	_hero._hit_time = 0.0
	_hero._dodge_time = 0.0
	_hero._dodge_cooldown = 0.0
	_hero._attack_cooldown = 0.0
	_hero._invulnerability_time = 0.0
	_hero.velocity = Vector3.ZERO
	_hero.position = Vector3(0, .035, 0)
	_hero.rotation.y = PI
	_hero._camera_pivot.rotation = Vector3.ZERO
	_hero._camera_pivot.global_position = _hero.position + Vector3.UP * 1.2
	_hero.set_move_input(Vector2.ZERO)
	_hero_hits = 0
	_health_before = 100
	_fox = FOX.instantiate()
	_fox.position = Vector3(0, .035, distance)
	_fox.target = _hero
	_fox.evade_chance = evade_chance
	_arena.add_child(_fox)
	_fox._rng.seed = 635
	_fox._leap_cooldown = 0.0

func _bite(dodged: bool) -> void:
	await _reset(1.06)
	assert(await _wait_state(_fox.State.WINDUP), "Fox must acquire close hero and bite")
	assert(_fox.action == _fox.Attack.BITE and _fox.animator.current_animation == "Bite")
	if dodged:
		await _wait_elapsed(.225)
		_dodge()
	assert(await _wait_state(_fox.State.RECOVER))
	assert(_hero.health == (100 if dodged else 92) and _hero_hits == (0 if dodged else 1))
	if dodged:
		# A real light swing hits the recovering Fox inside the existing contact area.
		_hero.position = _fox.position + Vector3.FORWARD * 1.04
		_hero.rotation.y = PI
		_hero._dodge_time = 0
		await _steps(2)
		_hero.attack()
		await _steps(8)
		assert(_fox.health < 19, "A missed bite leaves an actual sword counter window")
	print("PASS: Bite ", "side roll and sword counter" if dodged else "8 damage once")

func _parry() -> void:
	await _reset(1.06)
	assert(await _wait_state(_fox.State.WINDUP))
	await _wait_elapsed(.225)
	_hero.start_guard()
	assert(await _wait_state(_fox.State.STAGGER, 10), "Parry should use the hero's existing melee stagger handoff")
	assert(_hero.health == 100 and _hero.stamina < 100 and _fox.animator.current_animation == "Hit Reaction")
	print("PASS: Guard parry prevents bite damage and staggers Fox")

func _leap(dodged: bool) -> void:
	await _reset(3.5)
	assert(await _wait_state(_fox.State.WINDUP))
	assert(_fox.action == _fox.Attack.LEAP and _fox.animator.current_animation == "Quick Leap")
	var landing: Vector3 = _fox._landing
	var direction: Vector3 = _fox._locked_direction
	assert(_fox._feedback._warning.visible and landing.z > .3 and landing.z < .9)
	assert(await _wait_state(_fox.State.FLIGHT))
	if dodged:
		await _wait_elapsed(.22)
		_dodge()
	assert(await _wait_state(_fox.State.RECOVER))
	assert(_fox._locked_direction == direction and _fox._landing == landing)
	assert(not _fox._feedback._warning.visible and _fox.is_on_floor() and not _fox._blocked_flight)
	if dodged:
		assert(_fox.position.distance_to(landing) < .16, "A clear leap reaches its locked landing")
	else:
		assert(_fox._flight_contact and _fox.position.z > landing.z and _fox.position.z > 1.0,
			"A direct leap must land at the hero's body, outside their capsule")
	assert(_hero.health == (100 if dodged else 87) and _hero_hits == (0 if dodged else 1))
	if not dodged:
		assert(await _wait_state(_fox.State.REPOSITION))
		var before: float = _fox.position.distance_to(_hero.position)
		await _steps(12)
		assert(_fox.position.distance_to(_hero.position) > before + .20 and _hero_hits == 1)
	print("PASS: Leap ", "locked landing and real dodge" if dodged else "13 damage once, landing, recovery and retreat")

func _blocked_leap() -> void:
	await _reset(3.55)
	assert(await _wait_state(_fox.State.WINDUP) and _fox.action == _fox.Attack.LEAP)
	_wall(Vector3(0, .60, 1.93), Vector3(2.5, 1.2, .21))
	assert(await _wait_state(_fox.State.RECOVER))
	assert(_fox._blocked_flight and _fox.position.z >= 2.40 and _hero.health == 100)
	assert(not _fox._feedback._warning.visible)
	print("PASS: A wall introduced after launch planning blocks movement and cancels leap damage")

func _evade(blocked: bool) -> void:
	await _reset(2.46, 1.0)
	_fox._leap_cooldown = 8.0
	if blocked:
		_wall(Vector3(.71, .55, 2.52), Vector3(.18, 1.1, 1.5))
		_wall(Vector3(-.71, .55, 2.52), Vector3(.18, 1.1, 1.5))
	assert(await _wait_state(_fox.State.CHASE))
	assert(_fox._evade_cooldown <= 0)
	var before: Vector3 = _fox.position
	_hero.heavy_attack()
	await _steps(3)
	assert(_fox.state != _fox.State.EVADE, "The Fox needs time to react to the wind-up")
	if blocked:
		await _steps(19)
		assert(_fox.health == 15 and _fox._evade_cooldown == 0 and absf(_fox.position.x) < .40)
		print("PASS: Side walls prevent an unsafe dodge and the actual heavy attack lands")
		return
	assert(await _wait_state(_fox.State.EVADE, 9))
	await _steps(20)
	assert(_fox.health == 19 and absf(_fox.position.x - before.x) > .84, "The real heavy attack must miss the moving Fox")
	assert(_fox._evade_cooldown > 4.0)
	# A second real heavy wind-up before the cooldown expires must not trigger another evade.
	_fox.position = Vector3(0, .05, 2.46)
	_fox.velocity = Vector3.ZERO
	_fox.rotation.y = 0.0
	_fox._enter(_fox.State.CHASE)
	_fox._leap_cooldown = 8.0
	_hero._attack_cooldown = 0.0
	_hero._hit_time = 0.0
	_hero.stamina = 100
	_hero.heavy_attack()
	await _steps(22)
	assert(_fox.health == 15 and _fox._evade_cooldown > 3.0)
	print("PASS: Delayed physical side-dodge avoids heavy once, then cooldown allows the next hit")

func _heavy_stagger_and_death() -> void:
	await _reset(2.4)
	_fox.leap_min_range = 2.25
	assert(await _wait_state(_fox.State.ALERT))
	await _wait_elapsed(.16)
	_hero.heavy_attack()
	assert(await _wait_state(_fox.State.WINDUP))
	assert(_fox.action == _fox.Attack.LEAP)
	assert(await _wait_state(_fox.State.STAGGER))
	assert(_fox.health == 15 and _fox._stagger_length >= .65 and not _fox._feedback._warning.visible)
	var defeated_counts := [0]
	_fox.defeated.connect(func(): defeated_counts[0] += 1)
	_fox.take_damage(500)
	_fox.take_damage(500)
	assert(_fox.state == _fox.State.DEATH and _fox.animator.current_animation == "Death")
	assert(defeated_counts[0] == 1 and not _fox.is_in_group("combat_enemies") and _fox.collision_layer == 0)
	await _steps(161)
	assert(not is_instance_valid(_fox))
	print("PASS: Heavy attack interrupts leap prep and death clears collision and emits once")

func _wall(point: Vector3, size: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.position = point
	wall.collision_layer = 13
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	wall.add_child(collision)
	_arena.add_child(wall)
	_obstacles.append(wall)

func _dodge() -> void:
	_hero.set_move_input(Vector2.RIGHT)
	_hero.dodge()
	_hero.set_move_input(Vector2.ZERO)

func _count_hit(health: int, _maximum: int) -> void:
	if health < _health_before:
		_hero_hits += 1
	_health_before = health

func _wait_state(expected: int, ticks := 95) -> bool:
	for step in range(ticks):
		if _fox.state == expected:
			return true
		await physics_frame
	return false

func _wait_elapsed(seconds: float) -> void:
	while _fox._elapsed < seconds:
		await physics_frame

func _steps(ticks: int) -> void:
	for step in range(ticks):
		await physics_frame
