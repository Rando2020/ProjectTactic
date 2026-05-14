class_name AbilityDB
extends RefCounted

const ABILITIES: Dictionary = {
	# ── Player abilities ──────────────────────────────────────────────────────
	"fire": {
		"display_name": "Fire",
		"spell_type":   "fire",
		"mp_cost":      12,
		"range":        3,
		"base_power":   110,
		"target_type":  "enemy",
	},
	"blizzard": {
		"display_name": "Blizzard",
		"spell_type":   "blizzard",
		"mp_cost":      12,
		"range":        3,
		"base_power":   100,
		"target_type":  "enemy",
	},
	"thunder": {
		"display_name": "Thunder",
		"spell_type":   "thunder",
		"mp_cost":      15,
		"range":        4,
		"base_power":   120,
		"target_type":  "enemy",
	},
	"cure": {
		"display_name": "Cure",
		"spell_type":   "cure",
		"mp_cost":      8,
		"range":        3,
		"base_power":   80,
		"target_type":  "ally",
	},
	"holy": {
		"display_name": "Holy",
		"spell_type":   "holy",
		"mp_cost":      24,
		"range":        3,
		"base_power":   160,
		"target_type":  "enemy",
	},
	"wind_slash": {
		"display_name": "Wind Slash",
		"spell_type":   "wind",
		"mp_cost":      10,
		"range":        2,
		"base_power":   90,
		"target_type":  "enemy",
	},
	"mighty_strike": {
		"display_name": "Mighty Strike",
		"spell_type":   "physical",
		"mp_cost":      8,
		"range":        1,
		"base_power":   150,
		"target_type":  "enemy",
	},
	# ── Enemy abilities ───────────────────────────────────────────────────────
	"dark_breath": {
		"display_name": "Dark Breath",
		"spell_type":   "dark",
		"mp_cost":      18,
		"range":        2,
		"base_power":   130,
		"target_type":  "enemy",
	},
	"thunderstrike": {
		"display_name": "Thunderstrike",
		"spell_type":   "thunder",
		"mp_cost":      14,
		"range":        4,
		"base_power":   105,
		"target_type":  "enemy",
	},
	"void_pulse": {
		"display_name": "Void Pulse",
		"spell_type":   "dark",
		"mp_cost":      12,
		"range":        3,
		"base_power":   95,
		"target_type":  "enemy",
	},
}


static func get_ability(id: String) -> Dictionary:
	return ABILITIES.get(id, {})
