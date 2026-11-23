extends "res://scripts/tidewarden_shrine.gd"

const STONEWORK := preload("res://scripts/previews/tidewarden_stonework.gd")
const FERN := preload("res://assets/environment/fern_02_mobile.scn")

var masonry := STONEWORK.new()

func populate(island) -> void:
	super.populate(island)
	if is_queued_for_deletion():
		return
	# The first three posts have already been adopted by the shrine. The six
	# unadopted uprights and fallen pieces were decorative remnants of the old set.
	var scenery: Node3D = game.seal_fragments.get_node("Scenery")
	for remnant in scenery.get_children():
		remnant.queue_free()
	for label in game.seal_fragments.find_children("*","Label3D",false,false):
		label.queue_free()
	if not game.guardians.revealed():
		var seal := _build_broken_seal(scenery.global_position)
		game.opening.broken_seal_read.connect(seal.queue_free, CONNECT_ONE_SHOT)

func _build_pillar(pillar: Node3D, index: int) -> void:
	pillar.reparent(self)
	pillar.name = SEALS[index] + "SealPillar"
	pillar.global_position = _ground(SITES[index])
	var inward: Vector3 = (CENTER-SITES[index]).normalized()
	pillar.rotation.y = atan2(inward.x,inward.z)
	for retired in pillar.get_children():
		retired.free()
	var detail := masonry.build_pillar(pillar,index)
	pillars.append(pillar)
	inserts.append(detail.insert)
	grooves.append(detail.glow)

func _build_beacon() -> void:
	var facing := Vector3(.89,0,.46)
	var detail := masonry.build_beacon(self,_ground(CENTER),atan2(facing.x,facing.z))
	beacon = detail.mesh
	beacon_light = detail.light

func _build_court() -> void:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Eleven fitted stones define one court, with open joints for moss and roots.
	for index in 11:
		var a := TAU*index/11.0
		var b := a+TAU*.954/11.0
		_stone_tile(s,[CENTER+Vector3(cos(a),0,sin(a))*1.09,
			CENTER+Vector3(cos(a),0,sin(a))*2.32,
			CENTER+Vector3(cos(b),0,sin(b))*2.32,
			CENTER+Vector3(cos(b),0,sin(b))*1.09])
	s.generate_normals()
	var court := _piece(self,s.commit(),Vector3.ZERO,
		preload("res://scripts/environment_materials.gd").surface("rocky_terrain_02",.61,Color("acaa91")))
	court.name = "FittedStoneCourt"
	court.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for offset in [Vector3(-2.32,0,-1.15),Vector3(-2.2,0,1.38),Vector3(1.45,0,-2.05)]:
		var fern := FERN.instantiate() as Node3D
		add_child(fern)
		fern.position = _ground(CENTER+offset)
		fern.scale *= .53

func _build_broken_seal(point: Vector3) -> MeshInstance3D:
	# Keep a physical visual cue over the unchanged story interaction anchor.
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shape := [Vector3(-.68,0,-.34),Vector3(.68,0,-.34),
		Vector3(.74,0,.35),Vector3(-.61,0,.41)]
	var floor := _ground(point)
	for half in [-.40,.40]:
		var ring: Array[Vector3] = []
		for offset: Vector3 in shape:
			ring.append(floor+Vector3(half+offset.x*.52,0,offset.z))
		_stone_tile(s,ring)
	s.generate_normals()
	var marker := _piece(self,s.commit(),Vector3.ZERO,trim)
	marker.name = "InlaidBrokenSeal"
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return marker

func _stone_tile(s: SurfaceTool, outline: Array) -> void:
	var middle := Vector3.ZERO
	for p: Vector3 in outline:
		middle += p
	middle = _ground(middle/float(outline.size()))+Vector3.UP*.051
	for index in outline.size():
		var a := _ground(outline[index])+Vector3.UP*.038
		var b := _ground(outline[(index+1)%outline.size()])+Vector3.UP*.038
		for corner in [middle,a,b]:
			s.add_vertex(corner)
