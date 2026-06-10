## JobTreeData.gd
## Complete FF Tactics-inspired job tree.
## 3 tiers  Basic  Advanced  Ascended.
## Prerequisites enforce the progression path.
## Pure data  no scene dependencies.

class_name JobTreeData
extends RefCounted

## Job tier constants
const TIER_BASIC    := 1
const TIER_ADVANCED := 2
const TIER_ASCENDED := 3

## JP required per level [01, 12, 23, 34, 45, 5Master]
const JP_PER_LEVEL: Array[int] = [30, 90, 180, 320, 520, 800]

const JOBS: Dictionary = {

	#  TIER 1  BASIC (no prerequisites)

	"squire": {
		"id":          "squire",
		"name":        "Squire",
		"tier":        TIER_BASIC,
		"icon":        "res://assets/icons/job-knight-icon.png",
		"description": "A disciplined fighter. Reliable in any situation.",
		"prerequisites": {},
		"abilities": ["slash", "mighty_strike", "defend", "cover_ally"],
		"stat_bonuses_per_level": {
			"max_hp": 12, "physical": 2, "magic": 0, "speed": 0, "max_temper": 5,
		},
		"mastery_bonus": {
			"id": "squire_mastery",
			"description": "+1 Move permanently. Counter-attack chance +15%.",
			"move_bonus": 1, "counter_chance_bonus": 0.15,
		},
		"flavour": "Every knight was once a Squire. Few remain one for long.",
	},

	"arcanist": {
		"id":          "arcanist",
		"name":        "Arcanist",
		"tier":        TIER_BASIC,
		"icon":        "res://assets/icons/job-mage-icon.png",
		"description": "Commands elemental resonance through raw focus.",
		"prerequisites": {},
		"abilities": ["fireball", "blizzard", "thunderstrike", "void_pulse"],
		"stat_bonuses_per_level": {
			"max_hp": 6, "physical": 0, "magic": 3, "speed": 0, "max_ether": 15,
		},
		"mastery_bonus": {
			"id": "arcanist_mastery",
			"description": "All spells cost 20% less Ether. Elemental affinities on self improved.",
			"ether_cost_mult": 0.8,
		},
		"flavour": "The resonance does not care who calls it. The Arcanist just calls it first.",
	},

	"scout": {
		"id":          "scout",
		"name":        "Scout",
		"tier":        TIER_BASIC,
		"icon":        "res://assets/icons/job-archer-icon.png",
		"description": "Ranged attacker who controls positioning and terrain.",
		"prerequisites": {},
		"abilities": ["long_shot", "rain_of_arrows", "quickstep", "smoke_screen"],
		"stat_bonuses_per_level": {
			"max_hp": 8, "physical": 1, "magic": 1, "speed": 1, "max_temper": 3,
		},
		"mastery_bonus": {
			"id": "scout_mastery",
			"description": "Attack range +1. SURGE window +15% wider.",
			"range_bonus": 1, "surge_window_bonus": 0.15,
		},
		"flavour": "They see the battlefield before the battle begins.",
	},

	#  TIER 2  ADVANCED (requires 1 Basic job at level 2+)

	"warder": {
		"id":          "warder",
		"name":        "Warder",
		"tier":        TIER_ADVANCED,
		"icon":        "res://assets/icons/job-guardian-icon.png",
		"description": "Unbreakable defender. Draws attacks, protects allies.",
		"prerequisites": { "squire": 2 },
		"abilities": ["mighty_strike", "defend", "iron_wall", "retribution", "rally"],
		"stat_bonuses_per_level": {
			"max_hp": 18, "physical": 2, "magic": 0, "speed": -1, "max_temper": 12,
		},
		"mastery_bonus": {
			"id": "warder_mastery",
			"description": "Takes 25% less physical damage. Cover range increased to 2 tiles.",
			"phys_resist": 0.25, "cover_range": 2,
		},
		"flavour": "The Ashvale Watch bred this discipline. The Thornspire tested it.",
	},

	"luminary": {
		"id":          "luminary",
		"name":        "Luminary",
		"tier":        TIER_ADVANCED,
		"icon":        "res://assets/icons/job-cleric-icon.png",
		"description": "Holy conduit. Heals, buffs, and purges darkness.",
		"prerequisites": { "arcanist": 2 },
		"abilities": ["cure", "holy_strike", "luminous_barrier", "mass_cure", "consecrate"],
		"stat_bonuses_per_level": {
			"max_hp": 8, "physical": 0, "magic": 2, "speed": 0, "max_ether": 12,
		},
		"mastery_bonus": {
			"id": "luminary_mastery",
			"description": "Heals restore +30% more HP. Holy abilities auto-SURGE once per battle.",
			"heal_bonus_pct": 0.30, "holy_auto_surge": true,
		},
		"flavour": "Luminarch does not grant power. The Luminary finds it already within.",
	},

	"shadow": {
		"id":          "shadow",
		"name":        "Shadow",
		"tier":        TIER_ADVANCED,
		"icon":        "res://assets/icons/job-rogue-icon.png",
		"description": "Dark arts specialist. Positions in void, strikes from nowhere.",
		"prerequisites": { "scout": 2 },
		"abilities": ["dark_breath", "shadow_step", "void_scar", "expose_weakness", "vanish"],
		"stat_bonuses_per_level": {
			"max_hp": 7, "physical": 1, "magic": 2, "speed": 1, "max_ether": 8,
		},
		"mastery_bonus": {
			"id": "shadow_mastery",
			"description": "30% dodge chance. Dark abilities deal +25% damage to debuffed targets.",
			"dodge_chance": 0.30, "dark_bonus_vs_debuffed": 0.25,
		},
		"flavour": "The Null Conclave did not invent the Shadow. They just gave it a name.",
	},

	#  TIER 3  ASCENDED (requires 2 Advanced jobs at level 3+)

	"resonant": {
		"id":          "resonant",
		"name":        "Resonant",
		"tier":        TIER_ASCENDED,
		"icon":        "res://assets/icons/job-mage-icon.png",
		"description": "Masters elemental resonance chains. Triggers reactions that reshape the battlefield.",
		"prerequisites": { "luminary": 3, "shadow": 3 },
		"abilities": ["leyline_burst", "elemental_convergence", "resonance_fracture", "chain_resonance", "eidolon_drive"],
		"stat_bonuses_per_level": {
			"max_hp": 10, "physical": 0, "magic": 5, "speed": 1, "max_ether": 20,
		},
		"mastery_bonus": {
			"id": "resonant_mastery",
			"description": "Elemental reactions always echo once. Reaction damage +40%.",
			"reaction_echo": true, "reaction_bonus": 0.40,
		},
		"flavour": "The Bellkeepers spent forty years studying what the Resonant does in a single battle.",
	},

	"void_knight": {
		"id":          "void_knight",
		"name":        "Void Knight",
		"tier":        TIER_ASCENDED,
		"icon":        "res://assets/icons/job-knight-icon.png",
		"description": "Dark warrior who weaponises the void itself. Highest HP ceiling in the game.",
		"prerequisites": { "warder": 3, "shadow": 3 },
		"abilities": ["dark_echo", "sunder_armor", "null_break", "void_shield", "anchor_strike"],
		"stat_bonuses_per_level": {
			"max_hp": 22, "physical": 3, "magic": 1, "speed": 0, "max_temper": 8,
		},
		"mastery_bonus": {
			"id": "void_knight_mastery",
			"description": "Dark damage heals 20% of dealt amount. Immune to void/dark debuffs.",
			"dark_lifesteal": 0.20, "void_immune": true,
		},
		"flavour": "The Conclave feared this path. The Watch forbade it. It remains.",
	},
}


#  Prerequisite checking

## Returns true if a unit's job_jp meets the requirements for a job.
static func meets_prerequisites(job_id: String, unit_job_jp: Dictionary) -> bool:
	var job: Dictionary = JOBS.get(job_id, {})
	if job.is_empty(): return false
	var prereqs: Dictionary = job.get("prerequisites", {})
	if prereqs.is_empty(): return true   # Tier 1  always available

	for req_job: String in prereqs:
		var required_level: int = prereqs[req_job]
		var current_jp: int     = unit_job_jp.get(req_job, 0)
		var current_level: int  = _jp_to_level(current_jp)
		if current_level < required_level: return false
	return true


## Jobs available to a unit given their job_jp dict.
static func get_available_jobs(unit_job_jp: Dictionary) -> Array[String]:
	var available: Array[String] = []
	for job_id in JOBS:
		if meets_prerequisites(job_id, unit_job_jp):
			available.append(job_id)
	return available


## Compute total stat bonuses from a unit's job history.
## Returns additive bonuses to apply on top of base stats.
static func compute_stat_bonuses(unit_job_jp: Dictionary) -> Dictionary:
	var totals := { "max_hp":0,"physical":0,"magic":0,"speed":0,"max_temper":0,"max_ether":0 }
	for job_id in unit_job_jp:
		var job: Dictionary = JOBS.get(job_id, {})
		if job.is_empty(): continue
		var level: int = _jp_to_level(unit_job_jp[job_id])
		var bonuses: Dictionary = job.get("stat_bonuses_per_level", {})
		for stat in bonuses:
			if totals.has(stat): totals[stat] += bonuses[stat] * level
	return totals


## Get mastery bonuses for all mastered jobs (level 6).
static func get_mastery_bonuses(unit_job_jp: Dictionary) -> Array[Dictionary]:
	var mastered: Array[Dictionary] = []
	for job_id in unit_job_jp:
		if _jp_to_level(unit_job_jp[job_id]) >= 6:
			var job: Dictionary = JOBS.get(job_id, {})
			if job.has("mastery_bonus"): mastered.append(job["mastery_bonus"])
	return mastered


## All abilities a unit has unlocked through their job history.
static func get_all_unlocked_abilities(unit_job_jp: Dictionary) -> Array[String]:
	var abilities: Array[String] = []
	for job_id in unit_job_jp:
		var job: Dictionary = JOBS.get(job_id, {})
		if job.is_empty(): continue
		var level: int = _jp_to_level(unit_job_jp[job_id])
		var pool: Array = job.get("abilities", [])
		# Unlock one ability per level
		for i in range(min(level, pool.size())):
			if not abilities.has(pool[i]): abilities.append(pool[i])
	return abilities


static func get_job(job_id: String) -> Dictionary:
	return JOBS.get(job_id, {})


static func get_jobs_by_tier(tier: int) -> Array[String]:
	var result: Array[String] = []
	for job_id in JOBS:
		if JOBS[job_id].get("tier", 0) == tier: result.append(job_id)
	return result


static func _jp_to_level(jp: int) -> int:
	var lv := 0
	for threshold in [30, 90, 180, 320, 520, 800]:
		if jp >= threshold: lv += 1
		else: break
	return lv
