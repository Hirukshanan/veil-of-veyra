extends SceneTree

func _initialize() -> void:
	var terrain = preload("res://scripts/island_terrain.gd")
	var started := Time.get_ticks_msec()
	var mask: ImageTexture = terrain.trail_mask()
	assert(mask == terrain.trail_mask(), "Chapter reloads must reuse the mask")
	var image := mask.get_image()
	for route in terrain.trails():
		for point in route:
			var pixel := Vector2i((Vector2(point.x, point.z) / terrain.TRAIL_SPAN + Vector2.ONE * 0.5) * 512.0)
			assert(image.get_pixelv(pixel).r > 0.85, "Trail center must remain continuous")
	for point in [Vector2(28, 0), Vector2(-28, 0), Vector2(0, 40), Vector2(40, 0)]:
		var pixel := Vector2i((point / terrain.TRAIL_SPAN + Vector2.ONE * 0.5) * 512.0)
		assert(image.get_pixelv(pixel).r == 0.0, "Trail texture must not spill over the beach")
	var soft_pixels := 0
	for x in range(512):
		for y in range(512):
			var weight := image.get_pixel(x, y).r
			if weight > 0.05 and weight < 0.95:
				soft_pixels += 1
	assert(soft_pixels > 500, "Path borders need a soft transition")
	for chapter in range(3):
		var material: ShaderMaterial = terrain.material(chapter)
		for layer in ["sand", "grass", "soil"]:
			assert(material.get_shader_parameter(layer + "_color") is Texture2D)
			assert(material.get_shader_parameter(layer + "_normal") is Texture2D)
	print("PASS: continuous trail coverage, soft edges, clear beaches, cached mask and all chapter textures (%d ms)" % (Time.get_ticks_msec() - started))
	quit()