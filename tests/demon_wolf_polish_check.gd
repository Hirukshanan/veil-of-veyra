extends SceneTree

const WOLF := preload("res://scripts/enemy.gd")
const HERO := preload("res://scripts/player.gd")
var world: Node3D
var hero: CharacterBody3D
var ember_dimensions := Vector4.ZERO

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for frame in count:
		await physics_frame

func solid(at: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	collider.shape = box
	body.add_child(collider)
	body.position = at
	world.add_child(body)
	return body

func wait_for_tell(wolf: CharacterBody3D) -> bool:
	for frame in 240:
		if wolf._windup > 0.0:
			return true
		await physics_frame
	return false

func check_variant(kind: int) -> void:
	var wolf := WOLF.new()
	wolf.kind = kind
	wolf.position.y = .1
	wolf.target = hero
	world.add_child(wolf)
	assert(wolf._visual.animator != null)
	var body := wolf.find_children("*", "CollisionShape3D", false, false)[0] as CollisionShape3D
	var capsule := body.shape as CapsuleShape3D
	var dimensions := Vector4(wolf._visual._model.scale.x, capsule.radius, capsule.height, wolf.attack_range)
	if kind == WOLF.Kind.SHORE:
		ember_dimensions = dimensions
	elif kind == WOLF.Kind.BRUTE:
		assert(dimensions.is_equal_approx(ember_dimensions), "Dire Warg must match Ember Wolf scale, footprint and reach")
	else:
		assert(is_equal_approx(dimensions.x, 1.05) and is_equal_approx(dimensions.y, .31))
	hero.position = Vector3(0, 0, -30)
	hero.health = 100
	hero._invulnerability_time = 0.0
	await ticks(125)
	assert(wolf._ground_speed > 0.15 and wolf._visual._clip == "walk", "Expected a moving patrol")
	var prior_speed: float = wolf._ground_speed
	hero.position = Vector3(0, 0, -7)
	await ticks(2)
	assert(wolf._alert and wolf._ground_speed < wolf.move_speed and absf(wolf._ground_speed - prior_speed) < 1.5)
	await ticks(48)
	assert(wolf._visual._clip == "run" or wolf._warning.visible)
	assert(await wait_for_tell(wolf))
	assert(wolf._warning.visible and hero.health == 100)
	var start := wolf.global_position
	await ticks(ceili((wolf.windup_duration + WOLF.CONTACT_TIME + .04) * 60.0))
	assert(hero.health == 100 - wolf.attack_damage, "Expected one real melee hit for " + wolf.display_name)
	assert(wolf._feedback.swipe.visible)
	assert(wolf.global_position.distance_to(start) > .045, "The lunge must move the body when the path is open")
	await ticks(24)
	assert(hero.health == 100 - wolf.attack_damage and not wolf._feedback.swipe.visible)
	hero._invulnerability_time = 0.0
	assert(await wait_for_tell(wolf))
	var after_hit: int = hero.health
	await ticks(ceili(wolf._windup * .75 * 60.0))
	hero.position += Vector3.RIGHT * 2.3
	await ticks(45)
	assert(hero.health == after_hit, "Leaving the telegraph must evade the bite")
	hero.position = Vector3(0, 0, -40)
	await ticks(165)
	assert(not wolf._alert and not wolf._returning and wolf.position.distance_to(wolf._home) < 3.0)

	wolf.set_physics_process(false)
	wolf.global_position = Vector3.ZERO
	wolf.rotation.y = 0.0
	hero.position = Vector3(0, 0, -1.45)
	var blocker := solid(Vector3(0,.7,-.98), Vector3(3,1.4,.14))
	await ticks(2)
	wolf._bite_origin = wolf.global_position
	wolf._bite_heading = Vector3.FORWARD
	assert(not wolf._bite_path_clear())
	wolf._resolve_bite()
	assert(hero.health == after_hit, "Wall must block damage at contact")
	blocker.queue_free()
	var feedback: Node3D = wolf._feedback
	wolf.take_damage(100)
	await ticks(3)
	assert(not is_instance_valid(feedback))
	print("PASS ", kind, " patrol, chase, single bite, miss, recovery, return, wall and effect cleanup")

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	world = Node3D.new()
	root.add_child(world)
	solid(Vector3(0,-.5,0), Vector3(110,1,110))
	hero = HERO.new()
	world.add_child(hero)
	hero.set_collision_mask_value(WOLF.BODY_LAYER, true)
	hero.set_physics_process(false)
	for kind in 3:
		await check_variant(kind)
	world.queue_free()
	await ticks(2)
	quit()
