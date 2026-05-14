extends RefCounted
class_name PTPathfinder


static func movement_range(unit: Dictionary, tiles: Dictionary, width: int, height: int, occupied: Dictionary) -> Dictionary:
	var start: int = unit["tile"]
	var move_budget: int = int(unit.get("move", 3))
	var jump_limit: int = int(unit.get("jump", 2))
	var reached := { start: 0 }
	var frontier: Array[int] = [start]
	var cursor := 0

	while cursor < frontier.size():
		var current := frontier[cursor]
		cursor += 1
		var spent: int = reached[current]
		for next_tile in PTGridMath.neighbors(current, width, height):
			if not tiles.has(next_tile):
				continue
			var tile_data: Dictionary = tiles[next_tile]
			if not tile_data.get("walkable", false):
				continue
			if occupied.has(next_tile) and next_tile != start:
				continue
			var height_delta: int = abs(int(tile_data.get("height", 0)) - int(tiles[current].get("height", 0)))
			if height_delta > jump_limit:
				continue
			var cost := terrain_cost(tile_data)
			var next_spent := spent + cost
			if next_spent > move_budget:
				continue
			if not reached.has(next_tile) or next_spent < int(reached[next_tile]):
				reached[next_tile] = next_spent
				frontier.append(next_tile)
	return reached


static func best_step_toward(unit: Dictionary, target_tile: int, tiles: Dictionary, width: int, height: int, occupied: Dictionary) -> int:
	var reachable := movement_range(unit, tiles, width, height, occupied)
	var best_tile := int(unit["tile"])
	var best_score := 99999
	for tile in reachable.keys():
		if tile == unit["tile"]:
			continue
		var score := PTGridMath.manhattan(tile, target_tile, width) * 10 + int(reachable[tile])
		if score < best_score:
			best_score = score
			best_tile = tile
	return best_tile


static func terrain_cost(tile_data: Dictionary) -> int:
	if tile_data.has("moveCost"):
		return int(tile_data["moveCost"])
	match String(tile_data.get("terrain", "grass")):
		"water":
			return 3
		"cliff":
			return 2
		"stairs":
			return 1
		"dirt":
			return 1
	return 1
