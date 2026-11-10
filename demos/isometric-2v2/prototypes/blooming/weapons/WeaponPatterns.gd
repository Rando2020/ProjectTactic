extends RefCounted
## Provisional courtyard equipment only. One geometry contract for preview and damage.
const LOADOUTS := {"zane":["sword","spear"], "kael":["sword","greatsword"]}
const LABELS := {"sword":"Sword · 1 tile", "spear":"Spear · 2 in line", "greatsword":"Greatsword · 3 across"}
static func open_cell(cell: Vector2i, tiles: Dictionary) -> bool:
	return tiles.has(cell) and not bool(tiles[cell].get("blocks_movement",false)) and not bool(tiles[cell].get("blocks_line_of_sight",false))
static func footprint(weapon: String, origin: Vector2i, aim: Vector2i, tiles: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if weapon not in LABELS:return result
	var delta := aim-origin
	var distance := absi(delta.x)+absi(delta.y)
	if distance < 1 or distance > (2 if weapon=="spear" else 1) or (delta.x!=0 and delta.y!=0):return result
	var forward := Vector2i(signi(delta.x),signi(delta.y))
	var front := origin+forward
	if not open_cell(front,tiles):return result
	result.append(front)
	if weapon=="spear":
		var far := front+forward
		if open_cell(far,tiles):result.append(far)
		if aim not in result:result.clear()
	elif weapon=="greatsword":
		var side := Vector2i(forward.y,-forward.x)
		for cell in [front+side,front-side]:
			if open_cell(cell,tiles):result.append(cell)
	return result
static func aim_cells(weapon: String, origin: Vector2i, tiles: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
		for distance in range(1,3 if weapon=="spear" else 2):
			var aim: Vector2i=origin+direction*distance
			if not footprint(weapon,origin,aim,tiles).is_empty():result.append(aim)
	return result
