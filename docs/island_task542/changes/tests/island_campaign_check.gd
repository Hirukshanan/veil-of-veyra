extends SceneTree

const STORE = preload("res://scripts/campaign_store.gd")
var scene

func _initialize():call_deferred("run")

func load_candidate() -> void:
	scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)

func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var data:=STORE.DEFAULTS.duplicate()
	data.shards=240
	data.blade_level=3
	data.armor_level=2
	data.world_data=STORE.fresh_world()
	data.world_data.position=Vector3(68,0,0)
	data.world_data.health=73
	data.world_data.potions=6
	data.world_data.herbs=[1,4,8]
	data.world_data.relics=[2]
	data.world_data.seal_fragments=[0]
	data.world_data.cleared=[0,5]
	assert(STORE.save_progress(data)==OK)
	await load_candidate()
	assert(scene.shards==240 and scene.blade_level==3 and scene.armor_level==2)
	assert(scene.player.health==73 and scene.potions==6 and scene.player.max_health==150)
	assert(scene.herbs.collected_ids==[1,4,8] and scene.relic_hunt.collected_ids==[2] and scene.seal_fragments.collected_ids==[0])
	assert(scene.remaining_enemies==4 and scene.get_node_or_null("CampDemon0")==null and scene.get_node_or_null("CampDemon5")==null)
	assert(scene.player.position.y>0,"Old unsafe location gets support without resetting progress")
	scene._resume()
	Engine.time_scale=4
	scene.player.position=Vector3(76,1.58,-10)
	scene.player._camera_pivot.rotation=Vector3.ZERO
	var health: int=scene.player.health
	var ticks:=0
	while scene.player.position.z<6 and ticks<360:
		scene.player.set_move_input(Vector2.DOWN)
		await physics_frame
		ticks+=1
	assert(ticks<360,"Real hero must enter and traverse the grotto")
	assert(scene.player.health==health and scene.player.position.y>1.3 and scene.player.position.y<2.2)
	assert(1 in scene.relic_hunt.collected_ids,"The existing relic ID is collectable inside the new cave")
	scene.player.set_move_input(Vector2.ZERO)
	scene.player.position=Vector3(76,1.58,0)
	assert(scene._save_progress())
	assert(STORE.load_progress().error==OK)
	scene.queue_free()
	await process_frame
	await process_frame
	await load_candidate()
	assert(scene.shards==240 and scene.player.health==73 and scene.potions==6)
	assert(scene.player.position.distance_to(Vector3(76,1.58,0))<0.4,"Cave reload must not teleport onto the roof")
	assert(scene.herbs.collected_ids==[1,4,8] and scene.relic_hunt.collected_ids.has(1))
	# Existing boar reward, camp/lantern/dragon progression and upgrades remain functional.
	scene._resume()
	var boar=scene.get_node("DemonBoar")
	boar.take_damage(1000)
	assert(scene.shards==260 and scene.world_data.boar_defeated)
	scene._defeat_boar()
	assert(scene.shards==260)
	for enemy in get_nodes_in_group("combat_enemies"):
		if enemy.get_script()==scene.ENEMY_SCRIPT:enemy.take_damage(1000)
	await process_frame
	scene.seal_fragments.restore([0,1,2])
	scene.player.position=scene.lantern.position
	scene._interact_lantern()
	assert(scene.boss_spawned and scene.lantern_lit)
	scene.get_node("Tidewraith Dragon").take_damage(10000)
	assert(scene.completed and scene.shards==340)
	assert(STORE.load_progress().data.completed)
	scene.queue_free()
	paused=false
	await process_frame
	# Allow fixture audio voices to release before process shutdown.
	await create_timer(.75,true,false,true).timeout
	print("PASS: legacy equipment/quest/health preservation, safe relocation, real cave entry/relic, cave save reload, one-time boar reward and unchanged lantern/dragon progression")
	quit()
