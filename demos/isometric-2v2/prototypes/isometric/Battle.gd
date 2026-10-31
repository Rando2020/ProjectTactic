extends BattleScene
## Two presentation modes over exactly the same combat state.
var _mode_button: Button
var _rotate_left: Button
var _rotate_right: Button
var _angle_label: Label
var _stage_caption: Label
var _skin_button: Button

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
	caption.text = "THE PAINTED CHAPEL\n2 vs 2  ·  Arrows: cursor  ·  Enter: select  ·  Esc: back"
	_stage_caption = caption
	caption.add_theme_font_size_override("font_size", 19)
	caption.add_theme_color_override("font_color", Color("e0ca9b"))
	title.add_child(caption)
	_build_stage_controls(title)
	if bool(GameState.practice_session.get("rotatable_stage",false)):
		set_stage_mode(true)

func _build_stage_controls(layer: CanvasLayer) -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(20,70)
	row.add_theme_constant_override("separation",10)
	layer.add_child(row)
	_mode_button = Button.new()
	_mode_button.text = "Try rotatable stage"
	_mode_button.custom_minimum_size = Vector2(240,44)
	_mode_button.pressed.connect(func(): set_stage_mode(not tactical_grid.rotatable_mode))
	row.add_child(_mode_button)
	_rotate_left = Button.new()
	_rotate_left.text = "↶  Q"
	_rotate_left.custom_minimum_size = Vector2(84,44)
	_rotate_left.pressed.connect(func(): rotate_stage(-1))
	row.add_child(_rotate_left)
	_rotate_right = Button.new()
	_rotate_right.text = "E  ↷"
	_rotate_right.custom_minimum_size = Vector2(84,44)
	_rotate_right.pressed.connect(func(): rotate_stage(1))
	row.add_child(_rotate_right)
	_angle_label = Label.new()
	_angle_label.add_theme_font_size_override("font_size",20)
	row.add_child(_angle_label)
	for button: Button in [_mode_button,_rotate_left,_rotate_right]:
		button.add_theme_font_size_override("font_size",20)
		button.focus_mode = Control.FOCUS_NONE
	_skin_button = Button.new()
	_skin_button.position = Vector2(20, 118)
	_skin_button.custom_minimum_size = Vector2(300, 30)
	_skin_button.add_theme_font_size_override("font_size", 16)
	_skin_button.focus_mode = Control.FOCUS_NONE
	_skin_button.pressed.connect(func(): set_compact_skins(not bool(GameState.practice_session.get("compact_skins", true))))
	layer.add_child(_skin_button)
	_update_stage_controls()

func set_compact_skins(enabled: bool) -> bool:
	if battle_manager.is_resolving_action: return false
	GameState.practice_session["compact_skins"] = enabled
	for unit in battle_manager.units.values():
		if is_instance_valid(unit): unit._refresh_directional_sprite()
	battle_ui._portrait_cache.clear()
	var active = battle_manager.units.get(battle_manager.active_unit_id)
	if is_instance_valid(active) and is_instance_valid(battle_ui._active_portrait):
		battle_ui._active_portrait.texture = battle_ui._framed_portrait(active.unit_data.id)
	battle_ui._refresh_turn_portraits()
	battle_ui.refresh_skin_portraits()
	_update_stage_controls()
	return true

func set_stage_mode(enabled: bool) -> bool:
	if battle_manager.is_resolving_action: return false
	tactical_grid.set_rotatable(enabled)
	GameState.practice_session["rotatable_stage"] = enabled
	_frame_battlefield_camera()
	if battle_ui._selection:
		battle_ui._selection.refresh()
	_update_stage_controls()
	return true

func rotate_stage(step: int) -> bool:
	if battle_manager.is_resolving_action or not tactical_grid.rotatable_mode: return false
	tactical_grid.rotate_view(step)
	_frame_battlefield_camera()
	if battle_ui._selection:
		battle_ui._selection.cursor.queue_redraw()
		battle_ui._selection.refresh()
	_update_stage_controls()
	return true

func _update_stage_controls() -> void:
	if not is_instance_valid(_mode_button): return
	var rotating: bool = tactical_grid.rotatable_mode
	var busy: bool = battle_manager.is_resolving_action
	if is_instance_valid(_skin_button):
		_skin_button.disabled = busy
		_skin_button.text = "Skins: compact classes · use original" if bool(GameState.practice_session.get("compact_skins", true)) else "Skins: original · use compact classes"
	_mode_button.disabled = busy
	_mode_button.text = "Return to painted stage" if rotating else "Try rotatable stage"
	_rotate_left.visible = rotating
	_rotate_right.visible = rotating
	_rotate_left.disabled = busy
	_rotate_right.disabled = busy
	_angle_label.text = "View %d / 4 · flat playable floor" % (tactical_grid.quarter_turn+1) if rotating else "Painted comparison"
	_stage_caption.text = ("THE STONE CHAPEL · ROTATABLE COMPARISON" if rotating else "THE PAINTED CHAPEL") + "\n2 vs 2  ·  Arrows: cursor  ·  Enter: select  ·  Esc: back"


func _frame_battlefield_camera() -> void:
	if not _battle_camera or not tactical_grid: return
	var viewport := get_viewport_rect().size
	var bounds := tactical_grid.get_board_bounds().grow(24.0)
	_camera_bounds = bounds.grow(260)
	var area := Rect2(Vector2(24, 160), Vector2(maxf(320, viewport.x - 460), maxf(240, viewport.y - 200)))
	_camera_zoom_value = clampf(minf(area.size.x / bounds.size.x, area.size.y / bounds.size.y), 0.2, 1.5)
	_camera_base_position = bounds.get_center() + (viewport * 0.5 - area.get_center()) / _camera_zoom_value
	_battle_camera.position = _camera_base_position
	_battle_camera.zoom = Vector2.ONE * _camera_zoom_value

# Arrow keys belong to the battlefield cursor, not the camera in this demo.
func _process(delta: float) -> void:
	_update_camera_shake(delta)
	_update_stage_controls()
