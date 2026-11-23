extends Node

const EXPLORATION := preload("res://assets/audio/chapter_music/exploration.mp3")
const COMBAT := preload("res://assets/audio/chapter_music/combat.mp3")
const WOLF := preload("res://scripts/enemy.gd")
const FOX := preload("res://scripts/demon_fox.gd")
const BOAR := preload("res://scripts/demon_boar.gd")
const CHECK_INTERVAL := .20
const RELEASE_SECONDS := 2.0

var game: Node
var exploration: AudioStreamPlayer
var combat: AudioStreamPlayer
var _check_in := 0.0
var _combat_hold := 0.0
var _exploration_position := 0.0
var _want_combat := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = get_parent()
	exploration = _make_track(EXPLORATION)
	combat = _make_track(COMBAT)

func _make_track(source: AudioStreamMP3) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var loop := source.duplicate() as AudioStreamMP3
	loop.loop = true
	player.stream = loop
	player.volume_linear = 0.0
	add_child(player)
	return player

func _process(delta: float) -> void:
	# The title runs over a paused world. Reuse its exploration track when play begins.
	var at_title: bool = not game.started and is_instance_valid(game.title_screen)
	var pause_music := get_tree().paused and not at_title
	for track in [exploration, combat]:
		if track.stream_paused != pause_music:
			track.stream_paused = pause_music
	if pause_music:
		return
	var playable: bool = game.placement_ready and game.started and not game.game_finished and game.player.health > 0
	var quiet: bool = not playable or game.awakening.active or _bear_music_active()
	if quiet:
		_combat_hold = 0.0
		_want_combat = false
		_check_in = 0.0
	else:
		_check_in -= delta
		_combat_hold = maxf(0.0, _combat_hold - delta)
		if _check_in <= 0.0:
			_check_in = CHECK_INTERVAL
			if _enemy_engaged():
				_combat_hold = RELEASE_SECONDS
		_want_combat = _combat_hold > 0.0
	_fade(exploration, at_title or (not quiet and not _want_combat), -19.0, delta)
	_fade(combat, not quiet and _want_combat, -17.0, delta)

func _bear_music_active() -> bool:
	var score := game.get_node_or_null("BearEncounterAudio")
	if score != null and (score.bed.playing or score.battle.playing):
		return true
	var bear = game.cave_bear
	return is_instance_valid(bear) and bear.health > 0 and bear.can_process() and bear.state != bear.State.IDLE

func _enemy_engaged() -> bool:
	for enemy in get_tree().get_nodes_in_group("combat_enemies"):
		if not enemy.can_process() or enemy.health <= 0 or enemy.target != game.player:
			continue
		if enemy is WOLF and enemy._alert and not enemy._returning:
			return true
		if enemy is FOX and enemy.state not in [FOX.State.IDLE, FOX.State.PATROL, FOX.State.RETURN, FOX.State.DEATH]:
			return true
		if enemy is BOAR and enemy.state not in [BOAR.State.IDLE, BOAR.State.PATROL, BOAR.State.RETURN, BOAR.State.DEAD]:
			return true
	return false

func _fade(player: AudioStreamPlayer, wanted: bool, level_db: float, delta: float) -> void:
	if not wanted and not player.playing:
		return
	if wanted and not player.playing:
		player.play(_exploration_position if player == exploration else 0.0)
	var level := db_to_linear(level_db)
	var gain := move_toward(player.volume_linear, level if wanted else 0.0, delta * level / .85)
	player.volume_linear = gain
	if not wanted and is_zero_approx(gain):
		if player == exploration:
			_exploration_position = player.get_playback_position()
		player.stop()
