## GridSystem.gd
## Pure grid math. No nodes, no rendering. Stateless utility functions.
## Used by TacticalGrid, BattleManager, AI, and pathfinding.
##
## AI AGENT: Implement all TODO functions.
## Do not add Node dependencies. Keep this file pure GDScript with no @onready.

class_name GridSystem
extends RefCounted

const DIRECTIONS_CARDINAL := [
	Vector2i(0, -1),  # N
	Vector2i(1, 0),   # E
	Vector2i(0, 1),   # S
	Vector2i(-1, 0),  # W
]

const DIRECTIONS_ALL := [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
	Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1),
]

const FACING_NAMES := { Vector2i(0,-1):"N", Vector2i(1,0):"E", Vector2i(0,1):"S", Vector2i(-1,0):"W" }


## Returns true if position is within the map bounds
static func is_inside_map(pos: Vector2i, map_width: int, map_height: int) -> bool:
	# Return true if the grid position lies within the rectangular map bounds.
	# Map coordinates are 0-indexed and inclusive on the low end, exclusive on the high end.
	# Negative coordinates or values beyond width/height are considered outside.
	return pos.x >= 0 and pos.x < map_width and pos.y >= 0 and pos.y < map_height


## Returns all cardinal neighbor positions inside the map
static func get_adjacent(pos: Vector2i, map_width: int, map_height: int) -> Array[Vector2i]:
	# Collect all cardinal neighbor positions (N,E,S,W) that stay within the map bounds.
	var adj: Array[Vector2i] = []
	for dir in DIRECTIONS_CARDINAL:
		var next := pos + dir
		if GridSystem.is_inside_map(next, map_width, map_height):
			adj.append(next)
	return adj


## Returns all positions within move_range tiles using BFS.
## Respects move_cost per tile and blocks on impassable terrain and units.
## tiles_dict: { Vector2i: TileRuntimeData }
## unit_positions: Array[Vector2i] of occupied tiles (excluding mover)
static func get_move_range(
	origin: Vector2i,
	move_range: int,
	tiles_dict: Dictionary,
	unit_positions: Array,
	map_width: int,
	map_height: int
) -> Array[Vector2i]:
	# Compute all reachable tiles from `origin` within the provided move_range.
	# Uses a simple Dijkstra search over cardinal neighbors, accumulating each tile's move_cost.
	# Blocks movement into positions listed in unit_positions or tiles flagged as impassable.
	var result: Array[Vector2i] = []
	# frontier stores dictionaries {pos: Vector2i, cost: int}
	var frontier: Array = [ { "pos": origin, "cost": 0 } ]
	# visited maps positions to the lowest cost discovered so far
	var visited := {}
	visited[origin] = 0
	while frontier.size() > 0:
		# Pop the entry with the lowest cost
		frontier.sort_custom(func(a, b): return a["cost"] < b["cost"])
		var current = frontier.pop_front()
		var current_pos: Vector2i = current["pos"]
		var current_cost: int = current["cost"]
		for dir in DIRECTIONS_CARDINAL:
			var next_pos: Vector2i = current_pos + dir
			if not GridSystem.is_inside_map(next_pos, map_width, map_height):
				continue
			# Skip positions occupied by other units
			if unit_positions.has(next_pos):
				continue
			var tile = tiles_dict.get(next_pos, null)
			if tile == null:
				continue
			# If the tile blocks movement (via terrain), skip
			if tile.has("blocks_movement") and tile.blocks_movement:
				continue
            # Compute step cost as tile move cost plus height difference
            var step_cost: int = 1
            if tile.has("move_cost"):
                step_cost = tile.move_cost
            # Height difference between current and next tile increases cost linearly
            var current_tile = tiles_dict.get(current_pos, null)
            var current_height: int = 0
            if current_tile and current_tile.has("height"):
                current_height = current_tile.height
            var next_height: int = 0
            if tile.has("height"):
                next_height = tile.height
            var height_diff := abs(next_height - current_height)
            var move_cost_weight := step_cost + height_diff
            var new_cost: int = current_cost + move_cost_weight
			if new_cost > move_range:
				continue
			var prev_cost = visited.get(next_pos, null)
			if prev_cost == null or new_cost < prev_cost:
				visited[next_pos] = new_cost
				frontier.append({ "pos": next_pos, "cost": new_cost })
	# Exclude the origin from the result set
	for pos_key in visited.keys():
		if pos_key != origin:
			result.append(pos_key)
	return result


## Returns the shortest path from start to goal as Array[Vector2i].
## Returns empty array if no path exists.
static func find_path(
	start: Vector2i,
	goal: Vector2i,
	tiles_dict: Dictionary,
	unit_positions: Array,
	map_width: int,
	map_height: int
) -> Array[Vector2i]:
	# Find the shortest path between two grid positions using A*.
	# Returns an array of positions from start through goal inclusive.
	# If no path exists (blocked or out of range), returns an empty array.
	if start == goal:
		return [start]
	# Maintain open set and scores
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = { start: 0 }
	var f_score: Dictionary = { start: GridSystem.manhattan(start, goal) }
	while open_set.size() > 0:
		# select node with lowest f_score; use a large sentinel value for missing entries
		var inf := 9999999
		open_set.sort_custom(func(a, b): return f_score.get(a, inf) < f_score.get(b, inf))
		var current: Vector2i = open_set.pop_front()
		if current == goal:
			var path: Array[Vector2i] = [current]
			var cursor := current
			while came_from.has(cursor):
				cursor = came_from[cursor]
				path.append(cursor)
			path.reverse()
			return path
		for dir in DIRECTIONS_CARDINAL:
			var neighbor: Vector2i = current + dir
			if not GridSystem.is_inside_map(neighbor, map_width, map_height):
				continue
			# Skip if occupied by another unit (unless it's the goal)
			if unit_positions.has(neighbor) and neighbor != goal:
				continue
			var tile = tiles_dict.get(neighbor, null)
			if tile == null:
				continue
			# Skip impassable tiles
			if tile.has("blocks_movement") and tile.blocks_movement:
				continue
            # Compute step cost as tile move cost plus height difference
            var step_cost: int = 1
            if tile.has("move_cost"):
                step_cost = tile.move_cost
            # Height difference between current and neighbor tile increases cost
            var current_tile = tiles_dict.get(current, null)
            var current_height: int = 0
            if current_tile and current_tile.has("height"):
                current_height = current_tile.height
            var neighbor_height: int = 0
            if tile.has("height"):
                neighbor_height = tile.height
            var height_diff := abs(neighbor_height - current_height)
            var move_cost_weight := step_cost + height_diff
            var tentative_g: int = g_score.get(current, 9999999) + move_cost_weight
			if tentative_g < g_score.get(neighbor, 9999999):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + GridSystem.manhattan(neighbor, goal)
				if not neighbor in open_set:
					open_set.append(neighbor)
	# If we exhaust the open set without reaching the goal, no path
	return []


## Returns tiles within attack range from origin (default: adjacent cardinal only)
static func get_attack_range(
	origin: Vector2i,
	min_range: int,
	max_range: int,
	map_width: int,
	map_height: int
) -> Array[Vector2i]:
	# Compute all positions within the inclusive [min_range, max_range] Manhattan distance.
	var result: Array[Vector2i] = []
	for y in range(map_height):
		for x in range(map_width):
			var pos: Vector2i = Vector2i(x, y)
			var dist: int = GridSystem.manhattan(origin, pos)
			if dist == 0:
				continue
			if dist >= min_range and dist <= max_range:
				# For range 1-1, restrict to cardinal neighbors only
				if max_range == 1:
					if pos in GridSystem.get_adjacent(origin, map_width, map_height):
						result.append(pos)
				else:
					result.append(pos)
	return result


## Manhattan distance between two grid positions
static func manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


## Returns facing string "N"/"E"/"S"/"W" based on movement delta
static func facing_from_delta(from: Vector2i, to: Vector2i) -> String:
	var delta := Vector2i(sign(to.x - from.x), sign(to.y - from.y))
	if abs(to.x - from.x) >= abs(to.y - from.y):
		return "E" if delta.x > 0 else "W"
	return "S" if delta.y > 0 else "N"


## Returns true if there is line of sight between two positions.
## Blocked by tiles with blocks_line_of_sight = true or height difference > 1.
static func has_line_of_sight(
	from: Vector2i,
	to: Vector2i,
	tiles_dict: Dictionary
) -> bool:
	# Determine if two positions have an unobstructed line of sight using Bresenham's algorithm.
	var x0 = from.x
	var y0 = from.y
	var x1 = to.x
	var y1 = to.y
	var dx = abs(x1 - x0)
	var dy = -abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy
	# Determine the base height at the origin for height comparison
	var origin_tile = tiles_dict.get(from, null)
	var base_height: int = 0
	if origin_tile and origin_tile.has("height"):
		base_height = origin_tile.height
	while true:
		var current_pos: Vector2i = Vector2i(x0, y0)
		# Exclude the origin and destination from blocking checks
		if current_pos != from and current_pos != to:
			var tile = tiles_dict.get(current_pos, null)
			if tile == null:
				return false
			var tile_height: int = 0
			if tile.has("height"):
				tile_height = tile.height
			# Height difference > 1 blocks line of sight
			if abs(tile_height - base_height) > 1:
				return false
			# LoS blocking flag
			if tile.has("blocks_line_of_sight") and tile.blocks_line_of_sight:
				return false
		# Check if reached destination
		if current_pos == to:
			break
		var e2 = 2 * err
		if e2 >= dy:
			if x0 == x1:
				# Only adjust y
				pass
			else:
				err += dy
				x0 += sx
		if e2 <= dx:
			if y0 == y1:
				# Only adjust x
				pass
			else:
				err += dx
				y0 += sy
	return true


## Converts grid position to world pixel position (centered on tile)
static func grid_to_world(grid_pos: Vector2i, tile_size: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size.x + tile_size.x * 0.5,
				   grid_pos.y * tile_size.y + tile_size.y * 0.5)


## Converts world pixel position to grid position
static func world_to_grid(world_pos: Vector2, tile_size: Vector2i) -> Vector2i:
	return Vector2i(int(world_pos.x / tile_size.x), int(world_pos.y / tile_size.y))
