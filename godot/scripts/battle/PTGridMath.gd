extends RefCounted
class_name PTGridMath


static func col(tile: int, width: int) -> int:
	return tile % width


static func row(tile: int, width: int) -> int:
	return int(tile / width)


static func tile_id(col_id: int, row_id: int, width: int) -> int:
	return row_id * width + col_id


static func is_inside(tile: int, width: int, height: int) -> bool:
	return tile >= 0 and tile < width * height


static func manhattan(a: int, b: int, width: int) -> int:
	return abs(col(a, width) - col(b, width)) + abs(row(a, width) - row(b, width))


static func neighbors(tile: int, width: int, height: int) -> Array[int]:
	var result: Array[int] = []
	var c := col(tile, width)
	var r := row(tile, width)
	var candidates := [
		Vector2i(c, r - 1),
		Vector2i(c + 1, r),
		Vector2i(c, r + 1),
		Vector2i(c - 1, r),
	]
	for candidate in candidates:
		if candidate.x >= 0 and candidate.x < width and candidate.y >= 0 and candidate.y < height:
			result.append(tile_id(candidate.x, candidate.y, width))
	return result


static func tile_to_screen(tile: int, width: int, tile_width: float, tile_height: float, height_step: float, origin: Vector2, tile_height_value: int) -> Vector2:
	var c := float(col(tile, width))
	var r := float(row(tile, width))
	return origin + Vector2(
		(c - r) * tile_width * 0.5,
		(c + r) * tile_height * 0.5 - float(tile_height_value) * height_step
	)


static func screen_to_tile(position: Vector2, width: int, height: int, tile_width: float, tile_height: float, origin: Vector2) -> int:
	var local := position - origin
	var c := (local.x / (tile_width * 0.5) + local.y / (tile_height * 0.5)) * 0.5
	var r := (local.y / (tile_height * 0.5) - local.x / (tile_width * 0.5)) * 0.5
	var col_id := int(floor(c + 0.5))
	var row_id := int(floor(r + 0.5))
	if col_id < 0 or col_id >= width or row_id < 0 or row_id >= height:
		return -1
	return tile_id(col_id, row_id, width)
