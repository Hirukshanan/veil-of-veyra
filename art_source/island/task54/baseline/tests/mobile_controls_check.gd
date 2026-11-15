extends SceneTree
var scene
var taps := 0
func _initialize(): call_deferred("run")
func touch(at: Vector2, pressed: bool, index: int):
	var e:=InputEventScreenTouch.new()
	e.position=at
	e.pressed=pressed
	e.index=index
	root.push_input(e)
func drag(at: Vector2, relative: Vector2, index: int):
	var e:=InputEventScreenDrag.new()
	e.position=at
	e.relative=relative
	e.index=index
	root.push_input(e)
func tap(control: Control, index:=4):
	touch(control.get_global_rect().get_center(),true,index)
	touch(control.get_global_rect().get_center(),false,index)
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.size=Vector2i(1280,720)
	scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	var hero=scene.player
	hero.set_physics_process(false)
	hero.position=Vector3.ZERO
	for enemy in get_nodes_in_group("combat_enemies"):
		enemy.set_physics_process(false)
	assert(scene.find_child("TargetLockButton",true,false)==null,"Target lock must not appear in gameplay")
	assert(scene.find_child("TargetSwitchButton",true,false)==null,"Target switch must not appear in gameplay")
	var joystick=get_first_node_in_group("movement_joysticks")
	var joy: Vector2=joystick.get_global_rect().get_center()
	touch(joy,true,0)
	drag(joy+Vector2(35,0),Vector2(35,0),0)
	assert(hero._touch_move.x>0.1)
	var camera_at:=Vector2(900,330)
	var yaw: float=hero._camera_pivot.rotation.y
	touch(camera_at,true,1)
	drag(camera_at+Vector2(24,0),Vector2(24,0),1)
	assert(hero._camera_pivot.rotation.y<yaw)
	var attack=scene.find_child("AttackButton",true,false)
	attack.tap_requested.connect(func(): taps+=1)
	tap(attack,2)
	assert(taps==1 and hero._touch_move.x>0.1,"Third pointer attack must coexist with joystick/camera")
	yaw=hero._camera_pivot.rotation.y
	drag(joy+Vector2(40,0),Vector2(5,0),0)
	assert(hero._camera_pivot.rotation.y==yaw,"Joystick drag must never turn camera")
	touch(joy,false,0)
	touch(camera_at,false,1)
	assert(hero._touch_move==Vector2.ZERO and hero._camera_pointer==-1)
	# Menu must cancel an active camera finger, including a later stray drag.
	touch(camera_at,true,3)
	scene._pause_game()
	yaw=hero._camera_pivot.rotation.y
	drag(camera_at,Vector2(50,0),3)
	scene._resume()
	drag(camera_at,Vector2(50,0),3)
	assert(hero._camera_pivot.rotation.y==yaw and hero._camera_pointer==-1)
	for resolution in [Vector2i(800,450),Vector2i(1280,720),Vector2i(1920,864)]:
		root.size=resolution
		for frame in range(4): await process_frame
		for handed in [false,true]:
			for scale_value in [0.85,1.0,1.2]:
				scene.left_handed=handed
				scene.hud_scale=scale_value
				scene._apply_settings()
				var movement_rect: Rect2=joystick.get_global_rect()
				var attack_rect: Rect2=attack.get_global_rect()
				assert(movement_rect.size.is_equal_approx(attack_rect.size),"Default joystick and attack must share the same primary size")
				assert(is_equal_approx(movement_rect.get_center().y,attack_rect.get_center().y),"Primary controls must sit at the same height")
				assert(is_equal_approx(movement_rect.get_center().x+attack_rect.get_center().x,resolution.x),"Primary controls must mirror across the viewport")
				for key in ["DodgeButton","JumpButton","GuardButton","SprintButton","SpiritBurstButton","InteractButton"]:
					assert(scene.mobile_hud.control(key).size.x<attack.size.x,"Secondary controls must remain smaller than attack")
				var controls=[]
				for button in scene.find_children("*","Button",true,false):
					if scene.overlay.is_ancestor_of(button): continue
					assert(Rect2(Vector2.ZERO,Vector2(resolution)).grow(1).encloses(button.get_global_rect()),"Scaled HUD must stay inside viewport")
					controls.append(button)
				for i in range(controls.size()):
					assert(not joystick.get_global_rect().intersects(controls[i].get_global_rect()),"Actions cannot overlap movement")
					for j in range(i):
						assert(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()),"Action buttons must not overlap")
	for resolution in [Vector2i(800,450),Vector2i(1280,720)]:
		root.size=resolution
		for frame in range(4): await process_frame
		var bounds:=Rect2(Vector2(44,12),Vector2(resolution)-Vector2(68,36))
		for control in scene.find_children("*","Control",true,false):
			if control.get_script()==load("res://scripts/safe_area.gd"):
				control.test_safe_rect=bounds
				control.refresh()
		for handed in [false,true]:
			for scale_value in [0.85,1.2]:
				scene.left_handed=handed
				scene.hud_scale=scale_value
				scene._apply_settings()
				for button in scene.find_children("*","Button",true,false):
					if scene.overlay.is_ancestor_of(button): continue
					assert(bounds.grow(1).encloses(button.get_global_rect()),"Mirrored/scaled actions must honor cutout insets")
	scene._show_settings(scene._show_camp)
	scene.invert_y=false
	scene.left_handed=false
	var invert=scene.menu_box.get_node("InvertYToggle")
	invert.button_pressed=false
	invert.button_pressed=true
	assert(scene.invert_y and not scene.left_handed,"Invert toggle must change only camera setting")
	# Mirroring is now offered by the separate HUD editor presets; legacy settings still load.
	scene.left_handed=true
	scene._apply_settings()
	assert(scene.left_handed and scene.invert_y,"Handedness must preserve camera setting")
	scene._resume()
	touch(Vector2(300,300),true,7)
	assert(hero._camera_pointer==7,"Mirrored controls must also mirror the open camera zone")
	touch(Vector2(300,300),false,7)
	assert(scene._save_settings()==OK)
	scene.hud_scale=1.0
	scene.left_handed=false
	scene.invert_y=false
	scene._load_settings()
	assert(scene.hud_scale==1.2 and scene.left_handed and scene.player.invert_y)
	scene.queue_free()
	await process_frame
	paused=false
	scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.hud_scale==1.2 and scene.left_handed and scene.player.invert_y,"Control profile must survive a fresh scene")
	joystick=get_first_node_in_group("movement_joysticks")
	assert(joystick.get_global_rect().get_center().x>root.size.x*0.5,"Saved handedness must apply on scene creation")
	scene.queue_free()
	await process_frame
	paused=false
	print("PASS: clean gameplay HUD without target controls, three-pointer movement/camera/attack input, menu cancellation, safe-area bounds and saved layouts")
	quit()
