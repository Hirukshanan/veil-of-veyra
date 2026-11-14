extends SceneTree

const BOAR = preload("res://scripts/demon_boar.gd")
var world: Node3D
var boar
var target: Dummy
var defeats := 0

class Dummy extends CharacterBody3D:
	var health := 100
	var contacts := 0
	var invulnerable := false
	func take_damage(amount: int) -> void:
		if not invulnerable: health -= amount
	func take_charge_damage(amount: int, _direction: Vector3) -> void:
		contacts += 1
		take_damage(amount)

func _initialize() -> void:
	call_deferred("run")

func wait_game(seconds: float) -> void:
	await create_timer(seconds, false, true).timeout

func reset_case(point := Vector3(0, 0, -4.2)) -> void:
	boar.set_physics_process(false)
	boar.global_position = Vector3(0, 0.03, 0)
	boar.velocity = Vector3.ZERO
	boar.rotation = Vector3.ZERO
	boar._home = Vector3.ZERO
	boar._attack_delay = 0.0
	boar._sense_time = 0.0
	target.global_position = point
	target.health = 100
	target.contacts = 0
	target.invulnerable = false
	await physics_frame
	await physics_frame
	boar._enter(BOAR.State.WARNING)
	boar.set_physics_process(true)

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	Engine.time_scale = 3.0
	world = Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(60, 1, 60)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.5
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	target = Dummy.new()
	target.collision_layer = 1
	var target_collision := CollisionShape3D.new()
	var target_capsule := CapsuleShape3D.new()
	target_capsule.radius = 0.42
	target_capsule.height = 1.8
	target_collision.shape = target_capsule
	target_collision.position.y = 0.9
	target.add_child(target_collision)
	target.position = Vector3(0, 0, -4.2)
	world.add_child(target)
	boar = BOAR.new()
	boar.target = target
	boar.position.y = 0.03
	world.add_child(boar)
	boar.defeated.connect(func(): defeats += 1)
	await physics_frame
	assert(boar.animator.has_animation("death") and boar.animator.has_animation("charge_warning"))
	await reset_case(Vector3(0, 0, -2.0))
	boar._enter(BOAR.State.FACE)
	await wait_game(0.4)
	assert((-boar.global_basis.z).dot(boar.velocity.normalized()) > 0.9, "Close-range repositioning must not alternate between opposite turn commands")
	for index in range(26):
		target.position = boar.position + Vector3.FORWARD * 1.5
		await physics_frame
	assert(boar.state == BOAR.State.WARNING, "Continued melee pressure must not cause endless retreat")
	await reset_case()
	await wait_game(1.4)
	assert(boar.state == BOAR.State.WARNING and target.health == 100, "Full telegraph before damage")
	var committed: Vector3 = boar._charge_direction
	target.position.x = 3.0
	await wait_game(2.6)
	assert(target.health == 100 and target.contacts == 0, "Sidestep must avoid the committed lane")
	assert(boar._charge_direction.is_equal_approx(committed) and absf(boar.position.x) < 0.02, "No homing during charge")
	assert(boar.state == BOAR.State.RECOVERY)
	assert(absf(boar.position.y) < 0.08, "Visible feet must settle at the floor, not below it")
	await reset_case()
	await wait_game(3.2)
	assert(target.health == 82 and target.contacts == 1, "Valid tusk contact must hit once")
	await wait_game(0.6)
	assert(target.health == 82 and target.contacts == 1, "No repeated damage while overlapping")
	await reset_case()
	target.invulnerable = true
	await wait_game(3.2)
	assert(target.health == 100 and target.contacts <= 1, "An invulnerable target takes no charge damage")
	await reset_case()
	var wall := StaticBody3D.new()
	wall.collision_layer = 4 | 8
	wall.position = Vector3(0, 1.1, -3.0)
	var wall_collision := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(5, 2.2, 0.4)
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	# This obstacle appears after commitment, so a fresh collision must stop the attack.
	await wait_game(0.4)
	world.add_child(wall)
	await wait_game(2.8)
	assert(target.health == 100 and target.contacts == 0, "No attack through a solid wall")
	assert(boar.position.z > -1.9, "Swept body collision must stop before the wall")
	boar.set_physics_process(false)
	boar._enter(BOAR.State.IDLE)
	boar.position = Vector3.ZERO
	target.position = Vector3(0, 0, -6)
	await physics_frame
	assert(not boar._clear_line(target), "Walls block initial detection")
	wall.queue_free()
	await physics_frame
	boar.take_damage(1)
	assert(boar.state == BOAR.State.HURT and boar._clip == "hit_reaction")
	boar._enter(BOAR.State.WARNING)
	var hp: int = boar.health
	boar.take_damage(1)
	assert(boar.health == hp - 1 and boar.state == BOAR.State.WARNING, "Light hits damage charge poise without permanent stun-lock")
	boar.stagger(0.65)
	assert(boar.state == BOAR.State.HURT and not boar._warning.visible, "Existing heavy stagger interrupts charge")
	boar.take_damage(1000)
	boar.take_damage(1000)
	assert(defeats == 1 and boar.state == BOAR.State.DEAD and not boar.is_in_group("combat_enemies"))
	boar.set_physics_process(true)
	await wait_game(3.2)
	var skeleton: Skeleton3D = boar._model.find_children("*", "Skeleton3D", true, false)[0]
	var final_pose := skeleton.get_bone_global_pose(0)
	await wait_game(0.5)
	assert(skeleton.get_bone_global_pose(0).is_equal_approx(final_pose), "Death must hold its final pose")
	world.queue_free()
	await process_frame
	print("PASS: boar telegraph, committed dodgeable lane, single contact, invulnerability, wall/LOS collision, grounded collider, stagger, single defeat and death hold")
	quit()
