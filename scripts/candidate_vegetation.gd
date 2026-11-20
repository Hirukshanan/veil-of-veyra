extends Node3D

const ASSETS="res://assets/environment/new_island/vegetation/"
var landscape:Node3D
var patches:Array[Dictionary]=[]
var trees:Array[MultiMeshInstance3D]=[]
var grass_positions:=PackedVector3Array()
var tree_positions:=PackedVector3Array()
var clear_points:Array[Vector3]=[]
var elapsed:=0.0
var overview:=false
const REFINED=ASSETS+"refinement/"
var form_counts:=PackedInt32Array([0,0,0])
var form_by_anchor:Dictionary={}
var tree_materials:Array[ShaderMaterial]=[]
var grass_materials:Array[ShaderMaterial]=[]
var _grass_viewer := Vector2.INF
var _grass_lod_viewer := Vector2.INF
var _tree_lod_viewer := Vector2.INF

func populate(owner_landscape:Node3D,supplementary:Array[Transform3D])->void:
	landscape=owner_landscape
	name="CandidateVegetation"
	for entry in landscape.get_parent().placement_log:clear_points.append(entry.after)
	_build_trees(supplementary)
	_build_groundcover()
	_update_grass_counts()
	_update_density()

func _build_trees(supplementary:Array[Transform3D])->void:
	# Rendering-only replacement: original fused tree mesh/colliders remain intact.
	for mesh in landscape.regions[1].find_children("*","MeshInstance3D",true,false):mesh.hide()
	var roots:Array=JSON.parse_string(FileAccess.get_file_as_string(ASSETS+"forest_roots.json"))
	var rng:=RandomNumberGenerator.new();rng.seed=473295
	var transforms:Array[Transform3D]=[]
	for root_position in roots:
		var point:Vector3=landscape.ground_point(Vector3(root_position[0],0,root_position[1]))
		var width:=rng.randf_range(.9,1.35)
		var height:=rng.randf_range(2.1,3.15)
		transforms.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(width,height,width*rng.randf_range(.85,1.15))),point))
	for original in supplementary:
		# Preserve the exact existing trunk supports and use varied canopy proportions.
		var basis:Basis=original.basis.scaled(Vector3(rng.randf_range(.9,1.12),rng.randf_range(.94,1.12),rng.randf_range(.9,1.15)))
		transforms.append(Transform3D(basis,original.origin))
	# Physics only: supply missing colliders for the original 35 instanced roots.
	preload("res://scripts/island_accessibility.gd").tree_collisions(landscape,transforms.slice(0,roots.size()))
	var cells:Dictionary={}
	for index in range(transforms.size()):
		var transform:Transform3D=transforms[index]
		var form:int=index%3
		form_by_anchor[Vector2i(roundi(transform.origin.x*100),roundi(transform.origin.z*100))]=form
		form_counts[form]+=1
		tree_positions.append(transform.origin)
		var key:=Vector2i(floori(transform.origin.x/32),floori(transform.origin.z/32))
		if not cells.has(key):cells[key]=[]
		cells[key].append(transform)
	for key in cells:
		var center:=Vector3(key.x*32+16,0,key.y*32+16)
		for lod in range(3):
			for part in ["trunk","canopy"]:
				var mesh:Mesh=load(REFINED+part+"_lod%d.res"%lod)
				var values:Array[Transform3D]=[]
				for t in cells[key]:values.append(Transform3D(t.basis,t.origin-center))
				var visual:=_batch(mesh,values,center,rng)
				visual.name="Tree_%s_%s_%d"%[str(key),part,lod]
				visual.visibility_range_begin=0
				visual.visibility_range_end=190
				var material:ShaderMaterial=mesh.surface_get_material(0)
				if material not in tree_materials:tree_materials.append(material)
				visual.set_meta("tree_lod",lod)
				trees.append(visual)

func _clear(point:Vector3,radius:float)->bool:
	for target in clear_points:
		if Vector2(point.x-target.x,point.z-target.z).length()<radius:return false
	return true

func _build_groundcover()->void:
	var rng:=RandomNumberGenerator.new();rng.seed=936217
	var trail:Image=landscape.TERRAIN.trail_mask().get_image()
	var grass_meshes:Array[Mesh]=[]
	for lod in range(3):
		var mesh:Mesh=load(REFINED+"grass_lod%d.res"%lod)
		grass_meshes.append(mesh)
		grass_materials.append(mesh.surface_get_material(0))
	var fern_mesh:Mesh=load(ASSETS+"fern.res")
	for cx in range(-6,7):
		for cz in range(-2,4):
			var center:=Vector3(cx*16,0,cz*16)
			if Vector2(center.x,center.z).length()>92:continue
			var transforms:Array[Transform3D]=[]
			var ferns:Array[Transform3D]=[]
			var shrubs:Array[Transform3D]=[]
			for attempt in range(1000):
				var point:=center+Vector3(rng.randf_range(-8,8),0,rng.randf_range(-8,8))
				if point.z>53 or point.z< -36 or Vector2(point.x,point.z).length()>91:continue
				if point.x>46 and point.z> -40 and point.z<30:continue
				var uv:Vector2=(Vector2(point.x,point.z)/256+Vector2.ONE*.5)*512
				if trail.get_pixel(clampi(int(uv.x),0,511),clampi(int(uv.y),0,511)).r>.14:continue
				if not _clear(point,1.6):continue
				var blocked:=false
				for enemy in get_tree().get_nodes_in_group("combat_enemies"):
					if Vector2(enemy.position.x-point.x,enemy.position.z-point.z).length()<4.2:blocked=true;break
				if blocked:continue
				var d:float=absf(point.x-landscape.SURFACE.river_center(point.z))
				var w:float=landscape.SURFACE.river_width(point.z)
				if d<w+1.6:continue
				var forest:float=1-smoothstep(.65,1.2,Vector2((point.x+64)/27,(point.z+8)/32).length())
				var bank:float=1-smoothstep(w+2,w+10,d)
				var cluster:float=sin(point.x*.41+sin(point.z*.19))*cos(point.z*.31)
				var density:float=lerpf(.55,.42,forest)*(.35+.65*smoothstep(-.5,.65,cluster))
				density=lerpf(density,.8,bank*.65)
				density*=1-smoothstep(39,53,point.z)
				if rng.randf()>density:continue
				var hit:Dictionary=landscape.ground_hit(point)
				if hit.is_empty() or hit.position.y<.1 or hit.normal.y<.86:continue
				point=hit.position
				var scale_value:=rng.randf_range(.7,1.25)*(1+bank*.3)
				var basis:=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_value)
				transforms.append(Transform3D(basis,point-center-Vector3.UP*.015))
				grass_positions.append(point)
				if forest>.25 and rng.randf()<.07:
					ferns.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(.75,1.5)),point-center))
				if forest>.10 and forest<.55 and rng.randf()<.035:
					var size:=rng.randf_range(.24,.34)
					shrubs.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(size,size,size)),point-center-Vector3.UP*size*2.2))
			if transforms.is_empty():continue
			var levels:Array[MultiMeshInstance3D]=[]
			for lod in range(3):
				var visual:=_batch(grass_meshes[lod],transforms,center,rng)
				visual.name="Grass_%d_%d_LOD%d"%[cx,cz,lod]
				# Grass is for nearby ground-level views, not distant/aerial cameras.
				visual.visibility_range_end=65
				levels.append(visual)
			patches.append({"center":center,"levels":levels,"count":transforms.size()})
			if not ferns.is_empty():
				var visual:=_batch(fern_mesh,ferns,center,rng)
				visual.name="ForestUnderstory_%d_%d"%[cx,cz]
				visual.visibility_range_end=42
			if not shrubs.is_empty():
				var visual:=_batch(load(ASSETS+"canopy_lod2.res"),shrubs,center,rng)
				visual.name="ForestEdgeShrubs_%d_%d"%[cx,cz]
				visual.visibility_range_end=55

func _batch(mesh:Mesh,transforms:Array[Transform3D],center:Vector3,rng:RandomNumberGenerator)->MultiMeshInstance3D:
	var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_colors=true
	multi.use_custom_data=true;multi.mesh=mesh;multi.instance_count=transforms.size()
	for index in range(transforms.size()):
		multi.set_instance_transform(index,transforms[index])
		var tint:=rng.randf_range(.86,1.04)
		var unused_blue:float=rng.randf_range(.85,1.0)*tint
		var world:Vector3=transforms[index].origin+center
		var phase:float=fposmod(sin(world.x*12.9898+world.z*78.233)*43758.5453,1.0)
		var stable_tint:float=lerpf(.87,1.03,phase)
		multi.set_instance_color(index,Color(stable_tint,stable_tint,stable_tint*.94))
		var form:int=form_by_anchor.get(Vector2i(roundi(world.x*100),roundi(world.z*100)),0) if mesh.get_meta("refined_tree",false) else 0
		multi.set_instance_custom_data(index,Color(form*.5,center.x/256+.5,float(index)/maxi(1,transforms.size()),center.z/256+.5))
	var visual:=MultiMeshInstance3D.new();visual.position=center;visual.multimesh=multi
	visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Cover all authored vertex-morph forms, including taller/leaning crowns.
	visual.extra_cull_margin=4.0 if mesh.get_meta("refined_tree",false) else .08
	add_child(visual)
	return visual

func _process(delta: float) -> void:
	if landscape == null:
		return
	var hero: Vector3 = landscape.get_parent().player.global_position
	_update_grass_viewer(hero)
	elapsed += delta
	if elapsed < .25:
		return
	elapsed = 0
	_update_density()

func _update_grass_viewer(hero: Vector3) -> void:
	# The grass shader uses only the horizontal position.
	var point := Vector2(hero.x, hero.z)
	if point == _grass_viewer:
		return
	_grass_viewer = point
	for material in grass_materials:
		material.set_shader_parameter("grass_viewer", hero)

func _update_grass_counts() -> void:
	var fractions := [.26, .26, .26] if overview else [1.0, 1.0, .55]
	for patch in patches:
		for index in range(3):
			var visual: MultiMeshInstance3D = patch.levels[index]
			visual.multimesh.visible_instance_count = ceili(patch.count * fractions[index])

func _update_density() -> void:
	if landscape == null:
		return
	var hero: Vector3 = landscape.get_parent().player.global_position
	_update_grass_viewer(hero)
	var hero_xz := Vector2(hero.x, hero.z)
	if hero_xz != _grass_lod_viewer:
		_grass_lod_viewer = hero_xz
		for patch in patches:
			var distance: float = hero_xz.distance_to(Vector2(patch.center.x, patch.center.z))
			# Keep the gates around the shader crossfades.
			patch.levels[0].visible = not overview and distance < 23.5
			patch.levels[1].visible = not overview and distance > 8.5 and distance < 41.5
			patch.levels[2].visible = overview or (distance > 26.5 and distance < 56.0)
	var camera := get_viewport().get_camera_3d()
	var viewer := camera.global_position if camera != null else hero
	var viewer_xz := Vector2(viewer.x, viewer.z)
	if viewer_xz != _tree_lod_viewer:
		_tree_lod_viewer = viewer_xz
		for tree in trees:
			var level: int = tree.get_meta("tree_lod")
			var distance := viewer_xz.distance_to(Vector2(tree.global_position.x, tree.global_position.z))
			match level:
				0: tree.visible = not overview and distance < 46.0
				1: tree.visible = not overview and distance > 30.0 and distance < 86.0
				2: tree.visible = overview or (distance > 70.0 and distance < 165.0)

func density_at(distance:float)->float:
	return lerpf(lerpf(1.0,.5,smoothstep(10,22,distance)),.22,smoothstep(28,40,distance))

func set_review_overview(enabled: bool) -> void:
	if overview != enabled:
		overview = enabled
		_grass_lod_viewer = Vector2.INF
		_tree_lod_viewer = Vector2.INF
		_update_grass_counts()
	for material in tree_materials + grass_materials:
		material.set_shader_parameter("overview", enabled)
	_update_density()
