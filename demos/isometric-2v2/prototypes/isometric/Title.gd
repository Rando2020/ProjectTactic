extends Control

func _ready() -> void:
	var background := TextureRect.new()
	background.texture = preload("res://assets/environments/ruined-chapel/chapel-painted-background.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.45, 0.45, 0.45)
	add_child(background)
	var box := VBoxContainer.new()
	box.position = Vector2(120, 180)
	box.add_theme_constant_override("separation", 24)
	add_child(box)
	var title := Label.new()
	title.text = "ZANE\nThe Painted Chapel"
	title.add_theme_font_size_override("font_size", 56)
	box.add_child(title)
	var detail := Label.new()
	detail.text = "A separate 2D isometric proof.\nOriginal art. Shared ProjectTactic combat.\nZane + Kael against two enemies; retry freely."
	detail.add_theme_font_size_override("font_size", 24)
	box.add_child(detail)
	var play := Button.new()
	play.text = "Play 2 vs 2"
	play.custom_minimum_size = Vector2(300, 64)
	play.pressed.connect(func():
		play.disabled = true
		get_tree().change_scene_to_file("res://prototypes/isometric/Skirmish.tscn"))
	box.add_child(play)
	play.grab_focus()
