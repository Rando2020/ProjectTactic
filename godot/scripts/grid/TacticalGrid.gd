class_name TacticalGrid
extends Node2D

signal tile_clicked(grid_pos: Vector2i)
signal unit_clicked(unit_id: String)

@export var tile_size: Vector2i = Vector2i(64, 64)
@export var map_data: MapData

var tiles: Dictionary = {}          # Vector2i -> Dictionary
var unit_positions: Dictionary = {} # Vector2i -> unit_id String

var move_tiles: Array[Vector2i] = []
var attack_tiles: Array[Vector2i] = []
var ability_tiles: Array[Vector2i] = []
var selected_tile: Vector2i = Vector2i(-1, -1)

@onready var highlight_layer: Node2D = $HighlightLayer
@onready var unit_layer: Node2D = $UnitLayer


func _ready() -> void:
	if map_data:
		_build_tiles()
		_draw_base_tiles()


func initialize_from_map(p_map_data: MapData) -> void:
	map_data = p_map_data
	_build_tiles()
	_draw_base_tiles()


func _build_tiles() -> void:
	tiles.clear()
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
	for pos in tiles.keys():
		var data: Dictionary = tiles[pos]
		var world := _grid_to_local(pos)
		var base_color := _terrain_color(data.terrain, data.height)
		# Outer (dark border) rect fills the full tile
		var border := ColorRect.new()
		border.size = Vector2(tile_size.x, tile_size.y)
		border.position = world - Vector2(tile_size.x * 0.5, tile_size.y * 0.5)
		border.color = base_color.darkened(0.35)
		border.z_index = 0
		add_child(border)
		# Inner fill rect — 2 px inset on all sides
		var rect := ColorRect.new()
		rect.size = Vector2(tile_size.x - 4, tile_size.y - 4)
		rect.position = world - Vector2(tile_size.x * 0.5 - 2, tile_size.y * 0.5 - 2)
		rect.color = base_color
		rect.z_index = 0
		add_child(rect)
		# Subtle top-left highlight to give a slight bevel feel
		var hi := ColorRect.new()
		hi.size = Vector2(tile_size.x - 4, 2)
		hi.position = rect.position
		hi.color = base_color.lightened(0.15)
		hi.z_index = 0
		add_child(hi)
		# Height label
		if data.height > 0:
			var lbl := Label.new()
			lbl.text = "h%d" % data.height
			lbl.add_theme_font_size_override("font_size", 9)
			lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
			lbl.position = rect.position + Vector2(2, 2)
			lbl.z_index = 1
			add_child(lbl)


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


# ── Highlight API ─────────────────────────────────────────────────────────────

func show_move_range(positions: Array[Vector2i]) -> void:
	move_tiles = positions
	_refresh_highlights()


func show_attack_range(positions: Array[Vector2i]) -> void:
	attack_tiles = positions
	_refresh_highlights()


func show_ability_range(positions: Array[Vector2i]) -> void:
	ability_tiles = positions
	_refresh_highlights()


func clear_highlights() -> void:
	move_tiles.clear()
	attack_tiles.clear()
	ability_tiles.clear()
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
	if _is_valid_pos(selected_tile):
		_add_highlight(selected_tile, Color(1.0, 0.95, 0.0, 0.45))


func _add_highlight(pos: Vector2i, color: Color) -> void:
	var rect := ColorRect.new()
	rect.color = color
	rect.size = Vector2(tile_size.x - 4, tile_size.y - 4)
	rect.position = _grid_to_local(pos) - Vector2(tile_size.x * 0.5 - 2, tile_size.y * 0.5 - 2)
	highlight_layer.add_child(rect)


# ── Unit management ───────────────────────────────────────────────────────────

func place_unit(unit_node: Node2D, grid_pos: Vector2i) -> void:
	unit_layer.add_child(unit_node)
	unit_node.position = _grid_to_local(grid_pos)
	unit_positions[grid_pos] = unit_node.unit_id


func move_unit_visual(unit_id: String, from: Vector2i, to: Vector2i) -> void:
	for child in unit_layer.get_children():
		if child.get("unit_id") == unit_id:
			var tween := create_tween()
			tween.tween_property(child, "position", _grid_to_local(to), 0.22)
			break
	unit_positions.erase(from)
	unit_positions[to] = unit_id


# ── Input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var local_mouse := get_local_mouse_position()
	var grid_pos := Vector2i(
		int(local_mouse.x / tile_size.x),
		int(local_mouse.y / tile_size.y)
	)
	if not _is_valid_pos(grid_pos):
		return
	if unit_positions.has(grid_pos):
		unit_clicked.emit(unit_positions[grid_pos])
	else:
		tile_clicked.emit(grid_pos)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _grid_to_local(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * tile_size.x + tile_size.x * 0.5,
				   pos.y * tile_size.y + tile_size.y * 0.5)


func _is_valid_pos(pos: Vector2i) -> bool:
	if not map_data:
		return false
	return pos.x >= 0 and pos.y >= 0 and pos.x < map_data.map_width and pos.y < map_data.map_height


func get_tile(pos: Vector2i) -> Dictionary:
	return tiles.get(pos, {})
