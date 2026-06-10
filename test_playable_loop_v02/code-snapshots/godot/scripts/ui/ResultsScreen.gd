class_name ResultsScreen
extends Control

const DISPLAY_FONT := preload("res://assets/fonts/TrajanPro-Regular.ttf")
const CINZEL_FONT := preload("res://assets/fonts/Cinzel-Regular.ttf")
const SacredSelection := preload("res://scripts/ui/SacredSelectionStyle.gd")

const C_BG := Color(0.010, 0.011, 0.016)
const C_PANEL := Color(0.030, 0.028, 0.036, 0.96)
const C_PANEL_BLUE := Color(0.022, 0.032, 0.044, 0.96)
const C_GOLD := Color(0.82, 0.58, 0.28)
const C_GOLD_BRIGHT := Color(1.0, 0.80, 0.42)
const C_GOLD_DIM := Color(0.38, 0.25, 0.10)
const C_TEXT := Color(0.90, 0.82, 0.64)
const C_MUTED := Color(0.58, 0.50, 0.39)
const C_RED := Color(0.94, 0.27, 0.24)
const C_GREEN := Color(0.55, 0.86, 0.44)
const C_PURPLE := Color(0.84, 0.48, 0.95)
const C_BLUE := Color(0.38, 0.75, 1.0)

const STAGE_SELECT_SCENE := "res://scenes/StageSelect.tscn"
const ANTECHAMBER_SCENE := "res://scenes/AntechamberScene.tscn"
const CHARACTER_SCENE := "res://scenes/CharacterScreen.tscn"
const HUB_SCENE := "res://scenes/HubScene.tscn"

var _gs: Node
var _rewards: Dictionary = {}
var _death: Dictionary = {}
var _is_defeat := false
var _is_complete := false
var _floor := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gs = get_node_or_null("/root/GameState")
	_rewards = _gs.pending_rewards if _gs else {}
	_death = _gs.last_run_death if _gs else {}
	_is_defeat = not _death.is_empty()
	_floor = _gs.run_floor_reached if _gs else 0
	_is_complete = _floor >= RunState.TOTAL_FLOORS and not _is_defeat
	_build_ui()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_add_atmosphere()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var frame := _panel(Color(0.014, 0.015, 0.021, 0.96), C_GOLD_DIM, 2)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(frame)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 20)
	pad.add_theme_constant_override("margin_right", 20)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	frame.add_child(pad)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	pad.add_child(root)

	_build_header(root)
	_build_main_body(root)
	_build_footer(root)


func _add_atmosphere() -> void:
	for i in range(36):
		var line := ColorRect.new()
		line.color = Color(0.26, 0.18, 0.08, 0.030)
		line.size = Vector2(900.0 + float((i * 47) % 600), 1.0)
		line.position = Vector2(float((i * 97) % 700), 28.0 + float(i * 28))
		line.rotation = 0.01 * sin(float(i) * 1.7)
		add_child(line)


func _build_header(parent: VBoxContainer) -> void:
	var title := _label("BATTLE RESULTS", 56, C_GOLD_BRIGHT, true, HORIZONTAL_ALIGNMENT_CENTER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(title)

	var summary := HBoxContainer.new()
	summary.custom_minimum_size.y = 100
	summary.alignment = BoxContainer.ALIGNMENT_CENTER
	summary.add_theme_constant_override("separation", 16)
	parent.add_child(summary)

	var verdict := "VICTORY"
	var verdict_color := C_GOLD_BRIGHT
	if _is_defeat:
		verdict = "FALLEN"
		verdict_color = C_RED
	elif _is_complete:
		verdict = "ANCHOR SHATTERED"

	_summary_card(summary, verdict, _objective_text(), verdict_color, 1.28)
	_summary_card(summary, "BONUS", _bonus_text(), C_TEXT)
	_summary_card(summary, "FLOOR", "%d / %d" % [maxi(_floor, 1), RunState.TOTAL_FLOORS], C_TEXT)
	_summary_card(summary, "CLARITY GAINED", "+%d" % _clarity_gained(), C_PURPLE)
	_summary_card(summary, "LOOP DAY", "The War", C_TEXT)

	var rank := _label("MEASURED TRIUMPH" if not _is_defeat else "THE DESCENT ENDS", 25, C_GOLD_BRIGHT, true, HORIZONTAL_ALIGNMENT_CENTER)
	rank.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(rank)


func _summary_card(parent: HBoxContainer, title: String, value: String, color: Color, width_scale: float = 1.0) -> void:
	var card := _panel(C_PANEL, C_GOLD_DIM, 1)
	card.custom_minimum_size = Vector2(205.0 * width_scale, 76)
	parent.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)
	box.add_child(_label(title, 14, C_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label(value, 20, color, false, HORIZONTAL_ALIGNMENT_CENTER))


func _build_main_body(parent: VBoxContainer) -> void:
	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	parent.add_child(columns)

	var left := _panel(C_PANEL_BLUE, C_GOLD_DIM, 2)
	left.custom_minimum_size = Vector2(1020, 420)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	_build_party_results(left)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(680, 420)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)
	_build_spoils(right)
	_build_calling_progress(right)
	_build_revelation(right)


func _build_party_results(parent: PanelContainer) -> void:
	var margin := _inner(parent)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	root.add_child(_label("PARTY RESULTS", 17, C_GOLD, true))

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 28
	root.add_child(header)
	_header_cell(header, "VESSEL", 280)
	_header_cell(header, "EXP GAINED", 150)
	_header_cell(header, "JP GAINED", 140)
	_header_cell(header, "RESULT", 420)

	var rows := VBoxContainer.new()
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 4)
	root.add_child(rows)

	for unit in _party_rows():
		_party_row(rows, unit)


func _party_row(parent: VBoxContainer, unit: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 74
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var portrait := _panel(Color(0.018, 0.018, 0.026, 0.96), C_GOLD_DIM, 1)
	portrait.custom_minimum_size = Vector2(62, 62)
	row.add_child(portrait)
	portrait.add_child(_label(str(unit["name"]).left(1), 28, C_GOLD_BRIGHT, true, HORIZONTAL_ALIGNMENT_CENTER))

	var name_box := VBoxContainer.new()
	name_box.custom_minimum_size.x = 208
	name_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(name_box)
	name_box.add_child(_label(str(unit["name"]), 23, C_TEXT, true))
	name_box.add_child(_label("Lv. %d" % int(unit["level"]), 14, C_MUTED))

	row.add_child(_value_cell("+%d" % int(unit["exp"]), C_PURPLE, 150))
	row.add_child(_value_cell("+%d" % int(unit["jp"]), C_PURPLE, 140))

	var result := VBoxContainer.new()
	result.custom_minimum_size.x = 420
	result.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(result)
	for line in unit["notes"]:
		result.add_child(_label(str(line), 15, _result_color(str(line))))


func _build_spoils(parent: VBoxContainer) -> void:
	var panel := _section(parent, "BATTLE SPOILS", 154)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var gold := int(_rewards.get("gold", 0))
	var jp := int(_rewards.get("jp", 0))
	var items: Array = _gs.run_inventory if _gs else []
	_spoil(row, "JP", str(jp), C_PURPLE)
	_spoil(row, "Gold", str(gold), C_GOLD_BRIGHT)
	var item_count := mini(items.size(), 2)
	if item_count == 0:
		_spoil(row, "Reliquary", "None", C_MUTED)
	else:
		for i in range(item_count):
			var item: Dictionary = items[items.size() - 1 - i]
			_spoil(row, item.get("name", "Unknown Relic"), "x1", item.get("color", C_TEXT))


func _build_calling_progress(parent: VBoxContainer) -> void:
	var panel := _section(parent, "CALLING PROGRESS", 128)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)

	var icon := _panel(Color(0.020, 0.020, 0.030, 0.96), C_GOLD_DIM, 1)
	icon.custom_minimum_size = Vector2(76, 76)
	row.add_child(icon)
	icon.add_child(_label("K", 31, C_GOLD_BRIGHT, true, HORIZONTAL_ALIGNMENT_CENTER))

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(copy)
	copy.add_child(_label("Knight  Lv. 3", 24, C_TEXT, true))
	copy.add_child(_label("Calling Progress Increased", 15, C_GOLD))
	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(0, 18)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.max_value = 600
	progress.value = 320 + int(_rewards.get("jp", 0))
	copy.add_child(progress)
	copy.add_child(_label("%d / 600  Next ability unlock approaching" % int(progress.value), 13, C_MUTED))


func _build_revelation(parent: VBoxContainer) -> void:
	var panel := _section(parent, "REVELATION", 112)
	var text := "One of the fallen paused before the end.\nThe party did not understand why."
	if _is_defeat:
		text = "\n".join(_get_suggestions(_death, _gs))
	panel.add_child(_wrapped(text, 15, C_TEXT))


func _build_footer(parent: VBoxContainer) -> void:
	var actions := HBoxContainer.new()
	actions.custom_minimum_size.y = 170
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 12)
	parent.add_child(actions)

	if _is_defeat:
		_action_card(actions, "RETURN TO ANTECHAMBER", "Regroup and prepare for what comes.", _return_to_antechamber, true)
	else:
		_action_card(actions, "CONTINUE DESCENT", "Proceed deeper into the Mountain.", _continue_descent, true)
	_action_card(actions, "REVIEW PARTY", "Review equipment, callings, and party status.", _review_party)
	_action_card(actions, "RETURN TO ANTECHAMBER", "Return to the Antechamber and prepare.", _return_to_antechamber)
	_build_reward_choices(actions)


func _action_card(parent: HBoxContainer, title: String, desc: String, callback: Callable, selected: bool = false) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(330, 148)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = ""
	btn.add_theme_stylebox_override("normal", SacredSelection.button_box("selected" if selected else "default", C_PANEL))
	btn.add_theme_stylebox_override("hover", SacredSelection.button_box("hover", C_PANEL))
	btn.add_theme_stylebox_override("focus", SacredSelection.button_box("selected", C_PANEL))
	btn.add_theme_stylebox_override("pressed", SacredSelection.button_box("confirmed", C_PANEL))
	btn.pressed.connect(callback)
	parent.add_child(btn)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_top = 16
	box.offset_right = -18
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(box)
	box.add_child(_label(title, 18, C_GOLD_BRIGHT if selected else C_GOLD, true))
	box.add_child(_wrapped(desc, 15, C_TEXT))
	var marker := _label("*", 24, C_GOLD_BRIGHT if selected else C_GOLD_DIM, true, HORIZONTAL_ALIGNMENT_RIGHT)
	marker.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(marker)


func _build_reward_choices(parent: HBoxContainer) -> void:
	var panel := _panel(C_PANEL, C_GOLD_DIM, 2)
	panel.custom_minimum_size = Vector2(420, 148)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(_label("CHOOSE REWARD", 17, C_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	_reward_chip(row, "Temper Sigil", C_GOLD)
	_reward_chip(row, "Ether Thread", C_PURPLE, true)
	_reward_chip(row, "Brass Oath", C_GOLD)


func _reward_chip(parent: HBoxContainer, label_text: String, color: Color, selected: bool = false) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(118, 88)
	btn.text = ""
	btn.add_theme_stylebox_override("normal", SacredSelection.button_box("selected" if selected else "default", Color(0.022, 0.020, 0.028, 0.96)))
	btn.add_theme_stylebox_override("hover", SacredSelection.button_box("hover", Color(0.022, 0.020, 0.028, 0.96)))
	btn.pressed.connect(func() -> void: pass)
	parent.add_child(btn)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(box)
	box.add_child(_label("*", 24, color, true, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label(label_text, 13, C_TEXT, false, HORIZONTAL_ALIGNMENT_CENTER))


func _objective_text() -> String:
	if _is_defeat:
		return "Party defeated."
	if _is_complete:
		return "Destroy the Anchor."
	return str(_rewards.get("objective", "Defeat all enemies."))


func _bonus_text() -> String:
	if _is_defeat:
		return "Lessons learned."
	return "No ally fell." if _death.is_empty() else "Hard-fought."


func _clarity_gained() -> int:
	return 0 if _is_defeat else 1


func _party_rows() -> Array[Dictionary]:
	var ids: Array[String] = ["zane", "mira", "kael", "lyra"]
	var rows: Array[Dictionary] = []
	var jp := int(_rewards.get("jp", 0))
	for idx in range(ids.size()):
		var uid := ids[idx]
		var reg: Dictionary = _gs.unit_registry.get(uid, {}) if _gs and _gs.unit_registry else {}
		var name := str(reg.get("display_name", uid.capitalize()))
		var level := int(reg.get("level", 1 + idx))
		var notes: Array[String] = []
		if _is_defeat:
			notes.append("Wounded in descent")
			if uid == str(_death.get("victim_id", "")):
				notes.append("Fell to %s" % str(_death.get("killer_name", "an enemy")))
		else:
			if idx == 0:
				notes.append("Temper Restored +8")
			elif idx == 1:
				notes.append("Bond +1 with Kael")
			elif idx == 2:
				notes.append("Ether Restored +10")
			else:
				notes.append("Costume Integrity -1%")
		rows.append({
			"name": name,
			"level": level,
			"exp": 420 + idx * 35 + maxi(_floor, 1) * 10,
			"jp": jp,
			"notes": notes,
		})
	return rows


func _result_color(text: String) -> Color:
	if text.contains("Costume") or text.contains("Fell") or text.contains("Wounded"):
		return C_RED
	if text.contains("Temper") or text.contains("Bond"):
		return C_GREEN
	if text.contains("Ether"):
		return C_PURPLE
	return C_TEXT


func _get_suggestions(death: Dictionary, gs: Node) -> Array[String]:
	var suggestions: Array[String] = []
	var killer_type: String = death.get("killer_type", "")
	var was_anchor: bool = death.get("was_anchor", false)
	var was_elite: bool = death.get("was_elite", false)
	var elite_tier: String = death.get("elite_tier", "")

	var boon_ids: Array = []
	if gs and gs.active_run:
		boon_ids = gs.active_run.active_boons.map(func(b: Dictionary) -> String: return b.get("id", ""))

	if was_anchor:
		suggestions.append("Luminarch's Covenant halves the Anchor's pulse damage.")
		suggestions.append("Keep the party three tiles away when the Anchor drops below half HP.")
	elif was_elite:
		if elite_tier == "champion":
			suggestions.append("Void Sight reveals champion affixes before battle.")
		suggestions.append("Champion's Grit turns elite kills into healing.")
	elif killer_type == "storm_imp":
		suggestions.append("Storm Imps resist thunder. Use fire or blizzard.")
	elif killer_type == "void_cultist":
		suggestions.append("Void Cultists collapse when their Ether is stripped.")

	if not "swift_recovery" in boon_ids:
		suggestions.append("Swift Recovery can stabilize the party between floors.")
	if suggestions.is_empty():
		suggestions.append("Review positioning and terrain hazards before the next descent.")
	return suggestions.slice(0, 3)


func _continue_descent() -> void:
	get_tree().change_scene_to_file(STAGE_SELECT_SCENE)


func _review_party() -> void:
	get_tree().change_scene_to_file(CHARACTER_SCENE)


func _return_to_antechamber() -> void:
	_clear_run_if_finished()
	get_tree().change_scene_to_file(ANTECHAMBER_SCENE if ResourceLoader.exists(ANTECHAMBER_SCENE) else HUB_SCENE)


func _clear_run_if_finished() -> void:
	if not _gs:
		return
	if _is_defeat or _is_complete:
		_gs.run_floor_reached = 0
		_gs.run_jp_earned = 0
		_gs.run_inventory.clear()
		_gs.last_run_death.clear()
		_gs.best_floor_reached = max(_gs.best_floor_reached, _floor)
		if _is_complete:
			_gs.runs_completed += 1
		if _is_defeat:
			_gs.active_run = null


func _section(parent: VBoxContainer, title: String, height: int) -> VBoxContainer:
	var panel := _panel(C_PANEL, C_GOLD_DIM, 2)
	panel.custom_minimum_size.y = height
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var margin := _inner(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	box.add_child(_label(title, 16, C_GOLD, true))
	return box


func _spoil(parent: HBoxContainer, title: String, value: String, color: Color) -> void:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 145
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(box)
	box.add_child(_label("*", 34, color, true, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label(title, 15, C_TEXT, false, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label(value, 14, color, false, HORIZONTAL_ALIGNMENT_CENTER))


func _header_cell(parent: HBoxContainer, text: String, width: int) -> void:
	var l := _label(text, 13, C_GOLD, true)
	l.custom_minimum_size.x = width
	parent.add_child(l)


func _value_cell(text: String, color: Color, width: int) -> Label:
	var l := _label(text, 22, color, false, HORIZONTAL_ALIGNMENT_CENTER)
	l.custom_minimum_size.x = width
	return l


func _panel(fill: Color, edge: Color, border: int) -> PanelContainer:
	var pc := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = fill
	st.border_color = edge
	st.set_border_width_all(border)
	st.set_corner_radius_all(0)
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	pc.add_theme_stylebox_override("panel", st)
	return pc


func _inner(panel: PanelContainer) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	return margin


func _label(text: String, size: int, color: Color, display_font: bool = false,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", DISPLAY_FONT if display_font else CINZEL_FONT)
	return l


func _wrapped(text: String, size: int, color: Color) -> Label:
	var l := _label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
