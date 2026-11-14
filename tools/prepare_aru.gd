extends SceneTree

# Offline preparation only. See assets/characters/aru/README.md for source acquisition.
const SOURCE="res://.validation/hero_upgrade_2026-11-14/source/Male_Ranger.gltf"
const BASE="res://assets/characters/quaternius/Superhero_Male_FullBody.gltf"
const OUT="res://assets/characters/aru/"
var groups: Dictionary={}
var materials: Dictionary={}
var rig: Skeleton3D
var before_triangles:=0
var after_triangles:=0

func _initialize(): call_deferred("run")

func texture(source: String, name: String, pixels: int) -> Texture2D:
	var path:=OUT+name+".png"
	if "--textures-only" not in OS.get_cmdline_user_args():
		var imported: Texture2D=load(path)
		assert(imported!=null,"Import prepared textures before baking the scene.")
		return imported
	var image:=Image.load_from_file(ProjectSettings.globalize_path(source))
	assert(image!=null,"Required source texture is missing: "+source)
	image.resize(pixels,pixels,Image.INTERPOLATE_LANCZOS)
	assert(image.save_png(path)==OK)
	var settings:=ConfigFile.new()
	settings.set_value("remap","importer","texture")
	settings.set_value("remap","type","CompressedTexture2D")
	settings.set_value("deps","source_file",path)
	settings.set_value("params","compress/mode",2)
	settings.set_value("params","compress/high_quality",false)
	settings.set_value("params","compress/normal_map",1 if "normal" in name else 0)
	settings.set_value("params","mipmaps/generate",true)
	assert(settings.save(path+".import")==OK)
	return ImageTexture.create_from_image(image)

func material(key: String, color_map: Texture2D, roughness: float) -> StandardMaterial3D:
	var result:=StandardMaterial3D.new()
	result.resource_name=key
	result.albedo_texture=color_map
	result.roughness=roughness
	result.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return result

func reduced(arrays: Array, budget: int) -> Array:
	var result: Array=arrays.duplicate(true)
	var indices: PackedInt32Array=result[Mesh.ARRAY_INDEX]
	before_triangles+=indices.size()/3
	if budget>0 and indices.size()/3>budget:
		var importer:=ImporterMesh.new()
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,result)
		importer.generate_lods(25,60,[])
		var best: PackedInt32Array=indices
		for lod in range(importer.get_surface_lod_count(0)):
			var candidate:=importer.get_surface_lod_indices(0,lod)
			if candidate.size()/3>=budget*0.75 and candidate.size()<best.size(): best=candidate
		result[Mesh.ARRAY_INDEX]=best
	after_triangles+=result[Mesh.ARRAY_INDEX].size()/3
	return result

func append(arrays: Array, key: String) -> void:
	for custom in range(Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM3+1): arrays[custom]=null
	if not groups.has(key):
		var surface:=SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		groups[key]=surface
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	assert(mesh.get_surface_count()==1,"Unable to bake surface: "+key)
	groups[key].append_from(mesh,0,Transform3D.IDENTITY)

func bone_index(skin: Skin, index: int, skeleton: Skeleton3D) -> int:
	var bone:=skin.get_bind_bone(index)
	if bone<0: bone=skeleton.find_bone(skin.get_bind_name(index))
	assert(bone>=0)
	return bone

func outfit_arrays(part: MeshInstance3D, arrays: Array) -> Array:
	var result: Array=arrays.duplicate(true)
	var vertices: PackedVector3Array=result[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=result[Mesh.ARRAY_NORMAL]
	var bones: PackedInt32Array=result[Mesh.ARRAY_BONES]
	var to_rig:=rig.global_transform.affine_inverse()*part.global_transform
	for i in range(vertices.size()):
		vertices[i]=to_rig*vertices[i]
		normals[i]=(to_rig.basis*normals[i]).normalized()
	for i in range(bones.size()): bones[i]=bone_index(part.skin,bones[i],rig)
	result[Mesh.ARRAY_VERTEX]=vertices
	result[Mesh.ARRAY_NORMAL]=normals
	result[Mesh.ARRAY_BONES]=bones
	# Rebuild tangents after combining surfaces in the final local frame.
	result[Mesh.ARRAY_TANGENT]=null
	return result

func head_arrays(part: MeshInstance3D, arrays: Array, old_rig: Skeleton3D, body: bool) -> Array:
	var result: Array=arrays.duplicate(true)
	var indices: PackedInt32Array=result[Mesh.ARRAY_INDEX]
	var vertices: PackedVector3Array=result[Mesh.ARRAY_VERTEX]
	var selected:=PackedInt32Array()
	for at in range(0,indices.size(),3):
		var valid:=true
		if body:
			for index in indices.slice(at,at+3):
				if (part.global_transform*vertices[index]).y<1.485: valid=false
		if valid: selected.append_array(indices.slice(at,at+3))
	if selected.is_empty(): return []
	var normals: PackedVector3Array=result[Mesh.ARRAY_NORMAL]
	var bones: PackedInt32Array=result[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array=result[Mesh.ARRAY_WEIGHTS]
	var old_to_rig:=old_rig.global_transform.affine_inverse()*part.global_transform
	var maps: Array[Transform3D]=[]
	var new_bones:=PackedInt32Array()
	for bind in range(part.skin.get_bind_count()):
		var old_bone:=bone_index(part.skin,bind,old_rig)
		var new_bone:=rig.find_bone(old_rig.get_bone_name(old_bone))
		assert(new_bone>=0)
		new_bones.append(new_bone)
		maps.append(rig.get_bone_global_rest(new_bone)*old_rig.get_bone_global_rest(old_bone).affine_inverse())
	var influences:=bones.size()/vertices.size()
	for i in range(vertices.size()):
		var position:=Vector3.ZERO
		var normal:=Vector3.ZERO
		var original:=old_to_rig*vertices[i]
		var source_normal:=old_to_rig.basis*normals[i]
		for j in range(influences):
			var at:=i*influences+j
			position+=(maps[bones[at]]*original)*weights[at]
			normal+=(maps[bones[at]].basis*source_normal)*weights[at]
			bones[at]=new_bones[bones[at]]
		vertices[i]=position
		normals[i]=normal.normalized()
	result[Mesh.ARRAY_VERTEX]=vertices
	result[Mesh.ARRAY_NORMAL]=normals
	result[Mesh.ARRAY_BONES]=bones
	result[Mesh.ARRAY_INDEX]=selected
	result[Mesh.ARRAY_TANGENT]=null
	return result

func own(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner=owner_node
		own(child,owner_node)

func run():
	assert(FileAccess.file_exists(SOURCE),"Stage the selected author-provided source locally first.")
	DirAccess.make_dir_recursive_absolute(OUT)
	var document:=GLTFDocument.new()
	var state:=GLTFState.new()
	assert(document.append_from_file(SOURCE,state)==OK)
	var outfit=document.generate_scene(state)
	outfit.name="AruStarterWarrior"
	root.add_child(outfit)
	var base=load(BASE).instantiate()
	root.add_child(base)
	rig=outfit.find_children("*","Skeleton3D",true,false)[0]
	var old_rig: Skeleton3D=base.find_children("*","Skeleton3D",true,false)[0]
	assert(rig.get_bone_count()==65)
	var cloth=texture("res://.validation/hero_upgrade_2026-11-14/source/Ranger_Color.png","ranger_color_1024",1024)
	var skin=texture("res://.validation/hero_upgrade_2026-11-14/source/Skin_Color.png","arms_color_1024",1024)
	var face=texture("res://assets/characters/quaternius/T_Superhero_Male_Dark.png","face_color_1024",1024)
	var brow=texture("res://assets/characters/quaternius/T_Hair_1_BaseColor.png","brow_color_512",512)
	materials.Ranger=material("Aru cloth and leather",cloth,0.88)
	materials.Ranger.normal_enabled=true
	materials.Ranger.normal_texture=texture("res://.validation/hero_upgrade_2026-11-14/source/Ranger_Normal.png","ranger_normal_1024",1024)
	materials.Ranger.roughness_texture=texture("res://.validation/hero_upgrade_2026-11-14/source/Ranger_ORM.png","ranger_orm_1024",1024)
	materials.Ranger.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	materials.Ranger.metallic=0.45
	materials.Ranger.metallic_texture=materials.Ranger.roughness_texture
	materials.Ranger.metallic_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	materials.Arms=material("Aru hands and arms",skin,0.72)
	materials.Face=material("Aru face",face,0.72)
	materials.Face.normal_enabled=true
	materials.Face.normal_texture=texture("res://assets/characters/quaternius/T_Superhero_Male_Normal.png","face_normal_512",512)
	materials.Brows=material("Aru brows",brow,0.9)
	materials.Brows.albedo_color=Color("30251d")
	materials.Brows.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	materials.Brows.alpha_scissor_threshold=0.4
	materials.Brows.cull_mode=BaseMaterial3D.CULL_DISABLED
	materials.Eyes=material("Aru eyes",load("res://assets/characters/quaternius/T_Eye_Brown.png"),0.45)
	if "--textures-only" in OS.get_cmdline_user_args():
		outfit.free()
		base.free()
		print("PASS: staged mobile-sized color/normal/ORM textures for native GPU compression")
		quit()
		return
	var belt_kept:=false
	for part in outfit.find_children("*","MeshInstance3D",true,false):
		if "Belt" in part.name:
			if belt_kept:
				part.free()
				continue
			belt_kept=true
		for surface in range(part.mesh.get_surface_count()):
			var key: String="Arms" if "Regular" in part.get_active_material(surface).resource_name else "Ranger"
			var budget:=0
			if "Pauldron" in part.name: budget=700
			elif "Boot" in part.name: budget=2200
			elif "Bracer" in part.name: budget=1000
			elif "Hood" in part.name: budget=0
			elif "Belt" in part.name: budget=500
			elif "Body" in part.name: budget=0
			elif "Arms" in part.name and key=="Ranger": budget=1000
			append(reduced(outfit_arrays(part,part.mesh.surface_get_arrays(surface)),budget),key)
		part.free()
	for part in base.find_children("*","MeshInstance3D",true,false):
		var key: String="Eyes" if "Eyes" in part.name else ("Brows" if "Eyebrows" in part.name else "Face")
		for surface in range(part.mesh.get_surface_count()):
			var arrays:=head_arrays(part,part.mesh.surface_get_arrays(surface),old_rig,key=="Face")
			if not arrays.is_empty(): append(reduced(arrays,0),key)
	var mesh:=ArrayMesh.new()
	for key in groups:
		var surface: SurfaceTool=groups[key]
		surface.deindex()
		surface.index()
		surface.generate_tangents()
		surface.set_material(materials[key])
		surface.commit(mesh)
	mesh.resource_name="Aru optimized starter warrior"
	assert(ResourceSaver.save(mesh,OUT+"starter_warrior_mesh.res",ResourceSaver.FLAG_COMPRESS)==OK)
	var instance:=MeshInstance3D.new()
	instance.name="StarterWarrior"
	instance.mesh=load(OUT+"starter_warrior_mesh.res")
	instance.skin=rig.create_skin_from_rest_transforms()
	rig.add_child(instance)
	instance.skeleton=NodePath("..")
	for animation in outfit.find_children("*","AnimationPlayer",true,false): animation.free()
	own(outfit,outfit)
	outfit.scene_file_path=""
	var packed:=PackedScene.new()
	assert(packed.pack(outfit)==OK)
	assert(ResourceSaver.save(packed,OUT+"starter_warrior.scn",ResourceSaver.FLAG_COMPRESS)==OK)
	print("PASS: prepared skinned warrior; source triangles ",before_triangles," -> ",after_triangles,"; surfaces ",mesh.get_surface_count(),"; bones ",rig.get_bone_count())
	outfit.free()
	base.free()
	quit()
