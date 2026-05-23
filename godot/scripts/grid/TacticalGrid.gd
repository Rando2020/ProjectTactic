class_name TacticalGrid
extends Node2D

signal tile_clicked(grid_pos: Vector2i)
signal unit_clicked(unit_id: String)
signal tile_hovered(grid_pos: Vector2i)
signal unit_visual_position_changed(unit_id: String, world_pos: Vector2)

@export var tile_size: Vector2i = Vector2i(96, 48)
@export var height_step: float = 14.0
@export var tile_thickness: float = 16.0
@export var map_origin: Vector2 = Vector2(320, 64)
@export var map_data: MapData

var tiles: Dictionary = {}           # Vector2i -> Dictionary
var unit_positions: Dictionary = {}  # Vector2i -> unit_id String
var _tile_top_polys: Dictionary = {} # Vector2i -> Polygon2D, for mutation/art swap

const TERRAIN_TEXTURE_PATHS := {
	"grass": "res://assets/tiles/grass.png",
	"grass_flowers": "res://assets/tiles/grass_flowers.png",
	"brush": "res://assets/tiles/brush.png",
	"road": "res://assets/tiles/road.png",
	"stone": "res://assets/tiles/stone.png",
	"cracked_stone": "res://assets/tiles/cracked_stone.png",
	"high_ground": "res://assets/tiles/cliff_grass.png",
	"shallow_water": "res://assets/tiles/shallow_water.png",
	"ice": "res://assets/tiles/frozen_water.png",
	"frozen_water": "res://assets/tiles/frozen_water.png",
	"burning": "res://assets/tiles/burning_grass.png",
	"scorched": "res://assets/tiles/scorched_dirt.png",
	"shrine": "res://assets/tiles/holy_shrine.png",
}

const PROP_TEXTURE_PATHS := {
	"mossy_rock": "res://assets/props/mossy_rock.png",
	"leafy_bush": "res://assets/props/leafy_bush.png",
	"tree_stump": "res://assets/props/tree_stump.png",
	"ruin_block": "res://assets/props/ruin_block.png",
}

var _terrain_texture_cache: Dictionary = {}
var _prop_texture_cache: Dictionary = {}
var move_tiles: Array[Vector2i] = []
var attack_tiles: Array[Vector2i] = []
var ability_tiles: Array[Vector2i] = []
var aoe_preview_tiles: Array[Vector2i] = []
var path_preview_tiles: Array[Vector2i] = []
var selected_tile: Vector2i = Vector2i(-1, -1)
var target_tile: Vector2i = Vector2i(-1, -1)
var active_unit_tile: Vector2i = Vector2i(-1, -1)
var active_unit_team: String = ""

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


func redraw_base_tiles() -> void:
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
	_draw_props()


func _add_iso_tile(pos: Vector2i, world: Vector2, base_color: Color) -> void:
	var terrain: String = tiles[pos].get("terrain", "")
	if _uses_art_tile(terrain):
		var texture := _texture_for_terrain(terrain)
		if texture:
			_add_exposed_faces(pos, world, base_color)
			_add_art_tile_top(pos, world, texture)
			return

	_add_exposed_faces(pos, world, base_color)
	_add_procedural_top(pos, world, base_color)


func _add_exposed_faces(pos: Vector2i, world: Vector2, base_color: Color) -> void:
	var half_w := tile_size.x * 0.5
	var half_h := tile_size.y * 0.5
	var depth := _depth_for(pos)
	var height := _height_at(pos)
	var south := Vector2i(pos.x, pos.y + 1)
	var east := Vector2i(pos.x + 1, pos.y)
	var south_height := _height_at(south)
	var east_height := _height_at(east)

	if not tiles.has(south) or south_height < height:
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

	if not tiles.has(east) or east_height < height:
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


func _add_procedural_top(pos: Vector2i, world: Vector2, base_color: Color) -> void:
	var depth := _depth_for(pos)
	var top := Polygon2D.new()
	top.polygon = _diamond_polygon()
	top.position = world
	top.color = base_color
	top.z_index = depth + 2
	add_child(top)
	_tile_top_polys[pos] = top

	_add_connected_surface_detail(pos, world, base_color, depth)


func _add_art_tile_top(pos: Vector2i, world: Vector2, texture: Texture2D) -> void:
	var depth := _depth_for(pos)
	var top := Polygon2D.new()
	top.polygon = _diamond_polygon()
	top.texture = texture
	top.texture_offset = Vector2(-tile_size.x * 0.5, -tile_size.y * 0.5)
	top.color = Color.WHITE
	top.position = world
	top.z_index = depth + 2
	add_child(top)
	_tile_top_polys[pos] = top

	_add_soft_terrain_tint(pos, world, _terrain_color(tiles[pos].terrain, _height_at(pos)), depth)


func _uses_art_tile(terrain: String) -> bool:
	return TERRAIN_TEXTURE_PATHS.has(terrain)


func _texture_for_terrain(terrain: String) -> Texture2D:
	return _texture_from_path(TERRAIN_TEXTURE_PATHS.get(terrain, ""), _terrain_texture_cache)


func _texture_for_prop(prop_name: String) -> Texture2D:
	return _texture_from_path(PROP_TEXTURE_PATHS.get(prop_name, ""), _prop_texture_cache)


func _texture_from_path(path: String, cache: Dictionary) -> Texture2D:
	if path.is_empty():
		return null
	if cache.has(path):
		return cache[path]
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		cache[path] = null
		return null
	var bytes := file.get_buffer(file.get_length())
	if bytes.size() >= 7 and bytes.slice(0, 7).get_string_from_ascii() == "version":
		cache[path] = null
		return null
	var image := Image.new()
	var err := image.load_png_from_buffer(bytes)
	if err != OK:
		cache[path] = null
		return null
	var texture := ImageTexture.create_from_image(image)
	cache[path] = texture
	return texture

## Draw a glowing marker on void_anchor and high-value tiles
func _add_tile_marker(pos: Vector2i, world: Vector2, terrain: String) -> void:
	if terrain != "void_anchor": return
	var depth := _depth_for(pos)
	# Pulsing inner diamond
	var glow := Polygon2D.new()
	var half_w := tile_size.x * 0.28
	var half_h := tile_size.y * 0.28
	glow.polygon = PackedVector2Array([
		Vector2(0, -half_h), Vector2(half_w, 0),
		Vector2(0, half_h),  Vector2(-half_w, 0),
	])
	glow.position = world
	glow.color = Color(0.75, 0.20, 1.0, 0.60)
	glow.z_index = depth + 10
	add_child(glow)
	# Label
	var lbl := Label.new()
	lbl.text = "ANCHOR"
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0, 0.9))
	lbl.position = world + Vector2(-20, -tile_size.y * 0.35)
	lbl.z_index = depth + 11
	add_child(lbl)


func _add_connected_surface_detail(pos: Vector2i, world: Vector2, base_color: Color, depth: int) -> void:
	var terrain: String = tiles[pos].get("terrain", "")
	match terrain:
		"road":
			_add_surface_lines(pos, world, base_color.darkened(0.18), depth, 4, 0.28, 0.18)
		"stone", "high_ground":
			_add_stone_cracks(pos, world, base_color, depth)
		"shallow_water":
			_add_surface_lines(pos, world, base_color.lightened(0.28), depth, 3, 0.34, 0.22)
		"grass_flowers":
			_add_surface_lines(pos, world, base_color.lightened(0.18), depth, 2, 0.20, 0.12)
			_add_flower_specks(pos, world, depth)
		"brush":
			_add_surface_lines(pos, world, base_color.lightened(0.10), depth, 5, 0.25, 0.18)
		_:
			_add_surface_lines(pos, world, base_color.lightened(0.16), depth, 3, 0.22, 0.14)


func _add_surface_lines(pos: Vector2i, world: Vector2, color: Color, depth: int,
		count: int, max_span_ratio: float, alpha: float) -> void:
	for i in range(count):
		var detail := Line2D.new()
		var tile_noise := _tile_seed(pos, i)
		var y := lerpf(-tile_size.y * 0.24, tile_size.y * 0.20, tile_noise)
		var span := tile_size.x * lerpf(max_span_ratio * 0.45, max_span_ratio, _tile_seed(pos, i + 11))
		detail.points = PackedVector2Array([
			Vector2(-span, y),
			Vector2(span, y + lerpf(-2.0, 3.0, _tile_seed(pos, i + 23))),
		])
		detail.width = 1.0
		detail.default_color = color
		detail.modulate.a = alpha
		detail.position = world
		detail.z_index = depth + 3
		add_child(detail)


func _add_stone_cracks(pos: Vector2i, world: Vector2, base_color: Color, depth: int) -> void:
	for i in range(2):
		var tile_noise := _tile_seed(pos, i + 31)
		var crack := Line2D.new()
		var x := lerpf(-tile_size.x * 0.20, tile_size.x * 0.20, tile_noise)
		var y := lerpf(-tile_size.y * 0.18, tile_size.y * 0.16, _tile_seed(pos, i + 39))
		crack.points = PackedVector2Array([
			Vector2(x - 8.0, y),
			Vector2(x + 1.0, y + 3.0),
			Vector2(x + 10.0, y - 1.0),
		])
		crack.width = 1.0
		crack.default_color = base_color.darkened(0.30)
		crack.modulate.a = 0.22
		crack.position = world
		crack.z_index = depth + 3
		add_child(crack)


func _add_flower_specks(pos: Vector2i, world: Vector2, depth: int) -> void:
	for i in range(2):
		var speck := ColorRect.new()
		speck.size = Vector2(2.0, 2.0)
		speck.color = Color(0.95, 0.88, 0.62, 0.55)
		speck.position = world + Vector2(
			lerpf(-tile_size.x * 0.20, tile_size.x * 0.20, _tile_seed(pos, i + 47)),
			lerpf(-tile_size.y * 0.18, tile_size.y * 0.18, _tile_seed(pos, i + 53))
		)
		speck.z_index = depth + 4
		add_child(speck)


func _tile_seed(pos: Vector2i, salt: int) -> float:
	return float(abs((pos.x * 374761 + pos.y * 668265 + salt * 144269) % 1000)) / 1000.0


func _add_soft_terrain_tint(_pos: Vector2i, world: Vector2, base_color: Color, depth: int) -> void:
	var tint := Polygon2D.new()
	tint.polygon = _diamond_polygon(0.96)
	tint.position = world
	tint.color = base_color
	tint.modulate.a = 0.18
	tint.z_index = depth + 3
	add_child(tint)


func _add_subtle_rim(_pos: Vector2i, world: Vector2, base_color: Color, depth: int) -> void:
	var half_w := tile_size.x * 0.5
	var half_h := tile_size.y * 0.5
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


func _draw_props() -> void:
	if not map_data:
		return
	for prop_data: Dictionary in map_data.prop_overrides:
		var prop_name: String = prop_data.get("prop", "")
		if not PROP_TEXTURE_PATHS.has(prop_name):
			continue
		var texture := _texture_for_prop(prop_name)
		if not texture:
			continue
		var pos := Vector2i(prop_data.get("x", 0), prop_data.get("y", 0))
		if not _is_valid_pos(pos):
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = true
		sprite.position = _grid_to_local(pos) + Vector2(
			float(prop_data.get("offset_x", 0.0)),
			float(prop_data.get("offset_y", -2.0))
		)
		sprite.z_index = _depth_for(pos) + 80
		add_child(sprite)


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
		"scorched":      base = Color(0.14, 0.11, 0.09)
		"cracked_stone": base = Color(0.28, 0.30, 0.32)
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


func show_path_preview(positions: Array[Vector2i]) -> void:
	path_preview_tiles = positions
	_refresh_highlights()


func show_target_lock(pos: Vector2i) -> void:
	target_tile = pos
	_refresh_highlights()


func clear_target_lock() -> void:
	if target_tile == Vector2i(-1, -1):
		return
	target_tile = Vector2i(-1, -1)
	_refresh_highlights()


func clear_path_preview() -> void:
	if path_preview_tiles.is_empty():
		return
	path_preview_tiles.clear()
	_refresh_highlights()


func clear_aoe_preview() -> void:
	if aoe_preview_tiles.is_empty():
		return
	aoe_preview_tiles.clear()
	_refresh_highlights()


func show_active_unit(grid_pos: Vector2i, team: String) -> void:
	active_unit_tile = grid_pos
	active_unit_team = team
	_refresh_highlights()


func clear_highlights() -> void:
	move_tiles.clear()
	attack_tiles.clear()
	ability_tiles.clear()
	aoe_preview_tiles.clear()
	path_preview_tiles.clear()
	selected_tile = Vector2i(-1, -1)
	target_tile = Vector2i(-1, -1)
	_refresh_highlights()


func _refresh_highlights() -> void:
	for child in highlight_layer.get_children():
		child.queue_free()
	for pos in move_tiles:
		_add_highlight(pos, Color(0.0, 0.85, 1.0, 0.48), 0.90)
	for i in path_preview_tiles.size():
		var pos: Vector2i = path_preview_tiles[i]
		var alpha: float = 0.38 + min(float(i) * 0.035, 0.26)
		_add_highlight(pos, Color(0.15, 1.0, 0.95, alpha), 0.62)
		_add_path_step_badge(pos, i + 1)
	for pos in attack_tiles:
		_add_highlight(pos, Color(1.0, 0.35, 0.0, 0.50), 0.90)
	for pos in ability_tiles:
		_add_highlight(pos, Color(0.65, 0.18, 1.0, 0.48), 0.90)
	# AoE burst preview — hot red, drawn over ability range tiles
	for pos in aoe_preview_tiles:
		_add_highlight(pos, Color(1.0, 0.18, 0.08, 0.70), 0.98)
	if _is_valid_pos(active_unit_tile):
		var active_color := Color(0.25, 0.72, 1.0, 0.58) if active_unit_team == "player" else Color(1.0, 0.22, 0.18, 0.58)
		_add_highlight(active_unit_tile, active_color, 1.04)
	if _is_valid_pos(selected_tile):
		_add_selected_tile_guidance()
	if _is_valid_pos(target_tile):
		_add_target_lock(target_tile)


func _add_highlight(pos: Vector2i, color: Color, highlight_scale: float = 0.86) -> void:
	var diamond := Polygon2D.new()
	diamond.color = color
	diamond.polygon = _diamond_polygon(highlight_scale)
	diamond.position = _grid_to_local(pos)
	diamond.z_index = _depth_for(pos) + 50
	highlight_layer.add_child(diamond)

	var rim := Line2D.new()
	var poly := _diamond_polygon(highlight_scale)
	rim.points = PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]])
	rim.width = 2.0
	rim.default_color = Color(color.r, color.g, color.b, min(color.a + 0.28, 1.0))
	rim.position = _grid_to_local(pos)
	rim.z_index = _depth_for(pos) + 51
	highlight_layer.add_child(rim)


func _add_selected_tile_guidance() -> void:
	var label := ""
	var color := Color(1.0, 0.95, 0.0, 0.66)
	if selected_tile in move_tiles:
		label = "GO"
		color = Color(0.1, 1.0, 1.0, 0.82)
	elif selected_tile in attack_tiles:
		label = "HIT"
		color = Color(1.0, 0.28, 0.04, 0.82)
	elif selected_tile in ability_tiles:
		label = "CAST"
		color = Color(0.75, 0.30, 1.0, 0.82)
	_add_highlight(selected_tile, color, 1.08)
	if label != "":
		_add_tile_badge(selected_tile, label, color)


func _add_target_lock(pos: Vector2i) -> void:
	var color := Color(1.0, 0.88, 0.18, 0.86)
	_add_highlight(pos, Color(1.0, 0.86, 0.10, 0.28), 1.18)

	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(-9.0, -16.0),
		Vector2(-3.0, -16.0),
		Vector2(-3.0, -28.0),
		Vector2(3.0, -28.0),
		Vector2(3.0, -16.0),
		Vector2(9.0, -16.0),
	])
	arrow.position = _grid_to_local(pos) + Vector2(0.0, -tile_size.y * 0.34)
	arrow.color = color
	arrow.z_index = _depth_for(pos) + 70
	highlight_layer.add_child(arrow)

	_add_tile_badge(pos, "TARGET", color)


func _add_tile_badge(pos: Vector2i, text: String, color: Color) -> void:
	var badge := Label.new()
	badge.text = text
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	badge.add_theme_constant_override("outline_size", 4)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.size = Vector2(58.0, 18.0)
	badge.position = _grid_to_local(pos) + Vector2(-29.0, -12.0)
	badge.modulate = Color(1.0, 1.0, 1.0, min(color.a + 0.18, 1.0))
	badge.z_index = _depth_for(pos) + 60
	highlight_layer.add_child(badge)


func _add_path_step_badge(pos: Vector2i, step: int) -> void:
	var badge := Label.new()
	badge.text = str(step)
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color(0.0, 0.08, 0.08))
	badge.add_theme_color_override("font_outline_color", Color(0.55, 1.0, 0.95))
	badge.add_theme_constant_override("outline_size", 3)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.size = Vector2(24.0, 18.0)
	badge.position = _grid_to_local(pos) + Vector2(-12.0, -9.0)
	badge.z_index = _depth_for(pos) + 62
	highlight_layer.add_child(badge)


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
			var start_pos: Vector2 = child.position
			var end_pos: Vector2 = _unit_foot_pos(to)
			var tween := create_tween()
			tween.tween_method(
				func(pos: Vector2) -> void:
					child.position = pos
					unit_visual_position_changed.emit(unit_id, child.global_position),
				start_pos,
				end_pos,
				0.50
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			child.z_index = _unit_depth_for(to)
			await tween.finished
			break
	unit_positions.erase(from)
	unit_positions[to] = unit_id
	if active_unit_tile == from:
		show_active_unit(to, active_unit_team)


func remove_unit_visual(unit_id: String, grid_pos: Vector2i) -> void:
	if unit_positions.get(grid_pos, "") == unit_id:
		unit_positions.erase(grid_pos)
	for pos in unit_positions.keys():
		if unit_positions[pos] == unit_id:
			unit_positions.erase(pos)
	if active_unit_tile == grid_pos:
		active_unit_tile = Vector2i(-1, -1)
		active_unit_team = ""
	_refresh_highlights()


func get_unit_focus_position(grid_pos: Vector2i) -> Vector2:
	return _unit_foot_pos(grid_pos)


func get_board_bounds() -> Rect2:
	var first := true
	var min_pt := Vector2.ZERO
	var max_pt := Vector2.ZERO
	for pos: Vector2i in tiles.keys():
		var center := _grid_to_local(pos)
		var half_w := tile_size.x * 0.5
		var half_h := tile_size.y * 0.5
		var points := [
			center + Vector2(0, -half_h),
			center + Vector2(half_w, tile_thickness),
			center + Vector2(0, half_h + tile_thickness),
			center + Vector2(-half_w, tile_thickness),
		]
		for point: Vector2 in points:
			if first:
				min_pt = point
				max_pt = point
				first = false
			else:
				min_pt.x = min(min_pt.x, point.x)
				min_pt.y = min(min_pt.y, point.y)
				max_pt.x = max(max_pt.x, point.x)
				max_pt.y = max(max_pt.y, point.y)
	if first:
		return Rect2(map_origin, Vector2.ONE)
	return Rect2(min_pt, max_pt - min_pt)


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
	_draw_base_tiles()


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


func _diamond_polygon(polygon_scale: float = 1.0) -> PackedVector2Array:
	var half_w := tile_size.x * 0.5 * polygon_scale
	var half_h := tile_size.y * 0.5 * polygon_scale
	return PackedVector2Array([
		Vector2(0, -half_h),
		Vector2(half_w, 0),
		Vector2(0, half_h),
		Vector2(-half_w, 0),
	])


func _depth_for(pos: Vector2i) -> int:
	var height := _height_at(pos)
	return (pos.x + pos.y) * 10 + height * 2


func _height_at(pos: Vector2i) -> int:
	if not tiles.has(pos):
		return -1
	return int(tiles[pos].get("height", 0))


func _unit_depth_for(pos: Vector2i) -> int:
	return _depth_for(pos) + 100


func _is_valid_pos(pos: Vector2i) -> bool:
	if not map_data:
		return false
	return pos.x >= 0 and pos.y >= 0 and pos.x < map_data.map_width and pos.y < map_data.map_height


func get_tile(pos: Vector2i) -> Dictionary:
	return tiles.get(pos, {})
