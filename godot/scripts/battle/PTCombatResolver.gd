extends RefCounted
class_name PTCombatResolver


static func can_target(caster: Dictionary, target: Dictionary, ability: Dictionary, width: int) -> String:
	if caster.get("hp", 0) <= 0:
		return "Caster is down."
	if target.get("hp", 0) <= 0:
		return "Target is down."
	var category := String(ability.get("category", "Melee"))
	var same_team := caster.get("team", "") == target.get("team", "")
	if PTBattleMath.is_hostile_category(category) and same_team:
		return "Choose an enemy target."
	if PTBattleMath.is_ally_category(category) and not same_team:
		return "Choose an ally target."
	var distance := PTGridMath.manhattan(int(caster["tile"]), int(target["tile"]), width)
	if distance > int(ability.get("range", 1)):
		return "Target is out of range."
	if int(caster.get("mp", 0)) < int(ability.get("mpCost", 0)):
		return "Not enough MP."
	return ""


static func resolve(caster: Dictionary, target: Dictionary, ability: Dictionary, caster_tile: Dictionary, target_tile: Dictionary) -> Dictionary:
	var result := {
		"damage": 0,
		"healing": 0,
		"statuses": [],
		"message": "",
	}
	var category := String(ability.get("category", "Melee"))
	if category == "Heal":
		result["healing"] = PTBattleMath.healing(caster, ability, caster_tile, target_tile)
	elif category == "Guard":
		result["statuses"] = [{ "id": "guarded", "duration": 1 }]
	elif category == "Support":
		result["statuses"] = ability.get("appliesStatuses", [])
	elif category == "Mobility":
		result["statuses"] = [{ "id": "evasive", "duration": 1 }]
	else:
		result["damage"] = PTBattleMath.damage(caster, target, ability, caster_tile, target_tile)
		result["statuses"] = ability.get("appliesStatuses", [])
	return result
