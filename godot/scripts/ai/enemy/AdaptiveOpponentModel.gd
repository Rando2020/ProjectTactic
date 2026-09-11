class_name AdaptiveOpponentModel
extends RefCounted

## A fair, inspectable opponent model built only from completed player actions.
##
## It does not read future input, hidden choices, or future RNG. The model stores
## decaying tendencies that enemy intent code may use as a bounded scoring nudge.

const PROFILE_VERSION := 1
const DECAY_PER_TURN := 0.94
const MAX_SIGNAL := 1.0
const OBSERVATIONS_FOR_FULL_CONFIDENCE := 18.0

var _observation_count: int = 0
var _turns_observed: int = 0
var _global: Dictionary = {}
var _per_unit: Dictionary = {}
var _recent_actions: Array[Dictionary] = []


func _init() -> void:
	reset()


func reset() -> void:
	_observation_count = 0
	_turns_observed = 0
	_global = {
		"offensive_actions": 0.0,
		"basic_attacks": 0.0,
		"ability_actions": 0.0,
		"ranged_actions": 0.0,
		"low_hp_aggression": 0.0,
		"aggressive_moves": 0.0,
		"total_moves": 0.0,
		"cluster_signal": 0.0,
		"turn_samples": 0.0,
	}
	_per_unit.clear()
	_recent_actions.clear()


func observe_move(
	actor_id: String,
	distance_before: int,
	distance_after: int,
	tiles_moved: int
) -> void:
	if actor_id.is_empty() or tiles_moved <= 0:
		return
	_observation_count += 1
	_global["total_moves"] = float(_global.get("total_moves", 0.0)) + 1.0
	var unit := _unit_profile(actor_id)
	unit["moves"] = float(unit.get("moves", 0.0)) + 1.0
	if distance_after < distance_before:
		_global["aggressive_moves"] = float(_global.get("aggressive_moves", 0.0)) + 1.0
		unit["aggressive_moves"] = float(unit.get("aggressive_moves", 0.0)) + 1.0
	_recent(actor_id, "move", {
		"distance_before": distance_before,
		"distance_after": distance_after,
		"tiles_moved": tiles_moved,
	})


func observe_action(
	actor_id: String,
	action_kind: String,
	metadata: Dictionary = {}
) -> void:
	if actor_id.is_empty():
		return
	var normalized := action_kind.to_lower()
	if normalized not in ["basic_attack", "ability", "wait"]:
		return
	_observation_count += 1
	var unit := _unit_profile(actor_id)
	unit["actions"] = float(unit.get("actions", 0.0)) + 1.0
	if normalized == "wait":
		unit["waits"] = float(unit.get("waits", 0.0)) + 1.0
		_recent(actor_id, normalized, metadata)
		return

	_global["offensive_actions"] = float(_global.get("offensive_actions", 0.0)) + 1.0
	unit["offensive_actions"] = float(unit.get("offensive_actions", 0.0)) + 1.0
	if normalized == "basic_attack":
		_global["basic_attacks"] = float(_global.get("basic_attacks", 0.0)) + 1.0
		unit["basic_attacks"] = float(unit.get("basic_attacks", 0.0)) + 1.0
	else:
		_global["ability_actions"] = float(_global.get("ability_actions", 0.0)) + 1.0
		unit["ability_actions"] = float(unit.get("ability_actions", 0.0)) + 1.0

	var action_range := int(metadata.get("range", 1))
	if action_range > 1:
		_global["ranged_actions"] = float(_global.get("ranged_actions", 0.0)) + 1.0
		unit["ranged_actions"] = float(unit.get("ranged_actions", 0.0)) + 1.0

	var hp_ratio := clampf(float(metadata.get("actor_hp_ratio", 1.0)), 0.0, 1.0)
	if hp_ratio <= 0.35:
		_global["low_hp_aggression"] = float(_global.get("low_hp_aggression", 0.0)) + 1.0
		unit["low_hp_aggression"] = float(unit.get("low_hp_aggression", 0.0)) + 1.0

	var damage := maxf(float(metadata.get("damage", 0.0)), 0.0)
	var healing := maxf(float(metadata.get("healing", 0.0)), 0.0)
	unit["damage_contribution"] = float(unit.get("damage_contribution", 0.0)) + damage
	unit["healing_contribution"] = float(unit.get("healing_contribution", 0.0)) + healing
	unit["threat_value"] = float(unit.get("threat_value", 0.0)) + damage + healing * 0.65

	var element := str(metadata.get("element", ""))
	if not element.is_empty():
		var elements: Dictionary = unit.get("elements", {})
		elements[element] = float(elements.get(element, 0.0)) + 1.0
		unit["elements"] = elements

	_recent(actor_id, normalized, metadata)


func observe_turn_end(player_positions: Array[Vector2i]) -> void:
	_turns_observed += 1
	_decay()
	if player_positions.size() < 2:
		return
	var pairs := 0
	var close_pairs := 0
	for i in range(player_positions.size()):
		for j in range(i + 1, player_positions.size()):
			pairs += 1
			if _manhattan(player_positions[i], player_positions[j]) <= 2:
				close_pairs += 1
	if pairs <= 0:
		return
	var sample := float(close_pairs) / float(pairs)
	_global["cluster_signal"] = clampf(float(_global.get("cluster_signal", 0.0)) * 0.70 + sample * 0.30, 0.0, MAX_SIGNAL)
	_global["turn_samples"] = float(_global.get("turn_samples", 0.0)) + 1.0


func confidence() -> float:
	return clampf(float(_observation_count) / OBSERVATIONS_FOR_FULL_CONFIDENCE, 0.0, 1.0)


func signals() -> Dictionary:
	var offensive := maxf(float(_global.get("offensive_actions", 0.0)), 1.0)
	var moves := maxf(float(_global.get("total_moves", 0.0)), 1.0)
	return {
		"confidence": confidence(),
		"ability_preference": _ratio(float(_global.get("ability_actions", 0.0)), offensive),
		"ranged_preference": _ratio(float(_global.get("ranged_actions", 0.0)), offensive),
		"low_hp_aggression": _ratio(float(_global.get("low_hp_aggression", 0.0)), offensive),
		"aggressive_movement": _ratio(float(_global.get("aggressive_moves", 0.0)), moves),
		"clustering": clampf(float(_global.get("cluster_signal", 0.0)), 0.0, MAX_SIGNAL),
		"observations": _observation_count,
		"turns_observed": _turns_observed,
	}


func target_priority(target_id: String) -> float:
	## Returns 0..1 and is intentionally meaningless at low confidence.
	if target_id.is_empty() or not _per_unit.has(target_id):
		return 0.0
	var max_threat := 0.0
	for key in _per_unit.keys():
		var candidate: Dictionary = _per_unit[key]
		max_threat = maxf(max_threat, float(candidate.get("threat_value", 0.0)))
	if max_threat <= 0.0:
		return 0.0
	var unit: Dictionary = _per_unit[target_id]
	var raw := clampf(float(unit.get("threat_value", 0.0)) / max_threat, 0.0, 1.0)
	return raw * confidence()


func aoe_adaptation_signal() -> float:
	var s := signals()
	return clampf(float(s.get("clustering", 0.0)) * float(s.get("confidence", 0.0)), 0.0, 1.0)


func ranged_pressure_signal(target_id: String = "") -> float:
	var s := signals()
	var global_signal := float(s.get("ranged_preference", 0.0)) * float(s.get("confidence", 0.0))
	if target_id.is_empty() or not _per_unit.has(target_id):
		return clampf(global_signal, 0.0, 1.0)
	var unit: Dictionary = _per_unit[target_id]
	var offensive := maxf(float(unit.get("offensive_actions", 0.0)), 1.0)
	var local_signal := _ratio(float(unit.get("ranged_actions", 0.0)), offensive)
	return clampf((global_signal + local_signal * confidence()) * 0.5, 0.0, 1.0)


func explanation_for_target(target_id: String) -> Dictionary:
	if confidence() < 0.25 or target_id.is_empty() or not _per_unit.has(target_id):
		return {}
	var priority := target_priority(target_id)
	var ranged := ranged_pressure_signal(target_id)
	var unit: Dictionary = _per_unit[target_id]
	var offensive := maxf(float(unit.get("offensive_actions", 0.0)), 1.0)
	var low_hp := _ratio(float(unit.get("low_hp_aggression", 0.0)), offensive) * confidence()
	var reason := ""
	var strength := 0.0
	if priority >= 0.45:
		reason = "high observed contribution"
		strength = priority
	if ranged > strength and ranged >= 0.45:
		reason = "repeated ranged pressure"
		strength = ranged
	if low_hp > strength and low_hp >= 0.45:
		reason = "repeated aggression while wounded"
		strength = low_hp
	if reason.is_empty():
		return {}
	return {
		"reason": reason,
		"strength": clampf(strength, 0.0, 1.0),
		"confidence": confidence(),
	}


func to_dict() -> Dictionary:
	return {
		"version": PROFILE_VERSION,
		"observation_count": _observation_count,
		"turns_observed": _turns_observed,
		"global": _global.duplicate(true),
		"per_unit": _per_unit.duplicate(true),
		"recent_actions": _recent_actions.duplicate(true),
	}


func load_dict(data: Dictionary) -> void:
	reset()
	if int(data.get("version", -1)) != PROFILE_VERSION:
		return
	_observation_count = maxi(int(data.get("observation_count", 0)), 0)
	_turns_observed = maxi(int(data.get("turns_observed", 0)), 0)
	if data.get("global", {}) is Dictionary:
		_global.merge(data.get("global", {}), true)
	if data.get("per_unit", {}) is Dictionary:
		_per_unit = data.get("per_unit", {}).duplicate(true)
	if data.get("recent_actions", []) is Array:
		_recent_actions = data.get("recent_actions", []).duplicate(true)
	while _recent_actions.size() > 16:
		_recent_actions.pop_front()


func _unit_profile(actor_id: String) -> Dictionary:
	if not _per_unit.has(actor_id):
		_per_unit[actor_id] = {
			"actions": 0.0,
			"offensive_actions": 0.0,
			"basic_attacks": 0.0,
			"ability_actions": 0.0,
			"ranged_actions": 0.0,
			"low_hp_aggression": 0.0,
			"moves": 0.0,
			"aggressive_moves": 0.0,
			"waits": 0.0,
			"damage_contribution": 0.0,
			"healing_contribution": 0.0,
			"threat_value": 0.0,
			"elements": {},
		}
	return _per_unit[actor_id]


func _decay() -> void:
	for key in _global.keys():
		if key in ["cluster_signal", "turn_samples"]:
			continue
		if _global[key] is float or _global[key] is int:
			_global[key] = float(_global[key]) * DECAY_PER_TURN
	for actor_id in _per_unit.keys():
		var unit: Dictionary = _per_unit[actor_id]
		for key in unit.keys():
			if key == "elements":
				var elements: Dictionary = unit[key]
				for element in elements.keys():
					elements[element] = float(elements[element]) * DECAY_PER_TURN
				continue
			if unit[key] is float or unit[key] is int:
				unit[key] = float(unit[key]) * DECAY_PER_TURN


func _recent(actor_id: String, kind: String, metadata: Dictionary) -> void:
	_recent_actions.append({
		"actor_id": actor_id,
		"kind": kind,
		"metadata": metadata.duplicate(true),
	})
	while _recent_actions.size() > 16:
		_recent_actions.pop_front()


func _ratio(numerator: float, denominator: float) -> float:
	if denominator <= 0.0:
		return 0.0
	return clampf(numerator / denominator, 0.0, 1.0)


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)
