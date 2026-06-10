## SaveSlotScreen.gd
## Overlay opened from StartScreen's Load Game button.
## Shows 3 save slots.  Filled slots display run metadata and a Load button.
## Empty slots offer a New Slot button that navigates to AntechamberScene.
## Emits back_pressed when closed; caller connects that to queue_free.

class_name SaveSlotScreen
extends Control

signal back_pressed

const FONT_TITLE := preload("res://assets/fonts/TrajanPro-Bold.otf")
const FONT_BODY  := preload("res://assets/fonts/Cinzel-Regular.ttf")
const FONT_DATA  := preload("res://assets/fonts/CormorantGaramond-Regular.ttf")

const ANTECHAMBER  := "res://scenes/AntechamberScene.tscn"
const STAGE_SELECT := "res://scenes/StageSelect.tscn"

const GOLD        := Color(0.88, 0.70, 0.32)
const PANEL       := Color(0.025, 0.022, 0.023, 0.96)
const PANEL_EDGE  := Color(0.42, 0.28, 0.11)
const PANEL_SLOT  := Color(0.035, 0.030, 0.025, 0.96)
const TEXT        := Color(0.94, 0.88, 0.75)
const DIM         := Color(0.58, 0.50, 0.38)
const EMPTY_COL   := Color(0.38, 0.36, 0.34, 0.80)


func _ready() -> void:
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_pressed.emit()


func _build_ui() -> void:
	var save_sys: Node = get_node_or_null("/root/SaveSystem")

	# Full-screen dim backdrop
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Centred panel
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var outer := PanelContainer.new()
	outer.custom_minimum_size = Vector2(720, 0)
	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = PANEL
	outer_style.border_color = PANEL_EDGE
	outer_style.set_border_width_all(2)
	outer_style.set_corner_radius_all(10)
	outer_style.content_margin_left   = 38
	outer_style.content_margin_right  = 38
	outer_style.content_margin_top    = 34
	outer_style.content_margin_bottom = 34
	outer.add_theme_stylebox_override("panel", outer_style)
	center.add_child(outer)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	outer.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "SAVED GAMES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", GOLD)
	vbox.add_child(title)

	_add_separator(vbox)

	# Three slot cards; track the first interactive button for auto-focus.
	var first_btn: Button = null
	for slot_num in range(1, 4):
		var summary: Dictionary = save_sys.get_summary(slot_num) if save_sys else {"exists": false}
		var card_btn := _add_slot_card(vbox, slot_num, summary)
		if card_btn and first_btn == null:
			first_btn = card_btn

	_add_separator(vbox)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(160, 44)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_override("font", FONT_BODY)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.add_theme_color_override("font_color", TEXT)
	back_btn.add_theme_color_override("font_hover_color", GOLD)
	back_btn.add_theme_color_override("font_focus_color", GOLD)
	back_btn.add_theme_stylebox_override("normal", _btn_style(Color(0.055, 0.042, 0.022, 0.92), PANEL_EDGE, 1))
	back_btn.add_theme_stylebox_override("hover",  _btn_style(Color(0.080, 0.060, 0.028, 0.96), GOLD, 2))
	back_btn.add_theme_stylebox_override("focus",  _btn_style(Color(0.080, 0.060, 0.028, 0.96), GOLD, 2))
	back_btn.pressed.connect(func() -> void: back_pressed.emit())
	vbox.add_child(back_btn)

	call_deferred("_focus_default", first_btn if first_btn else back_btn)


## Builds one slot row.  Returns the action Button if the slot has a save (for focus).
func _add_slot_card(parent: Control, slot_num: int, summary: Dictionary) -> Button:
	var has_save: bool = summary.get("exists", false)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 88)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color     = PANEL_SLOT if has_save else Color(0.018, 0.016, 0.014, 0.92)
	card_style.border_color = GOLD if has_save else Color(PANEL_EDGE.r, PANEL_EDGE.g, PANEL_EDGE.b, 0.35)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(6)
	card_style.content_margin_left   = 20
	card_style.content_margin_right  = 20
	card_style.content_margin_top    = 14
	card_style.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", card_style)
	parent.add_child(card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	# Left: info column
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var slot_lbl := Label.new()
	slot_lbl.text = "Slot %d" % slot_num
	slot_lbl.add_theme_font_override("font", FONT_BODY)
	slot_lbl.add_theme_font_size_override("font_size", 14)
	slot_lbl.add_theme_color_override("font_color", GOLD if has_save else DIM)
	info.add_child(slot_lbl)

	if has_save:
		var floor_val: int  = summary.get("floor",    0)
		var gold_val:  int  = summary.get("gold",     0)
		var boons_val: int  = summary.get("boons",    0)
		var saved_at:  String = summary.get("saved_at", "")
		# Trim to YYYY-MM-DD if the string is long enough
		if saved_at.length() >= 10:
			saved_at = saved_at.substr(0, 10)

		var meta_lbl := Label.new()
		meta_lbl.text = "Floor %d  ·  %dg Gold  ·  %d Boon%s" % [
			floor_val, gold_val, boons_val,
			"s" if boons_val != 1 else "",
		]
		meta_lbl.add_theme_font_override("font", FONT_DATA)
		meta_lbl.add_theme_font_size_override("font_size", 22)
		meta_lbl.add_theme_color_override("font_color", TEXT)
		info.add_child(meta_lbl)

		var date_lbl := Label.new()
		date_lbl.text = "Saved %s" % saved_at
		date_lbl.add_theme_font_override("font", FONT_DATA)
		date_lbl.add_theme_font_size_override("font_size", 16)
		date_lbl.add_theme_color_override("font_color", DIM)
		info.add_child(date_lbl)
	else:
		var empty_lbl := Label.new()
		empty_lbl.text = "Empty"
		empty_lbl.add_theme_font_override("font", FONT_DATA)
		empty_lbl.add_theme_font_size_override("font_size", 22)
		empty_lbl.add_theme_color_override("font_color", EMPTY_COL)
		info.add_child(empty_lbl)

	# Right: action button
	var action_btn := Button.new()
	action_btn.custom_minimum_size  = Vector2(150, 44)
	action_btn.size_flags_vertical  = Control.SIZE_SHRINK_CENTER
	action_btn.add_theme_font_override("font", FONT_BODY)

	if has_save:
		action_btn.text = "Load"
		action_btn.add_theme_font_size_override("font_size", 18)
		action_btn.add_theme_color_override("font_color", TEXT)
		action_btn.add_theme_color_override("font_hover_color", GOLD)
		action_btn.add_theme_color_override("font_focus_color", GOLD)
		action_btn.add_theme_stylebox_override("normal", _btn_style(Color(0.055, 0.042, 0.022, 0.92), GOLD,   1))
		action_btn.add_theme_stylebox_override("hover",  _btn_style(Color(0.090, 0.068, 0.030, 0.96), GOLD,   2))
		action_btn.add_theme_stylebox_override("focus",  _btn_style(Color(0.090, 0.068, 0.030, 0.96), GOLD,   2))
		var captured_slot := slot_num
		action_btn.pressed.connect(func() -> void: _load_slot(captured_slot))
	else:
		action_btn.text = "New Slot"
		action_btn.add_theme_font_size_override("font_size", 16)
		action_btn.add_theme_color_override("font_color", DIM)
		action_btn.add_theme_color_override("font_hover_color", TEXT)
		action_btn.add_theme_color_override("font_focus_color", TEXT)
		action_btn.add_theme_stylebox_override("normal", _btn_style(Color(0.030, 0.027, 0.023, 0.92), Color(PANEL_EDGE.r, PANEL_EDGE.g, PANEL_EDGE.b, 0.45), 1))
		action_btn.add_theme_stylebox_override("hover",  _btn_style(Color(0.052, 0.042, 0.022, 0.92), PANEL_EDGE, 1))
		action_btn.add_theme_stylebox_override("focus",  _btn_style(Color(0.052, 0.042, 0.022, 0.92), PANEL_EDGE, 1))
		action_btn.pressed.connect(func() -> void:
			get_tree().change_scene_to_file(ANTECHAMBER))

	row.add_child(action_btn)

	# Return the button only for filled slots (drives initial focus)
	return action_btn if has_save else null


func _load_slot(slot_num: int) -> void:
	var save_sys: Node = get_node_or_null("/root/SaveSystem")
	if save_sys:
		save_sys.load_slot(slot_num)
	get_tree().change_scene_to_file(STAGE_SELECT)


func _focus_default(btn: Button) -> void:
	if is_instance_valid(btn):
		btn.grab_focus()


func _add_separator(parent: Control) -> void:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(PANEL_EDGE.r, PANEL_EDGE.g, PANEL_EDGE.b, 0.55))
	parent.add_child(sep)


func _btn_style(fill: Color, edge: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color      = fill
	style.border_color  = edge
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(4)
	style.content_margin_left   = 12
	style.content_margin_right  = 12
	style.content_margin_top    = 8
	style.content_margin_bottom = 8
	return style
