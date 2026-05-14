extends RefCounted
class_name PTStatusEffectSystem


static func apply_statuses(unit: Dictionary, statuses: Array) -> Dictionary:
	if not unit.has("statuses"):
		unit["statuses"] = []
	for status in statuses:
		var normalized := {
			"id": String(status.get("id", "")),
			"duration": int(status.get("duration", 1)),
			"stacks": int(status.get("stacks", 1)),
		}
		if normalized["id"] == "":
			continue
		_replace_or_add(unit["statuses"], normalized)
	return unit


static func start_turn_tick(unit: Dictionary, definitions: Dictionary) -> Dictionary:
	var remaining: Array = []
	for status in unit.get("statuses", []):
		var status_id := String(status.get("id", ""))
		var definition: Dictionary = definitions.get(status_id, {})
		if definition.get("tickDamage", 0) > 0:
			unit["hp"] = max(0, int(unit["hp"]) - int(definition["tickDamage"]))
		status["duration"] = int(status.get("duration", 1)) - 1
		if int(status["duration"]) > 0:
			remaining.append(status)
	unit["statuses"] = remaining
	return unit


static func movement_modifier(unit: Dictionary, definitions: Dictionary) -> int:
	var modifier := 0
	for status in unit.get("statuses", []):
		var definition: Dictionary = definitions.get(String(status.get("id", "")), {})
		modifier += int(definition.get("moveModifier", 0))
	return modifier


static func _replace_or_add(statuses: Array, next_status: Dictionary) -> void:
	for i in range(statuses.size()):
		if String(statuses[i].get("id", "")) == String(next_status["id"]):
			statuses[i] = next_status
			return
	statuses.append(next_status)
