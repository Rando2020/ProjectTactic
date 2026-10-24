extends Node
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	GameState.active_run = null
	GameState.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	var ui: BattleUI = battle.get_node("BattleUI")
	for i in range(180):
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN:
			break
		await get_tree().process_frame
	var unit: Unit = manager.units[manager.active_unit_id]
	check(unit.unit_id == "lyra", "fixture starts on Lyra as native observation")
	var origin := unit.grid_pos
	var mp := unit.mp
	ui._press_if_ready(ui._ability_btn, ui._on_ability)
	check(ui._ability_panel.visible and not ui._cancel_btn.disabled, "ability menu can be cancelled before selecting a spell")
	ui._press_if_ready(ui._cancel_btn, ui._on_cancel)
	check(not ui._ability_panel.visible, "Cancel closes the ability menu")
	ui._press_if_ready(ui._ability_btn, ui._on_ability)
	await get_tree().process_frame
	var first_ability: Button = ui._ability_list.get_child(0)
	first_ability.pressed.emit()
	check(manager.selected_ability_id == "long_shot", "actual first ability button selects Long Shot")
	check(not manager.tactical_grid.ability_tiles.is_empty(), "Long Shot displays CAST tiles")
	check(not ui._cancel_btn.disabled, "Cancel is enabled while selecting an ability target")
	ui._press_if_ready(ui._cancel_btn, ui._on_cancel)
	check(manager.active_command.is_empty() and manager.selected_ability_id.is_empty(), "UI Cancel clears pending selection")
	check(manager.tactical_grid.ability_tiles.is_empty(), "UI Cancel clears CAST tiles")
	check(unit.mp == mp and unit.grid_pos == origin and not manager.active_unit_has_acted and not manager.active_unit_has_moved, "Cancel consumes no resources or turn actions")
	ui._press_if_ready(ui._move_btn, ui._on_move)
	check(manager.active_command == "move" and manager.tactical_grid.ability_tiles.is_empty(), "exact Cancel then Move shows only movement range")
	# Also allow switching commands directly, without requiring Cancel first.
	manager.select_ability("long_shot")
	ui._press_if_ready(ui._move_btn, ui._on_move)
	check(manager.active_command == "move", "Move command accepted after targeting")
	check(manager.selected_ability_id.is_empty(), "Move clears obsolete ability selection")
	check(manager.tactical_grid.ability_tiles.is_empty(), "Move clears purple ability highlights")
	check(not manager.tactical_grid.move_tiles.is_empty(), "Move has legal GO tiles")
	print("Native tile (2,4) legal=%s; Lyra origin=%s; move range=%s" % [Vector2i(2, 4) in manager.tactical_grid.move_tiles, str(origin), str(manager.tactical_grid.move_tiles)])
	if not Vector2i(2, 4) in manager.tactical_grid.move_tiles:
		manager.tactical_grid.tile_clicked.emit(Vector2i(2, 4))
		check(unit.grid_pos == origin, "illegal native test tile does not move")
	var legal: Vector2i = manager.tactical_grid.move_tiles[0]
	manager.tactical_grid.tile_clicked.emit(legal)
	for i in range(240):
		if manager.active_unit_has_moved:
			break
		await get_tree().process_frame
	check(unit.grid_pos == legal and manager.active_unit_has_moved, "legal GO tile executes movement after ability cancellation/switch")
	check(not manager.active_unit_has_acted and unit.mp == mp, "movement leaves action and MP intact")
	battle.queue_free()
	await get_tree().process_frame
	print("Cancel/move input: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
