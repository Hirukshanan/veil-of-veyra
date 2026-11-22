extends RefCounted

# A read-only view of existing saved objectives. Rewards stay with campaign.gd.
static func snapshot(scene) -> Dictionary:
	return {"seals": scene.seal_fragments.collected_ids.size(), "camps": scene.remaining_enemies, "relics": scene.relic_hunt.collected, "herbs": scene.herbs.collected, "grove": scene.herbs.grove_count(), "accepted": scene.keeper.accepted, "reported": scene.keeper.reported, "watch_remaining": scene.keeper.remaining(), "lantern": scene.lantern_lit, "completed": scene.completed, "grove_reward": scene.world_data.grove_reward, "relic_reward": scene.world_data.relic_reward, "bounty_reward": scene.world_data.bounty_reward}

static func future_prerequisites(scene) -> Dictionary:
	return {"chapter_victory": scene.completed, "seal_complete": scene.seal_fragments.complete(), "cave_relic": 1 in scene.relic_hunt.collected_ids}

static func current(scene) -> Dictionary:
	if scene.completed:
		return {"title": "VEYRA RESTORED", "message": "Continue to explore Veyra.", "guide": "Explore the cave, foothills and meadows for remaining relics and Moonleaf. Report any cleared bounty in this scroll.", "reward": "80 Tide Shards already awarded for victory.", "next": "Optional discoveries remain available. Deeper cave mysteries are a future story thread."}
	if scene._uses_guardian_seal():
		if scene.lantern_lit:
			var grove: Dictionary = scene.guardians.grove_objective()
			return {"title": grove.title.to_upper(), "message": grove.next, "guide": grove.description, "reward": grove.reward, "next": grove.next}
		if scene.seal_fragments.complete():
			return {"title": "THE NORTHERN LANTERN", "message": "Restore the Northern Lantern.", "guide": "Follow the inland trail to the lantern and use Interact.", "reward": "Reveal a trail of ash toward Ancient Grove.", "next": "Investigate Ancient Grove."}
		if scene.guardians.revealed():
			var guardians: Dictionary = scene.guardians.journal("main")
			return {"title": guardians.title.to_upper(), "message": guardians.next, "guide": guardians.description, "reward": guardians.reward, "next": guardians.next}
		return {"title": "THE LANTERN'S SEAL", "message": "Investigate the broken seal.", "guide": "Search Tideseal Ruins to learn where the seal fragments went.", "reward": "Recover the seal needed by the Northern Lantern.", "next": "Defeat the three cursed guardians."}
	if scene.boss_spawned:
		return {"title": "THE TIDEWRAITH", "message": "Defeat the Tidewraith Dragon.", "guide": "Return to the restored northern lantern. Use the field guide to prepare for the confrontation.", "reward": "80 Tide Shards on victory; secured optional bonuses are paid once.", "next": "Victory resolves the island's current curse. Exploration remains available."}
	if scene.remaining_enemies == 0 and scene.seal_fragments.complete():
		return {"title": "THE NORTHERN LANTERN", "message": "Restore the northern lantern.", "guide": "The seal is whole and the camps are quiet. Follow the inland trail to the northern lantern; approach and use LIGHT / E.", "reward": "Unlock the Tidewraith confrontation.", "next": "The Tidewraith becomes the current objective."}
	if not scene.seal_fragments.complete():
		return {"title": "THE LANTERN'S SEAL", "message": "Recover the three seal fragments.", "guide": "Search south-west Tideseal Ruins. Approach each cyan fragment and use COLLECT / E.", "reward": "Restore the seal needed by the northern lantern.", "next": "Clear all five camp wolves as well to unlock the lantern."}
	return {"title": "QUIET THE FOREST CAMPS", "message": "Clear the remaining camp wolves.", "guide": "The seal is recovered. Search the western forest and its hill clearings. Moonleaf along the paths provides healing.", "reward": "Clear the route required by the lantern. Optional Western Watch credit counts the western pair.", "next": "The northern lantern becomes available when all five wolves are defeated."}

static func journal(scene) -> String:
	var goal := current(scene)
	var state := snapshot(scene)
	var guardian_flow: bool = scene._uses_guardian_seal()
	var text := "CURRENT — %s\n%s\nReward: %s\nNext: %s" % [goal.title, goal.guide, goal.reward, goal.next]
	text += "\n\nMAIN PROGRESS\nSeal fragments: %d/3. Camp wolves: %d/5 cleared, %d remaining." % [state.seals, clampi(5-state.camps,0,5), state.camps]
	if guardian_flow:
		text += "\nNorthern lantern: " + ("RESTORED" if state.lantern else "READY" if state.seals == 3 else "LOCKED — three guardian fragments required")
	else:
		text += "\nThese objectives are available together; neither resets the other."
		text += "\nNorthern lantern: " + ("RESTORED" if state.lantern else ("READY — camps and seal complete" if state.camps == 0 and state.seals == 3 else "LOCKED — all three fragments AND all five wolves required"))
		text += "\nTidewraith: " + ("DEFEATED — 80 shards received" if state.completed else ("ACTIVE — 80 shards on victory" if scene.boss_spawned else "LOCKED — restore the northern lantern first"))
	var watch := "AVAILABLE — accept the bounty in this scroll"
	if state.accepted:
		watch = "ACTIVE — %d western wolves remaining" % state.watch_remaining
		if state.watch_remaining == 0:
			watch = "READY — use Complete in this scroll"
	if state.reported:
		watch = "SECURED — 15 shards paid after Chapter I victory" if guardian_flow else "SECURED — 15 shards paid after Tidewraith victory"
	if state.bounty_reward:
		watch = "COMPLETE — 15 shards received"
	text += "\n\nWESTERN WATCH — %s\nOptional. Clear the western forest pair, then report using this scroll. Earlier kills count. Reward: 15 shards after both reporting and victory; paid once." % watch
	var relic_state := "%d/3 recovered" % state.relics
	if state.relic_reward:
		relic_state = "COMPLETE — 20 shards received"
	elif state.relics == 3:
		relic_state += " — bonus awaits victory"
	text += "\n\nKEEPER'S RELICS — %s\nOptional. Search the grassland trail, mountain foothills and eastern cave. Walk near each golden relic to recover it. The cave relic is accessible now. Reward: 20 shards once all three are found and %s." % [relic_state, "Chapter I victory is recorded" if guardian_flow else "the Tidewraith is defeated"]
	text += "\n\nMOONLEAF — %d plants gathered\nEach Moonleaf plant gives one healing potion. Use HEAL while injured to recover up to 50 health. Follow meadow and river-crossing paths to Moonleaf Grove." % state.herbs
	text += "\nMOONLEAF GROVE — " + ("COMPLETE — 25 shards received" if state.grove_reward else "%d/3 grove flowers" % mini(state.grove,3))
	text += "\nReward: 25 shards automatically on gathering three grove flowers, plus their normal potions. Other Moonleaf does not count toward the grove reward. All rewards are paid once."
	text += "\n\nTRAVEL AND PREPARATION\nApproach waystones to discover and bind them. Discovered waystones support return travel. Spend Tide Shards on blade/armor upgrades at camp."
	text += " The Demon Boar guards a seal fragment and awards 20 shards once." if guardian_flow else " Optional Demon Boar: 20 shards once; it is not required by the lantern."
	var requirements := future_prerequisites(scene)
	var ready: bool = requirements.values().all(func(value): return value)
	text += "\n\nBEYOND THE LANTERN — FUTURE STORY\n" + ("The island victory, seal and cave relic are recorded." if ready else "The deeper mystery follows island victory, the complete seal and discovery of the cave relic.")
	text += " A low echo carries through the deeper hall. The old stone keeps its source hidden."
	var chapter_route := "The guardian fragments restore the Northern Lantern and reveal the trail toward Ancient Grove." if guardian_flow else "Quieting the forest camps and recovering its fragments opens the northern lantern."
	text += "\n\nCHAPTER I — A LIGHT TO RECLAIM\nAru follows a shattered seal from the shore into Veyra's corrupted trails. %s The grasslands, foothills and cave preserve relics of an older mystery.\n\nSAVED JOURNEY\nCollected items, cleared wolves, bounty acceptance/report, reward flags, equipment, potions and waystones persist. Collected objectives remain available in any order. Unfinished enemies recover health after reload." % chapter_route
	text += "\nWaystone: " + scene.get_node("IslandExploration").rescue_name() + "\nBoundary: shallow water blocks deep-sea access."
	if not scene.quest_feedback.is_empty():
		text += "\n\nRECENT PROGRESS\n" + scene.quest_feedback.title + " — " + scene.quest_feedback.message
	return text

static func hud(scene) -> Dictionary:
	var data := {"title": "THE LANTERN'S SEAL", "message": "Recover the three seal fragments.", "progress": "Seal 0/3   •   Camps 0/5"}
	if not scene._world_ready:
		return data
	var goal := current(scene)
	data.title = goal.title
	data.message = goal.message
	data.progress = "Seal %d/3   •   Camps %d/5" % [scene.seal_fragments.collected_ids.size(), clampi(5-scene.remaining_enemies,0,5)]
	if not scene.boss_spawned or scene.completed:
		if scene.player.global_position.distance_to(scene.herbs.grove_center()) < 18:
			data.title = "MOONLEAF GROVE"
			data.message = "Collect glowing Moonleaf (%d/3)." % mini(3, scene.herbs.grove_count())
			data.progress = "25 shards + healing potions" if not scene.world_data.grove_reward else "Grove complete · 25 Tide Shards received"
		elif scene.keeper.accepted and not scene.keeper.reported and scene.keeper.remaining() == 0:
			data.title = "WESTERN WATCH"
			data.message = "Complete bounty in QUEST."
			data.progress = "15 shards after victory"
		elif scene.player.position.x > 58 and scene.player.position.z > -18 and scene.player.position.z < 58 and not 1 in scene.relic_hunt.collected_ids:
			data.title = "KEEPER'S RELICS"
			data.message = "Find the golden cave relic."
			data.progress = "Optional   •   20 after victory"
	if not scene.quest_feedback.is_empty() and Time.get_ticks_msec() < scene.quest_feedback.until:
		data.title = scene.quest_feedback.title
		data.message = scene.quest_feedback.message
		data.progress = scene.quest_feedback.get("progress", data.progress)
	return data

static func feedback(previous: Dictionary, state: Dictionary) -> Dictionary:
	if state.grove > previous.grove:
		var progress := "One healing potion per flower"
		if state.grove_reward and not previous.grove_reward:
			progress = "+25 Tide Shards received"
		return {"title": "MOONLEAF COLLECTED", "message": "%d/3 flowers · +1 potion" % mini(3, state.grove), "progress": progress}
	for entry in [["grove_reward", "GROVE COMPLETE", "+25 Tide Shards received."], ["relic_reward", "RELICS COMPLETE", "+20 Tide Shards received."], ["bounty_reward", "BOUNTY COMPLETE", "+15 Tide Shards received."]]:
		if state[entry[0]] and not previous[entry[0]]:
			return {"title": entry[1], "message": entry[2]}
	if state.seals > previous.seals:
		return {"title": "SEAL RECOVERED" if state.seals == 3 else "FRAGMENT RECOVERED", "message": "%d/3 fragments recorded." % state.seals}
	if state.relics > previous.relics:
		return {"title": "RELIC DISCOVERED", "message": "%d/3 relics recorded." % state.relics}
	if state.camps < previous.camps:
		return {"title": "CAMPS QUIET" if state.camps == 0 else "CAMP PROGRESS", "message": "%d/5 wolves cleared." % (5-state.camps)}
	if state.reported and not previous.reported:
		return {"title": "BOUNTY SECURED", "message": "15 shards after victory."}
	if state.accepted and not previous.accepted:
		return {"title": "WESTERN WATCH", "message": "Bounty accepted in the scroll."}
	if state.herbs > previous.herbs:
		return {"title": "MOONLEAF GATHERED", "message": "+1 healing potion received."}
	return {}
