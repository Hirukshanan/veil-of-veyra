extends SceneTree
var scene
var output:String
var rows:Array=[]
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	scene._resume();Engine.time_scale=4
	var hero=scene.player;hero._camera_pivot.rotation=Vector3.ZERO
	for z in [-62.,-52.,-40.,-25.,-10.,5.,20.,35.,50.,65.,80.,95.,105.]:
		for side in [-1.,1.]:
			var cx:float=scene.landscape.SURFACE.river_center(z);var width:float=scene.landscape.SURFACE.river_width(z)
			var bank:=Vector3(cx+side*(width+9),0,z);bank=scene.landscape.ground_point(bank)+Vector3.UP*.08
			hero.position=bank;hero.velocity=Vector3.ZERO;hero.health=100
			var entered:bool=await walk(Vector2(cx,z),180)
			var bottom:Vector3=hero.position
			var escaped:bool=await walk(Vector2(bank.x,z),240)
			var end:Vector3=hero.position
			var row:={"z_m":z,"bank":"west" if side<0 else "east","start_m":bank,"river_m":bottom,"end_m":end,"entered":entered,"escaped_walking":escaped,"health_preserved":hero.health==100,"no_rescue":hero.position.y> -5,"water_y_m":scene.landscape.SURFACE.river_level(z)}
			rows.append(row);print("RIVER ",z," ",row.bank," entry=",entered," escape=",escaped)
	FileAccess.open(output+"/river_movement.json",FileAccess.WRITE).store_string(JSON.stringify({"controller":"unmodified player.gd, normal walking input, 4x simulated time; teleport only between independent fixtures, never during an entry/escape","rows":rows},"  "))
	assert(rows.all(func(row):return row.entered and row.escaped_walking and row.health_preserved and row.no_rescue),"Every accessible river test must enter and escape with the real controller")
	hero.set_move_input(Vector2.ZERO);scene.queue_free();await process_frame
	print("RESULT river passes ",rows.filter(func(row):return row.entered and row.escaped_walking and row.health_preserved).size(),"/",rows.size());quit()
func walk(target:Vector2,frames:int)->bool:
	var hero=scene.player
	for frame in range(frames):
		var delta:Vector2=target-Vector2(hero.position.x,hero.position.z)
		if delta.length()<.55:hero.set_move_input(Vector2.ZERO);return true
		hero.set_move_input(delta.normalized());await physics_frame
	hero.set_move_input(Vector2.ZERO);return false
