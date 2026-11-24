extends SceneTree

const STORE := preload("res://scripts/campaign_store.gd")
const SCENE := "res://scenes/previews/chapter_one_bridge_playtest.tscn"
const AXIS := 2.7
var game
var hero
var output := ""
var baseline := false

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for i in count:
		await physics_frame

func open_world() -> void:
	assert(change_scene_to_file("res://scenes/previews/chapter_one_bear_playtest.tscn" if baseline else SCENE) == OK)
	await scene_changed
	game = current_scene
	while not is_instance_valid(game.title_screen):
		await physics_frame
	game.continue_button.pressed.emit()
	hero = game.player
	await ticks(12)

func shot(label: String) -> void:
	if output.is_empty():
		return
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"/"+label+".png") == OK)

func place(point: Vector3, yaw: float) -> void:
	hero.position = point
	hero.velocity = Vector3.ZERO
	hero._camera_pivot.rotation.y = yaw
	hero.rotation.y = yaw
	hero._camera_pivot.global_position = point + Vector3.UP*1.2
	hero.reset_physics_interpolation()

func cross(goal_z: float, sign_z: float, sprint: bool, touch: bool) -> void:
	if sprint:
		while hero.stamina < 30.0:
			await physics_frame
	var stick: Control = get_nodes_in_group("movement_joysticks")[0]
	var center := stick.get_global_rect().get_center()
	var speed_seen := 0.0
	var origin_z: float = hero.position.z
	if touch:
		send_touch(center, true)
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = center - Vector2(0,stick.size.y*(.57 if sprint else .26))
		drag.relative = drag.position-center
		root.push_input(drag,true)
		assert(hero._touch_move.y < -.3, "Joystick input failed: %s at %s" % [hero._touch_move,center])
	else:
		Input.action_press("move_forward", 1.0 if sprint else .56)
		if sprint:
			hero.toggle_sprint()
	for i in 1050:
		await physics_frame
		assert(hero.position.y > 33.85 and hero.position.y < 34.2)
		speed_seen = maxf(speed_seen, absf(hero.velocity.z))
		if (hero.position.z - goal_z)*sign_z >= 0:
			break
	if touch:
		send_touch(center, false)
	else:
		Input.action_release("move_forward")
	hero.sprint_enabled = false
	await ticks(3)
	assert((hero.position.z-origin_z)*sign_z >= absf(goal_z-origin_z)-.12,
		"Crossing stopped at %s, target z %s, speed %s" % [hero.position,goal_z,speed_seen])
	assert(speed_seen > (6.0 if sprint else 2.0), "Movement speed %s, sprint=%s, touch=%s" % [speed_seen, sprint, touch])

func send_touch(at: Vector2, pressed: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.position = at
	touch.pressed = pressed
	root.push_input(touch,true)

func check_floor() -> void:
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	for i in 136:
		var z := 46.5 + i*.25
		for x in [AXIS-1.62, AXIS, AXIS+1.62]:
			var ray := PhysicsRayQueryParameters3D.create(Vector3(x,34.14,z),Vector3(x,33.7,z), 4)
			var hit := space.intersect_ray(ray)
			assert(not hit.is_empty() and absf(hit.position.y-34.0)<.015 and hit.normal.y > .99,
				"Floor seam at x=%f z=%f: %s" % [x,z,hit])

func check_parapets() -> void:
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	for side in [-1.0, 1.0]:
		for z in [52.3, 63.0, 75.0, 80.5, 80.8]:
			var ray := PhysicsRayQueryParameters3D.create(
				Vector3(AXIS+side*1.65,34.62,z), Vector3(AXIS+side*2.4,34.62,z), 4)
			var hit := space.intersect_ray(ray)
			if baseline and z > 80.4:
				assert(hit.is_empty(), "Expected the original far landing seam to be open")
			else:
				assert(not hit.is_empty() and absf(hit.normal.x) > .98, "Missing parapet at z=%s" % z)

func press_against_parapets() -> void:
	for side in [-1.0, 1.0]:
		place(Vector3(AXIS+side*1.4,34.08,80.6),0)
		var action := "move_left" if side < 0.0 else "move_right"
		Input.action_press(action)
		await ticks(30)
		Input.action_release(action)
		assert(hero.is_on_floor() and absf(hero.position.x-AXIS)<1.87,
			"Hero crossed the far landing parapet on side %s" % side)

func check_progress() -> void:
	assert(game.completed and game.awakening.finished() and game.lantern_lit)
	assert(game.world_data.cursed_bear_defeated and game.world_data.ancient_grove_investigated)
	assert(game.seal_fragments.collected_ids == [0,1,2])
	assert(game.shards == 92 and game.potions == 4 and hero.health == 96)

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var args := OS.get_cmdline_user_args()
	baseline = args.has("before")
	if not args.is_empty():
		output = args[0]
	root.size = Vector2i(854,480) if args.has("mobile") else Vector2i(1280,720)
	var data := STORE.DEFAULTS.duplicate(true)
	data.completed = true
	data.shards = 92
	data.armor_level = 1
	data.world_data = STORE.fresh_world()
	data.world_data.merge({"position":Vector3(AXIS,34.08,45.6),"health":96,"potions":4,
		"lantern":true,"seal_fragments":[0,1,2],"cleared":[0,2,5],"boar_defeated":true,
		"ancient_grove_investigated":true,"cursed_bear_defeated":true,"lantern_awakening":true,
		"guardian_quest":{"investigated":true,"regions":[],"fox_defeated":true}}, true)
	assert(STORE.save_progress(data) == OK)
	await open_world()
	check_progress()
	assert(game.shrine.in_cell and game.awakening.gate.get_child(0).disabled)
	check_floor()
	check_parapets()
	place(Vector3(AXIS,34.08,46.5),PI)
	await ticks(16)
	await shot("01_bridge")
	if not baseline:
		print("TRAVERSAL_START ", Engine.get_process_frames())
		await cross(79.8,1.0,false,false)
		place(Vector3(AXIS + 1.31,34.08,79.7),0)
		await cross(49.0,-1.0,true,false)
		place(Vector3(AXIS - 1.31,34.08,49.0),PI)
		await cross(79.6,1.0,true,true)
		await shot("02_far_checkpoint")
		place(Vector3(AXIS,34.08,78.8),0)
		await cross(62.0,-1.0,false,true)
		assert(game._save_progress())
		await open_world()
		check_progress()
		assert(absf(hero.position.z-62.0) < .4 and hero.position.y > 33.9)
		print("PASS floor grid, walk, sprint, left/right lanes, repeated crossing, touch joystick and mid-bridge reload")
	# Inject the same off-deck position on both builds and let real gravity run.
	print("FALL_START ", Engine.get_process_frames())
	place(Vector3(AXIS+3.1,34.28,64.8),-.5)
	await shot("03_off_deck")
	if not baseline and not output.is_empty():
		await ticks(95)
	await ticks(85)
	if baseline:
		assert(hero.position.y < 33.55 and game.shrine.in_cell)
		await shot("04_trapped")
		print("PASS baseline reproduction: cavern floor holds Aru below the bridge")
	else:
		assert(hero.position.distance_to(game.FAR_BRIDGE) < .2 and hero.is_on_floor())
		await shot("04_recovered")
		check_progress()
		var saved: Dictionary = STORE.load_progress().data
		assert(saved.world_data.position.distance_to(game.FAR_BRIDGE)<.15)
		place(Vector3(AXIS-3.2,34.24,53.0),0)
		await ticks(75)
		assert(hero.position.distance_to(game.NEAR_BRIDGE) < .2 and hero.is_on_floor())
		await ticks(90)
		check_progress()
		assert(hero.position.distance_to(game.NEAR_BRIDGE) < .2)
		saved = STORE.load_progress().data
		saved.world_data.position = Vector3(8.0,25.0,73.0)
		assert(STORE.save_progress(saved) == OK)
		await open_world()
		check_progress()
		assert(hero.position.distance_to(game.FAR_BRIDGE) < .2 and game.shrine.in_cell)
		place(hero.position,0)
		await cross(73.0,-1.0,false,true)
		await press_against_parapets()
		print("PASS physical edge blocking, touch after recovery, near/far fall recovery, safe saved position, no respawn loop, legacy fallen save and Dragon-eye progression")
	print("CAPTURE_END ", Engine.get_process_frames())
	current_scene.queue_free()
	await process_frame
	quit()
