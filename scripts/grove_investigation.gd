extends Node3D

const PARTIAL := "grove_clues_read"
const DONE := "ancient_grove_investigated"
const STONE := Vector3(3.8,0,-49)
const PRINTS := Vector3(13,0,-39)
const CAVE_MOUTH := Vector3(76,0,-17)
const SEARCH := [Vector3(7,0,-44), Vector3(6.3,0,-46), Vector3(11,0,-41)]
const HINTS := ["Follow the gold thread northeast. What caught the light on the bank?",
	"The vein bends uphill. Find its mark on the broken stone.",
	"Something dragged earth across the seal. Read the tracks on the lower bank."]
const PROMPTS := ["Touch the ember-veined roots", "Trace the Lantern seal", "Read the heavy tracks"]
const FINDINGS := ["The roots glow from below. The curse is travelling beneath our feet.",
	"The same seal is cut into this stone. The Lantern once bound something underground.",
	"Five claws, sunk deep. The seal's guardian has worn a path to the eastern cave."]
const OUTWARD := [Vector3(18,0,-36), Vector3(23,0,-33), Vector3(32,0,-32),
	Vector3(47,0,-30), Vector3(60,0,-26), Vector3(71,0,-23), CAVE_MOUTH]
const CUES := [preload("res://assets/audio/grove/root.wav"), preload("res://assets/audio/grove/seal.wav"),
	preload("res://assets/audio/grove/tracks.wav")]
var game
var clues: Array[Node3D] = []
var roots_sap: StandardMaterial3D
var engraving: StandardMaterial3D
var lantern_gold: StandardMaterial3D
var routes: Array[MeshInstance3D] = []
var sound := AudioStreamPlayer3D.new()
var notice := ""
var notice_time := 0.0
var lens: Tween
var rest_fov := 75.0
var nearby := false
var proximity_glow: Tween
var spoor: Array[MeshInstance3D] = []

func stage() -> int:
	if game.world_data.get(DONE, false):
		return 3
	var saved: Variant = game.world_data.get(PARTIAL, 0)
	return clampi(saved, 0, 2) if saved is int else 0

func in_reach() -> bool:
	var n := stage()
	if n >= clues.size() or not game.lantern_lit:
		return false
	var local := clues[n].to_local(game.player.global_position)
	# The inscription can only be read from its carved face.
	return local.length() <= 2.8 and (n != 1 or local.z > .25)

func populate(island) -> void:
	game = island
	clues.append(game.guardians.grove_roots)
	roots_sap = clues[0].mesh.surface_get_material(1)
	roots_sap.emission = Color("ca3922")
	engraving = _material(Color("503e34"))
	engraving.emission_enabled = true
	engraving.emission = Color("ff7941")
	lantern_gold = _material(Color("926d43"))
	lantern_gold.emission_enabled = true
	lantern_gold.emission = Color("ffb950")
	_sigil(game.lantern, Vector3(0,.89,.55), .32, lantern_gold)
	var slab := _site("SplitSealstone", STONE)
	clues.append(slab)
	_build_stone(slab)
	var tracks := _site("RakedBank", PRINTS)
	clues.append(tracks)
	_build_tracks(tracks)
	var start: Vector3 = game.lantern.global_position
	_trail([start, Vector3(2,0,-26),Vector3(4.5,0,-32),Vector3(5.5,0,-38), clues[0].global_position], Color("ffc369"))
	_trail([clues[0].global_position, Vector3(6.2,0,-45.6),STONE], Color("f97d49"))
	_trail([STONE, Vector3(5.5,0,-43),Vector3(9.6,0,-40.8),PRINTS], Color("ee6e4d"))
	var east := [PRINTS]
	east.append_array(OUTWARD)
	_trail(east, Color("e49a59"))
	sound.name = "ClueResonance"
	sound.max_distance = 17
	sound.unit_size = 4
	sound.volume_db = -9
	add_child(sound)

func refresh(animate: bool) -> void:
	var n := stage()
	lantern_gold.emission_energy_multiplier = .9 if game.lantern_lit else 0.0
	roots_sap.emission_energy_multiplier = 1.5 if n >= 1 else .15
	engraving.emission_energy_multiplier = 1.05 if n >= 2 else .035
	for i in routes.size():
		var route := routes[i]
		route.visible = game.lantern_lit and i <= n and not game._sanctum_open()
		if not route.visible:
			continue
		var material: ShaderMaterial = route.material_override
		var length: float = route.get_meta("length")
		if animate and i == n:
			material.set_shader_parameter("front", 0.0)
			create_tween().tween_method(func(v: float): material.set_shader_parameter("front", v), 0.0, length+3.0, clampf(length/8, .8, 6))
		else:
			material.set_shader_parameter("front", length+3)
	if animate and n == 0:
		_react(game.lantern.global_position, 1, "The light is leaving the Lantern. Follow it northeast.")
	set_process(game.lantern_lit and not game._sanctum_open())

func investigate() -> void:
	if not in_reach():
		return
	var n := stage()
	if proximity_glow:
		proximity_glow.kill()
	if n == 2:
		game.world_data.erase(PARTIAL)
		game.world_data[DONE] = true
		game._award_shards(game._grove_shard_reward())
	else:
		game.world_data[PARTIAL] = n+1
	game.set_tracked_quest("main")
	game._save_progress()
	refresh(true)
	_react(clues[n].global_position, n, FINDINGS[n])
	if n == 1:
		var trace := create_tween()
		engraving.emission_energy_multiplier = .15
		trace.tween_property(engraving, "emission_energy_multiplier", 2.2, .42)
		trace.tween_property(engraving, "emission_energy_multiplier", 1.05, .8)
	if n == 2:
		for i in spoor.size():
			var clay: StandardMaterial3D = spoor[i].material_override
			var echo := create_tween()
			echo.tween_interval(.2*i)
			echo.tween_property(clay, "emission_energy_multiplier", .48, .22)
			echo.tween_property(clay, "emission_energy_multiplier", 0.0, .65)
		for mat in [roots_sap, engraving]:
			var pulse := create_tween()
			pulse.tween_property(mat, "emission_energy_multiplier", 3.5, .32)
			pulse.tween_property(mat, "emission_energy_multiplier", 1.2, 1.0)
	game._redraw_tracking()

func _process(delta: float) -> void:
	if game._sanctum_open():
		refresh(false)
		return
	notice_time = maxf(0, notice_time-delta)
	if stage() != 0:
		return
	var close: bool = game.player.global_position.distance_squared_to(clues[0].global_position) < 30
	if close != nearby:
		nearby = close
		if proximity_glow:
			proximity_glow.kill()
		proximity_glow = create_tween()
		proximity_glow.tween_property(roots_sap, "emission_energy_multiplier", 1.6 if close else .15, .45)

func _react(at: Vector3, cue: int, finding: String) -> void:
	notice = finding
	notice_time = 4.4
	sound.global_position = at + Vector3.UP*.5
	sound.stream = CUES[cue]
	sound.play()
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	if lens and lens.is_running():
		lens.kill()
	else:
		rest_fov = camera.fov
	lens = create_tween().set_trans(Tween.TRANS_SINE)
	lens.tween_property(camera, "fov", rest_fov - 4.5, .3)
	lens.tween_property(camera, "fov", rest_fov, .62)

func _site(label: String, point: Vector3) -> Node3D:
	var site := Node3D.new()
	site.name = label
	add_child(site)
	site.global_position = game.landscape.ground_point(point)
	return site

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .94
	return mat

func _piece(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = mat
	parent.add_child(part)
	part.position = pos
	return part

func _sigil(parent: Node3D, center: Vector3, r: float, mat: Material) -> void:
	# A split ring and a pointed wick, shared by the Lantern collar and older tablet.
	var lines := SurfaceTool.new()
	lines.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 30:
		if i in [6,7,21]: continue
		var a := TAU*i/30
		var b := TAU*(i+1)/30
		for v in [Vector2.from_angle(a)*.83,Vector2.from_angle(a),Vector2.from_angle(b),
				Vector2.from_angle(a)*.83,Vector2.from_angle(b),Vector2.from_angle(b)*.83]:
			lines.add_vertex(Vector3(v.x,v.y,0)*r)
	for p in [Vector2(0,.74),Vector2(-.31,-.22),Vector2(.05,-.61), Vector2(0,.74),Vector2(.05,-.61),Vector2(.28,.02)]:
		lines.add_vertex(Vector3(p.x,p.y,0)*r)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_piece(parent, lines.commit(), center, mat)

func _build_stone(site: Node3D) -> void:
	var rock := _material(Color("d2c5af"))
	rock.albedo_texture = preload("res://assets/environment/polyhaven/rocky_terrain_02_Diffuse.jpg")
	rock.uv1_triplanar = true
	rock.uv1_scale = Vector3.ONE * .58
	rock.cull_mode = BaseMaterial3D.CULL_DISABLED
	var outline := PackedVector2Array([Vector2(-1.1,-.25),Vector2(1.0,-.25),Vector2(.87,1.55),
		Vector2(.48,2.09),Vector2(.18,1.93),Vector2(-.12,2.18),Vector2(-.74,2.05),Vector2(-1,1.47)])
	var stone := SurfaceTool.new()
	stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i+1)%outline.size()]
		var front := Vector3(a.x*.88,lerpf(1,a.y,.91),.24)
		var next := Vector3(b.x*.88,lerpf(1,b.y,.91),.24)
		var lip := Vector3(a.x,a.y,.11)
		var lip_next := Vector3(b.x,b.y,.11)
		for v in [Vector3(0,.87,.24),next,front, front,next,lip_next,front,lip_next,lip,
				lip,lip_next,lip_next-Vector3.BACK*.46,lip,lip_next-Vector3.BACK*.46,lip-Vector3.BACK*.46,
				Vector3(0,.87,-.35),lip-Vector3.BACK*.46,lip_next-Vector3.BACK*.46]:
			stone.add_vertex(v)
	stone.generate_normals()
	_piece(site,stone.commit(),Vector3.ZERO,rock)
	for i in 4:
		var shard := PrismMesh.new()
		shard.size = Vector3(.47 + .08*i, .28+i*.09, .52)
		var chip := _piece(site,shard,Vector3(-1.05+.64*i,.07,.46+.12*(i%2)),rock)
		chip.rotation = Vector3(.14*i,.97*i,.22)
	_sigil(site,Vector3(-.04,1.13,.25),.55,engraving)
	site.rotation.y = .47
	site.rotation.z = -.12

func _build_tracks(site: Node3D) -> void:
	# Inlaid print silhouettes follow the terrain, including the five toes and raked clay.
	var heading := Vector2(.85,.53).normalized()
	var across := Vector2(-heading.y,heading.x)
	for i in 4:
		var earth := SurfaceTool.new()
		earth.begin(Mesh.PRIMITIVE_TRIANGLES)
		var at := heading*(i-1.5)*1.48 + across*(.46 if i%2 else -.46)
		_imprint(earth,site,at,heading,.35,.33,Color("412d26"))
		for j in 5:
			var spread := (j-2)*.165
			var toe := at + across*spread + heading*(.47-absf(spread)*.42)
			_imprint(earth,site,toe,heading,.083,.104,Color("493227"))
			_imprint(earth,site,toe+heading*.17,heading,.028,.10,Color("725145"))
		if i == 0:
			for j in 4:
				_imprint(earth,site,across*(1.05+j*.16)-heading*.48,heading,.049,.86-j*.09,Color("673e31"))
		var soil := _material(Color.WHITE)
		soil.vertex_color_use_as_albedo = true
		soil.cull_mode = BaseMaterial3D.CULL_DISABLED
		soil.emission_enabled = true
		soil.emission = Color("b54928")
		soil.emission_energy_multiplier = 0
		spoor.append(_piece(site, earth.commit(), Vector3.ZERO, soil))

func _imprint(s: SurfaceTool, site: Node3D, center: Vector2, direction: Vector2, width: float, length: float, tint: Color) -> void:
	var ring := PackedVector3Array()
	for k in 12:
		var a := TAU*k/12
		var offset := center + direction*cos(a)*length + Vector2(-direction.y,direction.x)*sin(a)*width
		var p: Vector3 = game.landscape.ground_point(site.position+Vector3(offset.x,0,offset.y))
		ring.append(p-site.position+Vector3.UP*.032)
	var middle := (ring[0]+ring[6])*.5
	for k in 12:
		for v in [ring[k],ring[(k+1)%12],middle]:
			s.set_color(tint if v == middle else tint.lightened(.11))
			s.set_normal(Vector3.UP)
			s.add_vertex(v)

func _trail(points: Array, tint: Color) -> void:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var distance := 0.0
	var last := Vector3.ZERO
	for i in range(1,points.size()):
		var a: Vector3 = points[i-1]
		var b: Vector3 = points[i]
		var side := Vector3(b.z-a.z,0,a.x-b.x).normalized()
		var steps := ceili(a.distance_to(b)/.42)
		for j in range(steps+1):
			var at := a.lerp(b,float(j)/steps)
			at += side * (.18*sin(distance*1.6)+.08*sin(distance*3.2))
			at = game.landscape.ground_point(at)+Vector3.UP*.052
			if j > 0:
				var next := distance + at.distance_to(last)
				var width := .044 + .02*sin(next*1.9)
				for pair in [[last-side*width,distance,0],[last+side*width,distance,1],[at+side*width,next,1],
						[last-side*width,distance,0],[at+side*width,next,1],[at-side*width,next,0]]:
					s.set_uv(Vector2(pair[1],pair[2]))
					s.add_vertex(pair[0])
				distance = next
			last = at
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/grove_ember.gdshader")
	mat.set_shader_parameter("ember",tint)
	var route := _piece(self,s.commit(),Vector3.ZERO,mat)
	route.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	route.set_meta("length",distance)
	routes.append(route)
