class_name WandererDB
extends RefCounted

const WANDERERS := [
	{
		"id": "ember-knight-solara",
		"name": "Ember Knight Solara",
		"title": "Disgraced Ashvale Watch Captain",
		"type": "challenger",
		"rarity": "uncommon",
		"floor_min": 1,
		"element": "fire",
		"teaches": "blaze-counter",
		"greeting": "You fight like a Watch soldier. Prove it. Face me.",
		"condition": {"type": "challenge", "label": "Accept her duel"},
		"reward": {"type": "secret-skill", "skill_id": "blaze-counter"},
	},
	{
		"id": "archive-mage-volant",
		"name": "Archive Mage Volant",
		"title": "Bellkeeper Researcher",
		"type": "teacher",
		"rarity": "uncommon",
		"floor_min": 1,
		"element": "holy",
		"teaches": "leyline-burst",
		"greeting": "I can show you how to channel a ley confluence. Knowledge has a cost.",
		"condition": {"type": "pay", "label": "Pay for the technique", "cost": 80, "currency": Currency.RUN_AETHER},
		"reward": {"type": "secret-skill", "skill_id": "leyline-burst"},
	},
	{
		"id": "void-scholar-thresh",
		"name": "Void Scholar Thresh",
		"title": "Former Null Conclave Researcher",
		"type": "teacher",
		"rarity": "rare",
		"floor_min": 2,
		"element": "dark",
		"teaches": "null-break",
		"greeting": "Destroy one of their elites while I watch. Then we talk.",
		"condition": {"type": "witness-elite-kill", "label": "Kill an Elite while Thresh watches"},
		"reward": {"type": "secret-skill", "skill_id": "null-break"},
	},
	{
		"id": "storm-duelist-kira",
		"name": "Storm Duelist Kira",
		"title": "Stormglass Bastion Dropout",
		"type": "challenger",
		"rarity": "uncommon",
		"floor_min": 2,
		"element": "thunder",
		"teaches": "arc-counter",
		"greeting": "The Bastion said my timing was wrong. Show me yours.",
		"condition": {"type": "challenge", "label": "Accept her duel"},
		"reward": {"type": "secret-skill", "skill_id": "arc-counter"},
	},
	{
		"id": "the-wandering-null",
		"name": "The Wandering Null",
		"title": "Unknown",
		"type": "teacher",
		"rarity": "legendary",
		"floor_min": 3,
		"element": "resonance",
		"teaches": "resonance-fracture",
		"greeting": "...",
		"condition": {"type": "flawless-floor", "label": "Complete this floor without taking damage"},
		"reward": {"type": "secret-skill", "skill_id": "resonance-fracture"},
	},
	{
		"id": "mirefen-seer-yuna",
		"name": "Mirefen Seer Yuna",
		"title": "Reedfolk Elder",
		"type": "scholar",
		"rarity": "rare",
		"floor_min": 2,
		"element": "water",
		"greeting": "The water showed me your path. I will share what waits ahead.",
		"condition": {"type": "free", "label": "Listen to her reading"},
		"reward": {"type": "reveal-and-boon", "reveal_floors": 2, "boon_rarity": "rare"},
	},
	{
		"id": "shadow-of-vaelthorn",
		"name": "Shadow of Vaelthorn",
		"title": "Corrupted Echo of the Dark Guardian",
		"type": "hostile",
		"rarity": "legendary",
		"floor_min": 3,
		"element": "dark",
		"teaches": "dark-echo",
		"greeting": "You carry the resonance. I will take it from you.",
		"condition": {"type": "defeat", "label": "Defeat the Shadow"},
		"reward": {"type": "secret-skill", "skill_id": "dark-echo"},
	},
	{
		"id": "lost-innocent",
		"name": "Lost Innocent",
		"title": "Wandering Soul",
		"type": "innocent",
		"rarity": "common",
		"floor_min": 1,
		"element": "none",
		"greeting": "If you get me to the end of the floor safely, I will share what I know.",
		"condition": {"type": "escort", "label": "Escort safely to floor end"},
		"reward": {"type": "random-common-or-jp", "jp_amount": 25},
	},
]

static func get_wanderer(wanderer_id: String) -> Dictionary:
	for wanderer: Dictionary in WANDERERS:
		if wanderer.get("id", "") == wanderer_id:
			return wanderer.duplicate(true)
	return {}

static func get_pool_for_floor(floor_number: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for wanderer: Dictionary in WANDERERS:
		if int(wanderer.get("floor_min", 1)) <= floor_number:
			pool.append(wanderer.duplicate(true))
	return pool

static func pick_for_floor(floor_number: int, rng: RandomNumberGenerator) -> Dictionary:
	var pool := get_pool_for_floor(floor_number)
	if pool.is_empty():
		return {}
	return pool[rng.randi_range(0, pool.size() - 1)].duplicate(true)
