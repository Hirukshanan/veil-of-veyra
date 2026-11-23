extends "res://scripts/bear_audio_review.gd"

const Investigation := preload("res://scripts/grove_investigation.gd")
var grove: Investigation

func _init() -> void:
	guardians = preload("res://scripts/grove_investigation_quest.gd").new(self)

func _create_grove() -> Investigation:
	return Investigation.new()

func _ready() -> void:
	await super._ready()
	grove = _create_grove()
	grove.name = "GroveInvestigation"
	add_child(grove)
	grove.populate(self)
	grove.refresh(false)

func _interact_lantern() -> void:
	var lit_before := lantern_lit
	super._interact_lantern()
	if lantern_lit and not lit_before and grove:
		set_tracked_quest("main")
		grove.refresh(true)

func _update_objective() -> void:
	super._update_objective()
	if grove and _can_investigate_grove():
		interact_button.accessibility_name = Investigation.PROMPTS[grove.stage()]

func awakening_quest() -> Dictionary:
	var row := super.awakening_quest()
	if not completed and not world_data.get(CHAPTER_GUARDIANS.GROVE_FLAG, false):
		row.objective = "Locked · Identify the keeper of the seal"
		row.next = "Read the evidence left on the riverbank."
	return row

func tracked_hint(base: Dictionary) -> Dictionary:
	if grove and lantern_lit and not completed and tracked_quest in ["", "main"] and not _sanctum_open():
		return guardians.hud("main")
	return super.tracked_hint(base)
