## MapGenerator.gd
## Procedurally generates a complete MapData + enemy roster for each floor.
## Seeded  same floor + seed = same map every time (deterministic replay).
##
## Usage:
##   var mg := MapGenerator.new()
##   var map := mg.generate_floor(floor_number, run_seed, heat_level)

class_name MapGenerator
extends RefCounted

#  Seeded RNG

var _s: int = 0

func _rng() -> float:
	_s = (_s * 1664525 + 1013904223) & 0xffffffff
	return float(_s & 0xffffffff) / 4294967296.0

func _ri(n: int) -> int:
	return int(_rng() * n)

func _rb(chance: float) -> bool:
	return _rng() < chance

#  ENEMY POOL
#  Fields:
#    id, name             identity
#    floor_min/max        floor range this enemy can appear
#    spawn_chance         0.0-1.0: probability this enemy is even in the pool
#                          for any given floor. 1.0 = always eligible if in range.
#                          Checked once per floor, seeded.
#    role                 "any"|"tank"|"fast"|"caster"|"heavy"
#                          Used by encounter composition templates.
#    weight               relative draw probability within the eligible pool
#    hp/mp/move/jump/speed/physical/magic/temper/ether   BASE stats at floor 1.
#                          Floor scaling is applied on top via _scale_stats().
#    abilities, affinities

const ENEMY_POOL: Array[Dictionary] = [
	#  Void Cultist
	# Glass cannon caster. Guaranteed spawn on every valid floor  it's the
	# tutorial enemy that teaches players "kill the mage first."
	{
		"id": "void_cultist", "name": "Void Cultist",
		"floor_min": 1, "floor_max": 6,
		"spawn_chance": 1.0,
		"role": "caster",
		"weight": 3,
		"hp": 65, "mp": 80, "move": 3, "jump": 1, "speed": 7,
		"physical": 18, "magic": 50, "temper": 30, "ether": 90,
		"abilities": ["void_pulse", "dark_breath"],
		"affinities": {"holy": 2.0, "dark": 0.0, "fire": 0.75},
	},
	#  Null Drake
	# Tanky melee. Always eligible in its range  teaches block/positioning.
	{
		"id": "null_drake", "name": "Null Drake",
		"floor_min": 1, "floor_max": 8,
		"spawn_chance": 1.0,
		"role": "tank",
		"weight": 3,
		"hp": 100, "mp": 35, "move": 3, "jump": 1, "speed": 5,
		"physical": 35, "magic": 22, "temper": 65, "ether": 50,
		"abilities": ["slash", "dark_breath"],
		"affinities": {"fire": 0.5, "blizzard": 1.5, "holy": 1.5, "dark": 0.5},
	},
	#  Storm Imp
	# Fast flanker. 80% chance to appear  occasionally absent, surprise.
	{
		"id": "storm_imp", "name": "Storm Imp",
		"floor_min": 2, "floor_max": 9,
		"spawn_chance": 0.80,
		"role": "fast",
		"weight": 3,
		"hp": 75, "mp": 50, "move": 4, "jump": 2, "speed": 10,
		"physical": 22, "magic": 42, "temper": 40, "ether": 80,
		"abilities": ["thunderstrike", "void_pulse"],
		"affinities": {"thunder": 0.0, "blizzard": 1.75, "holy": 1.25, "fire": 1.5},
	},
	#  Fen Wraith
	# Mid-tier bruiser. 70% chance  variant encounter, not guaranteed.
	{
		"id": "fen_wraith", "name": "Fen Wraith",
		"floor_min": 4, "floor_max": 10,
		"spawn_chance": 0.70,
		"role": "any",
		"weight": 2,
		"hp": 130, "mp": 60, "move": 3, "jump": 2, "speed": 7,
		"physical": 38, "magic": 45, "temper": 55, "ether": 80,
		"abilities": ["dark_breath", "void_pulse", "slash"],
		"affinities": {"fire": 1.5, "dark": 0.0, "holy": 1.75, "water": 0.5},
	},
	#  Void Golem
	# Heavy bruiser. 55% chance floor 7-9; boss floor it's forced separately.
	{
		"id": "void_golem", "name": "Void Golem",
		"floor_min": 7, "floor_max": 9,
		"spawn_chance": 0.55,
		"role": "heavy",
		"weight": 1,
		"hp": 240, "mp": 20, "move": 2, "jump": 1, "speed": 3,
		"physical": 60, "magic": 18, "temper": 100, "ether": 35,
		"abilities": ["mighty_strike", "iron_wall"],
		"affinities": {"holy": 2.0, "dark": 0.0, "fire": 0.5, "blizzard": 0.75},
	},
	#  Ashen Knight
	# New mid-game tank/caster hybrid. 60% chance, floors 5-9.
	{
		"id": "ashen_knight", "name": "Ashen Knight",
		"floor_min": 5, "floor_max": 9,
		"spawn_chance": 0.60,
		"role": "tank",
		"weight": 2,
		"hp": 155, "mp": 55, "move": 2, "jump": 1, "speed": 5,
		"physical": 42, "magic": 38, "temper": 80, "ether": 60,
		"abilities": ["slash", "holy_strike", "iron_wall"],
		"affinities": {"dark": 1.5, "holy": 0.5, "fire": 1.0, "blizzard": 0.75},
	},
	#  Rift Shade
	# Rare fast caster. Only 40% chance  high-value target when it appears.
	{
		"id": "rift_shade", "name": "Rift Shade",
		"floor_min": 6, "floor_max": 10,
		"spawn_chance": 0.40,
		"role": "caster",
		"weight": 1,
		"hp": 90, "mp": 110, "move": 3, "jump": 2, "speed": 9,
		"physical": 20, "magic": 65, "temper": 25, "ether": 120,
		"abilities": ["dark_breath", "void_pulse", "elemental_convergence"],
		"affinities": {"holy": 2.5, "dark": 0.0, "fire": 1.25, "blizzard": 1.25},
	},
]

#  ENCOUNTER TEMPLATES
#  Define the *shape* of a battle  how many enemies and what roles they fill.
#  The generator picks a template first, then fills each slot from the
#  eligible enemy pool.

#  Fields:
#    id, label            identity / debug name
#    weight               relative draw probability
#    floor_min/max        valid floor range
#    slots                Array of {role, count} describing each enemy group
#                          role "any" draws from the full eligible pool

const ENCOUNTER_TEMPLATES: Array[Dictionary] = [
	#  Swarm
	# Raw numbers. Tests AoE and action economy.
	{
		"id": "swarm", "label": "Swarm",
		"weight": 3, "floor_min": 1, "floor_max": 7,
		"slots": [
			{"role": "any", "count": 4},
		],
	},
	#  Vanguard
	# A tank out front soaking damage while others flank. Tests positioning.
	{
		"id": "vanguard", "label": "Vanguard",
		"weight": 3, "floor_min": 2, "floor_max": 10,
		"slots": [
			{"role": "tank", "count": 1},
			{"role": "any",  "count": 2},
		],
	},
	#  Ambush
	# Fast flankers + a caster in the back. Tests reaction speed.
	{
		"id": "ambush", "label": "Ambush",
		"weight": 2, "floor_min": 2, "floor_max": 10,
		"slots": [
			{"role": "fast",   "count": 2},
			{"role": "caster", "count": 1},
		],
	},
	#  Siege
	# Slow heavies with caster support. Tests sustained damage output.
	{
		"id": "siege", "label": "Siege",
		"weight": 2, "floor_min": 5, "floor_max": 10,
		"slots": [
			{"role": "heavy",  "count": 1},
			{"role": "caster", "count": 2},
		],
	},
	#  Suppression
	# Pure casters. High burst danger, low durability  punishes slow turns.
	{
		"id": "suppression", "label": "Suppression",
		"weight": 1, "floor_min": 3, "floor_max": 10,
		"slots": [
			{"role": "caster", "count": 3},
		],
	},
	#  Ironwall
	# All tanks + a fast skirmisher. Attrition battle, rewards elemental play.
	{
		"id": "ironwall", "label": "Ironwall",
		"weight": 1, "floor_min": 4, "floor_max": 10,
		"slots": [
			{"role": "tank", "count": 2},
			{"role": "fast", "count": 1},
		],
	},
]


#  Enemy count per floor
# Slightly more on higher floors; template fills these naturally.
const ENEMY_COUNTS: Array[int] = [3, 3, 3, 4, 4, 4, 5, 5, 6, 7]

#  STAT SCALING
#  Base stats defined in ENEMY_POOL are for FLOOR 1, HEAT 0.
#  Each floor and heat level applies a multiplicative bonus.

#  Scaling intent:
#     HP grows fastest (enemies stay threatening at deep floors)
#     Physical/Magic grow moderately (fights don't become instant-kill)
#     Temper/Ether grow at mid rate (stripping armor stays relevant)
#     Speed/Move/Jump do NOT scale (combat geometry stays consistent)

#  Floor scalar (applied to all stats):
#    scale = 1.0 + (floor_num - 1) * FLOOR_GROWTH_PER_FLOOR

#  Heat bonus (applied after floor scalar):
#    heat_mult = 1.0 + heat_level * HEAT_BONUS_PER_LEVEL

# Each floor beyond 1 adds this fraction to each stat group
const FLOOR_GROWTH_HP:     float = 0.12   # +12% HP per floor  2.08x at floor 10
const FLOOR_GROWTH_DAMAGE: float = 0.07   # +7%  per floor     1.63x at floor 10
const FLOOR_GROWTH_ARMOR:  float = 0.09   # +9%  per floor     1.81x at floor 10

# Each heat level adds a flat bonus on top of the already-scaled value
const HEAT_BONUS_PER_LEVEL: float = 0.06  # +6% all stats per heat level


## Apply floor + heat scaling to a spawn dict.
## Mutates and returns the dict.
func _scale_stats(spawn: Dictionary, floor_num: int, heat_level: int) -> Dictionary:
	var f: int   = max(0, floor_num - 1)  # floor 1 = no bonus
	var h: float = max(0.0, float(heat_level))

	# Floor growth multipliers
	var hp_mult:     float = 1.0 + float(f) * FLOOR_GROWTH_HP
	var dmg_mult:    float = 1.0 + float(f) * FLOOR_GROWTH_DAMAGE
	var armor_mult:  float = 1.0 + float(f) * FLOOR_GROWTH_ARMOR

	# Heat bonus  multiplicative on top of floor scaling
	var heat_factor: float = 1.0 + h * HEAT_BONUS_PER_LEVEL

	spawn["hp"]         = roundi(float(spawn.get("hp",         100)) * hp_mult    * heat_factor)
	spawn["max_temper"] = roundi(float(spawn.get("max_temper",  50)) * armor_mult * heat_factor)
	spawn["max_ether"]  = roundi(float(spawn.get("max_ether",   50)) * armor_mult * heat_factor)
	spawn["physical"]   = roundi(float(spawn.get("physical",    20)) * dmg_mult   * heat_factor)
	spawn["magic"]      = roundi(float(spawn.get("magic",       20)) * dmg_mult   * heat_factor)

	# Record for UI / debug
	spawn["_floor_num"]  = floor_num
	spawn["_heat_level"] = heat_level
	spawn["_scaled"]     = true

	return spawn

#  TERRAIN

const TERRAIN_GRASS       := "grass"
const TERRAIN_STONE       := "stone"
const TERRAIN_ROAD        := "road"
const TERRAIN_WATER       := "shallow_water"
const TERRAIN_DEEP_WATER  := "deep_water"
const TERRAIN_HIGH_GROUND := "high_ground"
const TERRAIN_SHRINE      := "shrine"
const TERRAIN_BURNING     := "burning"
const TERRAIN_VOID_ANCHOR := "void_anchor"
const TERRAIN_BRUSH       := "brush"

#  MAIN ENTRY

## Generate a complete MapData for a given floor, run seed, and heat level.
func generate_floor(floor_num: int, run_seed: int, heat_level: int = 0) -> MapData:
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
	map.reward_jp     = 30  + floor_num * 8

	#  Tile overrides
	var tiles: Array[Dictionary] = []

	var water_count := _ri(3) + 2 + floori(float(floor_num) / 3.0)
	_place_cluster(tiles, map_w, map_h, TERRAIN_WATER, water_count,
		_ri(map_w - 2) + 1, _ri(4) + 2)
	if floor_num >= 4 and _rb(0.45):
		var extra := _ri(2) + 1
		_place_cluster(tiles, map_w, map_h,
			TERRAIN_DEEP_WATER if floor_num >= 6 else TERRAIN_WATER,
			extra, _ri(map_w - 2) + 1, _ri(3) + 1)

	var hg_count := _ri(3) + 1
	for _i in range(hg_count):
		tiles.append({"x": _ri(map_w - 2) + 1, "y": _ri(map_h - 4) + 1,
			"terrain": TERRAIN_HIGH_GROUND, "height": 1})

	if _rb(0.5):
		var road_y := _ri(3) + 3
		for rx in range(map_w):
			tiles.append({"x": rx, "y": road_y, "terrain": TERRAIN_ROAD, "height": 0})

	var brush_count := _ri(3) + 1
	for _i in range(brush_count):
		tiles.append({"x": _ri(map_w), "y": _ri(map_h - 2) + 1,
			"terrain": TERRAIN_BRUSH, "height": 0})

	if floor_num >= 3:
		var shrine_count := 1 + (1 if floor_num >= 7 else 0)
		for _i in range(shrine_count):
			tiles.append({"x": _ri(map_w - 2) + 1, "y": _ri(4) + 2,
				"terrain": TERRAIN_SHRINE, "height": 0})

	if floor_num >= 4:
		var burn_count := _ri(2) + 1 + floori(float(floor_num) / 4.0)
		_place_cluster(tiles, map_w, map_h, TERRAIN_BURNING, burn_count,
			_ri(map_w - 2) + 1, _ri(3) + 1)

	if is_boss:
		tiles.append({"x": 5, "y": 0, "terrain": TERRAIN_VOID_ANCHOR, "height": 2})
		tiles.append({"x": 4, "y": 0, "terrain": TERRAIN_HIGH_GROUND, "height": 2})
		tiles.append({"x": 6, "y": 0, "terrain": TERRAIN_HIGH_GROUND, "height": 2})
		tiles.append({"x": 4, "y": 1, "terrain": TERRAIN_WATER, "height": 0})
		tiles.append({"x": 5, "y": 1, "terrain": TERRAIN_WATER, "height": 0})
		tiles.append({"x": 6, "y": 1, "terrain": TERRAIN_WATER, "height": 0})
		tiles.append({"x": 2, "y": 1, "terrain": TERRAIN_BURNING, "height": 0})
		tiles.append({"x": 8, "y": 1, "terrain": TERRAIN_BURNING, "height": 0})

	map.tile_overrides = tiles

	#  Enemy spawns
	var target_count := ENEMY_COUNTS[clamp(floor_num - 1, 0, ENEMY_COUNTS.size() - 1)]
	map.enemy_spawns = _generate_enemy_spawns(floor_num, run_seed, heat_level,
		target_count, map_w, map_h, is_boss)

	#  Player spawns (bottom edge)
	map.player_spawns = [
		{"unit_id": "zane", "x": 2, "y": 7, "facing": "N"},
		{"unit_id": "mira", "x": 4, "y": 7, "facing": "N"},
		{"unit_id": "kael", "x": 6, "y": 7, "facing": "N"},
	]

	#  Deployment zones (bottom two rows)
	var d_zones: Array[Dictionary] = []
	for dz_y in range(map_h - 2, map_h):
		for dz_x in range(0, map_w):
			d_zones.append({"x": dz_x, "y": dz_y})
	map.deployment_zones = d_zones

	return map

#  ENEMY SPAWN GENERATION

func _generate_enemy_spawns(floor_num: int, run_seed: int, heat_level: int,
		count: int, map_w: int, _map_h: int, is_boss: bool) -> Array[Dictionary]:

	var spawns: Array[Dictionary]       = []
	var used_positions: Array[Vector2i] = []

	#  Boss floor: forced composition
	if is_boss:
		spawns.append(_make_boss_anchor(floor_num, heat_level))
		used_positions.append(Vector2i(5, 0))
		for e in ENEMY_POOL:
			if e["id"] == "void_golem":
				var golem := _make_spawn(e, Vector2i(5, 2), floor_num, heat_level)
				spawns.append(golem)
				used_positions.append(Vector2i(5, 2))
				break
		# Two flanking golems at Heat 2+
		if heat_level >= 2:
			for e in ENEMY_POOL:
				if e["id"] == "void_golem":
					spawns.append(_make_spawn(e, Vector2i(2, 1), floor_num, heat_level))
					used_positions.append(Vector2i(2, 1))
					spawns.append(_make_spawn(e, Vector2i(8, 1), floor_num, heat_level))
					used_positions.append(Vector2i(8, 1))
					break

	#  Build eligible pool (check spawn_chance)
	# Use a separate RNG state so position rolls don't interfere
	var pool := _eligible_pool(floor_num, run_seed)

	#  Pick encounter template
	var template := _pick_template(floor_num, pool)

	#  Fill slots from template
	var slots_filled := spawns.size()   # already have boss units
	for slot in template["slots"]:
		var role: String = str(slot.get("role", "any"))
		var slot_count: int = int(slot.get("count", 1))

		# Heat 2+ adds one extra to "any" slots (more bodies)
		if role == "any" and heat_level >= 2 and _rb(0.5):
			slot_count += 1

		var role_pool := _pool_for_role(pool, role)
		if role_pool.is_empty():
			role_pool = pool   # fallback to full pool if no matching role

		for _i in range(slot_count):
			if slots_filled >= count:
				break
			var enemy_def := _pick_from_pool(role_pool)
			var pos       := _find_spawn_pos(used_positions, map_w)
			if pos == Vector2i(-1, -1):
				break   # map full
			var spawn := _make_spawn(enemy_def, pos, floor_num, heat_level)
			spawns.append(spawn)
			used_positions.append(pos)
			slots_filled += 1

	#  Fill any remaining slots with random enemies
	var attempts := 0
	while slots_filled < count and attempts < 60:
		attempts += 1
		if pool.is_empty():
			break
		var enemy_def := _pick_from_pool(pool)
		var pos       := _find_spawn_pos(used_positions, map_w)
		if pos == Vector2i(-1, -1):
			break
		spawns.append(_make_spawn(enemy_def, pos, floor_num, heat_level))
		used_positions.append(pos)
		slots_filled += 1

	return spawns


## Build the eligible pool for this floor: filter by floor range, then apply
## spawn_chance gate. Returns Array of enemy definition Dicts (weighted).
func _eligible_pool(floor_num: int, run_seed: int) -> Array:
	# Save RNG state, use a separate seed for pool eligibility
	var saved_s := _s
	_s = ((run_seed * 777 + floor_num * 31337) * 1664525 + 1013904223) & 0xffffffff
	if _s == 0: _s = 1

	var pool: Array = []
	for e in ENEMY_POOL:
		if floor_num < e["floor_min"] or floor_num > e["floor_max"]:
			continue
		var chance: float = float(e.get("spawn_chance", 1.0))
		if chance < 1.0 and not _rb(chance):
			continue   # This enemy type rolled absent this floor
		# Add weighted copies
		for _w in range(int(e.get("weight", 1))):
			pool.append(e)

	# Restore main RNG state so tile generation is unaffected
	_s = saved_s

	if pool.is_empty():
		# Guaranteed fallback: void_cultist is always spawn_chance 1.0 on floors 1-6
		pool = [ENEMY_POOL[0]]
	return pool


func _pick_template(floor_num: int, pool: Array) -> Dictionary:
	# Filter to valid templates for this floor
	var valid: Array = []
	for t in ENCOUNTER_TEMPLATES:
		if floor_num < int(t["floor_min"]) or floor_num > int(t["floor_max"]):
			continue
		# Skip template if pool can't fill its primary role
		var ok := true
		for slot in t["slots"]:
			var role: String = str(slot.get("role","any"))
			if role != "any" and _pool_for_role(pool, role).is_empty():
				ok = false; break
		if ok:
			for _w in range(int(t.get("weight", 1))):
				valid.append(t)

	if valid.is_empty():
		return ENCOUNTER_TEMPLATES[0]   # Swarm fallback

	return valid[_ri(valid.size())]


func _pool_for_role(pool: Array, role: String) -> Array:
	if role == "any":
		return pool
	return pool.filter(func(e: Dictionary) -> bool:
		return str(e.get("role","any")) == role or str(e.get("role","any")) == "any")


func _pick_from_pool(pool: Array) -> Dictionary:
	return pool[_ri(pool.size())]


func _find_spawn_pos(used: Array, map_w: int) -> Vector2i:
	var attempts := 0
	while attempts < 50:
		attempts += 1
		var ex := _ri(map_w - 2) + 1
		var ey := _ri(3)           # rows 0-2
		var pos := Vector2i(ex, ey)
		if not used.has(pos):
			return pos
	return Vector2i(-1, -1)   # map full

#  SPAWN BUILDERS

func _make_spawn(enemy_def: Dictionary, pos: Vector2i,
		floor_num: int, heat_level: int) -> Dictionary:
	var spawn := {
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
		"role":       enemy_def.get("role", "any"),
	}
	return _scale_stats(spawn, floor_num, heat_level)


func _make_boss_anchor(floor_num: int, heat_level: int) -> Dictionary:
	var spawn := {
		"unit_id":    "void_anchor",
		"name":       "The Sleeping Anchor",
		"x": 5, "y": 0, "facing": "S",
		"hp":         600,
		"mp":         0,
		"move":       0,
		"jump":       0,
		"speed":      1,
		"physical":   0,
		"magic":      80,
		"max_temper": 0,
		"max_ether":  200,
		"abilities":  ["void_anchor_pulse"],
		"affinities": {"holy": 2.5, "fire": 0.15, "thunder": 0.15,
					   "water": 0.15, "dark": 0.0, "blizzard": 0.15},
		"is_anchor":           true,
		"is_anchor_guardian":  true,
		"cannot_move":         true,
		"role":                "heavy",
	}
	# Boss scales too, but more slowly  it's a stage objective, not a unit
	var hp_scale := 1.0 + float(heat_level) * 0.15
	spawn["hp"]        = roundi(600.0 * hp_scale)
	spawn["max_ether"] = roundi(200.0 * hp_scale)
	spawn["_floor_num"]  = floor_num
	spawn["_heat_level"] = heat_level
	return spawn

#  TERRAIN HELPERS

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
		if ty >= 6: continue
		tiles.append({"x": tx, "y": ty, "terrain": terrain, "height": 0})
		placed += 1


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
		"Thornspire Vault  The Sleeping Anchor",
	]
	return names[clamp(floor_num - 1, 0, names.size() - 1)]
