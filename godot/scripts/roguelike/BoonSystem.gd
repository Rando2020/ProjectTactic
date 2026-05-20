## BoonSystem.gd — 32 Guardian boons, 4 tiers. Pure RefCounted.
class_name BoonSystem
extends RefCounted

const RARITIES: Dictionary = {
	"common":    {"label":"Common",    "color":Color(0.70,0.76,0.82), "weight":55},
	"rare":      {"label":"Rare",      "color":Color(0.98,0.75,0.14), "weight":30},
	"legendary": {"label":"Legendary", "color":Color(0.66,0.33,0.97), "weight":12},
	"unique":    {"label":"Unique",    "color":Color(0.93,0.27,0.27), "weight": 3},
}

const BOONS: Array[Dictionary] = [
	# Common
	{"id":"ignareth_warmth",  "name":"Ignareth's Warmth",  "rarity":"common",  "icon":"🔥","guardian":"ignareth",
	 "desc":"Fire +20% dmg. Burning lasts 1 extra turn.", "effect":{"type":"elemental_bonus","element":"fire","bonus":0.20}},
	{"id":"nerevan_touch",    "name":"Nerevan's Touch",    "rarity":"common",  "icon":"🌊","guardian":"nerevan",
	 "desc":"Water +20% dmg. Wet terrain grants Regen.", "effect":{"type":"elemental_bonus","element":"water","bonus":0.20}},
	{"id":"torvahk_rhythm",   "name":"Torvahk's Rhythm",  "rarity":"common",  "icon":"⚡","guardian":"torvahk",
	 "desc":"Thunder +20% dmg. Chain arcs +1 tile.", "effect":{"type":"elemental_bonus","element":"thunder","bonus":0.20,"chain_bonus":1}},
	{"id":"luminarch_light",  "name":"Luminarch's Light",  "rarity":"common",  "icon":"✨","guardian":"luminarch",
	 "desc":"Holy +20% dmg. Heals +15 HP.", "effect":{"type":"elemental_bonus","element":"holy","bonus":0.20,"heal_bonus":15}},
	{"id":"vaelthorn_shadow", "name":"Vaelthorn's Shadow", "rarity":"common",  "icon":"💀","guardian":"vaelthorn",
	 "desc":"Dark +20% dmg. Void Scar drains +20 Ether.", "effect":{"type":"elemental_bonus","element":"dark","bonus":0.20}},
	{"id":"iron_temper",      "name":"Iron Temper",        "rarity":"common",  "icon":"🛡",
	 "desc":"All party: +40 max Temper this run.", "effect":{"type":"stat_bonus","stat":"max_temper","amount":40}},
	{"id":"swift_recovery",   "name":"Swift Recovery",     "rarity":"common",  "icon":"💚",
	 "desc":"After each battle, restore 25% max HP.", "effect":{"type":"between_battle_heal","percent":0.25}},
	{"id":"surge_extend",     "name":"Resonant Surge",     "rarity":"common",  "icon":"⚡",
	 "desc":"SURGE window +20% wider. SURGE bonus +35%.", "effect":{"type":"surge_boost","window_bonus":0.20,"damage_bonus":0.35}},
	# Rare
	{"id":"ignareth_brand",   "name":"Ignareth's Brand",   "rarity":"rare",    "icon":"🔥","guardian":"ignareth",
	 "desc":"Burning enemies take 50% extra physical damage.", "effect":{"type":"passive","id":"brand","bonus":0.50}},
	{"id":"torvahk_patience", "name":"Torvahk's Patience", "rarity":"rare",    "icon":"⚡","guardian":"torvahk",
	 "desc":"SURGE window +30%. SURGE bonus +40%.", "effect":{"type":"surge_boost","window_bonus":0.30,"damage_bonus":0.40}},
	{"id":"vaelthorn_bargain","name":"Vaelthorn's Bargain", "rarity":"rare",    "icon":"💀","guardian":"vaelthorn",
	 "desc":"Sacrifice 20% HP at battle start. Deal 40% more damage.", "effect":{"type":"battle_start","trigger":"vaelthorn_bargain","hp_cost":0.20,"damage_bonus":0.40}},
	{"id":"luminarch_grace",  "name":"Luminarch's Grace",  "rarity":"rare",    "icon":"✨","guardian":"luminarch",
	 "desc":"Party starts Blessed (3t). +30% HP between battles.", "effect":{"type":"battle_start","apply_status":"blessed","turns":3,"target":"party"}},
	{"id":"jp_accelerator",   "name":"JP Accelerator",     "rarity":"rare",    "icon":"📈",
	 "desc":"All JP gains doubled this run.", "effect":{"type":"jp_multiplier","mult":2.0}},
	{"id":"champions_grit",   "name":"Champion's Grit",    "rarity":"rare",    "icon":"💪",
	 "desc":"Elite kills restore 30 HP + 20 Temper to killer.", "effect":{"type":"on_elite_kill","heal_hp":30,"heal_temper":20}},
	{"id":"void_sight",       "name":"Void Sight",         "rarity":"rare",    "icon":"👁",
	 "desc":"Enemy elite affixes revealed before each battle.", "effect":{"type":"reveal_elites"}},
	{"id":"double_strike",    "name":"Double Strike",      "rarity":"rare",    "icon":"⚔",
	 "desc":"Basic attacks 25% chance to hit twice.", "effect":{"type":"passive","id":"double_strike","chance":0.25}},
	{"id":"ashvale_resolve",  "name":"Ashvale Resolve",    "rarity":"rare",    "icon":"🛡",
	 "desc":"First hit each battle cannot reduce HP below 1.", "effect":{"type":"passive","id":"first_hit_guard"}},
	{"id":"reedfolk_reading", "name":"Reedfolk's Reading", "rarity":"rare",    "icon":"🌿",
	 "desc":"Reveals all elite affixes. Wet effects last +2 turns.", "effect":{"type":"reveal_elites"}},
	# Legendary
	{"id":"ignareth_roar",    "name":"Ignareth's Roar",    "rarity":"legendary","icon":"🔥","guardian":"ignareth",
	 "desc":"First fire ability auto-SURGEs. Burning tiles detonate (35 dmg).", "effect":{"type":"passive","id":"ignareth_roar","element":"fire","detonate":35}},
	{"id":"torvahk_fury",     "name":"Torvahk's Fury",     "rarity":"legendary","icon":"⚡","guardian":"torvahk",
	 "desc":"Stunned units lose 20 HP. Stun lasts +1 turn.", "effect":{"type":"passive","id":"torvahk_fury","stun_drain":20,"stun_extra":1}},
	{"id":"luminarch_judgment","name":"Luminarch's Judgment","rarity":"legendary","icon":"✨","guardian":"luminarch",
	 "desc":"Enemy deaths flare 28 holy damage to all adjacent.", "effect":{"type":"passive","id":"death_flare","damage":28}},
	{"id":"vaelthorn_echo",   "name":"Vaelthorn's Echo",   "rarity":"legendary","icon":"💀","guardian":"vaelthorn",
	 "desc":"Status expiry deals 35 dark damage.", "effect":{"type":"passive","id":"vaelthorn_echo","damage":35}},
	{"id":"elemental_echo",   "name":"Elemental Echo",     "rarity":"legendary","icon":"🌀",
	 "desc":"25% chance for any reaction to trigger twice.", "effect":{"type":"reaction_echo","chance":0.25}},
	{"id":"phoenix_vitality", "name":"Phoenix Vitality",   "rarity":"legendary","icon":"🔥",
	 "desc":"First 0-HP party member survives at 1 HP (once/battle).", "effect":{"type":"once_per_battle","outcome":"survive_at_1_hp"}},
	# Unique — Guardian Channelling (floor 4+ only)
	{"id":"ignareth_unchained","name":"Ignareth Unchained","rarity":"unique",  "icon":"🔥","guardian":"ignareth",
	 "desc":"All terrain ignites at battle start. Fire 2× damage. Party takes 8% HP fire/turn.",
	 "flavour":"The Eternal Flame does not distinguish friend from kindling.",
	 "effect":{"type":"battle_start","trigger":"ignite_all","fire_mult":2.0,"self_dmg":0.08}},
	{"id":"nerevan_veil",     "name":"Nerevan's Veil",     "rarity":"unique",  "icon":"🌊","guardian":"nerevan",
	 "desc":"3×3 tide at battle start. Party heals 12% HP/turn on water.",
	 "flavour":"The Mirefen does not flood. It remembers its original depth.",
	 "effect":{"type":"battle_start","trigger":"summon_tide","water_heal":0.12}},
	{"id":"torvahk_unchained","name":"Torvahk Unchained",  "rarity":"unique",  "icon":"⚡","guardian":"torvahk",
	 "desc":"Lightning arcs to nearest enemy each turn (30 dmg, 30% stun). Electrified water deals 55 dmg.",
	 "flavour":"They recorded 47 lightning strikes. They were all the same bolt.",
	 "effect":{"type":"battle_start","trigger":"lightning_aura","arc_damage":30,"arc_stun":0.30,"electrify_damage":55}},
	{"id":"luminarch_covenant","name":"Luminarch's Covenant","rarity":"unique", "icon":"✨","guardian":"luminarch",
	 "desc":"Party can never be reduced below 1 HP by a single hit. Anchors heal party 50 HP when struck.",
	 "flavour":"We found Luminarch's seal at the base of the Thornspire.",
	 "effect":{"type":"passive","id":"luminarch_covenant","min_hp":1,"anchor_heal":50}},
	{"id":"vaelthorn_unchained","name":"Vaelthorn Unchained","rarity":"unique","icon":"💀","guardian":"vaelthorn",
	 "desc":"All enemies start Cursed (2t). Kills restore 25 Ether + 10 HP to attacker.",
	 "flavour":"The Null Conclave did not corrupt Vaelthorn. Vaelthorn was waiting for them.",
	 "effect":{"type":"battle_start","trigger":"curse_all","on_kill":{"ether":25,"hp":10}}},
]

var _s: int = 0
func _rng() -> float:
	_s = (_s * 1664525 + 1013904223) & 0xffffffff
	return float(_s & 0xffffffff) / 4294967296.0

## Generate 3 boon offers for a floor. Floor scales rarity weights.
func generate_offers(rng_seed: int, floor_num: int, owned_ids: Array) -> Array:
	_s = rng_seed & 0xffffffff; if _s == 0: _s = 1

	var weights := {
		"common":    max(10, 55 - (floor_num - 1) * 5),
		"rare":      25 + (floor_num - 1) * 3,
		"legendary": 10 + (floor_num - 1) * 2,
		"unique":    (floor_num - 3) * 2 if floor_num >= 4 else 0,
	}
	var rpool: Array[String] = []
	for r in weights: for _i in range(weights[r]): rpool.append(r)

	var offers: Array = []
	var used: Array  = owned_ids.duplicate()

	for _slot in range(3):
		for _attempt in range(8):
			var rarity: String = rpool[int(_rng() * rpool.size())]
			var pool := BOONS.filter(func(b: Dictionary) -> bool:
				return b["rarity"] == rarity and not used.has(b["id"]))
			if pool.is_empty(): continue
			var boon: Dictionary = pool[int(_rng() * pool.size())]
			used.append(boon["id"]); offers.append(boon); break

	while offers.size() < 3:
		var commons := BOONS.filter(func(b: Dictionary) -> bool:
			return b["rarity"] == "common" and not used.has(b["id"]))
		if commons.is_empty(): break
		var fallback_boon: Dictionary = commons[int(_rng() * commons.size())]
		used.append(fallback_boon["id"]); offers.append(fallback_boon)

	return offers

func get_boon(boon_id: String) -> Dictionary:
	for b: Dictionary in BOONS:
		if b["id"] == boon_id: return b
	return {}
