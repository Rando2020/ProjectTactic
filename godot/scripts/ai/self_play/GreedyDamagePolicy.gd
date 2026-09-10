class_name GreedyDamagePolicy
extends RefCounted

## Simple deterministic tactical baseline.
## Priorities: secure a lethal attack, maximize immediate attack damage, move into
## the strongest available attack, otherwise reduce distance, then wait.

var policy_id := "greedy-damage-v1"


func choose_action(actions: Array[Dictionary]) -> Dictionary:
	if actions.is_empty():
		return {}
	var best := actions[0]
	var best_score := _score(best)
	var best_key := _stable_key(best)
	for i in range(1, actions.size()):
		var candidate := actions[i]
		var score := _score(candidate)
		var key := _stable_key(candidate)
		if score > best_score or (is_equal_approx(score, best_score) and key < best_key):
			best = candidate
			best_score = score
			best_key = key
	return best.duplicate(true)


func _score(action: Dictionary) -> float:
	match str(action.get("kind", "")):
		"attack":
			var score := 5000.0 + float(action.get("expected_damage", 0)) * 10.0
			if bool(action.get("lethal", false)):
				score += 100000.0
			return score
		"move":
			var score := 1000.0
			if bool(action.get("attack_available_after_move", false)):
				score += 10000.0 + float(action.get("best_attack_damage_after_move", 0)) * 10.0
			score -= float(action.get("nearest_enemy_distance", 999999)) * 20.0
			score += float(action.get("height", 0))
			return score
		"wait":
			return -100000.0
	return -200000.0


func _stable_key(action: Dictionary) -> String:
	var pos: Dictionary = action.get("target_position", {})
	return "%s|%s|%05d|%05d" % [
		str(action.get("kind", "")),
		str(action.get("target_id", "")),
		int(pos.get("x", -1)) + 10000,
		int(pos.get("y", -1)) + 10000,
	]
