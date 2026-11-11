extends SceneTree

const STORE = preload("res://scripts/campaign_store.gd")
const TERRAIN = preload("res://scripts/island_terrain.gd")
var scene
var hero

func _initialize(): call_deferred("run")

func open_world():
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	hero = scene.player
	hero.set_physics_process(false)
	for enemy in get_nodes_in_group("lock_targets"):
		enemy.set_physics_process(false)
	await physics_frame

func close_world():
	scene.queue_free()
	await process_frame
	paused = false

func coast(point: Vector3) -> float:
	return TERRAIN.coast_radius(atan2(point.z, point.x), TERRAIN.SHALLOW_WATER_BASE)

func step(count: int):
	for index in range(count):
		await physics_frame
		assert(Vector2(hero.position.x, hero.position.z).length() < coast(hero.position) - 0.38,
			"Player must stay inside the coast, including between wall segments")

func place(angle: float):
	hero.set_physics_process(false)
	hero.set_move_input(Vector2.ZERO)
	hero.position = Vector3(cos(angle), 0, sin(angle)) * (TERRAIN.coast_radius(angle, TERRAIN.SHALLOW_WATER_BASE) - 1.5)
	hero.velocity = Vector3.ZERO
	hero.clear_target_lock()
	hero._camera_pivot.rotation = Vector3.ZERO
	hero._dodge_time = 0.0
	hero._dodge_cooldown = 0.0
	hero.stamina = 100.0
	hero.sprint_enabled = false
	hero.set_physics_process(true)
	await step(ceili(Engine.physics_ticks_per_second * 0.6))

func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	for path in [STORE.PATH, STORE.BACKUP, STORE.TEMP]:
		DirAccess.remove_absolute(path)
	await open_world()
	var wall = scene.get_node("ShallowWaterWall")
	assert(wall.collision_layer == 8 and wall.collision_mask == 0)
	var space = scene.get_world_3d().direct_space_state
	# Cover every join and midpoint, including the closing segment.
	for index in range(TERRAIN.COAST_SEGMENTS * 2):
		var angle := index * TAU / (TERRAIN.COAST_SEGMENTS * 2)
		var radius := TERRAIN.coast_radius(angle, TERRAIN.SHALLOW_WATER_BASE)
		var radial := Vector3(cos(angle), 0, sin(angle))
		var query := PhysicsRayQueryParameters3D.create(radial * (radius - 3) + Vector3.DOWN, radial * (radius + 3) + Vector3.DOWN, 8)
		var hit = space.intersect_ray(query)
		assert(not hit.is_empty() and hit.collider == wall, "Coast wall must have no gaps")
		assert(absf(Vector2(hit.position.x, hit.position.z).length() - radius) < 0.1)

	var health: int = hero.health
	var ticks_before := Engine.physics_ticks_per_second
	for ticks in [60, 15]:
		Engine.physics_ticks_per_second = ticks
		# Axes, diagonals, and joins between both axes. Drive real player physics.
		for index in range(8):
			var angle := index * TAU / 8.0
			var radial := Vector2(cos(angle), sin(angle))
			for mode in ["walk", "sprint", "dodge"]:
				await place(angle)
				hero.set_move_input(radial)
				hero.sprint_enabled = mode == "sprint"
				if mode == "dodge": hero.dodge()
				await step(ceili(ticks * 0.45))
				var radius := Vector2(hero.position.x, hero.position.z).length()
				assert(radius > coast(hero.position) - 0.7, "Walking, sprinting and dodging must reach the same boundary")
				assert(hero.position.y < -1.45, "The boundary must permit actual shallow-water entry")
				assert(hero.health == health, "Normal sea entry must not damage or rescue the player")
				# Pushing straight outward must not jitter or drift through the wall.
				var blocked: Vector3 = hero.position
				await step(ceili(ticks * 0.2))
				assert(hero.position.distance_to(blocked) < 0.12, "Blocked movement must remain stable")
				# Press diagonally into the wall; motion must slide along the coastline.
				var tangent := Vector2(-radial.y, radial.x)
				hero.set_move_input((radial * 0.4 + tangent).normalized())
				await step(ceili(ticks * 0.45))
				var moved := Vector2(hero.position.x - blocked.x, hero.position.z - blocked.z)
				assert(moved.dot(tangent) > 1.3, "Diagonal input must slide along shore, including wall joins")
				var water_position: Vector3 = hero.position
				hero.set_move_input(-radial)
				await step(ceili(ticks * 0.5))
				assert(Vector2(hero.position.x, hero.position.z).length() < Vector2(water_position.x, water_position.z).length() - 1.8,
					"The player must be able to turn back toward land without getting stuck")
				assert(hero.health == health)
		print("PASS: real walk/sprint/dodge, stable blocking, diagonal sliding and return at %d physics FPS" % ticks)
	Engine.physics_ticks_per_second = ticks_before
	hero.set_physics_process(false)
	hero.set_move_input(Vector2.ZERO)
	var exploration = scene.get_node("IslandExploration")
	# Preserve the emergency fall rescue and its pre-existing penalty.
	hero.position = Vector3(0, -3.5, 0)
	exploration._physics_process(0)
	assert(hero.position.y == -3.5 and hero.health == health)
	hero.position.y = -4.5
	hero._invulnerability_time = 0
	exploration._physics_process(0)
	assert(hero.position == hero.rescue_position and hero.health == health - 20)
	# Follow the beach route and actually collect all fragments using normal interaction.
	for point in TERRAIN.trails()[4]:
		assert(Vector2(point.x, point.z).length() < coast(point) - 2.0)
	for point in scene.seal_fragments.LOCATIONS:
		hero.position = point
		scene._interact_world()
	assert(scene.seal_fragments.complete())

	# Round-trip valid wading saves around the entire irregular coastline.
	hero.health = 63
	scene.potions = 5
	scene.shards = 27
	for index in range(16):
		var angle := index * TAU / 16.0
		hero.position = Vector3(cos(angle), 0, sin(angle)) * (TERRAIN.coast_radius(angle, TERRAIN.SHALLOW_WATER_BASE) - 0.5)
		hero.position.y = -1.7
		var saved: Vector3 = hero.position
		assert(scene._save_progress(), "All reachable wading positions must pass save validation")
		assert(STORE.load_progress().data.world_data.position == saved)
		scene._restore_world()
		assert(hero.position.is_equal_approx(saved), "Resting against the wall must not cause relocation on reload")

	# The old waterline is dry land after expansion. Raise old submerged saves safely.
	hero.position = Vector3(0,-1.7,91.8)
	assert(scene._save_progress(), "Old save positions must remain readable for relocation")
	await close_world()
	await open_world()
	assert(hero.position.y >= TERRAIN.height_at(Vector2(hero.position.x,hero.position.z)))
	assert(hero.health == 63 and scene.potions == 5 and scene.shards == 27 and scene.seal_fragments.complete(),
		"Relocation must preserve resources and quest progress")
	assert(scene._save_progress())
	var safe_position: Vector3 = hero.position
	await close_world()
	await open_world()
	assert(hero.position.is_equal_approx(safe_position), "A relocated save must remain stable on the next reopen")
	var invalid: Dictionary = scene.world_data.duplicate(true)
	invalid.position = Vector3(TERRAIN.OUTER_RADIUS+20,0,0)
	assert(not STORE.valid_world(invalid, false, 0))
	await close_world()
	print("PASS: seamless coast, shallow water without damage, emergency recovery, all seal pickups, wading save/reload and legacy position relocation")
	quit()
