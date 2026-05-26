class_name BattleUI
extends CanvasLayer

signal spoils_continue_requested

const DISPLAY_FONT := preload("res://assets/fonts/TrajanPro-Regular.ttf")

var battle_manager: BattleManager

var _mission_label: Label
var _phase_label: Label
var _objective_label: Label
var _enemy_intent_panel: PanelContainer
var _enemy_intent_title: Label
var _enemy_intent_body: Label
var _unit_name: Label
var _hp_label: Label
var _mp_label: Label
var _temper_label: Label
var _ether_label: Label
var _hp_bar: ProgressBar
var _log_labels: Array[Label] = []
var _timeline_labels: Array[Label] = []
var _side_timeline_labels: Array[Label] = []
var _move_btn: Button
var _attack_btn: Button
var _wait_btn: Button
var _ability_btn: Button
var _confirm_btn: Button
var _cancel_btn: Button
var _ability_panel: VBoxContainer
var _ability_list: VBoxContainer
var _result_label: Label
var _status_label: Label
var _action_state_label: Label
var _tile_info_label: Label
var _command_hint_label: Label
var _preview_panel: PanelContainer
var _preview_mode_label: Label
var _preview_actor_portrait: TextureRect
var _preview_actor_label: Label
var _preview_target_portrait: TextureRect
var _preview_target_label: Label
var _preview_action_label: Label
var _preview_amount_label: Label
var _preview_hit_label: Label
var _preview_crit_label: Label
var _preview_note_label: Label
var _loadout_panel: PanelContainer
var _loadout_items_box: HBoxContainer
var _loadout_detail_label: Label
var _intro_banner: PanelContainer
var _intro_banner_style: StyleBoxFlat
var _spoils_overlay: Control
var _settings_overlay: Control
var _game_slider: HSlider
var _music_slider: HSlider
var _fx_slider: HSlider
var _game_value_label: Label
var _music_value_label: Label
var _fx_value_label: Label
var _is_player_turn: bool = false
var _can_move_now: bool = false
var _can_act_now: bool = false
var _has_pending_action: bool = false

const LOG_SIZE := 5
const TIMELINE_SLOTS := 5


func setup(manager: BattleManager) -> void:
	battle_manager = manager
	battle_manager.log_message.connect(_on_log)
	battle_manager.phase_changed.connect(_on_phase_changed)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.battle_won.connect(_on_battle_won)
	battle_manager.battle_lost.connect(_on_battle_lost)
	battle_manager.turn_order.timeline_updated.connect(_on_timeline_updated)
	battle_manager.ability_mode_started.connect(_on_ability_mode_started)
	battle_manager.tile_info_changed.connect(_on_tile_info_changed)
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.command_hint_changed.connect(_on_command_hint_changed)
	battle_manager.action_preview_changed.connect(_on_action_preview_changed)
	battle_manager.action_state_changed.connect(_on_action_state_changed)
	battle_manager.enemy_intent_changed.connect(_on_enemy_intent_changed)
	if battle_manager.objective_tracker:
		battle_manager.objective_tracker.objective_updated.connect(_on_objective_updated)
	_refresh_loadout_strip()


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Dark background panel on right half
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.045, 0.065, 0.82)
	bg.position = Vector2(908, 8)
	bg.size = Vector2(360, 704)
	add_child(bg)

	var root := VBoxContainer.new()
	root.position = Vector2(916, 14)
	root.size = Vector2(344, 690)
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	# Mission header
	_mission_label = Label.new()
	_mission_label.text = "ASHVALE ROAD"
	_mission_label.add_theme_font_size_override("font_size", 15)
	_mission_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	_mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_mission_label)

	_phase_label = Label.new()
	_phase_label.text = "Initializing"
	_phase_label.add_theme_font_size_override("font_size", 13)
	_phase_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_phase_label)

	_objective_label = Label.new()
	_objective_label.text = "Objective pending"
	_objective_label.add_theme_font_size_override("font_size", 12)
	_objective_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.48))
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_objective_label)

	_enemy_intent_panel = PanelContainer.new()
	_enemy_intent_panel.visible = false
	var intent_style := StyleBoxFlat.new()
	intent_style.bg_color = Color(0.05, 0.06, 0.085, 0.92)
	intent_style.border_color = Color(1.0, 0.45, 0.22, 0.72)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		intent_style.set_border_width(side, 1)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		intent_style.set_corner_radius(corner, 6)
	_enemy_intent_panel.add_theme_stylebox_override("panel", intent_style)
	root.add_child(_enemy_intent_panel)

	var intent_box := VBoxContainer.new()
	intent_box.add_theme_constant_override("separation", 2)
	_enemy_intent_panel.add_child(intent_box)
	_enemy_intent_title = Label.new()
	_enemy_intent_title.text = "ENEMY INTENT"
	_enemy_intent_title.add_theme_font_size_override("font_size", 10)
	_enemy_intent_title.add_theme_color_override("font_color", Color(1.0, 0.62, 0.36))
	intent_box.add_child(_enemy_intent_title)
	_enemy_intent_body = Label.new()
	_enemy_intent_body.text = ""
	_enemy_intent_body.add_theme_font_size_override("font_size", 12)
	_enemy_intent_body.add_theme_color_override("font_color", Color(0.92, 0.90, 0.84))
	_enemy_intent_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intent_box.add_child(_enemy_intent_body)

	_tile_info_label = Label.new()
	_tile_info_label.text = "Hover a tile"
	_tile_info_label.add_theme_font_size_override("font_size", 11)
	_tile_info_label.add_theme_color_override("font_color", Color(0.62, 0.72, 0.80))
	_tile_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_tile_info_label)

	_command_hint_label = Label.new()
	_command_hint_label.text = "Choose a command"
	_command_hint_label.add_theme_font_size_override("font_size", 12)
	_command_hint_label.add_theme_color_override("font_color", Color(0.25, 0.95, 1.0))
	_command_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_command_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_command_hint_label)

	root.add_child(_separator())

	# Active unit panel
	root.add_child(_section_label("ACTIVE UNIT"))

	_unit_name = Label.new()
	_unit_name.text = ""
	_unit_name.add_theme_font_size_override("font_size", 18)
	_unit_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	root.add_child(_unit_name)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size.y = 14
	_hp_bar.value = 100
	root.add_child(_hp_bar)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 16)
	root.add_child(stats_row)
	_hp_label     = _stat_label(stats_row, "HP")
	_mp_label     = _stat_label(stats_row, "MP")
	_temper_label = _stat_label(stats_row, "TMP")
	_ether_label  = _stat_label(stats_row, "ETH")

	root.add_child(_separator())

	# Command buttons
	root.add_child(_section_label("COMMANDS"))
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	root.add_child(btn_row)
	_move_btn   = _cmd_btn(btn_row, "Move",   _on_move)
	_attack_btn = _cmd_btn(btn_row, "Attack", _on_attack)
	_wait_btn   = _cmd_btn(btn_row, "Wait",   _on_wait)
	_ability_btn = _cmd_btn(btn_row, "Ability", _on_ability)

	var confirm_row := HBoxContainer.new()
	confirm_row.add_theme_constant_override("separation", 6)
	root.add_child(confirm_row)
	_confirm_btn = _cmd_btn(confirm_row, "Confirm", _on_confirm)
	_cancel_btn = _cmd_btn(confirm_row, "Cancel", _on_cancel)

	_action_state_label = Label.new()
	_action_state_label.text = "Move: ready    Action: ready"
	_action_state_label.add_theme_font_size_override("font_size", 12)
	_action_state_label.add_theme_color_override("font_color", Color(0.72, 0.84, 0.95))
	root.add_child(_action_state_label)

	_result_label = Label.new()
	_result_label.text = ""
	_result_label.add_theme_font_size_override("font_size", 13)
	_result_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	root.add_child(_result_label)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.95, 0.6, 1.0))
	root.add_child(_status_label)

	# Ability selection panel (hidden by default)
	_ability_panel = VBoxContainer.new()
	_ability_panel.visible = false
	_ability_panel.add_theme_constant_override("separation", 4)
	root.add_child(_ability_panel)

	var ab_header := Label.new()
	ab_header.text = " SELECT SPELL "
	ab_header.add_theme_font_size_override("font_size", 11)
	ab_header.add_theme_color_override("font_color", Color(0.7, 0.6, 1.0))
	ab_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ability_panel.add_child(ab_header)

	_ability_list = VBoxContainer.new()
	_ability_list.add_theme_constant_override("separation", 3)
	_ability_panel.add_child(_ability_list)

	root.add_child(_separator())

	# Turn timeline
	root.add_child(_section_label("TURN ORDER (next %d)" % TIMELINE_SLOTS))
	var timeline_row := HBoxContainer.new()
	timeline_row.add_theme_constant_override("separation", 4)
	root.add_child(timeline_row)
	for i in range(TIMELINE_SLOTS):
		var slot := _timeline_slot(timeline_row)
		_timeline_labels.append(slot)

	root.add_child(_separator())

	# Battle log
	root.add_child(_section_label("BATTLE LOG"))
	for i in range(LOG_SIZE):
		var lbl := Label.new()
		lbl.text = ""
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		root.add_child(lbl)
		_log_labels.append(lbl)

	_build_intro_banner()
	_build_side_timeline()
	_build_loadout_strip()
	_build_action_preview_panel()
	_build_settings_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			_toggle_settings_overlay()
			get_viewport().set_input_as_handled()
		KEY_M:
			_press_if_ready(_move_btn, _on_move)
		KEY_A:
			_press_if_ready(_attack_btn, _on_attack)
		KEY_S:
			_press_if_ready(_ability_btn, _on_ability)
		KEY_W:
			_press_if_ready(_wait_btn, _on_wait)
		KEY_ENTER, KEY_SPACE:
			_press_if_ready(_confirm_btn, _on_confirm)
		KEY_Q, KEY_BACKSPACE:
			_press_if_ready(_cancel_btn, _on_cancel)


func _press_if_ready(button: Button, callback: Callable) -> void:
	if _settings_overlay and _settings_overlay.visible:
		return
	if button and not button.disabled and button.visible:
		callback.call()
		get_viewport().set_input_as_handled()

func _build_intro_banner() -> void:
	_intro_banner = PanelContainer.new()
	_intro_banner.visible = false
	_intro_banner.position = Vector2(70.0, 36.0)
	_intro_banner.custom_minimum_size = Vector2(500.0, 82.0)
	_intro_banner_style = StyleBoxFlat.new()
	_intro_banner_style.bg_color = Color(0.035, 0.038, 0.052, 0.92)
	_intro_banner_style.border_color = Color(0.78, 0.66, 0.42, 0.86)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		_intro_banner_style.set_border_width(side, 1)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		_intro_banner_style.set_corner_radius(corner, 6)
	_intro_banner.add_theme_stylebox_override("panel", _intro_banner_style)
	add_child(_intro_banner)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_intro_banner.add_child(box)

	var title := Label.new()
	title.name = "Title"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.90, 0.95))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)


#  Builder helpers

func _build_side_timeline() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(12.0, 84.0)
	panel.custom_minimum_size = Vector2(120.0, 300.0)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.04, 0.06, 0.82)
	st.border_color = Color(0.25, 0.45, 0.65, 0.65)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 6)
	panel.add_theme_stylebox_override("panel", st)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)

	var title := Label.new()
	title.text = "NEXT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.75, 0.86, 1.0))
	box.add_child(title)

	for i in range(TIMELINE_SLOTS):
		var lbl := Label.new()
		lbl.text = "%d  -" % (i + 1)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.86, 0.88, 0.9))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.custom_minimum_size = Vector2(104.0, 28.0)
		box.add_child(lbl)
		_side_timeline_labels.append(lbl)


func _build_loadout_strip() -> void:
	_loadout_panel = PanelContainer.new()
	_loadout_panel.position = Vector2(12.0, 396.0)
	_loadout_panel.custom_minimum_size = Vector2(330.0, 112.0)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.04, 0.06, 0.86)
	st.border_color = Color(0.78, 0.66, 0.34, 0.58)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 6)
	_loadout_panel.add_theme_stylebox_override("panel", st)
	add_child(_loadout_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	_loadout_panel.add_child(box)

	var title := Label.new()
	title.text = "VOW / SIGIL / BOONS"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.92, 0.78, 0.46))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_loadout_items_box = HBoxContainer.new()
	_loadout_items_box.add_theme_constant_override("separation", 4)
	box.add_child(_loadout_items_box)

	_loadout_detail_label = Label.new()
	_loadout_detail_label.text = "Hover or select an icon."
	_loadout_detail_label.add_theme_font_size_override("font_size", 10)
	_loadout_detail_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.86))
	_loadout_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loadout_detail_label.custom_minimum_size = Vector2(312.0, 42.0)
	box.add_child(_loadout_detail_label)
	_refresh_loadout_strip()


func _refresh_loadout_strip() -> void:
	if not _loadout_items_box:
		return
	for child in _loadout_items_box.get_children():
		child.queue_free()
	var gs: Node = get_node_or_null("/root/GameState")
	if not gs or not gs.get("active_run"):
		_loadout_detail_label.text = "No active run loadout."
		return
	var run: RunState = gs.get("active_run") as RunState
	if not run:
		_loadout_detail_label.text = "No active run loadout."
		return
	var vow: Dictionary = VowSigilSystem.get_vow(str(run.equipped_vow_id))
	var sigil: Dictionary = VowSigilSystem.get_sigil(str(run.equipped_sigil_id))
	_add_loadout_item("V", Color(0.95, 0.68, 0.28), _loadout_vow_text(vow, int(run.equipped_vow_level)))
	_add_loadout_item("S", Color(0.45, 0.84, 1.0), _loadout_sigil_text(sigil, int(run.equipped_sigil_level)))
	var shown := 0
	for boon_variant in run.active_boons:
		if shown >= 7:
			break
		var boon_dict: Dictionary = boon_variant as Dictionary
		var icon := str(boon_dict.get("icon", "+"))
		if icon.length() > 2:
			icon = str(boon_dict.get("name", "?")).left(1).to_upper()
		_add_loadout_item(icon, _boon_color(boon_dict), _loadout_boon_text(boon_dict))
		shown += 1
	if run.active_boons.size() > shown:
		_add_loadout_item("+%d" % (run.active_boons.size() - shown), Color(0.8, 0.8, 0.8), "More boons are active. Open the route screen for the full list.")


func _add_loadout_item(label: String, color: Color, detail: String) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(30.0, 30.0)
	btn.tooltip_text = detail
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", color)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(color.r * 0.14, color.g * 0.14, color.b * 0.14, 0.92)
	st.border_color = color
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	btn.add_theme_stylebox_override("normal", st)
	var hover := st.duplicate() as StyleBoxFlat
	hover.bg_color = Color(color.r * 0.22, color.g * 0.22, color.b * 0.22, 0.96)
	btn.add_theme_stylebox_override("hover", hover)
	btn.mouse_entered.connect(_show_loadout_detail.bind(detail, color))
	btn.pressed.connect(_show_loadout_detail.bind(detail, color))
	_loadout_items_box.add_child(btn)


func _show_loadout_detail(detail: String, color: Color) -> void:
	if not _loadout_detail_label:
		return
	_loadout_detail_label.text = detail
	_loadout_detail_label.add_theme_color_override("font_color", color.lightened(0.24))


func _loadout_vow_text(vow: Dictionary, level: int) -> String:
	return "Vow: %s Lv.%d - %s" % [str(vow.get("name", "Vow")), level, str(vow.get("theme", ""))]


func _loadout_sigil_text(sigil: Dictionary, level: int) -> String:
	return "Sigil: %s Lv.%d - %s" % [str(sigil.get("name", "Sigil")), level, str(sigil.get("theme", ""))]


func _loadout_boon_text(boon: Dictionary) -> String:
	return "%s: %s" % [str(boon.get("name", "Boon")), str(boon.get("desc", ""))]


func _boon_color(boon: Dictionary) -> Color:
	var rarity := str(boon.get("rarity", "common"))
	if BoonSystem.RARITIES.has(rarity):
		var rarity_data: Dictionary = BoonSystem.RARITIES[rarity]
		return rarity_data.get("color", Color(0.9, 0.8, 0.5))
	return Color(0.9, 0.8, 0.5)


func _build_action_preview_panel() -> void:
	_preview_panel = PanelContainer.new()
	_preview_panel.visible = false
	_preview_panel.position = Vector2(238.0, 520.0)
	_preview_panel.custom_minimum_size = Vector2(820.0, 168.0)
	_preview_panel.size = Vector2(820.0, 168.0)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.035, 0.038, 0.052, 0.92)
	st.border_color = Color(0.78, 0.66, 0.42, 0.85)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 6)
	_preview_panel.add_theme_stylebox_override("panel", st)
	add_child(_preview_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 5)
	_preview_panel.add_child(root)

	var combat_row := HBoxContainer.new()
	combat_row.add_theme_constant_override("separation", 18)
	root.add_child(combat_row)
	_preview_actor_portrait = _portrait_column(combat_row, true)
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 5)
	combat_row.add_child(center)
	_preview_target_portrait = _portrait_column(combat_row, false)

	_preview_mode_label = _preview_label(center, "FORECAST", 11, Color(0.92, 0.78, 0.46), HORIZONTAL_ALIGNMENT_CENTER)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	center.add_child(row)
	_preview_actor_label = _preview_label(row, "Actor", 13, Color(0.8, 0.9, 1.0))
	_preview_action_label = _preview_label(row, "Action", 13, Color(1.0, 0.95, 0.72))
	_preview_target_label = _preview_label(row, "Target", 13, Color(1.0, 0.76, 0.72))

	var result_row := HBoxContainer.new()
	result_row.add_theme_constant_override("separation", 18)
	center.add_child(result_row)
	_preview_amount_label = _preview_label(result_row, "--", 34, Color(1.0, 0.92, 0.35))
	_preview_hit_label = _preview_label(result_row, "Hit --", 12, Color(0.75, 0.95, 0.85))
	_preview_crit_label = _preview_label(result_row, "Crit --", 12, Color(0.9, 0.75, 1.0))

	_preview_note_label = _preview_label(center, "", 11, Color(0.72, 0.78, 0.84))
	_preview_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _portrait_column(parent: Control, flip_h: bool) -> TextureRect:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(92.0, 114.0)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.08, 0.11, 0.92)
	st.border_color = Color(0.32, 0.34, 0.42, 0.9)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 5)
	panel.add_theme_stylebox_override("panel", st)
	parent.add_child(panel)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(82.0, 104.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.flip_h = flip_h
	panel.add_child(portrait)
	return portrait


func _preview_label(parent: Control, text: String, font_size: int, color: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", DISPLAY_FONT)
	lbl.horizontal_alignment = align
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(lbl)
	return lbl


func show_spoils(rewards: Dictionary, items: Array) -> void:
	if _spoils_overlay:
		_spoils_overlay.queue_free()
	_spoils_overlay = Control.new()
	_spoils_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_spoils_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_spoils_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_spoils_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900.0, 560.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -450.0
	panel.offset_top = -280.0
	panel.offset_right = 450.0
	panel.offset_bottom = 280.0
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.035, 0.04, 0.06, 0.96)
	st.border_color = Color(1.0, 0.78, 0.28, 0.9)
	st.content_margin_left = 34.0
	st.content_margin_right = 34.0
	st.content_margin_top = 26.0
	st.content_margin_bottom = 26.0
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 2)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(corner, 8)
	panel.add_theme_stylebox_override("panel", st)
	_spoils_overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(box)

	_spoils_label(box, "STAGE CLEAR", 30, Color(1.0, 0.88, 0.36), true)
	_spoils_label(box, "Spoils recovered from the field", 13, Color(0.74, 0.78, 0.84), true)

	var reward_row := HBoxContainer.new()
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.add_theme_constant_override("separation", 16)
	box.add_child(reward_row)
	_reward_chip(reward_row, "Gold", "%d" % rewards.get("gold", 0), Color(1.0, 0.78, 0.28))
	_reward_chip(reward_row, "JP", "%d" % rewards.get("jp", 0), Color(0.58, 0.84, 1.0))
	_reward_chip(reward_row, "Items", "%d" % items.size(), Color(0.75, 0.94, 0.62))

	var item_title := "ITEMS"
	if items.is_empty():
		item_title = "ITEMS - none found"
	_spoils_label(box, item_title, 12, Color(0.55, 0.60, 0.68), false)

	var item_row := HBoxContainer.new()
	item_row.alignment = BoxContainer.ALIGNMENT_CENTER
	item_row.add_theme_constant_override("separation", 10)
	item_row.custom_minimum_size = Vector2(820.0, 160.0)
	item_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(item_row)
	if items.is_empty():
		var empty := _spoils_label(item_row, "No gear dropped this time.", 16, Color(0.72, 0.76, 0.82), true)
		empty.custom_minimum_size = Vector2(760.0, 120.0)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		for i in range(min(items.size(), 3)):
			item_row.add_child(_spoils_item_card(items[i]))

	var cont := Button.new()
	cont.text = "Continue"
	cont.custom_minimum_size = Vector2(180.0, 42.0)
	cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cont.add_theme_font_override("font", DISPLAY_FONT)
	cont.add_theme_font_size_override("font_size", 14)
	cont.pressed.connect(_on_spoils_continue)
	box.add_child(cont)


func _spoils_label(parent: Control, text: String, font_size: int, color: Color,
		centered: bool) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", DISPLAY_FONT)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if centered:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
	return lbl


func _reward_chip(parent: Control, label: String, value: String, accent: Color) -> void:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(150.0, 68.0)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.08, 0.11, 0.92)
	st.border_color = accent.lerp(Color.WHITE, 0.16)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(corner, 6)
	chip.add_theme_stylebox_override("panel", st)
	parent.add_child(chip)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_child(box)
	_spoils_label(box, label.to_upper(), 10, accent, true)
	_spoils_label(box, value, 22, Color.WHITE, true)


func _spoils_item_card(item: Dictionary) -> PanelContainer:
	var accent: Color = item.get("color", Color(0.85, 0.82, 0.72))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(210.0, 150.0)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.055, 0.06, 0.085, 0.96)
	st.border_color = accent.lerp(Color.WHITE, 0.12)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(corner, 6)
	card.add_theme_stylebox_override("panel", st)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	_spoils_label(box, str(item.get("label", "")).to_upper(), 9, accent, true)
	_spoils_label(box, str(item.get("icon", "")), 24, Color.WHITE, true)
	_spoils_label(box, str(item.get("name", "?")), 13, Color(0.96, 0.94, 0.88), true)
	_spoils_label(box, str(item.get("slot", "")).to_upper(), 9, Color(0.54, 0.58, 0.66), true)
	var affixes: Array = item.get("affixes", [])
	for i in range(min(affixes.size(), 2)):
		var affix: Dictionary = affixes[i]
		_spoils_label(box, "- " + str(affix.get("label", "")), 10, Color(0.78, 0.82, 0.88), false)
	return card


func _on_spoils_continue() -> void:
	_play_sfx("ui_confirm")
	if _spoils_overlay:
		_spoils_overlay.queue_free()
		_spoils_overlay = null
	spoils_continue_requested.emit()


func _build_settings_overlay() -> void:
	_settings_overlay = Control.new()
	_settings_overlay.visible = false
	_settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_settings_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.58)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(400.0, 146.0)
	panel.custom_minimum_size = Vector2(480.0, 360.0)
	_settings_overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(box)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62))
	box.add_child(title)

	var hint := Label.new()
	hint.text = "Press Esc to return"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.70, 0.76, 0.84))
	box.add_child(hint)

	_game_slider = _add_volume_slider(box, "Game", _on_game_volume_changed)
	_music_slider = _add_volume_slider(box, "Music", _on_music_volume_changed)
	_fx_slider = _add_volume_slider(box, "FX", _on_fx_volume_changed)

	var close_btn := Button.new()
	close_btn.text = "Return"
	close_btn.custom_minimum_size = Vector2(120.0, 38.0)
	close_btn.pressed.connect(_toggle_settings_overlay)
	box.add_child(close_btn)

	_refresh_audio_settings_controls()


func _add_volume_slider(parent: Control, label_text: String, callback: Callable) -> HSlider:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var labels := HBoxContainer.new()
	row.add_child(labels)

	var name_label := Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 13)
	labels.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "100"
	value_label.custom_minimum_size.x = 42.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 13)
	labels.add_child(value_label)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	row.add_child(slider)

	match label_text:
		"Game":
			_game_value_label = value_label
		"Music":
			_music_value_label = value_label
		"FX":
			_fx_value_label = value_label

	return slider


func _toggle_settings_overlay() -> void:
	if not _settings_overlay:
		return
	_settings_overlay.visible = not _settings_overlay.visible
	if _settings_overlay.visible:
		_refresh_audio_settings_controls()


func _refresh_audio_settings_controls() -> void:
	var audio := _audio_settings()
	if not audio:
		return
	_set_slider_value(_game_slider, _game_value_label, audio.game_volume)
	_set_slider_value(_music_slider, _music_value_label, audio.music_volume)
	_set_slider_value(_fx_slider, _fx_value_label, audio.fx_volume)


func _set_slider_value(slider: HSlider, label: Label, value: int) -> void:
	if slider:
		slider.set_value_no_signal(value)
	if label:
		label.text = "%d" % value


func _audio_settings() -> Node:
	return get_node_or_null("/root/AudioSettings")


func _separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.25, 0.28, 0.32))
	return sep


func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", DISPLAY_FONT)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	return lbl


func _stat_label(parent: Control, prefix: String) -> Label:
	var lbl := Label.new()
	lbl.text = "%s: " % prefix
	lbl.add_theme_font_size_override("font_size", 12)
	parent.add_child(lbl)
	return lbl


func _cmd_btn(parent: Control, label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(96, 40)
	btn.disabled = true
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _timeline_slot(parent: Control) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(62, 42)
	var lbl := Label.new()
	lbl.text = ""
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(lbl)
	parent.add_child(panel)
	return lbl


#  Signal handlers

func _on_log(text: String) -> void:
	for i in range(LOG_SIZE - 1, 0, -1):
		_log_labels[i].text = _log_labels[i - 1].text
	_log_labels[0].text = "> " + text


func _on_phase_changed(phase: String) -> void:
	_phase_label.text = phase.replace("_", " ")
	_is_player_turn = phase == "PLAYER_TURN"
	_refresh_command_buttons()
	if _ability_panel: _ability_panel.visible = false


func _on_game_volume_changed(value: float) -> void:
	var audio := _audio_settings()
	if audio:
		audio.set_game_volume(value)
	if _game_value_label:
		_game_value_label.text = "%d" % int(round(value))


func _on_music_volume_changed(value: float) -> void:
	var audio := _audio_settings()
	if audio:
		audio.set_music_volume(value)
	if _music_value_label:
		_music_value_label.text = "%d" % int(round(value))


func _on_fx_volume_changed(value: float) -> void:
	var audio := _audio_settings()
	if audio:
		audio.set_fx_volume(value)
	if _fx_value_label:
		_fx_value_label.text = "%d" % int(round(value))


func _on_tile_info_changed(text: String) -> void:
	if _tile_info_label:
		_tile_info_label.text = text


func _on_command_hint_changed(text: String) -> void:
	if _command_hint_label:
		_command_hint_label.text = text


func _on_objective_updated(text: String) -> void:
	if _objective_label:
		_objective_label.text = text


func _on_enemy_intent_changed(intent: Dictionary) -> void:
	if not _enemy_intent_panel:
		return
	if intent.is_empty():
		_enemy_intent_panel.visible = false
		return
	_enemy_intent_panel.visible = true
	if str(intent.get("kind", "")) == "board":
		_enemy_intent_title.text = "ENEMY PLANS"
		_enemy_intent_title.add_theme_color_override("font_color", Color(1.0, 0.62, 0.36))
		_enemy_intent_body.text = _format_enemy_intent_board(intent.get("rows", []))
		_enemy_intent_body.add_theme_color_override("font_color", Color(0.92, 0.90, 0.84))
		_style_enemy_intent_panel("normal")
		return
	var actor := str(intent.get("actor", "Enemy"))
	var action := str(intent.get("action", "Act"))
	var target := str(intent.get("target", "-"))
	var note := str(intent.get("note", ""))
	var details: Dictionary = intent.get("details", {})
	var damage := int(details.get("damage", 0))
	var danger := str(intent.get("danger", "normal"))
	var danger_color := Color(0.92, 0.90, 0.84)
	if danger == "lethal":
		danger_color = Color(1.0, 0.35, 0.35)
	elif danger == "high":
		danger_color = Color(1.0, 0.65, 0.2)
	elif damage > 0:
		danger_color = Color(1.0, 0.88, 0.4)
	_enemy_intent_title.text = "ENEMY INTENT - %s" % actor.to_upper()
	_enemy_intent_title.add_theme_color_override("font_color", Color(1.0, 0.62, 0.36))
	var body_parts: Array[String] = []
	body_parts.append("%s -> %s" % [action, target])
	var detail_text := _format_enemy_intent_details(intent, details)
	if not detail_text.is_empty():
		body_parts.append(detail_text)
	if not note.is_empty():
		body_parts.append(note)
	_enemy_intent_body.text = "\n".join(body_parts)
	_enemy_intent_body.add_theme_color_override("font_color", danger_color)

	_style_enemy_intent_panel(danger)


func _style_enemy_intent_panel(danger: String) -> void:
	if _enemy_intent_panel:
		var panel_style := StyleBoxFlat.new()
		panel_style.content_margin_left = 8.0
		panel_style.content_margin_right = 8.0
		panel_style.content_margin_top = 6.0
		panel_style.content_margin_bottom = 6.0

		match danger:
			"lethal":
				panel_style.bg_color = Color(0.12, 0.04, 0.04, 0.92)
				panel_style.border_color = Color(1.0, 0.2, 0.2, 0.9)
				for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
					panel_style.set_border_width(side, 2)
			"high":
				panel_style.bg_color = Color(0.12, 0.08, 0.04, 0.92)
				panel_style.border_color = Color(1.0, 0.55, 0.2, 0.9)
				for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
					panel_style.set_border_width(side, 2)
			"medium":
				panel_style.bg_color = Color(0.06, 0.08, 0.10, 0.92)
				panel_style.border_color = Color(1.0, 0.75, 0.3, 0.7)
				for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
					panel_style.set_border_width(side, 1)
			_:
				panel_style.bg_color = Color(0.05, 0.06, 0.085, 0.92)
				panel_style.border_color = Color(0.4, 0.6, 0.8, 0.6)
				for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
					panel_style.set_border_width(side, 1)

		for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
			panel_style.set_corner_radius(corner, 6)
		_enemy_intent_panel.add_theme_stylebox_override("panel", panel_style)


func _format_enemy_intent_board(rows_variant: Variant) -> String:
	var rows: Array = []
	if rows_variant is Array:
		rows = rows_variant
	if rows.is_empty():
		return "No enemies remain."
	var lines: Array[String] = []
	var max_rows := mini(rows.size(), 4)
	for i in range(max_rows):
		var row: Dictionary = rows[i]
		var actor := str(row.get("actor", "Enemy"))
		var target := str(row.get("target", "-"))
		var danger := str(row.get("danger", "normal")).to_upper()
		var details: Dictionary = row.get("details", {})
		var dmg := int(details.get("damage", 0))
		var hp_after := int(details.get("target_hp_after", -1))
		var suffix := ""
		var area_label := str(details.get("area_label", ""))
		if not area_label.is_empty():
			suffix += "  " + area_label
		if dmg > 0:
			suffix += "  %d dmg" % dmg
			if hp_after >= 0:
				suffix += ", leaves %d HP" % hp_after
		elif dmg < 0:
			suffix += "  heals %d" % abs(dmg)
		var move_label := str(details.get("move_label", ""))
		if not move_label.is_empty():
			suffix += "  " + move_label
		lines.append("%s: %s -> %s%s" % [danger, actor, target, suffix])
	if rows.size() > max_rows:
		lines.append("+%d more enemy plan(s)" % (rows.size() - max_rows))
	return "\n".join(lines)


func _format_enemy_intent_details(intent: Dictionary, details: Dictionary) -> String:
	var parts: Array[String] = []
	var dmg := int(details.get("damage", 0))
	if dmg > 0:
		var line := "%d dmg" % dmg
		var hp_after := int(details.get("target_hp_after", -1))
		if hp_after >= 0:
			line += ", target HP %d" % hp_after
		if bool(details.get("can_ko", false)):
			line += " - KO threat"
		parts.append(line)
	elif dmg < 0:
		parts.append("Heals %d HP" % abs(dmg))
	var area_label := str(details.get("area_label", ""))
	if not area_label.is_empty():
		parts.append(area_label)
	if dmg > 0:
		parts.append("Hit %d%%" % int(details.get("hit_pct", 100)))
		var crit := int(details.get("crit_pct", 0))
		if crit > 0:
			parts.append("Crit %d%%" % crit)
	var move_label := str(details.get("move_label", ""))
	if not move_label.is_empty():
		parts.append(move_label)
	var intent_range := int(details.get("range", 0))
	if intent_range > 0:
		parts.append("Range %d" % intent_range)
	var affinity := str(details.get("affinity_label", ""))
	if not affinity.is_empty():
		parts.append(affinity)
	var danger := str(intent.get("danger", ""))
	if danger == "lethal":
		parts.append("Priority: lethal")
	elif danger == "high":
		parts.append("Priority: high")
	return "    ".join(parts)

func _on_action_preview_changed(preview: Dictionary) -> void:
	if not _preview_panel:
		return
	if preview.is_empty() or preview.get("visible", false) != true:
		_preview_panel.visible = false
		return
	_preview_panel.visible = true

	var el_color: Color = preview.get("element_color", Color(0.9, 0.85, 0.6))
	var is_heal: bool = preview.get("is_heal", false) == true
	var is_buff: bool = preview.get("is_buff", false) == true
	var aff_lbl: String = str(preview.get("affinity_label", ""))
	var aff_col: Color = preview.get("affinity_color", Color.WHITE)

	var el_icon: String = str(preview.get("element_icon", ""))
	var mode: String = str(preview.get("mode", "Forecast")).to_upper()
	_preview_mode_label.text = ("%s  %s" % [el_icon, mode]).strip_edges()
	_preview_mode_label.add_theme_color_override("font_color", el_color)

	_preview_actor_label.text = "ATTACKER\n%s" % str(preview.get("actor_name", preview.get("actor", "-")))

	var ab_name: String = str(preview.get("ability_name", preview.get("action", "")))
	var boon_pct: int = int(preview.get("boon_bonus_pct", 0))
	var ab_text: String = ab_name
	if boon_pct > 0:
		ab_text += "\n+%d%% boon" % boon_pct
	_preview_action_label.text = ab_text
	_preview_action_label.add_theme_color_override("font_color", el_color)

	var t_name: String = str(preview.get("target_name", preview.get("target", "-")))
	var hp_b: int = int(preview.get("hp_before", 0))
	var hp_a: int = int(preview.get("hp_after", 0))
	var max_hp: int = int(preview.get("max_hp", 1))
	var hp_text := ""
	if hp_b > 0:
		hp_text = "\nHP %d -> %d" % [hp_b, hp_a]
		if hp_a <= 0:
			hp_text += "  KO"
	_preview_target_label.text = "TARGET\n%s%s" % [t_name, hp_text]
	_preview_target_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55) if hp_a <= 0 and hp_b > 0 else Color(1.0, 0.76, 0.72))

	var dmg: int = int(preview.get("damage", 0))
	var heal: int = int(preview.get("heal", 0))
	if is_heal:
		_preview_amount_label.text = "+%d HP" % heal
		_preview_amount_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55))
	elif is_buff:
		_preview_amount_label.text = "BUFF"
		_preview_amount_label.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	elif preview.has("amount_label"):
		_preview_amount_label.text = str(preview.get("amount_label", ""))
		_preview_amount_label.add_theme_color_override("font_color", el_color)
	else:
		var dmin: int = int(preview.get("damage_min", dmg))
		var dmax: int = int(preview.get("damage_max", dmg))
		_preview_amount_label.text = "%d-%d" % [dmin, dmax] if dmax > dmin else str(dmg)
		_preview_amount_label.add_theme_color_override("font_color", el_color)

	if not aff_lbl.is_empty():
		var aff_display := "%s  %s" % [str(preview.get("element_icon", "")), aff_lbl]
		var affinity_val: float = float(preview.get("affinity", 1.0))
		if affinity_val >= 2.0:
			aff_display += " !!"
		elif affinity_val > 1.0:
			aff_display += " !"
		_preview_hit_label.text = aff_display
		_preview_hit_label.add_theme_color_override("font_color", aff_col)
	else:
		var hit: int = int(preview.get("hit_pct", 100))
		var hit_confidence := ""
		if hit >= 95:
			hit_confidence = " high"
		elif hit >= 75:
			hit_confidence = " steady"
		elif hit >= 50:
			hit_confidence = " risky"
		else:
			hit_confidence = " poor"
		_preview_hit_label.text = "Hit %d%%%s" % [hit, hit_confidence]
		_preview_hit_label.add_theme_color_override("font_color", Color(0.75, 0.95, 0.85))

	var jp: int = int(preview.get("jp_gain", 6))
	var crit_pct: int = int(preview.get("crit_pct", 0))
	var crit_text := "+%d JP" % jp
	if crit_pct > 0:
		crit_text = "Crit %d%%  +%d JP" % [crit_pct, jp]
	if hp_b > 0 and hp_a <= 0:
		crit_text += "  KO"
	elif hp_b > 0 and max_hp > 0 and float(hp_a) / float(max_hp) < 0.25:
		crit_text += "  Low HP"
	_preview_crit_label.text = crit_text
	_preview_crit_label.add_theme_color_override("font_color", Color(0.48, 0.86, 1.0))

	# Organize notes by priority for better readability
	var critical_notes: Array[String] = []
	var tactical_notes: Array[String] = []
	var detail_notes: Array[String] = []

	# Critical effects first (status, danger)
	var status_p: String = str(preview.get("status_preview", ""))
	if not status_p.is_empty():
		critical_notes.append("Status: " + status_p)
	if preview.get("can_counter", false) == true:
		critical_notes.append("Counter possible")

	# Tactical advantages second (flank, height, facing)
	var flank_l: String = str(preview.get("flank_label", ""))
	if not flank_l.is_empty():
		tactical_notes.append("Facing: " + flank_l)
	var height_rule: String = str(preview.get("height_rule_label", ""))
	if not height_rule.is_empty():
		tactical_notes.append(height_rule)
	var facing_rule: String = str(preview.get("facing_rule_label", ""))
	if not facing_rule.is_empty():
		tactical_notes.append(facing_rule)
	var run_bonus_notes: Array = preview.get("run_bonus_notes", []) as Array
	for bonus_note_variant in run_bonus_notes:
		tactical_notes.append(str(bonus_note_variant))

	# Details last (range, formula explanations)
	var range_l: String = str(preview.get("range_label", ""))
	if not range_l.is_empty():
		detail_notes.append(range_l)
	var height_l: String = str(preview.get("height_label", ""))
	if not height_l.is_empty():
		detail_notes.append(height_l)
	var aoe_n: String = str(preview.get("aoe_note", ""))
	if not aoe_n.is_empty():
		detail_notes.append(aoe_n)
	var formula_explain: Array = preview.get("formula_explain", [])
	if not formula_explain.is_empty():
		detail_notes.append("Formula: " + " / ".join(formula_explain))
	var note: String = str(preview.get("note", ""))
	if not note.is_empty():
		detail_notes.append(note)

	var notes: Array[String] = critical_notes + tactical_notes + detail_notes
	_preview_note_label.text = " | ".join(notes)
	_preview_note_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))

	_set_preview_portrait(_preview_actor_portrait, str(preview.get("actor_portrait", "")))
	_set_preview_portrait(_preview_target_portrait, str(preview.get("target_portrait", "")))

func _on_action_state_changed(can_move: bool, can_act: bool, has_pending: bool) -> void:
	_can_move_now = can_move
	_can_act_now = can_act
	_has_pending_action = has_pending
	if _action_state_label:
		var move_text := "Ready" if can_move else "Used"
		var act_text := "Ready" if can_act else "Used"
		_action_state_label.text = "Move: %s    Action: %s" % [move_text, act_text]
	_refresh_command_buttons()


func _refresh_command_buttons() -> void:
	if _move_btn:
		_move_btn.disabled = not _is_player_turn or not _can_move_now or _has_pending_action
	if _attack_btn:
		_attack_btn.disabled = not _is_player_turn or not _can_act_now or _has_pending_action
	if _ability_btn:
		_ability_btn.disabled = not _is_player_turn or not _can_act_now or _has_pending_action
	if _wait_btn:
		_wait_btn.disabled = not _is_player_turn or _has_pending_action
	if _confirm_btn:
		_confirm_btn.disabled = not _has_pending_action
	if _cancel_btn:
		_cancel_btn.disabled = not _has_pending_action


func _set_preview_portrait(rect: TextureRect, path: String) -> void:
	if not rect:
		return
	if path.is_empty():
		rect.texture = null
		return
	rect.texture = _texture_from_source(path)


func _texture_from_source(path: String) -> Texture2D:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var bytes := file.get_buffer(file.get_length())
	if bytes.size() >= 7 and bytes.slice(0, 7).get_string_from_ascii() == "version":
		return null
	var image := Image.new()
	var err := image.load_png_from_buffer(bytes)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)

func _show_status_banner(title_text: String, subtitle_text: String, accent: Color,
		hold_time: float = 1.4) -> void:
	if not _intro_banner:
		return
	var title := _intro_banner.get_node_or_null("VBoxContainer/Title") as Label
	var subtitle := _intro_banner.get_node_or_null("VBoxContainer/Subtitle") as Label
	if title:
		title.text = title_text
		title.add_theme_color_override("font_color", accent)
	if subtitle:
		subtitle.text = subtitle_text
	if _intro_banner_style:
		_intro_banner_style.border_color = accent.lerp(Color.WHITE, 0.12)
	_intro_banner.modulate.a = 1.0
	_intro_banner.visible = true
	var tw := create_tween()
	tw.tween_interval(hold_time)
	tw.tween_property(_intro_banner, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func() -> void: _intro_banner.visible = false)


func _on_battle_started(display_name: String, objective: String) -> void:
	if _mission_label:
		_mission_label.text = display_name.to_upper()
	if _objective_label:
		_objective_label.text = objective
	_show_status_banner(display_name.to_upper(), objective, Color(1.0, 0.92, 0.62))


func _on_turn_started(unit_id: String, _team: String) -> void:
	if not battle_manager:
		return
	var unit: Unit = battle_manager.units.get(unit_id)
	if not unit:
		return
	_unit_name.text = unit.display_name
	var max_hp := unit.unit_data.base_stats.hp
	_hp_bar.max_value = max_hp
	_hp_bar.value = unit.hp
	_hp_label.text    = "HP: %d/%d" % [unit.hp, max_hp]
	_mp_label.text    = "MP: %d" % unit.mp
	_temper_label.text = "TMP: %d" % unit.temper
	_ether_label.text  = "ETH: %d" % unit.ether
	# Status icons
	if unit.statuses.is_empty():
		_status_label.text = ""
	else:
		var parts: Array[String] = []
		for s: StatusEffect in unit.statuses:
			parts.append("%s(%d)" % [s.status_id.to_upper(), s.duration])
		_status_label.text = "  ".join(parts)


func _on_timeline_updated(ordered_units: Array) -> void:
	for i in range(TIMELINE_SLOTS):
		if i < ordered_units.size():
			_timeline_labels[i].text = ordered_units[i].get("display_name", "?")
			if i < _side_timeline_labels.size():
				_side_timeline_labels[i].text = "%d  %s" % [i + 1, ordered_units[i].get("display_name", "?")]
		else:
			if i < _side_timeline_labels.size():
				_side_timeline_labels[i].text = "%d  -" % (i + 1)
			_timeline_labels[i].text = ""


func _on_battle_won(rewards: Dictionary) -> void:
	_phase_label.text = "VICTORY!"
	_result_label.text = "+%dg  +%dJP" % [rewards.get("gold", 0), rewards.get("jp", 0)]
	if _objective_label:
		_objective_label.text = "Objective complete"
	_show_status_banner(
		"VICTORY",
		"+%dg  +%dJP" % [rewards.get("gold", 0), rewards.get("jp", 0)],
		Color(1.0, 0.86, 0.22),
		1.8
	)
	_is_player_turn = false
	_has_pending_action = false
	if _move_btn:    _move_btn.disabled    = true
	if _attack_btn:  _attack_btn.disabled  = true
	if _ability_btn: _ability_btn.disabled = true
	if _wait_btn:    _wait_btn.disabled    = true
	if _confirm_btn: _confirm_btn.disabled = true
	if _cancel_btn:  _cancel_btn.disabled  = true


func _on_battle_lost() -> void:
	_phase_label.text = "DEFEATED"
	_result_label.text = "All units fallen."
	if _objective_label:
		_objective_label.text = "Party defeated"
	_show_status_banner("DEFEATED", "Returning to the hub.", Color(1.0, 0.32, 0.26), 1.8)
	_is_player_turn = false
	_has_pending_action = false
	if _move_btn:    _move_btn.disabled    = true
	if _attack_btn:  _attack_btn.disabled  = true
	if _ability_btn: _ability_btn.disabled = true
	if _wait_btn:    _wait_btn.disabled    = true
	if _confirm_btn: _confirm_btn.disabled = true
	if _cancel_btn:  _cancel_btn.disabled  = true


func _on_ability_mode_started(usable_ids: Array) -> void:
	# Clear old buttons
	for child in _ability_list.get_children():
		child.queue_free()
	if usable_ids.is_empty():
		_result_label.text = "No usable abilities."
		return
	_ability_panel.visible = true
	for ab_id in usable_ids:
		var ab: Dictionary = AbilityDB.get_ability(ab_id)
		var el:       String = ab.get("spell_type", "")
		var el_icon:  String = ForecastCalculator.ELEMENT_ICONS.get(el, "")
		var el_col:   Color  = ForecastCalculator.ELEMENT_COLORS.get(el, Color(0.85,0.82,0.77))
		var aoe_type: String = ab.get("aoe_type", "")
		var shape_icon:  String = ForecastCalculator.AOE_SHAPE_ICONS.get(aoe_type, "")
		var shape_label: String = ForecastCalculator.AOE_SHAPE_LABELS.get(aoe_type, "")
		var mp:  int = ab.get("mp_cost", 0)
		var rng: int = ab.get("range", 0)

		# Outer button  transparent clickable container.
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.flat = true
		var st_btn := StyleBoxFlat.new()
		st_btn.bg_color = el_col.darkened(0.82)
		st_btn.border_color = el_col.darkened(0.35)
		st_btn.set_border_width_all(1)
		st_btn.set_corner_radius_all(0)
		st_btn.content_margin_left  = 4
		st_btn.content_margin_right = 4
		st_btn.content_margin_top   = 3
		st_btn.content_margin_bottom = 3
		btn.add_theme_stylebox_override("normal", st_btn)
		var st_hover := st_btn.duplicate() as StyleBoxFlat
		st_hover.bg_color = el_col.darkened(0.55)
		btn.add_theme_stylebox_override("hover", st_hover)
		var st_press := st_btn.duplicate() as StyleBoxFlat
		st_press.bg_color = el_col.darkened(0.30)
		btn.add_theme_stylebox_override("pressed", st_press)

		# Layout inside button.
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(row)

		# Element icon badge (colored square, 3232).
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(32, 32)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st_badge := StyleBoxFlat.new()
		st_badge.bg_color = el_col.darkened(0.4)
		st_badge.set_border_width_all(0)
		st_badge.set_corner_radius_all(0)
		badge.add_theme_stylebox_override("panel", st_badge)
		var badge_lbl := Label.new()
		badge_lbl.text = el_icon
		badge_lbl.add_theme_font_size_override("font_size", 18)
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(badge_lbl)
		row.add_child(badge)

		# Name + stats column.
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 1)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(col)

		var name_lbl := Label.new()
		name_lbl.text = ab.get("display_name", ab_id)
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(0.97, 0.94, 0.87))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(name_lbl)

		var stat_row := HBoxContainer.new()
		stat_row.add_theme_constant_override("separation", 6)
		stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(stat_row)

		var mp_lbl := Label.new()
		mp_lbl.text = ("%dMP" % mp) if mp > 0 else "free"
		mp_lbl.add_theme_font_size_override("font_size", 10)
		mp_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		mp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stat_row.add_child(mp_lbl)

		if rng > 0:
			var rng_lbl := Label.new()
			rng_lbl.text = "%d" % rng
			rng_lbl.add_theme_font_size_override("font_size", 10)
			rng_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			rng_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stat_row.add_child(rng_lbl)

		# Shape badge  right-aligned.
		if not shape_label.is_empty():
			var shape_lbl := Label.new()
			shape_lbl.text = "%s %s" % [shape_icon, shape_label]
			shape_lbl.add_theme_font_size_override("font_size", 10)
			shape_lbl.add_theme_color_override("font_color", el_col.lightened(0.25))
			shape_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
			shape_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stat_row.add_child(shape_lbl)

		var captured_id: String = ab_id
		btn.pressed.connect(func() -> void:
			_play_sfx("ui_confirm")
			_ability_panel.visible = false
			if battle_manager:
				battle_manager.select_ability(captured_id))
		_ability_list.add_child(btn)


#  Button callbacks

func _on_move() -> void:
	_play_sfx("ui_confirm")
	if battle_manager: battle_manager.select_command("move")

func _on_attack() -> void:
	_play_sfx("ui_confirm")
	if battle_manager: battle_manager.select_command("attack")

func _on_wait() -> void:
	_play_sfx("ui_confirm")
	if battle_manager: battle_manager.select_command("wait")

func _on_ability() -> void:
	_play_sfx("ui_confirm")
	if battle_manager: battle_manager.select_command("ability")


func _on_confirm() -> void:
	_play_sfx("ui_confirm")
	if battle_manager: battle_manager.confirm_pending_action()


func _on_cancel() -> void:
	_play_sfx("ui_confirm")
	if battle_manager: battle_manager.cancel_pending_action()


func _play_sfx(sfx_id: String) -> void:
	var audio := _audio_settings()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(sfx_id)
