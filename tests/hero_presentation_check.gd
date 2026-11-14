extends SceneTree

func _initialize(): call_deferred("run")

func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	var hero=scene.player
	hero.set_physics_process(false)
	var visual=hero._visual
	var rig: Skeleton3D=visual.hand.get_parent()
	var garment: MeshInstance3D=rig.get_node("StarterWarrior")
	assert(garment.skin!=null and garment.mesh is ArrayMesh and garment.mesh.get_surface_count()==5)
	assert(rig.get_bone_count()==65 and garment.skin.get_bind_count()==65)
	assert(garment.get_node(garment.skeleton)==rig)
	assert(visual.find_child("Tunic",true,false)==null and visual.find_child("LeftShoe",true,false)==null,"Primitive outfit must be retired")
	var triangles:=0
	var weights_checked:=0
	for surface in range(garment.mesh.get_surface_count()):
		var arrays: Array=garment.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
		triangles+=indices.size()/3
		assert(vertices.size()>0 and indices.size()>0 and bones.size()==vertices.size()*4 and bones.size()==weights.size())
		for i in range(vertices.size()):
			assert(vertices[i].is_finite())
			var total:=0.0
			for influence in range(4):
				var at:=i*4+influence
				assert(bones[at]>=0 and bones[at]<65 and is_finite(weights[at]) and weights[at]>=0)
				total+=weights[at]
			assert(absf(total-1.0)<0.02,"Every garment/head vertex must retain normalized skin weights")
			weights_checked+=1
		var material: StandardMaterial3D=garment.get_active_material(surface)
		assert(material!=null and material.albedo_texture!=null)
		for texture in [material.albedo_texture,material.normal_texture,material.roughness_texture]:
			if texture!=null: assert(texture.get_width()<=1024 and texture.get_height()<=1024,"Prepared textures must retain the mobile size cap")
	assert(triangles<=19000 and triangles>10000,"Keep the model inside its reviewed geometry budget")
	var original: Vector3=hero.position
	for clip in visual.CLIPS:
		visual.animator.play(clip)
		visual.animator.seek(visual.animator.get_animation(clip).length*0.1,true)
		visual.animator.advance(0.0)
		await process_frame
		var before: Transform3D=rig.get_bone_global_pose(rig.find_bone("hand_r"))
		visual.animator.seek(visual.animator.get_animation(clip).length*0.65,true)
		visual.animator.advance(0.0)
		await process_frame
		var after: Transform3D=rig.get_bone_global_pose(rig.find_bone("hand_r"))
		assert(not before.is_equal_approx(after),"Selected animation must move the real rig: "+clip)
		assert(hero.position==original,"Character animation must never drive the gameplay collision body")
		var transforms: Array[Transform3D]=[]
		for bone in range(65): transforms.append(rig.get_bone_global_pose(bone)*rig.get_bone_global_rest(bone).affine_inverse())
		for surface in range(garment.mesh.get_surface_count()):
			var arrays: Array=garment.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			for i in range(0,vertices.size(),19):
				var posed:=Vector3.ZERO
				for j in range(4): posed+=(transforms[bones[i*4+j]]*vertices[i])*weights[i*4+j]
				assert(posed.is_finite() and posed.length()<3.5,"Skinning must remain bounded in "+clip)
	hero._sound.stop()
	scene.queue_free()
	await process_frame
	paused=false
	print("PASS: real skinned warrior, 65-bone bindings, ",weights_checked," normalized vertex weights, capped textures, all 11 clips move the rig, bounded skinning and isolated collision body")
	quit()
