class_name CinematicTacticalGrid
extends "res://scripts/grid/TacticalGrid.gd"

## Presentation-only tactical highlight layer for the Ashvale vertical slice.
## Grid authority, click handling, movement legality, heights and occupancy stay
## in TacticalGrid. This subclass only changes how those states are drawn.

const MOVE_COLOR := Color(0.16, 0.76, 0.96, 0.42)
const PATH_COLOR := Color(0.45, 0.95, 1.0, 0.58)
const ATTACK_COLOR := Color(0.94, 0.24, 0.16, 0.44)
const ABILITY_COLOR := Color(0.64, 0.34, 0.96, 0.42)
const AOE_COLOR := Color(1.0, 0.20, 0.10, 0.58)
const PLAYER_ACTIVE := Color(0.52, 0.88, 1.0, 0.96)
const ENEMY_ACTIVE := Color(1.0, 0.38, 0.24, 0.96)
const TARGET_COLOR := Color(1.0, 0.82, 0.24, 0.98)


func _refresh_highlights() -> void:
	if not highlight_layer:
		return
	for child in highlight_layer.get_children():
		child.queue_free()

	var pulse: float = 0.78 + 0.22 * (sin(_highlight_animation_time * 1.45) * 0.5 + 0.5)

	for pos: Vector2i in move_tiles:
		_add_cinematic_tile(pos, MOVE_COLOR, 0.88, pulse, 1.5)

	for i in range(path_preview_tiles.size()):
		var path_pos: Vector2i = path_preview_tiles[i]
		var path_alpha: float = 0.42 + minf(float(i) * 0.035, 0.20)
		_add_cinematic_tile(path_pos, Color(PATH_COLOR.r, PATH_COLOR.g, PATH_COLOR.b, path_alpha), 0.62, 1.0, 1.25)
		_add_path_dot(path_pos, i + 1)

	for pos: Vector2i in attack_tiles:
		_add_cinematic_tile(pos, ATTACK_COLOR, 0.88, pulse, 1.6)

	for pos: Vector2i in ability_tiles:
		_add_cinematic_tile(pos, ABILITY_COLOR, 0.88, pulse, 1.6)

	for pos: Vector2i in aoe_preview_tiles:
		_add_cinematic_tile(pos, AOE_COLOR, 0.96, 1.0, 2.2)

	if _is_valid_pos(active_unit_tile):
		var active_color: Color = PLAYER_ACTIVE if active_unit_team == "player" else ENEMY_ACTIVE
		_add_cinematic_tile(active_unit_tile, Color(active_color.r, active_color.g, active_color.b, 0.14), 0.92, 1.0, 1.0)
		_add_cinematic_ring(active_unit_tile, active_color, 1.10 + (pulse - 0.78) * 0.10, 3.0, 0.90)

	if _is_valid_pos(selected_tile):
		var selected_color: Color = TARGET_COLOR
		if selected_tile in move_tiles:
			selected_color = PLAYER_ACTIVE
		elif selected_tile in attack_tiles:
			selected_color = ATTACK_COLOR.lightened(0.12)
		elif selected_tile in ability_tiles:
			selected_color = ABILITY_COLOR.lightened(0.18)
		_add_cinematic_ring(selected_tile, selected_color, 1.18, 3.5, 0.98)
		_add_center_mark(selected_tile, selected_color)

	if _is_valid_pos(target_tile):
		_add_target_lock_cinematic(target_tile)


func _add_cinematic_tile(pos: Vector2i, color: Color, scale_value: float,
		pulse: float, rim_width: float) -> void:
	var fill := Polygon2D.new()
	fill.polygon = _diamond_polygon(scale_value)
	fill.position = _grid_to_local(pos)
	fill.color = Color(color.r, color.g, color.b, color.a * pulse * 0.62)
	fill.z_index = _depth_for(pos) + 50
	highlight_layer.add_child(fill)

	var rim := Line2D.new()
	var poly: PackedVector2Array = _diamond_polygon(scale_value)
	rim.points = PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]])
	rim.width = rim_width
	rim.default_color = Color(color.r, color.g, color.b, minf(color.a * pulse + 0.34, 1.0))
	rim.position = _grid_to_local(pos)
	rim.z_index = _depth_for(pos) + 51
	highlight_layer.add_child(rim)


func _add_cinematic_ring(pos: Vector2i, color: Color, scale_value: float,
		width: float, alpha: float) -> void:
	var ring := Line2D.new()
	var poly: PackedVector2Array = _diamond_polygon(scale_value)
	ring.points = PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]])
	ring.width = width
	ring.default_color = Color(color.r, color.g, color.b, alpha)
	ring.position = _grid_to_local(pos)
	ring.z_index = _depth_for(pos) + 58
	highlight_layer.add_child(ring)


func _add_center_mark(pos: Vector2i, color: Color) -> void:
	var mark := Polygon2D.new()
	mark.polygon = PackedVector2Array([
		Vector2(0.0, -5.0),
		Vector2(7.0, 0.0),
		Vector2(0.0, 5.0),
		Vector2(-7.0, 0.0),
	])
	mark.color = Color(color.r, color.g, color.b, 0.92)
	mark.position = _grid_to_local(pos)
	mark.z_index = _depth_for(pos) + 60
	highlight_layer.add_child(mark)


func _add_path_dot(pos: Vector2i, step: int) -> void:
	var dot := Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(12):
		var angle: float = TAU * float(i) / 12.0
		points.append(Vector2(cos(angle) * 5.0, sin(angle) * 3.0))
	dot.polygon = points
	dot.color = Color(0.76, 0.98, 1.0, 0.92)
	dot.position = _grid_to_local(pos)
	dot.z_index = _depth_for(pos) + 61
	dot.set_meta("path_step", step)
	highlight_layer.add_child(dot)


func _add_target_lock_cinematic(pos: Vector2i) -> void:
	_add_cinematic_ring(pos, TARGET_COLOR, 1.24, 3.5, 0.96)

	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(-9.0, -15.0),
		Vector2(-3.5, -15.0),
		Vector2(-3.5, -27.0),
		Vector2(3.5, -27.0),
		Vector2(3.5, -15.0),
		Vector2(9.0, -15.0),
	])
	arrow.position = _grid_to_local(pos) + Vector2(0.0, -tile_size.y * 0.30)
	arrow.color = TARGET_COLOR
	arrow.z_index = _depth_for(pos) + 70
	highlight_layer.add_child(arrow)
