extends "res://scripts/grove_investigation.gd"

const INLAY := Vector3(8.8,0,-43.15)

func _make_seal_clue() -> Node3D:
	# A low, split bedrock shelf at the original Grove instead of a detached upright.
	var slab := _site("BuriedWardCarving",INLAY)
	var stone := SurfaceTool.new()
	stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := preload("res://scripts/environment_materials.gd").surface("rocky_terrain_02",.81,Color("aaa18d"))
	for half in [-1,1]:
		var edge := [Vector2(.06,-.79),Vector2(.88,-.71),Vector2(1.23,-.18),Vector2(.94,.63),Vector2(.15,.86),Vector2(.09,.24)]
		for k in edge.size():
			var a: Vector2 = edge[k]
			var b: Vector2 = edge[(k+1)%edge.size()]
			var va := Vector3(a.x*half,.18-a.y*.12,a.y)
			var vb := Vector3(b.x*half,.18-b.y*.12,b.y)
			for v in [Vector3(.40*half,.18,0),va,vb,va,vb,vb-Vector3.UP*.58,va,vb-Vector3.UP*.58,va-Vector3.UP*.58]:
				stone.add_vertex(v)
	stone.generate_normals()
	var mat := material.duplicate() as StandardMaterial3D
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_piece(slab,stone.commit(),Vector3.ZERO,mat)
	_sigil(slab,Vector3(0,.206,0),.53,engraving)
	(slab.get_child(-1) as MeshInstance3D).rotation.x = -PI*.5+.12
	return slab

func _build_guidance() -> void:
	# The shrine supplies physical spoor. Grove clue interactions keep their own reactions.
	pass

func lantern_message() -> String:
	return "The seal answers from the forest stones."
