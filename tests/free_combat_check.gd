extends SceneTree

func _initialize(): call_deferred("run")

func frames(count: int):
	for i in range(count): await physics_frame

func tab(pressed: bool):
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_TAB
	event.pressed=pressed
	Input.parse_input_event(event)

func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	var hero=scene.player
	var enemies=get_nodes_in_group("combat_enemies")
	assert(enemies.size()==5,"The shared registry must retain all five campaign enemies")
	for enemy in enemies:
		enemy.set_physics_process(false)
		enemy.position=Vector3(40,0,0)
	var enemy=enemies[0]
	enemy.position=Vector3(1.2,0,0)
	enemy.health=100
	hero.position=Vector3.ZERO
	hero.rotation=Vector3.ZERO
	hero._camera_pivot.rotation=Vector3.ZERO
	assert(not InputMap.has_action("target_lock"),"Tab must no longer bind a combat action")
	assert(not hero.has_method("toggle_target_lock") and not hero.has_method("switch_target_lock") and not hero.has_method("clear_target_lock"),"Target selection behavior must be removed")
	assert(scene.find_child("TargetLockButton",true,false)==null and scene.find_child("TargetSwitchButton",true,false)==null)
	assert(hero.find_children("*","Label3D",true,false).is_empty(),"The target marker must not be created")
	tab(true)
	await frames(8)
	assert(absf(hero.rotation.y)<0.001 and absf(hero._camera_pivot.rotation.y)<0.001,"Nearby enemies and Tab must not steer the hero or camera")
	tab(false)
	hero.set_move_input(Vector2.RIGHT)
	await frames(20)
	assert((-hero.global_basis.z).dot(Vector3.RIGHT)>0.95,"Movement must still turn the hero freely")
	hero.set_move_input(Vector2.ZERO)
	hero.set_physics_process(false)
	hero.position=Vector3.ZERO
	hero.rotation=Vector3.ZERO
	hero.velocity=Vector3.ZERO
	hero._rotate_camera(Vector2(25,0))
	assert(hero._camera_pivot.rotation.y<0 and absf(hero.rotation.y)<0.001,"Manual camera look must remain independent of stationary hero facing")
	# Sword damage still uses the player's forward overlap, without selecting an enemy.
	enemy.position=Vector3(0,0,-1.2)
	await frames(4)
	hero.attack()
	await create_timer(0.25).timeout
	await frames(4)
	assert(enemy.health==100-hero.attack_damage,"A freely aimed sword must still deal its ordinary damage")
	scene._pause_game()
	scene._show_enemy_guide()
	for label in scene.menu_box.find_children("*","Label",true,false):
		assert("LOCK ON" not in label.text and "crosshair" not in label.text,"The guide must not advertise retired controls")
	scene._resume()
	assert(not InputMap.has_action("target_lock"),"Menus must not restore the removed binding")
	scene.queue_free()
	await process_frame
	paused=false
	print("PASS: no target buttons, binding, marker or selection API; Tab leaves facing/camera alone; free movement, manual camera and sword damage remain functional")
	quit()
