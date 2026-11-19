extends Node3D

const REGION := preload("res://scripts/chapter_one_region.gd")
const CAMP_SITE := Vector3(-53, 0, 29)
const SHORE_STONE := Vector3(-3.65, 0, 25.5)
const ASH_CORE := Color(.105, .083, .097, .90)
const ASH_EDGE := Color(.23, .195, .20, .0)
const SHORE_TRAIL := [
	Vector3(-4, 0, 29), Vector3(-5.4, 0, 34.4), Vector3(-12.2, 0, 39.3),
	Vector3(-20.4, 0, 43.2), Vector3(-28.9, 0, 46.1), Vector3(-36.4, 0, 48.8),
	Vector3(-42, 0, 52.3),
]
const ROOT_TRAIL := [
	Vector3(-43.9, 0, 50.7), Vector3(-44.4, 0, 43.9), Vector3(-46.1, 0, 37.7),
	Vector3(-49.4, 0, 32.4), CAMP_SITE, Vector3(-48.9, 0, 28.5),
	Vector3(-44.4, 0, 27.9), Vector3(-40.9, 0, 27.1), Vector3(-37, 0, 27),
	Vector3(-38.8, 0, 22.0), Vector3(-40.2, 0, 16.7),
]

var landscape: Node3D
var camp_site: Vector3
var junction: Vector3
var _stone: Material
var _charcoal: StandardMaterial3D
var _ash: StandardMaterial3D

func _ready() -> void:
	name = "OpeningClues"
	camp_site = landscape.ground_point(CAMP_SITE)
	junction = landscape.ground_point(REGION.WAYMARKS[0].position)
	_stone = preload("res://scripts/environment_materials.gd").surface("rocky_terrain_02", .7)
	_charcoal = StandardMaterial3D.new()
	_charcoal.albedo_color = Color(.17, .124, .113)
	_charcoal.roughness = 1.0
	_ash = StandardMaterial3D.new()
	_ash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ash.vertex_color_use_as_albedo = true
	_ash.cull_mode = BaseMaterial3D.CULL_DISABLED
	_build_shore_ruin()
	_build_fire()
	_block(self, junction + Vector3(.70, .32, -.43), Vector3(.46, .76, .45), Vector3(.09, -.39, -.13), _stone)
	var tracks := SurfaceTool.new()
	tracks.begin(Mesh.PRIMITIVE_TRIANGLES)
	_mark_trail(tracks, SHORE_TRAIL, .28)
	_mark_trail(tracks, ROOT_TRAIL, .23)
	_ground_ribbon(tracks, [camp_site + Vector3(-.95, 0, -.74), camp_site, camp_site + Vector3(.77, 0, .50)], .70)
	_ground_ribbon(tracks, [camp_site, camp_site + Vector3(.73, 0, -.9), camp_site + Vector3(1.93, 0, -1.22)], .24)
	_ground_ribbon(tracks, [camp_site, camp_site + Vector3(-1.17, 0, .61), camp_site + Vector3(-1.78, 0, 1.63)], .25)
	_add_ash(self, tracks)

func _build_shore_ruin() -> void:
	var base: Vector3 = landscape.ground_point(SHORE_STONE)
	var upright := _block(self, base + Vector3.UP * .53, Vector3(.93, 1.23, .52),
		Vector3(-.09, -.32, .09), _stone)
	_block(self, base + Vector3(.71, .11, .27), Vector3(.45, .24, .52), Vector3(.12, .77, .18), _stone)
	var stain := SurfaceTool.new()
	stain.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-.23, -.61, .268)
	var b := Vector3(-.05, -.26, .269)
	var c := Vector3(-.13, .02, .271)
	var d := Vector3(.065, .30, .272)
	var e := Vector3(.12, .58, .272)
	_ribbon(stain, a, b, Vector3.RIGHT, .19, .15)
	_ribbon(stain, b, c, Vector3.RIGHT, .15, .17)
	_ribbon(stain, c, d, Vector3.RIGHT, .17, .10)
	_ribbon(stain, d, e, Vector3.RIGHT, .10, .013)
	_ribbon(stain, c, Vector3(-.34, .30, .272), Vector3.RIGHT, .10, .01)
	_ribbon(stain, b, Vector3(.32, .03, .272), Vector3.RIGHT, .12, .014)
	_add_ash(upright, stain)

func _build_fire() -> void:
	for index in range(7):
		var angle := float(index) * TAU / 7.0
		var offset := Vector3(cos(angle), 0, sin(angle)) * (.72 + .05 * sin(float(index) * 7.3))
		var floor_point: Vector3 = landscape.ground_point(camp_site + offset)
		_block(self, floor_point + Vector3.UP * .10, Vector3(.31, .24, .28),
			Vector3(.28 * sin(angle), angle, .32 * cos(angle)), _stone)
	for index in range(3):
		_block(self, camp_site + Vector3(.09 * index, .12 + .03 * index, -.08 * index),
			Vector3(.17, .13, .77), Vector3(.10, .69 + index * 1.92, .18), _charcoal)

func _block(parent: Node3D, point: Vector3, size: Vector3, angle: Vector3, material: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	var piece := MeshInstance3D.new()
	piece.mesh = shape
	piece.material_override = material
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	piece.visibility_range_end = 45.0
	piece.position = point
	piece.rotation = angle
	parent.add_child(piece)
	return piece

func _add_ash(parent: Node3D, surface: SurfaceTool) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = _ash
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)

func _mark_trail(surface: SurfaceTool, points: Array, width: float) -> void:
	for index in range(points.size() - 1):
		var start: Vector3 = points[index]
		var finish: Vector3 = points[index + 1]
		var direction := (finish - start).normalized()
		var side := direction.cross(Vector3.UP)
		var middle := (start + finish) * .5 + side * (.30 * sin(float(index) * 2.4))
		_ground_ribbon(surface, [middle - direction * 1.30, middle, middle + direction * 1.38], width)
		_ground_ribbon(surface, [middle, middle + direction * .78 + side * .67], width * .61)

func _ground_ribbon(surface: SurfaceTool, points: Array, width: float) -> void:
	for index in range(points.size() - 1):
		var start: Vector3 = points[index]
		var finish: Vector3 = points[index + 1]
		var lateral := (finish - start).cross(Vector3.UP).normalized()
		var count := maxi(1, ceili(start.distance_to(finish) / .55))
		for segment in range(count):
			var t0 := float(segment) / count
			var t1 := float(segment + 1) / count
			var w0 := lerpf(.055 if index == 0 else width, width if index == 0 else .035, t0)
			var w1 := lerpf(.055 if index == 0 else width, width if index == 0 else .035, t1)
			_ribbon(surface, start.lerp(finish, t0), start.lerp(finish, t1), lateral, w0, w1, true)

func _ribbon(surface: SurfaceTool, a: Vector3, b: Vector3, axis: Vector3, wa: float, wb: float, ground := false) -> void:
	var points := [a - axis * wa, a, a + axis * wa, b - axis * wb, b, b + axis * wb]
	if ground:
		for index in range(points.size()):
			points[index] = landscape.ground_point(points[index]) + Vector3.UP * .049
	for index in [0, 1, 4, 0, 4, 3, 1, 2, 5, 1, 5, 4]:
		surface.set_color(ASH_CORE if index in [1, 4] else ASH_EDGE)
		surface.add_vertex(points[index])
