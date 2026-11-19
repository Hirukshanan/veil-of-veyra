extends Node

# The encounter owns when night begins and ends. Exploration always starts at dusk.
const TRANSITION_SECONDS := 3.5
const CLOUDS := preload("res://assets/environment/new_island/dusk_cloud_cover.png")
const DUSK := {
	"sun": {
		"rotation_degrees": Vector3(-16.0, -58.0, 0.0),
		"light_color": Color(1.0, .89, .80),
		"light_energy": .76,
	},
	"environment": {
		"ambient_light_color": Color(.64, .70, .84),
		"ambient_light_energy": .39,
		"fog_light_color": Color(.48, .51, .60),
		"fog_light_energy": .71,
		"fog_density": .28,
		"fog_depth_begin": 36.0,
		"fog_depth_end": 260.0,
		"fog_sun_scatter": .08,
	},
	"sky": {
		"sky_top_color": Color(.104, .151, .235),
		"sky_horizon_color": Color(.44, .49, .57),
		"ground_horizon_color": Color(.44, .49, .57),
		"sky_curve": .27,
		"sun_angle_max": 12.0,
		"sky_cover_modulate": Color(.96, .97, 1.0, .88),
	},
}
const NIGHT := {
	"sun": {
		"rotation_degrees": Vector3(-32.0, -78.0, 0.0),
		"light_color": Color(.66, .76, 1.0),
		"light_energy": .34,
	},
	"environment": {
		"ambient_light_color": Color(.57, .68, .89),
		"ambient_light_energy": .30,
		"fog_light_color": Color(.23, .29, .42),
		"fog_light_energy": .61,
		"fog_density": .25,
		"fog_depth_begin": 31.0,
		"fog_depth_end": 235.0,
		"fog_sun_scatter": .02,
	},
	"sky": {
		"sky_top_color": Color(.051, .071, .135),
		"sky_horizon_color": Color(.165, .211, .31),
		"ground_horizon_color": Color(.165, .211, .31),
		"sky_curve": .29,
		"sun_angle_max": 3.2,
		"sky_cover_modulate": Color(.40, .53, .85, .46),
	},
}

var night_weight := 0.0
var _from_night := 0.0
var _to_night := 0.0
var _elapsed := 0.0
var _duration := 0.0
var _applied_night := -1.0
var _applied_cave := -1.0
var _game: Node3D
var _targets: Dictionary
var _cave_baseline: Dictionary = {}

func initialize(game: Node3D, sun: DirectionalLight3D, environment: Environment) -> void:
	_game = game
	var sky: ProceduralSkyMaterial = environment.sky.sky_material
	_targets = {"sun": sun, "environment": environment, "sky": sky}
	for group in _targets:
		var values := {}
		for property in DUSK[group]:
			values[property] = _targets[group].get(property)
		_cave_baseline[group] = values
	# The original cave sky had no cover. At full protection the texture is transparent.
	_cave_baseline.sky.sky_cover_modulate = Color(1, 1, 1, 0)
	sky.sky_cover = CLOUDS
	_update_lighting()

func set_boss_night(enabled: bool, duration: float = TRANSITION_SECONDS) -> void:
	_from_night = night_weight
	_to_night = 1.0 if enabled else 0.0
	_elapsed = 0.0
	_duration = maxf(0.0, duration)
	if _duration == 0.0:
		night_weight = _to_night
		_update_lighting()

func _process(delta: float) -> void:
	if _elapsed < _duration:
		_elapsed = minf(_elapsed + delta, _duration)
		night_weight = lerpf(_from_night, _to_night, smoothstep(0.0, _duration, _elapsed))
	_update_lighting()

func _update_lighting() -> void:
	var cave := _cave_weight()
	if cave == _applied_cave and (cave == 1.0 or night_weight == _applied_night):
		return
	_applied_cave = cave
	_applied_night = night_weight
	for group in _targets:
		var target: Object = _targets[group]
		for property in DUSK[group]:
			var value: Variant = _cave_baseline[group][property]
			if cave < 1.0:
				var exterior: Variant = lerp(DUSK[group][property], NIGHT[group][property], night_weight)
				value = lerp(exterior, value, cave)
			target.set(property, value)

func _cave_weight() -> float:
	if is_instance_valid(_game.awakening) and _game.awakening.active:
		return 1.0
	var position: Vector3 = _game.player.global_position
	# Follow the bend of the existing eastern cavern and leave its outdoor approach in dusk.
	var axis := lerpf(76.0, 65.0, smoothstep(6.0, 24.0, position.z))
	var across := 1.0 - smoothstep(11.0, 18.0, absf(position.x - axis))
	var entry := smoothstep(-14.0, -5.0, position.z)
	var rear := 1.0 - smoothstep(70.0, 78.0, position.z)
	var under_ridge := 1.0 - smoothstep(5.9, 8.5, position.y)
	return across * entry * rear * under_ridge
