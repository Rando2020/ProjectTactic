## LootSystem.gd  Diablo-style item generation. Pure RefCounted.
class_name LootSystem
extends RefCounted

const RARITIES := {
	"common":   {"label":"Common",   "color":Color(0.70,0.76,0.82),"affixes":1,"weight":55},
	"uncommon": {"label":"Uncommon", "color":Color(0.30,0.86,0.50),"affixes":2,"weight":28},
	"rare":     {"label":"Rare",     "color":Color(0.98,0.75,0.14),"affixes":3,"weight":14},
	"resonant": {"label":"Resonant", "color":Color(0.75,0.32,0.97),"affixes":4,"weight":3 },
}

const BASES := [
	{"id":"blade",   "name":"Blade",   "slot":"weapon",    "icon":"*"},
	{"id":"staff",   "name":"Staff",   "slot":"weapon",    "icon":"*"},
	{"id":"tome",    "name":"Tome",    "slot":"weapon",    "icon":"*"},
	{"id":"talisman","name":"Talisman","slot":"accessory", "icon":"*"},
	{"id":"ring",    "name":"Ring",    "slot":"accessory", "icon":"*"},
	{"id":"ward",    "name":"Ward",    "slot":"charm",     "icon":"*"},
	{"id":"rune",    "name":"Rune",    "slot":"charm",     "icon":"*"},
]

const ADJS := {
	"common":  ["Dull","Worn","Plain"],
	"uncommon":["Sharp","Polished","Keen"],
	"rare":    ["Gleaming","Wrathful","Ancient"],
	"resonant":["Eidolon","Resonant","Vaelthar"],
}

const AFFIXES := [
	{"id":"phys",  "label":"+{n} Physical",     "roll":[4,18], "weight":15},
	{"id":"mag",   "label":"+{n} Magic",         "roll":[4,18], "weight":15},
	{"id":"hp",    "label":"+{n} Max HP",         "roll":[20,60],"weight":14},
	{"id":"tmpr",  "label":"+{n} Max Temper",     "roll":[10,35],"weight":10},
	{"id":"fire",  "label":"+{n}% Fire Damage",   "roll":[8,28], "weight":8 },
	{"id":"thun",  "label":"+{n}% Thunder Damage","roll":[8,28], "weight":8 },
	{"id":"holy",  "label":"+{n}% Holy Damage",   "roll":[8,28], "weight":6 },
	{"id":"dark",  "label":"+{n}% Dark Damage",   "roll":[8,28], "weight":6 },
	{"id":"jp",    "label":"+{n}% JP Gain",        "roll":[10,30],"weight":7 },
	{"id":"spd",   "label":"+{n} Speed",           "roll":[1,3],  "weight":5 },
	{"id":"kill_hp","label":"On kill: +{n} HP",   "roll":[15,35],"weight":6 },
]

var _s: int = 0
func _rng() -> float:
	_s = (_s * 1664525 + 1013904223) & 0xffffffff
	return float(_s & 0xffffffff) / 4294967296.0

func _pick(arr: Array) -> Variant:
	return arr[int(_rng() * arr.size())]

func generate_item(item_seed: int, rarity_bonus: float = 0.0) -> Dictionary:
	_s = item_seed & 0xffffffff; if _s == 0: _s = 1

	# Roll rarity
	var rpool: Array = []
	for r in RARITIES:
		var w: int = RARITIES[r]["weight"]
		if r == "common": w = maxi(5, w - int(rarity_bonus * 40))
		else: w = w + int(rarity_bonus * 10)
		for _i in range(w): rpool.append(r)
	var rarity: String = rpool[int(_rng() * rpool.size())]
	var rd: Dictionary = RARITIES[rarity]

	var base: Dictionary = _pick(BASES)
	var adj:  String     = _pick(ADJS[rarity])

	# Roll affixes
	var affixes: Array = []
	var used:    Array = []
	for _i in range(rd["affixes"] * 3):
		if affixes.size() >= rd["affixes"]: break
		var pool := AFFIXES.filter(func(a: Dictionary) -> bool: return not used.has(a["id"]))
		if pool.is_empty(): break
		var total: int = pool.reduce(func(s: int, a: Dictionary) -> int: return s + a["weight"], 0)
		var roll := int(_rng() * total)
		var chosen: Dictionary = pool[0]
		for a in pool: roll -= a["weight"]; if roll <= 0: chosen = a; break
		var n := int(chosen["roll"][0] + _rng() * (chosen["roll"][1] - chosen["roll"][0]))
		affixes.append({"id":chosen["id"], "label":chosen["label"].replace("{n}", str(n)), "value":n})
		used.append(chosen["id"])

	return {
		"id":      "item_%d_%s" % [item_seed, rarity],
		"name":    "%s %s" % [adj, base["name"]],
		"slot":    base["slot"],
		"icon":    base["icon"],
		"rarity":  rarity,
		"color":   rd["color"],
		"label":   rd["label"],
		"affixes": affixes,
	}

func generate_battle_loot(defeated: Array, run_seed: int, floor_num: int) -> Array:
	var drops: Array = []
	var rarity_bonus := minf(0.6, float(floor_num) * 0.06)
	for i in defeated.size():
		_s = ((run_seed * 997 + i * 6271) & 0xffffffff)
		var is_elite: bool = defeated[i].get("elite_tier","") != ""
		if _rng() < (0.75 if is_elite else 0.12):
			var eb := 0.3 if defeated[i].get("elite_tier","") == "champion" else (0.15 if is_elite else 0.0)
			drops.append(generate_item((run_seed * 997 + i * 6271 + 2) & 0xffffffff, rarity_bonus + eb))
	return drops
