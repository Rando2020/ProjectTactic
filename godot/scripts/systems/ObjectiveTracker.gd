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


func on_unit_defeated(unit_id: String) -> void:
	# Check if a void anchor guardian died (for destroy_anchor missions)
	var u := units.filter(func(x: Unit) -> bool: return x.unit_data.id == unit_id)
	if not u.is_empty() and map_data.objective_type == "destroy_anchor":
		objective_updated.emit(get_progress_text())


func on_turn_advanced() -> void:
	turns_elapsed += 1
	objective_updated.emit(get_progress_text())


func get_progress_text() -> String:
	match map_data.objective_type:
		"defeat_all":
			var remaining := units.filter(func(u: Unit) -> bool: return u.team == "enemy" and u.hp > 0).size()
			return "Defeat all enemies — %d remaining." % remaining if remaining > 0 else "✓ All enemies defeated."
		"destroy_anchor":
			if _anchor_destroyed(): return "✓ The Anchor shatters!"
			var anchors := units.filter(func(u: Unit) -> bool:
				return u.team == "enemy" and u.unit_data != null and u.unit_data.id == "void_anchor" and u.hp > 0)
			var golem := units.filter(func(u: Unit) -> bool:
				return u.team == "enemy" and u.unit_data != null and u.unit_data.id == "void_golem" and u.hp > 0)
			if golem.size() > 0:
				return "Defeat the Void Golem, then destroy the Anchor with holy abilities."
			if anchors.size() > 0:
				return "Anchor HP: %d — Hit it with holy abilities!" % anchors[0].hp
			return "Destroy the Void Anchor."
		"reach_tile":
			return "Reach tile (%d, %d)." % [int(_map_value("objective_tile_x", 0)), int(_map_value("objective_tile_y", 0))]
		"protect_unit":
			return "Defeat all enemies. Protect your unit."
		"survive_turns":
			var left := maxi(0, int(_map_value("survive_turns", 5)) - turns_elapsed)
			return "✓ Survived." if left == 0 else "Survive %d more turn%s." % [left, "s" if left != 1 else ""]
		_:
			return str(_map_value("objective_label", "Objective in progress."))


func _all_enemies_dead() -> bool:
	return units.all(func(u: Unit) -> bool: return u.team != "enemy" or u.hp <= 0)


func _anchor_destroyed() -> bool:
	if map_data.objective_type != "destroy_anchor": return false
	# Victory when the void_anchor unit is at 0 HP
	var anchor_units := units.filter(func(u: Unit) -> bool:
		return u.team == "enemy" and (
			(u.unit_data != null and u.unit_data.id == "void_anchor") or
			(u.unit_data != null and u.unit_data.get("is_anchor") == true)
		))
	if anchor_units.is_empty():
		# No anchor unit found — fall back to all enemies dead
		return _all_enemies_dead()
	# All anchor units must be destroyed
	return anchor_units.all(func(u: Unit) -> bool: return u.hp <= 0)


func _map_value(property_name: String, fallback: Variant) -> Variant:
	if not map_data:
		return fallback
	var value: Variant = map_data.get(property_name)
	return fallback if value == null else value
