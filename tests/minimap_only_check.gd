extends SceneTree

const STORE := preload("res://scripts/campaign_store.gd")
const SCENE := preload("res://scenes/chapter_one.tscn")
const FORMER_PADS := [Vector3(0,0,27), Vector3(0,0,2), Vector3(0,0,-20)]
var game
var output := ""

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for frame in count:
		await physics_frame

func shot(name: String) -> void:
	if output.is_empty():
		return
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK)

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	if not OS.get_cmdline_user_args().is_empty():
		output = OS.get_cmdline_user_args()[0]
	var legacy := STORE.DEFAULTS.duplicate(true)
	legacy.world_data = STORE.fresh_world()
	legacy.world_data.merge({"position": Vector3(0, 0, 27), "checkpoint": 2, "discovered": [true,true,true],
		"guardian_quest": {"investigated": true, "regions": [0], "fox_defeated": false}}, true)
	legacy.shards = 17
	assert(STORE.save_progress(legacy) == OK)
	game = SCENE.instantiate()
	root.add_child(game)
	while not is_instance_valid(game.title_screen) or not is_instance_valid(game.tidewarden):
		await physics_frame
	game.continue_button.pressed.emit()
	await ticks(12)
	var hero: CharacterBody3D = game.player
	assert(game.shards == 17 and hero.position.distance_to(Vector3(0,hero.position.y,27)) < 1.0)
	assert(not game.world_data.has("checkpoint") and not game.world_data.has("discovered"))
	assert(game.tidewarden.pillars.size() == 3)
	var exploration := game.get_node("IslandExploration") as Node3D
	assert(exploration.get_child_count() == 0 and not exploration.has_method("travel_to"))
	assert(not game.has_method("_show_island_map") and not game.has_method("_travel_waystone"))
	assert(game.find_child("MapButton",true,false) == null)
	if DisplayServer.get_name() != "headless":
		assert(game.mobile_hud.chrome._map_overlay.is_visible_in_tree())
	assert(not game.guardian_map_markers().is_empty())
	var rects: Dictionary = game.mobile_hud.rectangles(Vector2(1280,720))
	assert(rects.PauseButton.position.x - rects.QuestScrollButton.position.x == 52.0)
	var start := hero.position
	hero.set_move_input(Vector2(0,-.7))
	await ticks(27)
	hero.set_move_input(Vector2.ZERO)
	assert(hero.position.distance_to(start) > .55)
	var key := InputEventKey.new()
	key.keycode = KEY_M
	key.pressed = true
	root.push_input(key)
	assert(not paused and not game.overlay.visible)
	await shot("01_HUD_Minimap")
	game._pause_game()
	var captions := []
	for node in game.menu_box.get_children():
		if node is Button:
			captions.append(node.text)
	assert(paused and captions == ["Resume", "Quest Journal", "Store", "Save and return to camp", "Settings", "Quit"])
	for frame in 5:
		await process_frame
	await shot("02_Pause_Menu")
	game._toggle_pause()
	assert(not paused)
	var camera := Camera3D.new()
	game.add_child(camera)
	hero.set_physics_process(false)
	for index in FORMER_PADS.size():
		var at: Vector3 = game.landscape.ground_point(FORMER_PADS[index])
		hero.global_position = at
		game._interact_world()
		await ticks(6)
		assert(hero.global_position.is_equal_approx(at), "Former pad site moved Aru")
		camera.global_position = at + Vector3(-4.2,2.7,4.8)
		camera.look_at(at + Vector3(.35,.58,-.45))
		camera.make_current()
		await shot("0%d_Former_Pad_%d" % [index+3,index+1])
	assert(game._save_progress())
	var saved: Dictionary = STORE.load_progress().data
	assert(not saved.world_data.has("checkpoint") and saved.world_data.position.is_equal_approx(hero.position))
	print("PASS minimap and quest markers, no map entry or pads, walking, pause/resume, shrine pillars and legacy save")
	game.queue_free()
	await process_frame
	quit()
