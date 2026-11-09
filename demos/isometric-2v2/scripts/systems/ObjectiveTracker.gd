## ObjectiveTracker.gd - All objective types including destroy_anchor.
class_name ObjectiveTracker
extends Node

var map_data: MapData
var units: Array[Unit] = []
var surface_states: Dictionary = {}   # shared ref to ElementalSystem.surface_states
var turns_elapsed: int = 0

signal objective_updated(progress_text: String)


func initialize(p_map_data: MapData, p_units: Array[Unit]) -> void:
	map_data = p_map_data
	units = p_units


func is_victory() -> bool:
	match map_data.objective_type:
		"defeat_all":
			return _all_enemies_dead()
		"destroy_anchor":
			for pos in surface_states:
				if surface_states[pos] == "void_anchor":
					return false
			return _anchor_destroyed()
		"reach_tile":
			var tx: int = int(_map_value("objective_tile_x", -1))
			var ty: int = int(_map_value("objective_tile_y", -1))
			if tx < 0:
				return _all_enemies_dead()
			for value in units:
				var unit := _valid_unit(value)
				if unit and unit.team == "player" and unit.hp > 0 and unit.grid_pos.x == tx and unit.grid_pos.y == ty:
					return true
			return false
		"protect_unit":
			var protected_id: String = str(_map_value("protected_unit_id", ""))
			var protected_alive := true
			for value in units:
				var unit := _valid_unit(value)
				if unit and unit.unit_data and unit.unit_data.id == protected_id:
					protected_alive = unit.hp > 0
					break
			return _all_enemies_dead() and protected_alive
		"survive_turns":
			return turns_elapsed >= int(_map_value("survive_turns", 5))
		_:
			return _all_enemies_dead()


func is_defeat() -> bool:
	for value in units:
		var unit := _valid_unit(value)
		if unit and unit.team == "player" and unit.hp > 0:
			return false
	return true


func on_unit_defeated(_unit_id: String) -> void:
	if map_data and map_data.objective_type == "destroy_anchor":
		objective_updated.emit(get_progress_text())


func on_turn_advanced() -> void:
	turns_elapsed += 1
	objective_updated.emit(get_progress_text())


func get_progress_text() -> String:
	match map_data.objective_type:
		"defeat_all":
			var remaining := _living_enemy_count()
			return "Defeat all enemies - %d remaining." % remaining if remaining > 0 else "All enemies defeated."
		"destroy_anchor":
			if _anchor_destroyed():
				return "The Anchor shatters!"
			var anchor_hp := _first_living_enemy_hp("void_anchor")
			var golem_hp := _first_living_enemy_hp("void_golem")
			if golem_hp > 0:
				return "Defeat the Void Golem, then destroy the Anchor with holy abilities."
			if anchor_hp > 0:
				return "Anchor HP: %d - Hit it with holy abilities!" % anchor_hp
			return "Destroy the Void Anchor."
		"reach_tile":
			return "Reach tile (%d, %d)." % [int(_map_value("objective_tile_x", 0)), int(_map_value("objective_tile_y", 0))]
		"protect_unit":
			return "Defeat all enemies. Protect your unit."
		"survive_turns":
			var left := maxi(0, int(_map_value("survive_turns", 5)) - turns_elapsed)
			return "Survived." if left == 0 else "Survive %d more turn%s." % [left, "s" if left != 1 else ""]
		_:
			return str(_map_value("objective_label", "Objective in progress."))


func _all_enemies_dead() -> bool:
	for value in units:
		var unit := _valid_unit(value)
		if unit and unit.team == "enemy" and unit.hp > 0:
			return false
	return true


func _anchor_destroyed() -> bool:
	if not map_data or map_data.objective_type != "destroy_anchor":
		return false
	var found_anchor := false
	for value in units:
		var unit := _valid_unit(value)
		if unit and unit.team == "enemy" and unit.unit_data and unit.unit_data.id == "void_anchor":
			found_anchor = true
			if unit.hp > 0:
				return false
	return true if found_anchor else _all_enemies_dead()


func _living_enemy_count() -> int:
	var count := 0
	for value in units:
		var unit := _valid_unit(value)
		if unit and unit.team == "enemy" and unit.hp > 0:
			count += 1
	return count


func _first_living_enemy_hp(unit_id: String) -> int:
	for value in units:
		var unit := _valid_unit(value)
		if unit and unit.team == "enemy" and unit.hp > 0 and unit.unit_data and unit.unit_data.id == unit_id:
			return unit.hp
	return 0


func _valid_unit(value: Variant) -> Unit:
	if value == null or not is_instance_valid(value) or not (value is Unit):
		return null
	return value as Unit


func _map_value(property_name: String, fallback: Variant) -> Variant:
	if not map_data:
		return fallback
	var value: Variant = map_data.get(property_name)
	return fallback if value == null else value
