extends Node3D

signal beacon_awakened

const STORE := preload("res://scripts/campaign_store.gd")
const GROVE := preload("res://scripts/grove_investigation.gd")
const CENTER := Vector3(-49.1,0,51.6)
# The western three standing stones of the authored Tideseal Ruins ring.
const SITES := [Vector3(-52.5592,0,58.1219), Vector3(-52.5592,0,49.8781), Vector3(-46.11395,0,44.7382)]
const REGION := preload("res://scripts/chapter_one_region.gd")
const TITLE := "Forgotten Tidewarden Shrine"
const ID := "tidewarden"
const FACES := ["Bind the Root Seal", "Align the Tide Seal", "Wake the Beacon Seal"]
const SEALS := ["Root", "Tide", "Beacon"]
const FINDINGS := [
	"The roots held the ward in place. Its first line runs beneath the forest.",
	"The tide cut this channel. The ward carried its light underground.",
	"The three lines answer one another. This ward once guarded the eastern cave.",
]
const TINTS := [Color("d7ae63"), Color("85c5b0"), Color("8dd9da")]
const ALL_SEATS := 7
const DISCOVERED := 8

var game
var pillars: Array[Node3D] = []
var inserts: Array[MeshInstance3D] = []
var grooves: Array[StandardMaterial3D] = []
var beacon: MeshInstance3D
var beacon_light: StandardMaterial3D
var stone: StandardMaterial3D
var trim: StandardMaterial3D
var seam: StandardMaterial3D
var moss: StandardMaterial3D
var sound: AudioStreamPlayer3D
var notice := ""
var notice_time := 0.0
var lighting: Tween

func populate(island) -> void:
	game = island
	name = "ForgottenTidewardenShrine"
	stone = preload("res://scripts/environment_materials.gd").surface("rocky_terrain_02", .63, Color("aaa395"))
	trim = stone.duplicate()
	trim.albedo_color = Color("786a52")
	seam = stone.duplicate()
	seam.albedo_color = Color("342e25")
	moss = stone.duplicate()
	moss.albedo_color = Color("617451")
	var originals := _forest_pillars(game.seal_fragments.get_node("Scenery"))
	if originals.size() != SITES.size():
		push_error("Tidewarden Shrine needs the three original western Tideseal pillars.")
		queue_free()
		return
	for index in originals.size():
		_build_pillar(originals[index], index)
	_build_beacon()
	_build_court()
	sound = AudioStreamPlayer3D.new()
	sound.max_distance = 18
	sound.unit_size = 3.5
	sound.volume_db = -4
	add_child(sound)
	restore_visuals()

static func cave_trail() -> Array:
	var route := [CENTER]
	route.append_array(REGION.TRAILS[0].slice(0, 4))
	# The old foothill route clips a steep shelf; cross the gradual south shoulder.
	route.append_array([Vector3(-35,0,9), Vector3(-23,0,9), Vector3(-10,0,11),
		Vector3(0,0,8), Vector3(2,0,-4), Vector3(1.85,0,-20)])
	route.append_array(REGION.TRAILS[1])
	return route
func mask() -> int:
	return game.world_data.get(STORE.TIDEWARDEN, 0)

func seated(index: int) -> bool:
	return (mask() & (1 << index)) != 0

func count() -> int:
	return int(seated(0)) + int(seated(1)) + int(seated(2))

func complete() -> bool:
	return (mask() & ALL_SEATS) == ALL_SEATS

func discovered() -> bool:
	return (mask() & DISCOVERED) != 0

func nearby() -> bool:
	return not game.shrine.in_cell and game.player.global_position.distance_squared_to(_world_center()) < 80.0

func available() -> bool:
	return discovered() or game.lantern_lit

func guides_main() -> bool:
	return game.lantern_lit and not complete() and not game.completed and not game.shrine.in_cell and game.grove.stage() == 0

func use_index() -> int:
	if not game.started or game.game_finished or get_tree().paused or game.player.health <= 0 or not nearby():
		return -1
	for index in pillars.size():
		var local := pillars[index].to_local(game.player.global_position)
		if local.z > .52 and local.z < 2.3 and absf(local.x) < 1.15 and absf(local.y) < 1.1:
			return index
	return -1

func prompt(index: int) -> String:
	if seated(index):
		return "Read the restored " + SEALS[index] + " Seal"
	if not game.guardians.collected(index):
		return "Inspect the " + SEALS[index] + " socket"
	return FACES[index]

func interact(index: int) -> void:
	if seated(index):
		_message(FINDINGS[index])
		return
	if not game.guardians.collected(index):
		if not game.guardians.revealed():
			_message("These sockets are empty. Inspect the broken seal at the center of Tideseal Ruins.")
			return
		var guardian: Dictionary = game.CHAPTER_GUARDIANS.GUARDIANS[index]
		_message("The %s socket matches Fragment %d. The %s holds it." % [SEALS[index], index+1, guardian.name])
		return
	game.world_data[STORE.TIDEWARDEN] = mask() | DISCOVERED | (1 << index)
	if complete() and game.tracked_quest in ["", "main", ID]:
		game.set_tracked_quest("main" if game.lantern_lit else game.CHAPTER_GUARDIANS.LANTERN)
	_animate_insert(index)
	_play(index, inserts[index].global_position)
	var saved: bool = game._save_progress()
	_message(FINDINGS[index] if saved else "Seal restored. Save pending.")
	if complete():
		_awaken()
	game._redraw_tracking()

func objective() -> Dictionary:
	var description := "The Tidewardens channelled the Northern Lantern through three sockets. Match each guardian fragment to its carving. Attunement leaves the fragments in your inventory."
	for index in 3:
		var state := "Restored" if seated(index) else "Fragment ready" if game.guardians.collected(index) else "Fragment missing"
		description += "\n%s Seal · %s" % [SEALS[index], state]
	return {
		"title":TITLE, "description":description, "objective":"Seal mechanisms", "value":count(), "total":3,
		"reward":"Reveal the ward's path to the eastern cave.",
		"next": next_step(), "done":complete(),
	}

func next_step() -> String:
	if complete():
		if game.grove.stage() == 3:
			return "The ward is lit. Follow the tracks from Ancient Grove to the eastern cave."
		return "Search the riverbank at Ancient Grove." if game.lantern_lit else "Light the Northern Lantern, then follow the ward's trail."
	if not nearby():
		return "Return to the standing stones south of Western Forest, at Tideseal Ruins."
	for index in 3:
		if not seated(index) and game.guardians.collected(index):
			return "Match Fragment %d to the %s socket." % [index+1, SEALS[index]]
	return "Read the sockets and recover the missing guardian fragments."

func _process(delta: float) -> void:
	notice_time = maxf(0, notice_time - delta)
	if not discovered() and game.started and not game.game_finished and nearby():
		game.world_data[STORE.TIDEWARDEN] = mask() | DISCOVERED
		_message("Three broken wards turn toward a silent beacon. Look for the fragment sockets.")
		game._save_progress()
		game._redraw_tracking()

func restore_visuals() -> void:
	for index in inserts.size():
		inserts[index].visible = seated(index)
		grooves[index].emission_energy_multiplier = .9 if seated(index) else .07
	beacon_light.emission_energy_multiplier = 1.7 if complete() else .025

func _message(line: String) -> void:
	notice = line
	notice_time = 5.0

func _world_center() -> Vector3:
	return beacon.global_position - Vector3.UP*1.76

func _animate_insert(index: int) -> void:
	var insert := inserts[index]
	var seat := insert.position
	var angle := insert.rotation
	insert.show()
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	match index:
		0:
			insert.position += Vector3(0,.32,.27)
			tween.tween_property(insert, "position", seat, .45)
		1:
			insert.rotate_z(PI*.5)
			tween.tween_property(insert, "rotation", angle, .57)
		2:
			insert.scale = Vector3.ONE*.25
			tween.tween_property(insert,"scale",Vector3.ONE,.48)
	tween.tween_property(grooves[index], "emission_energy_multiplier", 2.15, .32)
	tween.chain().tween_property(grooves[index], "emission_energy_multiplier", .9, .44)

func _awaken() -> void:
	lighting = create_tween().set_trans(Tween.TRANS_SINE)
	lighting.tween_interval(.65)
	for index in pillars.size():
		lighting.tween_callback(func(): _play(index, pillars[index].global_position))
		lighting.tween_property(grooves[index], "emission_energy_multiplier", 2.4, .12)
		lighting.tween_interval(.36)
		lighting.tween_property(grooves[index], "emission_energy_multiplier", .9, .13)
	lighting.tween_callback(func():
		_play(1, beacon.global_position, .62)
		_message("The beacon answers. The ward once guarded the eastern cave. " + next_step()))
	lighting.tween_property(beacon_light, "emission_energy_multiplier", 3.2, .36)
	lighting.tween_property(beacon_light, "emission_energy_multiplier", 1.7, .5)
	lighting.tween_callback(beacon_awakened.emit)

func _play(index: int, point: Vector3, pitch := 1.0) -> void:
	sound.stop()
	sound.global_position = point
	sound.stream = GROVE.CUES[index]
	sound.pitch_scale = pitch
	sound.play()

func _forest_pillars(scenery: Node3D) -> Array[Node3D]:
	var originals: Array[Node3D] = []
	for site in SITES:
		for child in scenery.get_children():
			# Fallen cylinders are meshes, whereas standing stones own their blockers.
			if not child is Node3D or child is MeshInstance3D:
				continue
			var offset: Vector3 = child.global_position - site
			if Vector2(offset.x,offset.z).length_squared() < .01:
				originals.append(child)
				break
	return originals

func _build_pillar(pillar: Node3D, index: int) -> void:
	# Keep the original post, cap and collider. Orient its socket into the court.
	pillar.reparent(self)
	pillar.name = SEALS[index] + "SealPillar"
	pillar.global_position = _ground(SITES[index])
	var inward: Vector3 = (CENTER - SITES[index]).normalized()
	pillar.rotation.y = atan2(inward.x, inward.z)
	var glow := _inlay(TINTS[index])
	grooves.append(glow)
	var socket_height := 1.01 if index == 0 else 1.15
	_piece(pillar, _lozenge(.43,.57,.085,.0), Vector3(0,socket_height,.47), stone)
	_piece(pillar, _lozenge(.27,.36,0,.0), Vector3(0,socket_height,.522), seam)
	_piece(pillar, _lozenge(.32,.414,.026,.0), Vector3(0,socket_height,.532), glow)
	inserts.append(_piece(pillar,_lozenge(.214,.294,0,.0),Vector3(0,socket_height,.552),glow))
	for step in index+1:
		var accent := _lozenge(.063,.042 + step*.011,0,.0)
		_piece(pillar, accent, Vector3((step - index*.5)*.17,socket_height+.64,.46), glow)
	pillars.append(pillar)

func _build_beacon() -> void:
	var center := _ground(CENTER)
	var pedestal := StaticBody3D.new()
	pedestal.name = "TidewardenBeacon"
	pedestal.collision_layer = 4 | 8
	pedestal.collision_mask = 0
	add_child(pedestal)
	pedestal.position = center
	for tier in 3:
		var step := CylinderMesh.new()
		step.radial_segments = 8
		step.top_radius = 1.12-tier*.19
		step.bottom_radius = step.top_radius + .08
		step.height = .24
		_piece(pedestal,step,Vector3.UP*(.12+tier*.22),stone if tier % 2 == 0 else trim)
	var collider := CollisionShape3D.new()
	var foot := CylinderShape3D.new()
	foot.radius = 1.18
	foot.height = .72
	collider.position.y = .34
	collider.shape = foot
	pedestal.add_child(collider)
	var arch := TorusMesh.new()
	arch.inner_radius = .61
	arch.outer_radius = .91
	arch.rings = 16
	arch.ring_segments = 8
	var halo := _piece(pedestal,arch,Vector3(0,1.76,0),stone)
	halo.rotation.x = PI*.5
	beacon_light = _inlay(Color("edc47e"))
	beacon = _piece(pedestal,_lozenge(.32,.59,.032,0),Vector3(0,1.76,.12),beacon_light)
	_piece(pedestal,_lozenge(.42,.69,.056,0),Vector3(0,1.76,-.035),trim)
	for angle in [0.0, TAU*.25, TAU*.5, TAU*.75]:
		var engraving := _piece(pedestal,_lozenge(.075,.15,.016,0),
			Vector3(sin(angle)*.78,1.76+cos(angle)*.78,.15),beacon_light)
		engraving.rotation.z = -angle

func _build_court() -> void:
	# Broken radial pavers follow the existing slope. Their height stays within the turf.
	var bed := SurfaceTool.new()
	bed.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 214
	for index in 28:
		if index in [1,7,13,21]:
			continue
		var from := float(index)*TAU/28.0
		var to := (index+.84)*TAU/28.0
		var inner := rng.randf_range(2.55,2.96)
		var outer := rng.randf_range(3.35,3.78)
		for span in 3:
			var a := lerpf(from,to,span/3.0)
			var b := lerpf(from,to,(span+1)/3.0)
			_paving_quad(bed,a,b,inner,outer)
	bed.generate_normals()
	_piece(self,bed.commit(),Vector3.ZERO,trim).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for index in 10:
		var angle := index*TAU/10.0
		if index in [2,3,4]:
			continue
		var at := _ground(CENTER+Vector3(cos(angle)*4.52,0,sin(angle)*4.23))
		var rubble := BoxMesh.new()
		rubble.size = Vector3(rng.randf_range(.45,.95),rng.randf_range(.2,.42),rng.randf_range(.32,.7))
		var chip := _piece(self,rubble,at+Vector3.UP*.07,moss if index%2 == 0 else stone)
		chip.rotation = Vector3(.13,angle+.44,-.24)
		if index%2 == 0:
			var fern := preload("res://assets/environment/fern_02_mobile.scn").instantiate() as Node3D
			add_child(fern)
			fern.position = at + Vector3(.16,-.03,.12)
			fern.rotation.y = angle
			fern.scale *= .66

func _paving_quad(surface: SurfaceTool, a: float, b: float, inner: float, outer: float) -> void:
	var ring := [Vector3(cos(a)*inner,0,sin(a)*inner), Vector3(cos(a)*outer,0,sin(a)*outer),
		Vector3(cos(b)*inner,0,sin(b)*inner), Vector3(cos(b)*outer,0,sin(b)*outer)]
	for i in [0,1,2,1,3,2]:
		surface.add_vertex(_ground(CENTER+ring[i])+Vector3.UP*.034)

func _ground(point: Vector3) -> Vector3:
	return game.landscape.ground_point(point)

func _inlay(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.darkened(.59)
	mat.emission_enabled = true
	mat.emission = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _piece(parent: Node3D, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.material_override = mat
	part.visibility_range_end = 85.0
	parent.add_child(part)
	return part

func _lozenge(width: float, height: float, border: float, z: float) -> ArrayMesh:
	var shape := SurfaceTool.new()
	shape.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector3(0,height,z), Vector3(width,0,z), Vector3(0,-height,z), Vector3(-width,0,z)]
	for i in corners.size():
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i+1)%4]
		var inner := Vector3(a.x * (1.0-border/width), a.y * (1.0-border/height), z-.028)
		var next := Vector3(b.x * (1.0-border/width), b.y * (1.0-border/height), z-.028)
		var vertices := [a,b,Vector3.ZERO] if border == 0.0 else [a,b,next,a,next,inner]
		for point in vertices:
			shape.add_vertex(point)
	shape.generate_normals()
	return shape.commit()
