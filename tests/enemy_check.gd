extends SceneTree

const ENEMY = preload("res://scripts/enemy.gd")
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
	for kind in range(3):
		var enemy = ENEMY.new()
		enemy.kind = kind
		enemy.health = 5
		enemy.target = target
		world.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.defeated.connect(func(): defeats += 1)
		assert(enemy.health == [5, 4, 8][kind])
		assert(is_equal_approx(enemy._warning.mesh.top_radius, enemy.attack_range))
		target.position = Vector3(0, 0, -8)
		enemy._physics_process(0.01)
		assert(is_equal_approx(Vector2(enemy.velocity.x, enemy.velocity.z).length(), [2.15, 3.1, 1.45][kind]))
		enemy.position = Vector3.ZERO
		enemy.velocity = Vector3.ZERO
		target.position = Vector3(0, 0, -1.2)
		target.damage_taken = 0
		enemy._physics_process(0.01)
		assert(enemy._warning.visible and target.damage_taken == 0)
		enemy._physics_process(enemy.windup_duration * 0.5)
		assert(target.damage_taken == 0, "Every kind must give the full warning")
		enemy._physics_process(enemy.windup_duration * 0.5 + 0.01)
		assert(target.damage_taken == [8, 5, 16][kind])
		assert(not enemy._warning.visible)
		enemy.position = Vector3.ZERO
		enemy.velocity = Vector3.ZERO
		enemy._physics_process(enemy.recovery_duration + 0.01)
		assert(enemy._warning.visible)
		target.position = Vector3(0, 0, -enemy.attack_range - 0.2)
		enemy._physics_process(enemy.windup_duration + 0.01)
		assert(target.damage_taken == [8, 5, 16][kind], "Escaping must avoid every kind's attack")
		enemy.position = Vector3.ZERO
		enemy.velocity = Vector3.ZERO
		target.position = Vector3(0, 0, -1.2)
		enemy._physics_process(enemy.recovery_duration + 0.01)
		enemy.take_damage(1)
		assert(enemy._windup == 0 and not enemy._warning.visible)
		assert(str(enemy.health) in enemy._health_label.text)
		enemy._physics_process(0.01)
		assert(enemy._material.albedo_color == Color(1, 0.85, 0.65))
		enemy._physics_process(0.2)
		assert(enemy._material.albedo_color == enemy.body_color)
		enemy.take_damage(100)
		enemy.take_damage(100)
		assert(defeats == kind + 1)
		await process_frame
	world.queue_free()
	await process_frame
	print("PASS: Shore/Scout/Brute health, pursuit speed, warning radius/timing, damage, escape, interruption, hit feedback and single defeat")
	quit()
