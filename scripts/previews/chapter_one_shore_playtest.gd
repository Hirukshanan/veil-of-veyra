extends "res://scripts/previews/chapter_one_bridge_playtest.gd"

func _build_island() -> void:
	landscape = preload("res://scripts/island_landscape.gd").new()
	landscape.terrain_data = landscape.SURFACE.duplicate()
	landscape.terrain_data.grade_estuary = true
	add_child(landscape)

func _ground_gameplay() -> void:
	super._ground_gameplay()
	var stem := CylinderMesh.new()
	stem.bottom_radius = .036
	stem.top_radius = .021
	stem.height = .444
	stem.radial_segments = 6
	stem.rings = 0
	for plant in herbs.plants:
		# Keep resolved pickup X/Z, including the safe bank placement of the river herb.
		plant.global_position = landscape.ground_point(plant.global_position)
		if plant.has_node("HarvestArea"):
			plant.position.y -= .022
		else:
			var base := MeshInstance3D.new()
			base.name = "RootedStem"
			base.mesh = stem
			base.material_override = plant.get_child(0).material_override
			base.position.y = .182
			plant.add_child(base)
