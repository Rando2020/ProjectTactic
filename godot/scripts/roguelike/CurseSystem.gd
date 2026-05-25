## CurseSystem.gd
## Returnal/Saros-style negative boons with tradeoffs.
## Each curse has a clear penalty AND unlocks something that
## couldn't be obtained otherwise  making them genuine decisions.
##
## Design rules:
##   1. Every curse changes HOW you play, not just how hard it is
##   2. Every curse unlocks something specific
##   3. Curses interact differently depending on your job/boons
##   4. Multiple curses can stack  some combos are secretly good

class_name CurseSystem
extends RefCounted

const CURSES: Array[Dictionary] = [

	#  Fire / Ignareth
	{
		"id":       "ignareth_debt",
		"name":     "Ignareth's Debt",
		"element":  "fire",
		"guardian": "ignareth",
		"icon":"*",
		"rarity":   "curse",
		"penalty":  "Your party takes 12% of all fire damage you deal.",
		"unlock":   "Legendary fire boons appear twice as often.",
		"flavour":  '"The flame feeds on everything. Including its master."',
		"effect": {
			"type":        "curse",
			"self_fire_pct":   0.12,
			"unlock_boon_element": "fire",
			"unlock_rarity":       "legendary",
			"unlock_weight_mult":  2.0,
		},
		"job_notes": "Brutal with Resonant (fire chains everywhere). Kael barely notices.",
		"combo_notes": "Terrible alone. Nerevan's Veil offsets self-damage with water heals.",
		"floor_min": 1,
	},

	#  Water / Nerevan
	{
		"id":       "tides_price",
		"name":     "The Tide's Price",
		"element":  "water",
		"guardian": "nerevan",
		"icon":"*",
		"penalty":  "Party cannot recover HP between floors. Between-battle heals do nothing.",
		"unlock":   "Nerevan Unique boons can appear. Nerevan's Veil floor minimum removed.",
		"flavour":  '"The tide gives. But not twice."',
		"effect": {
			"type":               "curse",
			"block_between_heals": true,
			"unlock_guardian_unique": "nerevan",
		},
		"job_notes": "Fine for Warder builds (high temper buffer). Rough for glass-cannon Arcanist.",
		"combo_notes": "Pairs with Luminarch's Grace (battle-start Blessed) and Phoenix Vitality.",
		"floor_min": 1,
	},

	#  Thunder / Torvahk
	{
		"id":       "storm_debt",
		"name":     "Storm Debt",
		"element":  "thunder",
		"guardian": "torvahk",
		"icon":"*",
		"penalty":  "SURGE window is 60% narrower. Missing SURGE costs 10 HP.",
		"unlock":   "Torvahk Unique boons can appear. Arc Counter taught free by first wanderer.",
		"flavour":  '"The gap still exists. You just have to be faster."',
		"effect": {
			"type":               "curse",
			"surge_window_penalty": -0.60,
			"surge_miss_hp_cost":   10,
			"unlock_guardian_unique": "torvahk",
		},
		"job_notes": "Devastates physical-attack Warder builds. Arcanists who skip SURGE barely care.",
		"combo_notes": "Stormglass Timing boon (auto-SURGE on crits) completely negates this curse.",
		"floor_min": 1,
	},

	#  Holy / Luminarch
	{
		"id":       "sacred_tithe",
		"name":     "The Sacred Tithe",
		"element":  "holy",
		"guardian": "luminarch",
		"icon":"*",
		"penalty":  "All heals are halved. Luminarch's Grace Blessed effect lasts only 1 turn.",
		"unlock":   "Luminarch Unique boons can appear. Chaplain Aldis appears guaranteed next ?.",
		"flavour":  '"Luminarch asks that you trust the light without leaning on it."',
		"effect": {
			"type":             "curse",
			"heal_multiplier":  0.5,
			"unlock_guardian_unique": "luminarch",
			"guarantee_wanderer":     "chaplain_aldis",
		},
		"job_notes": "Devastating if Mira is your primary healer. Job-define-changing.",
		"combo_notes": "Luminarch's Covenant (can't die in one hit) makes this much more tolerable.",
		"floor_min": 1,
	},

	#  Dark / Vaelthorn
	{
		"id":       "vaelthorns_echo_curse",
		"name":     "Vaelthorn's Hunger",
		"element":  "dark",
		"guardian": "vaelthorn",
		"icon":"*",
		"penalty":  "Every time a party member takes damage, they lose 8 Ether. Ether cannot regenerate naturally.",
		"unlock":   "Vaelthorn Unique boons can appear. Shadow of Vaelthorn appears on Floor 6.",
		"flavour":  '"The void does not take what you have. It takes what you need."',
		"effect": {
			"type":               "curse",
			"damage_ether_drain":  8,
			"block_ether_regen":   true,
			"unlock_guardian_unique": "vaelthorn",
			"guarantee_wanderer_floor": {"wanderer":"shadow_of_vaelthorn","floor":6},
		},
		"job_notes": "Arcanists who rely on MP for spells feel this immediately. Warder is fine.",
		"combo_notes": "Vaelthorn Unchained on-kill Ether restore partially offsets the drain.",
		"floor_min": 2,
	},

	#  Neutral / Run-shaping
	{
		"id":       "null_resonance",
		"name":     "The Null Resonance",
		"icon":"*",
		"element":  null,
		"penalty":  "All enemies gain one random extra affix at battle start.",
		"unlock":   "The Wandering Null appears on the next ? node. Resonance Fracture teachable.",
		"flavour":  '"The void remembers every enemy you\'ve faced. They remember you too."',
		"effect": {
			"type":               "curse",
			"enemy_extra_affix":   1,
			"guarantee_wanderer":  "the_wandering_null",
		},
		"job_notes": "Every class feels this  suddenly every enemy is elite.",
		"combo_notes": "Champion's Grit (elite kills heal you) turns this into a healing engine.",
		"floor_min": 2,
	},
	{
		"id":       "bellkeepers_toll",
		"name":     "The Bellkeeper's Toll",
		"icon":"*",
		"element":  null,
		"penalty":  "JP gain is halved this run.",
		"unlock":   "Archive Mage Volant appears guaranteed next ?. Teaches Leyline Burst for free.",
		"flavour":  '"Knowledge has always been expensive. The Bellkeepers just write it down."',
		"effect": {
			"type":             "curse",
			"jp_penalty":        0.5,
			"guarantee_wanderer":"archive_mage_volant",
		},
		"job_notes": "Directly conflicts with JP Accelerator boon. Never take both.",
		"combo_notes": "If you already have the abilities you want, this is almost free.",
		"floor_min": 1,
	},
	{
		"id":       "void_hunger",
		"name":     "Void Hunger",
		"icon":"*",
		"element":  null,
		"penalty":  "After each battle, one random party member permanently loses 15 max HP for this run.",
		"unlock":   "Resonant-tier items drop from elites at 3 rate.",
		"flavour":  '"The void feeds on potential. You just have to decide whose."',
		"effect": {
			"type":              "curse",
			"post_battle_hp_loss": 15,
			"resonant_drop_mult": 3.0,
		},
		"job_notes": "On long runs (Floor 8+) this becomes critical. Short efficient runs barely notice.",
		"combo_notes": "Luminarch's Covenant (min HP 1) means they can't be drained to death in one hit.",
		"floor_min": 3,
	},
	{
		"id":       "guardians_absence",
		"name":     "Guardian's Absence",
		"icon":"*",
		"element":  null,
		"penalty":  "One randomly chosen Guardian's boons are removed from the pool entirely this run.",
		"unlock":   "All remaining Guardian boons each gain +1 offer slot per pick.",
		"flavour":  '"Four voices sing louder than five divided."',
		"effect": {
			"type":              "curse",
			"ban_random_guardian": true,
			"remaining_weight_bonus": 1,
		},
		"job_notes": "If your build depends on fire and fire is banned  run ends here.",
		"combo_notes": "If you're already committed to one element, losing others costs almost nothing.",
		"floor_min": 2,
	},
	{
		"id":       "weight_of_iron",
		"name":     "The Weight of Iron",
		"icon":"*",
		"element":  null,
		"penalty":  "All party movement reduced by 1. Units cannot jump elevated terrain.",
		"unlock":   "Warder mastery abilities available without level prerequisite. Iron Duelist Garek guaranteed.",
		"flavour":  '"Mobility is a luxury. Power is not."',
		"effect": {
			"type":             "curse",
			"move_penalty":      -1,
			"block_jump":        true,
			"unlock_job_bypass": "warder",
			"guarantee_wanderer":"iron_duelist_garek",
		},
		"job_notes": "Kael/Warder barely cares (already slow). Mira/Arcanist loses significant positioning.",
		"combo_notes": "Terrible on open maps. On the boss floor (tight corridors) barely matters.",
		"floor_min": 1,
	},
]

var _s: int = 0
func _rng() -> float:
	_s = (_s * 1664525 + 1013904223) & 0xffffffff
	return float(_s & 0xffffffff) / 4294967296.0


## Generate one curse offer for a floor.
## Returns null if no new curses are available.
func generate_curse_offer(rng_seed: int, floor_num: int, owned_ids: Array) -> Dictionary:
	_s = rng_seed & 0xffffffff; if _s == 0: _s = 1
	var pool := CURSES.filter(func(c: Dictionary) -> bool:
		return c["floor_min"] <= floor_num and not owned_ids.has(c["id"]))
	if pool.is_empty(): return {}
	return pool[int(_rng() * pool.size())]


## Apply curse penalties into a bonuses dict (mutates in place).
func apply_curses(active_curses: Array, bonuses: Dictionary) -> void:
	for curse: Dictionary in active_curses:
		var fx: Dictionary = curse.get("effect", {})
		if fx.get("block_between_heals", false):
			bonuses["between_battle_heal"] = 0.0
		if fx.has("heal_multiplier"):
			bonuses["heal_bonus"] = int(bonuses.get("heal_bonus", 0) * fx["heal_multiplier"])
		if fx.has("surge_window_penalty"):
			bonuses["surge_window_bonus"] = (bonuses.get("surge_window_bonus",0.0) + fx["surge_window_penalty"])
		if fx.has("jp_penalty"):
			bonuses["jp_multiplier"] = bonuses.get("jp_multiplier",1.0) * fx["jp_penalty"]
		# Store for BattleScene/BattleManager to read
		if fx.get("enemy_extra_affix", 0) > 0:
			bonuses["enemy_extra_affixes"] = bonuses.get("enemy_extra_affixes",0) + fx["enemy_extra_affix"]
		if fx.get("damage_ether_drain", 0) > 0:
			bonuses["curse_ether_drain_on_hit"] = bonuses.get("curse_ether_drain_on_hit",0) + fx["damage_ether_drain"]
		if fx.get("self_fire_pct", 0.0) > 0.0:
			bonuses["curse_self_fire_pct"] = bonuses.get("curse_self_fire_pct",0.0) + fx["self_fire_pct"]
		if fx.get("move_penalty", 0) != 0:
			bonuses["curse_move_penalty"] = bonuses.get("curse_move_penalty",0) + fx["move_penalty"]
		if fx.get("resonant_drop_mult", 0.0) > 0.0:
			bonuses["resonant_drop_mult"] = bonuses.get("resonant_drop_mult",1.0) * fx["resonant_drop_mult"]


## What guardian UUID is banned this run (Guardian's Absence curse).
func get_banned_guardian(active_curses: Array, run_seed: int) -> String:
	for curse: Dictionary in active_curses:
		if curse.get("id","") == "guardians_absence":
			var guardians := ["ignareth","nerevan","torvahk","luminarch","vaelthorn"]
			_s = run_seed & 0xffffffff
			return guardians[int(_rng() * guardians.size())]
	return ""


## Check if a wanderer is guaranteed by an active curse.
func get_guaranteed_wanderer(active_curses: Array, floor_num: int) -> String:
	for curse: Dictionary in active_curses:
		var fx: Dictionary = curse.get("effect",{})
		if fx.has("guarantee_wanderer"):
			return fx["guarantee_wanderer"]
		if fx.has("guarantee_wanderer_floor"):
			var gw: Dictionary = fx["guarantee_wanderer_floor"]
			if floor_num >= gw.get("floor",99):
				return gw.get("wanderer","")
	return ""


## Check if a Guardian's Unique boons are unlocked by curses.
func get_unlocked_unique_guardians(active_curses: Array) -> Array[String]:
	var unlocked: Array[String] = []
	for curse: Dictionary in active_curses:
		var g: String = curse.get("effect",{}).get("unlock_guardian_unique","")
		if not g.is_empty() and not unlocked.has(g): unlocked.append(g)
	return unlocked


func get_curse(curse_id: String) -> Dictionary:
	for c: Dictionary in CURSES:
		if c["id"] == curse_id: return c
	return {}
