extends SceneTree
const DIR="res://assets/environment/new_island/vegetation/"
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(DIR)
	var source:Mesh=load("res://assets/environment/forest_tree_mobile.res")
	var importer:=ImporterMesh.new()
	for s in range(source.get_surface_count()):importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,source.surface_get_arrays(s),[],{},source.surface_get_material(s))
	importer.generate_lods(60,60,[])
	for level in range(3):
		var trunk_builder:=SurfaceTool.new();trunk_builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for s in range(source.get_surface_count()):
			var arrays:Array=source.surface_get_arrays(s)
			var best:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var target:int=[500,210,90][level]
			for lod in range(importer.get_surface_lod_count(s)):
				var indices:PackedInt32Array=importer.get_surface_lod_indices(s,lod)
				if abs(indices.size()/3-target)<abs(best.size()/3-target):best=indices
			for index in best:
				trunk_builder.set_normal(arrays[Mesh.ARRAY_NORMAL][index])
				trunk_builder.set_uv(arrays[Mesh.ARRAY_TEX_UV][index]*2)
				trunk_builder.add_vertex(arrays[Mesh.ARRAY_VERTEX][index])
		var material:=StandardMaterial3D.new()
		material.albedo_texture=load("res://assets/environment/polyhaven/island_tree_01/textures/island_tree_01_branches_diff_1k.jpg")
		material.roughness=.95;material.vertex_color_use_as_albedo=true
		material.albedo_color=Color(.86,.89,.80)
		trunk_builder.index();trunk_builder.set_material(material)
		var mesh:=trunk_builder.commit()
		ResourceSaver.save(mesh,DIR+"trunk_lod%d.res"%level,ResourceSaver.FLAG_COMPRESS)
		print("TRUNK_LOD ",level," triangles ",mesh.get_faces().size()/3)
		ResourceSaver.save(canopy(level),DIR+"canopy_lod%d.res"%level,ResourceSaver.FLAG_COMPRESS)
		ResourceSaver.save(grass(level),DIR+"grass_lod%d.res"%level,ResourceSaver.FLAG_COMPRESS)
	ResourceSaver.save(fern(),DIR+"fern.res",ResourceSaver.FLAG_COMPRESS)
	print("PASS: original curved grass/fern meshes and three LODs of existing CC0 tree art prepared")
	quit()
func canopy(level:int)->ArrayMesh:
	var rng:=RandomNumberGenerator.new();rng.seed=65931
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Asymmetric branching lobes instead of a single ball or flat reconstruction cap.
	var lobes:Array[Vector4]=[Vector4(.1,4.55,.1,1),Vector4(-1.05,4.0,.2,1.1),Vector4(.9,3.9,-.4,1.05),Vector4(.1,3.7,1.2,.95),Vector4(-.3,3.7,-1.1,.95),Vector4(-1.3,3.0,.2,.95),Vector4(1.35,3.1,.1,1.0),Vector4(.2,3.0,-1.3,.95),Vector4(.15,2.9,1.3,.9)]
	var count:int=[40,18,12][level]
	for lobe in lobes:
		for leaf in range(count):
			var direction:=Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1)).normalized()
			var center:=Vector3(lobe.x,lobe.y,lobe.z)+direction*rng.randf_range(.1,1.0)*Vector3(lobe.w,.7,lobe.w)
			var basis:=Basis.from_euler(Vector3(rng.randf_range(-1.2,1.2),rng.randf()*TAU,rng.randf_range(-1,1)))
			var w:float=rng.randf_range(.35,.52)*[1.0,1.35,2.8][level]
			var h:float=w*rng.randf_range(.9,1.3)
			var tile:=rng.randi_range(0,7)
			var start:=Vector2((tile if tile<5 else tile-5)*.2,0 if tile<5 else .55)
			var size:=Vector2(.2,.55 if tile<5 else .45)
			var corners:Array[Vector2]=[Vector2(-.5,-.5),Vector2(.5,-.5),Vector2(.5,.5),Vector2(-.5,.5)]
			for index in [0,2,1,0,3,2]:
				tool.set_normal(basis*Vector3.BACK)
				tool.set_uv(start+(corners[index]+Vector2.ONE*.5)*size)
				var shade:float=.66+.34*smoothstep(2.3,5.0,center.y)
				tool.set_color(Color(rng.randf_range(.86,1.0),1,rng.randf_range(.85,1.0))*shade)
				tool.add_vertex(center+basis*Vector3(corners[index].x*w,corners[index].y*h,0))
	tool.index()
	var mat:=ShaderMaterial.new();mat.shader=load(DIR+"leaves.gdshader")
	mat.set_shader_parameter("leaf_atlas",load("res://assets/environment/polyhaven/island_tree_01/textures/island_tree_01_leaves_diff_1k.jpg"))
	tool.set_material(mat)
	return tool.commit()
func grass(level:int)->ArrayMesh:
	var rng:=RandomNumberGenerator.new();rng.seed=17321
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var blades:int=[5,3,3][level]
	var segments:int=[3,2,1][level]
	for blade in range(blades):
		var theta:=rng.randf()*TAU
		var origin:=Vector3(rng.randf_range(-.2,.2),0,rng.randf_range(-.2,.2))
		var height:=rng.randf_range(.24,.51)
		var width:=rng.randf_range(.012,.024)
		var bend:=Vector3(cos(theta)*height*.55,0,sin(theta)*height*.55)
		var side:=Vector3(-sin(theta),0,cos(theta))*width
		for section in range(segments):
			var a:float=float(section)/segments;var b:float=float(section+1)/segments
			var lo:=origin+Vector3.UP*height*a+bend*a*a
			var hi:=origin+Vector3.UP*height*b+bend*b*b
			var verts:Array[Vector3]=[lo-side*(1-a),lo+side*(1-a),hi-side*(1-b),hi+side*(1-b)]
			var ids:Array=[0,1,2] if section==segments-1 else [0,1,2,1,3,2]
			for index in ids:
				var t:float=a if index<2 else b
				tool.set_color(Color(.23+.18*t,.34+.20*t,.09+.11*t))
				tool.set_uv(Vector2(index%2,t))
				tool.add_vertex(verts[index])
	tool.generate_normals();tool.index()
	var mat:=ShaderMaterial.new();mat.shader=load(DIR+"grass.gdshader");tool.set_material(mat)
	return tool.commit()
func fern()->ArrayMesh:
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for frond in range(7):
		var angle:float=frond*TAU/7
		var out:=Vector3(cos(angle),0,sin(angle))
		var side:=Vector3(-sin(angle),0,cos(angle))
		for segment in range(1,5):
			var t:float=segment/5.0
			var center:=out*t*.65+Vector3.UP*sin(t*PI*.8)*.36
			for sign_value in [-1,1]:
				var tip:Vector3=center+side*sign_value*(1-t)*.22+out*.15
				for v in [center-out*.06,tip,center+out*.05]:
					tool.set_uv(Vector2(0,t));tool.set_color(Color(.18,.34,.12));tool.add_vertex(v)
	tool.generate_normals();tool.index()
	var mat:=ShaderMaterial.new();mat.shader=load(DIR+"grass.gdshader");tool.set_material(mat)
	return tool.commit()
