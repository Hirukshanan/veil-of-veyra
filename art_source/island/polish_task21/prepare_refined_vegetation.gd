extends SceneTree
const A="res://assets/environment/new_island/vegetation/refinement/"
func _initialize():call_deferred("run")
func deform(p:Vector3,form:int)->Vector3:
	var t:float=smoothstep(.6,5.1,p.y)
	if form==1:return Vector3(p.x*(1-.08*t)+.12*sin(p.y*.9)*t,p.y*(1+.16*t),p.z*(1-.04*t))
	if form==2:return Vector3(p.x*(1+.36*t)+1.25*t,p.y*(1-.035*t),p.z*(1+.30*t)-.18*sin(p.y*.8)*t)
	return Vector3(p.x*(1+.65*t),p.y,p.z*(1+.65*t))
func morphed_normal(p:Vector3,n:Vector3,form:int)->Vector3:
	var tangent:Vector3=n.cross(Vector3.UP if absf(n.y)<.9 else Vector3.RIGHT).normalized()
	var bitangent:Vector3=n.cross(tangent).normalized()
	return (deform(p+tangent*.01,form)-deform(p,form)).cross(deform(p+bitangent*.01,form)-deform(p,form)).normalized()
func morph_tool()->SurfaceTool:
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(4):tool.set_custom_format(i,SurfaceTool.CUSTOM_RGBA_FLOAT)
	return tool
func vertex(tool:SurfaceTool,p:Vector3,n:Vector3,uv:Vector2,color:Color,center_y:float=0):
	var base:Vector3=deform(p,0)
	for form in [1,2]:
		var delta:Vector3=deform(p,form)-base
		var normal:Vector3=morphed_normal(p,n,form)
		tool.set_custom(form-1,Color(delta.x,delta.y,delta.z,0))
		tool.set_custom(form+1,Color(normal.x,normal.y,normal.z,0))
	tool.set_normal(morphed_normal(p,n,0));tool.set_uv(uv);tool.set_uv2(Vector2(center_y,1 if center_y>0 else 0));tool.set_color(color);tool.add_vertex(base)
func run():
	var budgets:Dictionary={}
	for level in range(3):
		var model:Node3D=load(A+"organic_trunk_lod%d.glb"%level).instantiate()
		var source:Mesh=model.find_children("*","MeshInstance3D",true,false)[0].mesh
		var tool:=morph_tool()
		for surface in range(source.get_surface_count()):
			var arrays:Array=source.surface_get_arrays(surface)
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			for i in indices:vertex(tool,arrays[Mesh.ARRAY_VERTEX][i],arrays[Mesh.ARRAY_NORMAL][i],arrays[Mesh.ARRAY_TEX_UV][i],Color.WHITE)
		tool.index();tool.generate_tangents()
		var material:=ShaderMaterial.new();material.shader=load(A+"bark.gdshader");material.set_shader_parameter("lod_level",level)
		material.set_shader_parameter("bark",load("res://assets/environment/polyhaven/island_tree_01/textures/island_tree_01_branches_diff_1k.jpg"))
		material.set_shader_parameter("bark_normal",load("res://assets/environment/polyhaven/island_tree_01/textures/island_tree_01_branches_nor_gl_1k.jpg"))
		tool.set_material(material);var trunk:=tool.commit();trunk.set_meta("refined_tree",true)
		assert(ResourceSaver.save(trunk,A+"trunk_lod%d.res"%level,ResourceSaver.FLAG_COMPRESS)==OK)
		var crown:=canopy(level);assert(ResourceSaver.save(crown,A+"canopy_lod%d.res"%level,ResourceSaver.FLAG_COMPRESS)==OK)
		var blades:=grass(level);assert(ResourceSaver.save(blades,A+"grass_lod%d.res"%level,ResourceSaver.FLAG_COMPRESS)==OK)
		budgets[str(level)]={"trunk_triangles":trunk.get_faces().size()/3,"canopy_triangles":crown.get_faces().size()/3,"grass_triangles":blades.get_faces().size()/3}
		model.free()
	var file:=FileAccess.open(A+"mesh_budgets.json",FileAccess.WRITE);file.store_string(JSON.stringify(budgets,"  "))
	print("PASS: three tree forms share morph-enabled instanced meshes; denser twig crowns and smooth grass LODs built ",budgets)
	quit()
func canopy(level:int)->ArrayMesh:
	var tips:Array=JSON.parse_string(FileAccess.get_file_as_string(A+"branch_tips.json"))
	var tool:=morph_tool();var rng:=RandomNumberGenerator.new();rng.seed=311749
	for entry in tips:
		var tip:=Vector3(entry.point[0],entry.point[1],entry.point[2]);var parent:=Vector3(entry.parent[0],entry.parent[1],entry.parent[2])
		var y:Vector3=(tip-parent).normalized();var x:Vector3=y.cross(Vector3.UP).normalized()
		if x.length()<.1:x=Vector3.RIGHT
		for card in range(7):
			var theta:=rng.randf_range(-.65,.65)
			var side:Vector3=x.rotated(y,theta);var normal:Vector3=side.cross(y).normalized()
			var center:Vector3=tip+side*rng.randf_range(-.55,.55)+normal*rng.randf_range(-.45,.45)+y*rng.randf_range(-.18,.4)
			var w:float=rng.randf_range(1.05,1.35);var h:float=w*rng.randf_range(.95,1.1)
			var tile:=rng.randi_range(0,3);var uv:=Vector2(tile%2,tile/2)*.5
			var shade:float=lerpf(.76,1.0,smoothstep(2.6,5.5,center.y))*rng.randf_range(.94,1.03)
			if level==1 and card%2!=0:continue
			if level==2 and card not in [1,5]:continue
			w*=[1.0,1.3,1.85][level];h*=[1.0,1.3,1.85][level]
			var points:Array[Vector3]=[center-side*w*.5-y*h*.5,center+side*w*.5-y*h*.5,center-side*w*.5+y*h*.5,center+side*w*.5+y*h*.5]
			var coords:Array[Vector2]=[Vector2(0,1),Vector2(1,1),Vector2(0,0),Vector2(1,0)]
			for i in [0,2,1,1,2,3]:vertex(tool,points[i],normal,uv+coords[i]*.5,Color(shade,shade,shade),center.y)
	tool.index();var material:=ShaderMaterial.new();material.shader=load(A+"foliage.gdshader");material.set_shader_parameter("lod_level",level);material.set_shader_parameter("twig_atlas",load(A+"twig_clusters.png"));tool.set_material(material)
	var result:=tool.commit();result.set_meta("refined_tree",true);return result
func grass(level:int)->ArrayMesh:
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng:=RandomNumberGenerator.new();rng.seed=17321
	var blades:int=[4,3,3][level];var segments:int=[5,2,1][level]
	for blade in range(blades):
		var theta:=rng.randf()*TAU;var origin:=Vector3(rng.randf_range(-.2,.2),0,rng.randf_range(-.2,.2))
		var height:=rng.randf_range(.22,.46);var width:=rng.randf_range(.009,.018)
		var bend:=Vector3(cos(theta)*height*.53,0,sin(theta)*height*.53);var side:=Vector3(-sin(theta),0,cos(theta))*width
		for section in range(segments):
			var a:float=float(section)/segments;var b:float=float(section+1)/segments
			var lo:=origin+Vector3.UP*height*a+bend*a*a;var hi:=origin+Vector3.UP*height*b+bend*b*b
			var wa:float=pow(1-a*a,.7);var wb:float=pow(maxf(0,1-b*b),.7)
			var points:Array[Vector3]=[lo-side*wa,lo+side*wa,hi-side*wb,hi+side*wb]
			var indices:Array=[0,1,2] if section==segments-1 else [0,1,2,1,3,2]
			for i in indices:
				var t:float=a if i<2 else b;tool.set_normal(Vector3.UP)
				tool.set_uv(Vector2(i%2,t));tool.set_color(Color(.24+.1*t,.35+.13*t,.10+.07*t));tool.add_vertex(points[i])
	tool.generate_normals();tool.index();var material:=ShaderMaterial.new();material.shader=load(A+"grass.gdshader");material.set_shader_parameter("lod_level",level);tool.set_material(material);return tool.commit()
