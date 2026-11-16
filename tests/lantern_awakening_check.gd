extends SceneTree
const STORE=preload("res://scripts/campaign_store.gd")
var scene
var output:String
var results:Array=[]

func _initialize():call_deferred("run")

func open_world():
	scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)

func close_world():
	scene.queue_free();paused=false
	await process_frame
	await create_timer(.75,true,false,true).timeout

func fixture():
	var data:=STORE.DEFAULTS.duplicate(true)
	data.world_data=STORE.fresh_world()
	data.completed=true;data.shards=80
	data.world_data.merge({"cleared":[0,1,2,3,4,5],"seal_fragments":[0,1,2],"relics":[1],"lantern":true,"position":Vector3(62.5,2.4,23)},true)
	assert(STORE.save_progress(data)==OK)

func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0]
	await open_world()
	var event=scene.awakening
	scene.player.position=event.PEDESTAL+Vector3(0,0,-2)
	assert(not event.eligible() and not event.start())
	scene.completed=true;scene.lantern_lit=true
	scene.seal_fragments.restore([0,1,2])
	assert(not event.eligible(),"Cave relic is required")
	scene.relic_hunt.restore([1])
	assert(event.eligible())
	for prerequisite in ["completed","lantern_lit"]:
		scene.set(prerequisite,false)
		assert(not event.eligible())
		scene.set(prerequisite,true)
	scene.seal_fragments.restore([0,1])
	assert(not event.eligible())
	var data:Dictionary=STORE.DEFAULTS.duplicate(true);data.world_data=STORE.fresh_world()
	for invalid in ["yes",1,null]:
		data.world_data.lantern_awakening=invalid
		assert(not STORE.valid_world(data.world_data,false,0))
	data.world_data.lantern_awakening=true
	assert(not STORE.valid_world(data.world_data,false,0))
	results.append("Incomplete requirements do not trigger; malformed or impossible optional flags are rejected")
	await close_world()
	fixture()
	await open_world()
	event=scene.awakening
	assert(event.eligible() and not event.finished())
	assert(scene.keeper.accepted==false and scene.herbs.grove_count()==0 and scene.relic_hunt.collected==1)
	assert(scene.interact_button.visible)
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(67,4,29),Vector3(67,4,35),4)
	await physics_frame
	assert(scene.get_world_3d().direct_space_state.intersect_ray(ray).collider==event.gate)
	var health:int=scene.player.health
	var previous_camera=get_root().get_camera_3d()
	scene.interact_button.pressed.emit()
	assert(event.active and not scene.player.is_physics_processing() and not scene.player.is_processing_input())
	assert(not event.start())
	scene.player.take_damage(10000)
	assert(scene.player.health==health)
	var samples:Array=[]
	while event.active:
		await process_frame
		if event.clock>6.2 and samples.is_empty():
			assert(event.pedestal.position.y<event.PEDESTAL.y-2)
			assert(event.gate.get_child(0).disabled)
			assert(event.cracks.get_child_count()==32)
			for point in [Vector3(66,4.8,21.5),Vector3(66,4.5,26),Vector3(67,4.8,29),Vector3(66,5,35),Vector3(64,5.5,44.5)]:
				var query:=PhysicsShapeQueryParameters3D.new();var sphere:=SphereShape3D.new();sphere.radius=.2
				query.shape=sphere;query.transform.origin=point;query.collision_mask=1|4|8
				assert(scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"Camera must remain inside the open cave")
				samples.append(point)
	assert(not paused and event.finished() and scene.player.health==health)
	assert(get_root().get_camera_3d()==previous_camera)
	assert(scene.shards==80 and not scene.world_data.bounty_reward and not scene.world_data.relic_reward)
	assert(event.last_eye_open>.99 and event.eye.get_parent()==event.overlay and event.eye_frame==5)
	assert(not event.start())
	assert(STORE.load_progress().data.world_data.lantern_awakening)
	results.append({"full_sequence":event.events.duplicate(true),"camera_clearance_samples":samples,"health_unchanged":true,"reward_unchanged":true})
	# Verify the opened passage with the real hero body, including a safe return.
	scene.player.position=Vector3(67,2.7,29)
	for frame in range(100):
		await physics_frame
		scene.player.velocity=Vector3(0,-.8,2.8)
		scene.player.move_and_slide()
	assert(scene.player.position.z>33.5)
	for frame in range(100):
		await physics_frame
		scene.player.velocity=Vector3(0,-.8,-2.8)
		scene.player.move_and_slide()
	assert(scene.player.position.z<30)
	results.append("Real hero capsule traverses opened passage and returns")
	await close_world()
	await open_world()
	event=scene.awakening
	assert(event.finished() and not event.active and not event.start())
	await physics_frame
	assert(event.gate.get_child(0).disabled and scene.shards==80)
	assert(scene.relic_hunt.collected_ids==[1])
	assert(scene.awakening_quest().done)
	await close_world()
	# Skip before the physical gate opens, then verify the same persistent result.
	fixture()
	await open_world()
	event=scene.awakening
	assert(event.start())
	event.skip_button.pressed.emit();event.skip()
	await physics_frame
	assert(event.finished() and not paused and event.gate.get_child(0).disabled)
	assert(scene.shards==80 and STORE.load_progress().data.world_data.lantern_awakening)
	results.append("Normal completion and immediate repeated Skip preserve the same open state, journal flag and 80-shard balance after reload")
	FileAccess.open(output+"/awakening_results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"cases":results,"save_version":STORE.VERSION,"optional_side_quests_required":false},"  "))
	await close_world()
	print("PASS: lantern prerequisites, full cinematic, collision/traversal, camera clearance, immunity, save/reload, duplicate guard and skip")
	quit()
