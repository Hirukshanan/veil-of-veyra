extends Node3D

func _ready() -> void:
	var trail := preload("res://scripts/island_terrain.gd").trail_mask().get_image()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7349
	var blade := SurfaceTool.new()
	blade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [0.0, PI / 2.0, PI / 4.0]:
		for point in [Vector3(-0.035,0,0),Vector3(0.05,0.28,0.04),Vector3(0.035,0,0)]:
			blade.add_vertex(point.rotated(Vector3.UP,angle))
	blade.generate_normals()
	var mesh := blade.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.26,0.43,0.085)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0,material)
	# Separate chunks allow distance culling instead of drawing the whole island.
	for x in range(-6,7):
		for z in range(-6,7):
			var center := Vector3(x*10,0,z*10)
			if center.length() > 65: continue
			var patch := MultiMeshInstance3D.new()
			patch.position = center
			patch.visibility_range_end = 30.0
			patch.visibility_range_end_margin = 5.0
			patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var instances := MultiMesh.new()
			instances.transform_format = MultiMesh.TRANSFORM_3D
			instances.use_colors = true
			instances.mesh = mesh
			instances.instance_count = 1400
			for index in range(1400):
				var local := Vector3(rng.randf_range(-5,5),0.02,rng.randf_range(-5,5))
				var world := center + local
				var uv := (Vector2(world.x, world.z) / 208.0 + Vector2.ONE * 0.5) * 512.0
				var on_path := false
				if uv.x >= 0 and uv.y >= 0 and uv.x < 512 and uv.y < 512:
					on_path = trail.get_pixel(int(uv.x), int(uv.y)).r > 0.15
				var scale_value := 0.0 if on_path else rng.randf_range(0.65,1.15) * (1.65 if sin(world.x * 0.3) * cos(world.z * 0.27) > 0.65 else 1.0)
				instances.set_instance_transform(index,Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_value),local))
				instances.set_instance_color(index,Color(0.8+rng.randf()*0.2,0.85+rng.randf()*0.15,0.7,1))
			patch.multimesh = instances
			add_child(patch)
