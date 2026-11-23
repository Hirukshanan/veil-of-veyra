extends SceneTree

const STORE := preload("res://scripts/campaign_store.gd")
const SCENE := "res://scenes/previews/modular_equipment_review.tscn"
var game
var screen
var out := ""
var mobile := false

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await process_frame

func open_game() -> void:
	game = load(SCENE).instantiate()
	root.add_child(game)
	while not is_instance_valid(game.title_screen):
		await physics_frame
	await frames(4)

func tap(button: Control) -> void:
	assert(button.is_visible_in_tree() and not button.disabled)
	for down in [true,false]:
		if mobile:
			var touch := InputEventScreenTouch.new()
			touch.position = button.get_global_rect().get_center()
			touch.pressed = down
			root.push_input(touch,true)
		else:
			var mouse := InputEventMouseButton.new()
			mouse.position = button.get_global_rect().get_center()
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.pressed = down
			root.push_input(mouse,true)
		await process_frame

func shot(name: String, hold: int) -> void:
	await frames(5 if out.is_empty() else hold)
	if not out.is_empty():
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(out+"/"+name+".png") == OK)

func close_up(name: String, focus: Vector3, offset: Vector3) -> void:
	if out.is_empty():
		return
	var view := screen.canvas.get_child(0) as SubViewport
	var camera := view.get_camera_3d()
	var original := camera.global_transform
	camera.global_position = focus + offset
	camera.look_at(focus)
	await shot(name,18)
	camera.global_transform = original

func outfit_views() -> void:
	if out.is_empty():
		return
	var start: float = screen.yaw
	for i in 3:
		var angle := PI + PI*.5*i
		screen.yaw = angle
		screen.preview.rotation.y = angle
		await shot(["05_front","06_side","07_back"][i],15)
	screen.yaw = start
	screen.preview.rotation.y = start

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var args := OS.get_cmdline_user_args()
	mobile = args.has("mobile")
	if args.size() > 1: out = args[1]
	root.size = Vector2i(854,480) if mobile else Vector2i(1280,720)
	var fixture := STORE.DEFAULTS.duplicate()
	fixture.shards = 65
	fixture.world_data = STORE.fresh_world()
	fixture.world_data.seal_fragments = [2]
	assert(STORE.save_progress(fixture) == OK)
	await open_game()
	assert(game.gear_selection() == {"blade":0,"shield":-1,"armor":0})
	await tap(game.title_screen.find_child("Armory",true,false))
	screen = game.get_node("Armory")
	await shot("01_starter_ranger",20)
	await tap(screen.choices[1])
	assert(screen.equip_button.disabled and screen.modular_preview.sword.visible and not game.modular.sword.visible)
	await tap(screen.upgrade_button)
	assert(game.shards == 45 and game.player.attack_damage == 2)
	await tap(screen.equip_button)
	assert(game.modular.sword.visible and not game.player._weapon.visible)
	await shot("02_embersteel",24)
	var sword: Node3D = screen.modular_preview.sword
	var sword_normal := sword.global_basis.z
	if sword_normal.z < 0:
		sword_normal = -sword_normal
	await close_up("02a_sword_detail",sword.to_global(Vector3(.026,.28,0)),
		(sword_normal*.7+Vector3.BACK).normalized()*1.78 + Vector3.LEFT*.14)
	await tap(screen.choices[0])
	await tap(screen.equip_button)
	assert(not game.modular.sword.visible and game.player._weapon.visible and game.player.attack_damage == 2)
	await tap(screen.choices[1])
	await tap(screen.equip_button)
	await tap(screen.tabs[1])
	await tap(screen.choices[0])
	assert(screen.modular_preview.shield.visible and not game.modular.shield.visible)
	await tap(screen.equip_button)
	assert(not screen.upgrade_button.visible and game.modular.shield.visible)
	await shot("03_thornward",24)
	var shield: Node3D = screen.modular_preview.shield
	await close_up("03a_shield_detail",shield.global_position,shield.global_basis.z.normalized()*1.20+Vector3.UP*.13)
	await tap(screen.equip_button)
	assert(not game.modular.shield.visible and not screen.modular_preview.shield.visible)
	await tap(screen.equip_button)
	await tap(screen.tabs[2])
	await tap(screen.choices[1])
	assert(screen.equip_button.disabled)
	await tap(screen.upgrade_button)
	await tap(screen.equip_button)
	assert(game.shards == 25 and game.player.max_health == 125)
	assert(game.modular.plates.all(func(n: Node3D): return n.visible))
	await shot("04_reinforced_ranger",36)
	var chest: Node3D = screen.modular_preview.plates[0]
	await close_up("04a_armor_detail",chest.to_global(Vector3(0,1.24,.13)),Vector3(-.60,.13,1.55))
	await outfit_views()
	await tap(screen.equip_button)
	assert(game.modular.plates.all(func(n: Node3D): return not n.visible) and game.player.max_health == 100)
	await tap(screen.choices[0])
	await tap(screen.equip_button)
	assert(game.player.max_health == 125 and not game.modular.plates[0].visible)
	await tap(screen.choices[1])
	await tap(screen.equip_button)
	for button in screen.find_children("*","Button",true,false):
		if button.text == "Back to menu":
			await tap(button)
			break
	assert(game.title_screen.visible)
	var save: Dictionary = STORE.load_progress().data
	assert(save.shards == 25 and save.blade_level == 1 and save.armor_level == 1)
	assert(save.world_data.seal_fragments == [2])
	assert(save.world_data.modular_equipment == {"blade":1,"shield":0,"armor":1})
	game.queue_free()
	paused = false
	await frames(5)
	await open_game()
	assert(game.modular.sword.visible and game.modular.shield.visible and game.modular.plates[0].visible)
	await tap(game.continue_button)
	var hero = game.player
	assert(game.started and game.has_node("DemonFox") and game.has_node("DemonBoar"))
	assert(hero.attack_damage == 2 and hero.max_health == 125)
	var camera: Camera3D
	var follow_camera := Callable()
	if not out.is_empty():
		var clearing: Vector3 = game.landscape.ground_point(Vector3(-8,0,32))
		hero.global_position = clearing + Vector3.UP*.1
		hero.velocity = Vector3.ZERO
		camera = Camera3D.new()
		game.add_child(camera)
		camera.fov = 37
		follow_camera = func():
			if is_instance_valid(camera) and camera.current:
				camera.global_position = hero.global_position + Vector3(-2.05,1.52,-3.7)
				camera.look_at(hero.global_position + Vector3.UP*.9)
		process_frame.connect(follow_camera)
		camera.make_current()
	await shot("08_island_loadout",24)
	var relaxed_shield: Vector3 = hero.to_local(game.modular.shield.global_position)
	hero.start_guard()
	assert(hero.guarding and game.modular.shield.visible)
	await frames(9)
	assert(game.modular.guard_pose.amount > .9)
	var raised_shield: Vector3 = hero.to_local(game.modular.shield.global_position)
	var outward: float = game.modular.shield.global_basis.z.normalized().dot(-hero.global_basis.z)
	assert(raised_shield.y > relaxed_shield.y + .02 and raised_shield.z < relaxed_shield.z and outward > .78,
		"Guard clearance/facing: %s / %s / %f" % [relaxed_shield,raised_shield,outward])
	await shot("09_guard",21)
	hero.end_guard()
	await frames(8)
	hero.attack()
	assert(hero._attack_time > 0)
	await shot("10_attack",5)
	await frames(20)
	hero.dodge()
	assert(hero._dodge_time > 0)
	await shot("11_dodge",5)
	await frames(16)
	hero.set_move_input(Vector2(0,-.48))
	await frames(24)
	assert(hero._visual.animator.current_animation == "Walk")
	hero.toggle_sprint()
	hero.set_move_input(Vector2(0,-1))
	await shot("12_sprint",24)
	assert(hero._visual.animator.current_animation == "Sprint")
	hero.set_move_input(Vector2.ZERO)
	assert(hero._visual.hand.get_parent().get_bone_count() == 65)
	print("PASS starter and variants, locked items, cosmetic shield, costs, legacy save, reload, actual island and combat inputs")
	if follow_camera.is_valid():
		process_frame.disconnect(follow_camera)
	game.queue_free()
	await frames(8)
	quit()
