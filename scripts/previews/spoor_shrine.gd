extends "res://scripts/previews/tidewarden_visual_shrine.gd"

const TREE := Vector3(19.2,0,-26)
const READ := "riverside_claws_read"
const FINDING := "Four deep cuts expose fresh wood. The great pawprints turn north toward Ancient Grove."
const PROMPT := "Inspect the claw marks"
var landmark: Node3D
var grove_tracks: MeshInstance3D
var eastern_tracks: MeshInstance3D

static func spoor_route() -> Array:
	var route := cave_trail()
	route.resize(route.find(Vector3(2,0,-4))+1)
	route.append_array([Vector3(6,0,-9),Vector3(12,0,-16), Vector3(16.6,0,-20),TREE+Vector3(0,0,3.25)])
	return route

func populate(island) -> void:
	super.populate(island)
	grove_tracks = _tracks(spoor_route())
	grove_tracks.name = "BearImpressions"
	grove_tracks.visible = complete()
	beacon_awakened.connect(grove_tracks.show)
	_build_cave_guidance()
	landmark = preload("res://scripts/previews/riverside_veteran_tree.gd").new()
	landmark.name = "ClawMarkedRiverTree"
	add_child(landmark)
	landmark.build(game.landscape,_ground(TREE))

func _build_cave_guidance() -> void:
	var east := [GROVE.PRINTS]
	east.append_array(GROVE.OUTWARD)
	eastern_tracks = _tracks(east)
	eastern_tracks.name = "EasternBankImpressions"
	eastern_tracks.hide()
	_refresh_eastern_tracks()

func _process(delta: float) -> void:
	super._process(delta)
	_refresh_eastern_tracks()

func _refresh_eastern_tracks() -> void:
	var active: bool = complete() and game.grove.stage()==3 and not game._sanctum_open()
	if active != eastern_tracks.visible:
		eastern_tracks.visible = active

func _tracks(path: Array) -> MeshInstance3D:
	var soil := SurfaceTool.new()
	soil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var curve := Curve3D.new()
	for point: Vector3 in path:
		curve.add_point(point)
	var length := curve.get_baked_length()
	var distance := 4.1
	var group := 0
	while distance < length-.6:
		for step in 2 + group%2:
			if distance > length-.35:
				break
			var origin := curve.sample_baked(distance)
			var forward := origin.direction_to(curve.sample_baked(minf(distance+.28,length))).rotated(Vector3.UP,sin(distance)*.11)
			var right := Vector3(forward.z,0,-forward.x)
			origin += right*(.42 if step%2 else -.42)
			_paw(soil,origin,forward,right,1.0 if step%2 else .92)
			distance += 1.54+.13*sin(distance)
		distance += 4.2+1.8*absf(sin(group*2.6))
		group += 1
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1
	soil.index()
	var trail := _piece(self,soil.commit(),Vector3.ZERO,mat)
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return trail

func _paw(s: SurfaceTool, center: Vector3, fore: Vector3, side: Vector3, size_factor: float) -> void:
	# A broad asymmetric heel, five toe pads, and five finer claw punctures.
	_pad(s,center,fore,side,.28*size_factor,.34*size_factor,true)
	for toe in 5:
		var x := (toe-2)*.142*size_factor
		var at := center + side*x + fore*(.34-.12*pow(absf(x)/.29,2)+x*.14)
		_pad(s,at,fore,side,.12*size_factor,.072,false)
		_pad(s,at+fore*.19,fore,side,.068,.023,false)

func _pad(s: SurfaceTool, at: Vector3, fore: Vector3, side: Vector3, length: float, width: float, sole: bool) -> void:
	var hit: Dictionary = game.landscape.ground_hit(at)
	if hit.is_empty():
		return
	var contact: Vector3 = hit.position
	if absf(at.x-game.landscape.SURFACE.river_center(at.z)) < game.landscape.SURFACE.river_width(at.z) and contact.y < game.landscape.SURFACE.river_level(at.z)+.05:
		return
	var up: Vector3 = hit.normal
	var outside: Array[Vector3] = []
	var inside: Array[Vector3] = []
	var dark := Color("433b2a")
	var rim := Color("746548")
	for k in 10:
		var angle := TAU*k/10.0
		var stretch := 1.0+.20*cos(angle) if sole else 1.0
		var delta := fore*cos(angle)*length+side*sin(angle)*width*stretch
		delta.y = -(up.x*delta.x+up.z*delta.z)/maxf(up.y,.1)
		outside.append(contact+delta+Vector3.UP*.027)
		inside.append(contact+delta*.73+Vector3.UP*.017)
	var middle := contact+Vector3.UP*.016
	for k in 10:
		var n := (k+1)%10
		for pt in [outside[k],outside[n],inside[n],outside[k],inside[n],inside[k],inside[k],inside[n],middle]:
			s.set_color(rim if pt == outside[k] or pt == outside[n] else dark)
			s.set_normal(Vector3.UP)
			s.add_vertex(pt)

func read_claws() -> bool:
	return game.world_data.get(READ,false)

func tree_in_reach() -> bool:
	if not complete() or read_claws() or not is_instance_valid(landmark) or not game.started or game.game_finished or game.get_tree().paused or game.player.health <= 0 or game.shrine.in_cell:
		return false
	var local: Vector3 = landmark.to_local(game.player.global_position)
	return absf(local.x)<1.96 and local.z>1.0 and local.z<4.4 and absf(local.y)<1.6

func inspect_tree() -> void:
	if not tree_in_reach():
		return
	game.world_data[READ] = true
	game.grove._react(landmark.global_position+Vector3(0,2,1.6),2,FINDING)
	game._save_progress()
	game._redraw_tracking()

func next_step() -> String:
	if complete() and not read_claws():
		return "Follow the broken groups of pawprints to the old tree on the riverbank."
	if complete() and game.grove.stage()<3:
		return "Read the evidence at Ancient Grove." if game.lantern_lit else "Restore the Northern Lantern at the shrine beacon."
	return super.next_step()

func objective() -> Dictionary:
	var row := super.objective()
	row.reward = "Reveal the guardian’s trail to the river."
	if read_claws():
		row.description += "\nRiverbank · " + FINDING
	return row
