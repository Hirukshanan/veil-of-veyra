extends "res://scripts/chapter_guardians.gd"

const Investigation := preload("res://scripts/grove_investigation.gd")

func can_investigate_grove() -> bool:
	return grove_pending() and game.grove != null and game.grove.in_reach()

func investigate_grove() -> void:
	if can_investigate_grove():
		game.grove.investigate()

func grove_objective() -> Dictionary:
	if not game.grove or game.world_data.get(BEAR_FLAG, false):
		return super.grove_objective()
	var n: int = game.grove.stage()
	var record := "The Lantern's light has slipped into the soil."
	for i in n:
		record += "\n" + Investigation.FINDINGS[i]
	var row: Dictionary
	if n == 3:
		row = super.grove_objective()
		row.description = record
		row.next = "Follow the enormous tracks to the eastern cave."
		row.objective = "Clues 3/3 · Enter the eastern cave"
		if game.shrine.in_cell:
			row.next = "Descend the ruined steps into the guardian's hall."
			row.objective = "Confront the Cursed Bear"
		elif game.player.position.distance_to(Investigation.CAVE_MOUTH) < 12.0:
			row.next = "Follow the cave's curved passage to the hidden steps."
	else:
		row = _row("Investigate Ancient Grove", record, "Evidence %d/3" % n, n, 3,
			"Find what the Lantern once sealed.", Investigation.HINTS[n], false)
	return row

func hud(id: String) -> Dictionary:
	if not game.grove or not game.lantern_lit or game.completed or game._sanctum_open() or id not in ["", "main"]:
		return super.hud(id)
	var row := grove_objective()
	var message: String = row.next
	if game.grove.notice_time > 0:
		message = game.grove.notice
	elif can_investigate_grove():
		message = Investigation.PROMPTS[game.grove.stage()]
	return {"title": row.title.to_upper(), "progress": row.objective, "message": message}

func markers() -> Array[Dictionary]:
	var pins := super.markers()
	if not game.grove or not game.lantern_lit or game.completed or game._sanctum_open():
		return pins
	for i in range(pins.size()-1, -1, -1):
		if pins[i].id == "main":
			pins.remove_at(i)
	var n: int = game.grove.stage()
	if n == 3 and game.shrine.in_cell:
		return pins
	var search: Vector3 = Investigation.SEARCH[n] if n < 3 else Investigation.CAVE_MOUTH
	pins.append({"id":"main", "point":search, "badge":"?" if n < 3 else "C",
		"radius":[9.0, 7.0, 5.0, 0.0][n], "color":Color("f2c27d"), "tracked":game.tracked_quest in ["","main"]})
	return pins
