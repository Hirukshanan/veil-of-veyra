extends SceneTree

const STORE := preload("res://scripts/campaign_store.gd")
const REVIEW := "res://scenes/previews/ancient_grove_investigation.tscn"
const STORY := preload("res://scripts/grove_investigation.gd")
const JOURNAL := preload("res://scripts/candidate_journal.gd")
var game
var hero
var output := ""
var capture := false

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for i in count: await physics_frame

func open() -> void:
	game = load(REVIEW).instantiate()
	root.add_child(game)
	while not game.grove: await physics_frame
	game._resume()
	hero = game.player
	await ticks(4)

func close() -> void:
	game.queue_free()
	await process_frame
	await ticks(4)

func walk(to: Vector3, radius := .44) -> void:
	for i in 1050:
		var delta := Vector3(to.x-hero.position.x,0,to.z-hero.position.z)
		if delta.length() < radius:
			hero.set_move_input(Vector2.ZERO)
			return
		var yaw := atan2(-delta.x,-delta.z)
		hero._camera_pivot.rotation.y = lerp_angle(hero._camera_pivot.rotation.y,yaw,.065)
		var dir := delta.normalized().rotated(Vector3.UP,-hero._camera_pivot.rotation.y)
		hero.set_move_input(Vector2(dir.x,dir.z))
		await physics_frame
	hero.set_move_input(Vector2.ZERO)
	push_error("Blocked route at %s approaching %s" % [hero.position,to])
	quit(1)
	await process_frame

func press(touch := false) -> void:
	for down in [true,false]:
		if touch:
			var event := InputEventScreenTouch.new()
			event.position = game.interact_button.get_global_rect().get_center()
			event.pressed = down
			root.push_input(event,true)
		else:
			var key := InputEventKey.new()
			key.physical_keycode = KEY_E
			key.pressed = down
			root.push_input(key,true)

func shot(label: String) -> void:
	if capture:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/"+label+".png")

func check(n: int) -> void:
	assert(game.grove.stage() == n)
	var row := JOURNAL.entry(game,"main")
	var hud: Dictionary = game.tracked_hint({})
	var pin: Dictionary = game.guardian_map_markers().back()
	assert(pin.tracked and row.title.to_upper() == hud.title)
	assert(("%d/3" % n) in hud.progress and game._temple_unlocked() == (n==3))
	assert(pin.point == (STORY.SEARCH[n] if n<3 else STORY.CAVE_MOUTH))
	assert((pin.radius>0) == (n<3))
	if n<3:
		assert(pin.point.distance_to(game.grove.clues[n].global_position) > 1.0)
	else:
		assert(not game.world_data.has(STORY.PARTIAL))
	print("PASS stage ",n," journal/HUD/minimap/gate")

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var args := OS.get_cmdline_user_args()
	capture = args.size()>0
	if capture: output = args[0]
	var fixture := STORE.DEFAULTS.duplicate(true)
	fixture.world_data = STORE.fresh_world()
	fixture.shards = 47
	fixture.world_data.merge({"seal_fragments":[0,1,2],"cleared":[0,1,2,3,4,5],"boar_defeated":true,
		"guardian_quest":{"regions":[0,1,2],"fox_defeated":true,"investigated":true},"position":Vector3(0,1,-18.1)},true)
	assert(STORE.save_progress(fixture) == OK)
	await open()
	assert(not game._temple_unlocked() and not game.grove.in_reach())
	await walk(game.lantern.position+Vector3.BACK*1.55)
	hero._camera_pivot.rotation.y = -.17
	await ticks(18)
	press()
	await ticks(95)
	assert(game.lantern_lit and game.grove.routes[0].visible)
	check(0)
	await shot("01_lantern")
	for waypoint in [Vector3(2,0,-25),Vector3(4.5,0,-32),Vector3(5.5,0,-38)]:
		await walk(waypoint)
	for i in 3:
		var site: Node3D = game.grove.clues[i]
		var side := Vector3(.6,0,1.8) if i!=2 else Vector3(-1.6,0,1.75)
		await walk(site.global_position+side)
		for frame in 28:
			hero._camera_pivot.rotation.y = lerp_angle(hero._camera_pivot.rotation.y,atan2(side.x,side.z),.12)
			hero._camera_pivot.rotation.x = lerpf(hero._camera_pivot.rotation.x,-.31 if i==2 else -.06,.12)
			await physics_frame
		await ticks(30)
		assert(game._can_investigate_grove() and game.interact_button.accessibility_name == STORY.PROMPTS[i])
		press(i == 1)
		await ticks(32)
		check(i+1)
		press()
		assert(game.grove.stage()==i+1 and game.shards==47 and not game.boss_spawned and not game.cave_bear)
		await shot(["02_roots","03_symbol","04_tracks"][i])
		await ticks(86)
		if not capture:
			assert(game._save_progress())
			await close()
			await open()
			check(i+1)
			assert(game.shards==47 and game.seal_fragments.collected_ids.size()==3)
	if capture:
		await walk(Vector3(18,0,-36))
		await ticks(60)
	else:
		assert(game.guardian_map_markers().back().point == STORY.CAVE_MOUTH)
		for point in STORY.OUTWARD: await walk(point)
		for point in [Vector3(76,0,5),Vector3(75,0,10),Vector3(71,0,15),Vector3(68,0,18.8)]: await walk(point)
		await ticks(110)
		for i in 120:
			if game.shrine.in_cell: break
			var direction := Vector3.BACK.rotated(Vector3.UP,-hero._camera_pivot.rotation.y)
			hero.set_move_input(Vector2(direction.x,direction.z))
			await physics_frame
		hero.set_move_input(Vector2.ZERO)
		assert(game.shrine.in_cell)
		await walk(Vector3(0,34,-4.4),.19)
		await ticks(30)
		assert(is_instance_valid(game.cave_bear) and game.bear_intro.active and not game.boss_spawned)
		print("PASS continuous route into the existing cave and Bear awakening")
	await close()
	print("PASS complete grove investigation")
	quit()
