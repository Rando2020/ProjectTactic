extends Node
## Test-only observer. Staged for QA export; never part of the production project.
## No commands, setters, synthetic Godot input, or callable JavaScript callbacks.

@onready var battle: BattleScene = get_parent()

func _process(_delta: float) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__projectTacticQA = " + JSON.stringify(snapshot()) + ";", true)

func _point(value: Vector2) -> Array:
	return [value.x, value.y]

func _label(label: Label) -> Dictionary:
	return {"instance_id": str(label.get_instance_id()),
		"text": label.text, "visible": label.is_visible_in_tree()}

func _button(button: Button) -> Dictionary:
	var labels: Array[String] = [button.text]
	for label: Label in button.find_children("*", "Label", true, false):
		labels.append(label.text)
	var transform := button.get_global_transform_with_canvas()
	var start: Vector2 = transform * Vector2.ZERO
	var end: Vector2 = transform * button.size
	return {
		"rect": [start.x, start.y, end.x - start.x, end.y - start.y],
		"visible": button.is_visible_in_tree(),
		"disabled": button.disabled, "labels": labels,
	}

func snapshot() -> Dictionary:
	var manager: BattleManager = battle.battle_manager
	var ui: BattleUI = battle.battle_ui
	var grid: TacticalGrid = battle.tactical_grid
	var unit: Unit = manager.units.get(manager.active_unit_id)
	var unit_state := {}
	if is_instance_valid(unit):
		unit_state = _unit_record(unit)
		unit_state["moved"] = manager.active_unit_has_moved
		unit_state["acted"] = manager.active_unit_has_acted
	var roster := {}
	for candidate: Unit in manager.units.values():
		if is_instance_valid(candidate):
			roster[str(candidate.get_instance_id())] = _unit_record(candidate)
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
		"schema": 2, "frame": Engine.get_process_frames(),
		"viewport": _point(get_viewport().get_visible_rect().size),
		"phase": BattleManager.Phase.keys()[manager.current_phase],
		"unit": unit_state, "roster": roster, "player_turn_serial": manager._player_turn_serial,
		"active_hud": {"name": _label(ui._unit_name), "mp": _label(ui._mp_label)},
		"command": manager.active_command,
		"ability_id": manager.selected_ability_id, "resolving": manager.is_resolving_action,
		"menu_visible": ui._ability_panel.is_visible_in_tree(),
		"intro_visible": ui._intro_banner.is_visible_in_tree(),
		"buttons": {"ability": _button(ui._ability_btn), "cancel": _button(ui._cancel_btn), "move": _button(ui._move_btn), "attack": _button(ui._attack_btn)},
		"abilities": abilities, "legal_moves": legal_moves,
		"highlights": {"ability": grid.ability_tiles.size(), "move": grid.move_tiles.size(),
			"attack": grid.attack_tiles.size(), "aoe": grid.aoe_preview_tiles.size(), "path": grid.path_preview_tiles.size()},
	}

func _unit_record(unit: Unit) -> Dictionary:
	return {
		"instance_id": str(unit.get_instance_id()), "id": unit.unit_id,
		"position": [unit.grid_pos.x, unit.grid_pos.y], "hp": unit.hp, "mp": unit.mp,
	}
