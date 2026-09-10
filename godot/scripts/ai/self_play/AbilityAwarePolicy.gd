class_name AbilityAwarePolicy
extends RefCounted

## Transparent evaluation policy that values useful abilities without replacing the
## existing greedy/random controls. It exists to reveal whether real character kits
## create tactically credible alternatives to basic attack, move, and wait.

var policy_id := "ability-aware-v1"


func uses_ability_actions() -> bool:
	return true


func choose_action(actions: Array[Dictionary]) -> Dictionary:
	if actions.is_empty():
		return {}
	var best: Dictionary = actions[0]
	var best_score := _score(best)
	var best_key := _tie_key(best)
	for index in range(1, actions.size()):
		var candidate: Dictionary = actions[index]
		var score := _score(candidate)
		var key := _tie_key(candidate)
		if score > best_score or (is_equal_approx(score, best_score) and key < best_key):
			best = candidate
			best_score = score
			best_key = key
	return best


func _score(action: Dictionary) -> float:
	var kind := str(action.get("kind", ""))
	match kind:
		"ability":
			var lethal_value := float(action.get("lethal_target_count", 0)) * 100000.0
			var damage_value := float(action.get("expected_damage", 0)) * 10.0
			var heal_value := float(action.get("expected_heal", 0)) * 8.0
			var status_value := float(action.get("status_target_count", 0)) * 120.0
			var area_value: float = maxf(float(action.get("target_count", 0)) - 1.0, 0.0) * 15.0
			var resource_cost := float(action.get("mp_cost", 0)) * 2.0
			return lethal_value + damage_value + heal_value + status_value + area_value - resource_cost
		"attack":
			return (100000.0 if bool(action.get("lethal", false)) else 0.0) \
				+ float(action.get("expected_damage", 0)) * 10.0
		"move":
			var enables_attack := 200.0 if bool(action.get("attack_available_after_move", false)) else 0.0
			var future_damage := float(action.get("best_attack_damage_after_move", 0)) * 5.0
			var distance := float(action.get("nearest_enemy_distance", 999))
			var height := float(action.get("height", 0))
			return enables_attack + future_damage - distance * 8.0 + height * 0.1
		"wait":
			return -1000.0
		_:
			return -10000.0


func _tie_key(action: Dictionary) -> String:
	var position: Dictionary = action.get("target_position", {})
	return "%s|%s|%s|%05d|%05d" % [
		str(action.get("action_id", "")),
		str(action.get("target_id", "")),
		str(action.get("ability_id", "")),
		int(position.get("x", -1)) + 10000,
		int(position.get("y", -1)) + 10000,
	]
