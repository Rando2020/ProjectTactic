extends "res://prototypes/isometric/BattleUI.gd"
## Isolated reference HUD. Reparents the real combat controls; never issues proxy actions.
signal rail_layout_changed
var tester_collapsed := false
var _bloom_objective_panel: PanelContainer
var _bloom_active_panel: PanelContainer
var _bloom_turn_strip: HBoxContainer
var _bloom_command_row: GridContainer
var _bloom_rail_toggle: Button
var _bloom_skin_toggle: Button
var _bloom_mp_bar: ProgressBar
var _bloom_armor: Label
var _bloom_hint: Label
var _bloom_ready := false
var _bloom_move_forecast := false
var _bloom_last_area := Rect2()

class BloomingSelection extends "res://prototypes/isometric/SelectionController.gd":
	func layout_popup() -> void:
		if is_instance_valid(ui): ui.call("_layout_bloom_commands")
	func refresh() -> void:
		super.refresh()
		if is_instance_valid(_header): _header.visible = not can_command()
		if is_instance_valid(_inspect): _inspect.visible = not can_command()
		if is_instance_valid(_help):
			_help.hide()
			ui._bloom_hint.text = _help.text
	func go_back() -> void:
		super.go_back()
		# Never leave Enter poised to end the turn after cancelling a target.
		if can_command():
			var focus := ui.get_viewport().gui_get_focus_owner()
			if focus: focus.release_focus()
			for button: Button in [ui._move_btn, ui._attack_btn, ui._ability_btn]:
				if button.visible and not button.disabled:
					button.grab_focus()
					break

func _make_selection_controller() -> Node:
	return BloomingSelection.new()

func _surface() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20212af2")
	style.border_color = Color("b69a67")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	return style

func _panel(id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = id
	panel.add_theme_stylebox_override("panel", _surface())
	add_child(panel)
	return panel

func _compact_label(label: Label, font_size: int = 16) -> void:
	label.add_theme_color_override("font_color", Color("eee4cf"))
	label.add_theme_font_size_override("font_size", font_size)
	label.custom_minimum_size = Vector2.ZERO
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _build_ui() -> void:
	super._build_ui()
	_bloom_objective_panel = _panel("BloomingObjective")
	var objective := VBoxContainer.new()
	_bloom_objective_panel.add_child(objective)
	_mission_label.reparent(objective)
	_mission_label.show()
	_mission_label.text = "THE BLOOMING RUINS"
	_compact_label(_mission_label,18)
	_objective_label.reparent(objective)
	_compact_label(_objective_label,15)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.custom_minimum_size.y = 28
	_objective_label.text = "Defeat both enemies"

	_bloom_turn_strip = HBoxContainer.new()
	_bloom_turn_strip.name = "BloomingPortraitTimeline"
	_bloom_turn_strip.add_theme_constant_override("separation",5)
	add_child(_bloom_turn_strip)
	_turn_portraits.hide()
	for row in _turn_rows:
		row.panel.reparent(_bloom_turn_strip)
		row.panel.custom_minimum_size = Vector2(60,78)
		row.portrait.reparent(row.panel)
		# Keep old text container alive for authoritative queue and forecast updates.
		row.who.get_parent().get_parent().hide()
		row.portrait.custom_minimum_size = Vector2(48,56)
		row.portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.when.reparent(row.panel)
		row.when.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		row.when.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_compact_label(row.when,12)
		row.when.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_bloom_active_panel = _panel("BloomingActiveUnit")
	var active := HBoxContainer.new()
	active.add_theme_constant_override("separation",10)
	_bloom_active_panel.add_child(active)
	_active_portrait.reparent(active)
	_active_portrait.custom_minimum_size = Vector2(72,100)
	var stats := VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active.add_child(stats)
	for control in [_unit_name,_hp_label,_hp_bar,_mp_label]:
		control.reparent(stats)
		control.custom_minimum_size = Vector2.ZERO
		if control is Label: _compact_label(control,18 if control == _unit_name else 15)
	_unit_name.custom_minimum_size.y = 24
	_unit_name.max_lines_visible = 2
	_hp_bar.custom_minimum_size.y = 8
	_hp_bar.show_percentage = false
	_bloom_mp_bar = ProgressBar.new()
	_bloom_mp_bar.custom_minimum_size.y = 6
	_bloom_mp_bar.show_percentage = false
	stats.add_child(_bloom_mp_bar)
	_bloom_armor = Label.new()
	_compact_label(_bloom_armor,12)
	stats.add_child(_bloom_armor)
	_bloom_armor.hide()
	for bar in [_hp_bar,_bloom_mp_bar]:
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("83a77b") if bar == _hp_bar else Color("7496ba")
		bar.add_theme_stylebox_override("fill",fill)
		var background := StyleBoxFlat.new()
		background.bg_color = Color("12151c")
		bar.add_theme_stylebox_override("background",background)
	_bloom_hint = Label.new()
	_bloom_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compact_label(_bloom_hint,15)
	add_child(_bloom_hint)

	_bloom_command_row = GridContainer.new()
	_bloom_command_row.columns = 4
	_bloom_command_row.name = "BloomingCommands"
	_bloom_command_row.add_theme_constant_override("separation",5)
	_chapel_command_buttons.add_child(_bloom_command_row)
	_chapel_command_panel.custom_minimum_size = Vector2.ZERO
	_chapel_command_panel.add_theme_stylebox_override("panel",_surface())
	var index := 0
	for button: Button in [_move_btn,_attack_btn,_ability_btn,_wait_btn]:
		button.reparent(_bloom_command_row)
		button.text = ["Move","Attack","Skills","Wait"][index]
		button.custom_minimum_size = Vector2(86,52)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_font_size_override("font_size",17)
		button.icon = null
		var icon_path := "res://assets/environments/blooming-ruins-v2/%s.svg" % ["move","attack","skill","wait"][index]
		if ResourceLoader.exists(icon_path): button.icon = load(icon_path)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",22)
		for state in ["normal","hover","pressed","focus","disabled"]:
			var style := _surface()
			style.bg_color = Color("403b38") if state in ["hover","focus"] else Color("252730")
			if state == "disabled": style.border_color = Color("5c574c")
			button.add_theme_stylebox_override(state,style)
		button.add_theme_color_override("font_color",Color("f2e7d1"))
		index += 1
	_cancel_btn.custom_minimum_size = Vector2(0,30)
	_cancel_btn.add_theme_font_size_override("font_size",15)
	_chapel_command_buttons.move_child(_cancel_btn,_chapel_command_buttons.get_child_count()-1)
	_chapel_command_buttons.get_child(0).hide()
	_bloom_rail_toggle = Button.new()
	_bloom_rail_toggle.name = "TesterRailToggle"
	_bloom_rail_toggle.tooltip_text = "Collapse or expand the tester / intent rail"
	_bloom_rail_toggle.pressed.connect(func(): set_tester_collapsed(not tester_collapsed))
	add_child(_bloom_rail_toggle)
	var rail_title := Label.new()
	rail_title.text = "TESTER / INTENT"
	_compact_label(rail_title,18)
	_right_panel_root.add_child(rail_title)
	_right_panel_root.move_child(rail_title,0)
	var view_label := Label.new()
	view_label.text = "Fixed courtyard view"
	_compact_label(view_label,15)
	_right_panel_root.add_child(view_label)
	_right_panel_root.move_child(view_label,1)
	_bloom_skin_toggle = Button.new()
	_bloom_skin_toggle.name = "CharacterAppearanceToggle"
	_bloom_skin_toggle.custom_minimum_size.y = 34
	_bloom_skin_toggle.tooltip_text = "Switch between the existing Compact and Original character appearances"
	_bloom_skin_toggle.pressed.connect(func():
		var scene := get_parent()
		if scene.has_method("set_compact_skins"):
			scene.set_compact_skins(not bool(GameState.practice_session.get("compact_skins",true)))
		_refresh_appearance_control())
	_right_panel_root.add_child(_bloom_skin_toggle)
	_right_panel_root.move_child(_bloom_skin_toggle,2)
	_refresh_appearance_control()
	for label in _right_panel_root.find_children("*","Label",true,false):
		_compact_label(label,16)
	_right_panel_root.add_theme_constant_override("separation",7)
	_build_compact_forecast()
	# Text and visibility changes update container minima on the next frame.
	# Re-anchor the bottom band after those measurements settle.
	for content in [_bloom_active_panel, _bloom_objective_panel, _chapel_command_buttons]:
		content.minimum_size_changed.connect(func(): _layout_persistent_hud.call_deferred())
	_bloom_ready = true
	_layout_persistent_hud()

func _process(_delta: float) -> void:
	_refresh_appearance_control()

func _refresh_appearance_control() -> void:
	if not is_instance_valid(_bloom_skin_toggle): return
	_bloom_skin_toggle.text = "Characters: %s ↔" % ("Compact" if bool(GameState.practice_session.get("compact_skins",true)) else "Original")
	_bloom_skin_toggle.disabled = battle_manager != null and battle_manager.is_resolving_action

func _build_compact_forecast() -> void:
	# Put the decision on the first page of the existing scroll view. The
	# portraits and repeated instructions must not squeeze the action/HP result.
	var center := _preview_mode_label.get_parent()
	var summary := VBoxContainer.new()
	summary.add_theme_constant_override("separation",5)
	_forecast_content.add_child(summary)
	_forecast_content.move_child(summary,0)
	for label in [_preview_action_label,_preview_target_label]:
		label.reparent(summary)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size",17)
		label.custom_minimum_size.y = 0
	_preview_actor_label.reparent(center)
	_preview_actor_label.add_theme_font_size_override("font_size",17)
	_preview_actor_label.custom_minimum_size.y = 54
	var results := HBoxContainer.new()
	results.add_theme_constant_override("separation",18)
	summary.add_child(results)
	for label in [_preview_amount_label,_preview_hit_label,_preview_crit_label]:
		label.reparent(results)
		label.add_theme_font_size_override("font_size",22 if label == _preview_amount_label else 17)
		label.custom_minimum_size.y = 28
	_preview_mode_label.reparent(_forecast_content)
	_forecast_content.move_child(_preview_mode_label,1)
	_preview_mode_label.add_theme_font_size_override("font_size",17)
	_preview_mode_label.custom_minimum_size.y = 22
	_preview_note_label.reparent(_forecast_content)
	# Status/counter warnings and tactical detail come before decorative portraits
	# and repeated instructions when the player scrolls beyond the summary.
	_forecast_content.move_child(_preview_note_label,1)
	_preview_note_label.add_theme_font_size_override("font_size",17)
	_preview_note_label.max_lines_visible = -1
	_preview_note_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_preview_note_label.custom_minimum_size.y = 44
	var connections := HBoxContainer.new()
	connections.add_theme_constant_override("separation",20)
	_forecast_content.add_child(connections)
	for label in [_preview_connection_label,_preview_intent_label]:
		label.reparent(connections)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size",16)
		label.custom_minimum_size.y = 44
	_preview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_preview_panel.add_theme_stylebox_override("panel",_surface())

func gameplay_rect(viewport_size: Vector2) -> Rect2:
	var factor: float = UISettings.shared().effective_scale(viewport_size)
	var rail_width := 48.0 * factor if tester_collapsed else clampf(viewport_size.x * 0.23,240,320 * factor)
	return Rect2(Vector2.ZERO,Vector2(maxf(1,viewport_size.x-rail_width-12),viewport_size.y))

func set_tester_collapsed(collapsed: bool) -> void:
	tester_collapsed = collapsed
	_layout_persistent_hud()

func _layout_persistent_hud() -> void:
	if not _bloom_ready: return
	var viewport := get_viewport().get_visible_rect().size
	UISettings.shared().apply_tree(self, viewport)
	var factor: float = UISettings.shared().effective_scale(viewport)
	var area := gameplay_rect(viewport)
	_objective_label.custom_minimum_size.y = 36 * factor
	var rail_x := area.end.x + 8
	_right_panel_bg.visible = not tester_collapsed
	_right_panel_scroll.visible = not tester_collapsed
	_right_panel_bg.position = Vector2(rail_x,56 * factor)
	_right_panel_bg.size = Vector2(viewport.x-rail_x-8,viewport.y-56 * factor-8)
	_right_panel_scroll.position = _right_panel_bg.position + Vector2(8,8)
	_right_panel_scroll.size = _right_panel_bg.size - Vector2(16,16)
	_bloom_rail_toggle.text = "‹" if tester_collapsed else "TESTER / INTENT   ›"
	_bloom_rail_toggle.position = Vector2(rail_x,8)
	_bloom_rail_toggle.size = Vector2(viewport.x-rail_x-8,44 * factor)
	_bloom_objective_panel.position = Vector2(12,12)
	_bloom_objective_panel.size = Vector2(minf(300 * factor,area.size.x*0.45),96 * factor)
	_bloom_turn_strip.position = Vector2(maxf(_bloom_objective_panel.get_rect().end.x+12,(area.size.x-320)*0.5),12)
	_bloom_turn_strip.size = Vector2(320,78)
	if _bloom_turn_strip.position.x + 320 > area.end.x-12:
		_bloom_turn_strip.position.x = area.end.x-332
	_bloom_active_panel.size = Vector2(330 * factor, maxf(160 * factor, _bloom_active_panel.get_combined_minimum_size().y))
	_bloom_active_panel.position = Vector2(12,viewport.y-_bloom_active_panel.size.y-12)
	_bloom_hint.position = Vector2(12, _bloom_objective_panel.get_rect().end.y+8)
	_bloom_hint.size = Vector2(area.size.x-24,32 * factor)
	_layout_bloom_commands()
	_layout_skills()
	_layout_forecast()
	if area != _bloom_last_area:
		_bloom_last_area = area
		rail_layout_changed.emit()

func _layout_chapel_command_dock() -> void:
	if _bloom_ready: _layout_bloom_commands()

func _layout_bloom_commands() -> void:
	if not _bloom_ready: return
	var area := gameplay_rect(get_viewport().get_visible_rect().size)
	var minimum_x := _bloom_active_panel.get_rect().end.x+10
	var width := minf(640,area.end.x-minimum_x-12)
	var x := maxf(minimum_x,(area.size.x-width)*0.5)
	var factor: float = UISettings.shared().effective_scale(get_viewport().get_visible_rect().size)
	# Wrap the real buttons, rather than letting their minimum widths overflow.
	_bloom_command_row.columns = 2 if width < 540 * factor else 4
	for button: Button in [_move_btn,_attack_btn,_ability_btn,_wait_btn]:
		button.custom_minimum_size.x = 0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var height := maxf(108 * factor, _chapel_command_buttons.get_combined_minimum_size().y + 16)
	_chapel_command_panel.position = Vector2(x,area.end.y-height-12)
	_chapel_command_panel.size = Vector2(width,height)
	_layout_skills()

func _bloom_content_bottom() -> float:
	return minf(_bloom_active_panel.position.y, _chapel_command_panel.position.y) - 12

func _bloom_content_top() -> float:
	return _bloom_hint.get_rect().end.y + 8

func _layout_skills() -> void:
	if not _bloom_ready or not is_instance_valid(_proof_skills_panel): return
	var area := gameplay_rect(get_viewport().get_visible_rect().size)
	var width := minf(430,area.size.x-24)
	var bottom := _bloom_content_bottom()
	var available_height := maxf(80,bottom-_bloom_content_top())
	if area.size.x < 900 and _preview_panel.visible and _proof_skills_panel.visible:
		available_height = maxf(60,(available_height-8)*0.5)
	var height := minf(_ability_panel.get_combined_minimum_size().y+24,available_height)
	_proof_skills_panel.position = Vector2(area.end.x-width-12,bottom-height)
	_proof_skills_panel.size = Vector2(width,height)

func _on_action_preview_changed(preview: Dictionary) -> void:
	_bloom_move_forecast = str(preview.get("mode", "")) == "Move"
	super._on_action_preview_changed(preview)
	# Preserve every authoritative identity, HP and KO value, using the available
	# row width instead of spending three lines on the TARGET prefix.
	_preview_target_label.text = _preview_target_label.text.replace("\n", " · ")

func _layout_forecast() -> void:
	if not _bloom_ready or not is_instance_valid(_forecast_content): return
	var area := gameplay_rect(get_viewport().get_visible_rect().size)
	var bottom := _bloom_content_bottom()
	var width := minf(680 if _bloom_move_forecast else 840,area.size.x-24)
	# Keep the original forecast top clear of retargetable board cells as
	# the resource/command band grows. Overflow stays in the real scroll view.
	var forecast_top := maxf(_bloom_content_top(), area.end.y - 418)
	var height := minf(180 if _bloom_move_forecast else 270,maxf(80,bottom-forecast_top))
	var x := 12.0
	var y := bottom-height
	if _proof_skills_panel.visible:
		if area.size.x >= 900:
			width = minf(840,area.size.x-466)
		else:
			width = minf(430,area.size.x-24)
			x = area.end.x-width-12
			height = maxf(60,(bottom-_bloom_content_top()-8)*0.5)
			y = _bloom_content_top()
	_preview_panel.position = Vector2(x,y)
	_preview_panel.size = Vector2(width,height)
	_layout_skills()

func _refresh_preview_connections() -> void:
	super._refresh_preview_connections()
	for row in _turn_rows:
		var full := str(row.when.text)
		row.when.text = full.split("  ·  ")[0].replace("NEXT ","")
		if bool(row.panel.get_meta("preview_affected",false)): row.when.text += " •"

func _refresh_active_resources() -> void:
	super._refresh_active_resources()
	if is_instance_valid(_bloom_mp_bar) and battle_manager:
		var unit = battle_manager.units.get(battle_manager.active_unit_id)
		if is_instance_valid(unit):
			_bloom_mp_bar.max_value = maxf(1,float(unit.unit_data.base_stats.mp))
			_bloom_mp_bar.value = unit.mp
			_bloom_armor.text = "Armor · TMP %d / ETH %d" % [unit.temper,unit.ether]
			_bloom_armor.visible = unit.temper > 0 or unit.ether > 0

func _on_battle_started(display_name: String, objective: String) -> void:
	# The persistent objective already introduces this scene. The inherited
	# transient banner occupies the same top-left space as the objective/hint.
	_objective_label.text = objective
	_intro_banner.hide()
	_mission_label.text = "THE BLOOMING RUINS"

func _unhandled_input(event: InputEvent) -> void:
	# Escape keeps backing out of combat first. From the unselected board it
	# reaches the existing settings panel instead of becoming a dead key.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _settings_overlay.visible or (_selection and _selection.selected_id.is_empty()):
			_toggle_settings_overlay()
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)

func _toggle_settings_overlay() -> void:
	super._toggle_settings_overlay()
	if _settings_overlay.visible:
		# Blooming's persistent HUD is created after the inherited overlay.
		# Keep the modal above it so clicks cannot reach combat controls.
		move_child(_settings_overlay, get_child_count() - 1)
