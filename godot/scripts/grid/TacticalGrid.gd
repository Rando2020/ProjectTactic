class_name TacticalGrid
extends Node2D

signal tile_clicked(grid_pos: Vector2i)
signal unit_clicked(unit_id: String)
signal tile_hovered(grid_pos: Vector2i)

@export var tile_size: Vector2i = Vector2i(96, 48)
@export var height_step: float = 14.0
@export var tile_thickness: float = 16.0
@export var map_origin: Vector2 = Vector2(320, 64)
@export var map_data: MapData

var tiles: Dictionary = {}           # Vector2i -> Dictionary
var unit_positions: Dictionary = {}  # Vector2i -> unit_id String
var _tile_top_polys: Dictionary = {} # Vector2i -> Polygon2D, for mutation/art swap

var move_tiles: Array[Vector2i] = []
var attack_tiles: Array[Vector2i] = []
var ability_tiles: Array[Vector2i] = []
var aoe_preview_tiles: Array[Vector2i] = []
var selected_tile: Vector2i = Vector2i(-1, -1)

@onready var highlight_layer: Node2D = $HighlightLayer
@onready var unit_layer: Node2D = $UnitLayer


func _ready() -> void:
	_configure_layers()
	if map_data:
		_build_tiles()
		_draw_base_tiles()


func initialize_from_map(p_map_data: MapData) -> void:
	_configure_layers()
	map_data = p_map_data
	_build_tiles()
	_draw_base_tiles()


func _configure_layers() -> void:
	if highlight_layer:
		highlight_layer.z_index = 1000
	if unit_layer:
		unit_layer.z_index = 2000


func _build_tiles() -> void:
	tiles.clear()
	_tile_top_polys.clear()
	var overrides := {}
	for override in map_data.tile_overrides:
		var pos := Vector2i(override.get("x", 0), override.get("y", 0))
		overrides[pos] = override
	for y in range(map_data.map_height):
		for x in range(map_data.map_width):
			var pos := Vector2i(x, y)
			var data: Dictionary = overrides.get(pos, {})
			var terrain: String = data.get("terrain", map_data.default_terrain)
			var height: int = data.get("height", 0)
			tiles[pos] = {
				"terrain": terrain,
				"height": height,
				"move_cost": _move_cost_for(terrain),
				"blocks_movement": terrain in ["wall", "deep_water"],
				"blocks_line_of_sight": terrain == "wall",
			}


func _draw_base_tiles() -> void:
	for child in get_children():
		if child != highlight_layer and child != unit_layer:
			child.queue_free()

	var draw_positions: Array = tiles.keys()
	draw_positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x + a.y == b.x + b.y:
			return a.y < b.y
		return a.x + a.y < b.x + b.y)

	for pos: Vector2i in draw_positions:
		var data: Dictionary = tiles[pos]
		var world := _grid_to_local(pos)
		var base_color := _terrain_color(data.terrain, data.height)
		_add_iso_tile(pos, world, base_color)
		if data.height > 0:
			var lbl := Label.new()
			lbl.text = "h%d" % data.height
			lbl.add_theme_font_size_override("font_size", 9)
			lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
			lbl.position = world + Vector2(-10, -tile_size.y * 0.48)
			lbl.z_index = _depth_for(pos) + 4
			add_child(lbl)


func _add_iso_tile(pos: Vector2i, world: Vector2, base_color: Color) -> void:
	var half_w := tile_size.x * 0.5
	var half_h := tile_size.y * 0.5
	var depth := _depth_for(pos)

	var left_face := Polygon2D.new()
	left_face.polygon = PackedVector2Array([
		Vector2(-half_w, 0),
		Vector2(0, half_h),
		Vector2(0, half_h + tile_thickness),
		Vector2(-half_w, tile_thickness),
	])
	left_face.position = world
	left_face.color = base_color.darkened(0.35)
	left_face.z_index = depth
	add_child(left_face)

	var right_face := Polygon2D.new()
	right_face.polygon = PackedVector2Array([
		Vector2(half_w, 0),
		Vector2(0, half_h),
		Vector2(0, half_h + tile_thickness),
		Vector2(half_w, tile_thickness),
	])
	right_face.position = world
	right_face.color = base_color.darkened(0.22)
	right_face.z_index = depth + 1
	add_child(right_face)

	var top := Polygon2D.new()
	top.polygon = _diamond_polygon()
	top.position = world
	top.color = base_color
	top.z_index = depth + 2
	add_child(top)
	_tile_top_polys[pos] = top

	var rim := Line2D.new()
	rim.points = PackedVector2Array([
		Vector2(0, -half_h),
		Vector2(half_w, 0),
		Vector2(0, half_h),
		Vector2(-half_w, 0),
		Vector2(0, -half_h),
	])
	rim.width = 1.0
	rim.default_color = base_color.lightened(0.18)
	rim.position = world
	rim.z_index = depth + 3
	add_child(rim)


func _terrain_color(terrain: String, height: int) -> Color:
	var base: Color
	match terrain:
		"grass":         base = Color(0.14, 0.42, 0.17)
		"road":          base = Color(0.48, 0.37, 0.22)
		"stone":         base = Color(0.36, 0.40, 0.44)
		"shrine":        base = Color(0.50, 0.38, 0.16)
		"shallow_water": base = Color(0.12, 0.46, 0.65)
		"deep_water":    base = Color(0.07, 0.20, 0.42)
		"ice":           base = Color(0.65, 0.84, 0.92)
		"burning":       base = Color(0.70, 0.16, 0.07)
		"wall":          base = Color(0.09, 0.11, 0.14)
		"high_ground":   base = Color(0.26, 0.30, 0.34)
		_:               base = Color(0.14, 0.34, 0.17)
	return base.lightened(height * 0.07)


func _move_cost_for(terrain: String) -> int:
	match terrain:
		"shallow_water", "high_ground": return 2
		"deep_water", "wall": return 99
		_: return 1


func show_move_range(positions: Array[Vector2i]) -> void:
	move_tiles = positions
	_refresh_highlights()


func show_attack_range(positions: Array[Vector2i]) -> void:
	attack_tiles = positions
	_refresh_highlights()


func show_ability_range(positions: Array[Vector2i]) -> void:
	ability_tiles = positions
	_refresh_highlights()


func show_aoe_preview(positions: Array[Vector2i]) -> void:
	aoe_preview_tiles = positions
	_refresh_highlights()


func clear_aoe_preview() -> void:
	if aoe_preview_tiles.is_empty():
		return
	aoe_preview_tiles.clear()
	_refresh_highlights()


func clear_highlights() -> void:
	move_tiles.clear()
	attack_tiles.clear()
	ability_tiles.clear()
	aoe_preview_tiles.clear()
	selected_tile = Vector2i(-1, -1)
	_refresh_highlights()


func _refresh_highlights() -> void:
	for child in highlight_layer.get_children():
		child.queue_free()
	for pos in move_tiles:
		_add_highlight(pos, Color(0.0, 0.9, 1.0, 0.38))
	for pos in attack_tiles:
		_add_highlight(pos, Color(1.0, 0.45, 0.0, 0.38))
	for pos in ability_tiles:
		_add_highlight(pos, Color(0.6, 0.1, 1.0, 0.38))
	# AoE burst preview — hot red, drawn over ability range tiles
	for pos in aoe_preview_tiles:
		_add_highlight(pos, Color(1.0, 0.18, 0.08, 0.65))
	if _is_valid_pos(selected_tile):
		_add_highlight(selected_tile, Color(1.0, 0.95, 0.0, 0.45))


func _add_highlight(pos: Vector2i, color: Color) -> void:
	var diamond := Polygon2D.new()
	diamond.color = color
	diamond.polygon = _diamond_polygon(0.86)
	diamond.position = _grid_to_local(pos)
	diamond.z_index = _depth_for(pos) + 50
	highlight_layer.add_child(diamond)


## World position where a unit's feet should sit on the tile.
## Offset toward the south vertex so the sprite looks planted on the top face.
func _unit_foot_pos(grid_pos: Vector2i) -> Vector2:
	return _grid_to_local(grid_pos) + Vector2(0.0, float(tile_size.y) * 0.28)


func place_unit(unit_node: Node2D, grid_pos: Vector2i) -> void:
	unit_layer.add_child(unit_node)
	unit_node.position = _unit_foot_pos(grid_pos)
	unit_node.z_index = _unit_depth_for(grid_pos)
	unit_positions[grid_pos] = unit_node.unit_id


func move_unit_visual(unit_id: String, from: Vector2i, to: Vector2i) -> void:
	for child in unit_layer.get_children():
		if child.get("unit_id") == unit_id:
			var tween := create_tween()
			tween.tween_property(child, "position", _unit_foot_pos(to), 0.22)
			child.z_index = _unit_depth_for(to)
			break
	unit_positions.erase(from)
	unit_positions[to] = unit_id


## Converts a flammable tile (grass, road) to burning terrain.
## Updates both the logical tile data and the visual top colour.
func ignite_tile(pos: Vector2i) -> void:
	if not tiles.has(pos):
		return
	var tile: Dictionary = tiles[pos]
	if tile.get("terrain", "") not in ["grass", "road"]:
		return
	tile["terrain"] = "burning"
	tile["move_cost"] = 1
	if _tile_top_polys.has(pos):
		var top: Polygon2D = _tile_top_polys[pos]
		top.color = Color(0.70, 0.16, 0.07)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hov := _local_to_grid(get_local_mouse_position())
		if _is_valid_pos(hov) and hov != selected_tile:
			selected_tile = hov
			_refresh_highlights()
			tile_hovered.emit(hov)
		elif not _is_valid_pos(hov) and _is_valid_pos(selected_tile):
			selected_tile = Vector2i(-1, -1)
			_refresh_highlights()
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var grid_pos := _local_to_grid(get_local_mouse_position())
	if not _is_valid_pos(grid_pos):
		return
	if unit_positions.has(grid_pos):
		unit_clicked.emit(unit_positions[grid_pos])
	else:
		tile_clicked.emit(grid_pos)


func _grid_to_local(pos: Vector2i) -> Vector2:
	var height := 0
	if tiles.has(pos):
		height = int(tiles[pos].get("height", 0))
	return map_origin + Vector2(
		(pos.x - pos.y) * tile_size.x * 0.5,
		(pos.x + pos.y) * tile_size.y * 0.5 - float(height) * height_step
	)


func _local_to_grid(local_pos: Vector2) -> Vector2i:
	var best_pos := Vector2i(-1, -1)
	var best_dist := INF
	for pos: Vector2i in tiles.keys():
		var center := _grid_to_local(pos)
		var delta := local_pos - center
		var normalized: float = abs(delta.x) / (tile_size.x * 0.5) + abs(delta.y) / (tile_size.y * 0.5)
		if normalized <= 1.08:
			var dist := delta.length_squared()
			if dist < best_dist:
				best_dist = dist
				best_pos = pos
	return best_pos


func _diamond_polygon(scale: float = 1.0) -> PackedVector2Array:
	var half_w := tile_size.x * 0.5 * scale
	var half_h := tile_size.y * 0.5 * scale
	return PackedVector2Array([
		Vector2(0, -half_h),
		Vector2(half_w, 0),
		Vector2(0, half_h),
		Vector2(-half_w, 0),
	])


func _depth_for(pos: Vector2i) -> int:
	var height := 0
	if tiles.has(pos):
		height = int(tiles[pos].get("height", 0))
	return (pos.x + pos.y) * 10 + height * 2


func _unit_depth_for(pos: Vector2i) -> int:
	return _depth_for(pos) + 100


func _is_valid_pos(pos: Vector2i) -> bool:
	if not map_data:
		return false
	return pos.x >= 0 and pos.y >= 0 and pos.x < map_data.map_width and pos.y < map_data.map_height


func get_tile(pos: Vector2i) -> Dictionary:
	return tiles.get(pos, {})
