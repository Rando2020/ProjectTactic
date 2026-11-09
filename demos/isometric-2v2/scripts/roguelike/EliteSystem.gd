## EliteSystem.gd  Pure RefCounted. Floor-scaled elite rolls.
class_name EliteSystem
extends RefCounted

const TIERS: Dictionary = {
	"marked":   {"label":"Marked",   "hp_mult":1.4, "jp_mult":1.5, "col":Color(1.0,0.88,0.27)},
	"elite":    {"label":"Elite",    "hp_mult":1.7, "jp_mult":2.0, "col":Color(1.0,0.60,0.20)},
	"champion": {"label":"Champion", "hp_mult":2.2, "jp_mult":3.0, "col":Color(0.93,0.27,0.27)},
}

const FLOOR_RATES: Array[Dictionary] = [
	{"normal":0.78,"marked":0.14,"elite":0.06,"champion":0.02},
	{"normal":0.68,"marked":0.18,"elite":0.10,"champion":0.04},
	{"normal":0.58,"marked":0.22,"elite":0.14,"champion":0.06},
	{"normal":0.46,"marked":0.28,"elite":0.18,"champion":0.08},
	{"normal":0.36,"marked":0.30,"elite":0.22,"champion":0.12},
	{"normal":0.28,"marked":0.30,"elite":0.26,"champion":0.16},
	{"normal":0.20,"marked":0.30,"elite":0.30,"champion":0.20},
	{"normal":0.14,"marked":0.28,"elite":0.34,"champion":0.24},
	{"normal":0.08,"marked":0.24,"elite":0.36,"champion":0.32},
	{"normal":0.00,"marked":0.00,"elite":0.30,"champion":0.70},  # Boss floor
]

const PREFIXES: Array[Dictionary] = [
	{"id":"volatile",  "label":"Volatile",   "on_death":{"type":"explosion","damage":45}},
	{"id":"fortified", "label":"Fortified",  "stats":{"hp_mult":1.8,"resist":0.25}},
	{"id":"empowered", "label":"Empowered",  "stats":{"dmg_mult":1.4}},
	{"id":"siphoning", "label":"Siphoning",  "on_hit":{"type":"mp_drain","amount":20}},
	{"id":"cursed",    "label":"Cursed",     "on_hit":{"type":"status","status":"burn","chance":0.35}},
	{"id":"berserker", "label":"Berserking", "conditional":{"trigger":"hp_below_half","speed":3,"dmg":1.25}},
	{"id":"vampiric",  "label":"Vampiric",   "on_hit":{"type":"lifesteal","pct":0.30}},
	{"id":"shielded",  "label":"Shielded",   "on_spawn":{"type":"ether_shield"}},
]

const SUFFIXES: Array[Dictionary] = [
	{"id":"of_frost",    "label":"of Frost",     "on_spawn":"freeze_adjacent"},
	{"id":"of_storm",    "label":"of the Storm", "on_spawn":"electrify_water"},
	{"id":"of_flames",   "label":"of Flames",    "on_spawn":"ignite_spawn"},
	{"id":"of_the_pack", "label":"of the Pack",  "aura":"pack_leader"},
	{"id":"of_iron",     "label":"of Iron",      "status_immune":true},
	{"id":"of_shadows",  "label":"of Shadows",   "dodge":0.30},
	{"id":"of_the_void", "label":"of the Void",  "immune":["dark","resonance"]},
	{"id":"of_the_tide", "label":"of the Tide",  "on_spawn":"flood_adjacent"},
]

var _s: int = 0
func _rng() -> float:
	_s = (_s * 1664525 + 1013904223) & 0xffffffff
	return float(_s & 0xffffffff) / 4294967296.0

## Get elite spawn rates for a floor, scaled by heat level.
## heat_level 0 = base, each +1 shifts 3% from normal  champion.
func get_rates(floor_num: int, heat_level: int = 0) -> Dictionary:
	var base := FLOOR_RATES[clamp(floor_num - 1, 0, FLOOR_RATES.size() - 1)].duplicate()
	if heat_level <= 0: return base
	# Each heat level shifts 3% of normal chance to harder tiers
	var shift := minf(base["normal"] - 0.05, float(heat_level) * 0.03)
	base["normal"]   = base["normal"]   - shift
	base["elite"]    = base["elite"]    + shift * 0.5
	base["champion"] = base["champion"] + shift * 0.5
	return base

func roll_tier(unit_seed: int, floor_num: int) -> String:
	_s = unit_seed & 0xffffffff; if _s == 0: _s = 1
	var rates := get_rates(floor_num)
	var roll := _rng()
	if roll < rates["champion"]: return "champion"
	roll -= rates["champion"]
	if roll < rates["elite"]: return "elite"
	roll -= rates["elite"]
	if roll < rates["marked"]: return "marked"
	return "normal"

## Apply elite modifiers to a spawn dict in place. Returns modified dict.
func apply_to_spawn(spawn: Dictionary, run_seed: int, unit_idx: int, floor_num: int) -> Dictionary:
	var useed := (run_seed * 31 + unit_idx * 7919) & 0xffffffff
	var tier  := roll_tier(useed, floor_num)
	if tier == "normal": return spawn

	_s = useed
	var td: Dictionary = TIERS[tier]
	var result := spawn.duplicate(true)

	# Prefixes
	var num_pre := 2 if tier == "champion" else 1
	var pre_copy := PREFIXES.duplicate(); pre_copy.shuffle()
	var prefixes := pre_copy.slice(0, min(num_pre, pre_copy.size()))

	# Suffix
	var suffixes: Array = []
	if tier != "marked":
		suffixes.append(SUFFIXES[int(_rng() * SUFFIXES.size())])

	# Build name
	var pre_str := " ".join(prefixes.map(func(p: Dictionary) -> String: return p["label"]))
	var suf_str: String = (" " + suffixes[0]["label"]) if suffixes.size() > 0 else ""
	result["name"] = ("%s %s%s" % [pre_str, spawn.get("name","Enemy"), suf_str]).strip_edges()

	# Scale HP
	var hp_mult: float = td["hp_mult"]
	for p in prefixes:
		hp_mult *= p.get("stats",{}).get("hp_mult", 1.0)
	result["hp"]         = roundi(float(spawn.get("hp", 100)) * hp_mult)
	result["max_temper"] = roundi(float(spawn.get("max_temper", 50)) * float(td["hp_mult"]))
	result["max_ether"]  = roundi(float(spawn.get("max_ether", 50)) * float(td["hp_mult"]))

	result["elite_tier"]  = tier
	result["elite_color"] = td["col"]
	result["jp_mult"]     = spawn.get("jp_mult", 1.0) * td["jp_mult"]
	result["prefixes"]    = prefixes
	result["suffixes"]    = suffixes

	# Damage mult
	var dmg_mult := 1.0
	for p in prefixes: dmg_mult *= p.get("stats",{}).get("dmg_mult", 1.0)
	if dmg_mult > 1.0: result["dmg_mult"] = dmg_mult

	# Status immune / dodge from suffixes
	for suf in suffixes:
		if suf.get("status_immune", false): result["status_immune"] = true
		if suf.has("dodge"): result["dodge_chance"] = suf["dodge"]

	return result

## Apply to all spawns in a list.
func apply_to_floor(spawns: Array, run_seed: int, floor_num: int, heat_level: int = 0) -> Array:
	var result: Array = []
	var idx := 0
	for s in spawns:
		result.append(apply_to_spawn_with_heat(s.duplicate(true), run_seed, idx, floor_num, heat_level))
		idx += 1
	return result

func apply_to_spawn_with_heat(spawn: Dictionary, run_seed: int, unit_idx: int,
		floor_num: int, heat_level: int) -> Dictionary:
	var useed := (run_seed * 31 + unit_idx * 7919) & 0xffffffff
	var tier  := _roll_tier_with_rates(useed, get_rates(floor_num, heat_level))
	if tier == "normal": return spawn
	_s = useed; return _apply_tier(spawn, tier)

func _roll_tier_with_rates(unit_seed: int, rates: Dictionary) -> String:
	_s = unit_seed & 0xffffffff; if _s == 0: _s = 1
	var roll := _rng()
	if roll < rates["champion"]: return "champion"
	roll -= rates["champion"]
	if roll < rates["elite"]: return "elite"
	roll -= rates["elite"]
	if roll < rates["marked"]: return "marked"
	return "normal"

func _apply_tier(spawn: Dictionary, tier: String) -> Dictionary:
	var td: Dictionary = TIERS[tier]
	var result := spawn.duplicate(true)
	var pre_copy := PREFIXES.duplicate(); pre_copy.shuffle()
	var prefixes := pre_copy.slice(0, 2 if tier == "champion" else 1)
	var suffixes: Array = []
	if tier != "marked": suffixes.append(SUFFIXES[int(_rng() * SUFFIXES.size())])
	var pre_str := " ".join(prefixes.map(func(p: Dictionary) -> String: return p["label"]))
	var suf_str: String = (" " + suffixes[0]["label"]) if suffixes.size() > 0 else ""
	result["name"] = ("%s %s%s" % [pre_str, spawn.get("name","Enemy"), suf_str]).strip_edges()
	var hp_mult: float = td["hp_mult"]
	for p in prefixes: hp_mult *= p.get("stats",{}).get("hp_mult", 1.0)
	result["hp"]         = roundi(float(spawn.get("hp", 100)) * hp_mult)
	result["max_temper"] = roundi(float(spawn.get("max_temper", 50)) * float(td["hp_mult"]))
	result["max_ether"]  = roundi(float(spawn.get("max_ether", 50)) * float(td["hp_mult"]))
	result["elite_tier"] = tier; result["elite_color"] = td["col"]
	result["jp_mult"]    = spawn.get("jp_mult", 1.0) * td["jp_mult"]
	result["prefixes"]   = prefixes; result["suffixes"] = suffixes
	var dmg_mult := 1.0
	for p in prefixes: dmg_mult *= p.get("stats",{}).get("dmg_mult", 1.0)
	if dmg_mult > 1.0: result["dmg_mult"] = dmg_mult
	for suf in suffixes:
		if suf.get("status_immune", false): result["status_immune"] = true
		if suf.has("dodge"): result["dodge_chance"] = suf["dodge"]
	return result
