extends RefCounted

static func surface(id: String, scale_factor := 0.25, tint := Color.WHITE) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var folder := "res://assets/environment/polyhaven/"
	material.albedo_texture = load(folder + id + "_Diffuse.jpg")
	material.normal_enabled = true
	material.normal_texture = load(folder + id + "_nor_gl.jpg")
	material.normal_scale = 0.6
	material.roughness_texture = load(folder + id + "_Rough.jpg")
	material.albedo_color = tint
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * scale_factor
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material
