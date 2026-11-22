extends SceneTree

const STORE := preload("res://scripts/campaign_store.gd")
const QUEST := preload("res://scripts/chapter_guardians.gd")
const ROUTE := [Vector2(76, 5), Vector2(75, 10), Vector2(71, 15), Vector2(68, 19)]
var game
var hero
var bear
var camera_samples := 0

func _initialize() -> void:
	call_deferred("run")

func open_world() -> void:
	game = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(game)
	while not game.placement_ready:
		await physics_frame
	game._resume()
	hero = game.player

func close_world() -> void:
	game.queue_free()
	await process_frame
	await create_timer(.3, true, false, true).timeout

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var movie := OS.get_cmdline_user_args().has("movie")
	var fixture := STORE.DEFAULTS.duplicate(true)
	fixture.world_data = STORE.fresh_world()
	fixture.blade_level = 4
	fixture.armor_level = 4
	fixture.world_data.merge({"position": Vector3(67,2.5,24), "health":200, "lantern":true, "seal_fragments":[0,1,2], "cleared":[0,1,2,3,4,5]}, true)
	assert(STORE.save_progress(fixture) == OK)
	await open_world()
	await ticks(24)
	assert(not is_instance_valid(game.cave_bear))
	assert(not game.temple.open and game.temple.chamber == null)
	assert(not game.temple.exposed_steps.visible and not game.awakening.eligible())
	if not movie:
		await walk(Vector2(67.8,18.1))
		for i in 60:
			steer(Vector3.BACK)
			await physics_frame
		hero.set_move_input(Vector2.ZERO)
		assert(hero.position.z<19.6 and game.temple.chamber == null)
	hero.position = game.guardians.grove_point
	game._interact_world()
	assert(game.world_data[QUEST.GROVE_FLAG])
	hero.position = Vector3(76,1.65,-17)
	for point in ROUTE:
		await walk(point)
	await ticks(100)
	await threshold(Vector2(67.8,22), true)
	await walk(Vector2(0,-4.7))
	await ticks(16)
	bear = game.cave_bear
	assert(is_instance_valid(bear) and bear.is_on_floor() and bear.animator.get_animation_list().size() == 16)
	game._update_bear_encounter()
	assert(game.cave_bear == bear)
	assert(1 in game.relic_hunt.collected_ids and not game.awakening.eligible())
	if movie:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0]+"/after.png")
	var space = game.get_world_3d().direct_space_state
	var ceiling = space.intersect_ray(PhysicsRayQueryParameters3D.create(bear.position + Vector3.UP, bear.position + Vector3.UP*12, 16))
	assert(not ceiling.is_empty() and ceiling.position.y-bear.position.y > 4.2)
	var clearance := PhysicsShapeQueryParameters3D.new()
	var body = bear.get_node("Body")
	clearance.shape = body.shape
	clearance.transform = body.global_transform
	clearance.transform.origin.y += .15
	clearance.collision_mask = 4
	assert(space.intersect_shape(clearance).is_empty(), "Spawn capsule touches cave walls or props")
	print("PASS: entrance, relic, curved passage, gated spawn, headroom ", ceiling.position.y-bear.position.y)
	# Retreat via the same pass, then re-enter for a fresh attempt.
	if not movie:
		await walk(Vector2(0,-12))
		assert(game.cave_bear == bear)
		await threshold(Vector2(0,-24), false)
		await ticks(2)
		assert(not is_instance_valid(game.cave_bear))
		await threshold(Vector2(67.8,22), true)
		await walk(Vector2(0,-4))
		await ticks(18)
		bear = game.cave_bear
		assert(is_instance_valid(bear))
	if not movie:
		for quarter in 4:
			hero._camera_pivot.rotation.y = quarter * PI / 2.0
			await ticks(4)
			check_camera()
		for attack in [bear.Attack.CLAWS, bear.Attack.BITE, bear.Attack.ROAR, bear.Attack.SLAM]:
			hero.position = bear.position + Vector3.FORWARD * 2.65
			hero.velocity = Vector3.ZERO
			bear.rotation.y = 0
			var before: int = hero.health
			bear._begin(attack)
			if attack == bear.Attack.SLAM:
				await ticks(65)
				hero._camera_pivot.rotation.y = 0.0
				hero.dodge()
			assert(await wait_state(bear.State.RECOVER, 230))
			if attack == bear.Attack.SLAM:
				assert(hero.health == before)
			else:
				assert(hero.health < before)
			await ticks(28)
		# Charge straight into the sealed northern end of the arena after Aru sidesteps.
		bear.position = Vector3(7,34.1,18)
		hero.position = Vector3(7,34.1,20.7)
		bear.rotation.y = PI
		bear._begin(bear.Attack.CHARGE)
		await ticks(29)
		bear.rotation.y = PI
		hero.position = Vector3(4,34.1,16)
		assert(await wait_state(bear.State.STAGGER, 170))
		assert(bear.position.z < 21.5)
		print("PASS: cave claw combo, roar, slam dodge and charge wall stagger")
		assert(await wait_state(bear.State.CHASE, 90))
	var before_shards: int = game.shards
	for frame in 2400:
		if bear.health <= 0:
			break
		var dir: Vector3 = bear.global_position - hero.global_position
		dir.y = 0
		steer(dir)
		if dir.length() < 2.8:
			hero.attack()
		await physics_frame
		assert(hero.health > 0, "Actual hero must survive the fight")
	hero.set_move_input(Vector2.ZERO)
	assert(bear.health == 0 and bear.enraged and game.world_data[QUEST.BEAR_FLAG])
	assert(not game.completed and not game.boss_spawned and not game.awakening.active)
	game._bear_victory()
	assert(game.shards == before_shards and game.awakening.eligible())
	assert(game.guardian_journal("main").title == "The Lantern Awakening")
	await ticks(100)
	await walk(Vector2(0,19))
	assert(game._save_progress())
	if not movie:
		await close_world()
		await open_world()
		assert(game.world_data[QUEST.BEAR_FLAG] and game.temple.chamber != null and not game.completed and not game.boss_spawned)
		assert(game.shards == before_shards and game.awakening.eligible() and not game.awakening.finished())
	await threshold(Vector2(0,24),false)
	await walk(Vector2(64.4,25))
	var relics: Array = game.relic_hunt.collected_ids.duplicate()
	game.relic_hunt.collected_ids.erase(1)
	assert(not game.awakening.eligible(), "Bear victory alone cannot unlock the cinematic")
	game.relic_hunt.collected_ids.assign(relics)
	if not movie:
		await threshold(Vector2(67.8,21.45),true)
		await walk(Vector2(0,-4))
		await threshold(Vector2(0,-24),false)
		assert(not is_instance_valid(game.cave_bear))
		await walk(Vector2(71,15))
		await walk(Vector2(75,10))
		await walk(Vector2(76,5))
		# Retrace the curved passage; a straight line would cut through rock.
		await walk(Vector2(75,10))
		await walk(Vector2(71,15))
		await threshold(Vector2(67.8,21),true)
		await walk(Vector2(0,19))
		await threshold(Vector2(0,24),false)
		await walk(Vector2(64.4,25))
	assert(game.awakening.near_pedestal())
	await ticks(22)
	assert(not is_instance_valid(game.cave_bear) and not game.awakening.active)
	game._interact_world()
	assert(game.awakening.active)
	if movie:
		while game.awakening.active: await physics_frame
	else: game.awakening.skip()
	assert(game.completed and game.awakening.finished() and game.shards == before_shards+80)
	await close_world()
	await open_world()
	assert(game.completed and game.awakening.finished() and not game.boss_spawned and game.shards==before_shards+80)
	await close_world()
	print("PASS: sword victory, rage, safe return, one-time reward, save/reload, manual altar, Skip and permanent passage")
	quit()

func steer(direction: Vector3) -> void:
	var local: Vector3 = direction.normalized().rotated(Vector3.UP,-hero._camera_pivot.rotation.y)
	hero.set_move_input(Vector2(local.x,local.z))

func walk(goal: Vector2) -> void:
	for i in 800:
		var delta := goal - Vector2(hero.position.x,hero.position.z)
		if delta.length() < .38:
			hero.set_move_input(Vector2.ZERO)
			return
		var dir := Vector3(delta.x,0,delta.y).normalized()
		hero._camera_pivot.rotation.y = lerp_angle(hero._camera_pivot.rotation.y,atan2(-dir.x,-dir.z),.09)
		steer(dir)
		await physics_frame
		if i%12==0 and hero.position.z > -6:
			check_camera()
	assert(false,"Blocked walking to %s at %s"%[goal,hero.position])

func threshold(goal: Vector2, entering: bool) -> void:
	for i in 650:
		if is_instance_valid(game.temple.chamber) == entering:
			hero.set_move_input(Vector2.ZERO)
			return
		var dir := Vector3(goal.x-hero.position.x,0,goal.y-hero.position.z).normalized()
		hero._camera_pivot.rotation.y = lerp_angle(hero._camera_pivot.rotation.y,atan2(-dir.x,-dir.z),.09)
		steer(dir)
		await physics_frame
	assert(false,"Threshold blocked at %s"%hero.position)

func check_camera() -> void:
	var cam = hero._camera_arm.get_child(0)
	var ray := PhysicsRayQueryParameters3D.create(hero._camera_arm.global_position, cam.global_position, 4)
	assert(game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "Camera crossed cave rock")
	camera_samples += 1

func wait_state(state: int, limit: int) -> bool:
	for i in limit:
		if bear.state == state:
			return true
		await physics_frame
	return false

func ticks(count: int) -> void:
	for i in count:
		await physics_frame
