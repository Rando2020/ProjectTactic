class_name EliteAffixDB
extends RefCounted

const ELITE_TIERS := {
	"normal": {"label": "Normal", "color": "#94a3b8", "hp_mult": 1.0, "jp_mult": 1.0},
	"marked": {"label": "Marked", "color": "#fde047", "hp_mult": 1.4, "jp_mult": 1.5},
	"elite": {"label": "Elite", "color": "#f97316", "hp_mult": 1.7, "jp_mult": 2.0},
	"champion": {"label": "Champion", "color": "#ef4444", "hp_mult": 2.2, "jp_mult": 3.0},
}

const PREFIXES := {
	"volatile": {"id": "volatile", "label": "Volatile", "description": "Explodes on death, damaging adjacent units.", "on_death": {"type": "explosion", "damage": 45}, "stat_mods": {}},
	"fortified": {"id": "fortified", "label": "Fortified", "description": "+80% HP. Physical damage reduced.", "stat_mods": {"hp_mult": 1.8, "physical_resist": 0.25}},
	"empowered": {"id": "empowered", "label": "Empowered", "description": "Deals more damage.", "stat_mods": {"damage_mult": 1.4}},
	"siphoning": {"id": "siphoning", "label": "Siphoning", "description": "Hits drain MP from target.", "on_hit": {"type": "mp_drain", "amount": 20}, "stat_mods": {}},
	"cursed": {"id": "cursed", "label": "Cursed", "description": "Chance to apply bleed on hit.", "on_hit": {"type": "status", "status": "bleed", "turns": 2, "chance": 0.35}, "stat_mods": {}},
	"berserker": {"id": "berserker", "label": "Berserking", "description": "Below half HP: gains speed and damage.", "conditional": {"trigger": "hp_below_half", "speed_bonus": 3, "damage_mult": 1.25}, "stat_mods": {}},
	"vampiric": {"id": "vampiric", "label": "Vampiric", "description": "Heals for a portion of damage dealt.", "on_hit": {"type": "lifesteal", "percent": 0.30}, "stat_mods": {}},
	"shielded": {"id": "shielded", "label": "Shielded", "description": "Starts with a one-hit Ether shield.", "stat_mods": {"ether_shield": 1}},
}

const SUFFIXES := {
	"of_frost": {"id": "of_frost", "label": "of Frost", "description": "Adjacent tiles become ice. Hits can slow.", "on_spawn": {"type": "freeze_adjacent"}, "on_hit": {"type": "status", "status": "slow", "turns": 1, "chance": 0.6}},
	"of_the_storm": {"id": "of_the_storm", "label": "of the Storm", "description": "Nearby water becomes electrified.", "on_spawn": {"type": "electrify_water", "radius": 3}},
	"of_flames": {"id": "of_flames", "label": "of Flames", "description": "Spawns on burning ground. Immune to fire.", "on_spawn": {"type": "ignite_spawn"}, "stat_mods": {"immunities": ["fire"]}},
	"of_the_pack": {"id": "of_the_pack", "label": "of the Pack", "description": "Nearby enemies deal more damage.", "aura": {"type": "pack_leader", "radius": 2, "damage_mult": 1.2}},
	"of_iron": {"id": "of_iron", "label": "of Iron", "description": "Immune to status effects.", "stat_mods": {"status_immune": true}},
	"of_shadows": {"id": "of_shadows", "label": "of Shadows", "description": "Higher dodge chance.", "stat_mods": {"dodge_chance": 0.3}},
	"of_the_void": {"id": "of_the_void", "label": "of the Void", "description": "Immune to dark/resonance. Voids nearby tiles.", "stat_mods": {"immunities": ["dark", "resonance"]}},
	"of_the_tide": {"id": "of_the_tide", "label": "of the Tide", "description": "Floods adjacent tiles with shallow water.", "on_spawn": {"type": "flood_adjacent", "terrain": "shallow_water"}},
}

const ELITE_SPAWN_RATES := {"normal": 0.70, "marked": 0.18, "elite": 0.09, "champion": 0.03}

static func weighted_tier(rng: RandomNumberGenerator, elite_rate_bonus: float = 0.0) -> String:
	var roll := rng.randf()
	var normal_cutoff: float = clamp(float(ELITE_SPAWN_RATES.normal) - elite_rate_bonus, 0.10, 0.90)
	if roll < normal_cutoff:
		return "normal"
	if roll < normal_cutoff + 0.18:
		return "marked"
	if roll < normal_cutoff + 0.30:
		return "elite"
	return "champion"

static func random_prefix(rng: RandomNumberGenerator) -> Dictionary:
	var keys := PREFIXES.keys()
	return PREFIXES[keys[rng.randi_range(0, keys.size() - 1)]].duplicate(true)

static func random_suffix(rng: RandomNumberGenerator) -> Dictionary:
	var keys := SUFFIXES.keys()
	return SUFFIXES[keys[rng.randi_range(0, keys.size() - 1)]].duplicate(true)

static func generate_affix_set(rng: RandomNumberGenerator, elite_rate_bonus: float = 0.0) -> Dictionary:
	var tier_id := weighted_tier(rng, elite_rate_bonus)
	var tier: Dictionary = ELITE_TIERS[tier_id].duplicate(true)
	var result := {"tier_id": tier_id, "tier": tier, "prefix": {}, "suffix": {}}
	if tier_id != "normal":
		result.prefix = random_prefix(rng)
		result.suffix = random_suffix(rng)
	return result
