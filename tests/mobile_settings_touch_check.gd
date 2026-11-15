extends SceneTree
var scene
var results:Array=[]
func _initialize():call_deferred("run")
func settle(frames:int=5):
	for frame in range(frames):await process_frame
func touch(at:Vector2,pressed:bool,index:int):
	var event:=InputEventScreenTouch.new();event.position=at;event.pressed=pressed;event.index=index;root.push_input(event)
func drag(at:Vector2,relative:Vector2,index:int):
	var event:=InputEventScreenDrag.new();event.position=at;event.relative=relative;event.index=index;root.push_input(event)
func fields()->Dictionary:
	var data:={}
	for key in scene.settings_screen.FIELDS:data[key]=scene.get(key)
	return data
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(800,450)
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	scene.player.set_physics_process(false);scene._resume()
	scene._show_settings(scene._pause_game);await settle()
	var settings=scene.settings_screen
	assert(settings.cards.columns==1 and settings.scroll.get_v_scroll_bar().max_value>settings.scroll.size.y)
	var title:Label=settings.cards.get_child(0).get_child(0).get_child(0)
	var start:Vector2=title.get_global_rect().get_center()
	var old_scale:float=scene.hud_scale
	touch(start,true,2);drag(start+Vector2(0,-100),Vector2(0,-100),2);touch(start+Vector2(0,-100),false,2);await settle()
	assert(settings.scroll.scroll_vertical>=90 and scene.hud_scale==old_scale,"A real title-space swipe scrolls without changing a nearby slider")
	results.append({"case":"blank_title_touch_scroll","scroll_pixels":settings.scroll.scroll_vertical,"slider_unchanged":true})
	settings.scroll.scroll_vertical=0;await settle()
	var slider:HSlider=settings.sliders.hud_scale;var at:Vector2=slider.get_global_rect().get_center()
	touch(at,true,3);drag(at+Vector2(70,0),Vector2(70,0),3);touch(at+Vector2(70,0),false,3);await settle()
	assert(scene.hud_scale!=old_scale and settings.scroll.scroll_vertical==0,"Real slider-track touch changes the value while keeping page scroll independent")
	results.append({"case":"slider_track_touch","before":old_scale,"after":scene.hud_scale,"scroll_pixels":settings.scroll.scroll_vertical})
	var layout_rows:=[]
	for resolution in [Vector2i(800,450),Vector2i(1280,720),Vector2i(1600,720),Vector2i(732,414)]:
		root.size=resolution;await settle()
		var safe:=Rect2(Vector2(36,12),Vector2(resolution)-Vector2(60,24))
		for control in scene.find_children("*","Control",true,false):
			if control.get_script()==load("res://scripts/safe_area.gd"):control.test_safe_rect=safe;control.refresh()
		await settle()
		for caption in ["Controls","Camera","Graphics & Sound"]:
			settings.select_tab(caption);await settle()
			assert(safe.grow(1).encloses(settings.get_global_rect()))
			for button in [settings.save_button,settings.cancel_button,settings.reset_button]:assert(safe.grow(1).encloses(button.get_global_rect()),"Save/Back/Reset must stay visible inside safe margins")
			for tab in settings.tabs.values():assert(safe.grow(1).encloses(tab.get_global_rect()))
			for panel in settings.cards.get_children():assert(panel.size.x<=settings.scroll.size.x+1,"Settings cards must not create horizontal clipping")
			layout_rows.append({"resolution":resolution,"safe_rect":safe,"tab":caption,"columns":settings.cards.columns,"footer_clear":true,"cards_within_width":true})
	results.append({"case":"landscape_tabs_safe_areas","combinations":layout_rows})
	# Keep the original values/format and verify the actual fixed footer save path.
	settings.select_tab("Camera");settings.sliders.camera_sensitivity.value=1.45;settings.sliders.camera_distance.value=8.2
	settings.select_tab("Graphics & Sound");settings.sliders.sound_volume.value=.35
	var choice:OptionButton=settings.find_child("FrameLimitChoice",true,false);choice.select(0);choice.item_selected.emit(0)
	var expected:Dictionary=fields();settings.save_button.pressed.emit();await settle()
	assert(not is_instance_valid(scene.settings_screen))
	var config:=ConfigFile.new();assert(config.load(scene.SETTINGS_PATH)==OK)
	for key in expected:assert(is_equal_approx(float(config.get_value("settings",key)),float(expected[key])))
	var durable:String=FileAccess.get_file_as_string(scene.SETTINGS_PATH)
	scene._show_settings(scene._pause_game);await settle();settings=scene.settings_screen;var snapshot:Dictionary=fields()
	settings.reset_button.pressed.emit();assert(scene.camera_distance==6.3 and scene.frame_limit==30)
	settings.cancel_button.pressed.emit();await settle()
	assert(FileAccess.get_file_as_string(scene.SETTINGS_PATH)==durable)
	for key in snapshot:assert(scene.get(key)==snapshot[key],"Back must restore entry values even when mobile bootstrap defaults differ from desktop defaults")
	results.append({"case":"save_and_reset_preview_cancel","preserved_values":expected,"durable_file_unchanged_on_cancel":true})
	scene._show_settings(scene._pause_game);await settle();settings=scene.settings_screen;settings.select_tab("Camera");settings.sliders.camera_distance.value=6.8
	assert(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(scene.SETTINGS_PATH+".tmp"))==OK)
	settings.save_button.pressed.emit();assert(is_instance_valid(scene.settings_screen) and "could not be saved" in settings.status.text)
	assert(FileAccess.get_file_as_string(scene.SETTINGS_PATH)==durable,"Failed temp writes preserve the last settings file")
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.SETTINGS_PATH+".tmp"))==OK)
	settings.cancel_button.pressed.emit();await settle()
	results.append({"case":"failed_settings_write_retains_file_and_screen","passed":true})
	scene.queue_free();paused=false;await settle();await create_timer(.25,true,false,true).timeout
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	for key in expected:assert(scene.get(key)==expected[key],"Selected values must survive a new game scene")
	assert(scene.mobile_hud.editor==null and scene.find_child("TargetLockButton",true,false)==null and scene.find_child("SprintButton",true,false)==null)
	var output:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	FileAccess.open(output+"/settings_touch_results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"platform":"automated actual Godot touch dispatch and scene reload; not phone usability","cases":results,"reloaded_values":expected},"  "))
	print("PASS: title-space swipes, slider-track touches, all tabs/footer safe-area layout, save/reload, reset cancel and failed-write preservation")
	scene.queue_free();paused=false;await settle();await create_timer(.25,true,false,true).timeout;quit()
