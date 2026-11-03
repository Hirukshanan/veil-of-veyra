extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for frame in range(4):
		await physics_frame

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	var hero = scene.player
	for child in scene.get_children():
		if child.get_script() == scene.ENEMY_SCRIPT:
			child.set_physics_process(false)
	hero.set_camera_distance(6.3)
	await _settle()
	var arm: SpringArm3D = hero._camera_arm
	assert(absf(arm.get_hit_length() - 6.3) < 0.1, "Clear camera must not collide with its owner")
	var wall := StaticBody3D.new()
	wall.collision_layer = 4
	wall.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 6, 0.5)
	shape.shape = box
	wall.add_child(shape)
	scene.add_child(wall)
	wall.global_position = arm.global_position + arm.global_basis.z * 3.0
	await _settle()
	assert(arm.get_hit_length() < 3.0 and arm.get_hit_length() > 1.0, "Camera must retract before the wall")
	var camera := arm.get_child(0) as Camera3D
	assert(camera.global_position.distance_to(arm.global_position) < 3.0)
	wall.queue_free()
	await _settle()
	assert(absf(arm.get_hit_length() - 6.3) < 0.1, "Camera must extend when obstruction clears")
	hero.set_camera_distance(8.0)
	await _settle()
	assert(absf(arm.get_hit_length() - 8.0) < 0.1)
	hero._camera_pivot.rotation.x = 0.5
	await _settle()
	assert(arm.get_hit_length() < 8.0, "Low camera angle must collide with terrain")
	assert(camera.global_position.y > 0.1)
	print("PASS: camera owner exclusion, obstacle retraction, clear-path extension, distance setting and terrain collision")
	scene.queue_free()
	await process_frame
	quit()
