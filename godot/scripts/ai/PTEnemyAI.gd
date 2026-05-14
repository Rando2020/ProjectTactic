extends RefCounted
class_name PTEnemyAI


static func choose_action(enemy_index: int, units: Array, tiles: Dictionary, abilities_by_id: Dictionary, width: int, height: int) -> Dictionary:
	var enemy: Dictionary = units[enemy_index]
	var target_index := nearest_target(enemy_index, units, "player", width)
	if target_index < 0:
		return { "type": "wait" }

	var target: Dictionary = units[target_index]
	var best_ability := best_available_ability(enemy, target, abilities_by_id, width)
	if best_ability != "":
		return { "type": "ability", "target": target_index, "abilityId": best_ability }

	var occupied := occupied_tiles(units, enemy_index)
	var next_tile := PTPathfinder.best_step_toward(enemy, int(target["tile"]), tiles, width, height, occupied)
	if next_tile != int(enemy["tile"]):
		return { "type": "move", "tile": next_tile, "target": target_index }
	return { "type": "wait" }


static func best_available_ability(enemy: Dictionary, target: Dictionary, abilities_by_id: Dictionary, width: int) -> String:
	var best_id := ""
	var best_power := -9999
	for ability_id in enemy.get("abilityIds", []):
		if not abilities_by_id.has(ability_id):
			continue
		var ability: Dictionary = abilities_by_id[ability_id]
		if int(enemy.get("mp", 0)) < int(ability.get("mpCost", 0)):
			continue
		if PTCombatResolver.can_target(enemy, target, ability, width) != "":
			continue
		var power := int(ability.get("power", 0))
		if power > best_power:
			best_power = power
			best_id = ability_id
	return best_id


static func nearest_target(from_index: int, units: Array, team: String, width: int) -> int:
	var best := -1
	var best_distance := 99999
	for i in range(units.size()):
		if units[i].get("team", "") != team or int(units[i].get("hp", 0)) <= 0:
			continue
		var distance := PTGridMath.manhattan(int(units[from_index]["tile"]), int(units[i]["tile"]), width)
		if distance < best_distance:
			best_distance = distance
			best = i
	return best


static func occupied_tiles(units: Array, ignore_index: int = -1) -> Dictionary:
	var occupied := {}
	for i in range(units.size()):
		if i == ignore_index or int(units[i].get("hp", 0)) <= 0:
			continue
		occupied[int(units[i]["tile"])] = i
	return occupied
