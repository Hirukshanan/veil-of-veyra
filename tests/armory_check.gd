extends SceneTree

const STORE := preload("res://scripts/campaign_store.gd")
const SCENE := "res://scenes/previews/armory_review.tscn"
var game
var screen
var output := ""
var mobile := false

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await process_frame

func open() -> void:
	game = load(SCENE).instantiate()
	root.add_child(game)
	while not is_instance_valid(game.title_screen) or not game.placement_ready:
		await physics_frame
	await frames(8)

func click(button: Control) -> void:
	assert(button.is_visible_in_tree() and not button.disabled)
	for down in [true, false]:
		if mobile:
			var tap := InputEventScreenTouch.new()
			tap.position = button.get_global_rect().get_center()
			tap.pressed = down
			root.push_input(tap, true)
		else:
			var event := InputEventMouseButton.new()
			event.position = button.get_global_rect().get_center()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = down
			root.push_input(event, true)
		await process_frame

func shot(label: String) -> void:
	if not output.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output + "/" + label + ".png")

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var args := OS.get_cmdline_user_args()
	mobile = args.has("mobile")
	if args.size() > 1:
		output = args[1]
	root.size = Vector2i(854,480) if mobile else Vector2i(1280,720)
	var data := STORE.DEFAULTS.duplicate(true)
	data.shards = 55
	data.blade_level = 1
	data.world_data = STORE.fresh_world()
	data.world_data.seal_fragments = [0]
	data.world_data.herbs = [2]
	assert(STORE.save_progress(data) == OK)
	await open()
	assert(game.equipped("blade") and game.equipped("armor") and game.player.attack_damage == 2)
	await shot("01_title")
	await click(game.title_screen.find_child("Armory",true,false))
	screen = game.get_node("Armory")
	await frames(28)
	assert(screen.preview._weapon.visible and screen.stats.text.contains("Attack  2"))
	await shot("02_weapons")
	var initial_yaw: float = screen.preview.rotation.y
	for control in screen.find_children("*","Button",true,false):
		if control.text == "Rotate right":
			await click(control)
	await frames(34)
	assert(absf(wrapf(screen.preview.rotation.y-initial_yaw,-PI,PI)) > .25)
	await click(screen.equip_button)
	assert(game.player.attack_damage == 0 and not game.player._weapon.visible and not screen.preview._weapon.visible)
	await frames(24)
	await shot("03_blade_unequipped")
	await click(screen.equip_button)
	await click(screen.upgrade_button)
	assert(game.player.attack_damage == 3 and game.blade_level == 2 and game.shards == 15)
	assert(screen.upgrade_button.disabled and game.change_gear("blade",true) == "You need more Tide Shards.")
	await click(screen.tabs[1])
	assert(not screen.upgrade_button.visible and screen.levels.text == "No shield owned")
	await click(screen.tabs[2])
	assert(screen.upgrade_button.disabled)
	game.shards += 40
	screen._refresh()
	await click(screen.upgrade_button)
	assert(game.armor_level == 1 and game.player.max_health == 125 and game.shards == 35)
	await frames(22)
	await shot("04_armor_upgraded")
	await click(screen.equip_button)
	assert(game.player.max_health == 100 and screen.preview._visual._plain_outfit != null)
	await frames(18)
	await shot("05_armor_unequipped")
	for control in screen.find_children("*","Button",true,false):
		if control.text == "Back to menu":
			await click(control)
			break
	assert(game.title_screen.visible)
	var saved: Dictionary = STORE.load_progress().data
	assert(saved.shards == 35 and saved.blade_level == 2 and saved.armor_level == 1)
	assert(not saved.world_data.armor_equipped and saved.world_data.blade_equipped)
	assert(saved.world_data.seal_fragments == [0] and saved.world_data.herbs == [2])
	game.queue_free()
	paused = false
	await frames(5)
	await open()
	assert(game.player.attack_damage == 3 and game.player.max_health == 100 and game.shards == 35)
	await click(game.continue_button)
	assert(game.started and not paused and game.placement_ready)
	assert(game.has_node("DemonFox") and game.has_node("DemonBoar") and not game.boss_spawned)
	assert(game.seal_fragments.collected_ids == [0] and game.herbs.collected_ids == [2])
	# The normal guard uses the same mitigation shown by the Armory.
	var attacker := Node3D.new()
	game.add_child(attacker)
	attacker.global_position = game.player.global_position - game.player.global_basis.z * 2
	game.player.guarding = true
	var health: int = game.player.health
	game.player.take_damage(10, attacker)
	assert(game.player.health == health-3 and game.player.stamina <= 80.0)
	await shot("06_resume_gameplay")
	print("PASS title, Armory, actual preview, blade and armor, shard costs, legacy defaults, reload and gameplay guard")
	game.queue_free()
	await frames(12)
	quit()
