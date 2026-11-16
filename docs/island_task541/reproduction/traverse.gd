extends SceneTree
func _initialize():call_deferred("run")
func run():
	var out:String=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out+"/frames")
	var game=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(game)
	while not game.placement_ready:await physics_frame
	game._resume()
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	var hero=game.player
	hero.position=Vector3(76,1.65,-14)
	var targets=[Vector2(76,5),Vector2(75,10),Vector2(71,15),Vector2(68,19),Vector2(66,25),Vector2(68,19),Vector2(71,15),Vector2(75,10),Vector2(76,5),Vector2(76,-14)]
	var step:=0
	var ticks:=0
	var frames:=0
	while step<targets.size() and ticks<2400:
		var delta:Vector2=targets[step]-Vector2(hero.position.x,hero.position.z)
		if delta.length()<.55:
			print("REACHED ",step," ",hero.position)
			step+=1
			continue
		var direction:=Vector3(delta.x,0,delta.y).normalized()
		var yaw:=atan2(-direction.x,-direction.z)
		hero._camera_pivot.rotation.y=lerp_angle(hero._camera_pivot.rotation.y,yaw,.045)
		var move:=direction.rotated(Vector3.UP,-hero._camera_pivot.rotation.y)
		hero.set_move_input(Vector2(move.x,move.z))
		await physics_frame
		ticks+=1
		if ticks%4==0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(out+"/frames/%04d.jpg"%frames,.85)
			frames+=1
	print("ROUTE steps=",step," position=",hero.position," relic=",game.relic_hunt.collected_ids)
	quit(0 if step==targets.size() and 1 in game.relic_hunt.collected_ids else 1)
