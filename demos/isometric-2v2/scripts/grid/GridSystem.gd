## GridSystem.gd
## Pure grid math. No nodes, no rendering. Stateless utility functions.

class_name GridSystem
extends RefCounted

const DIRECTIONS_CARDINAL: Array[Vector2i] = [
	Vector2i(0, -1),  # N
	Vector2i(1, 0),   # E
	Vector2i(0, 1),   # S
	Vector2i(-1, 0),  # W
]

const DIRECTIONS_ALL: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
	Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1),
]


## Returns true if position is within the map bounds
static func is_inside_map(pos: Vector2i, map_width: int, map_height: int) -> bool:
	return pos.x >= 0 and pos.x < map_width and pos.y >= 0 and pos.y < map_height


## Returns all cardinal neighbour positions inside the map
static func get_adjacent(pos: Vector2i, map_width: int, map_height: int) -> Array[Vector2i]:
	var adj: Array[Vector2i] = []
	for dir: Vector2i in DIRECTIONS_CARDINAL:
		var next: Vector2i = pos + dir
		if GridSystem.is_inside_map(next, map_width, map_height):
			adj.append(next)
	return adj


## Returns all positions reachable within move_range using Dijkstra BFS.
## tiles_dict: Dictionary{ Vector2i -> Dictionary }
## unit_positions: Array of occupied Vector2i (excluding the mover)
static func get_move_range(
	origin: Vector2i,
	move_range: int,
	tiles_dict: Dictionary,
	unit_positions: Array,
	map_width: int,
	map_height: int,
	jump_range: int = 99
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var frontier: Array[Dictionary] = [ { "pos": origin, "cost": 0 } ]
	var visited: Dictionary = {}
	visited[origin] = 0
	while frontier.size() > 0:
		frontier.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["cost"] < b["cost"])
		var current: Dictionary = frontier.pop_front()
		var current_pos: Vector2i = current["pos"]
		var current_cost: int = current["cost"]
		for dir: Vector2i in DIRECTIONS_CARDINAL:
			var next_pos: Vector2i = current_pos + dir
			if not GridSystem.is_inside_map(next_pos, map_width, map_height):
				continue
			if unit_positions.has(next_pos):
				continue
			if not tiles_dict.has(next_pos):
				continue
			var tile: Dictionary = tiles_dict[next_pos]
			if tile.get("blocks_movement", false):
				continue
			var step_cost: int = tile.get("move_cost", 1)
			var current_height: int = 0
			if tiles_dict.has(current_pos):
				var ct: Dictionary = tiles_dict[current_pos]
				current_height = ct.get("height", 0)
			var next_height: int = tile.get("height", 0)
			var height_diff: int = abs(next_height - current_height)
			# Cannot climb or drop more than the unit's jump stat
			if height_diff > jump_range:
				continue
			var new_cost: int = current_cost + step_cost + height_diff
			if new_cost > move_range:
				continue
			var prev: Variant = visited.get(next_pos, null)
			if prev == null or new_cost < int(prev):
				visited[next_pos] = new_cost
				frontier.append({ "pos": next_pos, "cost": new_cost })
	for pos_key: Variant in visited.keys():
		var p: Vector2i = pos_key
		if p != origin:
			result.append(p)
	return result


## Returns the shortest path from start to goal using A*.
## Returns empty array if no path exists.
static func find_path(
	start: Vector2i,
	goal: Vector2i,
	tiles_dict: Dictionary,
	unit_positions: Array,
	map_width: int,
	map_height: int
) -> Array[Vector2i]:
	if start == goal:
		return [start]
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = { start: 0 }
	var f_score: Dictionary = { start: GridSystem.manhattan(start, goal) }
	while open_set.size() > 0:
		var inf := 9999999
		open_set.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return f_score.get(a, inf) < f_score.get(b, inf))
		var current: Vector2i = open_set.pop_front()
		if current == goal:
			var path: Array[Vector2i] = [current]
			var cursor: Vector2i = current
			while came_from.has(cursor):
				cursor = came_from[cursor]
				path.append(cursor)
			path.reverse()
			return path
		for dir: Vector2i in DIRECTIONS_CARDINAL:
			var neighbor: Vector2i = current + dir
			if not GridSystem.is_inside_map(neighbor, map_width, map_height):
				continue
			if unit_positions.has(neighbor) and neighbor != goal:
				continue
			if not tiles_dict.has(neighbor):
				continue
			var tile: Dictionary = tiles_dict[neighbor]
			if tile.get("blocks_movement", false):
				continue
			var step_cost: int = tile.get("move_cost", 1)
			var current_height: int = 0
			if tiles_dict.has(current):
				var ct: Dictionary = tiles_dict[current]
				current_height = ct.get("height", 0)
			var neighbor_height: int = tile.get("height", 0)
			var tentative_g: int = g_score.get(current, 9999999) + step_cost + abs(neighbor_height - current_height)
			if tentative_g < g_score.get(neighbor, 9999999):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + GridSystem.manhattan(neighbor, goal)
				if not neighbor in open_set:
					open_set.append(neighbor)
	return []


## Returns tiles within [min_range, max_range] Manhattan distance from origin.
static func get_attack_range(
	origin: Vector2i,
	min_range: int,
	max_range: int,
	map_width: int,
	map_height: int
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(map_height):
		for x in range(map_width):
			var pos := Vector2i(x, y)
			var dist: int = GridSystem.manhattan(origin, pos)
			if dist == 0:
				continue
			if dist >= min_range and dist <= max_range:
				if max_range == 1:
					if pos in GridSystem.get_adjacent(origin, map_width, map_height):
						result.append(pos)
				else:
					result.append(pos)
	return result


## Manhattan distance between two grid positions
static func manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


## Returns "N"/"E"/"S"/"W" based on movement delta
static func facing_from_delta(from: Vector2i, to: Vector2i) -> String:
	var delta := Vector2i(sign(to.x - from.x), sign(to.y - from.y))
	if abs(to.x - from.x) >= abs(to.y - from.y):
		return "E" if delta.x > 0 else "W"
	return "S" if delta.y > 0 else "N"


## Bresenham line-of-sight check.
static func has_line_of_sight(from: Vector2i, to: Vector2i, tiles_dict: Dictionary) -> bool:
	var x0: int = from.x
	var y0: int = from.y
	var x1: int = to.x
	var y1: int = to.y
	var dx: int = abs(x1 - x0)
	var dy: int = -abs(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	var base_height: int = 0
	if tiles_dict.has(from):
		var ot: Dictionary = tiles_dict[from]
		base_height = ot.get("height", 0)
	while true:
		var cur := Vector2i(x0, y0)
		if cur != from and cur != to:
			if not tiles_dict.has(cur):
				return false
			var tile: Dictionary = tiles_dict[cur]
			if abs(tile.get("height", 0) - base_height) > 1:
				return false
			if tile.get("blocks_line_of_sight", false):
				return false
		if cur == to:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			if x0 != x1:
				err += dy
				x0 += sx
		if e2 <= dx:
			if y0 != y1:
				err += dx
				y0 += sy
	return true


## Grid  world pixel (tile centre)
static func grid_to_world(grid_pos: Vector2i, tile_size: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size.x + tile_size.x * 0.5,
				   grid_pos.y * tile_size.y + tile_size.y * 0.5)


## World pixel  grid position
static func world_to_grid(world_pos: Vector2, tile_size: Vector2i) -> Vector2i:
	return Vector2i(int(world_pos.x / tile_size.x), int(world_pos.y / tile_size.y))
