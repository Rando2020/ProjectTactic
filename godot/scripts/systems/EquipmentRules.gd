class_name EquipmentRules
extends RefCounted

const SLOTS := {"main_hand": "Weapon", "accessory": "Accessory", "charm": "Charm"}
const STATS := {"phys": "physical", "mag": "magic", "hp": "hp", "tmpr": "max_temper", "spd": "speed"}

static func starter_items() -> Array:
	return [
		{"id": "training-blade", "name": "Training Blade", "slot": "weapon", "rarity": "common", "affixes": [{"id": "phys", "label": "+6 Physical", "value": 6}]},
		{"id": "ashwood-focus", "name": "Ashwood Focus", "slot": "weapon", "rarity": "common", "affixes": [{"id": "mag", "label": "+6 Magic", "value": 6}]},
		{"id": "copper-band", "name": "Copper Band", "slot": "accessory", "rarity": "common", "affixes": [{"id": "hp", "label": "+20 Max HP", "value": 20}]},
		{"id": "hearth-ward", "name": "Hearth Ward", "slot": "charm", "rarity": "common", "affixes": [{"id": "tmpr", "label": "+10 Max Temper", "value": 10}]},
	]

static func slot_for(item: Dictionary) -> String:
	var slot := str(item.get("slot", ""))
	return "main_hand" if slot == "weapon" else slot

static func find_item(items: Array, id: String) -> Dictionary:
	for item in items:
		if item is Dictionary and str(item.get("id", "")) == id:
			return item
	return {}

static func supported(item: Dictionary) -> bool:
	if not SLOTS.has(slot_for(item)):
		return false
	for affix in item.get("affixes", []):
		if not STATS.has(str(affix.get("id", ""))):
			return false
	return true
