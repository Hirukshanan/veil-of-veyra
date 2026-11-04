extends Node3D

const MODEL_PATH := "res://assets/characters/literock/Dire_Wolf_Lite.glb"
var kind := 0
var skin: StandardMaterial3D
var animator: AnimationPlayer
var _model: Node3D
var _fallback: Node3D
var _clip := ""

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

func animate(delta: float, speed: float, anticipation: float, strike: float, hurt: float) -> void:
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
