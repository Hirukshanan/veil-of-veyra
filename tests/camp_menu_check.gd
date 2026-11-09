extends SceneTree
func _initialize(): call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(paused and scene.camp_menu.visible and not scene.menu_scroll.visible)
	assert(scene.camp_menu.buttons.blade.disabled and scene.camp_menu.buttons.armor.disabled)
	for resolution in [Vector2i(800,450),Vector2i(1280,720),Vector2i(1920,864)]:
		root.size=resolution
		for i in range(6): await process_frame
		var safe=scene.menu_scroll.get_parent()
		safe.test_safe_rect=Rect2(Vector2(44,12),Vector2(resolution)-Vector2(68,24))
		safe.refresh()
		for i in range(6): await process_frame
		var bounds:Rect2=safe.get_global_rect()
		var buttons:Array=scene.camp_menu.buttons.values()
		for index in range(buttons.size()):
			assert(bounds.grow(1).encloses(buttons[index].get_global_rect()),"Camp button must remain inside safe area")
			assert(buttons[index].size.y>=42,"Touch targets must stay usable")
			for other in range(index):
				assert(not buttons[index].get_global_rect().intersects(buttons[other].get_global_rect()),"Camp buttons must not overlap")
	scene.camp_menu.buttons.settings.pressed.emit()
	assert(scene.menu_scroll.visible and not scene.camp_menu.visible and paused)
	scene._show_camp()
	scene.shards=100
	scene._show_camp()
	assert(not scene.camp_menu.buttons.blade.disabled)
	scene.camp_menu.buttons.blade.pressed.emit()
	assert(scene.blade_level==1 and scene.shards==80)
	scene.camp_menu.buttons.armor.pressed.emit()
	assert(scene.armor_level==1 and scene.shards==60)
	scene.camp_menu.buttons.guides.pressed.emit()
	assert(not scene.camp_menu.visible and "FIELD GUIDE"==scene.menu_box.get_child(0).text)
	scene._show_camp()
	scene.camp_menu.buttons.reset.pressed.emit()
	assert("BEGIN A NEW JOURNEY?"==scene.menu_box.get_child(0).text and scene.shards==60)
	scene._show_camp()
	scene.camp_menu.buttons.quests.pressed.emit()
	assert(scene.journal_open and scene.quest_parchment.visible and not scene.camp_menu.visible)
	scene._show_camp()
	scene.camp_menu.buttons.play.pressed.emit()
	assert(not paused and not scene.overlay.visible and scene.started)
	var config:=ConfigFile.new()
	assert(config.load("res://export_presets.cfg")==OK)
	for key in ["launcher_icons/main_192x192","launcher_icons/adaptive_foreground_432x432","launcher_icons/adaptive_background_432x432"]:
		var path:String=config.get_value("preset.0.options",key,"")
		var texture:Texture2D=load(path)
		var image:=texture.get_image()
		assert(image!=null and image.get_width()>=432 and image.get_height()>=432)
	assert(ProjectSettings.get_setting("application/config/icon")=="res://assets/ui/brand/launcher.png")
	scene.queue_free()
	await process_frame
	paused=false
	print("PASS: camp safe-area bounds/touch spacing, upgrade actions, settings/guides/reset/journal/play navigation and launcher assets")
	quit()
