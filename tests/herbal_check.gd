extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	scene.player.set_physics_process(false)
	scene.player.position=scene.herbs.LOCATIONS[0]
	var before:int=scene.potions
	paused=true
	scene._interact_world()
	assert(scene.potions==before)
	paused=false
	scene._update_objective()
	assert("COLLECT" in scene.interact_button.text)
	scene.interact_button.pressed.emit()
	assert(scene.potions==before+1 and scene.herbs.collected==1)
	scene._interact_world()
	assert(scene.potions==before+1,"No duplicate harvest")
	scene.player.health=30
	scene._heal()
	assert(scene.player.health>30 and scene.potions==before)
	assert("1/5" in scene.herbs.journal_text())
	scene.queue_free()
	await process_frame
	print("PASS: harvest button, pause guard, single harvest, healing and journal progress")
	quit()
