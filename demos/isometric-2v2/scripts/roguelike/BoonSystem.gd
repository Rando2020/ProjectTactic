## BoonSystem.gd  32 Guardian boons, 4 tiers. Pure RefCounted.
class_name BoonSystem
extends RefCounted

const RARITIES: Dictionary = {
	"common":    {"label":"Common",    "color":Color(0.70,0.76,0.82), "weight":55},
	"rare":      {"label":"Rare",      "color":Color(0.98,0.75,0.14), "weight":30},
	"legendary": {"label":"Legendary", "color":Color(0.66,0.33,0.97), "weight":12},
	"unique":    {"label":"Unique",    "color":Color(0.93,0.27,0.27), "weight": 3},
}

const BOON_LANE_LIMITS: Dictionary = {
	"movement": 2,
}

static func boon_lane(boon: Dictionary) -> String:
	var explicit_lane := str(boon.get("lane", ""))
	if not explicit_lane.is_empty():
		return explicit_lane
	var effect: Dictionary = boon.get("effect", {})
	if effect.get("type", "") == "stat_bonus" and str(effect.get("stat", "")) in ["move", "movement"]:
		return "movement"
	if int(effect.get("move_bonus", 0)) > 0:
		return "movement"
	if effect.get("type", "") == "tactical" and str(effect.get("id", "")) in ["battle_fury", "iron_momentum", "reaping_step"]:
		return "movement"
	return ""

static func boon_lane_limit(lane: String) -> int:
	return int(BOON_LANE_LIMITS.get(lane, 999))

static func boons_in_lane(active_boons: Array, lane: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if lane.is_empty():
		return result
	for boon: Dictionary in active_boons:
		if boon_lane(boon) == lane:
			result.append(boon)
	return result

static func needs_lane_replacement(active_boons: Array, incoming_boon: Dictionary) -> bool:
	var lane := boon_lane(incoming_boon)
	if lane.is_empty():
		return false
	return boons_in_lane(active_boons, lane).size() >= boon_lane_limit(lane)
const BOONS: Array[Dictionary] = [
	# Common
	{"id":"ignareth_warmth",  "name":"Ignareth's Warmth",  "rarity":"common",  "icon":"*","guardian":"ignareth",
	 "desc":"Fire +20% dmg. Burning lasts 1 extra turn.", "effect":{"type":"elemental_bonus","element":"fire","bonus":0.20}},
	{"id":"nerevan_touch",    "name":"Nerevan's Touch",    "rarity":"common",  "icon":"*","guardian":"nerevan",
	 "desc":"Water +20% dmg. Wet terrain grants Regen.", "effect":{"type":"elemental_bonus","element":"water","bonus":0.20}},
	{"id":"torvahk_rhythm",   "name":"Torvahk's Rhythm",  "rarity":"common",  "icon":"*","guardian":"torvahk",
	 "desc":"Thunder +20% dmg. Chain arcs +1 tile.", "effect":{"type":"elemental_bonus","element":"thunder","bonus":0.20,"chain_bonus":1}},
	{"id":"luminarch_light",  "name":"Luminarch's Light",  "rarity":"common",  "icon":"*","guardian":"luminarch",
	 "desc":"Holy +20% dmg. Heals +15 HP.", "effect":{"type":"elemental_bonus","element":"holy","bonus":0.20,"heal_bonus":15}},
	{"id":"vaelthorn_shadow", "name":"Vaelthorn's Shadow", "rarity":"common",  "icon":"*","guardian":"vaelthorn",
	 "desc":"Dark +20% dmg. Void Scar drains +20 Ether.", "effect":{"type":"elemental_bonus","element":"dark","bonus":0.20}},
	{"id":"iron_temper",      "name":"Iron Temper",        "rarity":"common",  "icon":"*",
	 "desc":"All party: +40 max Temper and +1 Move this run.", "effect":{"type":"stat_bonus","stat":"max_temper","amount":40,"move_bonus":1}},
	{"id":"swift_recovery",   "name":"Swift Recovery",     "rarity":"common",  "icon":"*",
	 "desc":"After each battle, restore 25% max HP.", "effect":{"type":"between_battle_heal","percent":0.25}},
	{"id":"windrunner_step",  "name":"Windrunner Step",   "rarity":"common",  "icon":"+",
	 "desc":"All party: +1 Move this run. Repositioning feels better immediately.", "effect":{"type":"stat_bonus","stat":"move","amount":1}},
	{"id":"surge_extend",     "name":"Resonant Surge",     "rarity":"common",  "icon":"*",
	 "desc":"SURGE window +20% wider. SURGE bonus +35%.", "effect":{"type":"surge_boost","window_bonus":0.20,"damage_bonus":0.35}},
	# Rare
	{"id":"ignareth_brand",   "name":"Ignareth's Brand",   "rarity":"rare",    "icon":"*","guardian":"ignareth",
	 "desc":"Burning enemies take 50% extra physical damage.", "effect":{"type":"passive","id":"brand","bonus":0.50}},
	{"id":"torvahk_patience", "name":"Torvahk's Patience", "rarity":"rare",    "icon":"*","guardian":"torvahk",
	 "desc":"SURGE window +30%. SURGE bonus +40%.", "effect":{"type":"surge_boost","window_bonus":0.30,"damage_bonus":0.40}},
	{"id":"vaelthorn_bargain","name":"Vaelthorn's Bargain", "rarity":"rare",    "icon":"*","guardian":"vaelthorn",
	 "desc":"Sacrifice 20% HP at battle start. Deal 40% more damage.", "effect":{"type":"battle_start","trigger":"vaelthorn_bargain","hp_cost":0.20,"damage_bonus":0.40}},
	{"id":"luminarch_grace",  "name":"Luminarch's Grace",  "rarity":"rare",    "icon":"*","guardian":"luminarch",
	 "desc":"Party starts Blessed (3t). +30% HP between battles.", "effect":{"type":"battle_start","apply_status":"blessed","turns":3,"target":"party"}},
	{"id":"jp_accelerator",   "name":"JP Accelerator",     "rarity":"rare",    "icon":"*",
	 "desc":"All JP gains doubled this run.", "effect":{"type":"jp_multiplier","mult":2.0}},
	{"id":"champions_grit",   "name":"Champion's Grit",    "rarity":"rare",    "icon":"*",
	 "desc":"Elite kills restore 30 HP + 20 Temper to killer.", "effect":{"type":"on_elite_kill","heal_hp":30,"heal_temper":20}},
	{"id":"void_sight",       "name":"Void Sight",         "rarity":"rare",    "icon":"*",
	 "desc":"Enemy elite affixes revealed before each battle.", "effect":{"type":"reveal_elites"}},
	{"id":"double_strike",    "name":"Double Strike",      "rarity":"rare",    "icon":"*",
	 "desc":"Basic attacks 25% chance to hit twice.", "effect":{"type":"passive","id":"double_strike","chance":0.25}},
	{"id":"ashvale_resolve",  "name":"Ashvale Resolve",    "rarity":"rare",    "icon":"*",
	 "desc":"First hit each battle cannot reduce HP below 1.", "effect":{"type":"passive","id":"first_hit_guard"}},
	{"id":"reedfolk_reading", "name":"Reedfolk's Reading", "rarity":"rare",    "icon":"*",
	 "desc":"Reveals all elite affixes. Wet effects last +2 turns.", "effect":{"type":"reveal_elites"}},
	# Legendary
	{"id":"ignareth_roar",    "name":"Ignareth's Roar",    "rarity":"legendary","icon":"*","guardian":"ignareth",
	 "desc":"First fire ability auto-SURGEs. Burning tiles detonate (35 dmg).", "effect":{"type":"passive","id":"ignareth_roar","element":"fire","detonate":35}},
	{"id":"torvahk_fury",     "name":"Torvahk's Fury",     "rarity":"legendary","icon":"*","guardian":"torvahk",
	 "desc":"Stunned units lose 20 HP. Stun lasts +1 turn.", "effect":{"type":"passive","id":"torvahk_fury","stun_drain":20,"stun_extra":1}},
	{"id":"luminarch_judgment","name":"Luminarch's Judgment","rarity":"legendary","icon":"*","guardian":"luminarch",
	 "desc":"Enemy deaths flare 28 holy damage to all adjacent.", "effect":{"type":"passive","id":"death_flare","damage":28}},
	{"id":"vaelthorn_echo",   "name":"Vaelthorn's Echo",   "rarity":"legendary","icon":"*","guardian":"vaelthorn",
	 "desc":"Status expiry deals 35 dark damage.", "effect":{"type":"passive","id":"vaelthorn_echo","damage":35}},
	{"id":"elemental_echo",   "name":"Elemental Echo",     "rarity":"legendary","icon":"*",
	 "desc":"25% chance for any reaction to trigger twice.", "effect":{"type":"reaction_echo","chance":0.25}},
	{"id":"phoenix_vitality", "name":"Phoenix Vitality",   "rarity":"legendary","icon":"*",
	 "desc":"First 0-HP party member survives at 1 HP (once/battle).", "effect":{"type":"once_per_battle","outcome":"survive_at_1_hp"}},
	# Unique  Guardian Channelling (floor 4+ only)
	{"id":"ignareth_unchained","name":"Ignareth Unchained","rarity":"unique",  "icon":"*","guardian":"ignareth",
	 "desc":"All terrain ignites at battle start. Fire 2x damage. Party takes 8% HP fire/turn.",
	 "flavour":"The Eternal Flame does not distinguish friend from kindling.",
	 "effect":{"type":"battle_start","trigger":"ignite_all_terrain","fire_mult":2.0,"self_dmg":0.08}},
	{"id":"nerevan_veil",     "name":"Nerevan's Veil",     "rarity":"unique",  "icon":"*","guardian":"nerevan",
	 "desc":"3x3 tide at battle start. Party heals 12% HP/turn on water.",
	 "flavour":"The Mirefen does not flood. It remembers its original depth.",
	 "effect":{"type":"battle_start","trigger":"summon_tide","water_heal":0.12}},
	{"id":"torvahk_unchained","name":"Torvahk Unchained",  "rarity":"unique",  "icon":"*","guardian":"torvahk",
	 "desc":"Lightning arcs to nearest enemy each turn (30 dmg, 30% stun). Electrified water deals 55 dmg.",
	 "flavour":"They recorded 47 lightning strikes. They were all the same bolt.",
	 "effect":{"type":"battle_start","trigger":"lightning_aura","arc_damage":30,"arc_stun":0.30,"electrify_damage":55}},
	{"id":"luminarch_covenant","name":"Luminarch's Covenant","rarity":"unique", "icon":"*","guardian":"luminarch",
	 "desc":"Party can never be reduced below 1 HP by a single hit. Anchors heal party 50 HP when struck.",
	 "flavour":"We found Luminarch's seal at the base of the Thornspire.",
	 "effect":{"type":"passive","id":"luminarch_covenant","min_hp":1,"anchor_heal":50}},
	{"id":"vaelthorn_unchained","name":"Vaelthorn Unchained","rarity":"unique","icon":"*","guardian":"vaelthorn",
	 "desc":"All enemies start Cursed (2t). Kills restore 25 Ether + 10 HP to attacker.",
	 "flavour":"The Null Conclave did not corrupt Vaelthorn. Vaelthorn was waiting for them.",
	 "effect":{"type":"battle_start","trigger":"vaelthorn_curse_all","on_kill":{"ether":25,"hp":10}}},
]

##  Tactical Boons
## Hades-style boons that change HOW attacks work, not just stat numbers.
const TACTICAL_BOONS: Array[Dictionary] = [
	# Common
	{"id":"knocking_blow",   "name":"Knocking Blow",   "rarity":"common",    "icon":"*",
	 "category":"tactical",
	 "desc":"50% chance on hit: hurl the target 1 tile away from you.",
	 "effect":{"type":"tactical","id":"knockback","chance":0.50}},

	# Rare
	{"id":"cleaving_strikes","name":"Cleaving Strikes", "rarity":"rare",     "icon":"*",
	 "category":"tactical",
	 "desc":"Attacks strike the two tiles flanking your target  3-wide cleave arc.",
	 "effect":{"type":"tactical","id":"cleave"}},

	{"id":"piercing_rush",   "name":"Piercing Rush",    "rarity":"rare",     "icon":"*",
	 "category":"tactical",
	 "desc":"Attacks pierce the primary target and hit anyone standing directly behind them.",
	 "effect":{"type":"tactical","id":"piercing_line"}},

	{"id":"echo_strike",     "name":"Echo Strike",      "rarity":"rare",     "icon":"*",
	 "category":"tactical",
	 "desc":"35% chance after a hit: strike the same target a second time at full power.",
	 "effect":{"type":"tactical","id":"echo_strike","chance":0.35}},

	{"id":"battle_fury",     "name":"Battle Fury",      "rarity":"rare",     "icon":"*",
	 "category":"tactical",
	 "desc":"Moving before attacking this turn adds 30% bonus damage to that strike.",
	 "effect":{"type":"tactical","id":"battle_fury","bonus":0.30}, "lane":"movement"},

	{"id":"sundering_blow",  "name":"Sundering Blow",   "rarity":"rare",     "icon":"*",
	 "category":"tactical",
	 "desc":"Each hit permanently reduces the target's max Temper by 20.",
	 "effect":{"type":"tactical","id":"sundering","amount":20}},

	{"id":"iron_momentum",   "name":"Iron Momentum",    "rarity":"rare",     "icon":"*",
	 "category":"tactical",
	 "desc":"Moving 3 or more tiles before attacking adds 30% bonus damage.",
	 "effect":{"type":"tactical","id":"iron_momentum","min_move":3}, "lane":"movement"},

	# Legendary
	{"id":"coup_de_grace",   "name":"Coup de Grace",    "rarity":"legendary","icon":"*",
	 "category":"tactical",
	 "desc":"Attacks against enemies below 30% HP deal 75% bonus damage.",
	 "effect":{"type":"tactical","id":"coup_de_grace","threshold":0.30,"bonus":0.75}},

	{"id":"bloodthirst",     "name":"Bloodthirst",      "rarity":"legendary","icon":"*",
	 "category":"tactical",
	 "desc":"Recover HP equal to 30% of all damage you deal.",
	 "effect":{"type":"tactical","id":"bloodthirst","percent":0.30}},

	{"id":"ruinous_field",   "name":"Ruinous Field",    "rarity":"legendary","icon":"*",
	 "category":"tactical",
	 "desc":"Every 3rd successful hit ignites the ground under your target.",
	 "effect":{"type":"tactical","id":"ruinous_field","interval":3}},

	{"id":"reaping_step",    "name":"Reaping Step",     "rarity":"legendary","icon":"*",
	 "category":"tactical",
	 "desc":"Killing an enemy grants a free move of up to 3 tiles.",
	 "effect":{"type":"tactical","id":"reaping_step","range":3}, "lane":"movement"},

	# Unique
	{"id":"wrath_crescendo", "name":"Wrath Crescendo",  "rarity":"unique",   "icon":"*",
	 "category":"tactical",
	 "desc":"Each kill this battle increases your damage by 8% (stacks up to 10x, resets each battle).",
	 "flavour":"The mountain does not tire. It simply accumulates.",
	 "effect":{"type":"tactical","id":"wrath_crescendo","per_kill":0.08}},
]

const STYLE_BOONS: Array[Dictionary] = [
	# Common Sigil-friendly build shapers
	{"id":"vanguard_bulwark", "name":"Vanguard Bulwark", "rarity":"common", "icon":"+",
	 "category":"style", "tags":["physical", "guard", "temper"],
	 "desc":"Party gains +30 max Temper. Best for front-line physical jobs.",
	 "effect":{"type":"stat_bonus", "stat":"max_temper", "amount":30}},

	{"id":"arcanist_reservoir", "name":"Arcanist Reservoir", "rarity":"common", "icon":"+",
	 "category":"style", "tags":["magic", "ether", "surge"],
	 "desc":"SURGE window +15%. SURGE damage +20%. Helps spell turns land cleanly.",
	 "effect":{"type":"surge_boost", "window_bonus":0.15, "damage_bonus":0.20}},

	{"id":"duelist_footwork", "name":"Duelist Footwork", "rarity":"common", "icon":"+",
	 "category":"style", "tags":["flank", "speed", "physical"],
	 "desc":"Party gains +1 Move. Better angles, better back attacks.",
	 "effect":{"type":"stat_bonus", "stat":"move", "amount":1}, "lane":"movement"},

	{"id":"ranger_sightline", "name":"Ranger Sightline", "rarity":"common", "icon":"+",
	 "category":"style", "tags":["range", "line", "accuracy"],
	 "desc":"Attacks pierce the primary target and hit a unit directly behind them.",
	 "effect":{"type":"tactical", "id":"piercing_line"}},

	{"id":"cantor_litany", "name":"Cantor's Litany", "rarity":"common", "icon":"+",
	 "category":"style", "tags":["heal", "support", "survive"],
	 "desc":"After each battle, restore 18% max HP.",
	 "effect":{"type":"between_battle_heal", "percent":0.18}},

	{"id":"marauder_shove", "name":"Marauder Shove", "rarity":"common", "icon":"+",
	 "category":"style", "tags":["knockback", "physical"],
	 "desc":"35% chance on hit: hurl the target 1 tile away from you.",
	 "effect":{"type":"tactical", "id":"knockback", "chance":0.35}},

	# Rare Sigil payoffs
	{"id":"vanguard_counterstance", "name":"Vanguard Counterstance", "rarity":"rare", "icon":"+",
	 "category":"style", "tags":["physical", "counter", "guard"],
	 "desc":"Basic attacks gain an 18% chance to strike twice.",
	 "effect":{"type":"passive", "id":"double_strike", "chance":0.18}},

	{"id":"arcanist_overflow", "name":"Arcanist Overflow", "rarity":"rare", "icon":"+",
	 "category":"style", "tags":["magic", "ether", "elemental"],
	 "desc":"15% chance for any elemental reaction to trigger twice.",
	 "effect":{"type":"reaction_echo", "chance":0.15}},

	{"id":"duelist_execution", "name":"Duelist Execution", "rarity":"rare", "icon":"+",
	 "category":"style", "tags":["flank", "execute", "physical"],
	 "desc":"Attacks against enemies below 40% HP deal 35% bonus damage.",
	 "effect":{"type":"tactical", "id":"coup_de_grace", "threshold":0.40, "bonus":0.35}},

	{"id":"ranger_broadhead", "name":"Ranger Broadhead", "rarity":"rare", "icon":"+",
	 "category":"style", "tags":["range", "accuracy", "physical"],
	 "desc":"Each hit permanently reduces the target's max Temper by 15.",
	 "effect":{"type":"tactical", "id":"sundering", "amount":15}},

	{"id":"cantor_grace", "name":"Cantor's Grace", "rarity":"rare", "icon":"+",
	 "category":"style", "tags":["heal", "support", "survive"],
	 "desc":"First 0-HP party member survives at 1 HP once per battle.",
	 "effect":{"type":"once_per_battle", "outcome":"survive_at_1_hp"}},

	{"id":"marauder_cleave", "name":"Marauder Cleave", "rarity":"rare", "icon":"+",
	 "category":"style", "tags":["cleave", "physical"],
	 "desc":"Attacks strike the two tiles flanking your target.",
	 "effect":{"type":"tactical", "id":"cleave"}},
]
func _all_boons() -> Array:
	var combined: Array = []
	combined.append_array(BOONS)
	combined.append_array(TACTICAL_BOONS)
	combined.append_array(STYLE_BOONS)
	return combined

var _s: int = 0
func _rng() -> float:
	_s = (_s * 1664525 + 1013904223) & 0xffffffff
	return float(_s & 0xffffffff) / 4294967296.0

## Generate 3 boon offers for a floor. Floor scales rarity weights.
func generate_offers(rng_seed: int, floor_num: int, owned_ids: Array, loadout_bonus: Dictionary = {}) -> Array:
	_s = rng_seed & 0xffffffff; if _s == 0: _s = 1

	var weights := {
		"common":    max(10, 55 - (floor_num - 1) * 5),
		"rare":      25 + (floor_num - 1) * 3,
		"legendary": 10 + (floor_num - 1) * 2,
		"unique":    (floor_num - 3) * 2 if floor_num >= 4 else 0,
	}
	var rarity_weights: Dictionary = loadout_bonus.get("rarity_weights", {})
	for rarity_key in rarity_weights.keys():
		if weights.has(rarity_key):
			weights[rarity_key] = maxi(0, int(round(float(weights[rarity_key]) * float(rarity_weights[rarity_key]))))
	var rpool: Array[String] = []
	for r in weights: for _i in range(weights[r]): rpool.append(r)

	var all := _all_boons()
	var offers: Array = []
	var used: Array  = owned_ids.duplicate()

	for _slot in range(3):
		for _attempt in range(8):
			var rarity: String = rpool[int(_rng() * rpool.size())]
			var pool := all.filter(func(b: Dictionary) -> bool:
				return b["rarity"] == rarity and not used.has(b["id"]))
			if pool.is_empty(): continue
			var boon: Dictionary = _weighted_boon_pick(pool, loadout_bonus)
			used.append(boon["id"]); offers.append(boon); break

	while offers.size() < 3:
		var commons := all.filter(func(b: Dictionary) -> bool:
			return b["rarity"] == "common" and not used.has(b["id"]))
		if commons.is_empty(): break
		var fallback_boon: Dictionary = _weighted_boon_pick(commons, loadout_bonus)
		used.append(fallback_boon["id"]); offers.append(fallback_boon)

	return offers

func _weighted_boon_pick(pool: Array, loadout_bonus: Dictionary) -> Dictionary:
	if pool.is_empty():
		return {}
	if loadout_bonus.is_empty():
		return pool[int(_rng() * pool.size())]
	var total := 0.0
	var weighted: Array[Dictionary] = []
	for boon: Dictionary in pool:
		var weight := _loadout_multiplier(boon, loadout_bonus)
		total += weight
		weighted.append({"boon": boon, "weight": weight})
	var roll := _rng() * total
	var cursor := 0.0
	for entry: Dictionary in weighted:
		cursor += float(entry.get("weight", 1.0))
		if roll <= cursor:
			return entry.get("boon", {})
	return weighted.back().get("boon", {})

func _loadout_multiplier(boon: Dictionary, loadout_bonus: Dictionary) -> float:
	var mult := 1.0
	var guardian := str(boon.get("guardian", ""))
	var effect: Dictionary = boon.get("effect", {})
	var element := str(effect.get("element", ""))
	var guardian_weights: Dictionary = loadout_bonus.get("guardian_weights", {})
	var element_weights: Dictionary = loadout_bonus.get("element_weights", {})
	var tag_weights: Dictionary = loadout_bonus.get("tag_weights", {})
	if not guardian.is_empty():
		mult *= float(guardian_weights.get(guardian, 1.0))
	if not element.is_empty():
		mult *= float(element_weights.get(element, 1.0))
	for tag in _boon_tags(boon):
		mult *= float(tag_weights.get(tag, 1.0))
	return maxf(0.05, mult)

func _boon_tags(boon: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	var id := str(boon.get("id", ""))
	var desc := str(boon.get("desc", "")).to_lower()
	var category := str(boon.get("category", ""))
	for explicit_tag in boon.get("tags", []):
		tags.append(str(explicit_tag))
	var effect: Dictionary = boon.get("effect", {})
	var effect_type := str(effect.get("type", ""))
	var effect_id := str(effect.get("id", ""))
	if not category.is_empty(): tags.append(category)
	if effect_type == "elemental_bonus": tags.append("elemental")
	if effect_type == "surge_boost" or id.contains("surge"): tags.append("surge")
	if effect_type == "between_battle_heal" or desc.contains("heal") or desc.contains("regen"): tags.append("heal")
	if desc.contains("temper"): tags.append("temper")
	if desc.contains("cannot reduce") or desc.contains("survive") or desc.contains("blessed"): tags.append("survive")
	if desc.contains("damage") or desc.contains("dmg"): tags.append("damage")
	if desc.contains("physical"): tags.append("physical")
	if desc.contains("stun"): tags.append("stun")
	if desc.contains("curse") or effect_id.contains("curse"): tags.append("curse")
	if desc.contains("ether"): tags.append("ether")
	if effect_id in ["knockback", "cleave", "piercing_line", "echo_strike", "battle_fury", "sundering", "iron_momentum", "coup_de_grace", "bloodthirst", "ruinous_field", "reaping_step", "wrath_crescendo"]:
		match effect_id:
			"knockback": tags.append("knockback")
			"cleave": tags.append("cleave")
			"piercing_line": tags.append("line")
			"coup_de_grace": tags.append("execute")
			"reaping_step": tags.append("speed"); tags.append("kill")
			"bloodthirst": tags.append("heal")
			_: tags.append("physical")
	return tags
func get_boon(boon_id: String) -> Dictionary:
	for b: Dictionary in _all_boons():
		if b["id"] == boon_id: return b
	return {}
