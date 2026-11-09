extends Node
## Read-only test instrumentation. This directory is absent from production exports.

func _process(_delta: float) -> void:
	if not OS.has_feature("web"):
		return
	var state = snapshot()
	if not state.is_empty():
		JavaScriptBridge.eval("window.__courtyardQA = " + JSON.stringify(state) + ";", true)

func button_record(button: BaseButton) -> Dictionary:
	var rect: Rect2 = button.get_global_rect()
	return {"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"visible": button.is_visible_in_tree(), "disabled": button.disabled}

func snapshot() -> Dictionary:
	var battle = get_tree().current_scene
	if not is_instance_valid(battle) or not (battle is BattleScene):
		return {}
	var manager = battle.battle_manager
	var ui = battle.battle_ui
	if not is_instance_valid(manager) or not is_instance_valid(ui) or not is_instance_valid(ui._selection):
		return {}
	var unit = manager.units.get(manager.active_unit_id)
	if not is_instance_valid(unit):
		return {}
	var selection = ui._selection
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	return {
		"schema": 1, "frame": Engine.get_process_frames(), "viewport": [viewport.x, viewport.y],
		"scene": battle.scene_file_path, "unit_count": manager.units.size(),
		"phase": BattleManager.Phase.keys()[manager.current_phase], "resolving": manager.is_resolving_action,
		"selected": selection.selected_id, "command": manager.active_command,
		"review": selection.has_review(), "settings": ui._settings_overlay.visible,
		"cursor": [selection.cursor_cell.x, selection.cursor_cell.y],
		"unit": {"id": unit.unit_id, "position": [unit.grid_pos.x, unit.grid_pos.y],
			"hp": unit.hp, "mp": unit.mp, "moved": manager.active_unit_has_moved,
			"acted": manager.active_unit_has_acted},
		"confirm": button_record(ui._confirm_btn),
	}
