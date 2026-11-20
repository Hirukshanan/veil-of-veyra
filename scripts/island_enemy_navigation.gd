extends Node3D

# Shared static graph over the encounter areas and their approaches.
const STEP:=2.0
const REGIONS := [
	Rect2i(-48, -26, 43, 51), # Western woods
	Rect2i(8, -32, 22, 20), # Northern foothills
	Rect2i(10, 10, 14, 19), # Southern grassland
]
var graph:=AStar3D.new()
var points:Dictionary={}
var routes:Dictionary={}
var shortcuts:Dictionary={}
var landscape:Node3D
var build_ms:=0.0
var path_requests:=0
var _capsule:CapsuleShape3D

func populate(source:Node3D)->void:
	landscape=source;var start:=Time.get_ticks_usec()
	_capsule=CapsuleShape3D.new();_capsule.radius=1.0;_capsule.height=2.8
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=_capsule;query.collision_mask=4|8
	for region in REGIONS:
		for z in range(region.position.y, region.end.y):
			for x in range(region.position.x, region.end.x):
				var hit:Dictionary=landscape.ground_hit(Vector3(x*STEP,0,z*STEP))
				if hit.is_empty() or hit.normal.y<.86 or hit.position.y<.1:continue
				query.transform.origin=hit.position+Vector3.UP*1.53
				if not get_world_3d().direct_space_state.intersect_shape(query).is_empty():continue
				var key:=Vector2i(x,z);var id:=points.size()
				points[key]=id;graph.add_point(id,hit.position+Vector3.UP*.08)
	for key in points:
		for delta in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i(1,1),Vector2i(-1,1)]:
			var other:Vector2i=key+delta
			if not points.has(other):continue
			if abs(delta.x)+abs(delta.y)==2 and (not points.has(key+Vector2i(delta.x,0)) or not points.has(key+Vector2i(0,delta.y))):continue
			var a:Vector3=graph.get_point_position(points[key]);var b:Vector3=graph.get_point_position(points[other])
			if absf(a.y-b.y)>.9 or not _clear(a,b):continue
			graph.connect_points(points[key],points[other])
	build_ms=(Time.get_ticks_usec()-start)/1000.0

func _clear(a:Vector3,b:Vector3)->bool:
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=_capsule
	query.transform.origin=a+Vector3.UP*(1.52+maxf(0,b.y-a.y))
	query.motion=Vector3(b.x-a.x,0,b.z-a.z);query.collision_mask=4|8
	# cast_motion ignores starting overlaps; reject them before a shortcut.
	if not get_world_3d().direct_space_state.intersect_shape(query).is_empty():return false
	return get_world_3d().direct_space_state.cast_motion(query)[0]>.98

func direction(actor:Node3D,goal:Vector3)->Vector3:
	var offset:Vector3=goal-actor.global_position;offset.y=0
	if offset.length()<.3:return Vector3.ZERO
	var key:int=actor.get_instance_id();var now:float=Time.get_ticks_msec()*.001
	# Sense static shortcuts at most five times per second, not every physics tick.
	# Actual CharacterBody collision remains authoritative between observations.
	var shortcut:Dictionary=shortcuts.get(key,{})
	if shortcut.is_empty() or now>shortcut.until or goal.distance_to(shortcut.goal)>1:
		shortcut={"until":now+.2,"goal":goal,"clear":absf(goal.y-actor.position.y)<.8 and _clear(actor.global_position,goal)}
		shortcuts[key]=shortcut
	if shortcut.clear:return offset.normalized()
	var route:Dictionary=routes.get(key,{})
	if route.is_empty() or now>route.until or Vector2(goal.x-route.goal.x,goal.z-route.goal.z).length()>2:
		var start_id:int=graph.get_closest_point(actor.global_position)
		var end_id:int=graph.get_closest_point(goal)
		var path:PackedVector3Array=graph.get_point_path(start_id,end_id)
		route={"path":path,"index":0,"until":now+.6,"goal":goal};routes[key]=route;path_requests+=1
	var path:PackedVector3Array=route.path
	while route.index<path.size() and Vector2(path[route.index].x-actor.position.x,path[route.index].z-actor.position.z).length()<.7:route.index+=1
	if route.index>=path.size():return Vector3.ZERO
	var direction_vector:Vector3=path[route.index]-actor.global_position;direction_vector.y=0
	return direction_vector.normalized()
