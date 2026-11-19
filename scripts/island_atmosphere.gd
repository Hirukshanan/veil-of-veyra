extends Node3D

# Candidate-only dressing. No physics, progression, vegetation or water edits.
const LIGHTING := preload("res://scripts/island_lighting.gd")
var landmark_positions:Array[Vector3]=[]
var added_triangles:=0
var _lighting: Node

func set_boss_night(enabled: bool, duration: float = LIGHTING.TRANSITION_SECONDS) -> void:
	_lighting.set_boss_night(enabled, duration)

func populate(scene:Node3D)->void:
	var world: WorldEnvironment
	var sun: DirectionalLight3D
	for node in scene.get_children():
		if node is WorldEnvironment:
			world = node
			var environment:Environment=node.environment
			var sky:ProceduralSkyMaterial=environment.sky.sky_material
			sky.sky_top_color=Color(.20,.37,.52);sky.sky_horizon_color=Color(.66,.74,.73)
			sky.ground_horizon_color=sky.sky_horizon_color;sky.sky_curve=.32
			environment.ambient_light_color=Color(.62,.72,.77);environment.ambient_light_energy=.38
			environment.fog_enabled=true;environment.fog_mode=Environment.FOG_MODE_DEPTH
			environment.fog_light_color=Color(.61,.71,.74);environment.fog_light_energy=.75
			environment.fog_density=.25;environment.fog_depth_begin=40;environment.fog_depth_end=300;environment.fog_depth_curve=1.5
			environment.fog_sun_scatter=.10;environment.fog_aerial_perspective=.18;environment.fog_sky_affect=.18
			environment.volumetric_fog_enabled=false;environment.glow_enabled=false
		if node is DirectionalLight3D:
			sun = node
			node.rotation_degrees=Vector3(-39,-32,0);node.light_color=Color(1.0,.94,.83);node.light_energy=1.12
			node.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
			node.directional_shadow_max_distance=26;node.directional_shadow_fade_start=.78
			node.shadow_bias=.035;node.shadow_normal_bias=1.0
	_lighting = LIGHTING.new()
	_lighting.name = "IslandLighting"
	_lighting.initialize(scene, sun, world.environment)
	add_child(_lighting)
	# Keep the existing shadow preference and settings menu behavior.
	var landscape:Node3D=scene.landscape
	for visual in landscape.find_children("*","MeshInstance3D",true,false):
		var material:Material=visual.material_override
		if not material is ShaderMaterial:continue
		var shader_path:String=material.shader.resource_path
		if shader_path not in ["res://assets/environment/new_island/land.gdshader","res://assets/environment/new_island/region.gdshader"]:continue
		var copy:ShaderMaterial=material.duplicate()
		copy.shader=load("res://assets/environment/new_island/task4/"+shader_path.get_file())
		for uniform in material.shader.get_shader_uniform_list():
			copy.set_shader_parameter(uniform.name,material.get_shader_parameter(uniform.name))
		copy.set_shader_parameter("journey_mask",preload("res://assets/environment/new_island/task4/journey_mask.png"))
		visual.material_override=copy
	_landmark(landscape,Vector2(-34,15),"WayfarerSunwheel",8,2.5,0.12)
	_landmark(landscape,Vector2(12,31),"RiverCompass",5,2.15,0.71)

func _landmark(landscape:Node3D,center:Vector2,label:String,rays:int,radius:float,rotation:float)->void:
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Broken radial slate inlays sit flush against support, allowing normal traversal.
	for segment in range(44):
		if segment%11 in [0,1]:continue
		var a:float=segment*TAU/44+rotation;var b:float=(segment+.86)*TAU/44+rotation
		_quad(s,landscape,center,[Vector2(cos(a),sin(a))*radius,Vector2(cos(a),sin(a))*(radius-.22),Vector2(cos(b),sin(b))*radius,Vector2(cos(b),sin(b))*(radius-.22)])
	for ray in range(rays):
		var angle:float=ray*TAU/rays+rotation
		var direction:=Vector2(cos(angle),sin(angle));var tangent:=Vector2(-direction.y,direction.x)
		_quad(s,landscape,center,[direction*.48-tangent*.10,direction*.48+tangent*.10,direction*(radius-.48)-tangent*.055,direction*(radius-.48)+tangent*.055])
	s.generate_normals();var visual:=MeshInstance3D.new();visual.name=label;visual.mesh=s.commit()
	var material:=StandardMaterial3D.new();material.albedo_texture=preload("res://assets/environment/new_island/task3/rock_albedo.png")
	material.albedo_color=Color(1.08,1.01,.83);material.uv1_triplanar=true;material.uv1_triplanar_sharpness=4;material.uv1_world_triplanar=true;material.uv1_scale=Vector3.ONE*.6;material.roughness=.95
	visual.material_override=material;visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;visual.visibility_range_end=110
	add_child(visual);landmark_positions.append(landscape.ground_point(Vector3(center.x,0,center.y)));added_triangles+=visual.mesh.get_faces().size()/3
func _quad(s:SurfaceTool,landscape:Node3D,center:Vector2,corners:Array)->void:
	for index in [0,2,1,1,2,3]:
		var point:Vector2=center+corners[index]
		s.set_uv(point*.6);s.add_vertex(landscape.ground_point(Vector3(point.x,0,point.y))+Vector3.UP*.018)
