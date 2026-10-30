extends BattleUI
## Compact proof-only layout; reuses every real command/resource/forecast handler.
var _proof_skills_panel: PanelContainer

func _build_ui() -> void:
	super._build_ui()
	if not is_instance_valid(_chapel_command_panel):
		_build_chapel_command_dock()
	_loadout_panel.hide()
	_temper_label.hide()
	_ether_label.hide()
	_mission_label.hide()
	_tile_info_label.hide()
	for label in _log_labels:
		label.hide()
	for child in _right_panel_root.get_children():
		if child is HSeparator or child is TextureRect:
			child.hide()
		if child is Label and (child.text in ["ACTIVE UNIT", "YOUR NEXT ACTION", "RECENT ACTIONS"] or child.text.begins_with("TURN ORDER")):
			child.hide()
	for i in range(4, _timeline_labels.size()):
		_timeline_labels[i].get_parent().hide()
	_cancel_btn.reparent(_chapel_command_buttons)
	_cancel_btn.text = "Cancel  [Esc]"
	_cancel_btn.custom_minimum_size = Vector2(190, 56)
	_preview_panel.reparent(self)
	_preview_panel.custom_minimum_size = Vector2(500, 0)
	_preview_mode_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_note_label.max_lines_visible = 4
	_preview_note_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_active_portrait.custom_minimum_size = Vector2(64, 92)
	_preview_panel.resized.connect(_layout_forecast)
	_preview_panel.minimum_size_changed.connect(_layout_forecast)
	_chapel_command_panel.custom_minimum_size.x = 220
	for command in [_move_btn, _attack_btn, _ability_btn, _wait_btn, _cancel_btn]:
		command.custom_minimum_size = Vector2(190,56)
		command.add_theme_font_size_override("font_size", 22)
	_proof_skills_panel = PanelContainer.new()
	_proof_skills_panel.theme = _right_panel_root.theme
	_proof_skills_panel.custom_minimum_size = Vector2(350,0)
	add_child(_proof_skills_panel)
	_ability_panel.reparent(_proof_skills_panel)
	_proof_skills_panel.hide()
	for label in find_children("*", "Label", true, false):
		label.add_theme_font_size_override("font_size", maxi(22, label.get_theme_font_size("font_size")))

func _layout_persistent_hud() -> void:
	if not is_instance_valid(_right_panel_scroll): return
	var viewport := get_viewport().get_visible_rect().size
	var width := minf(400, viewport.x * 0.28)
	var height := minf(790, viewport.y - 40)
	_right_panel_bg.position = Vector2(viewport.x - width - 20, 20)
	_right_panel_bg.size = Vector2(width, height)
	_right_panel_scroll.position = _right_panel_bg.position + Vector2(12,12)
	_right_panel_scroll.size = Vector2(width - 24, height - 24)
	_right_panel_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_layout_chapel_command_dock()
	_layout_forecast()
	_layout_skills()
	if get_parent().has_method("_frame_battlefield_camera"):
		get_parent().call_deferred("_frame_battlefield_camera")

func _layout_forecast() -> void:
	if not is_instance_valid(_preview_panel): return
	var viewport := get_viewport().get_visible_rect().size
	_preview_panel.size = Vector2(500, _preview_panel.get_combined_minimum_size().y)
	_preview_panel.position = Vector2(maxf(210, viewport.x - 940), maxf(110, viewport.y - _preview_panel.size.y - 22))

func _on_action_preview_changed(preview: Dictionary) -> void:
	super._on_action_preview_changed(preview)
	if not preview.is_empty():
		_preview_mode_label.text = "FORECAST · Click highlighted tile to commit"
		_preview_note_label.tooltip_text = _preview_note_label.text
	_layout_forecast()

func _on_action_state_changed(can_move: bool, can_act: bool, has_pending: bool) -> void:
	super._on_action_state_changed(can_move, can_act, has_pending)
	if battle_manager and (battle_manager.active_command.is_empty() or battle_manager.is_resolving_action):
		_preview_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if battle_manager and not battle_manager.active_command.is_empty():
			_on_cancel()
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)

func _layout_skills() -> void:
	if not is_instance_valid(_proof_skills_panel): return
	var viewport := get_viewport().get_visible_rect().size
	_proof_skills_panel.position = Vector2(250, maxf(110, viewport.y * 0.52))

func _on_ability_panel_visibility_changed() -> void:
	if is_instance_valid(_proof_skills_panel):
		_proof_skills_panel.visible = _ability_panel.visible
	_layout_skills()

func _on_ability_mode_started(usable_ids: Array) -> void:
	super._on_ability_mode_started(usable_ids)
	for label in _ability_panel.find_children("*", "Label", true, false):
		label.add_theme_font_size_override("font_size", maxi(20, label.get_theme_font_size("font_size")))
	for row in _ability_list.get_children():
		if row is Button: row.custom_minimum_size.y = 66
	_layout_skills()
