extends SceneTree

const AssetRegistryScript := preload("res://scripts/data/AssetRegistry.gd")

var _passes := 0
var _failures := 0


func _initialize() -> void:
	var manifest := AssetRegistryScript.get_manifest()
	_expect_eq(int(manifest.get("schema_version", 0)), 1, "manifest schema is v1")
	var footprint: Dictionary = manifest.get("tile_footprint", {})
	_expect_eq(Vector2i(int(footprint.get("width", 0)), int(footprint.get("height", 0))), Vector2i(96, 48), "tile footprint is 96 x 48")

	for terrain_id in ["grass", "grass_flowers", "road", "stone", "high_ground", "shallow_water"]:
		var candidates := AssetRegistryScript.get_environment_candidates("forgotten-field", "terrain", terrain_id)
		_expect_true(candidates.size() == 2, "%s has preferred and fallback paths" % terrain_id)
		_expect_true(candidates.size() > 0 and FileAccess.file_exists(candidates[0]), "%s preferred art exists" % terrain_id)
		_expect_true(AssetRegistryScript.load_first_texture(candidates) != null, "%s resolves to a texture" % terrain_id)

	for overlay_id in ["selected", "move", "attack", "ability"]:
		var candidates := AssetRegistryScript.get_overlay_candidates("forgotten-field", overlay_id)
		_expect_true(candidates.size() == 2, "%s overlay has preferred and fallback paths" % overlay_id)
		_expect_true(candidates.size() > 0 and FileAccess.file_exists(candidates[0]), "%s overlay art exists" % overlay_id)
		_expect_true(AssetRegistryScript.load_first_texture(candidates) != null, "%s overlay resolves to a texture" % overlay_id)

	for team_id in ["player", "enemy"]:
		var candidates := AssetRegistryScript.get_unit_indicator_candidates(team_id)
		_expect_true(candidates.size() == 1, "%s indicator is optional and manifest-backed" % team_id)
		_expect_true(AssetRegistryScript.load_first_texture(candidates) != null, "%s indicator resolves to a texture" % team_id)

	var fallback_texture := AssetRegistryScript.load_first_texture([
		"res://assets/does-not-exist/intentional-missing-file.png",
		"res://assets/environments/forgotten-field/tiles/environment-forgotten-field-grass-tile-v01.png",
	])
	_expect_true(fallback_texture != null, "missing preferred file falls back without failure")

	if _failures > 0:
		push_error("Asset manifest test failed: %d failure(s), %d pass(es)" % [_failures, _passes])
		quit(1)
		return

	print("Asset manifest contract: OK (%d assertions)" % _passes)
	quit(0)


func _expect_true(value: bool, label: String) -> void:
	if value:
		_passes += 1
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _expect_eq(actual: Variant, expected: Variant, label: String) -> void:
	_expect_true(actual == expected, "%s | expected=%s actual=%s" % [label, str(expected), str(actual)])
