extends Node3D

const CLUES := preload("res://scripts/chapter_opening_clues.gd")
const SAVE_KEY := "chapter_opening"
const BELL := 1
const CAMP := 2
const JUNCTION := 4
const SWORD := 8
const DODGE := 16
const COUNTER := 32
const ALL_BEATS := BELL | CAMP | JUNCTION | SWORD | DODGE | COUNTER
const CAMP_FINDING := "The fire is cold. The roots are warm."
const JUNCTION_LINE := "See where the roots lead."
const FRAGMENT_NOTES := [
	"A seal held something dangerous below.",
	"The ward holds where the stone is whole.",
	"The ash crosses only through the break.",
]

var game
var _wolf: Node3D
var _camp: Vector3
var _junction: Vector3
var _beach: Vector3
var _bell: AudioStreamPlayer3D
var _bell_delay := .55
var _message := ""
var _message_time := 0.0
var _dodge_prompts := 0
var _was_winding_up := false
var _saw_windup := false
var _health_at_crouch := 0
var _uses_touch := OS.has_feature("mobile")

func _ready() -> void:
	_wolf = game.get_node_or_null("CampDemon4")
	_beach = game.get_node("IslandExploration").checkpoint_position(0)
	var clues := CLUES.new()
	clues.landscape = game.landscape
	add_child(clues)
	_camp = clues.camp_site
	_junction = clues.junction
	_bell = AudioStreamPlayer3D.new()
	_bell.name = "DistantWarningBell"
	_bell.position = game.landscape.ground_point(Vector3(-16, 0, 16)) + Vector3.UP * 2.4
	_bell.unit_size = 11.0
	_bell.max_distance = 38.0
	_bell.volume_db = -9.0
	add_child(_bell)

func _exit_tree() -> void:
	if is_instance_valid(_bell):
		_bell.stop()
		_bell.stream = null

func _physics_process(delta: float) -> void:
	if not game.started or game.game_finished or game.player.health <= 0 or not active():
		return
	_message_time = maxf(0.0, _message_time - delta)
	var position: Vector3 = game.player.global_position
	if not has_beat(BELL) and game.seal_fragments.collected_ids.is_empty() and position.distance_to(_beach) < 10.5:
		_bell_delay -= delta
		if _bell_delay <= 0.0:
			_bell.stream = _bell_stream()
			_bell.play()
			_mark(BELL, true)
	if has_beat(CAMP) and not has_beat(JUNCTION) and not game.seal_fragments.collected_ids.is_empty() and position.distance_to(_junction) < 3.15:
		_cue(JUNCTION_LINE, 5.5)
		_mark(JUNCTION, true)
	if not has_beat(JUNCTION) and not game.seal_fragments.collected_ids.is_empty():
		_watch_wolf(position)

func active() -> bool:
	return not game.lantern_lit and not game.boss_spawned and not game.completed

static func saved_flags(world: Dictionary) -> int:
	var saved: Variant = world.get(SAVE_KEY, 0)
	return (saved & ALL_BEATS) if saved is int and saved >= 0 else 0

func has_beat(beat: int) -> bool:
	return (saved_flags(game.world_data) & beat) != 0

func _mark(beat: int, save_now := false) -> void:
	game.world_data[SAVE_KEY] = saved_flags(game.world_data) | beat
	if save_now:
		game._save_progress()

func can_inspect() -> bool:
	return active() and game.started and not game.game_finished and not get_tree().paused and game.player.health > 0 \
		and not has_beat(CAMP) and game.player.global_position.distance_to(_camp) <= 2.15

func inspect_camp() -> void:
	_cue(CAMP_FINDING, 6.0)
	_mark(CAMP, true)

func fragment_recovered() -> void:
	if not active():
		return
	var index: int = game.seal_fragments.collected_ids.size() - 1
	_cue(FRAGMENT_NOTES[index], 5.0)

func _cue(message: String, duration: float) -> void:
	_message = message
	_message_time = duration

func _watch_wolf(position: Vector3) -> void:
	if not is_instance_valid(_wolf) or _wolf.get("health") <= 0 or position.distance_squared_to(_wolf.global_position) > 116.0:
		_was_winding_up = false
		_saw_windup = false
		return
	var windup: bool = _wolf.get("_windup") > 0.0
	if not has_beat(SWORD) and _wolf.get("_alert_time") > 0.0:
		_cue("Tap Attack when it closes." if _uses_touch else "J · Strike when the wolf closes.", 3.0)
		_mark(SWORD)
	if windup and not _was_winding_up and position.distance_to(_wolf.global_position) <= 3.55:
		_saw_windup = true
		_health_at_crouch = game.player.health
		if not has_beat(DODGE) and _dodge_prompts < 2:
			_cue("Dodge sideways as it crouches." if _uses_touch else "K · Dodge sideways as it crouches.", 1.6)
			_dodge_prompts += 1
			if _dodge_prompts == 2:
				_mark(DODGE)
	if not windup and _saw_windup:
		if _wolf.get("_strike_time") > 0.0 and position.distance_to(_wolf.global_position) <= 5.0:
			if game.player.health == _health_at_crouch and game.player.get("_dodge_cooldown") > .15:
				_mark(DODGE)
			if not has_beat(COUNTER):
				_cue("Counter while it recovers.", 2.5)
				_mark(COUNTER)
		_saw_windup = false
	_was_winding_up = windup

func objective() -> Dictionary:
	if not active():
		return {}
	var seals: int = game.seal_fragments.collected_ids.size()
	var camps: int = clampi(5 - game.remaining_enemies, 0, 5)
	var title := "THE WARNING"
	var message := "Follow the ash to Tideseal Ruins."
	var guide := "The warning bell fell silent. Follow the ash southwest from the beach waystone and recover a seal fragment at Tideseal Ruins."
	var step := "Follow the ash to Tideseal Ruins."
	if seals > 0:
		title = "THE BROKEN SEAL"
		message = "Follow the roots to the camp."
		guide = "The broken ward once held something dangerous below. Follow the dark roots north of the ruins to the cold fire at the forest edge. Approach from the east to pass the wolf."
		step = "Inspect the abandoned camp."
		if has_beat(CAMP):
			title = "THE WARM ROOTS"
			message = "Find the woodland junction."
			guide = "The fire is cold. The roots are warm. Ash runs beneath the trail. Follow it east to the woodland waymark."
			step = "Reach the woodland junction."
		if has_beat(JUNCTION):
			title = "THE NORTHERN LANTERN"
			message = "Restore the Northern Lantern."
			guide = "See where the roots lead. Follow the woodland trail north toward the Northern Lantern. The seal and cleared camps are still needed to light it."
			step = "Recover the %d missing seal fragments." % (3 - seals) if seals < 3 else (
				"Clear the remaining camp wolves." if camps < 5 else "Use Interact at the Northern Lantern.")
	var progress := "Seal %d/3 · Camps %d/5" % [seals, camps]
	if has_beat(JUNCTION) and seals < 3:
		progress = "Seal %d/3 · %d missing · Camps %d/5" % [seals, 3 - seals, camps]
	return {"title": title, "message": message, "progress": progress, "guide": guide, "next": step}

func hud_hint() -> Dictionary:
	var hint := objective()
	if not hint.is_empty() and _message_time > 0.0:
		hint.message = _message
	return hint

func _bell_stream() -> AudioStreamWAV:
	const RATE := 16000
	const LENGTH := .96
	const FREQUENCIES := [196.0, 333.0, 519.0, 747.0, 1193.0]
	const GAINS := [.44, .30, .16, .10, .044]
	var samples := PackedByteArray()
	samples.resize(int(RATE * LENGTH) * 2)
	for frame in range(samples.size() / 2):
		var time := float(frame) / RATE
		var wave := 0.0
		for start in [0.0, .48]:
			var ring: float = time - start
			if ring < 0.0:
				continue
			for partial in range(FREQUENCIES.size()):
				wave += sin(TAU * FREQUENCIES[partial] * ring) * GAINS[partial] * exp(-ring * (2.4 + partial * 1.05)) * smoothstep(0.0, .016, ring)
		var cut := 1.0 - smoothstep(.885, .905, time)
		samples.encode_s16(frame * 2, roundi(clampf(wave * cut, -1.0, 1.0) * 22300.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = samples
	return stream
