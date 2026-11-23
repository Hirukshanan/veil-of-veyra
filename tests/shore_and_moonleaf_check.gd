extends SceneTree

const SCENE := "res://scenes/previews/chapter_one_shore_playtest.tscn"
const STORE := preload("res://scripts/campaign_store.gd")
const LAND := preload("res://scripts/island_landscape.gd")

var game
var hero: CharacterBody3D

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for index in count:
		await physics_frame

func open_game() -> void:
	assert(change_scene_to_file(SCENE) == OK)
	await scene_changed
	game = current_scene
	while not is_instance_valid(game.title_screen):
		await physics_frame
	game.continue_button.pressed.emit()
	hero = game.player
	await ticks(15)

func place(x: float, z: float, yaw := 0.0) -> void:
	var ground: Vector3 = game.landscape.ground_point(Vector3(x,0,z))
	hero.position = ground + Vector3.UP*.14
	hero.velocity = Vector3.ZERO
	hero._camera_pivot.rotation.y = yaw
	hero.rotation.y = yaw
	hero._camera_pivot.global_position = hero.position + Vector3.UP * 1.2
	hero.reset_physics_interpolation()
	await ticks(12)

func key_interact() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	root.push_input(key, true)

func touch(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)

func tap_collect() -> void:
	var button: Button = game.interact_button
	var point := button.get_global_rect().get_center()
	var viewport_point := root.get_final_transform() * point
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = viewport_point
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func check_plants() -> void:
	assert(game.herbs.plants.size() == 11)
	var sloped := 0
	var plants: Array = game.herbs.plants.duplicate()
	for plant in plants:
		var id: int = plant.get_meta("pickup_id")
		var contact: Dictionary = game.landscape.ground_hit(plant.position)
		assert(not contact.is_empty())
		if contact.normal.y < .97:
			sloped += 1
		var stem: MeshInstance3D = plant.get_node("RootedStem") if id < 8 else plant.get_child(0)
		var base: float = stem.global_position.y - stem.mesh.height * .5
		assert(base <= contact.position.y and base > contact.position.y - .05, "Plant base %d" % id)
		assert(stem.global_position.y + stem.mesh.height * .5 > contact.position.y + .30)
		await place(plant.position.x,plant.position.z + .7)
		assert(game.herbs.nearest(hero.position) == plant)
		assert(game.interact_button.visible and not game.interact_button.disabled)
		if id == 10:
			assert(game.interact_button.accessibility_name == "Collect Moonleaf")
			tap_collect()
		else:
			key_interact()
		await ticks(4)
		assert(game.potions == 4 + id and id in game.herbs.collected_ids, "Pickup %d" % id)
		key_interact()
		await ticks(3)
		assert(game.potions == 4 + id, "Duplicate pickup %d" % id)
		if id == 6:
			await open_game()
			assert(game.herbs.collected_ids == [0,1,2,3,4,5,6] and game.potions == 10)
			# Later plants were freed with the previous scene; replace only pending handles.
			plants[7] = game.herbs.plants[0]
			plants[8] = game.herbs.plants[1]
			plants[9] = game.herbs.plants[2]
			plants[10] = game.herbs.plants[3]
	assert(sloped >= 4 and game.herbs.grove_count() == 3 and game.shards == 25)
	await open_game()
	assert(game.herbs.plants.is_empty() and game.herbs.collected_ids.size() == 11)
	assert(game.potions == 14 and game.shards == 25 and game.world_data.grove_reward)
	print("PASS all 11 grounded pickups, %d sloped sites, keyboard and touchscreen harvest, potion and reward persistence" % sloped)

func ground_distance() -> float:
	var hit: Dictionary = game.landscape.ground_hit(hero.position)
	assert(not hit.is_empty(), "Missing floor at %s" % hero.position)
	return hero.position.y - hit.position.y

func move_to(target: Vector2, sprint := false, use_touch := false) -> void:
	if sprint:
		while hero.stamina < 85:
			await physics_frame
	var start := Vector2(hero.position.x,hero.position.z)
	var heading := (target - start).normalized()
	hero._camera_pivot.rotation.y = atan2(-heading.x,-heading.y)
	var stick: Control = get_nodes_in_group("movement_joysticks")[0]
	var center := stick.get_global_rect().get_center()
	if use_touch:
		touch(center,true)
		var drag := InputEventScreenDrag.new()
		drag.position = center - Vector2(0, stick.size.y * (.57 if sprint else .24))
		drag.relative = drag.position-center
		root.push_input(drag,true)
		assert(hero._touch_move.y < -.3)
	else:
		Input.action_press("move_forward",1.0 if sprint else .55)
		if sprint:
			hero.toggle_sprint()
	var max_speed := 0.0
	for tick in 650:
		await physics_frame
		max_speed = maxf(max_speed, Vector2(hero.velocity.x,hero.velocity.z).length())
		assert(hero.position.y > -2.65 and ground_distance() < .44, "Loss of floor at %s" % hero.position)
		var remaining := target - Vector2(hero.position.x,hero.position.z)
		if remaining.dot(heading) < .18:
			break
	if use_touch:
		touch(center,false)
	else:
		Input.action_release("move_forward")
	hero.sprint_enabled = false
	var finish := Vector2(hero.position.x,hero.position.z)
	assert(finish.distance_to(target) < .7, "Blocked shore route from %s to %s, reached %s" % [start,target,finish])
	assert(max_speed > (6.5 if sprint else 2.0))

func check_water() -> void:
	var land: Node3D = game.landscape
	for node_name in ["Sea","FlowingRiver","EstuaryWater"]:
		assert(land.get_node(node_name).get_child_count() == 0)
	var mesh: MeshInstance3D = land.get_node("EstuaryWater")
	var arrays := mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var tested := 0
	var error := 0.0
	for index in vertices.size():
		var p := vertices[index]
		if colors[index].r < .99 or p.z >= 109.0:
			continue
		var hit: Dictionary = land.ground_hit(p)
		assert(not hit.is_empty())
		error = maxf(error, absf(p.y - hit.position.y))
		tested += 1
	assert(tested > 150 and error < .012, "Shore edge %d error %.3f" % [tested,error])
	for side in [-1.0, 1.0]:
		var a := Vector2(LAND._river_center(91.0) + side*(LAND._river_width(91.0)+1.8),91.0)
		var b := Vector2(LAND._river_center(103.0) + side*(LAND._river_width(103.0)+1.8),103.0)
		await place(a.x,a.y)
		await move_to(b, side > 0, side > 0)
		var z := 100.0
		var x := LAND._river_center(z)
		var width := LAND._river_width(z)
		await place(x+side*(width+2.0),z)
		await move_to(Vector2(x+side*width*.68,z), false, side < 0)
		await ticks(5)
		assert(hero.is_on_floor() and ground_distance() < .12)
		assert(hero.position.y < LAND._river_surface_height(z) - .22)
		if side < 0:
			var wading_position := hero.position
			assert(game._save_progress())
			await open_game()
			assert(hero.position.distance_to(wading_position) < .20 and hero.is_on_floor())
			assert(game.potions == 14 and game.shards == 25 and game.herbs.grove_count() == 3)
		await move_to(Vector2(x+side*(width+2.0),z))
	# The existing coastline boundary remains the final limit, beyond supported wading.
	var x := LAND._river_center(110.0)
	await place(x,109.0,PI)
	Input.action_press("move_forward")
	await ticks(160)
	Input.action_release("move_forward")
	assert(hero.position.z > 110.0 and hero.position.z < 118.5 and ground_distance() < .15)
	assert(hero.health == 100 and hero.is_on_floor())
	print("PASS %d water-edge contacts (max %.4fm), west/east walk, sprint, shallow wade and retreat, supported inlet and sea boundary" % [tested,error])

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(854,480) if args.has("mobile") else Vector2i(1280,720)
	Input.emulate_mouse_from_touch = true
	var seed := STORE.DEFAULTS.duplicate(true)
	seed.world_data = STORE.fresh_world()
	seed.world_data.position = Vector3(0,3,28)
	assert(STORE.save_progress(seed) == OK)
	await open_game()
	await check_plants()
	await check_water()
	game.queue_free()
	await process_frame
	quit()
