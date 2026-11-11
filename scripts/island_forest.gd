extends Node3D

const TERRAIN = preload("res://scripts/island_terrain.gd")
const TREE_MESH = preload("res://assets/environment/forest_tree_mobile.res")
var clearings: Array[Vector4] = []
var tree_positions: Array[Vector3] = []
var tree_heights: Array[float] = []

func _ready() -> void:
	name="TallForests"
	var trail := TERRAIN.trail_mask().get_image()
	var rng := RandomNumberGenerator.new()
	rng.seed=50619
	var cells := {}
	for x in range(-10,11):
		for z in range(-10,8):
			var point:=Vector2(x*7.5+rng.randf_range(-1.2,1.2),z*7.5+rng.randf_range(-1.2,1.2))
			if not _inside_forest(point) or not _clear_ground(point,trail): continue
			var at:=Vector3(point.x,TERRAIN.height_at(point),point.y)
			var width:=rng.randf_range(1.2,1.55)
			var height:=rng.randf_range(2.6,3.4)
			var basis:=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(width,height,width))
			var key:=Vector2i(floori(point.x/20.0),floori(point.y/20.0))
			if not cells.has(key): cells[key]=[]
			cells[key].append(Transform3D(basis,at-Vector3(key.x*20,0,key.y*20)))
			tree_positions.append(at)
			tree_heights.append(TREE_MESH.get_aabb().size.y*height)
			var trunk:=StaticBody3D.new()
			trunk.name="ForestTrunk%d"%tree_positions.size()
			trunk.position=at
			trunk.collision_layer=4|8
			trunk.collision_mask=0
			var collision:=CollisionShape3D.new()
			var shape:=CylinderShape3D.new()
			shape.radius=0.38*width
			shape.height=3.0*height
			collision.shape=shape
			collision.position.y=shape.height*0.5
			trunk.add_child(collision)
			add_child(trunk)
	# Spatial batches keep new forests from adding one draw call per tree/surface.
	for key in cells:
		var patch:=MultiMeshInstance3D.new()
		patch.name="ForestCell_%d_%d"%[key.x,key.y]
		patch.position=Vector3(key.x*20,0,key.y*20)
		patch.visibility_range_end=70.0
		var instances:=MultiMesh.new()
		instances.transform_format=MultiMesh.TRANSFORM_3D
		instances.mesh=TREE_MESH
		instances.instance_count=cells[key].size()
		for index in range(instances.instance_count):
			instances.set_instance_transform(index,cells[key][index])
		patch.multimesh=instances
		add_child(patch)
		var canopy:=MultiMeshInstance3D.new()
		canopy.name=patch.name+"_Canopy"
		canopy.position=patch.position
		canopy.visibility_range_end=patch.visibility_range_end
		var leaves:=MultiMesh.new()
		leaves.transform_format=MultiMesh.TRANSFORM_3D
		leaves.mesh=preload("res://scripts/tree_canopy.gd").mesh()
		leaves.instance_count=instances.instance_count
		for index in range(leaves.instance_count):
			leaves.set_instance_transform(index,instances.get_instance_transform(index))
		canopy.multimesh=leaves
		add_child(canopy)

static func _inside_forest(point: Vector2) -> bool:
	for region in TERRAIN.FORESTS:
		if ((point-Vector2(region.x,region.y))/Vector2(region.z,region.w)).length()<1.0:
			return true
	return false

func _clear_ground(point: Vector2,trail: Image) -> bool:
	if TERRAIN.contour(point)>TERRAIN.GRASS_RADIUS-6.0: return false
	var pixel:=Vector2i((point/TERRAIN.TRAIL_SPAN+Vector2.ONE*0.5)*512.0)
	if trail.get_pixelv(pixel).r>0.02: return false
	for clearing in clearings:
		if point.distance_to(Vector2(clearing.x,clearing.z))<clearing.w: return false
	for herb in preload("res://scripts/herbal_plants.gd").LOCATIONS:
		if point.distance_to(Vector2(herb.x,herb.z))<2.5: return false
	for relic in [Vector2(-22,15),Vector2(22,-7),Vector2(-6,-29)]:
		if point.distance_to(relic)<3.0: return false
	return true
