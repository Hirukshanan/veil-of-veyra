extends SceneTree

var scene
var attacks := 0
func _initialize(): call_deferred("run")
func settle():
	for i in range(4): await process_frame
func open_world():
	scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await settle()
	scene._resume()
	scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"): enemy.set_physics_process(false)
func close_world():
	scene.queue_free()
	await process_frame
	paused=false
func press(caption: String):
	for child in scene.menu_box.get_children():
		if child is Button and child.text==caption:
			child.pressed.emit()
			return
	assert(false,"Missing navigation action: "+caption)
func editor_screen():
	scene._show_settings(scene._pause_game)
	press("Controls")
	press("Customize HUD")
	await settle()
	return scene.mobile_hud.editor
func pointer(at: Vector2, pressed: bool):
	var e:=InputEventScreenTouch.new()
	e.position=at
	e.index=8
	e.pressed=pressed
	root.push_input(e)
func drag(at: Vector2):
	var e:=InputEventScreenDrag.new()
	e.position=at
	e.relative=Vector2(12,0)
	e.index=8
	root.push_input(e)
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.size=Vector2i(1280,720)
	await open_world()
	var hud=scene.mobile_hud
	assert(scene.find_child("HUDCustomization",true,false)==null,"Customization must never be permanently visible")
	assert(scene.find_child("TargetSwitchButton",true,false)==null and scene.find_child("TargetLockButton",true,false)==null,"Removed target controls must not appear in gameplay")
	var allowed_buttons: Array=["AttackButton","DodgeButton","JumpButton","GuardButton","SpiritBurstButton","SprintButton","InteractButton","HealButton","CampButton","QuestScrollButton","MapButton","PauseButton"]
	for button in scene.find_children("*","Button",true,false):
		if button.is_visible_in_tree():
			assert(button.name in allowed_buttons,"Only gameplay actions/navigation may be visible: "+button.name)
	assert(hud.chrome.visible and not scene.status_label.visible and not scene.health_label.visible)
	assert("Recover" in hud.chrome.quest_content().message)
	scene.boss_spawned=true
	scene.completed=true
	assert("explore" in hud.chrome.quest_content().message,"Completed journeys must not show an already-defeated boss objective")
	scene.boss_spawned=false
	scene.completed=false
	assert(hud.control("GuardButton")!=null and hud.control("MapButton")!=null)
	assert(root.get_camera_3d()==scene.player._camera_arm.get_child(0),"Portrait and minimap must not steal the gameplay camera")
	# An old profile's retired button must not erase the rest of a custom layout.
	var legacy:=ConfigFile.new()
	legacy.set_value("hud","version",1)
	legacy.set_value("hud","profile",{"preset":"Classic","controls":{"TargetSwitchButton":{"x":0.8,"y":0.7},"TargetLockButton":{"scale":1.2,"opacity":0.7},"AttackButton":{"opacity":0.6}}})
	assert(legacy.save(hud.PATH)==OK)
	hud.load_profile()
	assert(hud.profile.preset=="Classic" and hud.profile.controls.AttackButton.opacity==0.6 and not hud.profile.controls.has("TargetSwitchButton") and not hud.profile.controls.has("TargetLockButton"),"Retiring target controls must preserve the preset and other saved settings")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(hud.PATH))
	hud.profile={"preset":"Battle","controls":{}}
	hud.refresh()
	assert(hud.control("MovementJoystick").size.x<=144,"Movement joystick must be smaller than the old 190px control")
	for resolution in [Vector2(800,450),Vector2(1280,720),Vector2(1600,720),Vector2(732,414)]:
		for preset in ["Battle","Classic","Left-Handed"]:
			var data: Dictionary={"preset":preset,"controls":{}}
			assert(hud.layout_error(data,resolution).is_empty(),"Every default preset must remain separated: %s at %s: %s" % [preset,resolution,hud.layout_error(data,resolution)])
	var before_world: Dictionary=scene.world_data.duplicate(true)
	hud.control("AttackButton").tap_requested.connect(func(): attacks+=1)
	var editor=await editor_screen()
	assert(paused and is_instance_valid(editor))
	assert(not scene.overlay.visible and not scene.overlay.is_processing_input())
	assert(not hud.chrome.get_parent().get_parent().visible,"Gameplay layer must be hidden during editing")
	assert(editor.footer.size()==3 and editor.save_button.visible and editor.reset_button.visible)
	assert("TargetLockButton" not in hud.MOVABLE and "TargetSwitchButton" not in hud.MOVABLE and editor.selection.item_count==hud.MOVABLE.size(),"Customization must list only remaining gameplay controls")
	var rects: Dictionary=editor.preview_rects()
	var start: Vector2=editor.preview.global_position+rects.AttackButton.get_center()
	pointer(start,true)
	var at: Vector2=editor.preview.global_position+editor._preview_transform()*(Vector2(0.94,0.86)*Vector2(1280,720))
	drag(at)
	pointer(at,false)
	assert(editor.draft.controls.has("AttackButton"),"Dragging must store an actual control position")
	assert(absf(editor.draft.controls.AttackButton.x-0.94)<0.02,"Positions must be normalized to the safe game canvas")
	editor.size_slider.value=1.05
	editor.opacity_slider.value=0.55
	assert(editor.draft.controls.AttackButton.scale==1.05 and editor.draft.controls.AttackButton.opacity==0.55)
	var active: Rect2=editor.preview_rects().AttackButton
	var handle: Vector2=editor.preview.global_position+active.end+Vector2(4,4)
	pointer(handle,true)
	drag(handle+Vector2(3,3))
	pointer(handle+Vector2(3,3),false)
	assert(editor.draft.controls.AttackButton.scale>1.05,"Dragging the corner must resize the selected control")
	editor.size_slider.value=1.05
	assert(hud.profile.controls.is_empty() and attacks==0,"Preview changes must neither apply nor fire gameplay actions")
	assert(hud.layout_error(editor.draft,Vector2(1280,720)).is_empty())
	editor.save_button.pressed.emit()
	await settle()
	assert(not is_instance_valid(hud.editor) and scene.overlay.visible)
	assert(hud.profile.controls.AttackButton.opacity==0.55 and is_equal_approx(hud.control("AttackButton").modulate.a,0.55))
	assert(scene.overlay.is_processing_input() and scene.world_data==before_world)
	editor=await editor_screen()
	assert(editor.draft.controls.AttackButton.opacity==0.55)
	editor.preset_buttons[1].pressed.emit()
	assert(editor.draft.preset=="Classic" and hud.profile.preset=="Battle","Preset preview must be isolated until Save")
	editor.cancel_button.pressed.emit()
	await settle()
	assert(hud.profile.preset=="Battle" and hud.profile.controls.AttackButton.opacity==0.55)
	editor=await editor_screen()
	editor.draft.controls.GuardButton={"x":0.94,"y":0.86}
	editor.save_button.pressed.emit()
	assert(is_instance_valid(hud.editor) and "close" in editor.status.text,"Overlapping controls must not be saved")
	editor.draft.controls.erase("GuardButton")
	editor.draft.controls.AttackButton={"x":0.5,"y":0.5,"scale":1.0,"opacity":0.8}
	editor.save_button.pressed.emit()
	assert(is_instance_valid(hud.editor) and "middle" in editor.status.text,"Saving must protect the center combat view")
	editor.reset_button.pressed.emit()
	assert(editor.draft.preset=="Battle" and editor.draft.controls.is_empty())
	editor.preset_buttons[2].pressed.emit()
	assert(editor.draft.preset=="Left-Handed")
	editor.save_button.pressed.emit()
	await settle()
	assert(scene.player.left_handed_controls and hud.control("MovementJoystick").position.x>root.size.x*0.5)
	# Failed writes leave the previous durable profile intact and keep the editor open.
	var saved:=FileAccess.get_file_as_string("user://hud_profile.cfg")
	editor=await editor_screen()
	assert(DirAccess.make_dir_absolute(ProjectSettings.globalize_path("user://hud_profile.cfg.tmp"))==OK)
	editor.save_button.pressed.emit()
	assert("could not be saved" in editor.status.text and FileAccess.get_file_as_string("user://hud_profile.cfg")==saved)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://hud_profile.cfg.tmp"))
	editor.cancel_button.pressed.emit()
	await settle()
	# Current melee guard/parry is real; ordinary unguarded and environmental damage remain unchanged.
	scene._resume()
	var hero=scene.player
	hero.position=Vector3.ZERO
	hero.rotation=Vector3.ZERO
	var enemy=scene.get_node("CampDemon0")
	enemy.position=Vector3(0,0,-2)
	hero.stamina=100
	hero._attack_cooldown=0
	hero._dodge_time=0
	hero._invulnerability_time=0
	var hp: int=hero.health
	var guard_at: Vector2=hud.control("GuardButton").get_global_rect().get_center()
	pointer(guard_at,true)
	assert(hero.guarding,"Guard touch-down must activate the real player action")
	hero.take_melee_damage(10,enemy)
	assert(hero.health==hp and hero.stamina==80,"Timed parry must prevent a frontal melee hit and spend stamina")
	hero._parry_window=0
	hero.take_melee_damage(10,enemy)
	assert(hero.health==hp-3 and hero.stamina==60,"Holding guard must reduce, not erase, ordinary melee damage")
	pointer(guard_at,false)
	assert(not hero.guarding,"Releasing guard must release the action")
	hero._invulnerability_time=0
	hero.take_damage(10)
	assert(hero.health==hp-13,"Unguarded/environmental damage must retain its old value")
	hero._attack_cooldown=0
	hero.start_guard()
	scene._pause_game()
	assert(not hero.guarding,"Menus must release guard")
	await close_world()
	await open_world()
	hud=scene.mobile_hud
	assert(hud.profile.preset=="Left-Handed" and scene.player.left_handed_controls,"Preset must survive a fresh scene")
	assert(hud.control("MovementJoystick").position.x>root.size.x*0.5)
	editor=await editor_screen()
	editor.reset_button.pressed.emit()
	editor.save_button.pressed.emit()
	await settle()
	assert(hud.profile.preset=="Battle" and hud.profile.controls.is_empty() and not scene.player.left_handed_controls)
	# Malformed profiles are never allowed to hide all controls; recover from the valid backup.
	var file:=FileAccess.open("user://hud_profile.cfg",FileAccess.WRITE)
	file.store_string("invalid profile")
	file.close()
	await close_world()
	await open_world()
	assert(scene.mobile_hud.profile.preset=="Left-Handed","Unreadable primary must fall back to its previous valid profile")
	assert(scene.remaining_enemies==5 and not scene.boss_spawned and not scene.completed)
	await close_world()
	print("PASS: separate gameplay/editor, settings path, touch drag, size/opacity, presets, save/cancel/reset/reopen, safe profiles, failed-write recovery and functional guard/parry")
	quit()
