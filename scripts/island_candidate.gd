extends "res://scripts/campaign.gd"

const FOX_ENCOUNTER := preload("res://scenes/enemies/demon_fox_combat.tscn")
const CHAPTER_OPENING := preload("res://scripts/chapter_opening.gd")
const CHAPTER_GUARDIANS := preload("res://scripts/chapter_guardians.gd")

var awakening: Node3D
var opening: Node3D
var guardians := CHAPTER_GUARDIANS.new(self)
var _region_check := 0.0
var landscape: Node3D
var placement_ready := false
var placement_log: Array[Dictionary] = []
var encounter_log: Array[Dictionary] = []
var enemy_navigation: Node3D

func _restore_world() -> void:
	guardians.restore()
	super._restore_world()
	# The legacy restore samples the old height function; validate this saved point
	# against the new collision instead, including a legitimate cave floor.
	player.global_position = world_data.position

func _uses_guardian_seal() -> bool:
	return true

func _build_island() -> void:
	landscape = preload("res://scripts/island_landscape.gd").new()
	add_child(landscape)

func _build_decor() -> void:
	pass

func _create_exploration() -> Node3D:
	return preload("res://scripts/island_candidate_exploration.gd").new()

func _ready() -> void:
	_load_tracking()
	super._ready()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_ground_gameplay()
	landscape.populate_ground_detail()
	var atmosphere := preload("res://scripts/island_atmosphere.gd").new()
	atmosphere.name = "IslandAtmosphere"
	add_child(atmosphere)
	atmosphere.populate(self)
	# Synchronize newly instanced trunk shapes before sampling navigation clearance.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_configure_encounters()
	awakening = preload("res://scripts/lantern_awakening.gd").new()
	awakening.game = self
	add_child(awakening)
	opening = CHAPTER_OPENING.new()
	opening.name = "ChapterOpening"
	opening.game = self
	add_child(opening)
	placement_ready = true
	guardians.refresh_tracking(true)

func _physics_process(delta: float) -> void:
	if not placement_ready or not started or game_finished or player.health <= 0:
		return
	_region_check -= delta
	if _region_check <= 0.0:
		_region_check = .25
		if guardians.discover_regions():
			_save_progress()
			_redraw_tracking()

func _ground_node(node: Node3D, safe := false) -> void:
	var before := node.global_position
	node.global_position = landscape.safe_point(before) if safe else landscape.ground_point(before)
	placement_log.append({"node":str(node.name),"before":before,"after":node.global_position})

func _ground_gameplay() -> void:
	for enemy in get_tree().get_nodes_in_group("combat_enemies"):
		_ground_node(enemy,true)
		if "_home" in enemy:
			enemy._home = enemy.global_position
			enemy._patrol_goal = enemy.global_position
	_ground_node(lantern,true)
	for item in herbs.plants:_ground_node(item,true)
	for item in seal_fragments.fragments:_ground_node(item,true)
	for item in relic_hunt.relics:
		if int(item.get_meta("pickup_id")) == 1:item.global_position=Vector3(76,1.58,5)
		else:_ground_node(item,true)
	# Keep the original quest scenery and NPC; only its support height changes.
	_ground_node(seal_fragments.get_node("Scenery"))
	# Western Watch is a journal-only Node, not a physical NPC.
	var exploration = get_node("IslandExploration")
	for index in range(3):
		var point: Vector3 = landscape.safe_point(exploration.CHECKPOINTS[index])
		exploration.grounded_checkpoints.append(point)
		exploration.get_node("Waystone%d"%index).global_position = point
		exploration._waystone_labels[index].global_position = point+Vector3.UP*2
	if exploration.checkpoint_index >= 0:player.rescue_position = exploration.checkpoint_position(exploration.checkpoint_index)+Vector3.UP
	else:player.rescue_position = exploration.checkpoint_position(0)+Vector3.UP
	# All original save IDs/equipment/health are preserved; relocate only unsafe support.
	player.global_position = landscape.supported_saved_point(player.global_position)
	player.velocity = Vector3.ZERO
	player._camera_pivot.global_position = player.global_position+Vector3.UP*1.2

func _spawn_boss() -> void:
	super._spawn_boss()
	var dragon := get_node_or_null("Tidewraith Dragon")
	if dragon != null:dragon.position.y = landscape.height_at(Vector2(dragon.position.x,dragon.position.z))

func _configure_encounters() -> void:
	# Preserve spawn IDs, species, rewards and save flags; move only existing actors.
	# Do this after accepted vegetation generation so no foliage placement changes.
	var positions:={"CampDemon0":Vector3(-72,0,4),"CampDemon1":Vector3(-52,0,4),"CampDemon2":Vector3(-40,0,-28),"CampDemon3":Vector3(-64,0,-24),"CampDemon4":Vector3(-68,0,28),"DemonBoar":Vector3(-36,0,12)}
	for actor in get_tree().get_nodes_in_group("combat_enemies"):
		if not positions.has(str(actor.name)):continue
		var before:Vector3=actor.position
		actor.position=landscape.ground_point(positions[str(actor.name)])+Vector3.UP*.08
		actor.velocity=Vector3.ZERO;actor._home=actor.position;actor._patrol_goal=actor.position
		if actor.name == "DemonBoar":
			actor.enable_elite()
		encounter_log.append({"id":str(actor.name),"before":before,"after":actor.position,"health":actor.health})
	# Bind the existing bounty to its western wolves after candidate placement.
	keeper.target_enemy_ids.assign(["CampDemon0", "CampDemon1"])
	enemy_navigation=preload("res://scripts/island_enemy_navigation.gd").new()
	enemy_navigation.name="CandidateEnemyNavigation";add_child(enemy_navigation)
	enemy_navigation.populate(landscape)
	for actor in get_tree().get_nodes_in_group("combat_enemies"):
		if positions.has(str(actor.name)):actor.navigation=enemy_navigation
	_spawn_fox()

func _spawn_fox() -> void:
	if guardians.fox_defeated():
		return
	var marker: Marker3D = $DemonFoxSpawn
	var fox := FOX_ENCOUNTER.instantiate() as CharacterBody3D
	fox.position = landscape.ground_point(marker.position) + Vector3.UP * .015
	fox.rotation = marker.rotation
	fox.target = player
	fox.navigation = enemy_navigation
	fox.defeated.connect(_defeat_fox)
	add_child(fox)

func _defeat_world_enemy(index: int) -> void:
	if index == CHAPTER_GUARDIANS.WARG_INDEX and index not in world_data.cleared:
		guardians.recover(0)
	super._defeat_world_enemy(index)
	_redraw_tracking()

func _defeat_fox() -> void:
	if not guardians.fox_defeated():
		guardians.recover(1)
		_save_progress()
		_update_objective()
		_redraw_tracking()

func _defeat_boar() -> void:
	if not world_data.get("boar_defeated", false):
		guardians.recover(2)
	super._defeat_boar()
	_update_objective()
	_redraw_tracking()

func _interact_lantern() -> void:
	var was_lit := lantern_lit
	super._interact_lantern()
	if lantern_lit and not was_lit:
		guardians.refresh_tracking(false)
		_redraw_tracking()

var tracked_quest := ""
const TRACKING_PATH := "user://journal_tracking.cfg"

func set_tracked_quest(id:String):
	if (id == CHAPTER_GUARDIANS.LANTERN or guardians.index_for(id) >= 0) and not guardians.can_track(id):
		return
	if tracked_quest == id:
		return
	_refresh_quest_feedback()
	tracked_quest=id
	quest_feedback.clear()
	var preference:=ConfigFile.new()
	preference.set_value("journal","tracked",id)
	preference.save(TRACKING_PATH)
	_redraw_tracking()

func _load_tracking():
	var preference:=ConfigFile.new()
	if FileAccess.file_exists(TRACKING_PATH) and preference.load(TRACKING_PATH)==OK:
		var saved=preference.get_value("journal","tracked","")
		if saved is String and (saved in ["main","watch","grove","relic","awakening",CHAPTER_GUARDIANS.LANTERN]
				or guardians.index_for(saved) >= 0):
			tracked_quest = saved

var journal_view: Control

func _show_journal() -> void:
	if is_instance_valid(awakening) and awakening.active:
		return
	if not started or game_finished or (get_tree().paused and not pause_menu_open):
		return
	var group := "Main"
	var id := tracked_quest
	if is_instance_valid(journal_view):
		group = journal_view.section
		id = journal_view.selected
	elif id in ["watch","grove","relic"]:
		group = "Side"
	_clear_menu("Quest Journal","")
	journal_open=true
	pause_menu_open=true
	menu_scroll.hide()
	journal_view=preload("res://scripts/candidate_journal.gd").new()
	journal_view.game=self
	journal_view.section=group
	journal_view.selected=id
	menu_scroll.get_parent().add_child(journal_view)

func _dismiss_journal():
	if is_instance_valid(journal_view):
		journal_view.hide()
		journal_view.queue_free()
		journal_view=null

func _clear_menu(title:String,message:String,save_world:=true) -> void:
	_dismiss_journal()
	super._clear_menu(title,message,save_world)

func _resume() -> void:
	if is_instance_valid(awakening) and awakening.active:
		return
	_dismiss_journal()
	super._resume()

func _close_journal_animated() -> void:
	if is_instance_valid(journal_view):
		journal_view.close(_resume)

func _toggle_journal() -> void:
	if is_instance_valid(awakening) and awakening.active:
		return
	if journal_open:
		_close_journal_animated()
	else:
		super._toggle_journal()

func _toggle_pause() -> void:
	if is_instance_valid(awakening) and awakening.active:
		awakening.skip()
		return
	if journal_open:
		_close_journal_animated()
	else:
		super._toggle_pause()

func tracked_hint(base:Dictionary) -> Dictionary:
	if is_instance_valid(awakening) and completed and tracked_quest in ["", "main"] and not awakening.finished():
		var objective:Dictionary=awakening.quest()
		return {"title":objective.title.to_upper(),"message":objective.next,"progress":"Seal recovered · Cave relic recorded"}
	if placement_ready:
		var target: Dictionary = guardians.hud(tracked_quest)
		if not target.is_empty():
			if tracked_quest != CHAPTER_GUARDIANS.LANTERN and not opening.active_message().is_empty():
				target.message = opening.active_message()
			return target
	if is_instance_valid(opening) and tracked_quest in ["", "main"]:
		var hint: Dictionary = opening.hud_hint()
		if not hint.is_empty():
			return hint
	if tracked_quest=="" or not _world_ready or Time.get_ticks_msec()<quest_feedback.get("until",0):
		return base
	var q:=preload("res://scripts/candidate_journal.gd").entry(self,tracked_quest)
	if tracked_quest=="main":
		var current:=CHAPTER_QUESTS.current(self)
		return {"title":current.title,"message":current.message,"progress":q.objective}
	if q.done: return base
	return {"title":q.title.to_upper(),"message":q.next,"progress":"%s  %d/%d" % [q.objective,q.value,q.total]}

func _pause_game() -> void:
	if is_instance_valid(awakening) and awakening.active:
		return
	super._pause_game()

func awakening_quest() -> Dictionary:
	return awakening.quest()

func opening_journal() -> Dictionary:
	if not is_instance_valid(opening):
		return {}
	var goal: Dictionary = opening.objective()
	if opening.has_beat(CHAPTER_OPENING.CAMP):
		goal["finding"] = CHAPTER_OPENING.CAMP_FINDING
	return goal

func guardian_journal(id: String) -> Dictionary:
	if not placement_ready:
		return {}
	var row: Dictionary = guardians.journal(id)
	if id == "main" and not row.is_empty() and opening.has_beat(CHAPTER_OPENING.CAMP):
		row["finding"] = CHAPTER_OPENING.CAMP_FINDING
	return row

func guardian_journal_ids() -> Array[String]:
	return guardians.ids() if placement_ready else []

func guardian_map_markers() -> Array[Dictionary]:
	return guardians.markers() if placement_ready else []

func hide_enemy_map_dot(enemy: Node) -> bool:
	for guardian in CHAPTER_GUARDIANS.GUARDIANS:
		if enemy.name == guardian.actor:
			return true
	return false

func show_ruins_map_marker() -> bool:
	return placement_ready and not guardians.revealed()

func _redraw_tracking() -> void:
	if is_instance_valid(mobile_hud) and is_instance_valid(mobile_hud.chrome):
		mobile_hud.chrome.refresh_guidance()

func _show_camp() -> void:
	super._show_camp()
	if not lantern_lit and not completed:
		camp_menu._art_heading.text = "THE THREE CURSED GUARDIANS" if guardians.revealed() else "THE LANTERN'S SEAL"
		camp_menu._art_caption.text = "The three fragments restore the Northern Lantern." if guardians.revealed() else (
			"The inland camps have gone quiet.\nFollow the ash inland.")

func _update_objective() -> void:
	super._update_objective()
	if is_instance_valid(awakening) and not awakening.active and not awakening.finished() and awakening.eligible() and awakening.near_pedestal():
		interact_button.visible=true
		interact_button.disabled=false
		interact_button.icon=preload("res://assets/ui/controls/lantern.svg")
		interact_button.accessibility_name="Interact · Place lantern"
	elif _can_investigate_seal():
		interact_button.visible = true
		interact_button.disabled = false
		interact_button.icon = preload("res://assets/ui/controls/collect.svg")
		interact_button.accessibility_name = "Investigate broken seal"
	elif _can_inspect_camp():
		interact_button.visible = true
		interact_button.disabled = false
		interact_button.icon = preload("res://assets/ui/controls/collect.svg")
		interact_button.accessibility_name = "Inspect abandoned camp"

func _interact_world() -> void:
	if not started or game_finished or get_tree().paused or player.health <= 0:
		return
	if is_instance_valid(awakening) and awakening.eligible() and awakening.near_pedestal() and not awakening.finished():
		awakening.start()
		return
	if _can_investigate_seal():
		guardians.investigate()
		_update_objective()
		_redraw_tracking()
		return
	if _can_inspect_camp():
		opening.inspect_camp()
		_update_objective()
		return
	super._interact_world()

func _can_investigate_seal() -> bool:
	return placement_ready and started and not game_finished and not get_tree().paused and player.health > 0 and guardians.can_investigate()

func _can_inspect_camp() -> bool:
	if not is_instance_valid(opening) or not opening.can_inspect():
		return false
	var position: Vector3 = player.global_position
	return seal_fragments.nearest(position) == null and herbs.nearest(position) == null
