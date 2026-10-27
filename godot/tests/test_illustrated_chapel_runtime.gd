extends Node

# Headless runtime smoke: real Battle.tscn and actual chapter layout, no art mock.
# Runs on isolated CI HOME/XDG paths; restores transient practice_session.

var checks := 0
var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var before: Dictionary = GameState.practice_session.duplicate(true)
	# Do not begin_practice(), which saves; route the real battle with the
	# same in-memory flags after title admission.
	GameState.practice_session = {
		"state": "playing", "mode": "zane_duel",
		"illustrated_chapel": true,
	}
	var root := preload("res://scenes/Battle.tscn").instantiate()
	add_child(root)
	await get_tree().process_frame
	await get_tree().process_frame

	var grid := root.get_node("BattleManager/TacticalGrid") as TacticalGrid
	var manager := root.get_node("BattleManager") as BattleManager
	var ui := root.get_node("BattleUI") as BattleUI

	check(grid.map_data != null and grid.map_data.id == "illustrated_chapel_practice",
		"actual battle loaded optional illustrated chapel map")
	check(grid._environment_theme_id == "ruined-chapel",
		"actual TacticalGrid picked chapel tiles")
	check(manager.units.size() == 2, "real duel maintains exactly two combat units")
	check(grid.unit_positions.has(Vector2i(4, 5)) and grid.unit_positions.has(Vector2i(6, 5)),
		"original duel unit positions are present on the painted board")
	check(is_instance_valid(ui._chapel_command_panel), "lower-left command panel exists")
	if is_instance_valid(ui._chapel_command_panel):
		check(ui._move_btn.get_parent() == ui._chapel_command_buttons,
			"move command is the real original button")
		check(ui._attack_btn.get_parent() == ui._chapel_command_buttons,
			"attack command is the real original button")
		check(ui._ability_btn.get_parent() == ui._chapel_command_buttons,
			"skill command is the real original button")
		check(ui._wait_btn.get_parent() == ui._chapel_command_buttons,
			"wait command is the real original button")
		check(ui._ability_btn.text == "Skills", "battlefield action reads Skills")
	check(ui._preview_panel.get_parent() == ui._right_panel_root,
		"forecast remains a contained neutral panel, not a fullscreen overlay")
	check(ui._preview_actor_portrait != null and ui._preview_target_portrait != null,
		"original attacker and defender portrait slots remain intact")
	check(not manager.is_resolving_action, "entering painted battle does not commit an action")
	check(grid.get_tile(Vector2i(0, 4)).get("blocks_movement", false),
		"low-wall art corresponds to an actual impassable cell")
	check(not grid.get_tile(Vector2i(5, 5)).get("blocks_movement", true),
		"center of tactical field stays walkable")

	var zane: Unit = manager.units[grid.unit_positions[Vector2i(4, 5)]]
	var portrait_path := manager._portrait_path(zane)
	check(portrait_path.ends_with("zane-portrait-illustrated.png"), "approved portrait resolves in real chapel")

	root.queue_free()
	await get_tree().process_frame
	GameState.practice_session = before
	print("Illustrated chapel runtime: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		printerr("FAIL: " + description)
