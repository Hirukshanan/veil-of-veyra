extends RefCounted

# Separated, broad hills: x, z, footprint radius, summit height.
const PEAKS := [
	Vector4(-56,-45,23,9), Vector4(39,-55,24,10),
	Vector4(69,1,18,6), Vector4(-64,18,21,7),
	Vector4(8,67,22,8), Vector4(-18,-74,20,7)
]

static func height_at(point: Vector2) -> float:
	var height := 0.0
	for hill in PEAKS:
		var distance: float = point.distance_to(Vector2(hill.x,hill.y))/hill.z
		if distance < 1.0:
			height=maxf(height,hill.w*0.5*(1.0+cos(PI*distance)))
	return height
