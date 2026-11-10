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

func menu_records(ui) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if not ui._ability_panel.is_visible_in_tree(): return records
	for child in ui._ability_list.get_children():
		if not child is Button or child.is_queued_for_deletion(): continue
		var record := button_record(child)
		record["ability_id"] = str(child.get_meta("ability_id", ""))
		record["magic_school"] = str(child.get_meta("magic_school", ""))
		record["text"] = child.text
		records.append(record)
	return records

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
	var focused = get_viewport().gui_get_focus_owner()
	var units: Dictionary = {}
	for id in manager.units:
		var member = manager.units[id]
		if is_instance_valid(member):
			units[id] = {"position": [member.grid_pos.x, member.grid_pos.y], "hp": member.hp, "team": member.team}
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	return {
		"schema": 2, "frame": Engine.get_process_frames(), "viewport": [viewport.x, viewport.y],
		"scene": battle.scene_file_path, "unit_count": manager.units.size(),
		"units": units,
		"phase": BattleManager.Phase.keys()[manager.current_phase], "resolving": manager.is_resolving_action,
		"selected": selection.selected_id, "command": manager.active_command,
		"review": selection.has_review(), "settings": ui._settings_overlay.visible,
		"waiting_facing": selection._waiting_facing,
		"category": ui._command_category, "school": ui._magic_school,
		"ability_id": manager.selected_ability_id,
		"menu_visible": ui._ability_panel.is_visible_in_tree(), "entries": menu_records(ui),
		"focus": {"ability_id": str(focused.get_meta("ability_id", "")),
			"magic_school": str(focused.get_meta("magic_school", ""))} if focused else {},
		"cursor": [selection.cursor_cell.x, selection.cursor_cell.y],
		"unit": {"id": unit.unit_id, "position": [unit.grid_pos.x, unit.grid_pos.y],
			"hp": unit.hp, "mp": unit.mp, "moved": manager.active_unit_has_moved,
			"acted": manager.active_unit_has_acted, "abilities": unit.unit_data.abilities.duplicate()},
		"confirm": button_record(ui._confirm_btn),
		"buttons": {"magic": button_record(ui._magic_btn), "skills": button_record(ui._ability_btn),
			"back": button_record(ui._cancel_btn), "wait": button_record(ui._wait_btn)},
	}
