extends "res://scripts/previews/chapter_one_tidewarden_visual_review.gd"

const SPOOR := preload("res://scripts/previews/spoor_shrine.gd")
const BANK := preload("res://scripts/previews/spoor_grove.gd")

func _create_tidewarden() -> Tidewarden:
	return SPOOR.new()

func _create_grove() -> Investigation:
	return BANK.new()

func _build_lantern() -> void:
	# The existing Chapter I light interaction now belongs to the shrine beacon.
	lantern = Marker3D.new()
	lantern.name = "BeaconLanternAnchor"
	lantern.position = Tidewarden.CENTER
	add_child(lantern)
	_bind_keys(&"interact",[KEY_E])

func _ground_gameplay() -> void:
	super._ground_gameplay()
	lantern.global_position = landscape.ground_point(Tidewarden.CENTER)
	# The gold shape behind the lamp was a real relic. Keep its pickup ID and
	# collection radius, seated in the earth beyond the Grove carving.
	for relic in relic_hunt.relics:
		if relic.get_meta("pickup_id") == 2:
			relic.global_position = landscape.ground_point(Vector3(2.0,0,-44.0))
			relic.set_meta("grounded_relic",true)
			relic.get_child(1).free()
			var gem := relic.get_child(0) as MeshInstance3D
			gem.position.y = .21
			gem.rotation = Vector3(.23,.6,.53)
			var brass := gem.material_override.duplicate() as StandardMaterial3D
			brass.emission_enabled = false
			brass.metallic = .38
			gem.material_override = brass

func _update_objective() -> void:
	super._update_objective()
	if is_instance_valid(tidewarden) and tidewarden.tree_in_reach():
		interact_button.visible = true
		interact_button.disabled = false
		interact_button.icon = preload("res://assets/ui/controls/collect.svg")
		interact_button.accessibility_name = SPOOR.PROMPT

func _interact_world() -> void:
	if is_instance_valid(tidewarden) and tidewarden.tree_in_reach():
		tidewarden.inspect_tree()
		_update_objective()
		return
	super._interact_world()

func _follow_tracks() -> bool:
	return is_instance_valid(tidewarden) and tidewarden.complete() and not tidewarden.read_claws() and grove and grove.stage()==0 and not completed and lantern_lit

func guardian_journal(id: String) -> Dictionary:
	var row := super.guardian_journal(id)
	if row.is_empty():
		return row
	if id == CHAPTER_GUARDIANS.LANTERN:
		row.description = "The forest shrine's beacon carries the Northern Lantern's flame. Bring the three guardian fragments to the beacon."
	if id == "main" and grove and lantern_lit and not completed:
		if world_data.get(SPOOR.READ,false):
			row.description = "Riverbank finding · " + SPOOR.FINDING + "\n" + row.description
		if _follow_tracks():
			row.next = tidewarden.next_step()
		elif grove.stage() < 3:
			row.next = ["Search the tangled roots on the west bank at Ancient Grove.","Trace the old seal on the broken bedrock beside the roots.","Read the heavy tracks on the lower bank."][grove.stage()]
	return row

func tracked_hint(base: Dictionary) -> Dictionary:
	var hud := super.tracked_hint(base)
	if is_instance_valid(tidewarden) and tidewarden.tree_in_reach():
		return {"title":"THE BEAST'S TRAIL","progress":"Riverside investigation","message":SPOOR.PROMPT}
	if grove and grove.notice_time > 0 and grove.notice == SPOOR.FINDING and not shrine.in_cell:
		return {"title":"CLUE RECORDED","progress":"The scarred river tree","message":grove.notice}
	if tracked_quest in ["","main"] and lantern_lit and grove and grove.stage()<3 and not shrine.in_cell and not (is_instance_valid(tidewarden) and tidewarden.guides_main()):
		var row := guardian_journal("main")
		if not row.is_empty() and grove.notice_time <= 0 and not _can_investigate_grove():
			hud.message = row.next
	return hud

func guardian_map_markers() -> Array[Dictionary]:
	var pins := super.guardian_map_markers()
	for pin in pins:
		if pin.id != "main":
			continue
		if _follow_tracks():
			pin.point = SPOOR.TREE
			pin.radius = 7.
		elif grove and grove.stage()==1:
			pin.point = BANK.INLAY
			pin.radius = 4.
	return pins
