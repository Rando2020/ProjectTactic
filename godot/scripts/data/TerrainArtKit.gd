## Opt-in art kit. Does not change any terrain's gameplay properties.
extends RefCounted

const NAMES := ["grass", "dirt", "stone", "cracked_stone", "shallow_water", "scorched"]

static func textures() -> Dictionary[String, Texture2D]:
	var result: Dictionary[String, Texture2D] = {}
	for terrain in NAMES:
		result[terrain] = load("res://assets/tiles/terrain_v2/%s.png" % terrain) as Texture2D
	return result

static func test_map() -> MapData:
	var map := MapData.new()
	map.id = "terrain_art_lab"
	map.display_name = "Terrain art laboratory"
	map.map_width = 8
	map.map_height = 8
	map.reward_gold = 0
	map.reward_jp = 0
	for y in 8:
		for x in 8:
			var material: String = NAMES[mini(x / 3, 2) + (3 if y >= 4 else 0)]
			map.tile_overrides.append({"x": x, "y": y, "terrain": material,
				"height": 1 if x >= 6 and y <= 1 else 0})
	return map
