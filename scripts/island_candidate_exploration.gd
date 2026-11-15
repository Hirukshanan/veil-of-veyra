extends "res://scripts/island_exploration.gd"

var grounded_checkpoints: Array[Vector3] = []

func _ready() -> void:
	# Keep travel/progress logic, omit every old terrain/forest/decor constructor.
	for index in range(CHECKPOINTS.size()):
		var marker := Node3D.new()
		marker.name = "Waystone%d" % index
		marker.position = CHECKPOINTS[index]
		add_child(marker)
		var visual := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 1.2
		mesh.bottom_radius = 1.2
		mesh.height = 0.08
		visual.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("bda76b")
		visual.material_override = material
		marker.add_child(visual)
		_waystone_labels.append(_label("WAYSTONE • approach to bind",CHECKPOINTS[index]+Vector3.UP*2))

func checkpoint_position(index: int) -> Vector3:
	return grounded_checkpoints[index] if grounded_checkpoints.size() == 3 else CHECKPOINTS[index]
