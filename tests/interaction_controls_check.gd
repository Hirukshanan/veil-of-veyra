extends SceneTree
var scene
var light_taps := 0
var heavy_taps := 0
func _initialize(): call_deferred("run")
func key(pressed: bool, repeat_event := false):
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = pressed
	event.echo = repeat_event
	root.push_input(event)
func touch(button: Control, pressed: bool, index := 0, outside := false):
	var event := InputEventScreenTouch.new()
	event.index=index
	event.position=button.get_global_rect().get_center() if not outside else Vector2(2,200)
	event.pressed=pressed
	root.push_input(event)
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	root.size=Vector2i(800,450)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("lock_targets"): enemy.set_physics_process(false)
	scene.player.position=scene.herbs.LOCATIONS[0]
	await process_frame
	var potions:int=scene.potions
	key(true)
	key(false)
	await process_frame
	assert(scene.herbs.collected==1 and scene.potions==potions+1,"Quick E tap must collect")
	key(true,true)
	assert(scene.herbs.collected==1,"Key repeat must not harvest")
	scene.player.position=scene.herbs.LOCATIONS[1]
	await process_frame
	var interact=scene.interact_button
	touch(interact,true)
	assert(scene.herbs.collected==2,"Touch down must collect immediately")
	scene.player.position.x+=2.1
	await process_frame
	touch(interact,false)
	assert(scene.herbs.collected==2,"Moving away before release must not undo collection")
	key(true)
	key(false)
	assert(scene.herbs.collected==2,"Out-of-range input must not collect")
	scene.player.position=scene.herbs.LOCATIONS[2]
	scene._pause_game()
	key(true)
	key(false)
	assert(scene.herbs.collected==2,"Pause must guard input even though overlay receives it")
	scene._resume()
	var attack=scene.find_child("AttackButton",true,false)
	attack.tap_requested.connect(func(): light_taps+=1)
	attack.heavy_requested.connect(func(): heavy_taps+=1)
	assert(scene.find_child("HeavyAttackButton",true,false)==null and scene.find_child("TargetLockButton",true,false)!=null)
	for layer in scene.get_children():
		if layer is CanvasLayer and layer!=scene.overlay:
			for button in layer.find_children("*","Button",true,false):
				assert(button.text.is_empty() and button.icon!=null,"HUD actions must be icon-only")
	await process_frame
	touch(attack,true)
	touch(attack,false)
	assert(light_taps==1 and heavy_taps==0,"Short touch releases one light attack")
	scene.player.cancel_swing()
	scene.player._attack_cooldown=0
	await process_frame
	touch(attack,true)
	attack._process(0.41)
	assert(heavy_taps==1 and scene.player.stamina==60,"Hold must trigger a heavy attack and its real stamina cost")
	attack._process(0.6)
	touch(attack,false)
	assert(light_taps==1 and heavy_taps==1,"Holding and releasing must never double-fire")
	scene.player.cancel_swing()
	scene.player._attack_cooldown=0
	touch(attack,true)
	scene._pause_game()
	scene._resume()
	touch(attack,false)
	assert(light_taps==1 and heavy_taps==1,"Menus must cancel pending hold")
	touch(attack,true)
	touch(attack,false,0,true)
	assert(light_taps==1 and heavy_taps==1,"Outside release must cancel")
	# Insufficient stamina consumes the hold without falling back to a light hit.
	scene.player.stamina=20
	touch(attack,true)
	attack._process(0.41)
	touch(attack,false)
	assert(scene.player.stamina==20 and light_taps==1 and heavy_taps==2)
	scene.player.cancel_swing()
	await create_timer(1.3).timeout
	scene.queue_free()
	await process_frame
	paused=false
	print("PASS: quick E, moving touch harvest, range/pause guards, icon-only HUD, short tap, held heavy, no repeats and hold cancellation")
	quit()
