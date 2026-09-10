extends SceneTree
var failures := 0
func _init() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _run() -> void:
	var scene: Node = load("res://scenes/Battle.tscn").instantiate()
	var ui: Node = scene.get_node("BattleUI")
	var grid: Node = scene.get_node("BattleManager/TacticalGrid")
	for unit_id in scene.SPRITE_PATHS:
		var path: String = scene.SPRITE_PATHS[unit_id]
		check(not FileAccess.file_exists(path), "pack fixture omits raw PNG: " + unit_id)
		check(scene._texture_from_source(path) != null, "packed battle sprite: " + unit_id)
		check(ui._texture_from_source(path) != null, "packed UI portrait: " + unit_id)
	for terrain in grid.TERRAIN_TEXTURE_PATHS:
		check(grid._texture_for_terrain(terrain) != null, "packed original terrain fallback: " + terrain)
	for prop in grid.PROP_TEXTURE_PATHS:
		check(grid._texture_for_prop(prop) != null, "packed battlefield prop: " + prop)
	scene.free()
	quit(1 if failures else 0)
