extends SceneTree
const A="res://assets/environment/new_island/vegetation/refinement/"
func _initialize():call_deferred("run")
func run():
	var viewport:=SubViewport.new();viewport.size=Vector2i(1024,1024);viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var material:=ShaderMaterial.new();var shader:=Shader.new()
	shader.code="shader_type spatial; render_mode unshaded,cull_disabled; uniform sampler2D atlas:source_color; void fragment(){vec3 c=texture(atlas,UV).rgb; ALBEDO=c*vec3(.76,1.02,.68); ALPHA=max(c.r,max(c.g,c.b)); ALPHA_SCISSOR_THRESHOLD=.07;}"
	material.shader=shader;material.set_shader_parameter("atlas",load("res://assets/environment/polyhaven/island_tree_01/textures/island_tree_01_leaves_diff_1k.jpg"))
	var wood:=StandardMaterial3D.new();wood.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;wood.albedo_color=Color(.19,.12,.06);wood.cull_mode=BaseMaterial3D.CULL_DISABLED
	var leaves:=SurfaceTool.new();leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stems:=SurfaceTool.new();stems.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng:=RandomNumberGenerator.new();rng.seed=771142
	for variant in range(4):
		var center:=Vector3(-1.05 if variant%2==0 else 1.05,1.05 if variant<2 else -1.05,0)
		for segment in range(6):
			var a:float=segment/6.0;var b:float=(segment+1)/6.0
			var lo:=center+Vector3(sin(a*2.1+variant)*.08,-.82+a*1.6,0)
			var hi:=center+Vector3(sin(b*2.1+variant)*.08,-.82+b*1.6,0)
			quad(stems,lo+Vector3(-.016,0,0),lo+Vector3(.016,0,0),hi+Vector3(-.01,0,0),hi+Vector3(.01,0,0),Vector2.ZERO,Vector2.ONE)
			for side in [-1,1]:
				var theta:float=side*(.65+rng.randf_range(-.13,.13))
				var basis:=Basis(Vector3.FORWARD,theta)
				var leaf_center:=lo+basis*Vector3(0,.28,0)+Vector3(side*.16,0,.02)
				var tile:=rng.randi_range(0,7);var start:=Vector2((tile if tile<5 else tile-5)*.2,0 if tile<5 else .55);var size:=Vector2(.2,.55 if tile<5 else .45)
				quad(leaves,leaf_center+basis*Vector3(-.15,-.27,0),leaf_center+basis*Vector3(.15,-.27,0),leaf_center+basis*Vector3(-.15,.27,0),leaf_center+basis*Vector3(.15,.27,0),start,size)
	for entry in [[leaves,material],[stems,wood]]:
		var visual:=MeshInstance3D.new();visual.mesh=entry[0].commit();visual.material_override=entry[1];viewport.add_child(visual)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.2;camera.position=Vector3(0,0,6);viewport.add_child(camera);camera.look_at(Vector3.ZERO);camera.make_current()
	for frame in range(12):await process_frame
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png(A+"twig_clusters.png")==OK)
	print("PASS: four original 3D twig arrangements baked locally from existing CC0 leaf scans to a 1K cutout atlas")
	viewport.queue_free();await process_frame;quit()
func quad(tool:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3,start:Vector2,size:Vector2):
	var points:Array[Vector3]=[a,b,c,d];var uvs:Array[Vector2]=[Vector2(0,1),Vector2(1,1),Vector2(0,0),Vector2(1,0)]
	for i in [0,2,1,1,2,3]:tool.set_normal(Vector3.BACK);tool.set_uv(start+uvs[i]*size);tool.add_vertex(points[i])
