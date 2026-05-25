## WandererData.gd
## GDScript definitions for all 10 wandering characters.
## Mirror of src/game/data/wanderers.js

class_name WandererData
extends RefCounted

const WANDERERS: Array[Dictionary] = [
	{
		"id": "ember_knight_solara", "type": "challenger",
		"name": "Ember Knight Solara", "title": "Disgraced Ashvale Watch Captain",
		"element": "fire", "portrait":"?", "teaches": "blaze_counter",
		"floor_min": 1,
		"greeting": '"You fight like a Watch soldier. That\'s not a compliment  but it means you know what you\'re doing. Prove it."',
		"accept_msg": '"Good. Come on then."',
		"decline_msg": '"Smart. Or cowardly. Hard to tell from here."',
		"reward_msg": '"...Decent. Here  the technique that got me stripped of my rank." [Teaches Blaze Counter]',
		"condition": { "type": "pay", "label": "Pay 60g for the lesson", "cost": 60 },
		"alt_condition": { "type": "challenge", "label": "Accept her duel instead (free)", "subtype": "duel" },
		"reward": { "type": "secret_skill", "skill_id": "blaze_counter" },
	},
	{
		"id": "archive_mage_volant", "type": "teacher",
		"name": "Archive Mage Volant", "title": "Bellkeeper Researcher",
		"element": "holy", "portrait":"?", "teaches": "leyline_burst",
		"floor_min": 1,
		"greeting": '"Twelve years cataloguing resonance events. I\'ll share one technique  for a price."',
		"accept_msg": '"The knowledge costs 80g. Consider it a research donation."',
		"decline_msg": '"As you wish. The ley lines will remain uncharted."',
		"reward_msg": '"Here. Don\'t waste it." [Teaches Leyline Burst]',
		"poor_msg": '"You don\'t have enough. Come back when you\'ve earned more than dust."',
		"condition": { "type": "pay", "label": "Pay 80g", "cost": 80 },
		"alt_condition": {
			"type": "answer", "label": "Answer his question (skip the gold)",
			"question": "What element does a Bellkeeper record but never wields?",
			"answer": "resonance",
		},
		"reward": { "type": "secret_skill", "skill_id": "leyline_burst" },
	},
	{
		"id": "void_scholar_thresh", "type": "teacher",
		"name": "Void Scholar Thresh", "title": "Former Null Conclave Researcher",
		"element": "dark", "portrait":"?", "teaches": "null_break",
		"floor_min": 2,
		"greeting": '"I left the Conclave. We have that in common. Kill one of their elites while I watch  then we\'ll talk."',
		"condition_met_msg": '"You did it. Here  this is how the Anchors are actually held together." [Teaches Null-Break]',
		"decline_msg": '"Then go."',
		"condition": { "type": "witness_elite_kill", "label": "Kill an Elite enemy while Thresh watches" },
		"reward": { "type": "secret_skill", "skill_id": "null_break" },
	},
	{
		"id": "storm_duelist_kira", "type": "challenger",
		"name": "Storm Duelist Kira", "title": "Stormglass Bastion Dropout",
		"element": "thunder", "portrait":"?", "teaches": "arc_counter",
		"floor_min": 2,
		"greeting": '"The Bastion said my timing was wrong. I disagreed. Show me your timing."',
		"accept_msg": '"Good. I fight fast. Keep up."',
		"decline_msg": '"Shame. I had a technique worth sharing."',
		"reward_msg": '"...You have good timing. Here." [Teaches Arc Counter]',
		"condition": { "type": "pay", "label": "Pay 50g  she respects gold", "cost": 50 },
		"alt_condition": { "type": "challenge", "label": "Accept her duel", "subtype": "duel" },
		"reward": { "type": "secret_skill", "skill_id": "arc_counter" },
	},
	{
		"id": "the_wandering_null", "type": "teacher",
		"name": "The Wandering Null", "title": "Unknown",
		"element": "resonance", "portrait":"?", "teaches": "resonance_fracture",
		"floor_min": 3,
		"greeting": '"..."',
		"condition_met_msg": '"..." [The void around them briefly shatters. You understand something new.] [Teaches Resonance Fracture]',
		"decline_msg": '"..."',
		"condition": { "type": "flawless_floor", "label": "Complete this floor without taking damage" },
		"reward": { "type": "secret_skill", "skill_id": "resonance_fracture" },
	},
	{
		"id": "chaplain_aldis", "type": "teacher",
		"name": "Chaplain Aldis", "title": "Traveling Luminarch Devotee",
		"element": "holy", "portrait":"?", "teaches": "last_rites",
		"floor_min": 1,
		"greeting": '"Luminarch\'s grace extends even here. I teach what I can to those worth teaching."',
		"accept_msg": '"The technique is old. Older than the Bellkeepers. Here."',
		"decline_msg": '"Then go. Luminarch keeps no one against their will."',
		"reward_msg": '"Here." [Teaches Last Rites]',
		"condition": { "type": "pay", "label": "Donate 40g to his mission", "cost": 40 },
		"alt_condition": { "type": "party_full_hp", "label": "Arrive with party at full HP" },
		"reward": { "type": "secret_skill", "skill_id": "last_rites" },
	},
	{
		"id": "iron_duelist_garek", "type": "merchant",
		"name": "Iron Duelist Garek", "title": "Mercenary Knight",
		"element": "", "portrait":"?", "teaches": "sunder_armor",
		"floor_min": 1,
		"greeting": '"I work for gold. You want the technique, it costs sixty."',
		"accept_msg": '"Gold? Always."',
		"poor_msg": '"Come back with sixty."',
		"reward_msg": '"Here. Don\'t thank me." [Teaches Sunder Armor]',
		"condition": { "type": "pay", "label": "Pay 60g", "cost": 60 },
		"reward": { "type": "secret_skill", "skill_id": "sunder_armor" },
	},
	{
		"id": "mirefen_seer_yuna", "type": "scholar",
		"name": "Mirefen Seer Yuna", "title": "Reedfolk Elder",
		"element": "water", "portrait":"?", "teaches": "",
		"floor_min": 2,
		"greeting": '"The water showed me your path. All of it  the elites, the boons, the thing waiting at the end. I\'ll share."',
		"reward_msg": '"Here is what waits ahead." [Reveals all elite affixes on this floor and the next] [Grants one random Rare boon]',
		"condition": { "type": "free", "label": "Listen to her reading" },
		"reward": { "type": "reveal_and_boon", "reveal_floors": 2, "boon_rarity": "rare" },
	},
	{
		"id": "shadow_of_vaelthorn", "type": "hostile",
		"name": "Shadow of Vaelthorn", "title": "Corrupted Echo",
		"element": "dark", "portrait":"?", "teaches": "dark_echo",
		"floor_min": 3,
		"greeting": '"You carry the resonance. I\'ll take it from you."',
		"reward_msg": '"...The echo remains." [Dark Echo skill fragment found]',
		"condition": { "type": "defeat", "label": "Defeat the Shadow in combat" },
		"reward": { "type": "secret_skill", "skill_id": "dark_echo" },
	},
	{
		"id": "lost_innocent", "type": "innocent",
		"name": "Lost Innocent", "title": "Wandering Soul",
		"element": "", "portrait":"?", "teaches": "",
		"floor_min": 1,
		"greeting": '"Oh! A person! I\'ve been lost in here for  I don\'t know how long. Get me to the end of the floor safely?"',
		"survived_msg": '"Thank you! Here  I\'ve been absorbing the energy of this place." [Grants +25 JP all OR a random Common boon]',
		"condition": { "type": "escort", "label": "Escort them through the floor" },
		"reward": { "type": "jp_or_boon", "jp_amount": 25, "boon_rarity": "common" },
	},
]

static func get_wanderer(wanderer_id: String) -> Dictionary:
	for w: Dictionary in WANDERERS:
		if w["id"] == wanderer_id: return w
	return {}

static func get_for_floor(floor: int, rng_val: float, exclude_ids: Array = []) -> Dictionary:
	var pool := WANDERERS.filter(func(w: Dictionary) -> bool:
		return w["floor_min"] <= floor and not exclude_ids.has(w["id"]))
	if pool.is_empty(): return {}
	return pool[int(rng_val * pool.size())]
