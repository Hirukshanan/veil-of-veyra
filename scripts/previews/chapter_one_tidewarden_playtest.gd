extends "res://scripts/previews/chapter_one_shore_playtest.gd"

const Tidewarden := preload("res://scripts/tidewarden_shrine.gd")
var tidewarden: Tidewarden

func _ready() -> void:
	await super._ready()
	tidewarden = _create_tidewarden()
	add_child(tidewarden)
	tidewarden.populate(self)
	if tidewarden.complete() and tracked_quest == Tidewarden.ID:
		set_tracked_quest("main")
	_redraw_tracking()

func _create_tidewarden() -> Tidewarden:
	return Tidewarden.new()

func _load_tracking() -> void:
	super._load_tracking()
	if tracked_quest.is_empty():
		var preference := ConfigFile.new()
		if preference.load(TRACKING_PATH) == OK and preference.get_value("journal","tracked","") == Tidewarden.ID:
			tracked_quest = Tidewarden.ID

func _update_objective() -> void:
	super._update_objective()
	if not is_instance_valid(tidewarden):
		return
	var index := tidewarden.use_index()
	if index >= 0:
		interact_button.visible = true
		interact_button.disabled = false
		interact_button.icon = preload("res://assets/ui/controls/collect.svg")
		interact_button.accessibility_name = tidewarden.prompt(index)

func _interact_world() -> void:
	if is_instance_valid(tidewarden):
		var index := tidewarden.use_index()
		if index >= 0:
			tidewarden.interact(index)
			_update_objective()
			return
	super._interact_world()

func guardian_journal_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(super.guardian_journal_ids())
	if is_instance_valid(tidewarden) and tidewarden.available():
		ids.append(Tidewarden.ID)
	return ids

func guardian_journal(id: String) -> Dictionary:
	if is_instance_valid(tidewarden) and id == Tidewarden.ID and tidewarden.available():
		return tidewarden.objective()
	var row := super.guardian_journal(id)
	if is_instance_valid(tidewarden) and id == "main" and tidewarden.guides_main() and not row.is_empty():
		row.next = "The Tidewarden Shrine by Western Forest can reveal how the ward reaches the eastern cave."
	return row

func tracked_hint(base: Dictionary) -> Dictionary:
	if is_instance_valid(tidewarden) and not shrine.in_cell:
		var contextual := tidewarden.nearby() and tracked_quest in ["", "main"]
		var tracked := tracked_quest == Tidewarden.ID or (tracked_quest in ["", "main"] and tidewarden.guides_main())
		if (tidewarden.notice_time > 0 and tidewarden.nearby()) or (not tidewarden.complete() and (tracked or contextual)):
			var line := tidewarden.next_step()
			if tidewarden.notice_time > 0 and tidewarden.nearby():
				line = tidewarden.notice
			return {"title": Tidewarden.TITLE.to_upper(), "progress": "Seals restored %d/3" % tidewarden.count(),
				"message": line}
	return super.tracked_hint(base)

func guardian_map_markers() -> Array[Dictionary]:
	var pins: Array[Dictionary] = []
	pins.assign(super.guardian_map_markers())
	if not is_instance_valid(tidewarden) or not tidewarden.available() or tidewarden.complete():
		return pins
	var guided := tracked_quest in ["", "main"] and tidewarden.guides_main()
	if guided:
		for index in range(pins.size()-1, -1, -1):
			if pins[index].id == "main":
				pins.remove_at(index)
	pins.append({"id":Tidewarden.ID, "badge":"S", "point":Tidewarden.CENTER,
		"radius":0.0 if tidewarden.discovered() else 7.0, "color":Color("e0b87f"),
		"label":"Tidewarden Shrine", "tracked":tracked_quest == Tidewarden.ID or guided})
	return pins
