extends SceneTree

const TERRAIN = preload("res://scripts/island_terrain.gd")
const REGION = preload("res://scripts/chapter_one_region.gd")
const STORE = preload("res://scripts/campaign_store.gd")
var scene
var hero
var visited := 0

func _initialize() -> void:
	call_deferred("run")

func open_world() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	scene._autosave_time = -10000
	hero = scene.player
	hero.set_physics_process(false)
	for enemy in get_nodes_in_group("lock_targets"):
		enemy.set_physics_process(false)
	await physics_frame

func close_world() -> void:
	scene.queue_free()
	await process_frame
	paused = false

func sweep_route(route: PackedVector3Array, space: PhysicsDirectSpaceState3D) -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.46 # Slightly wider than Aru's 0.42m capsule.
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 8
	query.margin = 0.04
	for index in range(route.size()):
		var point := route[index]
		var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 20, point + Vector3.DOWN * 3, 1))
		assert(not ground.is_empty() and absf(ground.position.y) < 0.15, "New route must retain continuous flat ground")
		query.transform = Transform3D(Basis.IDENTITY, point + Vector3.UP * 0.95)
		assert(space.intersect_shape(query).is_empty(), "Player-sized route overlap at %s" % point)
		if index + 1 < route.size():
			query.motion = route[index + 1] - point
			assert(space.cast_motion(query)[0] > 0.99, "Player-sized route sweep blocked at %s" % point)
			query.motion = Vector3.ZERO

func walk(route: PackedVector3Array) -> void:
	for point in route:
		var attempts := 0
		while Vector2(hero.position.x - point.x, hero.position.z - point.z).length() > 0.32:
			var direction := Vector2(point.x - hero.position.x, point.z - hero.position.z)
			hero.set_move_input(direction.normalized() * minf(1.0, direction.length() * 2.0))
			await physics_frame
			attempts += 1
			var blocker := str(hero.get_last_slide_collision().get_collider().get_path()) if hero.get_slide_collision_count() > 0 else "none"
			assert(attempts < 150, "Real movement stuck en route to %s from %s; collider=%s; velocity=%s" % [point, hero.position, blocker, hero.velocity])
			assert(hero.health == 100 and hero.position.y > -0.1, "Traversal must not fall, rescue or lose health")
		visited += 1
	hero.set_move_input(Vector2.ZERO)
	await physics_frame

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	for path in [STORE.PATH, STORE.BACKUP, STORE.TEMP]:
		DirAccess.remove_absolute(path)
	await open_world()
	assert(scene.remaining_enemies == 5 and scene.get_node_or_null("CampDemon5") == null)
	assert(STORE.VERSION == 4, "Geography must not change the save schema")
	var region: Node3D = scene.get_node("IslandExploration/ChapterOneRegion")
	assert(region.get_node("AncientGrove").global_position == REGION.GROVE_CENTER)
	assert(region.get_node("DragonPerch").global_position == REGION.DRAGON_PERCH)
	var perch: Marker3D = region.get_node("DragonPerch")
	var facing := REGION.DRAGON_CAMERA - REGION.DRAGON_PERCH
	facing.y = 0
	assert((-perch.global_basis.z).dot(facing.normalized()) > 0.99, "Perched Dragon must face the reserved camera")
	assert(region.find_children("*", "Camera3D", true, false).is_empty(), "Reserved markers must not seize the gameplay camera")
	assert(REGION.GROVE_CENTER.distance_to(scene.herbs.GROVE.CENTER) > 50, "Keep optional Moonleaf Grove separate")
	var space: PhysicsDirectSpaceState3D = scene.get_world_3d().direct_space_state
	var routes := TERRAIN.trails()
	assert(routes.size() == 8)
	sweep_route(routes[0], space)
	for index in range(5, routes.size()):
		sweep_route(routes[index], space)
	# Reserve a usable floor, not just an empty center pixel.
	for x in range(-8, 9, 2):
		for z in range(-8, 9, 2):
			if Vector2(x,z).length() > REGION.GROVE_RADIUS:
				continue
			var point := REGION.GROVE_CENTER + Vector3(x, 0, z)
			var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 20, point + Vector3.DOWN * 3, 1))
			assert(not floor_hit.is_empty() and absf(floor_hit.position.y) < 0.3, "Grove floor must remain nearly level")
			var capsule := PhysicsShapeQueryParameters3D.new()
			var shape := CapsuleShape3D.new()
			shape.radius = 0.46
			shape.height = 1.8
			capsule.shape = shape
			capsule.collision_mask = 8
			capsule.transform.origin = point + Vector3.UP
			assert(space.intersect_shape(capsule).is_empty(), "Grove floor must stay clear of solid props")
	for dx in [-2.0, 0.0, 2.0]:
		var sight := space.intersect_ray(PhysicsRayQueryParameters3D.create(REGION.DRAGON_CAMERA, REGION.DRAGON_LOOK_AT + Vector3(dx,0,0), 1|4))
		assert(sight.is_empty(), "Reserved Dragon camera needs an unobstructed sightline")
	for entry in REGION.WAYMARKS:
		var point: Vector3 = entry.position
		for mask in [4, 8]:
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3(-1,0.35,0), point + Vector3(1,0.35,0), mask))
			assert(not hit.is_empty(), "Wayfinding stones must remain solid for player and camera")
	print("PASS: player-sized trail sweeps, level/clear grove, solid waymarks and reserved Dragon sightline")
	# Run the actual controller at a 30Hz simulation step, accelerated only in wall time.
	var old_ticks := Engine.physics_ticks_per_second
	var old_scale := Engine.time_scale
	Engine.physics_ticks_per_second = 120
	Engine.time_scale = 4.0
	hero._camera_pivot.rotation = Vector3.ZERO
	hero.set_move_input(Vector2.ZERO)
	hero.set_physics_process(true)
	await walk(routes[4]) # Beach -> seals.
	await walk(routes[5]) # Seals -> western foothills -> woodland -> central trail.
	var north := PackedVector3Array()
	for point in routes[0]:
		if point.z <= -13.0:
			north.append(point)
	await walk(north) # Existing lantern ruins.
	await walk(routes[6]) # Northern exit -> Ancient Grove.
	await walk(routes[7]) # Return via eastern woodland.
	var west := routes[2].duplicate()
	west.reverse()
	await walk(west)
	var beach := PackedVector3Array()
	for point in routes[0]:
		if point.z >= -4.0 and point.z <= 27.0:
			beach.append(point)
	beach.reverse()
	await walk(beach)
	await walk(routes[3]) # Optional Moonleaf Grove still has a clear entrance.
	var moonleaf_return := routes[3].duplicate()
	moonleaf_return.reverse()
	await walk(moonleaf_return)
	hero.set_physics_process(false)
	Engine.physics_ticks_per_second = old_ticks
	Engine.time_scale = old_scale
	assert(hero.position.distance_to(Vector3(0,0,27)) < 0.6)
	assert(not scene.boss_spawned and not scene.completed, "Exploring new geography must not advance the story")
	# New locations round-trip with current progress and reward semantics intact.
	hero.position = REGION.GROVE_CENTER
	hero.health = 63
	scene.potions = 5
	scene.shards = 27
	scene.seal_fragments.restore([0])
	assert(scene._save_progress())
	await close_world()
	await open_world()
	assert(hero.position.distance_to(REGION.GROVE_CENTER) < 0.2)
	assert(hero.health == 63 and scene.potions == 5 and scene.shards == 27)
	assert(scene.seal_fragments.collected_ids == [0] and scene.remaining_enemies == 5)
	assert(not scene.boss_spawned and not scene.completed)
	await close_world()
	print("PASS: real shore/foothills/forest/ruins/grove round trip, Moonleaf return, %d waypoints and unchanged-progress save/reopen" % visited)
	quit()
