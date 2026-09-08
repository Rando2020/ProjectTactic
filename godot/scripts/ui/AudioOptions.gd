## Shared title/map audio controls backed by the existing AudioSettings owner.
extends Control

signal closed

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 380)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06)
	style.border_color = Color(0.79, 0.65, 0.34)
	style.set_border_width_all(2)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = "AUDIO OPTIONS"
	heading.add_theme_font_size_override("font_size", 26)
	box.add_child(heading)
	var audio := get_node("/root/AudioSettings")
	for bus in ["Game", "Music", "FX"]:
		var caption := Label.new()
		caption.text = "%s: %d%%" % [bus, audio.get_volume(bus)]
		caption.add_theme_font_size_override("font_size", 20)
		box.add_child(caption)
		var slider := HSlider.new()
		slider.name = bus + "Volume"
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = audio.get_volume(bus)
		slider.custom_minimum_size.y = 32
		slider.value_changed.connect(func(value: float) -> void:
			match bus:
				"Game": audio.set_game_volume(value)
				"Music": audio.set_music_volume(value)
				"FX": audio.set_fx_volume(value)
			caption.text = "%s: %d%%" % [bus, int(value)]
		)
		box.add_child(slider)
	var done := Button.new()
	done.text = "Done"
	done.custom_minimum_size.y = 48
	done.pressed.connect(_close)
	box.add_child(done)
	done.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	closed.emit()
	queue_free()
