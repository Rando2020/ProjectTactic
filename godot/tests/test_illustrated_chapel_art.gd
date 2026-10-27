extends SceneTree

# Real Godot resource/import and map acceptance for the illustrative art lane.
# This test never starts a battle, changes user:// data, or replaces the duel.

const SceneScript := preload("res://scripts/battle/BattleScene.gd")
const Registry := preload("res://scripts/data/AssetRegistry.gd")

var passed := 0
var failures: Array[String] = []


func _initialize() -> void:
	var stage := SceneScript.new()
	var map: MapData = stage._create_illustrated_chapel_map()
	_check(map.id == "illustrated_chapel_practice", "art lane has its own map ID")
	_check(map.environment_theme_id == "ruined-chapel", "painted environment theme is opt-in")
	_check(map.map_width == 10 and map.map_height == 8, "stable ten by eight tactical footprint")
	_check(map.objective_type == "defeat_all", "combat objective remains canonical")

	var blocked: Dictionary = {}
	for entry: Dictionary in map.tile_overrides:
		var p := Vector2i(int(entry.x), int(entry.y))
		_check(p.x >= 0 and p.x < map.map_width and p.y >= 0 and p.y < map.map_height, "tile override is in bounds")
		if str(entry.get("terrain", "")) == "wall":
			blocked[p] = true
	_check(not blocked.has(Vector2i(4, 5)) and not blocked.has(Vector2i(6, 5)),
		"both original Zane duel spawn coordinates stay unblocked")
	_check(blocked.has(Vector2i(0, 4)) and blocked.has(Vector2i(9, 4)),
		"decorative low walls are truthful blocking terrain")

	for terrain_id in ["stone", "cracked_stone", "high_ground", "wall"]:
		var candidates: Array[String] = Registry.get_environment_candidates("ruined-chapel", "terrain", terrain_id)
		_check(not candidates.is_empty(), terrain_id + " is in asset manifest")
		_check(ResourceLoader.exists(candidates[0], "Texture2D"), terrain_id + " art imports in Godot")
	for prop_id in ["chapel_arch", "chapel_pillar", "chapel_wall", "chapel_torch"]:
		var candidates: Array[String] = Registry.get_environment_candidates("ruined-chapel", "props", prop_id)
		_check(not candidates.is_empty(), prop_id + " is manifest backed")
		_check(ResourceLoader.exists(candidates[0], "Texture2D"), prop_id + " art imports in Godot")

	stage.free()
	if not failures.is_empty():
		for message in failures:
			push_error(message)
		quit(1)
		return
	print("Illustrated chapel art: %d checks, 0 failures" % passed)
	quit(0)


func _check(ok: bool, message: String) -> void:
	passed += 1
	if not ok:
		failures.append(message)
