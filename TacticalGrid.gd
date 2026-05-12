## TacticalGrid.gd
## Node2D that renders the battle map and handles tile selection.
## Owns tile visual state (highlighted, selected, targetable).
## Does NOT own units or game logic — emits signals upward to BattleManager.
##
## AI AGENT: Implement all TODO sections.
## Signals are the contract with BattleManager — do not change their signatures.

class_name TacticalGrid
extends Node2D

signal tile_clicked(grid_pos: Vector2i)
signal unit_clicked(unit_id: String)

@export var tile_size: Vector2i = Vector2i(64, 64)
@export var map_data: MapData

## Runtime tile state — built from map_data on _ready
var tiles: Dictionary = {}        # Vector2i -> TileRuntimeData
var unit_positions: Dictionary = {} # Vector2i -> unit_id String

## Visual highlight sets
var move_tiles: Array[Vector2i] = []
var attack_tiles: Array[Vector2i] = []
var ability_tiles: Array[Vector2i] = []
var selected_tile: Vector2i = Vector2i(-1, -1)

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var highlight_layer: Node2D = $HighlightLayer
@onready var unit_layer: Node2D = $UnitLayer


func _ready() -> void:
	# Build the runtime tiles dictionary from map_data. Each entry stores
	# terrain ID, height, move_cost, and LoS blocking flags. In a complete
	# implementation these values would be pulled from TileData resources.
	tiles.clear()
	# Create a lookup for tile overrides by position
	var overrides := {}
	for override in map_data.tile_overrides:
		var pos := Vector2i(override.get("x", 0), override.get("y", 0))
		overrides[pos] = override
	# Iterate across the map dimensions
	for y in range(map_data.map_height):
		for x in range(map_data.map_width):
			var pos := Vector2i(x, y)
			var data := overrides.get(pos, {})
			var terrain_id := data.get("terrain", map_data.default_terrain)
			var height := data.get("height", 0)
			# Construct a simple runtime dictionary. Real values should be
			# derived from TileData resources (move_cost, blocks_movement, etc.).
			var runtime := {
				"terrain": terrain_id,
				"height": height,
				"move_cost": 1,
				"blocks_movement": false,
				"blocks_line_of_sight": false
			}
			tiles[pos] = runtime
    # Optionally render the base tilemap here. Without a TileSet this is a
    # no-op in the scaffold. When assets are available, iterate tiles and call
    # tile_map.set_cell() with the appropriate atlas indices.
    # tile_map.clear()
    # for pos in tiles.keys():
    #     var cell_id = 0  # look up atlas index based on terrain
    #     tile_map.set_cell(0, pos, cell_id)
    #
    # Once the runtime tile dictionary is built, there is nothing more to do
    # here in the scaffold. Removing the trailing `pass` prevents an
    # unreachable-statement warning.
    return


## Called by BattleManager when a unit is selected
func show_move_range(positions: Array[Vector2i]) -> void:
	move_tiles = positions
	_refresh_highlights()


## Called by BattleManager when attack command is active
func show_attack_range(positions: Array[Vector2i]) -> void:
	attack_tiles = positions
	_refresh_highlights()


## Clears all highlight overlays
func clear_highlights() -> void:
	move_tiles.clear()
	attack_tiles.clear()
	ability_tiles.clear()
	selected_tile = Vector2i(-1, -1)
	_refresh_highlights()


## Updates unit_positions registry and moves unit sprite to new grid position
func move_unit_visual(unit_id: String, from: Vector2i, to: Vector2i) -> void:
	# Animate the visual representation of a unit moving on the grid. Find
	# the unit node by its unit_id, then tween its position from the old
	# world coordinate to the new one. Update the unit_positions dictionary
	# after initiating the animation.
	var unit_node: Node2D = null
	for child in unit_layer.get_children():
		if child.has_method("unit_id"):
			# If the child exposes unit_id as a property
			if child.unit_id == unit_id:
				unit_node = child
				break
	if unit_node:
		var start_pos := GridSystem.grid_to_world(from, tile_size)
		var end_pos := GridSystem.grid_to_world(to, tile_size)
		# Immediately set position if start mismatch
		unit_node.position = start_pos
		var tween := create_tween()
		tween.tween_property(unit_node, "position", end_pos, 0.25)
	# Update unit_positions registry
	unit_positions.erase(from)
	unit_positions[to] = unit_id


## Places a unit node at a grid position (called during deployment and battle start)
func place_unit(unit_node: Node2D, grid_pos: Vector2i) -> void:
	unit_layer.add_child(unit_node)
	unit_node.position = GridSystem.grid_to_world(grid_pos, tile_size)
	unit_positions[grid_pos] = unit_node.unit_id


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var grid_pos := GridSystem.world_to_grid(get_local_mouse_position(), tile_size)
		if not _is_valid_pos(grid_pos):
			return
		if unit_positions.has(grid_pos):
			unit_clicked.emit(unit_positions[grid_pos])
		else:
			tile_clicked.emit(grid_pos)


func _refresh_highlights() -> void:
	# Clear existing highlight visuals
	for child in highlight_layer.get_children():
		child.queue_free()
	# Helper to add a colored overlay at a grid position
	func _add_highlight(pos: Vector2i, color: Color) -> void:
		var rect := ColorRect.new()
		rect.color = color
		rect.size = tile_size
		# Position rect so it aligns with the top-left corner of the tile
		var world_pos: Vector2 = GridSystem.grid_to_world(pos, tile_size)
		rect.position = world_pos - Vector2(tile_size.x * 0.5, tile_size.y * 0.5)
		highlight_layer.add_child(rect)
	# Move range: cyan overlay
	for pos in move_tiles:
		_add_highlight(pos, Color(0, 1, 1, 0.3))
	# Attack range: orange overlay
	for pos in attack_tiles:
		_add_highlight(pos, Color(1, 0.5, 0, 0.3))
	# Ability range: purple overlay
	for pos in ability_tiles:
		_add_highlight(pos, Color(0.5, 0, 1, 0.3))
	# Selected tile: yellow overlay
	if _is_valid_pos(selected_tile):
		_add_highlight(selected_tile, Color(1, 1, 0, 0.35))


func _is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < map_data.map_width and pos.y < map_data.map_height


## Returns TileRuntimeData at position or null
func get_tile(pos: Vector2i) -> RefCounted:
	return tiles.get(pos, null)
