extends BattleScene
## Opt-in standalone proof: same battle logic, original 2D painted art only.

func _ready() -> void:
	if GameState.practice_session.is_empty():
		GameState.begin_illustrated_chapel_practice()
	GameState.practice_session["painted_chapel"] = true
	GameState.practice_session["rig3d"] = false
	GameState.practice_session["terrain3d"] = false
	GameState.practice_session["isolated_isometric"] = true

	unit_scene = preload("res://prototypes/isometric/Unit.tscn")
	super._ready()
	# No 3D/quality comparison controls in this deliberately 2D proof.
	if is_instance_valid(comparison_panel):
		comparison_panel.queue_free()
	var title := CanvasLayer.new()
	add_child(title)
	var caption := Label.new()
	caption.position = Vector2(20, 18)
	caption.text = "THE PAINTED CHAPEL\n2D isometric proof  ·  Click highlighted tiles to commit\nM Move  ·  A Attack  ·  S Skills  ·  W Wait  ·  Esc Cancel"
	caption.add_theme_font_size_override("font_size", 19)
	caption.add_theme_color_override("font_color", Color("e0ca9b"))
	title.add_child(caption)

func _frame_battlefield_camera() -> void:
	if not _battle_camera or not tactical_grid: return
	var viewport := get_viewport_rect().size
	var bounds := tactical_grid.get_board_bounds().grow(24.0)
	_camera_bounds = bounds.grow(260)
	var area := Rect2(Vector2(24, 100), Vector2(maxf(320, viewport.x - 460), maxf(240, viewport.y - 140)))
	_camera_zoom_value = clampf(minf(area.size.x / bounds.size.x, area.size.y / bounds.size.y), 0.2, 1.5)
	_camera_base_position = bounds.get_center() + (viewport * 0.5 - area.get_center()) / _camera_zoom_value
	_battle_camera.position = _camera_base_position
	_battle_camera.zoom = Vector2.ONE * _camera_zoom_value
