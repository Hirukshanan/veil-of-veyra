extends SceneTree
func _initialize():call_deferred("run")
func run():
	var rows:=[];var polish=load("res://scripts/island_rock_water_polish.gd").new()
	for region in ["WaterfallMountains","EasternCaves"]:
		var load_start:=Time.get_ticks_usec();var source=load("res://assets/environment/new_island/"+region+".glb").instantiate()
		var load_ms:float=(Time.get_ticks_usec()-load_start)/1000.0
		for visual in source.find_children("*","MeshInstance3D",true,false):
			var before:PackedVector3Array=visual.mesh.get_faces();var start:=Time.get_ticks_usec();polish._smooth_normals(visual)
			var ms:float=(Time.get_ticks_usec()-start)/1000.0;assert(before==visual.mesh.get_faces())
			rows.append({'region':region,'mesh':str(visual.name),'normal_and_lod_ms':ms,'region_load_ms':load_ms,'faces_identical':true,'triangles':before.size()/3})
		source.free()
	var landscape=load("res://scripts/island_landscape.gd").new();landscape._build_grotto()
	var grotto=landscape.get_node("PlayableGrotto");var start:=Time.get_ticks_usec();polish._smooth_normals(grotto)
	rows.append({'region':'grotto','normal_and_lod_ms':(Time.get_ticks_usec()-start)/1000.0})
	landscape.free();polish.free()
	var f:=FileAccess.open("res://.validation/island_task51/startup_microprofile.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({'platform':OS.get_name(),'android_measurement':false,'scope':'Existing normal/LOD functions invoked once on original source meshes; desktop CPU microprofile, not complete app startup or a sustained frame benchmark','rows':rows},'  '));print('PASS: startup normal/LOD CPU microprofile recorded without source or geometry changes');call_deferred('quit')
