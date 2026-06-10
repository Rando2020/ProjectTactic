class_name AntechamberScene
extends Control

const DISPLAY_FONT := preload("res://assets/fonts/TrajanPro-Regular.ttf")
const CINZEL_FONT := preload("res://assets/fonts/Cinzel-Regular.ttf")
const SacredSelection := preload("res://scripts/ui/SacredSelectionStyle.gd")

const STAGE_SELECT_SCENE := "res://scenes/StageSelect.tscn"
const CHARACTER_SCENE := "res://scenes/CharacterScreen.tscn"
const START_SCENE := "res://scenes/StartScreen.tscn"
const INN_SCENE := preload("res://scenes/InnScreen.tscn")
const INVENTORY_SCENE := preload("res://scenes/InventoryScreen.tscn")
const CODEX_SCENE := preload("res://scenes/CodexScreen.tscn")

const C_BG := Color(0.012, 0.011, 0.016)
const C_PANEL := Color(0.036, 0.032, 0.044, 0.95)
const C_PANEL_ALT := Color(0.052, 0.037, 0.028, 0.95)
const C_PANEL_BLUE := Color(0.028, 0.042, 0.054, 0.95)
const C_PANEL_PURPLE := Color(0.044, 0.032, 0.062, 0.95)
const C_PANEL_RED := Color(0.060, 0.025, 0.020, 0.94)
const C_GOLD := Color(0.83, 0.60, 0.28)
const C_GOLD_BRIGHT := Color(1.0, 0.82, 0.45)
const C_GOLD_DIM := Color(0.42, 0.29, 0.12)
const C_TEXT := Color(0.90, 0.82, 0.64)
const C_MUTED := Color(0.58, 0.50, 0.39)
const C_DISABLED := Color(0.36, 0.33, 0.30)
const C_SOUL := Color(0.78, 0.45, 1.0)
const C_OBSIDIAN := Color(0.62, 0.65, 0.68)
const C_GLYPH := Color(0.32, 0.78, 1.0)
const C_BOSS := Color(0.96, 0.24, 0.17)

var _gs: Node
var _meta: Node
var _run_mgr: Node
var _message_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gs = get_node_or_null("/root/GameState")
	_meta = get_node_or_null("/root/MetaProgression")
	_run_mgr = get_node_or_null("/root/RunManager")
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file(START_SCENE)


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_add_texture_noise()

	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 28)
	frame.add_theme_constant_override("margin_right", 28)
	frame.add_theme_constant_override("margin_top", 18)
	frame.add_theme_constant_override("margin_bottom", 18)
	add_child(frame)

	var outer := _panel(C_PANEL, C_GOLD_DIM, 2, 0)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(outer)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 22)
	pad.add_theme_constant_override("margin_top", 18)
	pad.add_theme_constant_override("margin_bottom", 18)
	outer.add_child(pad)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 14)
	pad.add_child(root)

	_build_header(root)
	_build_main_grid(root)
	_build_npc_strip(root)
	_build_footer(root)


func _add_texture_noise() -> void:
	for i in range(28):
		var line := ColorRect.new()
		line.color = Color(0.20, 0.16, 0.10, 0.035)
		line.size = Vector2(1200.0 + float(i * 17), 1.0)
		line.position = Vector2(40.0 + float((i * 73) % 340), 40.0 + float(i * 31))
		line.rotation = 0.02 * sin(float(i))
		add_child(line)


func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 134
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 20)
	parent.add_child(header)

	var sigil := _panel(Color(0.018, 0.017, 0.024, 0.96), C_GOLD_DIM, 2, 0)
	sigil.custom_minimum_size = Vector2(114, 114)
	header.add_child(sigil)
	var sigil_box := VBoxContainer.new()
	sigil_box.alignment = BoxContainer.ALIGNMENT_CENTER
	sigil_box.add_theme_constant_override("separation", 0)
	sigil.add_child(sigil_box)
	sigil_box.add_child(_label("A", 58, C_GOLD_BRIGHT, true, HORIZONTAL_ALIGNMENT_CENTER))
	sigil_box.add_child(_label("ASCENT", 11, C_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER))

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 3)
	header.add_child(title_stack)
	title_stack.add_child(_label("THE APPOINTED: AS ABOVE", 14, C_GOLD, true))
	title_stack.add_child(_label("EIDOLON CHRONICLES", 44, C_TEXT, true))
	title_stack.add_child(_label("ANTECHAMBER OF ASCENT", 22, C_GOLD_BRIGHT, true))
	title_stack.add_child(_label("Strengthen the vessel. Prepare the descent. Obey the Design.", 15, C_MUTED))

	var currencies := GridContainer.new()
	currencies.columns = 4
	currencies.custom_minimum_size = Vector2(690, 92)
	currencies.add_theme_constant_override("h_separation", 12)
	currencies.add_theme_constant_override("v_separation", 8)
	header.add_child(currencies)
	_currency_card(currencies, "SOUL SHARDS", "soul-shards", C_SOUL)
	_currency_card(currencies, "OBSIDIAN", "obsidian", C_OBSIDIAN)
	_currency_card(currencies, "GLYPHS", "glyphs", C_GLYPH)
	_currency_card(currencies, "BOSS TOKENS", "boss-tokens", C_BOSS)


func _currency_card(parent: Control, title: String, currency_id: String, tint: Color) -> void:
	var card := _panel(Color(tint.r * 0.08, tint.g * 0.08, tint.b * 0.08, 0.72), C_GOLD_DIM, 1, 0)
	card.custom_minimum_size = Vector2(162, 84)
	parent.add_child(card)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var icon := _label(_currency_icon(currency_id), 32, tint, true, HORIZONTAL_ALIGNMENT_CENTER)
	icon.custom_minimum_size.x = 40
	row.add_child(icon)

	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(copy)
	copy.add_child(_label(title, 12, C_GOLD, true))
	copy.add_child(_label(str(_get_currency(currency_id)), 28, C_TEXT, true))


func _build_main_grid(parent: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	parent.add_child(grid)

	_build_body_training(grid)
	_build_heat_altar(grid)
	_build_guardian_shrine(grid)
	_build_job_reliquary(grid)


func _build_body_training(parent: Control) -> void:
	var card := _section(parent, "BODY TRAINING", "Permanent power applied to every run.", C_PANEL_BLUE, C_GOLD_DIM)
	var rows := _rows_container(card)
	_training_row(rows, "HP", "Max HP", "max_hp", 20, {"soul-shards": 20})
	_training_row(rows, "PH", "Physical Power", "physical", 35, {"soul-shards": 35})
	_training_row(rows, "MG", "Magic Power", "magic", 25, {"soul-shards": 25})


func _training_row(parent: VBoxContainer, icon: String, label_text: String, stat_id: String,
		base_cost: int, cost: Dictionary) -> void:
	var level := _get_upgrade(stat_id)
	var bonus := _stat_bonus(stat_id)
	var scaled_cost := cost.duplicate()
	for key in scaled_cost.keys():
		scaled_cost[key] = base_cost + level * base_cost
	var row := _action_row(parent, icon, label_text, "Lv %d" % level, _cost_text(scaled_cost), _can_spend(scaled_cost))
	row.pressed.connect(func() -> void:
		if _spend(scaled_cost):
			_meta.add_upgrade(stat_id)
			if _meta.has_method("save"):
				_meta.save()
			_build_ui()
		else:
			_show_msg("Not enough currency."))
	row.tooltip_text = "Current bonus: +%d" % bonus


func _build_heat_altar(parent: Control) -> void:
	var card := _section(parent, "HEAT ALTAR", "Optional difficulty. Greater heat, greater rewards.", C_PANEL_ALT, Color(0.74, 0.25, 0.10))
	var rows := _rows_container(card)
	_heat_row(rows, 1, {"soul-shards": 30})
	_heat_row(rows, 2, {"soul-shards": 55, "boss-tokens": 1})
	_heat_row(rows, 3, {"soul-shards": 90, "boss-tokens": 2, "obsidian": 15})


func _heat_row(parent: VBoxContainer, level: int, cost: Dictionary) -> void:
	var unlocked: bool = _meta != null and int(_meta.get("max_heat_unlocked")) >= level
	var selected: bool = _meta != null and int(_meta.get("selected_heat_level")) == level
	var label_text: String = "Heat %s" % _roman(level)
	var state: String = "Selected" if selected else ("Unlocked" if unlocked else "Unlock")
	var row: Button = _action_row(parent, _roman(level), label_text, state, _cost_text(cost), unlocked or _can_spend(cost), selected)
	row.pressed.connect(func() -> void:
		if not _meta:
			_show_msg("Meta progression is unavailable.")
			return
		if unlocked:
			_meta.selected_heat_level = level
			_meta.save()
			_build_ui()
			return
		if _spend(cost):
			_meta.max_heat_unlocked = maxi(level, int(_meta.max_heat_unlocked))
			_meta.selected_heat_level = level
			_meta.save()
			_build_ui()
		else:
			_show_msg("Not enough currency."))


func _build_guardian_shrine(parent: Control) -> void:
	var card := _section(parent, "GUARDIAN SHRINE", "Unlock stronger boons for each Primal Guardian.", C_PANEL, C_GOLD_DIM)
	var rows := _rows_container(card)
	_unlock_row(rows, "IF", "Ignareth's Deeper Flame", "guardian-ignareth-deeper-flame", {"glyphs": 8, "phoenix-sigils": 5})
	_unlock_row(rows, "NV", "Nerevan's Tide Memory", "guardian-nerevan-tide-memory", {"glyphs": 8, "phoenix-sigils": 5})
	_unlock_row(rows, "TS", "Torvakh's Storm Pattern", "guardian-torvakh-storm-pattern", {"glyphs": 8, "titan-sigils": 5})
	_unlock_row(rows, "LM", "Luminarch's Sacred Memory", "guardian-luminarch-sacred-memory", {"glyphs": 8, "titan-sigils": 5})
	_unlock_row(rows, "VE", "Vaelthorn's Echo Fragment", "guardian-vaelthorn-echo-fragment", {"glyphs": 10, "boss-tokens": 1})


func _build_job_reliquary(parent: Control) -> void:
	var card := _section(parent, "JOB RELIQUARY", "Spend rare materials to open deeper job routes.", C_PANEL_PURPLE, Color(0.55, 0.28, 0.72))
	var rows := _rows_container(card)
	_unlock_row(rows, "BK", "Advanced Jobs", "advanced-jobs-unlocked", {"obsidian": 10, "boss-tokens": 1})
	_unlock_row(rows, "AX", "Ascended Jobs", "ascended-jobs-unlocked", {"obsidian": 25, "boss-tokens": 3})
	_unlock_row(rows, "SK", "Secret Skill Slots", "secret-skill-slots", {"obsidian": 20, "glyphs": 10})


func _unlock_row(parent: VBoxContainer, icon: String, label_text: String, flag_id: String, cost: Dictionary) -> void:
	var unlocked: bool = _meta != null and _meta.has_method("has_unlock") and _meta.has_unlock(flag_id)
	var row: Button = _action_row(parent, icon, label_text, "Unlocked" if unlocked else "Locked", _cost_text(cost), unlocked or _can_spend(cost), unlocked)
	row.disabled = unlocked
	row.pressed.connect(func() -> void:
		if unlocked:
			return
		if _spend(cost):
			_meta.add_unlock(flag_id)
			_meta.save()
			_build_ui()
		else:
			_show_msg("Not enough currency."))


func _build_npc_strip(parent: VBoxContainer) -> void:
	var strip := HBoxContainer.new()
	strip.custom_minimum_size.y = 112
	strip.add_theme_constant_override("separation", 12)
	parent.add_child(strip)
	_npc_card(strip, "SERA", "KEEPER OF THE LAST HEARTH", "\"Orren found you, then. Keep his marks close. The lower stairs move when no one is looking.\"")
	_npc_card(strip, "VARN", "LAST OF THE ASHVALE WATCH", "\"Orren is reckless, but his routes are good. If he says a door is safe, it is safe enough.\"")
	_npc_card(strip, "ARCHIVE MAGE VOLANT", "BELLKEEPER RESEARCHER", "\"You met Orren? Good. His maps are infuriatingly imprecise and usually correct.\"")


func _npc_card(parent: HBoxContainer, npc_name: String, title: String, quote: String) -> void:
	var card := _panel(Color(0.030, 0.028, 0.036, 0.96), C_GOLD_DIM, 1, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var portrait := _panel(Color(0.018, 0.018, 0.023, 0.96), C_GOLD_DIM, 1, 0)
	portrait.custom_minimum_size = Vector2(84, 96)
	row.add_child(portrait)
	var mark := _label(npc_name.left(1), 38, C_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
	portrait.add_child(mark)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(copy)
	copy.add_child(_label(npc_name, 17, C_GOLD_BRIGHT, true))
	copy.add_child(_label(title, 11, C_MUTED, true))
	var q := _wrapped(quote, 14, C_TEXT)
	q.custom_minimum_size.y = 44
	copy.add_child(q)


func _build_footer(parent: VBoxContainer) -> void:
	var line := HBoxContainer.new()
	line.custom_minimum_size.y = 76
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_theme_constant_override("separation", 12)
	parent.add_child(line)

	_footer_button(line, "BEGIN DESCENT", _on_begin_descent, C_GOLD_DIM, 1.22, true)
	_footer_button(line, "MANAGE JOBS", _on_manage_jobs, Color(0.20, 0.28, 0.36), 1.0)
	_footer_button(line, "THE INN", _on_inn, Color(0.38, 0.22, 0.07), 1.0)
	_footer_button(line, "INVENTORY", _on_inventory, Color(0.05, 0.28, 0.30), 1.0)
	_footer_button(line, "CODEX", _on_codex, Color(0.26, 0.12, 0.38), 1.0)
	_footer_button(line, "RUN MAP", _on_debug_map, Color(0.16, 0.16, 0.16), 0.85)

	_message_label = _label("", 13, C_GOLD_BRIGHT)
	_message_label.custom_minimum_size.y = 18
	parent.add_child(_message_label)


func _footer_button(parent: HBoxContainer, text: String, callback: Callable, tint: Color, width_scale: float, selected: bool = false) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(150.0 * width_scale, 62)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_override("font", CINZEL_FONT)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", C_TEXT)
	btn.add_theme_color_override("font_hover_color", C_GOLD_BRIGHT)
	SacredSelection.apply_button(btn, tint, selected)
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _section(parent: Control, title: String, subtitle: String, fill: Color, edge: Color) -> VBoxContainer:
	var panel := _panel(fill, edge, 2, 0)
	panel.custom_minimum_size = Vector2(0, 220)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	box.add_child(_label(title, 25, C_GOLD_BRIGHT, true))
	box.add_child(_label(subtitle, 13, C_MUTED))
	box.add_child(HSeparator.new())
	return box


func _rows_container(parent: VBoxContainer) -> VBoxContainer:
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 7)
	parent.add_child(rows)
	return rows


func _action_row(parent: VBoxContainer, icon: String, label_text: String, state_text: String,
		cost_text: String, can_afford: bool, selected: bool = false) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size.y = 36
	btn.focus_mode = Control.FOCUS_ALL
	btn.text = ""
	btn.disabled = false
	btn.add_theme_stylebox_override("normal", _row_style(can_afford, false, false, selected))
	btn.add_theme_stylebox_override("hover", _row_style(true, true))
	btn.add_theme_stylebox_override("focus", _row_style(true, false, false, true))
	btn.add_theme_stylebox_override("pressed", _row_style(true, true, true))
	parent.add_child(btn)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_right = -10
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	btn.add_child(row)

	var left_marker := _label("*", 16, C_GOLD_BRIGHT if selected else Color(0, 0, 0, 0), true, HORIZONTAL_ALIGNMENT_CENTER)
	left_marker.custom_minimum_size.x = 18
	row.add_child(left_marker)
	var ico := _label(icon, 15, C_GOLD_BRIGHT if selected else (C_GOLD if can_afford else C_DISABLED), true, HORIZONTAL_ALIGNMENT_CENTER)
	ico.custom_minimum_size.x = 34
	row.add_child(ico)
	var name_label := _label(label_text, 15, C_GOLD_BRIGHT if selected else (C_TEXT if can_afford else C_DISABLED))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(_label(state_text, 13, C_MUTED))
	row.add_child(_label(cost_text, 13, C_GOLD if can_afford else C_DISABLED, false, HORIZONTAL_ALIGNMENT_RIGHT))
	var right_marker := _label("*", 16, C_GOLD_BRIGHT if selected else Color(0, 0, 0, 0), true, HORIZONTAL_ALIGNMENT_CENTER)
	right_marker.custom_minimum_size.x = 18
	row.add_child(right_marker)
	return btn


func _panel(fill: Color, edge: Color, border_width: int, radius: int) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = fill
	st.border_color = edge
	st.set_border_width_all(border_width)
	st.set_corner_radius_all(radius)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", st)
	return p


func _row_style(can_afford: bool, hover: bool = false, pressed: bool = false, selected: bool = false) -> StyleBoxFlat:
	if not can_afford:
		return SacredSelection.row("disabled", Color(0.040, 0.036, 0.044, 0.92))
	if selected:
		return SacredSelection.row("selected", Color(0.040, 0.036, 0.044, 0.92))
	if pressed:
		return SacredSelection.row("confirmed", Color(0.030, 0.026, 0.034, 0.96))
	if hover:
		return SacredSelection.row("hover", Color(0.040, 0.036, 0.044, 0.92))
	return SacredSelection.row("default", Color(0.040, 0.036, 0.044, 0.92))


func _label(text: String, font_px: int, color: Color, display_font: bool = false,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_px)
	l.add_theme_color_override("font_color", color)
	if display_font:
		l.add_theme_font_override("font", DISPLAY_FONT)
	else:
		l.add_theme_font_override("font", CINZEL_FONT)
	return l


func _wrapped(text: String, font_px: int, color: Color) -> Label:
	var l := _label(text, font_px, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _currency_icon(currency_id: String) -> String:
	match currency_id:
		"soul-shards": return "SS"
		"obsidian": return "OB"
		"glyphs": return "GL"
		"boss-tokens": return "BT"
		"phoenix-sigils": return "PX"
		"titan-sigils": return "TN"
		_: return "CR"


func _roman(value: int) -> String:
	match value:
		1: return "I"
		2: return "II"
		3: return "III"
		_: return str(value)


func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key in cost.keys():
		parts.append("%d %s" % [int(cost[key]), _currency_icon(str(key))])
	return "  ".join(parts)


func _get_currency(currency_id: String) -> int:
	if _meta and _meta.has_method("get_currency"):
		return int(_meta.get_currency(currency_id))
	return 0


func _get_upgrade(upgrade_id: String) -> int:
	if _meta and _meta.has_method("get_upgrade"):
		return int(_meta.get_upgrade(upgrade_id))
	return 0


func _stat_bonus(stat_id: String) -> int:
	if _meta and _meta.has_method("get_stat_bonus"):
		return int(_meta.get_stat_bonus(stat_id))
	return 0


func _can_spend(cost: Dictionary) -> bool:
	return _meta != null and _meta.has_method("can_spend") and _meta.can_spend(cost)


func _spend(cost: Dictionary) -> bool:
	return _meta != null and _meta.has_method("spend") and _meta.spend(cost)


func _show_msg(text: String) -> void:
	if _message_label:
		_message_label.text = text


func _change_scene(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		_show_msg("Scene is not ready yet.")


func _on_begin_descent() -> void:
	_change_scene(STAGE_SELECT_SCENE)


func _on_manage_jobs() -> void:
	_change_scene(CHARACTER_SCENE)


func _on_inn() -> void:
	var screen := INN_SCENE.instantiate() as InnScreen
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.back_pressed.connect(screen.queue_free)
	add_child(screen)


func _on_inventory() -> void:
	var screen := INVENTORY_SCENE.instantiate() as InventoryScreen
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.back_pressed.connect(screen.queue_free)
	add_child(screen)


func _on_codex() -> void:
	var screen := CODEX_SCENE.instantiate() as CodexScreen
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.back_pressed.connect(screen.queue_free)
	add_child(screen)


func _on_debug_map() -> void:
	_change_scene(STAGE_SELECT_SCENE)
