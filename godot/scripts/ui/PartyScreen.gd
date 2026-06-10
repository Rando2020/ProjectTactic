## PartyScreen.gd
## Overlay opened from StageSelect before a new run starts.
## Shows all 7 characters; player selects exactly PARTY_SIZE (4) to take into the run.
## Emits party_confirmed(ids) on accept; emits cancelled on back/Escape.

class_name PartyScreen
extends Control

signal party_confirmed(selected_ids: Array)
signal cancelled

const FONT_TITLE := preload("res://assets/fonts/TrajanPro-Bold.otf")
const FONT_BODY  := preload("res://assets/fonts/Cinzel-Regular.ttf")
const FONT_DATA  := preload("res://assets/fonts/CormorantGaramond-Regular.ttf")

## Exactly how many units must be chosen before the run can begin.
const PARTY_SIZE := 4

# Colour palette
const GOLD      := Color(0.88, 0.70, 0.32)
const PANEL     := Color(0.025, 0.022, 0.023, 0.96)
const PANEL_EDGE:= Color(0.42, 0.28, 0.11)
const TEXT      := Color(0.94, 0.88, 0.75)
const DIM       := Color(0.58, 0.50, 0.38)
const SEL_BG    := Color(0.022, 0.060, 0.048, 0.96)  # teal-dark fill when selected
const SEL_EDGE  := Color(0.35, 0.96, 0.68)            # bright teal border when selected
const UNSEL_BG  := Color(0.018, 0.016, 0.014, 0.94)
const UNSEL_EDGE:= Color(0.30, 0.26, 0.20, 0.60)
const HP_FULL   := Color(0.22, 0.78, 0.45)
const HP_MID    := Color(0.84, 0.62, 0.18)
const HP_LOW    := Color(0.82, 0.20, 0.20)

## Currently selected unit IDs (in order of selection).
var _selected: Array[String] = []
## uid → Button (card widget)
var _card_btns: Dictionary = {}
## uid → Label (shows "IN" / "—" status)
var _state_lbls: Dictionary = {}
## Confirm button — enabled only when _selected.size() == PARTY_SIZE
var _confirm_btn: Button
## Live counter label e.g. "3 / 4 selected"
var _count_lbl: Label


func _ready() -> void:
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		cancelled.emit()


func _build_ui() -> void:
	var gs: Node = get_node_or_null("/root/GameState")

	# ── Full-screen dim backdrop ──────────────────────────────────────────────
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# ── Centred outer panel ───────────────────────────────────────────────────
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var outer := PanelContainer.new()
	outer.custom_minimum_size = Vector2(1460, 0)
	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = PANEL
	outer_style.border_color = PANEL_EDGE
	outer_style.set_border_width_all(2)
	outer_style.set_corner_radius_all(10)
	outer_style.content_margin_left   = 40
	outer_style.content_margin_right  = 40
	outer_style.content_margin_top    = 34
	outer_style.content_margin_bottom = 34
	outer.add_theme_stylebox_override("panel", outer_style)
	center.add_child(outer)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	outer.add_child(vbox)

	# ── Title ─────────────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "CHOOSE YOUR PARTY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", GOLD)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Select %d of %d characters for this run.  Click a card to toggle." % [
		PARTY_SIZE, Characters.PARTY_ORDER.size()]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", FONT_BODY)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", DIM)
	vbox.add_child(subtitle)

	_add_separator(vbox)

	# ── Unit cards ────────────────────────────────────────────────────────────
	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 14)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(cards_row)

	for uid: String in Characters.PARTY_ORDER:
		_add_unit_card(cards_row, uid, gs)

	_add_separator(vbox)

	# ── Footer ────────────────────────────────────────────────────────────────
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 24)
	vbox.add_child(footer)

	# Count label
	_count_lbl = Label.new()
	_count_lbl.text = "0 / %d selected" % PARTY_SIZE
	_count_lbl.add_theme_font_override("font", FONT_BODY)
	_count_lbl.add_theme_font_size_override("font_size", 18)
	_count_lbl.add_theme_color_override("font_color", DIM)
	_count_lbl.custom_minimum_size = Vector2(200, 0)
	_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(_count_lbl)

	# Back button
	var back_btn := _make_btn("← Back", PANEL_EDGE, false)
	back_btn.add_theme_color_override("font_color", DIM)
	back_btn.add_theme_color_override("font_hover_color", TEXT)
	back_btn.pressed.connect(func() -> void: cancelled.emit())
	footer.add_child(back_btn)

	# Confirm button
	_confirm_btn = _make_btn("Begin Descent  →", GOLD, false)
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(func() -> void:
		party_confirmed.emit(_selected.duplicate()))
	footer.add_child(_confirm_btn)

	# Focus the first card
	call_deferred("_focus_first_card")


## Builds one unit card.  The entire PanelContainer is wrapped in a Button so
## the whole surface is clickable, with inner children set to MOUSE_FILTER_IGNORE.
func _add_unit_card(parent: Control, uid: String, gs: Node) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(182, 220)
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal",  _card_style(false, false))
	btn.add_theme_stylebox_override("hover",   _card_style(false, true))
	btn.add_theme_stylebox_override("focus",   _card_style(false, true))
	btn.add_theme_stylebox_override("pressed", _card_style(false, true))
	_card_btns[uid] = btn

	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left   = 14
	inner.offset_right  = -14
	inner.offset_top    = 14
	inner.offset_bottom = -14
	inner.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 6)
	btn.add_child(inner)

	# ── Status badge (top-right corner) ──
	var badge_row := HBoxContainer.new()
	badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(badge_row)

	var initial_lbl := Label.new()
	initial_lbl.text = uid.left(1).to_upper()
	initial_lbl.add_theme_font_override("font", FONT_TITLE)
	initial_lbl.add_theme_font_size_override("font_size", 36)
	initial_lbl.add_theme_color_override("font_color", GOLD)
	initial_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	initial_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.add_child(initial_lbl)

	var state_lbl := Label.new()
	state_lbl.text = "—"
	state_lbl.add_theme_font_override("font", FONT_BODY)
	state_lbl.add_theme_font_size_override("font_size", 13)
	state_lbl.add_theme_color_override("font_color", DIM)
	state_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	state_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.add_child(state_lbl)
	_state_lbls[uid] = state_lbl

	# ── Name ──
	var char_data: Dictionary = Characters.get_character(uid)
	var display_name: String = str(char_data.get("human_name", uid.capitalize()))

	var name_lbl := Label.new()
	name_lbl.text = display_name
	name_lbl.add_theme_font_override("font", FONT_BODY)
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", TEXT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(name_lbl)

	# ── Job ──
	var job_id: String = ""
	var jp_val: int    = 0
	if gs and gs.get("unit_registry") != null:
		var reg: Dictionary = gs.unit_registry.get(uid, {})
		job_id = str(reg.get("current_job_id", ""))
		jp_val = int(reg.get("jp", 0))

	var job_name: String = job_id.capitalize()
	if not job_id.is_empty():
		var job_dict: Dictionary = JobTreeData.get_job(job_id)
		if not job_dict.is_empty():
			job_name = str(job_dict.get("name", job_name))

	var job_lbl := Label.new()
	job_lbl.text = job_name if not job_name.is_empty() else "—"
	job_lbl.add_theme_font_override("font", FONT_DATA)
	job_lbl.add_theme_font_size_override("font_size", 15)
	job_lbl.add_theme_color_override("font_color", GOLD)
	job_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(job_lbl)

	# ── JP ──
	var jp_lbl := Label.new()
	jp_lbl.text = "JP  %d" % jp_val
	jp_lbl.add_theme_font_override("font", FONT_DATA)
	jp_lbl.add_theme_font_size_override("font_size", 15)
	jp_lbl.add_theme_color_override("font_color", DIM)
	jp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(jp_lbl)

	# ── HP bar + label ──
	var hp_row := _hp_row(uid, gs)
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(hp_row)

	# Wire the toggle
	btn.pressed.connect(func() -> void: _toggle_unit(uid))
	parent.add_child(btn)


## Returns a VBoxContainer showing a thin HP bar and a "HP X / Y" label.
func _hp_row(uid: String, gs: Node) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)

	var current_hp := 0
	var base_hp    := 0
	if gs and gs.get("unit_registry") != null:
		var reg: Dictionary = gs.unit_registry.get(uid, {})
		base_hp    = int(reg.get("base_hp",    0))
		current_hp = int(reg.get("current_hp", base_hp))

	# Visual bar (only if hp data is available)
	if base_hp > 0:
		var bar_bg := PanelContainer.new()
		bar_bg.custom_minimum_size = Vector2(0, 7)
		bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = Color(0.15, 0.10, 0.10)
		bg_style.set_corner_radius_all(3)
		bar_bg.add_theme_stylebox_override("panel", bg_style)
		box.add_child(bar_bg)

		var ratio: float = clampf(float(current_hp) / float(base_hp), 0.0, 1.0)
		var bar_fill := ColorRect.new()
		var fill_color: Color = HP_FULL if ratio > 0.50 else (HP_MID if ratio > 0.25 else HP_LOW)
		bar_fill.color = fill_color
		# Anchor fill to match ratio
		bar_fill.anchor_left   = 0.0
		bar_fill.anchor_top    = 0.0
		bar_fill.anchor_right  = ratio
		bar_fill.anchor_bottom = 1.0
		bar_bg.add_child(bar_fill)

	var hp_lbl := Label.new()
	if base_hp > 0:
		hp_lbl.text = "HP  %d / %d" % [current_hp, base_hp]
	else:
		hp_lbl.text = "HP  —"
	hp_lbl.add_theme_font_override("font", FONT_DATA)
	hp_lbl.add_theme_font_size_override("font_size", 13)
	hp_lbl.add_theme_color_override("font_color", DIM)
	box.add_child(hp_lbl)

	return box


## Toggle a unit in/out of the selected party.  At most PARTY_SIZE can be selected.
func _toggle_unit(uid: String) -> void:
	if _selected.has(uid):
		_selected.erase(uid)
	elif _selected.size() < PARTY_SIZE:
		_selected.append(uid)
	# If already at PARTY_SIZE and not currently selected, do nothing (full party).
	_refresh_cards()


## Update every card's appearance and the footer labels to match current selection.
func _refresh_cards() -> void:
	for uid: String in _card_btns:
		var btn: Button = _card_btns[uid]
		var sel: bool = uid in _selected
		btn.add_theme_stylebox_override("normal",  _card_style(sel, false))
		btn.add_theme_stylebox_override("hover",   _card_style(sel, true))
		btn.add_theme_stylebox_override("focus",   _card_style(sel, true))
		btn.add_theme_stylebox_override("pressed", _card_style(sel, true))

		var state_lbl: Label = _state_lbls[uid]
		if sel:
			state_lbl.text = "IN"
			state_lbl.add_theme_color_override("font_color", SEL_EDGE)
		else:
			var full: bool = _selected.size() >= PARTY_SIZE
			state_lbl.text = "—"
			state_lbl.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08, 0.70) if full else DIM)

	var n := _selected.size()
	_count_lbl.text = "%d / %d selected" % [n, PARTY_SIZE]
	_count_lbl.add_theme_color_override("font_color", GOLD if n == PARTY_SIZE else DIM)
	_confirm_btn.disabled = n != PARTY_SIZE


func _focus_first_card() -> void:
	if not _card_btns.is_empty():
		var first_btn: Button = _card_btns.values()[0]
		if is_instance_valid(first_btn):
			first_btn.grab_focus()


# ── Style helpers ─────────────────────────────────────────────────────────────

func _card_style(selected: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color     = SEL_BG.lerp(Color(0.04, 0.10, 0.08, 0.98), 0.3) if hover else SEL_BG
		style.border_color = SEL_EDGE
		style.set_border_width_all(2)
	else:
		style.bg_color     = UNSEL_BG.lightened(0.04) if hover else UNSEL_BG
		style.border_color = GOLD if hover else UNSEL_EDGE
		style.set_border_width_all(2 if hover else 1)
	style.set_corner_radius_all(7)
	style.content_margin_left   = 0
	style.content_margin_right  = 0
	style.content_margin_top    = 0
	style.content_margin_bottom = 0
	return style


func _make_btn(label_text: String, edge_color: Color, _selected_state: bool) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(200, 48)
	btn.add_theme_font_override("font", FONT_BODY)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", TEXT)
	btn.add_theme_color_override("font_hover_color", GOLD)
	btn.add_theme_color_override("font_focus_color", GOLD)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.055, 0.042, 0.022, 0.92)
	normal_style.border_color = edge_color
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(4)
	normal_style.content_margin_left = 14; normal_style.content_margin_right = 14
	normal_style.content_margin_top  = 8;  normal_style.content_margin_bottom = 8
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.090, 0.068, 0.030, 0.96)
	hover_style.border_color = GOLD
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(4)
	hover_style.content_margin_left = 14; hover_style.content_margin_right = 14
	hover_style.content_margin_top  = 8;  hover_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal",  normal_style)
	btn.add_theme_stylebox_override("hover",   hover_style)
	btn.add_theme_stylebox_override("focus",   hover_style)
	btn.add_theme_stylebox_override("disabled", _disabled_style())
	return btn


func _disabled_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.030, 0.027, 0.023, 0.70)
	style.border_color = Color(0.28, 0.23, 0.18, 0.40)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top  = 8;  style.content_margin_bottom = 8
	return style


func _add_separator(parent: Control) -> void:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(PANEL_EDGE.r, PANEL_EDGE.g, PANEL_EDGE.b, 0.55))
	parent.add_child(sep)
