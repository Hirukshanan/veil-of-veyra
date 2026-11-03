extends Node3D

const BONUS_SHARDS := 20
const RELIC_COUNT := 3

var player: Node3D
var chapter := 0
var active := false
var collected := 0
var relics: Array[Node3D] = []

func _ready() -> void:
	var locations := [Vector3(-8, 0, -4), Vector3(8, 0, -4), Vector3(0, 0, 9)]
	for index in range(RELIC_COUNT):
		var relic := Node3D.new()
		relic.name = "KeeperRelic%d" % (index + 1)
		relic.position = locations[index].rotated(Vector3.UP, chapter * 0.5)
		add_child(relic)
		relics.append(relic)
		var gem := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.55, 0.9, 0.55)
		gem.mesh = mesh
		gem.position.y = 1.0
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.65, 0.2)
		material.emission_enabled = true
		material.emission = Color(0.7, 0.35, 0.04)
		gem.material_override = material
		relic.add_child(gem)
		var label := Label3D.new()
		label.text = "KEEPER RELIC"
		label.position.y = 2.0
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 32
		relic.add_child(label)

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(player) or int(player.get("health")) <= 0:
		return
	for relic in relics.duplicate():
		relic.get_child(0).rotate_y(delta)
		if player.global_position.distance_to(relic.global_position) <= 1.4:
			relics.erase(relic)
			collected += 1
			relic.queue_free()

func progress_text() -> String:
	if collected == RELIC_COUNT:
		return "Keeper relics: 3/3 — Defeat the dragon for +20 shards"
	var nearest := INF
	for relic in relics:
		nearest = minf(nearest, player.global_position.distance_to(relic.global_position))
	return "Optional: Keeper relics %d/3 | Nearest: %.0f m | Walk near to collect" % [collected, nearest]

func reward() -> int:
	return BONUS_SHARDS if collected == RELIC_COUNT else 0
