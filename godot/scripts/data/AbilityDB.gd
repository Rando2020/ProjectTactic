class_name AbilityDB
extends RefCounted

## status_effect dict keys: id, duration, magnitude (0.0 = no DoT), damage_type

const ABILITIES: Dictionary = {
	# ── Player abilities ──────────────────────────────────────────────────────
	"fire": {
		"display_name": "Fire",
		"spell_type":   "fire",
		"mp_cost":      12,
		"range":        3,
		"base_power":   110,
		"target_type":  "enemy",
		# Burns for 2 turns — 7 % max HP per tick, fire damage
		"status_effect": {"id": "burn", "duration": 2, "magnitude": 0.07, "damage_type": "fire"},
	},
	"blizzard": {
		"display_name": "Blizzard",
		"spell_type":   "blizzard",
		"mp_cost":      12,
		"range":        3,
		"base_power":   100,
		"target_type":  "enemy",
		# Frozen limbs — slows for 2 turns
		"status_effect": {"id": "slow", "duration": 2, "magnitude": 0.0, "damage_type": "pure"},
	},
	"thunder": {
		"display_name": "Thunder",
		"spell_type":   "thunder",
		"mp_cost":      15,
		"range":        4,
		"base_power":   120,
		"target_type":  "enemy",
		# Lightning stun — slows for 2 turns
		"status_effect": {"id": "slow", "duration": 2, "magnitude": 0.0, "damage_type": "pure"},
	},
	"cure": {
		"display_name": "Cure",
		"spell_type":   "cure",
		"mp_cost":      8,
		"range":        3,
		"base_power":   80,
		"target_type":  "ally",
		# No status effect
	},
	"holy": {
		"display_name": "Holy",
		"spell_type":   "holy",
		"mp_cost":      24,
		"range":        3,
		"base_power":   160,
		"target_type":  "enemy",
		# Blinding light — blind for 2 turns (physical attacks miss ~35 % of the time)
		"status_effect": {"id": "blind", "duration": 2, "magnitude": 0.0, "damage_type": "pure"},
	},
	"wind_slash": {
		"display_name": "Wind Slash",
		"spell_type":   "wind",
		"mp_cost":      10,
		"range":        2,
		"base_power":   90,
		"target_type":  "enemy",
		# Wind disrupts footing — slow for 1 turn
		"status_effect": {"id": "slow", "duration": 1, "magnitude": 0.0, "damage_type": "pure"},
	},
	"mighty_strike": {
		"display_name": "Mighty Strike",
		"spell_type":   "physical",
		"mp_cost":      8,
		"range":        1,
		"base_power":   150,
		"target_type":  "enemy",
		# Pure damage — no status
	},
	# ── Enemy abilities ───────────────────────────────────────────────────────
	"dark_breath": {
		"display_name": "Dark Breath",
		"spell_type":   "dark",
		"mp_cost":      18,
		"range":        2,
		"base_power":   130,
		"target_type":  "enemy",
		# Void corruption — poisons for 3 turns (6 % max HP/turn, dark damage)
		"status_effect": {"id": "poison", "duration": 3, "magnitude": 0.06, "damage_type": "dark"},
	},
	"thunderstrike": {
		"display_name": "Thunderstrike",
		"spell_type":   "thunder",
		"mp_cost":      14,
		"range":        4,
		"base_power":   105,
		"target_type":  "enemy",
		# Heavy lightning — slows for 2 turns
		"status_effect": {"id": "slow", "duration": 2, "magnitude": 0.0, "damage_type": "pure"},
	},
	"void_pulse": {
		"display_name": "Void Pulse",
		"spell_type":   "dark",
		"mp_cost":      12,
		"range":        3,
		"base_power":   95,
		"target_type":  "enemy",
		# Void energy seals magic — silences for 2 turns
		"status_effect": {"id": "silence", "duration": 2, "magnitude": 0.0, "damage_type": "pure"},
	},
}


static func get_ability(id: String) -> Dictionary:
	return ABILITIES.get(id, {})
