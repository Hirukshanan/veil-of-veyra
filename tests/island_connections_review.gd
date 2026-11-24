extends "res://tests/island_check.gd"

# Review fixture only; uses the unchanged player controller and static collision.
func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	assert(scene.landscape.regions.size() == 5)
	assert(scene.get_node_or_null("Island") == null and scene.get_node_or_null("ChapterEnvironment") == null)
	assert(scene.get_node("IslandExploration").get_node_or_null("ChapterOneRegion") == null)
	assert(scene.remaining_enemies == 5)
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.65
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 4 | 8
	# Exact static surface support/headroom graph, not merely visual proximity.
	for z in range(-54,55):
		for x in range(-54,55):
			var point := Vector3(x*2,0,z*2)
			var hit: Dictionary = scene.landscape.ground_hit(point)
			if hit.is_empty() or hit.position.y < -0.6 or hit.position.y > 8 or hit.normal.y < 0.82:continue
			query.transform.origin = hit.position + Vector3.UP*0.97
			if not scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty():continue
			cells[Vector2i(x,z)] = hit.position+Vector3.UP*0.08
	# Flood from the actual player spawn with slope and lateral-obstacle checks.
	var start := Vector2i(roundi(scene.player.position.x/2),roundi(scene.player.position.z/2))
	assert(cells.has(start),"Player spawn must have walkable capsule support")
	var queue := [start]
	seen[start] = true
	var index := 0
	while index < queue.size():
		var cell: Vector2i = queue[index]
		index += 1
		for direction in directions:
			var next: Vector2i = cell+direction
			if seen.has(next) or not cells.has(next) or absf(cells[next].y-cells[cell].y)>1.2:continue
			var ray := PhysicsRayQueryParameters3D.create(cells[cell]+Vector3.UP*0.8,cells[next]+Vector3.UP*0.8,4|8)
			if not scene.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():continue
			seen[next]=true
			parent_cell[next]=cell
			queue.append(next)
	var goals: Array[Dictionary] = []
	for index_region in range(5):goals.append({"name":scene.landscape.REGION_FILES[index_region],"position":scene.landscape.safe_point(scene.landscape.REVIEW_POINTS[index_region])})
	for item in scene.herbs.plants+scene.seal_fragments.fragments:
		goals.append({"name":str(item.name),"position":item.global_position})
	goals.append({"name":"Lantern","position":scene.lantern.global_position})
	for goal in goals:
		var cell := closest(goal.position)
		var error: float = cells[cell].distance_to(goal.position) if cells.has(cell) else INF
		if error>3.0:result.unreachable.append({"name":goal.name,"error":error,"position":goal.position})
		result.routes.append({"name":goal.name,"distance_to_route":error,"route":route_to(goal.position)})
	result["walkable_cells"] = cells.size()
	result["connected_cells"] = seen.size()
	result["spawn"] = scene.player.global_position
	result["placements"] = scene.placement_log
	var f := FileAccess.open("res://.validation/island_visual_2026-11-15/connection_routes.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	assert(result.unreachable.is_empty(),"Every region/quest needs a connected capsule-clear route: "+str(result.unreachable))

	scene._resume()
	Engine.time_scale = 4.0
	scene.player._camera_pivot.rotation = Vector3.ZERO
	var initial_health: int = scene.player.health
	var legs: Array[Dictionary] = []
	var trace: Array[Dictionary] = []
	var region_names := ["WaterfallMountains","WesternForest","RiverGrassland","EasternCaves","SouthernBeach"]
	for region_index in range(5):
		var destination: Vector3 = scene.landscape.safe_point(scene.landscape.REVIEW_POINTS[region_index])
		var planned := route_to(destination)
		assert(planned.size()>0)
		for returning in [false,true]:
			var path := planned.duplicate()
			if returning:path.reverse()
			var ticks := 0
			var distance := 0.0
			var before: Vector3 = scene.player.position
			var leg_start: Vector3 = before
			var blocked := false
			for point in path:
				var waypoint_ticks := 0
				while Vector2(scene.player.position.x-point.x,scene.player.position.z-point.z).length()>0.55 and waypoint_ticks<150:
					var offset: Vector3 = point-scene.player.position
					scene.player.set_move_input(Vector2(offset.x,offset.z).normalized())
					await physics_frame
					waypoint_ticks+=1
					ticks+=1
					distance+=scene.player.position.distance_to(before)
					before=scene.player.position
					if ticks%8==0:trace.append({"region":region_names[region_index],"returning":returning,"tick":ticks,"position":[before.x,before.y,before.z],"health":scene.player.health,"grounded":scene.player.is_on_floor()})
				if waypoint_ticks>=150:
					blocked=true
					break
				assert(scene.player.health==initial_health and scene.player.position.y>-1.0,"Connection travel must not use fall/rescue or lose health")
			scene.player.set_move_input(Vector2.ZERO)
			legs.append({"region":region_names[region_index],"returning":returning,"waypoints":path.size(),"ticks":ticks,"distance_walked_m":distance,"start":[leg_start.x,leg_start.y,leg_start.z],"end":[scene.player.position.x,scene.player.position.y,scene.player.position.z],"blocked":blocked,"health":scene.player.health})
			result["legs"]=legs
			result["trace"]=trace
			var output:=FileAccess.open("res://.validation/island_visual_2026-11-15/connection_walk.json",FileAccess.WRITE)
			output.store_string(JSON.stringify(result,"  "))
			assert(not blocked,"Real hero blocked on "+region_names[region_index]+(" return" if returning else " outward"))
			print("REGION_WALK_PASS ",region_names[region_index]," return=",returning," distance_m=",snappedf(distance,.01)," ticks=",ticks)
	result["all_five_regions_walked_both_directions"]=true
	result["health_preserved"]=scene.player.health==initial_health
	var output:=FileAccess.open("res://.validation/island_visual_2026-11-15/connection_walk.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  "))
	scene.queue_free()
	paused=false
	await process_frame
	print("PASS: actual existing hero walked outward and back across all five regional approaches, without teleports between legs, damage, fall or rescue")
	quit()
