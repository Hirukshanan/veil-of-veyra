extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	assert(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/island_candidate.tscn","Only run this fixture against the independent review copy")
	assert(ProjectSettings.get_setting("application/config/use_custom_user_dir"),"Review copy must isolate user saves")
	var scene=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	assert(scene.landscape.regions.size()==5)
	assert(scene.get_node_or_null("Island")==null)
	assert(scene.remaining_enemies==5 and scene.get_node_or_null("DemonBoar")!=null)
	for region in scene.landscape.regions:
		assert(not region.find_children("*","MeshInstance3D",true,false).is_empty())
		for mesh in region.find_children("*","MeshInstance3D",true,false):
			var texture:Texture2D=mesh.material_override.get_shader_parameter("source_map")
			assert(texture.get_width()==2048 and texture.get_height()==2048)
	scene._resume()
	for frame in range(10):await physics_frame
	assert(scene.player.health==100 and scene.player.global_position.y>0)
	scene.queue_free()
	paused=false
	await process_frame
	print("PASS: independently extracted project launches candidate, five meshes/textures load, actual campaign hero/HUD/enemies initialize and review saves are isolated")
	quit()
