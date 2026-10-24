extends Node
## Test-only observer. Staged for QA export; never part of the production project.
## No commands, setters, synthetic Godot input, or callable JavaScript callbacks.

@onready var battle: BattleScene = get_parent()

func _process(_delta: float) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__projectTacticQA = " + JSON.stringify(snapshot()) + ";", true)

func _point(value: Vector2) -> Array:
	return [value.x, value.y]

func _button(button: Button) -> Dictionary:
	var transform := button.get_global_transform_with_canvas()
	var start: Vector2 = transform * Vector2.ZERO
	var end: Vector2 = transform * button.size
	return {
		"rect": [start.x, start.y, end.x - start.x, end.y - start.y],
		"visible": button.is_visible_in_tree(),
		"disabled": button.disabled,
	}

func snapshot() -> Dictionary:
	var manager: BattleManager = battle.battle_manager
	var ui: BattleUI = battle.battle_ui
	var grid: TacticalGrid = battle.tactical_grid
	var unit: Unit = manager.units.get(manager.active_unit_id)
	var unit_state := {}
	if unit:
		unit_state = {
			"id": unit.unit_id, "position": [unit.grid_pos.x, unit.grid_pos.y],
			"hp": unit.hp, "mp": unit.mp,
			"moved": manager.active_unit_has_moved, "acted": manager.active_unit_has_acted,
		}
	var abilities: Array = []
	for child in ui._ability_list.get_children():
		if child is Button and not child.is_queued_for_deletion():
			abilities.append(_button(child))
	var legal_moves: Array = []
	for pos: Vector2i in grid.move_tiles:
		if grid.unit_positions.has(pos):
			continue
		var center: Vector2 = grid.get_global_transform_with_canvas() * grid._grid_to_local(pos)
		legal_moves.append({"position": [pos.x, pos.y], "point": _point(center)})
	return {
		"schema": 1, "frame": Engine.get_process_frames(),
		"viewport": _point(get_viewport().get_visible_rect().size),
		"phase": BattleManager.Phase.keys()[manager.current_phase],
		"unit": unit_state, "command": manager.active_command,
		"ability_id": manager.selected_ability_id, "resolving": manager.is_resolving_action,
		"menu_visible": ui._ability_panel.is_visible_in_tree(),
		"intro_visible": ui._intro_banner.is_visible_in_tree(),
		"buttons": {"ability": _button(ui._ability_btn), "cancel": _button(ui._cancel_btn), "move": _button(ui._move_btn)},
		"abilities": abilities, "legal_moves": legal_moves,
		"highlights": {"ability": grid.ability_tiles.size(), "move": grid.move_tiles.size(),
			"attack": grid.attack_tiles.size(), "aoe": grid.aoe_preview_tiles.size(), "path": grid.path_preview_tiles.size()},
	}
