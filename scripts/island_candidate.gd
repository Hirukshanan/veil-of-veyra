extends "res://scripts/campaign.gd"

const FOX_ENCOUNTER := preload("res://scenes/enemies/demon_fox_combat.tscn")
const CHAPTER_OPENING := preload("res://scripts/chapter_opening.gd")
const CHAPTER_GUARDIANS := preload("res://scripts/chapter_guardians.gd")

const BEAR_SCENE := "res://scenes/enemies/cursed_bear_boss.tscn"
const TEMPLE := preload("res://scripts/buried_temple.gd")
var temple: TEMPLE = _create_bear_temple()
var cave_bear: CharacterBody3D
var awakening: Node3D
var opening: Node3D
var guardians := CHAPTER_GUARDIANS.new(self)
var _region_check := 0.0
var landscape: Node3D
var placement_ready := false
var placement_log: Array[Dictionary] = []
var encounter_log: Array[Dictionary] = []
var enemy_navigation: Node3D

func _create_bear_temple() -> TEMPLE:
	return TEMPLE.new()

func _restore_world() -> void:
	guardians.restore()
	super._restore_world()
	# The legacy restore samples the old height function; validate this saved point
	# against the new collision instead, including a legitimate cave floor.
	player.global_position = world_data.position

func _uses_guardian_seal() -> bool:
	return true

func _lantern_spawns_boss() -> bool:
	return false

func _build_player() -> void:
	super._build_player()
	player.set_collision_mask_value(2, true)
	player.set_collision_mask_value(ENEMY_SCRIPT.BODY_LAYER, true)

func _build_island() -> void:
	landscape = preload("res://scripts/island_landscape.gd").new()
	add_child(landscape)

func _build_decor() -> void:
	pass

func _create_exploration() -> Node3D:
	return preload("res://scripts/island_candidate_exploration.gd").new()

func _create_awakening() -> Node3D:
	return preload("res://scripts/lantern_awakening.gd").new()

func _ready() -> void:
	awakening = _create_awakening()
	awakening.game = self
	_load_tracking()
	super._ready()
	await get_tree().physics_frame
	await get_tree().physics_frame
	add_child(temple)
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
	awakening.passage_opened.connect(_finish_bear_chapter)
	add_child(awakening)
	opening = CHAPTER_OPENING.new()
	opening.name = "ChapterOpening"
	opening.game = self
	add_child(opening)
	guardians.grove_point = landscape.ground_point(CHAPTER_GUARDIANS.GROVE_CENTER)
	var soundtrack := preload("res://scripts/chapter_island_music.gd").new()
	soundtrack.name = "ChapterIslandMusic"
	add_child(soundtrack)
	placement_ready = true
	guardians.refresh_tracking(true)

func _physics_process(delta: float) -> void:
	if not placement_ready or not started or game_finished or player.health <= 0:
		return
	_update_temple_thresholds()
	_region_check -= delta
	if _region_check <= 0.0:
		_region_check = .25
		_update_bear_encounter()
		if guardians.discover_regions():
			_save_progress()
			_redraw_tracking()

func _sanctum_open() -> bool:
	return completed or world_data.get(CHAPTER_GUARDIANS.BEAR_FLAG, false)

func _temple_unlocked() -> bool:
	return _sanctum_open() or (lantern_lit and world_data.get(CHAPTER_GUARDIANS.GROVE_FLAG, false))

func _cross_threshold(destination: Vector3) -> void:
	player.global_position = destination
	player.velocity = Vector3.ZERO
	player._camera_pivot.global_position = destination + Vector3.UP * 1.2
	player.reset_physics_interpolation()
	# Bridge the paired doorways with a brief dark threshold; controls stay live.
	var transition := CanvasLayer.new()
	transition.layer = 1
	add_child(transition)
	var shade := ColorRect.new()
	transition.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(.025,.021,.018,.95)
	var fade := transition.create_tween()
	fade.tween_property(shade,"color:a",0.0,.22)
	fade.tween_callback(transition.queue_free)

func _update_temple_thresholds() -> void:
	var p: Vector3 = player.position
	if is_instance_valid(temple.chamber):
		var retreat := p.z < -22.7
		var sanctum := p.z > 22.4 and _sanctum_open()
		if not retreat and not sanctum and TEMPLE.inside(p): return
		if retreat or sanctum:
			_cross_threshold(TEMPLE.INNER + Vector3.BACK*1.8 if sanctum else TEMPLE.OUTER + Vector3.FORWARD*2)
		if is_instance_valid(cave_bear):
			cave_bear.queue_free()
			cave_bear = null
			boss_name_label.hide()
			boss_health_bar.hide()
		temple.leave()
		return
	if not _temple_unlocked() or p.y < 1 or p.y > 5: return
	if p.distance_to(TEMPLE.OUTER)<9 and not temple.open:
		temple.unlock(_sanctum_open())
	if absf(p.x-TEMPLE.OUTER.x)>2: return
	var entering := p.z > 19.53 and p.z < 20.55 and temple.veil.position.y < 1.8
	var returning := p.z > 21.24 and p.z < 22.2 and _sanctum_open()
	if entering or returning:
		temple.populate(_sanctum_open())
		_cross_threshold(Vector3(0,34.12,20.1) if returning else TEMPLE.TOP + Vector3(0,.12,-1))

func _update_bear_encounter() -> void:
	if not is_instance_valid(temple.chamber) or _sanctum_open() or is_instance_valid(cave_bear):
		return
	var point: Vector3 = player.global_position
	if point.z < -5.3: return
	var pad := TEMPLE.DEN if point.distance_to(TEMPLE.DEN)>4 else TEMPLE.DEN+Vector3.LEFT*6
	cave_bear = load(BEAR_SCENE).instantiate()
	cave_bear.position = pad + Vector3.UP*.08
	cave_bear.rotation.y = atan2(pad.x - point.x, pad.z - point.z)
	cave_bear.target = player
	cave_bear.health_changed.connect(_bear_health_changed)
	cave_bear.defeated.connect(_bear_victory, CONNECT_ONE_SHOT)
	add_child(cave_bear)
	_bear_health_changed(cave_bear.health, cave_bear.MAX_HEALTH)

func _bear_health_changed(value: int, maximum: int) -> void:
	boss_name_label.text = "CURSED BEAR"
	boss_health_bar.max_value = maximum
	boss_health_bar.value = value
	boss_name_label.visible = value > 0
	boss_health_bar.visible = value > 0

func _bear_victory() -> void:
	if world_data.get(CHAPTER_GUARDIANS.BEAR_FLAG, false):
		return
	world_data[CHAPTER_GUARDIANS.BEAR_FLAG] = true
	temple.unseal()
	_update_objective()
	_redraw_tracking()
	_save_progress()

func _finish_bear_chapter() -> void:
	if completed or not world_data.get(CHAPTER_GUARDIANS.BEAR_FLAG, false):
		return
	completed = true
	shards = mini(999999, shards + 80)
	_claim_optional_rewards()

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
	for item in herbs.plants:
		_ground_node(item, not item.has_node("HarvestArea"))
	var grove := preload("res://scripts/moonleaf_grove.gd").new()
	grove.candidate = true
	add_child(grove)
	grove.populate_candidate(landscape)
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
	var restored: Vector3 = player.global_position
	if TEMPLE.inside(restored) and _temple_unlocked():
		temple.populate(_sanctum_open())
	else:
		player.global_position = landscape.supported_saved_point(restored)
		if not _sanctum_open() and absf(restored.x-67)<8 and restored.y<6 and restored.z>20 and restored.z<34:
			player.global_position = TEMPLE.OUTER + Vector3.FORWARD*2
	player.velocity = Vector3.ZERO
	player._camera_pivot.global_position = player.global_position+Vector3.UP*1.2

func _configure_encounters() -> void:
	# Preserve spawn IDs, species, rewards and save flags; move only existing actors.
	# Do this after accepted vegetation generation so no foliage placement changes.
	var positions := {
		"CampDemon0": Vector3(-72, 0, 4),
		"CampDemon1": Vector3(-52, 0, -16),
		"CampDemon2": CHAPTER_GUARDIANS.WARG_HOME,
		"CampDemon3": Vector3(28, 0, 39),
		"CampDemon4": Vector3(-68, 0, 28),
		"DemonBoar": CHAPTER_GUARDIANS.BOAR_HOME,
	}
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
	if placement_ready and completed and tracked_quest in ["", "main"] and not awakening.finished():
		var objective:Dictionary=awakening.quest()
		return {"title":objective.title.to_upper(),"message":objective.next,"progress":"Seal recovered · Cave relic recorded"}
	if quest_feedback.get("title") == "MOONLEAF COLLECTED" and Time.get_ticks_msec() < quest_feedback.get("until", 0):
		return base
	if base.title == "MOONLEAF GROVE" and tracked_quest in ["", "main", "grove"]:
		return base
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
	var quest: Dictionary = awakening.quest()
	if world_data.get(CHAPTER_GUARDIANS.BEAR_FLAG, false) and not completed:
		quest.objective = "Cursed Bear defeated · Bring the cave relic to the altar"
		quest.next = "Approach the inner chamber altar and use Interact." if 1 in relic_hunt.collected_ids else "Search the entrance chamber for the cave relic."
	elif not completed:
		quest.description = "Beyond the cave's outer chambers, a sealed altar keeps the deeper passage shut."
		quest.objective = "Locked · Defeat the Cursed Bear"
		quest.next = "Follow the ash to Ancient Grove. The cave altar awaits the Grove's guardian."
		quest.locked = true
	return quest

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
	if lantern_lit and not completed:
		var goal: Dictionary = guardians.grove_objective()
		camp_menu._art_heading.text = goal.title.to_upper()
		camp_menu._art_caption.text = goal.next
	elif not lantern_lit and not completed:
		camp_menu._art_heading.text = "THE THREE CURSED GUARDIANS" if guardians.revealed() else "THE LANTERN'S SEAL"
		camp_menu._art_caption.text = "The three fragments restore the Northern Lantern." if guardians.revealed() else (
			"The inland camps have gone quiet.\nFollow the ash inland.")

func _update_objective() -> void:
	super._update_objective()
	if placement_ready and not awakening.active and not awakening.finished() and awakening.eligible() and awakening.near_pedestal():
		interact_button.visible=true
		interact_button.disabled=false
		interact_button.icon=preload("res://assets/ui/controls/lantern.svg")
		interact_button.accessibility_name="Interact · Place lantern"
	elif _can_investigate_grove():
		interact_button.visible = true
		interact_button.disabled = false
		interact_button.icon = preload("res://assets/ui/controls/collect.svg")
		interact_button.accessibility_name = "Investigate Ancient Grove"
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

	if interact_button.accessibility_name == "Collect herb":
		var plant: Node3D = herbs.nearest(player.global_position)
		if plant != null and plant.has_node("HarvestArea"):
			interact_button.accessibility_name = "Collect Moonleaf"
			herbs.set_prompt(plant)
			return
	herbs.set_prompt(null)

func _interact_world() -> void:
	if not started or game_finished or get_tree().paused or player.health <= 0:
		return
	if is_instance_valid(awakening) and awakening.eligible() and awakening.near_pedestal() and not awakening.finished():
		awakening.start()
		return
	if _can_investigate_grove():
		guardians.investigate_grove()
		_update_objective()
		_redraw_tracking()
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

func _can_investigate_grove() -> bool:
	return placement_ready and started and not game_finished and not get_tree().paused and player.health > 0 and guardians.can_investigate_grove()

func _can_inspect_camp() -> bool:
	if not is_instance_valid(opening) or not opening.can_inspect():
		return false
	var position: Vector3 = player.global_position
	return seal_fragments.nearest(position) == null and herbs.nearest(position) == null
