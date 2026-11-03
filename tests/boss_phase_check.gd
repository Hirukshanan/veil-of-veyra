extends SceneTree

const BOSS = preload("res://scripts/boss.gd")
var phase_signals := 0
var defeats := 0

class Target extends Node3D:
	var damage_taken := 0
	func take_damage(amount: int) -> void:
		damage_taken += amount

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var world := Node3D.new()
	root.add_child(world)
	var target := Target.new()
	world.add_child(target)
	for maximum in [34, 48, 62]:
		var boss = BOSS.new()
		boss.max_health = maximum
		boss.health = maximum
		boss.target = target
		boss.enraged_started.connect(func(): phase_signals += 1)
		boss.defeated.connect(func(): defeats += 1)
		world.add_child(boss)
		boss.set_physics_process(false)
		var phase_before := phase_signals
		target.position = Vector3(0, 0, -5)
		target.damage_taken = 0
		boss.take_damage(maximum / 2 - 1)
		assert(not boss.enraged)
		boss._physics_process(0.01)
		assert(boss._state == BOSS.AttackState.WINDUP)
		assert(boss._state_time == 0.85)
		assert("FIRE BREATH" in boss._attack_label.text)
		boss.take_damage(1)
		assert(boss.enraged and phase_signals == phase_before + 1)
		assert(boss._state_time == 0.85 and not boss._attack_enraged, "Threshold hit must preserve an in-flight warning")
		boss._physics_process(0.4)
		assert(boss._state == BOSS.AttackState.WINDUP and target.damage_taken == 0)
		boss._physics_process(0.46)
		boss._physics_process(0.01)
		assert(target.damage_taken == 16)
		boss._physics_process(0.6)
		assert(boss._state == BOSS.AttackState.RECOVER and boss._state_time == 0.8)
		boss._physics_process(0.81)
		boss.position = Vector3.ZERO
		boss.velocity = Vector3.ZERO
		target.position = Vector3(0, 0, -2)
		boss._physics_process(0.01)
		assert(boss._state_time == 0.65 and boss._attack_enraged)
		assert("CHARGE" in boss._attack_label.text)
		boss._physics_process(0.66)
		boss._physics_process(0.01)
		assert(is_equal_approx(Vector2(boss.velocity.x, boss.velocity.z).length(), 11.0))
		assert(target.damage_taken == 34)
		boss._physics_process(0.01)
		assert(target.damage_taken == 34, "Charge must not damage twice")
		boss._physics_process(0.5)
		assert(boss._state == BOSS.AttackState.RECOVER and boss._state_time == 0.6)
		boss.take_damage(1)
		assert(phase_signals == phase_before + 1)
		boss.take_damage(1000)
		boss.take_damage(1000)
		await process_frame
	assert(defeats == 3 and phase_signals == 3)
	var lethal = BOSS.new()
	lethal.enraged_started.connect(func(): phase_signals += 1)
	world.add_child(lethal)
	lethal.take_damage(1000)
	assert(phase_signals == 3, "Lethal hits must not announce a new phase")
	await process_frame
	world.queue_free()
	await process_frame
	print("PASS: scaled phase thresholds, one-time transition, preserved in-flight telegraph, enraged charge/recovery, attack labels, single hits and lethal skip")
	quit()
