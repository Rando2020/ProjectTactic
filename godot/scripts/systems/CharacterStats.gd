class_name CharacterStats
extends RefCounted

const BASE := {
	"zane": {"level": 11, "hp": 320, "mp": 90, "move": 4, "jump": 2, "speed": 8, "physical": 42, "magic": 48, "max_temper": 80, "max_ether": 110, "attack_range_min": 1, "attack_range_max": 1},
	"mira": {"level": 10, "hp": 280, "mp": 120, "move": 4, "jump": 2, "speed": 7, "physical": 28, "magic": 54, "max_temper": 65, "max_ether": 130, "attack_range_min": 1, "attack_range_max": 1},
	"kael": {"level": 12, "hp": 380, "mp": 55, "move": 4, "jump": 2, "speed": 6, "physical": 55, "magic": 32, "max_temper": 110, "max_ether": 70, "attack_range_min": 1, "attack_range_max": 1},
	"lyra": {"level": 10, "hp": 240, "mp": 70, "move": 4, "jump": 2, "speed": 9, "physical": 52, "magic": 18, "max_temper": 55, "max_ether": 65, "attack_range_min": 2, "attack_range_max": 4},
}

static func calculate(uid: String, registry: Dictionary, items: Array, permanent: Dictionary = {}, configured: Dictionary = {}) -> Dictionary:
	var result: Dictionary = BASE.get(uid, {}).duplicate()
	if result.is_empty():
		return result
	result.merge(configured, true)
	var configured_speed := int(result.speed)
	result["physical_resistance"] = 0
	result["magic_resistance"] = 0
	var bonuses := JobTreeData.compute_stat_bonuses(registry.get("job_jp", {}))
	for key in bonuses:
		var stat: String = "hp" if key == "max_hp" else str(key)
		result[stat] = int(result.get(stat, 0)) + int(bonuses[key])
	for stat in permanent:
		result[stat] = int(result.get(stat, 0)) + int(permanent[stat])
	var equipment: Dictionary = registry.get("equipment", {})
	var seen: Array[String] = []
	for slot in equipment:
		var item := EquipmentRules.find_item(items, str(equipment[slot]))
		if item.is_empty() or EquipmentRules.slot_for(item) != slot or str(item.id) in seen:
			continue
		seen.append(str(item.id))
		for affix in item.get("affixes", []):
			var stat: String = EquipmentRules.STATS.get(str(affix.get("id", "")), "")
			if not stat.is_empty():
				result[stat] = int(result.get(stat, 0)) + int(affix.get("value", 0))
	if configured_speed > 0:
		result.speed = maxi(1, int(result.speed))
	result.hp = maxi(1, int(result.hp))
	return result
