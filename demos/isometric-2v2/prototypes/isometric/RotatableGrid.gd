extends TacticalGrid
## Presentation-only projection adapter; the original cells and rules never rotate.
var rotatable_mode := false
var quarter_turn := 0
var stage_view: Node2D
var _painted_tile_size := Vector2i(128,64)

func set_rotatable(enabled: bool) -> void:
	if enabled == rotatable_mode: return
	if enabled and not is_instance_valid(stage_view):
		stage_view = preload("res://prototypes/isometric/RotatableStage.gd").new()
		terrain_view = stage_view
		add_child(stage_view)
		stage_view.configure(self)
	rotatable_mode = enabled
	if stage_view:
		stage_view.visible = enabled
		stage_view.set_process(enabled)
		stage_view.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED
	highlight_layer.visible = not enabled
	if enabled:
		stage_view.set_angle(quarter_turn)
		_update_tile_size()
	else:
		tile_size = _painted_tile_size
	_draw_base_tiles()
	_reproject_units()
	_refresh_highlights()

func rotate_view(step: int) -> void:
	if not rotatable_mode: return
	quarter_turn = posmod(quarter_turn + step,4)
	stage_view.set_angle(quarter_turn)
	_update_tile_size()
	_reproject_units()
	_refresh_highlights()

func _update_tile_size() -> void:
	var center: Vector2 = stage_view.projected_point(Vector2(2,2))
	var corner: Vector2 = stage_view.projected_point(Vector2(2.5,2.5))
	var side: Vector2 = stage_view.projected_point(Vector2(2.5,1.5))
	tile_size = Vector2i(roundi(maxf(absf(corner.x-center.x),absf(side.x-center.x))*2),roundi(maxf(absf(corner.y-center.y),absf(side.y-center.y))*2))

func _draw_base_tiles() -> void:
	super._draw_base_tiles()
	if rotatable_mode:
		set_legacy_terrain_visible(false)
	if is_instance_valid(stage_view): stage_view.visible = rotatable_mode

func _reproject_units() -> void:
	if not unit_layer: return
	for child in unit_layer.get_children():
		if child is Unit:
			child.position = _unit_foot_pos(child.grid_pos)
			child.z_index = _unit_depth_for(child.grid_pos)
			child.set_view_quarter(quarter_turn if rotatable_mode else 0)
			if child._sprite: child._sprite.visible = not rotatable_mode
		elif child.has_method("queue_redraw"): child.queue_redraw()

func _grid_to_local(pos: Vector2i) -> Vector2:
	return stage_view.projected_point(Vector2(pos)) if rotatable_mode and stage_view else super._grid_to_local(pos)

func _unit_foot_pos(pos: Vector2i) -> Vector2:
	return _grid_to_local(pos) if rotatable_mode else super._unit_foot_pos(pos)

func _local_to_grid(point: Vector2) -> Vector2i:
	if not rotatable_mode: return super._local_to_grid(point)
	var cell: Vector2 = stage_view.unproject_ground(point)
	var rounded := Vector2i(roundi(cell.x),roundi(cell.y))
	if not tiles.has(rounded): return Vector2i(-1,-1)
	return rounded if absf(cell.x-rounded.x) <= 0.5 and absf(cell.y-rounded.y) <= 0.5 else Vector2i(-1,-1)

func _unit_depth_for(pos: Vector2i) -> int:
	return roundi(_grid_to_local(pos).y) if rotatable_mode else super._unit_depth_for(pos)

func get_board_bounds() -> Rect2:
	if not rotatable_mode: return super.get_board_bounds()
	var result := Rect2(_grid_to_local(Vector2i(0,0)),Vector2.ONE)
	for cell: Vector2i in tiles:
		result = result.expand(_grid_to_local(cell))
	return result.grow(155)

func screen_step(delta: Vector2i) -> Vector2i:
	if not rotatable_mode: return delta
	match quarter_turn:
		1: return Vector2i(delta.y,-delta.x)
		2: return -delta
		3: return Vector2i(-delta.y,delta.x)
	return delta
