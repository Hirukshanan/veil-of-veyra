extends "res://scripts/island_candidate.gd"

const SHRINE := preload("res://scripts/grand_shrine.gd")
@export var polish_model: PackedScene
@export var connected_awakening := false
@export var dragon_cavern := false
var shrine: SHRINE
var cinema_shell: MeshInstance3D
var first_roar := false
var introduced := false


func _create_bear_temple() -> TEMPLE:
	return SHRINE.new()

func _create_awakening() -> Node3D:
	if connected_awakening:
		var event := preload("res://scripts/sanctum_awakening.gd").new()
		event.extend_passage = dragon_cavern
		return event
	return super._create_awakening()

func _ready() -> void:
	shrine = temple as SHRINE
	shrine.polish_model = polish_model
	shrine.dragon_cavern = dragon_cavern
	await super._ready()
	if polish_model:
		var gameplay_camera := player._camera_arm.get_child(0) as Camera3D
		gameplay_camera.cull_mask &= ~(1 << 18)
	cinema_shell = MeshInstance3D.new()
	var grotto := landscape.get_node("PlayableGrotto") as MeshInstance3D
	cinema_shell.mesh = grotto.mesh
	cinema_shell.material_override = grotto.material_override
	cinema_shell.layers = 1<<18
	cinema_shell.hide()
	awakening.add_child(cinema_shell)
	if shrine.in_cell: _place_sanctum()

func _owns_cell(point: Vector3) -> bool:
	return SHRINE.owns(point) or (dragon_cavern and point.z>=47 and point.z<86 and point.y>=17 and point.y<50 and absf(point.x-2.7)<19)

func _ground_gameplay() -> void:
	var saved: Vector3 = player.position
	super._ground_gameplay()
	if _sanctum_open() and saved.y>1 and saved.y<6 and saved.z>21.2 and saved.z<48 and absf(saved.x-65)<5.8:
		shrine.populate(true)
		player.position = SHRINE.ALTAR + Vector3(1.2,.16,-1.8)
		player.velocity = Vector3.ZERO
		player._camera_pivot.global_position = player.position+Vector3.UP*1.2
	elif _temple_unlocked() and _owns_cell(saved):
		shrine.populate(_sanctum_open())
		player.position = saved
		if saved.z < -5:
			player.position.x = clampf(saved.x,-3.1,3.1)
			player.position.y = 34.18+clampf((-5.-saved.z)*.45,0.,10.8)
		elif saved.z < 20:
			player.position.x = clampf(saved.x,-8.4,8.4)
		elif not _sanctum_open():
			player.position = Vector3(0,34.12,17)
		player._camera_pivot.global_position = player.position+Vector3.UP*1.2

func _interact_world() -> void:
	super._interact_world()
	if not connected_awakening and shrine.in_cell and awakening.active: cinema_shell.show()

func _place_sanctum() -> void:
	awakening.position = SHRINE.ALTAR-awakening.PEDESTAL
	shrine.decorate_altar(awakening.pedestal)
	if connected_awakening: awakening.attach_sanctum(shrine)
	if polish_model:
		for chunk in awakening.chunks:
			chunk.layers = 1 << 18
		_refresh_sanctum_seal()
	awakening.show()
	awakening.process_mode = Node.PROCESS_MODE_INHERIT

func _refresh_sanctum_seal() -> void:
	if connected_awakening: return
	for panel in shrine.sanctum_seal:
		panel.visible = not awakening.finished()

func _finish_bear_chapter() -> void:
	super._finish_bear_chapter()
	_refresh_sanctum_seal()

func _update_temple_thresholds() -> void:
	if not connected_awakening and is_instance_valid(cinema_shell):
		cinema_shell.visible = shrine.in_cell and awakening.active and awakening.clock < 17.3
	if awakening.active: return
	var p: Vector3 = player.position
	if shrine.in_cell:
		if p.z < -31.45 or not _owns_cell(p):
			if p.z < -31.45: _cross_threshold(TEMPLE.OUTER+Vector3.FORWARD*2)
			shrine.suspend_cell()
			awakening.hide()
			awakening.process_mode = Node.PROCESS_MODE_DISABLED
			if is_instance_valid(cave_bear):
				cave_bear.hide()
				cave_bear.process_mode = Node.PROCESS_MODE_DISABLED
				boss_name_label.hide()
				boss_health_bar.hide()
		elif introduced and is_instance_valid(cave_bear) and cave_bear.health>0:
			# On the stairs the player can break contact. The boss keeps its
			# transform, health and current animation inside the hall.
			var engaged := p.z >= -5.4 or cave_bear.position.z > -3.5
			cave_bear.target = player if engaged else null
			if engaged and first_roar and cave_bear.state==cave_bear.State.CHASE:
				first_roar = false
				cave_bear._begin(cave_bear.Attack.ROAR)
		return
	if not _temple_unlocked() or p.y<1 or p.y>5: return
	if p.distance_to(TEMPLE.OUTER)<9 and not shrine.open: shrine.unlock(_sanctum_open())
	if absf(p.x-TEMPLE.OUTER.x)>2 or p.z<=19.53 or p.z>=20.55 or shrine.veil.position.y>=1.8: return
	shrine.populate(_sanctum_open())
	_place_sanctum()
	_cross_threshold(SHRINE.STAIR_TOP)
	if is_instance_valid(cave_bear):
		cave_bear.show()
		cave_bear.process_mode = Node.PROCESS_MODE_INHERIT
		if introduced: _bear_health_changed(cave_bear.health,cave_bear.MAX_HEALTH)

func _update_bear_encounter() -> void:
	if not shrine.in_cell or _sanctum_open(): return
	if not is_instance_valid(cave_bear):
		cave_bear = load(BEAR_SCENE).instantiate()
		cave_bear.position = SHRINE.LAIR
		cave_bear.health_changed.connect(_bear_health_changed)
		cave_bear.defeated.connect(_bear_victory,CONNECT_ONE_SHOT)
		add_child(cave_bear)
	if introduced or player.position.z < -12: return
	introduced = true
	cave_bear.target = player
	cave_bear._enter(cave_bear.State.ALERT,1.06)
	cave_bear._play("Alert_Aggro")
	first_roar = true
	_bear_health_changed(cave_bear.health,cave_bear.MAX_HEALTH)
