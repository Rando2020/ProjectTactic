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
		"icon":        "res://assets/generated/icons/job-knight-icon.png",
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
		"icon":        "res://assets/generated/icons/job-mage-icon.png",
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
		"icon":        "res://assets/generated/icons/job-archer-icon.png",
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
		"icon":        "res://assets/generated/icons/job-guardian-icon.png",
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
		"icon":        "res://assets/generated/icons/job-cleric-icon.png",
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
		"icon":        "res://assets/generated/icons/job-rogue-icon.png",
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
		"icon":        "res://assets/generated/icons/job-mage-icon.png",
		"description": "Masters elemental resonance chains. Triggers reactions that reshape the battlefield.",
