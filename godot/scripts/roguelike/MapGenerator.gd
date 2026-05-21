## MapGenerator.gd
## Procedurally generates a complete MapData + enemy roster for each floor.
## Seeded — same floor + seed = same map every time (deterministic replay).
##
## Usage:
##   var mg := MapGenerator.new()
##   var map := mg.generate_floor(floor_number, run_seed)
##   # map is a MapData ready to pass to BattleScene

class_name MapGenerator
extends RefCounted

# ── Seeded RNG ────────────────────────────────────────────────────────────────

var _s: int = 0

func _rng() -> float:
	_s = (_s * 1664525 + 1013904223) & 0xffffffff
	return float(_s & 0xffffffff) / 4294967296.0

func _ri(n: int) -> int:
	return int(_rng() * n)

func _rb(chance: float) -> bool:
	return _rng() < chance


# ── Enemy definitions ─────────────────────────────────────────────────────────
## Each entry: id, display_name, floor_min, floor_max, hp, mp, move, jump,
##   speed, physical, magic, max_temper, max_ether, abilities[], affinities{}

const ENEMY_POOL: Array[Dictionary] = [
	{
		"id": "void_cultist", "name": "Void Cultist",
		"floor_min": 1, "floor_max": 6,
		"hp": 80, "mp": 80, "move": 3, "jump": 1, "speed": 7,
		"physical": 20, "magic": 55, "temper": 40, "ether": 100,
		"abilities": ["void_pulse", "dark_breath"],
		"affinities": {"holy": 2.0, "dark": 0.0, "fire": 0.75},
		"weight": 3,
	},
	{
		"id": "null_drake", "name": "Null Drake",
		"floor_min": 1, "floor_max": 8,
		"hp": 120, "mp": 35, "move": 3, "jump": 1, "speed": 6,
		"physical": 38, "magic": 30, "temper": 80, "ether": 60,
		"abilities": ["dark_breath"],
		"affinities": {"fire": 0.5, "blizzard": 1.5, "holy": 1.5, "dark": 0.5},
		"weight": 3,
	},
	{
		"id": "storm_imp", "name": "Storm Imp",
		"floor_min": 2, "floor_max": 9,
		"hp": 90, "mp": 50, "move": 4, "jump": 2, "speed": 9,
		"physical": 25, "magic": 45, "temper": 50, "ether": 90,
		"abilities": ["thunderstrike", "void_pulse"],
		"affinities": {"thunder": 0.0, "blizzard": 1.75, "holy": 1.25},
		"weight": 3,
	},
	{
		"id": "fen_wraith", "name": "Fen Wraith",
		"floor_min": 4, "floor_max": 10,
		"hp": 110, "mp": 60, "move": 3, "jump": 2, "speed": 8,
		"physical": 32, "magic": 42, "temper": 45, "ether": 85,
		"abilities": ["dark_breath", "void_pulse"],
		"affinities": {"fire": 1.5, "dark": 0.0, "holy": 1.75, "water": 0.5},
		"weight": 2,
	},
	{
		"id": "void_golem", "name": "Void Golem",
		"floor_min": 7, "floor_max": 10,
		"hp": 280, "mp": 20, "move": 2, "jump": 1, "speed": 4,
		"physical": 65, "magic": 20, "temper": 120, "ether": 40,
		"abilities": ["mighty_strike"],
		"affinities": {"holy": 2.0, "dark": 0.0, "fire": 0.5, "blizzard": 0.75},
		"weight": 1,
	},
]

# Enemy count per floor: [floor1, floor2, ..., floor10]
const ENEMY_COUNTS: Array[int] = [2, 2, 3, 3, 4, 4, 5, 5, 6, 7]

# Terrain types available
const TERRAIN_GRASS        := "grass"
const TERRAIN_STONE        := "stone"
const TERRAIN_ROAD         := "road"
const TERRAIN_WATER        := "shallow_water"
const TERRAIN_DEEP_WATER   := "deep_water"
const TERRAIN_HIGH_GROUND  := "high_ground"
const TERRAIN_SHRINE       := "shrine"
const TERRAIN_BURNING      := "burning"
const TERRAIN_VOID_ANCHOR  := "void_anchor"
const TERRAIN_BRUSH        := "brush"


# ── Main entry ────────────────────────────────────────────────────────────────

## Generate a complete MapData for a given floor and run seed.
func generate_floor(floor_num: int, run_seed: int) -> MapData:
	_s = ((run_seed * 1000 + floor_num) * 6364136223846793005 + 1442695040888963407) & 0xffffffff
	if _s == 0: _s = 1

	var map       := MapData.new()
	var map_w     := 10
	var map_h     := 8
	var is_boss   := floor_num >= 10

	map.id            = "generated_floor_%d_%d" % [floor_num, run_seed]
	map.display_name  = _floor_name(floor_num)
	map.map_width     = map_w
	map.map_height    = map_h
	map.default_terrain = TERRAIN_STONE if floor_num >= 5 else TERRAIN_GRASS
	map.objective_type  = "destroy_anchor" if is_boss else "defeat_all"
	map.objective_label = "Destroy the Void Anchor" if is_boss else "Defeat all enemies"
	map.reward_gold   = 100 + floor_num * 30
	map.reward_jp     = 30 + floor_num * 8

	# ── Tile overrides ────────────────────────────────────────────────────
	var tiles: Array[Dictionary] = []

	# Water cluster (1-2 clusters)
	var water_count := _ri(3) + 2 + floori(float(floor_num) / 3.0)
	_place_cluster(tiles, map_w, map_h, TERRAIN_WATER, water_count,
		_ri(map_w - 2) + 1, _ri(4) + 2)
	if floor_num >= 4 and _rb(0.45):
		var extra := _ri(2) + 1
		_place_cluster(tiles, map_w, map_h,
			TERRAIN_DEEP_WATER if floor_num >= 6 else TERRAIN_WATER,
			extra, _ri(map_w - 2) + 1, _ri(3) + 1)

	# High ground
	var hg_count := _ri(3) + 1
	for _i in range(hg_count):
		tiles.append({"x": _ri(map_w - 2) + 1, "y": _ri(map_h - 4) + 1,
			"terrain": TERRAIN_HIGH_GROUND, "height": 1})

	# Road corridor (50%)
	if _rb(0.5):
		var road_y := _ri(3) + 3
		for rx in range(map_w):
			tiles.append({"x": rx, "y": road_y, "terrain": TERRAIN_ROAD, "height": 0})

	# Brush scatter
	var brush_count := _ri(3) + 1
	for _i in range(brush_count):
		tiles.append({"x": _ri(map_w), "y": _ri(map_h - 2) + 1,
			"terrain": TERRAIN_BRUSH, "height": 0})

	# Shrine (floor 3+)
	if floor_num >= 3:
		var shrine_count := 1 + (1 if floor_num >= 7 else 0)
		for _i in range(shrine_count):
			tiles.append({"x": _ri(map_w - 2) + 1, "y": _ri(4) + 2,
				"terrain": TERRAIN_SHRINE, "height": 0})

	# Burning ground (floor 4+)
	if floor_num >= 4:
		var burn_count := _ri(2) + 1 + floori(float(floor_num) / 4.0)
		_place_cluster(tiles, map_w, map_h, TERRAIN_BURNING, burn_count,
			_ri(map_w - 2) + 1, _ri(3) + 1)

	# Void Anchor tile (boss floor only)
	if is_boss:
		tiles.append({"x": 5, "y": 0, "terrain": TERRAIN_VOID_ANCHOR, "height": 2})
		# Flanking walls
		tiles.append({"x": 4, "y": 0, "terrain": TERRAIN_HIGH_GROUND, "height": 2})
		tiles.append({"x": 6, "y": 0, "terrain": TERRAIN_HIGH_GROUND, "height": 2})
		# Approach water — electrifiable with Torvahk builds
		tiles.append({"x": 4, "y": 1, "terrain": TERRAIN_WATER, "height": 0})
		tiles.append({"x": 5, "y": 1, "terrain": TERRAIN_WATER, "height": 0})
		tiles.append({"x": 6, "y": 1, "terrain": TERRAIN_WATER, "height": 0})
		# Add burning ground on flanks
		tiles.append({"x": 2, "y": 1, "terrain": TERRAIN_BURNING, "height": 0})
		tiles.append({"x": 8, "y": 1, "terrain": TERRAIN_BURNING, "height": 0})

	map.tile_overrides = tiles

	# ── Enemy spawns ──────────────────────────────────────────────────────
	var enemy_count := ENEMY_COUNTS[clamp(floor_num - 1, 0, ENEMY_COUNTS.size() - 1)]
	map.enemy_spawns = _generate_enemy_spawns(floor_num, enemy_count, map_w, map_h, is_boss)

	# ── Player spawns (bottom edge) ───────────────────────────────────────
	map.player_spawns = [
		{"unit_id": "zane", "x": 2, "y": 7, "facing": "N"},
		{"unit_id": "mira", "x": 4, "y": 7, "facing": "N"},
		{"unit_id": "kael", "x": 6, "y": 7, "facing": "N"},
	]

	return map


# ── Helpers ───────────────────────────────────────────────────────────────────

func _place_cluster(tiles: Array, map_w: int, map_h: int,
		terrain: String, count: int, cx: int, cy: int) -> void:
	var dirs := [Vector2i(0,0), Vector2i(1,0), Vector2i(-1,0),
				 Vector2i(0,1), Vector2i(0,-1), Vector2i(1,1), Vector2i(-1,-1)]
	dirs.shuffle()
	var placed := 0
	for d in dirs:
		if placed >= count: break
		var tx: int = clampi(cx + d.x, 0, map_w - 1)
		var ty: int = clampi(cy + d.y, 0, map_h - 1)
		# Don't place in player spawn rows (y >= 6)
		if ty >= 6: continue
		tiles.append({"x": tx, "y": ty, "terrain": terrain, "height": 0})
		placed += 1


func _generate_enemy_spawns(floor_num: int, count: int, map_w: int, _map_h: int,
		is_boss: bool) -> Array[Dictionary]:
	# Build weighted pool of valid enemy types for this floor
	var pool: Array[Dictionary] = []
	for e in ENEMY_POOL:
		if floor_num >= e["floor_min"] and floor_num <= e["floor_max"]:
			for _w in range(e["weight"]):
				pool.append(e)

	if pool.is_empty(): pool = [ENEMY_POOL[0]]

	var spawns: Array[Dictionary] = []
	var used_positions: Array[Vector2i] = []

	# Boss floor: force Void Golem + Void Anchor
	if is_boss:
		# The Anchor — stationary, holy-weak, pulses dark damage every turn
		spawns.append({
			"unit_id": "void_anchor", "name": "The Sleeping Anchor",
			"x": 5, "y": 0, "facing": "S",
			"hp": 600, "mp": 0, "move": 0, "jump": 0, "speed": 1,
			"physical": 0, "magic": 80, "max_temper": 0, "max_ether": 200,
			"abilities": ["void_anchor_pulse"],
			"affinities": {"holy": 2.5, "fire": 0.15, "thunder": 0.15,
						   "water": 0.15, "dark": 0.0, "blizzard": 0.15},
			"is_anchor": true, "is_anchor_guardian": true,
			"cannot_move": true,
		})
		used_positions.append(Vector2i(5, 0))
		# The Golem — guardian in front of the anchor
		for e in ENEMY_POOL:
			if e["id"] == "void_golem":
				spawns.append(_make_spawn(e, Vector2i(5, 2)))
				used_positions.append(Vector2i(5, 2))
				break

	# Fill remaining enemy slots
	var attempts := 0
	while spawns.size() < count and attempts < 100:
		attempts += 1
		var enemy_def: Dictionary = pool[_ri(pool.size())]
		# Spread enemies across top portion of map
		var ex := _ri(map_w - 2) + 1
		var ey := _ri(3) + 0   # rows 0-3
		var pos := Vector2i(ex, ey)
		if used_positions.has(pos): continue
		used_positions.append(pos)
		spawns.append(_make_spawn(enemy_def, pos))

	return spawns


func _make_spawn(enemy_def: Dictionary, pos: Vector2i) -> Dictionary:
	return {
		"unit_id":    enemy_def["id"],
		"name":       enemy_def["name"],
		"x":          pos.x,
		"y":          pos.y,
		"facing":     "S",
		"hp":         enemy_def["hp"],
		"mp":         enemy_def["mp"],
		"move":       enemy_def["move"],
		"jump":       enemy_def["jump"],
		"speed":      enemy_def["speed"],
		"physical":   enemy_def["physical"],
		"magic":      enemy_def["magic"],
		"max_temper": enemy_def["temper"],
		"max_ether":  enemy_def["ether"],
		"abilities":  enemy_def["abilities"],
		"affinities": enemy_def["affinities"],
	}


func _floor_name(floor_num: int) -> String:
	var names: Array[String] = [
		"Ashvale Outskirts",
		"Crumbled Watchpost",
		"Mirefen Border",
		"Sunken Archive",
		"Bellkeeper's Approach",
		"Collapsed Sanctum",
		"Fen Wraith Hollow",
		"Stormglass Ruins",
		"Thornspire Approach",
		"Thornspire Vault — The Sleeping Anchor",
	]
	return names[clamp(floor_num - 1, 0, names.size() - 1)]
