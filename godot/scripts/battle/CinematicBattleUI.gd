class_name CinematicBattleUI
extends "res://scripts/battle/BattleUI.gd"

## Presentation layer inspired by the Ashvale target mockup.
## The base BattleUI still owns all command callbacks, previews, settings,
## spoils, battle-state wiring and keyboard shortcuts. This subclass only
## rearranges those proven controls into a stronger tactical HUD and adds a
## read-only party roster.

const CINEMATIC_FONT := preload("res://assets/fonts/TrajanPro-Regular.ttf")
const GOLD := Color(0.78, 0.63, 0.35, 0.95)
const GOLD_BRIGHT := Color(0.96, 0.82, 0.50, 1.0)
const PANEL_BG := Color(0.018, 0.023, 0.032, 0.90)
const PANEL_BG_SOFT := Color(0.025, 0.032, 0.045, 0.84)
const TEXT_MAIN := Color(0.93, 0.91, 0.84, 1.0)
const TEXT_MUTED := Color(0.58, 0.62, 0.68, 1.0)
const PLAYER_ACCENT := Color(0.35, 0.72, 0.92, 1.0)
const DANGER_ACCENT := Color(0.90, 0.30, 0.22, 1.0)

var _cinematic_root: Control
var _party_list: VBoxContainer
var _party_cards: Dictionary = {}
var _active_party_id: String = ""
var _legacy_root: Control
var _command_panel: PanelContainer
var _ability_host: PanelContainer
var _intent_host: PanelContainer
var _terrain_host: PanelContainer
var _header_title: Label
var _header_subtitle: Label


func _build_ui() -> void:
	# Build the battle-proven UI first so every inherited member and callback is
	# initialized exactly as before. We then reparent the important controls.
	super._build_ui()
	_legacy_root = _mission_label.get_parent() as Control if _mission_label else null
	_build_cinematic_shell()
	_extract_live_controls()
	_hide_legacy_shell()
	_style_live_controls()
	_position_inherited_overlays()


func setup(manager: BattleManager) -> void:
	super.setup(manager)
	if battle_manager and battle_manager.combat_resolver:
		if not battle_manager.combat_resolver.combat_resolved.is_connected(_on_cinematic_combat_resolved):
			battle_manager.combat_resolver.combat_resolved.connect(_on_cinematic_combat_resolved)
	if battle_manager and not battle_manager.unit_defeated.is_connected(_on_cinematic_unit_defeated):
		battle_manager.unit_defeated.connect(_on_cinematic_unit_defeated)
	call_deferred("_refresh_party_roster")


func _build_cinematic_shell() -> void:
	_cinematic_root = Control.new()
	_cinematic_root.name = "CinematicBattleHUD"
	_cinematic_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cinematic_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_cinematic_root)

	_build_brand_header()
	_build_party_roster_panel()
	_build_turn_order_strip()
	_build_mission_panel()
	_build_intent_panel()
	_build_command_panel()
	_build_ability_host()
	_build_terrain_panel()
	_build_bottom_hint()


func _build_brand_header() -> void:
	var panel := _panel(_cinematic_root, Vector2(22, 18), Vector2(520, 116), GOLD, 0.58)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	_header_title = _label(box, "THE APPOINTED", 32, GOLD_BRIGHT)
	_header_title.add_theme_constant_override("outline_size", 3)
	_header_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_header_subtitle = _label(box, "SACRIFICE SHAPES A BRIGHTER TOMORROW", 11, TEXT_MUTED)
	var mode := _label(box, "TACTICAL DIORAMA // ASHVALE", 10, PLAYER_ACCENT)
	mode.add_theme_constant_override("outline_size", 2)
	mode.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))


func _build_party_roster_panel() -> void:
	var panel := _panel(_cinematic_root, Vector2(20, 150), Vector2(330, 500), GOLD, 0.76)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)
	var title := _label(outer, "PARTY", 12, GOLD_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_party_list = VBoxContainer.new()
	_party_list.add_theme_constant_override("separation", 8)
	_party_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(_party_list)


func _build_turn_order_strip() -> void:
	var panel := _panel(_cinematic_root, Vector2(640, 22), Vector2(650, 84), GOLD, 0.60)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var title := _label(box, "TURN ORDER", 10, TEXT_MUTED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for lbl in _timeline_labels:
		var slot_panel := lbl.get_parent()
		if slot_panel:
			slot_panel.reparent(row)
			slot_panel.custom_minimum_size = Vector2(102, 42)
			var st := _style(Color(0.03, 0.04, 0.055, 0.88), PLAYER_ACCENT.darkened(0.35), 1)
			slot_panel.add_theme_stylebox_override("panel", st)
		lbl.add_theme_font_override("font", CINEMATIC_FONT)
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", TEXT_MAIN)


func _build_mission_panel() -> void:
	var panel := _panel(_cinematic_root, Vector2(1400, 20), Vector2(490, 122), GOLD, 0.66)
	var box := VBoxContainer.new()
	box.name = "MissionBox"
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	# Live labels are reparented here in _extract_live_controls.


func _build_intent_panel() -> void:
	_intent_host = _panel(_cinematic_root, Vector2(1490, 170), Vector2(390, 360), DANGER_ACCENT, 0.78)
	var box := VBoxContainer.new()
	box.name = "IntentBox"
	box.add_theme_constant_override("separation", 8)
	_intent_host.add_child(box)
	var title := _label(box, "ENEMY INTENT", 15, Color(1.0, 0.66, 0.42))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_command_panel() -> void:
	_command_panel = _panel(_cinematic_root, Vector2(20, 675), Vector2(330, 370), GOLD, 0.84)
	var box := VBoxContainer.new()
	box.name = "CommandBox"
	box.add_theme_constant_override("separation", 8)
	_command_panel.add_child(box)
	var title := _label(box, "COMMAND", 14, GOLD_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_ability_host() -> void:
	_ability_host = _panel(_cinematic_root, Vector2(460, 810), Vector2(990, 235), GOLD, 0.78)
	_ability_host.visible = true
	var box := VBoxContainer.new()
	box.name = "AbilityHostBox"
	box.add_theme_constant_override("separation", 6)
	_ability_host.add_child(box)
	var title := _label(box, "ABILITIES", 11, GOLD_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var idle := _label(box, "Select Ability to open the active unit's techniques.", 11, TEXT_MUTED)
	idle.name = "IdleHint"
	idle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_terrain_panel() -> void:
	_terrain_host = _panel(_cinematic_root, Vector2(1500, 790), Vector2(380, 220), GOLD, 0.74)
	var box := VBoxContainer.new()
	box.name = "TerrainBox"
	box.add_theme_constant_override("separation", 8)
	_terrain_host.add_child(box)
	var title := _label(box, "FIELD READ", 13, GOLD_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_bottom_hint() -> void:
	var panel := _panel(_cinematic_root, Vector2(560, 1040), Vector2(800, 32), GOLD, 0.46)
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	# Live command hint is reparented here.


func _extract_live_controls() -> void:
	var mission_box := _find_named_container(_cinematic_root, "MissionBox")
	if mission_box:
		_reparent(_mission_label, mission_box)
		_reparent(_phase_label, mission_box)
		_reparent(_objective_label, mission_box)

	var intent_box := _find_named_container(_intent_host, "IntentBox")
	if intent_box:
		_reparent(_enemy_intent_panel, intent_box)
		_enemy_intent_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var command_box := _find_named_container(_command_panel, "CommandBox")
	if command_box:
		_reparent(_unit_name, command_box)
		_reparent(_hp_bar, command_box)
		var stats := HBoxContainer.new()
		stats.add_theme_constant_override("separation", 12)
		command_box.add_child(stats)
		_reparent(_hp_label, stats)
		_reparent(_mp_label, stats)
		_reparent(_temper_label, stats)
		_reparent(_ether_label, stats)
		var primary := VBoxContainer.new()
		primary.add_theme_constant_override("separation", 4)
		command_box.add_child(primary)
		_reparent(_move_btn, primary)
		_reparent(_attack_btn, primary)
		_reparent(_ability_btn, primary)
		_reparent(_wait_btn, primary)
		var confirm_row := HBoxContainer.new()
		confirm_row.add_theme_constant_override("separation", 6)
		command_box.add_child(confirm_row)
		_reparent(_confirm_btn, confirm_row)
		_reparent(_cancel_btn, confirm_row)
		_reparent(_action_state_label, command_box)
		_reparent(_result_label, command_box)
		_reparent(_status_label, command_box)

	var ability_box := _find_named_container(_ability_host, "AbilityHostBox")
	if ability_box:
		_reparent(_ability_panel, ability_box)
		_ability_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var terrain_box := _find_named_container(_terrain_host, "TerrainBox")
	if terrain_box:
		_reparent(_tile_info_label, terrain_box)

	# The bottom hint panel is the last cinematic panel added before extraction.
	for child in _cinematic_root.get_children():
		if child is PanelContainer and child.position.y >= 1030.0:
			var hint_box := child.get_child(0) as HBoxContainer
			if hint_box:
				_reparent(_command_hint_label, hint_box)
			break

	# Keep inherited modal/forecast systems, but put them above the new HUD.
	_reparent(_preview_panel, _cinematic_root)
	_reparent(_intro_banner, _cinematic_root)
	_reparent(_settings_overlay, _cinematic_root)


func _hide_legacy_shell() -> void:
	if _legacy_root:
		_legacy_root.visible = false

	# Hide the old large right-side backing rectangle and side timeline panel.
	for child in get_children():
		if child == _cinematic_root:
			continue
		if child is ColorRect and child.position.x > 800.0:
			child.visible = false
		elif child is PanelContainer:
			if child == _loadout_panel:
				child.visible = false
			elif child.position.x < 200.0 and child != _intro_banner:
				child.visible = false

	if _loadout_panel:
		_loadout_panel.visible = false


func _style_live_controls() -> void:
	for lbl in [_mission_label, _phase_label, _objective_label, _unit_name,
			_hp_label, _mp_label, _temper_label, _ether_label, _tile_info_label,
			_command_hint_label, _action_state_label, _result_label, _status_label]:
		if lbl:
			lbl.add_theme_font_override("font", CINEMATIC_FONT)

	if _mission_label:
		_mission_label.add_theme_font_size_override("font_size", 21)
		_mission_label.add_theme_color_override("font_color", GOLD_BRIGHT)
		_mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _phase_label:
		_phase_label.add_theme_font_size_override("font_size", 11)
		_phase_label.add_theme_color_override("font_color", PLAYER_ACCENT)
		_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _objective_label:
		_objective_label.add_theme_font_size_override("font_size", 11)
		_objective_label.add_theme_color_override("font_color", TEXT_MAIN)
		_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _unit_name:
		_unit_name.add_theme_font_size_override("font_size", 20)
		_unit_name.add_theme_color_override("font_color", GOLD_BRIGHT)
		_unit_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if _hp_bar:
		_hp_bar.custom_minimum_size.y = 13
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.10, 0.04, 0.04, 0.92)
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(0.78, 0.18, 0.12, 0.96)
		_hp_bar.add_theme_stylebox_override("background", bg)
		_hp_bar.add_theme_stylebox_override("fill", fill)

	for button in [_move_btn, _attack_btn, _ability_btn, _wait_btn]:
		_style_command_button(button)
	for button in [_confirm_btn, _cancel_btn]:
		_style_secondary_button(button)

	if _enemy_intent_title:
		_enemy_intent_title.add_theme_font_override("font", CINEMATIC_FONT)
		_enemy_intent_title.add_theme_font_size_override("font_size", 11)
	if _enemy_intent_body:
		_enemy_intent_body.add_theme_font_override("font", CINEMATIC_FONT)
		_enemy_intent_body.add_theme_font_size_override("font_size", 11)
		_enemy_intent_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _tile_info_label:
		_tile_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tile_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_tile_info_label.add_theme_color_override("font_color", TEXT_MAIN)
		_tile_info_label.add_theme_font_size_override("font_size", 12)
	if _command_hint_label:
		_command_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_command_hint_label.add_theme_color_override("font_color", Color(0.62, 0.88, 1.0))
		_command_hint_label.add_theme_font_size_override("font_size", 10)


func _position_inherited_overlays() -> void:
	if _preview_panel:
		_preview_panel.position = Vector2(500, 610)
		_preview_panel.size = Vector2(920, 175)
		_preview_panel.custom_minimum_size = Vector2(920, 175)
	if _intro_banner:
		_intro_banner.position = Vector2(660, 128)
		_intro_banner.custom_minimum_size = Vector2(600, 90)
	if _settings_overlay:
		_settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_battle_started(display_name: String, objective: String) -> void:
	super._on_battle_started(display_name, objective)
	if _header_subtitle:
		_header_subtitle.text = "%s // %s" % [display_name.to_upper(), objective.to_upper()]
	call_deferred("_refresh_party_roster")


func _on_turn_started(unit_id: String, team: String) -> void:
	super._on_turn_started(unit_id, team)
	_active_party_id = unit_id if team == "player" else ""
	_refresh_party_roster()


func _on_ability_mode_started(usable_ids: Array) -> void:
	super._on_ability_mode_started(usable_ids)
	call_deferred("_style_ability_buttons")
	var idle := _find_named_control(_ability_host, "IdleHint")
	if idle:
		idle.visible = usable_ids.is_empty()


func _on_cinematic_combat_resolved(_result: Dictionary) -> void:
	call_deferred("_refresh_party_roster")


func _on_cinematic_unit_defeated(_unit_id: String) -> void:
	call_deferred("_refresh_party_roster")


func _refresh_party_roster() -> void:
	if not _party_list or not battle_manager:
		return
	var players: Array[Unit] = []
	var desired_order := ["zane", "mira", "kael", "lyra"]
	for preferred_id in desired_order:
		var preferred: Unit = battle_manager.units.get(preferred_id)
		if preferred and preferred.team == "player":
			players.append(preferred)
	for value in battle_manager.units.values():
		var unit := value as Unit
		if unit and unit.team == "player" and unit not in players:
			players.append(unit)

	var live_ids: Dictionary = {}
	for unit in players:
		live_ids[unit.unit_id] = true
		if not _party_cards.has(unit.unit_id):
			_party_cards[unit.unit_id] = _create_party_card(unit)
		_update_party_card(unit, _party_cards[unit.unit_id])

	for existing_id in _party_cards.keys():
		if not live_ids.has(existing_id):
			var refs: Dictionary = _party_cards[existing_id]
			var panel: Control = refs.get("panel")
			if panel:
				panel.visible = false


func _create_party_card(unit: Unit) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(292, 100)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_party_list.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(76, 84)
	portrait_frame.add_theme_stylebox_override("panel", _style(Color(0.045, 0.05, 0.065, 0.96), GOLD.darkened(0.25), 1))
	row.add_child(portrait_frame)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(70, 80)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(portrait)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var name_lbl := _label(info, unit.display_name, 15, TEXT_MAIN)
	var job_lbl := _label(info, _pretty_job(unit.current_job_id), 10, TEXT_MUTED)
	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(176, 9)
	hp_bar.show_percentage = false
	info.add_child(hp_bar)
	var hp_lbl := _label(info, "HP", 9, Color(0.95, 0.55, 0.48))
	var mp_lbl := _label(info, "MP", 9, Color(0.48, 0.72, 1.0))

	if unit.unit_data and unit.unit_data.sprite_sheet:
		portrait.texture = unit.unit_data.sprite_sheet

	return {
		"panel": panel,
		"portrait": portrait,
		"name": name_lbl,
		"job": job_lbl,
		"hp_bar": hp_bar,
		"hp": hp_lbl,
		"mp": mp_lbl,
	}


func _update_party_card(unit: Unit, refs: Dictionary) -> void:
	var panel := refs.get("panel") as PanelContainer
	var name_lbl := refs.get("name") as Label
	var job_lbl := refs.get("job") as Label
	var hp_bar := refs.get("hp_bar") as ProgressBar
	var hp_lbl := refs.get("hp") as Label
	var mp_lbl := refs.get("mp") as Label
	var portrait := refs.get("portrait") as TextureRect
	if not panel:
		return
	panel.visible = true
	var max_hp: int = unit.hp
	if unit.unit_data:
		max_hp = unit.unit_data.base_stats.hp
	max_hp = maxi(max_hp, 1)
	if name_lbl: name_lbl.text = unit.display_name
	if job_lbl: job_lbl.text = _pretty_job(unit.current_job_id)
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = max(unit.hp, 0)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.10, 0.035, 0.035, 0.92)
		var fill := StyleBoxFlat.new()
		var hp_ratio := float(max(unit.hp, 0)) / float(max_hp)
		fill.bg_color = Color(0.82, 0.18, 0.12, 0.96) if hp_ratio > 0.3 else Color(1.0, 0.43, 0.16, 0.98)
		hp_bar.add_theme_stylebox_override("background", bg)
		hp_bar.add_theme_stylebox_override("fill", fill)
	if hp_lbl: hp_lbl.text = "HP  %d / %d" % [max(unit.hp, 0), max_hp]
	if mp_lbl: mp_lbl.text = "MP  %d" % max(unit.mp, 0)
	if portrait and unit.unit_data and unit.unit_data.sprite_sheet:
		portrait.texture = unit.unit_data.sprite_sheet
	var accent := PLAYER_ACCENT if unit.unit_id == _active_party_id else GOLD.darkened(0.22)
	if unit.is_defeated or unit.hp <= 0:
		accent = Color(0.30, 0.30, 0.32, 0.8)
		panel.modulate = Color(0.55, 0.55, 0.58, 0.72)
	else:
		panel.modulate = Color.WHITE
	panel.add_theme_stylebox_override("panel", _style(PANEL_BG_SOFT, accent, 2 if unit.unit_id == _active_party_id else 1))


func _style_ability_buttons() -> void:
	if not _ability_list:
		return
	for child in _ability_list.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(0, 46)
			child.add_theme_font_override("font", CINEMATIC_FONT)


func _style_command_button(button: Button) -> void:
	if not button:
		return
	button.custom_minimum_size = Vector2(286, 48)
	button.add_theme_font_override("font", CINEMATIC_FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", GOLD_BRIGHT)
	button.add_theme_stylebox_override("normal", _style(Color(0.025, 0.03, 0.04, 0.90), GOLD.darkened(0.35), 1))
	button.add_theme_stylebox_override("hover", _style(Color(0.08, 0.065, 0.035, 0.96), GOLD_BRIGHT, 2))
	button.add_theme_stylebox_override("pressed", _style(Color(0.11, 0.075, 0.03, 0.98), GOLD_BRIGHT, 2))
	button.add_theme_stylebox_override("disabled", _style(Color(0.018, 0.02, 0.026, 0.72), Color(0.18, 0.18, 0.20, 0.7), 1))


func _style_secondary_button(button: Button) -> void:
	if not button:
		return
	button.custom_minimum_size = Vector2(136, 34)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", CINEMATIC_FONT)
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_stylebox_override("normal", _style(Color(0.025, 0.03, 0.04, 0.88), Color(0.28, 0.32, 0.38, 0.9), 1))
	button.add_theme_stylebox_override("hover", _style(Color(0.055, 0.06, 0.07, 0.94), PLAYER_ACCENT, 1))
	button.add_theme_stylebox_override("disabled", _style(Color(0.018, 0.02, 0.026, 0.62), Color(0.15, 0.16, 0.18, 0.62), 1))


func _panel(parent: Control, pos: Vector2, panel_size: Vector2, border: Color, alpha: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = panel_size
	panel.custom_minimum_size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", _style(Color(PANEL_BG.r, PANEL_BG.g, PANEL_BG.b, alpha), border, 1))
	parent.add_child(panel)
	return panel


func _style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.content_margin_left = 12.0
	st.content_margin_right = 12.0
	st.content_margin_top = 9.0
	st.content_margin_bottom = 9.0
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, width)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(corner, 3)
	return st


func _label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", CINEMATIC_FONT)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(lbl)
	return lbl


func _reparent(node: Node, new_parent: Node) -> void:
	if node and new_parent and node.get_parent() != new_parent:
		node.reparent(new_parent, false)


func _find_named_container(root: Node, target_name: String) -> Container:
	if not root:
		return null
	if root.name == target_name and root is Container:
		return root as Container
	for child in root.get_children():
		var found := _find_named_container(child, target_name)
		if found:
			return found
	return null


func _find_named_control(root: Node, target_name: String) -> Control:
	if not root:
		return null
	if root.name == target_name and root is Control:
		return root as Control
	for child in root.get_children():
		var found := _find_named_control(child, target_name)
		if found:
			return found
	return null


func _pretty_job(job_id: String) -> String:
	if job_id.is_empty():
		return "Adventurer"
	return job_id.replace("_", " ").capitalize()
