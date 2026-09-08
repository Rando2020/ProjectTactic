class_name StartScreen
extends Control

const HUB_SCENE := "res://scenes/HubScene.tscn"
const FONT_TITLE := preload("res://assets/fonts/TrajanPro-Bold.otf")
const FONT_BODY := preload("res://assets/fonts/Cinzel-Regular.ttf")

const GOLD := Color(0.88, 0.70, 0.32)
const GOLD_BRIGHT := Color(1.0, 0.88, 0.52)
const INK := Color(0.018, 0.017, 0.027)
const PANEL := Color(0.025, 0.022, 0.023, 0.86)
const PANEL_EDGE := Color(0.42, 0.28, 0.11)
const TEXT := Color(0.94, 0.88, 0.75)
const DIM := Color(0.58, 0.50, 0.38)

@onready var music_player: AudioStreamPlayer = $MusicPlayer

var _button_box: VBoxContainer
var _status_label: Label
var _buttons: Array[Button] = []
var _pulse: float = 0.0
var _options: Control
var _load_dialog: AcceptDialog


func _ready() -> void:
	_setup_music()
	_build_ui()
	call_deferred("_focus_first_button")


func _process(delta: float) -> void:
	_pulse = fmod(_pulse + delta, TAU)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		return
	if event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == null:
		_focus_first_button()


func _draw() -> void:
	var rect := get_rect()
	_draw_background(rect)
	_draw_rock_shapes(rect)
	_draw_title_flourish(rect)
	_draw_border(rect)


func _setup_music() -> void:
	if music_player.stream is AudioStreamWAV:
		var wav_stream := music_player.stream as AudioStreamWAV
		wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_player.bus = "Music"
	music_player.play()


func _build_ui() -> void:
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 70)
	root.add_theme_constant_override("margin_top", 54)
	root.add_theme_constant_override("margin_right", 70)
	root.add_theme_constant_override("margin_bottom", 54)
	add_child(root)

	var layout := HBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(layout)

	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_column.alignment = BoxContainer.ALIGNMENT_BEGIN
	title_column.add_theme_constant_override("separation", 8)
	layout.add_child(title_column)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(1, 78)
	title_column.add_child(top_spacer)

	var title_small := _make_label("THE", 58, GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	title_small.custom_minimum_size = Vector2(1220, 66)
	title_column.add_child(title_small)

	var title := _make_label("APPOINTED", 126, GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	title.custom_minimum_size = Vector2(1220, 136)
	title_column.add_child(title)

	var subtitle := _make_label("AS ABOVE", 46, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.custom_minimum_size = Vector2(1220, 62)
	title_column.add_child(subtitle)

	var menu_spacer := Control.new()
	menu_spacer.custom_minimum_size = Vector2(90, 1)
	layout.add_child(menu_spacer)

	var menu_panel := PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(430, 438)
	menu_panel.add_theme_stylebox_override("panel", _panel_style(PANEL, PANEL_EDGE, 3, 14))
	layout.add_child(menu_panel)

	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 28)
	menu_margin.add_theme_constant_override("margin_top", 28)
	menu_margin.add_theme_constant_override("margin_right", 28)
	menu_margin.add_theme_constant_override("margin_bottom", 24)
	menu_panel.add_child(menu_margin)

	_button_box = VBoxContainer.new()
	_button_box.add_theme_constant_override("separation", 10)
	menu_margin.add_child(_button_box)

	_add_menu_button("New Game", _on_new_game_pressed)
	_add_menu_button("Continue", _on_continue_pressed)
	_add_menu_button("Load Game", _on_load_pressed)
	_add_menu_button("Options", _on_options_pressed)
	_add_menu_button("Credits", _on_credits_pressed)
	if not OS.has_feature("web"):
		_add_menu_button("Exit", _on_exit_pressed)

	_status_label = _make_label("Press Enter, Space, or A to select.", 17, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	_status_label.custom_minimum_size = Vector2(380, 36)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button_box.add_child(_status_label)
	_refresh_continue()


func _add_menu_button(label_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(370, 54)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", FONT_BODY)
	button.add_theme_font_size_override("font_size", 29)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", GOLD_BRIGHT)
	button.add_theme_color_override("font_focus_color", GOLD_BRIGHT)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.030, 0.027, 0.025, 0.92), Color(0.27, 0.17, 0.07), 1, 2))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.072, 0.055, 0.028, 0.96), GOLD, 2, 2))
	button.add_theme_stylebox_override("focus", _panel_style(Color(0.080, 0.058, 0.026, 0.98), GOLD_BRIGHT, 3, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.11, 0.082, 0.035, 1.0), GOLD_BRIGHT, 3, 2))
	button.pressed.connect(callback)
	button.mouse_entered.connect(func() -> void: button.grab_focus())
	_button_box.add_child(button)
	_buttons.append(button)


func _focus_first_button() -> void:
	if not _buttons.is_empty():
		_buttons[1 if not _buttons[1].disabled else 0].grab_focus()


func _on_new_game_pressed() -> void:
	_play_confirm()
	music_player.stop()
	get_tree().change_scene_to_file(HUB_SCENE)


func _on_continue_pressed() -> void:
	_play_confirm()
	var saves := get_node("/root/SaveSystem")
	if not saves.load_slot():
		_set_status(saves.last_error)
		return
	music_player.stop()
	get_tree().change_scene_to_file(saves.continue_scene())


func _refresh_continue() -> void:
	var summary: Dictionary = get_node("/root/SaveSystem").get_summary()
	_buttons[1].disabled = not summary.get("exists", false)
	if summary.get("exists", false):
		_buttons[0].text = "Enter Hub"
		_set_status("Continue: Floor %d / %dg" % [summary.floor, summary.gold] if summary.get("has_run", false) else "Continue: Hub / %dg" % summary.gold)
	else:
		_set_status("Start a new game. Your progress saves at run checkpoints.")


func _on_load_pressed() -> void:
	_play_confirm()
	if is_instance_valid(_load_dialog):
		return
	_load_dialog = AcceptDialog.new()
	_load_dialog.title = "Load checkpoint"
	_load_dialog.ok_button_text = "Cancel"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_load_dialog.add_child(box)
	var saves := get_node("/root/SaveSystem")
	for slot in range(1, 4):
		var summary: Dictionary = saves.get_summary(slot)
		var button := Button.new()
		button.custom_minimum_size = Vector2(440, 52)
		var label := "Autosave" if slot == 1 else "Slot %d" % slot
		button.text = "%s: %dg / %s" % [label, summary.gold, "Floor %d" % summary.floor if summary.get("has_run", false) else "Hub"] if summary.get("exists", false) else label + ": Empty or unavailable"
		button.disabled = not summary.get("exists", false)
		button.pressed.connect(_load_checkpoint.bind(slot))
		box.add_child(button)
	_load_dialog.confirmed.connect(_load_dialog.queue_free)
	_load_dialog.canceled.connect(_load_dialog.queue_free)
	add_child(_load_dialog)
	_load_dialog.popup_centered(Vector2i(480, 280))


func _load_checkpoint(slot: int) -> void:
	var saves := get_node("/root/SaveSystem")
	if not saves.activate_slot(slot):
		_set_status(saves.last_error)
		return
	music_player.stop()
	get_tree().change_scene_to_file(saves.continue_scene())


func _on_options_pressed() -> void:
	_play_confirm()
	if is_instance_valid(_options):
		return
	_options = preload("res://scripts/ui/AudioOptions.gd").new()
	_options.closed.connect(_focus_first_button)
	add_child(_options)


func _on_credits_pressed() -> void:
	_play_confirm()
	_set_status("Created by ProjectTactic. Music: Gold Severance.")


func _on_exit_pressed() -> void:
	_play_confirm()
	get_tree().quit()


func _set_status(message: String) -> void:
	_status_label.text = message


func _play_confirm() -> void:
	var audio_settings := get_node_or_null("/root/AudioSettings")
	if audio_settings and audio_settings.has_method("play_sfx"):
		audio_settings.play_sfx("ui_confirm", -3.0)


func _make_label(label_text: String, font_px: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_TITLE)
	label.add_theme_font_size_override("font_size", font_px)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.76))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	return label


func _panel_style(fill: Color, edge: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _draw_background(rect: Rect2) -> void:
	draw_rect(rect, INK)
	for i in range(11):
		var t := float(i) / 10.0
		var color := Color(0.08 + t * 0.08, 0.07 + t * 0.02, 0.14 + t * 0.16, 0.42)
		var cloud_rect := Rect2(
			Vector2(rect.size.x * (0.08 + t * 0.08), rect.size.y * (0.08 + sin(t * 4.0) * 0.06)),
			Vector2(rect.size.x * 0.34, rect.size.y * 0.58)
		)
		draw_rect(cloud_rect, color)
	for i in range(7):
		var center := Vector2(rect.size.x * (0.26 + float(i) * 0.095), rect.size.y * (0.40 + sin(float(i)) * 0.12))
		var radius := 230.0 + sin(_pulse + float(i)) * 18.0
		draw_circle(center, radius, Color(0.43, 0.10, 0.30, 0.16))
	draw_rect(Rect2(Vector2.ZERO, rect.size), Color(0.0, 0.0, 0.0, 0.22))


func _draw_rock_shapes(rect: Rect2) -> void:
	var rock_color := Color(0.09, 0.13, 0.20, 0.86)
	var rock_edge := Color(0.22, 0.28, 0.38, 0.72)
	var left_base := PackedVector2Array([
		Vector2(rect.size.x * 0.06, rect.size.y * 0.77),
		Vector2(rect.size.x * 0.13, rect.size.y * 0.54),
		Vector2(rect.size.x * 0.23, rect.size.y * 0.57),
		Vector2(rect.size.x * 0.28, rect.size.y * 0.92),
		Vector2(rect.size.x * 0.04, rect.size.y * 0.92),
	])
	var right_arch := PackedVector2Array([
		Vector2(rect.size.x * 0.70, rect.size.y * 0.18),
		Vector2(rect.size.x * 0.83, rect.size.y * 0.23),
		Vector2(rect.size.x * 0.93, rect.size.y * 0.63),
		Vector2(rect.size.x * 0.84, rect.size.y * 0.88),
		Vector2(rect.size.x * 0.77, rect.size.y * 0.52),
		Vector2(rect.size.x * 0.65, rect.size.y * 0.40),
	])
	draw_colored_polygon(left_base, rock_color)
	draw_polyline(left_base, rock_edge, 4.0, true)
	draw_colored_polygon(right_arch, rock_color)
	draw_polyline(right_arch, rock_edge, 4.0, true)
	for i in range(18):
		var x := rect.size.x * (0.04 + float(i) * 0.052)
		var y := rect.size.y * (0.86 + sin(float(i) * 1.7) * 0.035)
		draw_circle(Vector2(x, y), 22.0 + float(i % 4) * 8.0, Color(0.12, 0.18, 0.23, 0.55))


func _draw_title_flourish(rect: Rect2) -> void:
	var center_x := rect.size.x * 0.48
	var y := rect.size.y * 0.37
	var line_color := Color(GOLD.r, GOLD.g, GOLD.b, 0.48 + 0.18 * sin(_pulse))
	draw_line(Vector2(center_x - 300.0, y), Vector2(center_x - 95.0, y), line_color, 2.0)
	draw_line(Vector2(center_x + 95.0, y), Vector2(center_x + 300.0, y), line_color, 2.0)
	draw_circle(Vector2(center_x, y), 8.0, line_color)


func _draw_border(rect: Rect2) -> void:
	var margin := 28.0
	var border_rect := Rect2(Vector2(margin, margin), rect.size - Vector2(margin * 2.0, margin * 2.0))
	draw_rect(border_rect, Color(GOLD.r, GOLD.g, GOLD.b, 0.62), false, 2.0)
	draw_rect(border_rect.grow(-8.0), Color(0.12, 0.08, 0.03, 0.72), false, 1.0)
	var corners := [
		border_rect.position,
		Vector2(border_rect.end.x, border_rect.position.y),
		Vector2(border_rect.position.x, border_rect.end.y),
		border_rect.end,
	]
	for corner in corners:
		draw_circle(corner, 10.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.76))
