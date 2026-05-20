class_name BoonDB
extends RefCounted

const RARITY_WEIGHTS_BY_FLOOR := {
	1: {"common": 55, "rare": 30, "legendary": 12, "unique": 0},
	2: {"common": 45, "rare": 35, "legendary": 15, "unique": 0},
	3: {"common": 35, "rare": 40, "legendary": 18, "unique": 2},
	4: {"common": 25, "rare": 45, "legendary": 21, "unique": 4},
}

const BOONS := [
	{"id": "phoenix-heart", "name": "Phoenix Heart", "guardian": "phoenix", "rarity": "common", "description": "+10% max HP for this run. Healing effects are slightly stronger.", "tags": ["sustain", "fire", "guardian"], "effects": {"max_hp_percent": 0.10, "healing_mult": 1.10}},
	{"id": "ember-reprisal", "name": "Ember Reprisal", "guardian": "phoenix", "rarity": "rare", "description": "First time a unit drops below 35% HP each battle, ignite adjacent enemy tiles.", "tags": ["fire", "counter", "terrain"], "effects": {"trigger": "low_hp_once", "terrain": "burning"}},
	{"id": "titan-bulwark", "name": "Titan Bulwark", "guardian": "titan", "rarity": "common", "description": "+15% physical resistance while waiting or guarding.", "tags": ["defense", "earth", "guardian"], "effects": {"wait_physical_resist": 0.15}},
	{"id": "stone-oath", "name": "Stone Oath", "guardian": "titan", "rarity": "rare", "description": "After waiting, gain a one-hit shield at the start of the next turn.", "tags": ["defense", "shield", "tempo"], "effects": {"wait_grants_shield": 1}},
	{"id": "storm-quickening", "name": "Storm Quickening", "guardian": "storm", "rarity": "rare", "description": "+1 speed for the run. Thunder abilities have higher status chance.", "tags": ["speed", "thunder", "status"], "effects": {"speed_flat": 1, "thunder_status_bonus": 0.15}},
	{"id": "void-bargain", "name": "Void Bargain", "guardian": "void", "rarity": "legendary", "description": "+25% damage, but healing is reduced by 20% for the run.", "tags": ["risk", "damage", "dark"], "effects": {"damage_mult": 1.25, "healing_mult": 0.80}},
]

static func get_boon(boon_id: String) -> Dictionary:
	for boon: Dictionary in BOONS:
		if boon.get("id", "") == boon_id:
			return boon.duplicate(true)
	return {}

static func get_boons_by_guardian(guardian_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for boon: Dictionary in BOONS:
		if boon.get("guardian", "") == guardian_id:
			result.append(boon.duplicate(true))
	return result

static func get_weighted_rarity(floor_number: int, rng: RandomNumberGenerator) -> String:
	var key: int = clamp(floor_number, 1, 4)
	var weights: Dictionary = RARITY_WEIGHTS_BY_FLOOR.get(key, RARITY_WEIGHTS_BY_FLOOR[1])
	var total := 0
	for rarity: String in weights.keys():
		total += int(weights[rarity])
	var roll := rng.randi_range(1, max(total, 1))
	var cursor := 0
	for rarity: String in weights.keys():
		cursor += int(weights[rarity])
		if roll <= cursor:
			return rarity
	return "common"

static func generate_boon_options(rng: RandomNumberGenerator, floor_number: int = 1, option_count: int = 3) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var used: Dictionary = {}
	var attempts := 0
	while options.size() < option_count and attempts < 50:
		attempts += 1
		var rarity := get_weighted_rarity(floor_number, rng)
		var candidates: Array[Dictionary] = []
		for boon: Dictionary in BOONS:
			if boon.get("rarity", "common") == rarity and not used.has(boon.get("id", "")):
				candidates.append(boon)
		if candidates.is_empty():
			continue
		var picked: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
		used[picked.get("id", "")] = true
		options.append(picked.duplicate(true))
	return options
