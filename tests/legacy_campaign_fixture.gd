extends RefCounted

const CAMPAIGN := preload("res://scripts/campaign.gd")
const FIXTURE := "user://legacy_campaign_fixture.tscn"
static var _packed: PackedScene

static func instantiate() -> Node:
	if _packed == null:
		var legacy := Node3D.new()
		legacy.name = "Main"
		legacy.set_script(CAMPAIGN)
		var packed := PackedScene.new()
		var result := packed.pack(legacy)
		legacy.free()
		assert(result == OK)
		# Some legacy checks exercise reload_current_scene(). Give the fixture
		# a reloadable path in the isolated test profile.
		assert(ResourceSaver.save(packed, FIXTURE) == OK)
		_packed = packed
	var scene := _packed.instantiate()
	scene.scene_file_path = FIXTURE
	return scene
