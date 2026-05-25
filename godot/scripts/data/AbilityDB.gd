class_name AbilityDB
extends RefCounted

## status_effect keys: id, duration, magnitude (0 = no DoT), damage_type
## jp_cost: JP required to learn this ability on the character screen

const ABILITIES: Dictionary = {
	#  Player starting abilities
	"fire": {
		"display_name": "Fire",
		"spell_type":   "fire",
		"mp_cost":      12,
		"range":        3,
		"base_power":   100,
		"target_type":  "enemy",
		"jp_cost":      100,
		"aoe_type":     "fan",   # sweeps 3 tiles wide  primary + 1 each side
		"fan_width":    1,
		"status_effect": {"id": "burn", "duration": 2, "magnitude": 0.07, "damage_type": "fire"},
	},
	"blizzard": {
		"display_name": "Blizzard",
		"spell_type":   "blizzard",
		"mp_cost":      12,
		"range":        3,
		"base_power":   95,
		"target_type":  "enemy",
		"jp_cost":      100,
		"aoe_type":     "cross",  # primary + 4 cardinal tiles  punishes clustered groups
		"cross_arm":    1,
		"status_effect": {"id": "slow", "duration": 2, "magnitude": 0.0, "damage_type": "pure"},
	},
	"thunder": {
		"display_name": "Thunder",
		"spell_type":   "thunder",
		"mp_cost":      15,
		"range":        4,
		"base_power":   130,
		"target_type":  "enemy",
		"jp_cost":      120,
		"aoe_type":     "chain",  # arcs to one nearby enemy at -40% power
		"chain_range":  2,
		"chain_count":  1,
		"chain_falloff":0.40,
	},
	"cure": {
		"display_name": "Cure",
		"spell_type":   "cure",
		"mp_cost":      8,
		"range":        3,
		"base_power":   80,
		"target_type":  "ally",
		"jp_cost":      80,
	},
	"holy": {
		"display_name": "Holy",
		"spell_type":   "holy",
		"mp_cost":      24,
		"range":        3,
		"base_power":   160,
		"target_type":  "enemy",
		"jp_cost":      300,
		"status_effect": {"id": "blind", "duration": 2, "magnitude": 0.0, "damage_type": "pure"},
	},
	"wind_slash": {
		"display_name": "Wind Slash",
		"spell_type":   "wind",
		"mp_cost":      10,
		"range":        3,
		"base_power":   85,
		"target_type":  "enemy",
		"jp_cost":      100,
		"aoe_type":     "line",   # pierces straight through  hits everything in a column
		"status_effect": {"id": "slow", "duration": 1, "magnitude": 0.0, "damage_type": "pure"},
	},
	"mighty_strike": {
		"display_name": "Mighty Strike",
		"spell_type":   "physical",
		"mp_cost":      8,
		"range":        1,
		"base_power":   150,
		"target_type":  "enemy",
		"jp_cost":      100,
	},
	#  Learnable player abilities
	"fira": {
		"display_name": "Fira",
		"spell_type":   "fire",
		"mp_cost":      18,
		"range":        4,
		"base_power":   140,
		"target_type":  "enemy",
		"jp_cost":      200,
		"aoe_type":     "fan",   # wider fan  primary + 2 each side (5 tiles wide)
		"fan_width":    2,
		"status_effect": {"id": "burn", "duration": 3, "magnitude": 0.08, "damage_type": "fire"},
	},
	"blizzara": {
		"display_name": "Blizzara",
		"spell_type":   "blizzard",
		"mp_cost":      18,
		"range":        4,
		"base_power":   130,
		"target_type":  "enemy",
		"jp_cost":      200,
		"aoe_type":     "cross",  # longer arms  2 tiles out each direction (9 tiles total)
		"cross_arm":    2,
		"status_effect": {"id": "slow", "duration": 3, "magnitude": 0.0, "damage_type": "pure"},
	},
	"cura": {
		"display_name": "Cura",
		"spell_type":   "cure",
		"mp_cost":      14,
		"range":        3,
		"base_power":   130,
		"target_type":  "ally",
		"jp_cost":      150,
	},
	"dark_blade": {
		"display_name": "Dark Blade",
		"spell_type":   "dark",
		"mp_cost":      10,
		"range":        1,
		"base_power":   130,
		"target_type":  "enemy",
		"jp_cost":      200,
		"status_effect": {"id": "poison", "duration": 2, "magnitude": 0.06, "damage_type": "dark"},
	},
	"tremor": {
		"display_name": "Tremor",
		"spell_type":   "physical",
		"mp_cost":      12,
		"range":        0,           # self-cast: center is always the caster
		"base_power":   115,
		"target_type":  "enemy",
		"jp_cost":      150,
		"aoe_type":     "radius",
		"aoe_radius":   1,           # hits all enemies within 1 tile of caster
		"status_effect": {"id": "slow", "duration": 1, "magnitude": 0.0, "damage_type": "pure"},
	},
	"aero": {
		"display_name": "Aero",
		"spell_type":   "wind",
		"mp_cost":      15,
		"range":        5,
		"base_power":   105,
		"target_type":  "enemy",
		"jp_cost":      180,
		"aoe_type":     "line",   # longer range line  threatens the whole column
		"status_effect": {"id": "slow", "duration": 2, "magnitude": 0.0, "damage_type": "pure"},
	},
	#  Lyra's bow abilities
	"pin_shot": {
		"display_name": "Pin Shot",
		"spell_type":   "physical",
		"mp_cost":      0,
		"range":        4,
		"min_range":    2,
		"base_power":   100,
		"target_type":  "enemy",
		"jp_cost":      0,
		"vfx_mode":     "arrow",
		"status_effect": {"id": "slow", "duration": 2, "magnitude": 0.0, "damage_type": "pure"},
	},
	"aimed_shot": {
		"display_name": "Aimed Shot",
		"spell_type":   "physical",
		"mp_cost":      6,
		"range":        5,
		"min_range":    2,
		"base_power":   145,
		"target_type":  "enemy",
		"jp_cost":      150,
		"vfx_mode":     "arrow",
	},
	"eagle_eye": {
		"display_name": "Eagle Eye",
		"spell_type":   "physical",
		"mp_cost":      10,
		"range":        6,
		"min_range":    2,
		"base_power":   130,
		"target_type":  "enemy",
		"jp_cost":      200,
		"vfx_mode":     "arrow",
		"status_effect": {"id": "blind", "duration": 2, "magnitude": 0.0, "damage_type": "pure"},
	},
	"scatter_shot": {
		"display_name": "Scatter Shot",
		"spell_type":   "physical",
		"mp_cost":      14,
		"range":        3,
		"min_range":    2,
		"base_power":   85,
		"target_type":  "enemy",
		"jp_cost":      250,
		"vfx_mode":     "arrow",
		"aoe_type":     "radius",   # hits all enemies within 1 tile of target tile
		"aoe_radius":   1,
	},
	#  Buff / support abilities
	"haste": {
		"display_name": "Haste",
		"spell_type":   "buff",
		"mp_cost":      10,
		"range":        3,
		"base_power":   0,
		"target_type":  "ally",
		"jp_cost":      150,
		"status_effect": {"id": "haste", "duration": 3, "magnitude": 0.0, "damage_type": "pure"},
	},
	"protect": {
		"display_name": "Protect",
		"spell_type":   "buff",
		"mp_cost":      8,
		"range":        2,
		"base_power":   0,
		"target_type":  "ally",
		"jp_cost":      150,
		"status_effect": {"id": "protect", "duration": 3, "magnitude": 0.0, "damage_type": "pure"},
	},
	"firaga": {
		"display_name": "Firaga",
		"spell_type":   "fire",
		"mp_cost":      26,
		"range":        4,
		"base_power":   175,
		"target_type":  "enemy",
		"jp_cost":      300,
		"aoe_type":     "fan",   # max-tier fan: 3 wide + 1 row deep behind target (6 tiles)
		"fan_width":    1,
		"fan_depth":    1,
		"status_effect": {"id": "burn", "duration": 3, "magnitude": 0.09, "damage_type": "fire"},
	},
	#  Enemy abilities
	"dark_breath": {
		"display_name": "Dark Breath",
		"spell_type":   "dark",
		"mp_cost":      18,
		"range":        2,
		"base_power":   130,
		"target_type":  "enemy",
		"jp_cost":      0,
		"status_effect": {"id": "poison", "duration": 3, "magnitude": 0.06, "damage_type": "dark"},
	},
	"thunderstrike": {
		"display_name": "Thunderstrike",
		"spell_type":   "thunder",
		"mp_cost":      14,
		"range":        4,
		"base_power":   105,
		"target_type":  "enemy",
		"jp_cost":      0,
		"aoe_type":     "chain",
		"chain_range":  2,
		"chain_count":  1,
		"chain_falloff":0.40,
	},
	"void_pulse": {
		"display_name": "Void Pulse",
		"spell_type":   "dark",
		"mp_cost":      12,
		"range":        3,
		"base_power":   95,
		"target_type":  "enemy",
		"jp_cost":      0,
		"status_effect": {"id": "silence", "duration": 2, "magnitude": 0.0, "damage_type": "pure"},
	},
	"shadow_mend": {
		"display_name": "Shadow Mend",
		"spell_type":   "cure",
		"mp_cost":      16,
		"range":        0,
		"base_power":   70,
		"target_type":  "ally",
		"jp_cost":      0,
	},

	#  Secret Skills (learned from Wanderers only)
	"resonance_fracture": {
		"id": "resonance_fracture", "display_name": "Resonance Fracture",
		"type": "spell", "spell_type": "dark", "base_power": 90,
		"mp_cost": 60, "range": 0,  # self-cast  erupts from the caster
		"aoe_type": "nova", "aoe_radius": 3,
		"vfx_mode": "dark",
		"description": "Detonate the field from within  nova hits all enemies within 3 tiles of YOU.",
		"secret": true, "teacher": "the_wandering_null",
	},
	"null_break": {
		"id": "null_break", "display_name": "Null-Break",
		"type": "spell", "spell_type": "dark", "base_power": 45,
		"mp_cost": 35, "range": 2,
		"description": "Disrupts target  45 dmg and removes one elite prefix for this battle.",
		"status_effect": {"id": "null_broken", "duration": 99, "magnitude": 0.0, "damage_type": "dark"},
		"secret": true, "teacher": "void_scholar_thresh",
	},
	"leyline_burst": {
		"id": "leyline_burst", "display_name": "Leyline Burst",
		"type": "spell", "spell_type": "holy", "base_power": 55,
		"mp_cost": 40, "range": 3, "aoe_radius": 1,
		"vfx_mode": "holy",
		"description": "Taps the ley network  55 holy+fire dmg in a 3x3 area. Ignites terrain.",
		"secret": true, "teacher": "archive_mage_volant",
	},
	"last_rites": {
		"id": "last_rites", "display_name": "Last Rites",
		"type": "spell", "spell_type": "buff", "base_power": 0,
		"mp_cost": 30, "range": 4,
		"status_effect": {"id": "last_rites", "duration": 99, "magnitude": 0.0, "damage_type": "pure"},
		"description": "When target would die, they act one final time first.",
		"secret": true, "teacher": "chaplain_aldis",
	},
	"blaze_counter": {
		"id": "blaze_counter", "display_name": "Blaze Counter",
		"type": "spell", "spell_type": "fire", "base_power": 50,
		"mp_cost": 0, "range": 1,
		"status_effect": {"id": "blaze_counter_ready", "duration": 99, "magnitude": 0.0, "damage_type": "fire"},
		"description": "Passive: once per battle, auto-counter with 50 fire dmg when struck.",
		"secret": true, "teacher": "ember_knight_solara",
	},
	"sunder_armor": {
		"id": "sunder_armor", "display_name": "Sunder Armor",
		"type": "spell", "spell_type": "physical", "base_power": 30,
		"mp_cost": 20, "range": 1,
		"status_effect": {"id": "armor_broken", "duration": 99, "magnitude": 0.25, "damage_type": "physical"},
		"description": "30 dmg and permanently reduces physical defense 25% for this run.",
		"secret": true, "teacher": "iron_duelist_garek",
	},
	"arc_counter": {
		"id": "arc_counter", "display_name": "Arc Counter",
		"type": "spell", "spell_type": "thunder", "base_power": 40,
		"mp_cost": 0, "range": 1,
		"status_effect": {"id": "arc_counter_ready", "duration": 99, "magnitude": 0.0, "damage_type": "pure"},
		"description": "Passive: once per battle, auto-counter with 40 thunder dmg (30% stun) when struck.",
		"secret": true, "teacher": "storm_duelist_kira",
	},
	"dark_echo": {
		"id": "dark_echo", "display_name": "Dark Echo",
		"type": "spell", "spell_type": "dark", "base_power": 60,
		"mp_cost": 25, "range": 3,
		"description": "Copies and mirrors the last ability any enemy used, dark-typed at 60 power.",
		"secret": true, "teacher": "shadow_of_vaelthorn",
	},
	#  Void Anchor
	"void_anchor_pulse": {
		"id": "void_anchor_pulse", "display_name": "Void Pulse",
		"type": "spell", "spell_type": "dark", "base_power": 0,
		"mp_cost": 0, "range": 2, "aoe_radius": 2,
		"description": "The Anchor pulses void energy  30 dark damage to all units within 2 tiles. Cannot be silenced.",
		"vfx_mode": "dark",
		"is_anchor_ability": true,
	},

	#  Job-tree abilities

	# Squire / Warder
	"defend": {
		"id": "defend", "display_name": "Defend",
		"type": "buff", "spell_type": "physical", "base_power": 0,
		"mp_cost": 0, "range": 0,
		"status_effect": {"id": "defending", "duration": 1, "magnitude": 0.5, "damage_type": "physical"},
		"description": "Brace  take 50% less damage until your next turn.",
	},
	"cover_ally": {
		"id": "cover_ally", "display_name": "Cover",
		"type": "buff", "spell_type": "physical", "base_power": 0,
		"mp_cost": 0, "range": 2,
		"status_effect": {"id": "covering", "duration": 1, "magnitude": 1.0, "damage_type": "physical"},
		"description": "Take hits directed at an adjacent ally until your next turn.",
	},
	"iron_wall": {
		"id": "iron_wall", "display_name": "Iron Wall",
		"type": "buff", "spell_type": "physical", "base_power": 0,
		"mp_cost": 10, "range": 0,
		"status_effect": {"id": "iron_wall", "duration": 2, "magnitude": 0.6, "damage_type": "physical"},
		"description": "Shield stance for 2 turns. Take 40% less damage. Cannot act.",
	},
	"retribution": {
		"id": "retribution", "display_name": "Retribution",
		"type": "attack", "spell_type": "physical", "base_power": 70,
		"mp_cost": 15, "range": 1,
		"description": "A fierce counter-blow. Deals +50% bonus damage if used after being hit.",
	},
	"rally": {
		"id": "rally", "display_name": "Rally",
		"type": "buff", "spell_type": "holy", "base_power": 0,
		"mp_cost": 20, "range": 3,
		"status_effect": {"id": "rallied", "duration": 2, "magnitude": 1.25, "damage_type": "physical"},
		"description": "Inspire an ally  they deal 25% more damage for 2 turns.",
	},

	# Scout
	"long_shot": {
		"id": "long_shot", "display_name": "Long Shot",
		"type": "attack", "spell_type": "physical", "base_power": 60,
		"mp_cost": 0, "range": 5, "attack_range_min": 3, "attack_range_max": 5,
		"description": "Precise arrow from extreme range (3-5 tiles). Can't be used at melee range.",
	},
	"rain_of_arrows": {
		"id": "rain_of_arrows", "display_name": "Rain of Arrows",
		"type": "attack", "spell_type": "physical", "base_power": 40,
		"mp_cost": 20, "range": 4, "aoe_radius": 1,
		"description": "Fires into a 3x3 area  40 power to all units in range. Friendly fire possible.",
	},
	"quickstep": {
		"id": "quickstep", "display_name": "Quickstep",
		"type": "buff", "spell_type": "physical", "base_power": 0,
		"mp_cost": 5, "range": 0,
		"status_effect": {"id": "quickstep", "duration": 1, "magnitude": 2.0, "damage_type": "physical"},
		"description": "Move again immediately. Can't act after.",
	},
	"smoke_screen": {
		"id": "smoke_screen", "display_name": "Smoke Screen",
		"type": "spell", "spell_type": "wind", "base_power": 0,
		"mp_cost": 15, "range": 3, "aoe_radius": 1,
		"status_effect": {"id": "blind", "duration": 2, "magnitude": 1.0, "damage_type": "wind"},
		"description": "Applies Blind (2t) to all units in target area  miss chance 35%.",
	},

	# Luminary
	"luminous_barrier": {
		"id": "luminous_barrier", "display_name": "Luminous Barrier",
		"type": "buff", "spell_type": "holy", "base_power": 0,
		"mp_cost": 25, "range": 3,
		"status_effect": {"id": "barrier", "duration": 2, "magnitude": 60.0, "damage_type": "pure"},
		"description": "Grants target a 60-HP absorb shield that lasts 2 turns.",
	},
	"mass_cure": {
		"id": "mass_cure", "display_name": "Mass Cure",
		"type": "heal", "spell_type": "holy", "base_power": 60,
		"mp_cost": 40, "range": 3, "aoe_radius": 2,
		"description": "Heals all allies within a 55 area for 60 power.",
	},
	"consecrate": {
		"id": "consecrate", "display_name": "Consecrate",
		"type": "spell", "spell_type": "holy", "base_power": 55,
		"mp_cost": 30, "range": 4,
		"status_effect": {"id": "burn", "duration": 1, "magnitude": 0.0, "damage_type": "holy"},
		"description": "Holy fire  55 holy damage, removes one negative status from caster.",
	},

	# Shadow
	"shadow_step": {
		"id": "shadow_step", "display_name": "Shadow Step",
		"type": "buff", "spell_type": "dark", "base_power": 0,
		"mp_cost": 10, "range": 4,
		"status_effect": {"id": "invisible", "duration": 1, "magnitude": 1.0, "damage_type": "dark"},
		"description": "Teleport to any unoccupied tile within 4 tiles and gain Invisible (1t).",
	},
	"expose_weakness": {
		"id": "expose_weakness", "display_name": "Expose Weakness",
		"type": "spell", "spell_type": "dark", "base_power": 25,
		"mp_cost": 12, "range": 2,
		"status_effect": {"id": "exposed", "duration": 2, "magnitude": 0.25, "damage_type": "dark"},
		"description": "25 dark damage and applies Exposed (2t)  target takes 25% more damage.",
	},
	"vanish": {
		"id": "vanish", "display_name": "Vanish",
		"type": "buff", "spell_type": "dark", "base_power": 0,
		"mp_cost": 8, "range": 0,
		"status_effect": {"id": "invisible", "duration": 2, "magnitude": 1.0, "damage_type": "dark"},
		"description": "Become Invisible for 2 turns. Enemies cannot target you.",
	},

	# Resonant
	"elemental_convergence": {
		"id": "elemental_convergence", "display_name": "Elemental Convergence",
		"type": "spell", "spell_type": "resonance", "base_power": 65,
		"mp_cost": 45, "range": 4,
		"description": "Deals 65 damage of the element the target is weakest to. Auto-selects element.",
	},
	"chain_resonance": {
		"id": "chain_resonance", "display_name": "Chain Resonance",
		"type": "spell", "spell_type": "thunder", "base_power": 40,
		"mp_cost": 30, "range": 3,
		"aoe_type":     "chain",  # chains to ALL enemies in range with no hop limit
		"chain_range":  3,
		"chain_count":  12,       # effectively unlimited
		"chain_falloff":0.15,     # only slight falloff  resonance sustains itself
		"description": "40 thunder. Chain arcs to ALL enemies within reach  minimal falloff.",
	},
	"eidolon_drive": {
		"id": "eidolon_drive", "display_name": "Eidolon Drive",
		"type": "spell", "spell_type": "resonance", "base_power": 100,
		"mp_cost": 70, "range": 3,
		"description": "Unleash 100 resonance damage. Clears all terrain effects in a 3x3 area.",
	},

	# Void Knight
	"void_shield": {
		"id": "void_shield", "display_name": "Void Shield",
		"type": "buff", "spell_type": "dark", "base_power": 0,
		"mp_cost": 20, "range": 0,
		"status_effect": {"id": "void_shield", "duration": 2, "magnitude": 80.0, "damage_type": "dark"},
		"description": "80-HP void absorb shield for 2 turns. Absorbed damage restores Ether.",
	},
	"anchor_strike": {
		"id": "anchor_strike", "display_name": "Anchor Strike",
		"type": "attack", "spell_type": "dark", "base_power": 85,
		"mp_cost": 25, "range": 1,
		"description": "85 dark + physical damage. Deals triple damage to structures and anchors.",
		"bonus_vs_anchor": 3.0,
	},

}


static func get_ability(id: String) -> Dictionary:
	return ABILITIES.get(id, {})
