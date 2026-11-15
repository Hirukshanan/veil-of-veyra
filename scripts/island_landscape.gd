extends Node3D

# Connected ground is deliberately independent of the five regional diorama slabs.
const REGION_FILES := ["WaterfallMountains", "WesternForest", "RiverGrassland", "EasternCaves", "SouthernBeach"]
const TERRAIN = preload("res://scripts/island_terrain.gd")
const SURFACE = preload("res://assets/environment/new_island/terrain_surface.res")
const REGION_CENTERS := [Vector2(0,-68), Vector2(-64,-8), Vector2(5,2), Vector2(68,-10), Vector2(0,66)]
const REVIEW_POINTS := [Vector3(0,0,-37), Vector3(-64,0,12), Vector3(8,0,24), Vector3(68,0,-36), Vector3(0,0,82)]
var regions: Array[Node3D] = []
var ground_triangles := 0
var ready_for_play := false

static func height_at(p: Vector2) -> float:
	return SURFACE.sample(p)

func _ready() -> void:
	name = "NewIslandLandscape"
	_build_ground()
	for region_name in REGION_FILES:
		var region: Node3D = load("res://assets/environment/new_island/"+region_name+".glb").instantiate()
		region.name = region_name
		add_child(region)
		regions.append(region)
		for mesh in region.find_children("*", "MeshInstance3D", true, false):
			var bounds: AABB = mesh.mesh.get_aabb()
			var source: StandardMaterial3D = mesh.get_active_material(0)
			var material := ShaderMaterial.new()
			material.shader = preload("res://assets/environment/new_island/region.gdshader")
			material.set_shader_parameter("source_map",source.albedo_texture)
			material.set_shader_parameter("vertex_blend",region_name!="WesternForest")
			material.set_shader_parameter("waterfall_region",region_name=="WaterfallMountains")
			material.set_shader_parameter("footprint",Vector4(bounds.get_center().x,bounds.get_center().z,bounds.size.x*0.5,bounds.size.z*0.5))
			material.set_shader_parameter("grass",preload("res://assets/environment/polyhaven/leafy_grass_Diffuse.jpg"))
			material.set_shader_parameter("sand",preload("res://assets/environment/polyhaven/coast_sand_01_Diffuse.jpg"))
			material.set_shader_parameter("soil",preload("res://assets/environment/polyhaven/forest_ground_04_Diffuse.jpg"))
			material.set_shader_parameter("trail_mask",TERRAIN.trail_mask())
			mesh.material_override = material
			# Update the existing render mesh before building its matching physics shape.
			preload("res://scripts/island_accessibility.gd").fit_region(mesh,region_name,SURFACE)
			mesh.create_trimesh_collision()
			var body: StaticBody3D = mesh.get_child(0)
			body.collision_layer = 1 | 4 | 8 | 16
			if region_name=="WesternForest":
				# This hidden fused prototype no longer matches the approved instanced trees.
				body.free()
				continue
			body.collision_mask = 0
			var collision_shape: ConcavePolygonShape3D = body.get_child(0).shape
			collision_shape.backface_collision = true
			mesh.lod_bias = 0.7
			mesh.visibility_range_end = 380.0
	_build_water()
	_build_grotto()
	var coast_wall:=TERRAIN.shallow_water_wall()
	coast_wall.collision_layer=1|4|8
	add_child(coast_wall)
	var polish := preload("res://scripts/island_rock_water_polish.gd").new()
	polish.name = "RockWaterPolish"
	add_child(polish)
	polish.populate(self)
	ready_for_play = true

func populate_ground_detail() -> void:
	var transforms:Array[Transform3D]=_populate_forest()
	var vegetation:=preload("res://scripts/candidate_vegetation.gd").new()
	vegetation.name="CandidateVegetation"
	add_child(vegetation)
	vegetation.populate(self,transforms)

func _populate_forest() -> Array[Transform3D]:
	# Keep every existing support/collider and deterministic placement unchanged.
	var transforms: Array[Transform3D]=[]
	var rng:=RandomNumberGenerator.new()
	rng.seed=71422
	for index in range(40):
		var angle:=rng.randf()*TAU
		var radius:=sqrt(rng.randf())
		var point:=Vector3(-64+cos(angle)*24*radius,0,-8+sin(angle)*30*radius)
		# Leave an east/west route through the woodland.
		if absf(point.z-10)<3.0:continue
		point.y=height_at(Vector2(point.x,point.z))
		var size:=rng.randf_range(.85,1.25)
		var basis:=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(size,size*2.2,size))
		transforms.append(Transform3D(basis,point))
		var body:=StaticBody3D.new()
		body.collision_layer=1|4|8
		body.collision_mask=0
		var collision:=CollisionShape3D.new()
		var shape:=CylinderShape3D.new()
		shape.radius=.35*size
		shape.height=6.6*size
		collision.shape=shape
		collision.position=point+Vector3.UP*shape.height*.5
		body.add_child(collision)
		add_child(body)
	return transforms

func _build_grotto() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A 15 m grotto: 5 m wide, 3.8 m clear height, closed at the far end.
	for section in range(8):
		for side in range(12):
			var vertices: Array[Vector3] = []
			for pair in [Vector2i(section,side),Vector2i(section+1,side),Vector2i(section,side+1),Vector2i(section+1,side),Vector2i(section+1,side+1),Vector2i(section,side+1)]:
				var angle: float = pair.y*PI/12.0
				var rough: float = sin(pair.x*2.3+pair.y*3.1)*0.10
				vertices.append(Vector3(76+cos(angle)*(2.6+rough),1.5+sin(angle)*(3.8+rough),-6+pair.x*2.0))
			for vertex in vertices:
				surface.set_uv(Vector2(vertex.x*0.4,vertex.z*0.4+vertex.y*0.3))
				surface.add_vertex(vertex)
	for vertex in [Vector3(73.4,1.5,-6),Vector3(78.6,1.5,-6),Vector3(73.4,1.5,10),Vector3(78.6,1.5,-6),Vector3(78.6,1.5,10),Vector3(73.4,1.5,10)]:
		surface.set_uv(Vector2(vertex.x,vertex.z)*0.3)
		surface.add_vertex(vertex)
	for side in range(12):
		for vertex in [Vector3(76,1.5,10),Vector3(76+cos(side*PI/12)*2.6,1.5+sin(side*PI/12)*3.8,10),Vector3(76+cos((side+1)*PI/12)*2.6,1.5+sin((side+1)*PI/12)*3.8,10)]:
			surface.set_uv(Vector2(vertex.x,vertex.y)*0.3)
			surface.add_vertex(vertex)
	surface.generate_normals()
	var grotto := MeshInstance3D.new()
	grotto.name = "PlayableGrotto"
	grotto.mesh = surface.commit()
	var material: StandardMaterial3D = preload("res://scripts/environment_materials.gd").surface("rocky_terrain_02",0.6)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(0.62,0.66,0.62)
	grotto.material_override = material
	add_child(grotto)
	grotto.create_trimesh_collision()
	var body: StaticBody3D = grotto.get_child(0)
	body.collision_layer = 1 | 4 | 8 | 16
	body.collision_mask = 0
	var shape: ConcavePolygonShape3D = body.get_child(0).shape
	shape.backface_collision = true
	var fill := OmniLight3D.new()
	fill.position = Vector3(76,3.1,2)
	fill.omni_range = 9
	fill.light_energy = 0.45
	fill.light_color = Color(0.64,0.75,0.79)
	fill.shadow_enabled = false
	add_child(fill)

func supported_saved_point(point: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.8,point-Vector3.UP*2.0,16)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.normal.y>0.82:
		var shape := PhysicsShapeQueryParameters3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius=0.42
		capsule.height=1.8
		shape.shape=capsule
		shape.transform.origin=hit.position+Vector3.UP*.97
		shape.collision_mask=4|8
		if get_world_3d().direct_space_state.intersect_shape(shape).is_empty():return hit.position+Vector3.UP*.08
	return safe_point(point)

func _build_ground() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(SURFACE.columns-1):
		for x in range(SURFACE.columns-1):
			# One owner per cell: regional patches share these exact edge vertices.
			if SURFACE.cells[z*(SURFACE.columns-1)+x]!=0:continue
			var px:float=SURFACE.origin.x+x*SURFACE.spacing
			var pz:float=SURFACE.origin.y+z*SURFACE.spacing
			var step:float=SURFACE.spacing
			var cuts:int=SURFACE.cuts(px+step*.5,pz+step*.5)
			var spacing:float=step/cuts
			for dz in range(cuts):
				for dx in range(cuts):
					var a:Vector3=SURFACE.vertex_at(px+dx*spacing,pz+dz*spacing)
					var b:Vector3=SURFACE.vertex_at(a.x+spacing,a.z)
					var c:Vector3=SURFACE.vertex_at(a.x,a.z+spacing)
					var d:Vector3=SURFACE.vertex_at(b.x,c.z)
					for vertex in [a,b,c,b,d,c]:surface.add_vertex(vertex)
					ground_triangles+=2

	surface.generate_normals()
	surface.index()
	var mesh := surface.commit()
	var ground := MeshInstance3D.new()
	ground.name = "ConnectedTerrain"
	ground.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/environment/new_island/land.gdshader")
	material.set_shader_parameter("grass",preload("res://assets/environment/polyhaven/leafy_grass_Diffuse.jpg"))
	material.set_shader_parameter("sand",preload("res://assets/environment/polyhaven/coast_sand_01_Diffuse.jpg"))
	material.set_shader_parameter("soil",preload("res://assets/environment/polyhaven/forest_ground_04_Diffuse.jpg"))
	material.set_shader_parameter("trail_mask",TERRAIN.trail_mask())
	ground.material_override = material
	add_child(ground)
	ground.create_trimesh_collision()
	var body: StaticBody3D = ground.get_child(0)
	body.collision_layer = 1 | 4 | 8 | 16
	body.collision_mask = 0

func _build_water() -> void:
	var sea := MeshInstance3D.new()
	sea.name = "Sea"
	var plane := PlaneMesh.new()
	plane.size = Vector2(2000,2000)
	sea.mesh = plane
	sea.position.y = -1.45
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/environment/coastal_water.gdshader")
	material.set_shader_parameter("waterline_base",110.0)
	material.set_shader_parameter("coast_amplitudes",Vector3(5,3,1.5))
	sea.material_override = material
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea)
	var water := SurfaceTool.new()
	water.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(SURFACE.columns-1):
		var pz:float=SURFACE.origin.y+z*SURFACE.spacing
		if pz < -68 or pz > 118:continue
		for x in range(SURFACE.columns-1):
			var px:float=SURFACE.origin.x+x*SURFACE.spacing
			if absf(px-_river_center(pz))>_river_width(pz)+3:continue
			var step:float=SURFACE.spacing
			# Refine only the channel corridor, keeping the rest of the island cheap.
			var cuts:int=SURFACE.cuts(px+step*.5,pz+step*.5)
			var spacing:float=step/cuts
			for dz in range(cuts):
				for dx in range(cuts):
					var a:Vector3=SURFACE.vertex_at(px+dx*spacing,pz+dz*spacing)
					var b:Vector3=SURFACE.vertex_at(a.x+spacing,a.z)
					var c:Vector3=SURFACE.vertex_at(a.x,a.z+spacing)
					var d:Vector3=SURFACE.vertex_at(b.x,c.z)
					_add_wet_triangle(water,[a,b,c])
					_add_wet_triangle(water,[b,d,c])

	water.generate_normals()
	water.index()
	var river := MeshInstance3D.new()
	river.name = "FlowingRiver"
	river.mesh = water.commit()
	var river_material := ShaderMaterial.new()
	river_material.shader = preload("res://assets/environment/new_island/river.gdshader")
	river.material_override = river_material
	river.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(river)

static func _river_center(z:float) -> float:
	var upper:float=(z+68)*22.0/30.0+3.0*sin(clampf((z+68)/30.0,0,1)*PI)
	var lower:float=23.0+5.0*sin((z+35)*0.065)
	return lerpf(upper,lower,smoothstep(-40,-36,z)) if z < -36 else lower

static func _river_width(z:float) -> float:
	return 2.1+0.6*smoothstep(-45,-30,z)+0.22*sin(z*0.17)+4.5*smoothstep(88,114,z)

static func _river_surface_height(z:float) -> float:
	return 1.6-1.7*smoothstep(-68,-38,z) if z < -38 else -0.1-1.39*smoothstep(75,112,z)

func _add_wet_triangle(surface:SurfaceTool,triangle:Array[Vector3]) -> void:
	var polygon:Array[Vector3]=[]
	var shore:Array[bool]=[]
	for index in range(3):
		var a:=triangle[index]
		var b:=triangle[(index+1)%3]
		var da:=_river_surface_height(a.z)-a.y
		var db:=_river_surface_height(b.z)-b.y
		if da>=0:
			polygon.append(a)
			shore.append(absf(da)<0.0001)
		if (da>=0)!=(db>=0):
			polygon.append(a.lerp(b,da/(da-db)))
			shore.append(true)
	for index in range(1,polygon.size()-1):
		for vertex_index in [0,index,index+1]:
			var vertex:=polygon[vertex_index]
			vertex.y=_river_surface_height(vertex.z)
			surface.set_color(Color(1 if shore[vertex_index] else 0,1,1,1))
			surface.set_uv(Vector2((vertex.x-_river_center(vertex.z))/_river_width(vertex.z)*0.5+0.5,vertex.z*0.15))
			surface.add_vertex(vertex)

func ground_hit(point: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(point.x,45,point.z),Vector3(point.x,-5,point.z),16)
	query.hit_from_inside = false
	return get_world_3d().direct_space_state.intersect_ray(query)

func ground_point(point: Vector3) -> Vector3:
	var hit := ground_hit(point)
	return Vector3(point.x,hit.position.y if not hit.is_empty() else height_at(Vector2(point.x,point.z)),point.z)

func safe_point(point: Vector3) -> Vector3:
	var preserved:Vector3=SURFACE.preserved_point(point)
	if preserved.is_finite():return preserved
	# Search a nearby low-slope support with capsule headroom; never reset inventory/quests.
	for radius in [0.0,2.0,4.0,7.0,10.0]:
		for index in range(16 if radius > 0 else 1):
			var sample: Vector3 = point + Vector3(cos(index*TAU/16.0),0,sin(index*TAU/16.0))*radius
			var hit := ground_hit(sample)
			if hit.is_empty() or hit.normal.y < 0.82 or hit.position.y < -0.7 or hit.position.y > 8.0:continue
			var query := PhysicsShapeQueryParameters3D.new()
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.42
			capsule.height = 1.8
			query.shape = capsule
			query.transform.origin = hit.position + Vector3.UP*0.96
			query.collision_mask = 4 | 8
			if get_world_3d().direct_space_state.intersect_shape(query).is_empty():return hit.position + Vector3.UP*0.08
	return Vector3(0,height_at(Vector2(0,27))+0.1,27)
