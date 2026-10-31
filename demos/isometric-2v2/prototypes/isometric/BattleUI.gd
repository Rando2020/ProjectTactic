extends BattleUI
## Compact proof-only layout; reuses every real command/resource/forecast handler.
var _proof_skills_panel: PanelContainer
var _selection: Node
var _turn_portraits: VBoxContainer
var _turn_rows: Array[Dictionary] = []

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
	# Replace the buried text-only grid with a visible portrait queue.
	_timeline_labels[0].get_parent().get_parent().hide()
	_build_turn_portraits()
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
	_preview_panel.position = Vector2(20, 145)

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
	if _selection: _selection.refresh.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if _selection and _selection.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	# Shortcuts are only available after explicitly selecting the active ally.
	if _selection and _selection.can_command() and not _selection.is_targeting():
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
	if _selection:
		_selection.refresh.call_deferred()
		if _ability_list.get_child_count() > 0:
			_ability_list.get_child(0).grab_focus.call_deferred()

func setup(manager: BattleManager) -> void:
	super.setup(manager)
	_selection = preload("res://prototypes/isometric/SelectionController.gd").new()
	add_child(_selection)
	_selection.setup(self, manager)

func _layout_chapel_command_dock() -> void:
	if _selection:
		_selection.layout_popup()
	else:
		super._layout_chapel_command_dock()

func _on_move() -> void:
	if not _selection or not _selection.can_command(): return
	super._on_move()
	_selection.refresh()

func _on_attack() -> void:
	if not _selection or not _selection.can_command(): return
	super._on_attack()
	_selection.refresh()

func _on_ability() -> void:
	if not _selection or not _selection.can_command(): return
	super._on_ability()
	_selection.refresh()

func _on_wait() -> void:
	if not _selection or not _selection.can_command(): return
	super._on_wait()

func _on_cancel() -> void:
	if _selection: _selection.go_back()

# The scheduler projection starts AFTER the active turn has consumed its CT.
# Keep NOW separate; never label the first future turn as the current actor.
func _build_turn_portraits() -> void:
	_turn_portraits = VBoxContainer.new()
	_turn_portraits.name = "PortraitTurnOrder"
	_turn_portraits.add_theme_constant_override("separation", 5)
	_right_panel_root.add_child(_turn_portraits)
	_right_panel_root.move_child(_turn_portraits, 0)
	var title := Label.new()
	title.text = "TURN ORDER"
	title.add_theme_font_size_override("font_size", 22)
	_turn_portraits.add_child(title)
	for i in 5:
		var panel := PanelContainer.new()
		panel.custom_minimum_size.y = 66
		_turn_portraits.add_child(panel)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("20212a")
		style.border_color = Color("ddbc79") if i == 0 else Color("625743")
		style.set_border_width_all(2 if i == 0 else 1)
		style.set_content_margin_all(5)
		style.set_corner_radius_all(5)
		panel.add_theme_stylebox_override("panel", style)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		panel.add_child(row)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(48, 56)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(portrait)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		var who := Label.new()
		who.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		who.add_theme_font_size_override("font_size", 22)
		copy.add_child(who)
		var when := Label.new()
		when.add_theme_font_size_override("font_size", 18)
		copy.add_child(when)
		_turn_rows.append({"panel":panel, "portrait":portrait, "who":who, "when":when, "unit_id":""})

func _refresh_turn_portraits() -> void:
	if not battle_manager or not is_instance_valid(_turn_portraits): return
	var entries: Array = []
	var active: Unit = battle_manager.units.get(battle_manager.active_unit_id)
	if is_instance_valid(active) and active.hp > 0:
		entries.append({"unit_id":active.unit_id, "display_name":active.display_name, "team":active.team, "now":true})
	for entry in battle_manager.turn_order.get_projected_order(4):
		entries.append(entry)
	for i in _turn_rows.size():
		var row: Dictionary = _turn_rows[i]
		row.panel.visible = i < entries.size()
		row.unit_id = ""
		if i >= entries.size(): continue
		var entry: Dictionary = entries[i]
		row.unit_id = entry.unit_id
		var unit: Unit = battle_manager.units.get(entry.unit_id)
		row.portrait.texture = AssetRegistry.load_first_texture(AssetRegistry.get_character_portrait_candidates(unit.unit_data.id)) if is_instance_valid(unit) else null
		row.who.text = entry.display_name
		var side := "ALLY" if entry.team == "player" else "ENEMY"
		row.when.text = ("NOW" if entry.get("now", false) else "NEXT %d" % (i if entries[0].get("now", false) else i + 1)) + "  ·  " + side
		row.when.add_theme_color_override("font_color", Color("9cdbeb") if entry.team == "player" else Color("f2a394"))
		row.panel.tooltip_text = row.who.text + " · " + row.when.text

func _on_timeline_updated(ordered_units: Array) -> void:
	super._on_timeline_updated(ordered_units)
	# tick_until_ready emits just before manager changes active identity.
	_refresh_turn_portraits.call_deferred()

func _on_turn_started(unit_id: String, team: String) -> void:
	super._on_turn_started(unit_id, team)
	_refresh_turn_portraits()
