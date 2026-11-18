extends Resource

# Blender-exported signed height deltas on the candidate's 1.25 m triangle grid.
const SPACING := 1.25

@export var origin: Vector2
@export var columns: int
@export var rows: int
@export var heights: PackedFloat32Array

func sample(point: Vector2) -> float:
	var grid := (point - origin) / SPACING
	if grid.x <= 0.0 or grid.y <= 0.0 or grid.x >= columns - 1 or grid.y >= rows - 1:
		return 0.0
	var x := floori(grid.x)
	var z := floori(grid.y)
	var u := grid.x - x
	var v := grid.y - z
	var a := heights[z * columns + x]
	var b := heights[z * columns + x + 1]
	var c := heights[(z + 1) * columns + x]
	var d := heights[(z + 1) * columns + x + 1]
	if u + v <= 1.0:
		return a + (b - a) * u + (c - a) * v
	return d + (c - d) * (1.0 - u) + (b - d) * (1.0 - v)
