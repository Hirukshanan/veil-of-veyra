extends "res://tests/island_review.gd"

# Review cameras only. No gameplay source, placement, input or progression is edited.
var extra_camera: Camera3D
var captured_views: Array[Dictionary] = []

func _initialize() -> void:
	output="res://.validation/island_polish_task1"
	call_deferred("run")

func save_view(label: String, kind: String, camera: Camera3D) -> void:
	for frame in range(12):await process_frame
	await RenderingServer.frame_post_draw
	var error:=root.get_texture().get_image().save_png(output+"/"+label+".png")
	assert(error==OK)
	captured_views.append({"name":label,"kind":kind,"camera_position":camera.global_position,"camera_rotation":camera.global_rotation,"hero_position":scene.player.global_position,"native_resolution":[root.size.x,root.size.y]})
	print("CAPTURED_NATIVE_VIEW ",label)

func gameplay_view(label: String, point: Vector3, yaw: float) -> void:
	scene._resume()
	var hero=scene.player
	hero.global_position=scene.landscape.safe_point(point)
	hero.velocity=Vector3.ZERO
	hero.rotation.y=yaw
	hero._camera_pivot.rotation=Vector3(-.12,yaw,0)
	hero._camera_pivot.global_position=hero.position+Vector3.UP*1.2
	var camera:Camera3D=hero._camera_arm.get_child(0)
	camera.make_current()
	await save_view(label,"actual third-person campaign; controlled review placement",camera)

func close_view(label: String, point: Vector3, offset: Vector3) -> void:
	var target:Vector3=scene.landscape.ground_point(point)+Vector3.UP*.15
	extra_camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	extra_camera.fov=56
	extra_camera.global_position=target+offset
	extra_camera.look_at(target)
	extra_camera.make_current()
	# UI is hidden only for inspection-camera images, never gameplay views.
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	await save_view(label,"native inspection-camera close-up; no post-edit",extra_camera)
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.show()
	# Resume hides the menu canvas while retaining gameplay HUD.
	scene._resume()

func metrics() -> Dictionary:
	var region_rows:=[]
	for region in scene.landscape.regions:
		var bounds:=AABB()
		var first:=true
		var triangles:=0
		var vertices:=0
		var texture_rows:=[]
		for mesh in region.find_children("*","MeshInstance3D",true,false):
			var box:AABB=mesh.global_transform*mesh.mesh.get_aabb()
			bounds=box if first else bounds.merge(box)
			first=false
			for surface in range(mesh.mesh.get_surface_count()):
				var arrays:Array=mesh.mesh.surface_get_arrays(surface)
				vertices+=arrays[Mesh.ARRAY_VERTEX].size()
				triangles+=arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX]!=null and not arrays[Mesh.ARRAY_INDEX].is_empty() else arrays[Mesh.ARRAY_VERTEX].size()/3
			var texture:Texture2D=mesh.material_override.get_shader_parameter("source_map")
			var image:Image=texture.get_image()
			texture_rows.append({"resource":texture.resource_path,"width":texture.get_width(),"height":texture.get_height(),"image_format_enum":image.get_format(),"is_compressed":image.is_compressed(),"mipmaps":image.get_mipmap_count(),"image_payload_bytes":image.get_data().size()})
		region_rows.append({"region":str(region.name),"aabb_min":[bounds.position.x,bounds.position.y,bounds.position.z],"aabb_max":[bounds.end.x,bounds.end.y,bounds.end.z],"size_xyz_m":[bounds.size.x,bounds.size.y,bounds.size.z],"base_triangles":triangles,"render_vertices":vertices,"textures":texture_rows})
	var terrain:MeshInstance3D=scene.landscape.get_node("ConnectedTerrain")
	var terrain_bounds:AABB=terrain.global_transform*terrain.mesh.get_aabb()
	var land_min:=Vector2(INF,INF)
	var land_max:=Vector2(-INF,-INF)
	var emerged_samples:=0
	for z in range(-120,121,2):
		for x in range(-120,121,2):
			var hit:Dictionary=scene.landscape.ground_hit(Vector3(x,0,z))
			if hit.is_empty() or hit.position.y< -1.40:continue
			land_min=land_min.min(Vector2(x,z))
			land_max=land_max.max(Vector2(x,z))
			emerged_samples+=1
	var wall:StaticBody3D=scene.landscape.get_node("ShallowWaterWall")
	var wall_shape:CollisionShape3D=wall.get_child(0)
	var wall_faces:PackedVector3Array=wall_shape.shape.get_faces()
	var wall_min:=Vector3(INF,INF,INF)
	var wall_max:=Vector3(-INF,-INF,-INF)
	for vertex in wall_faces:
		var point:Vector3=wall_shape.global_transform*vertex
		wall_min=wall_min.min(point)
		wall_max=wall_max.max(point)
	return {"regions":region_rows,"connecting_ground_aabb_xyz_m":[terrain_bounds.size.x,terrain_bounds.size.y,terrain_bounds.size.z],"connecting_ground_triangles":scene.landscape.ground_triangles,"emerged_land_sampling":{"spacing_m":2,"min_xz":[land_min.x,land_min.y],"max_xz":[land_max.x,land_max.y],"approx_size_xz_m":[land_max.x-land_min.x+2,land_max.y-land_min.y+2],"approx_projected_area_m2":emerged_samples*4,"definition":"Top static support at least 5 cm above sea; includes steep scenery, not a claim all cells are walkable"},"wading_boundary_aabb_xyz_m":[wall_max.x-wall_min.x,wall_max.y-wall_min.y,wall_max.z-wall_min.z],"sea":{"size_xz_m":[2000,2000],"height_y_m":-1.45},"memory":{"engine_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"scope":"Godot scene-wide monitors including hero, enemies, HUD/minimap and reused assets; not OS working set or phone memory"}}

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST")=="1")
	assert(OS.get_environment("APPDATA").replace("\\","/").contains("/.validation/island_polish_"))
	scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	extra_camera=Camera3D.new()
	extra_camera.near=.05
	scene.add_child(extra_camera)
	extra_camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	extra_camera.fov=56
	extra_camera.global_position=Vector3(-32.0,3.17935,13.0)
	extra_camera.global_rotation=Vector3(-0.475177,-1.030377,0.0)
	extra_camera.make_current()
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	await save_view("14_seam_west","exact pre-polish camera pose; native render",extra_camera)
	extra_camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	extra_camera.fov=56
	extra_camera.global_position=Vector3(3.0,3.159205,-31.0)
	extra_camera.global_rotation=Vector3(-0.380506,0.643501,0.0)
	extra_camera.make_current()
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	await save_view("15_seam_north","exact pre-polish camera pose; native render",extra_camera)
	extra_camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	extra_camera.fov=56
	extra_camera.global_position=Vector3(41.0,4.926602,-14.0)
	extra_camera.global_rotation=Vector3(-0.587292,-0.982794,0.0)
	extra_camera.make_current()
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	await save_view("16_seam_east","exact pre-polish camera pose; native render",extra_camera)
	extra_camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	extra_camera.fov=56
	extra_camera.global_position=Vector3(-2.0,4.125586,31.0)
	extra_camera.global_rotation=Vector3(-0.339837,2.356194,0.0)
	extra_camera.make_current()
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	await save_view("17_seam_south","exact pre-polish camera pose; native render",extra_camera)
	extra_camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	extra_camera.fov=56
	extra_camera.global_position=Vector3(9.0,1.442702,-49.0)
	extra_camera.global_rotation=Vector3(-0.440511,-0.785398,0.0)
	extra_camera.make_current()
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	await save_view("18_riverbank_upper","exact pre-polish camera pose; native render",extra_camera)
	extra_camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	extra_camera.fov=56
	extra_camera.global_position=Vector3(32.8,3.716861,9.0)
	extra_camera.global_rotation=Vector3(-0.401247,0.785398,0.0)
	extra_camera.make_current()
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	await save_view("19_riverbank_middle","exact pre-polish camera pose; native render",extra_camera)
	extra_camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	extra_camera.fov=56
	extra_camera.global_position=Vector3(19.0,0.763853,101.0)
	extra_camera.global_rotation=Vector3(-0.380506,-0.927295,0.0)
	extra_camera.make_current()
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	await save_view("20_riverbank_outlet","exact pre-polish camera pose; native render",extra_camera)
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.show()
	await gameplay_view("10_connection_west",Vector3(-33,0,12),PI*.5)
	await gameplay_view("12_connection_east",Vector3(41,0,-13),-PI*.5)
	await gameplay_view("13_connection_south",Vector3(-10,0,34),PI)
	# Exact overhead camera. Disable only review-camera distance culling so all
	# regional trees are represented in the overview, rather than hiding at altitude.
	for visual in scene.landscape.find_children("*","GeometryInstance3D",true,false):visual.visibility_range_end=0
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	extra_camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	extra_camera.size=270
	extra_camera.position=Vector3(0,240,0)
	extra_camera.rotation_degrees=Vector3(-90,0,0)
	extra_camera.make_current()
	await save_view("00_top_down","native exact overhead; review-only culling disabled",extra_camera)
	var result:=metrics()
	result["views"]=captured_views
	result["gameplay_source_unchanged"]=true
	var file:=FileAccess.open(output+"/visual_metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "))
	print("PASS: 11 native screenshots, seam/riverbank close-ups, runtime dimensions and memory metrics captured")
	scene.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	await create_timer(.3).timeout
	quit()
