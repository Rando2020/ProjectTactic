## OptionsScreen.gd
## Overlay opened from StartScreen. Three volume sliders wired to AudioSettings autoload.
## Emits back_pressed when the player closes; caller connects that to queue_free.

class_name OptionsScreen
extends Control

signal back_pressed

const FONT_TITLE := preload("res://assets/fonts/TrajanPro-Bold.otf")
const FONT_BODY  := preload("res://assets/fonts/Cinzel-Regular.ttf")

const GOLD       := Color(0.88, 0.70, 0.32)
const PANEL      := Color(0.025, 0.022, 0.023, 0.96)
const PANEL_EDGE := Color(0.42, 0.28, 0.11)
const TEXT       := Color(0.94, 0.88, 0.75)
const DIM        := Color(0.58, 0.50, 0.38)


func _ready() -> void:
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_pressed.emit()


func _build_ui() -> void:
	var audio_settings: Node = get_node_or_null("/root/AudioSettings")

	# Semi-transparent backdrop — blocks clicks reaching StartScreen
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# CenterContainer so the panel floats in the middle of the screen
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Styled options panel
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL
	panel_style.border_color = PANEL_EDGE
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left   = 38
	panel_style.content_margin_right  = 38
	panel_style.content_margin_top    = 34
	panel_style.content_margin_bottom = 34
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# Title row
	var title := Label.new()
	title.text = "OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", GOLD)
	vbox.add_child(title)

	_add_separator(vbox)

	# Section label
	var audio_lbl := Label.new()
	audio_lbl.text = "Audio"
	audio_lbl.add_theme_font_override("font", FONT_BODY)
	audio_lbl.add_theme_font_size_override("font_size", 14)
	audio_lbl.add_theme_color_override("font_color", DIM)
	vbox.add_child(audio_lbl)

	# Read current volumes (fallback to sensible defaults if autoload absent)
	var master_vol: int = audio_settings.get_volume("Game")  if audio_settings else 100
	var music_vol:  int = audio_settings.get_volume("Music") if audio_settings else 80
	var fx_vol:     int = audio_settings.get_volume("FX")    if audio_settings else 100

	_add_slider_row(vbox, "Master", master_vol,
		func(v: float) -> void:
			if audio_settings:
				audio_settings.set_game_volume(v))

	_add_slider_row(vbox, "Music", music_vol,
		func(v: float) -> void:
			if audio_settings:
				audio_settings.set_music_volume(v))

	_add_slider_row(vbox, "SFX", fx_vol,
		func(v: float) -> void:
			if audio_settings:
				audio_settings.set_fx_volume(v))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)

	_add_separator(vbox)

	# Close / back button
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(180, 48)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_override("font", FONT_BODY)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", TEXT)
	close_btn.add_theme_color_override("font_hover_color", GOLD)
	close_btn.add_theme_color_override("font_focus_color", GOLD)
	close_btn.add_theme_stylebox_override("normal", _btn_style(Color(0.055, 0.042, 0.022, 0.92), PANEL_EDGE, 1))
	close_btn.add_theme_stylebox_override("hover",  _btn_style(Color(0.080, 0.060, 0.028, 0.96), GOLD,       2))
	close_btn.add_theme_stylebox_override("focus",  _btn_style(Color(0.080, 0.060, 0.028, 0.96), GOLD,       2))
	close_btn.pressed.connect(func() -> void: back_pressed.emit())
	vbox.add_child(close_btn)
	close_btn.grab_focus()


## One labelled slider row: [Name label] [HSlider] [##%]
func _add_slider_row(parent: Control, label_text: String, initial_value: int, on_changed: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.custom_minimum_size = Vector2(74, 0)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_override("font", FONT_BODY)
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", TEXT)
	row.add_child(name_lbl)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step      = 1
	slider.value     = initial_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size   = Vector2(0, 28)
	row.add_child(slider)

	var pct_lbl := Label.new()
	pct_lbl.text = "%d%%" % initial_value
	pct_lbl.custom_minimum_size    = Vector2(54, 0)
	pct_lbl.horizontal_alignment   = HORIZONTAL_ALIGNMENT_RIGHT
	pct_lbl.vertical_alignment     = VERTICAL_ALIGNMENT_CENTER
	pct_lbl.add_theme_font_override("font", FONT_BODY)
	pct_lbl.add_theme_font_size_override("font_size", 17)
	pct_lbl.add_theme_color_override("font_color", GOLD)
	row.add_child(pct_lbl)

	# Update label and fire callback whenever the slider moves
	slider.value_changed.connect(func(v: float) -> void:
		pct_lbl.text = "%d%%" % int(v)
		on_changed.call(v))


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
