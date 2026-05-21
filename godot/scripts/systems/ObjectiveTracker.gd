## ObjectiveTracker.gd — All objective types including destroy_anchor.
class_name ObjectiveTracker
extends Node

var map_data:     MapData
var units:        Array[Unit] = []
var surface_states: Dictionary = {}   # shared ref to ElementalSystem.surface_states
var turns_elapsed: int = 0

signal objective_updated(progress_text: String)


func initialize(p_map_data: MapData, p_units: Array[Unit]) -> void:
	map_data = p_map_data
	units    = p_units
	objective_updated.emit(get_progress_text())


func is_victory() -> bool:
	match map_data.objective_type:
		"defeat_all":
			return _all_enemies_dead()
		"destroy_anchor":
			# Victory when no void_anchor surface state remains
			for pos in surface_states:
				if surface_states[pos] == "void_anchor": return false
			# Also check if map had an anchor and it's been destroyed
			return _anchor_destroyed()
		"reach_tile":
			var tx: int = int(_map_value("objective_tile_x", -1))
			var ty: int = int(_map_value("objective_tile_y", -1))
			if tx < 0: return _all_enemies_dead()
			return units.any(func(u: Unit) -> bool:
				return u.team == "player" and u.hp > 0 and u.grid_pos.x == tx and u.grid_pos.y == ty)
		"protect_unit":
			var protected_id: String = str(_map_value("protected_unit_id", ""))
			var protected := units.filter(func(u: Unit) -> bool: return u.unit_data.id == protected_id)
			return _all_enemies_dead() and (protected.is_empty() or protected[0].hp > 0)
		"survive_turns":
			return turns_elapsed >= int(_map_value("survive_turns", 5))
		_:
			return _all_enemies_dead()


func is_defeat() -> bool:
	return units.all(func(u: Unit) -> bool: return u.team != "player" or u.hp <= 0)


func on_unit_defeated(_unit_id: String) -> void:
	objective_updated.emit(get_progress_text())


func on_turn_advanced() -> void:
	turns_elapsed += 1
	objective_updated.emit(get_progress_text())


func get_progress_text() -> String:
	match map_data.objective_type:
		"defeat_all":
			var remaining := units.filter(func(u: Unit) -> bool: return u.team == "enemy" and u.hp > 0).size()
			if remaining > 0:
				return "Defeat all enemies - %d remaining." % remaining
			return "All enemies defeated."
		"destroy_anchor":
			if _anchor_destroyed():
				return "Anchor destroyed!"
			return "Destroy the Void Anchor - use a holy ability on it."
		"reach_tile":
			return "Reach tile (%d, %d)." % [int(_map_value("objective_tile_x", 0)), int(_map_value("objective_tile_y", 0))]
		"protect_unit":
			return "Defeat all enemies. Protect your unit."
		"survive_turns":
			var left := maxi(0, int(_map_value("survive_turns", 5)) - turns_elapsed)
			if left == 0:
				return "Survived."
			var suffix := ""
			if left != 1:
				suffix = "s"
			return "Survive %d more turn%s." % [left, suffix]
		_:
			return str(_map_value("objective_label", "Objective in progress."))


func _all_enemies_dead() -> bool:
	return units.all(func(u: Unit) -> bool: return u.team != "enemy" or u.hp <= 0)


func _anchor_destroyed() -> bool:
	# Anchor is destroyed if any surface state that WAS void_anchor is now gone
	# We track this by checking if the map had an anchor tile and no anchor-type
	# units/surfaces remain
	if map_data.objective_type != "destroy_anchor": return false
	# Check if any enemy tagged as anchor-guardian is still alive
	var anchor_guardians := units.filter(func(u: Unit) -> bool:
		return u.team == "enemy" and bool(u.unit_data.get("is_anchor_guardian")) and u.hp > 0)
	if anchor_guardians.size() > 0: return false
	return _all_enemies_dead()


func _map_value(property_name: String, fallback: Variant) -> Variant:
	if not map_data:
		return fallback
	var value: Variant = map_data.get(property_name)
	if value == null:
		return fallback
	return value
