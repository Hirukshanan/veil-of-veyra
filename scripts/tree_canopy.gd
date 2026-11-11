extends RefCounted

static var _mesh: ArrayMesh

# Textured leaf cards reuse the existing CC0 atlas; no extra image download is needed.
static func mesh() -> ArrayMesh:
	if _mesh != null: return _mesh
	var rng:=RandomNumberGenerator.new()
	rng.seed=45281
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lobes: Array[Vector4]=[Vector4(0,4.2,0,1.15),Vector4(-1.0,3.55,0.15,1.2),Vector4(0.95,3.6,-0.15,1.15),Vector4(0.1,3.65,1.05,1.1),Vector4(-0.2,3.5,-1.0,1.15)]
	for lobe in lobes:
		for leaf in range(100):
			var direction:=Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1)).normalized()
			var offset:=direction*rng.randf_range(0.25,1.0)*Vector3(lobe.w,0.65,lobe.w)
			var center:=Vector3(lobe.x,lobe.y,lobe.z)+offset
			var basis:=Basis.from_euler(Vector3(rng.randf_range(-1.3,1.3),rng.randf()*TAU,rng.randf_range(-1.0,1.0)))
			var width:=rng.randf_range(0.16,0.24)
			var height:=rng.randf_range(0.22,0.34)
			var tile:=rng.randi_range(0,7)
			var uv_start:=Vector2((tile if tile<5 else tile-5)*0.2,0.0 if tile<5 else 0.55)
			var uv_size:=Vector2(0.2,0.55 if tile<5 else 0.45)
			var corners: Array[Vector2]=[Vector2(-0.5,-0.5),Vector2(0.5,-0.5),Vector2(0.5,0.5),Vector2(-0.5,0.5)]
			for index in [0,2,1,0,3,2]:
				var corner:=corners[index]
				surface.set_normal(basis*Vector3.BACK)
				surface.set_uv(uv_start+(corner+Vector2.ONE*0.5)*uv_size)
				surface.add_vertex(center+basis*Vector3(corner.x*width,corner.y*height,0))
	surface.index()
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/environment/tree_leaves.gdshader")
	material.set_shader_parameter("leaf_atlas",preload("res://assets/environment/polyhaven/island_tree_01/textures/island_tree_01_leaves_diff_1k.jpg"))
	surface.set_material(material)
	_mesh=surface.commit()
	return _mesh
