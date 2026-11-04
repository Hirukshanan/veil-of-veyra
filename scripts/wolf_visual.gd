extends Node3D

const MODEL_PATH := "res://assets/characters/literock/Dire_Wolf_Lite.glb"
var kind := 0
var skin: StandardMaterial3D
var animator: AnimationPlayer
var _model: Node3D
var _fallback: Node3D
var _clip := ""
var _materials: Array[StandardMaterial3D] = []
var _defeated := false

func _ready() -> void:
	if not ResourceLoader.exists(MODEL_PATH):
		push_warning("Dire Wolf Lite is missing. Follow assets/characters/literock/README.md to install the licensed model.")
		_fallback = preload("res://scripts/creature_visual.gd").new()
		_fallback.kind = kind
		_fallback.skin = skin
		add_child(_fallback)
		return
	_model = load(MODEL_PATH).instantiate()
	_model.scale = Vector3.ONE * [0.78, 0.66, 1.05][kind]
	_model.rotation.y = PI # Imported wolf faces +Z; combat faces -Z.
	add_child(_model)
	animator = _model.find_children("*", "AnimationPlayer", true, false)[0]
	for name in ["idle", "walk", "run"]:
		animator.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material: StandardMaterial3D = mesh.get_active_material(surface).duplicate()
			material.albedo_color = [Color(0.9, 0.72, 0.64), Color(0.65, 0.75, 0.85), Color(0.65, 0.57, 0.6)][kind]
			mesh.set_surface_override_material(surface, material)
			_materials.append(material)

func animate(delta: float, speed: float, anticipation: float, strike: float, hurt: float) -> void:
	if _defeated:
		return
	for material in _materials:
		material.emission_enabled = hurt > 0.0
		material.emission = Color(0.45, 0.25, 0.12) * clampf(hurt, 0.0, 1.0)
	if _fallback != null:
		_fallback.animate(delta, speed, anticipation, strike, hurt)
		return
	var next := "bite" if anticipation > 0.0 or strike > 0.0 else ("run" if speed > 2.5 else ("walk" if speed > 0.1 else "idle"))
	if hurt > 0.0:
		next = "idle"
	if next != _clip:
		animator.play(next, 0.08)
		_clip = next
	if next == "bite":
		# Sample anticipation/contact/recovery from the gameplay clock; no second damage timer.
		animator.seek(0.65 + (1.0 - strike) * 0.35 if strike > 0.0 else anticipation * 0.65, true)
		animator.pause()
	else:
		if not animator.is_playing():
			animator.play(next)
		animator.speed_scale = clampf(speed / (3.1 if next == "run" else 2.15), 0.6, 1.6) if next != "idle" else 1.0

func show_defeat(world: Node3D) -> void:
	if _defeated:
		return
	_defeated = true
	if animator != null:
		animator.pause()
	# Keep only the visual: the enemy collider, target and reward lifecycle end now.
	reparent(world, true)
	add_to_group("enemy_remains")
	var remains := get_tree().get_nodes_in_group("enemy_remains")
	if remains.size() > 8:
		remains[0].remove_from_group("enemy_remains")
		remains[0].hide()
		remains[0].queue_free()
	if _fallback != null:
		for mesh in _fallback.find_children("*", "MeshInstance3D", true, false):
			var material: StandardMaterial3D = mesh.get_active_material(0).duplicate()
			mesh.material_override = material
			_materials.append(material)
	for material in _materials:
		material.emission_enabled = false
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation:z", rotation.z + 1.35, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", position.y + 0.22, 0.24)
	tween.chain().tween_method(_fade, 1.0, 0.0, 0.45).set_delay(0.15)
	tween.chain().tween_callback(queue_free)

func _fade(alpha: float) -> void:
	for material in _materials:
		material.albedo_color.a = alpha