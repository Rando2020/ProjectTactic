class_name StartScreen
extends Control

const ANTECHAMBER_SCENE  := "res://scenes/AntechamberScene.tscn"
const STAGE_SELECT_SCENE := "res://scenes/StageSelect.tscn"
const OPTIONS_SCENE      := preload("res://scenes/OptionsScreen.tscn")
const SAVE_SLOT_SCENE    := preload("res://scenes/SaveSlotScreen.tscn")
const FONT_TITLE := preload("res://assets/fonts/TrajanPro-Bold.otf")
const FONT_BODY  := preload("res://assets/fonts/Cinzel-Regular.ttf")
const BG_TEXTURE := preload("res://assets/ui/start_screen/appointed-title-screen.png")
const TITLE_MUSIC := preload("res://assets/music/gold-severance.ogg")

const GOLD       := Color(0.88, 0.70, 0.32)
const GOLD_BRIGHT := Color(1.0, 0.88, 0.52)
const PANEL      := Color(0.025, 0.022, 0.023, 0.90)
const PANEL_EDGE := Color(0.42, 0.28, 0.11)
const TEXT       := Color(0.94, 0.88, 0.75)
const DIM        := Color(0.58, 0.50, 0.38)

@onready var music_player: AudioStreamPlayer = $MusicPlayer

var _button_box: VBoxContainer
var _status_label: Label
var _buttons: Array[Button] = []
var _pulse: float = 0.0


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
	_draw_title_flourish(rect)
	_draw_border(rect)


func _setup_music() -> void:
	_ensure_music_bus()
	if music_player.stream == null:
		music_player.stream = TITLE_MUSIC
	if music_player.stream is AudioStreamOggVorbis:
		var ogg_stream := music_player.stream as AudioStreamOggVorbis
		ogg_stream.loop = true
	music_player.bus = "Music"
	if not music_player.finished.is_connected(_restart_music):
		music_player.finished.connect(_restart_music)
	call_deferred("_restart_music")


func _restart_music() -> void:
	if music_player == null or music_player.stream == null:
		return
	if not music_player.playing:
		music_player.play(0.0)


func _ensure_music_bus() -> void:
	var game_bus := AudioServer.get_bus_index("Game")
	if game_bus == -1:
		AudioServer.add_bus()
		game_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(game_bus, "Game")
		AudioServer.set_bus_send(game_bus, "Master")
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus == -1:
		AudioServer.add_bus()
		music_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_bus, "Music")
	AudioServer.set_bus_send(music_bus, "Game")
	AudioServer.set_bus_mute(music_bus, false)


func _build_ui() -> void:
	# Full-screen background image
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture = BG_TEXTURE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

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

	# Spacer takes up the left area where title art already lives in the image
	var title_spacer := Control.new()
	title_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(title_spacer)

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

	_add_menu_button("New Game",  _on_new_game_pressed)
	_add_menu_button("Continue",  _on_continue_pressed)
	_add_menu_button("Load Game", _on_load_pressed)
	_add_menu_button("Options",   _on_options_pressed)
	_add_menu_button("Credits",   _on_credits_pressed)
	_add_menu_button("Exit",      _on_exit_pressed)

	_status_label = _make_label("Press Enter, Space, or A to select.", 17, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	_status_label.custom_minimum_size = Vector2(380, 36)
	_button_box.add_child(_status_label)


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
	button.add_theme_stylebox_override("normal",  _panel_style(Color(0.030, 0.027, 0.025, 0.92), Color(0.27, 0.17, 0.07), 1, 2))
	button.add_theme_stylebox_override("hover",   _panel_style(Color(0.072, 0.055, 0.028, 0.96), GOLD, 2, 2))
	button.add_theme_stylebox_override("focus",   _panel_style(Color(0.080, 0.058, 0.026, 0.98), GOLD_BRIGHT, 3, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.11, 0.082, 0.035, 1.0),   GOLD_BRIGHT, 3, 2))
	button.pressed.connect(callback)
	button.mouse_entered.connect(func() -> void: button.grab_focus())
	_button_box.add_child(button)
	_buttons.append(button)


func _focus_first_button() -> void:
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func _on_new_game_pressed() -> void:
	_play_confirm()
	music_player.stop()
	get_tree().change_scene_to_file(ANTECHAMBER_SCENE)


func _on_continue_pressed() -> void:
	_play_confirm()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs and gs.get("active_run") != null:
		music_player.stop()
		get_tree().change_scene_to_file(STAGE_SELECT_SCENE)
	else:
		_set_status("No run in progress — start a New Game or use Load Game.")


func _on_load_pressed() -> void:
	_play_confirm()
	var screen := SAVE_SLOT_SCENE.instantiate() as SaveSlotScreen
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.back_pressed.connect(screen.queue_free)
	add_child(screen)


func _on_options_pressed() -> void:
	_play_confirm()
	var screen := OPTIONS_SCENE.instantiate() as OptionsScreen
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.back_pressed.connect(screen.queue_free)
	add_child(screen)


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
	style.border_width_left   = border_width
	style.border_width_top    = border_width
	style.border_width_right  = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left     = corner_radius
	style.corner_radius_top_right    = corner_radius
	style.corner_radius_bottom_left  = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left  = 10
	style.content_margin_right = 10
	style.content_margin_top    = 6
	style.content_margin_bottom = 6
	return style


func _draw_title_flourish(rect: Rect2) -> void:
	var center_x := rect.size.x * 0.48
	var y        := rect.size.y * 0.37
	var line_color := Color(GOLD.r, GOLD.g, GOLD.b, 0.48 + 0.18 * sin(_pulse))
	draw_line(Vector2(center_x - 300.0, y), Vector2(center_x - 95.0, y), line_color, 2.0)
	draw_line(Vector2(center_x + 95.0, y), Vector2(center_x + 300.0, y), line_color, 2.0)
	draw_circle(Vector2(center_x, y), 8.0, line_color)


func _draw_border(rect: Rect2) -> void:
	var margin      := 28.0
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
