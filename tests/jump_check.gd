extends SceneTree
const TERRAIN=preload("res://scripts/island_terrain.gd")
var scene
var hero
func _initialize(): call_deferred("run")
func frames(count: int):
	for index in range(count): await physics_frame
func touch(button: Button,pressed: bool):
	var event:=InputEventScreenTouch.new()
	event.index=0
	event.position=button.get_global_rect().get_center()
	event.pressed=pressed
	root.push_input(event)
func space(pressed: bool,echo:=false):
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_SPACE
	event.keycode=KEY_SPACE
	event.pressed=pressed
	event.echo=echo
	root.push_input(event)
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.size=Vector2i(800,450)
	scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	hero=scene.player
	for enemy in get_nodes_in_group("combat_enemies"): enemy.set_physics_process(false)
	await frames(12)
	var button=scene.find_child("JumpButton",true,false)
	assert(button!=null and button.icon!=null and button.text.is_empty())
	assert(button.accessibility_name=="Jump" and not button.disabled)
	assert(button._has_point(button.size*0.5) and not button._has_point(Vector2.ZERO))
	for other in scene.find_children("*","Button",true,false):
		if other!=button and not scene.overlay.is_ancestor_of(other):
			assert(not button.get_global_rect().intersects(other.get_global_rect()),"Jump must not overlap another action")
	assert(hero.can_jump())
	var ground: float=hero.position.y
	# Quick keyboard input is event-driven, and Space no longer triggers dodge.
	space(true)
	space(false)
	assert(hero._jumping and is_equal_approx(hero.velocity.y,hero.JUMP_SPEED) and hero._dodge_time==0)
	assert(not hero.can_jump())
	assert(hero._visual.animator.current_animation=="Jump_Start")
	await frames(12)
	assert(hero.position.y>ground+0.7 and not hero.is_on_floor())
	assert(hero._visual.animator.current_animation=="Jump")
	var velocity: float=hero.velocity.y
	hero.jump()
	assert(hero.velocity.y==velocity,"Repeated midair jump must not add height")
	var saw_landing := false
	for index in range(42):
		await physics_frame
		saw_landing = saw_landing or hero._visual.animator.current_animation == "Jump_Land"
	assert(saw_landing,"Landing must play its own animation before returning to idle")
	assert(hero.is_on_floor() and absf(hero.position.y-ground)<0.1 and hero.can_jump())
	assert(hero._visual.animator.current_animation=="Sword_Idle")
	space(true,true)
	assert(not hero._jumping,"Keyboard repeat must not cause a jump")
	space(false)
	# Real GUI touch-down launches once; holding through landing never auto-repeats.
	await frames(5)
	hero.set_move_input(Vector2(0,-1))
	var origin: Vector3=hero.position
	assert(not button.disabled and hero.can_jump(),"Jump button must become available after landing")
	touch(button,true)
	assert(hero._jumping,"Touch-down must launch a grounded jump")
	var peak:=ground
	for index in range(54):
		await physics_frame
		peak=maxf(peak,hero.position.y)
	touch(button,false)
	hero.set_move_input(Vector2.ZERO)
	assert(peak>ground+1.0 and peak<ground+1.5,"Jump height must remain bounded")
	assert(hero.position.distance_to(origin)>2.0,"Movement must continue while jumping")
	assert(hero.is_on_floor() and not hero._jumping)
	# Shared guards protect menu, death and committed combat actions.
	scene._pause_game()
	hero.jump()
	assert(not hero._jumping)
	scene._resume()
	hero.health=0
	hero.jump()
	assert(not hero._jumping)
	hero.health=100
	for key in ["_attack_cooldown","_dodge_time","_hit_time"]:
		hero.set(key,0.2)
		hero.jump()
		assert(not hero._jumping)
		hero.set(key,0.0)
	# Jumping outward must not bypass the sea wall, including low physics FPS.
	var ticks_before:=Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second=15
	var angle:=PI*0.5
	var coast:=TERRAIN.coast_radius(angle,TERRAIN.SHALLOW_WATER_BASE)
	hero.position=Vector3(0,-1.0,coast-1.5)
	hero.velocity=Vector3.ZERO
	hero._camera_pivot.rotation=Vector3.ZERO
	await frames(10)
	assert(hero.can_jump())
	hero.jump()
	hero.set_move_input(Vector2(0,1))
	for index in range(22):
		await physics_frame
		var point:=Vector2(hero.position.x,hero.position.z)
		assert(point.length()<TERRAIN.coast_radius(point.angle(),TERRAIN.SHALLOW_WATER_BASE)-0.38,"Jump must not cross the deep-water boundary")
	assert(hero.is_on_floor() and hero.health==100)
	Engine.physics_ticks_per_second=ticks_before
	scene.queue_free()
	await process_frame
	paused=false
	print("PASS: round nonoverlapping jump icon, keyboard/touch launch, start/air/landing motion, bounded height, moving jumps, no repeat/double jump, action guards and sea-wall collision at 15 FPS")
	quit()
