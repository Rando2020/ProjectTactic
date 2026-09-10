class_name SelfPlayDecisionSurface
extends RefCounted

## Adapter between BattleManager's real tactical state and interchangeable self-play policies.
## It does not own combat rules. Legal moves and attacks come from the same GridSystem,
## unit stats, TacticalGrid, and CombatFormula-backed prediction path used by gameplay.


func legal_actions(manager: BattleManager) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if manager == null or manager.current_phase != BattleManager.Phase.PLAYER_TURN:
		return actions
	var unit: Unit = manager._living_unit(manager.active_unit_id)
	if unit == null:
		return actions

	if not manager.active_unit_has_acted:
		actions.append_array(_attack_actions(manager, unit))
	if not manager.active_unit_has_moved:
		actions.append_array(_move_actions(manager, unit))

	actions.append({
		"kind": "wait",
		"actor_id": unit.unit_id,
		"action_id": "wait",
		"target_id": "",
		"target_position": _position_dict(unit.grid_pos),
		"expected_damage": 0,
		"lethal": false,
		"nearest_enemy_distance": _nearest_enemy_distance(manager, unit.grid_pos, unit.team),
		"best_attack_damage_after_move": 0,
		"attack_available_after_move": false,
	})

	actions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_key(a) < _sort_key(b)
	)
	return actions


func execute_action(manager: BattleManager, action: Dictionary) -> void:
	if manager == null or manager.current_phase != BattleManager.Phase.PLAYER_TURN:
		return
	match str(action.get("kind", "")):
		"attack":
			manager.select_command("attack")
			var target_id := str(action.get("target_id", ""))
			if not target_id.is_empty():
				manager._on_unit_clicked(target_id)
		"move":
			manager.select_command("move")
			var target_pos := _dict_position(action.get("target_position", {}))
			await manager._on_tile_clicked(target_pos)
		"wait":
			manager.select_command("wait")


func action_key(action: Dictionary) -> String:
	return _sort_key(action)


func _attack_actions(manager: BattleManager, unit: Unit) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var atk_min: int = unit.unit_data.base_stats.attack_range_min
	var atk_max: int = unit.unit_data.base_stats.attack_range_max
	for uid in manager.units.keys():
		var target: Unit = manager._living_unit(str(uid))
		if target == null or target.team == unit.team or target.hp <= 0:
			continue
		var distance := GridSystem.manhattan(unit.grid_pos, target.grid_pos)
		if distance < atk_min or distance > atk_max:
			continue
		var damage := manager._predict_attack_damage(
			unit,
			target,
			manager.tactical_grid.get_tile(unit.grid_pos),
			manager.tactical_grid.get_tile(target.grid_pos)
		)
		actions.append({
			"kind": "attack",
			"actor_id": unit.unit_id,
			"action_id": "basic-attack",
			"target_id": target.unit_id,
			"target_position": _position_dict(target.grid_pos),
			"expected_damage": damage,
			"lethal": damage >= target.hp,
			"target_hp": target.hp,
			"nearest_enemy_distance": distance,
			"best_attack_damage_after_move": damage,
			"attack_available_after_move": true,
		})
	return actions


func _move_actions(manager: BattleManager, unit: Unit) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var occupied: Array = []
	for uid in manager.units.keys():
		var other: Unit = manager._living_unit(str(uid))
		if other and other.unit_id != unit.unit_id and other.hp > 0:
			occupied.append(other.grid_pos)

	var reachable := GridSystem.get_move_range(
		unit.grid_pos,
		unit.unit_data.base_stats.move,
		manager.tactical_grid.tiles,
		occupied,
		manager.map_data.map_width,
		manager.map_data.map_height,
		unit.unit_data.base_stats.jump
	)
	for raw_pos in reachable:
		var pos: Vector2i = raw_pos
		if pos == unit.grid_pos:
			continue
		var future := _future_attack_features(manager, unit, pos)
		actions.append({
			"kind": "move",
			"actor_id": unit.unit_id,
			"action_id": "move",
			"target_id": "",
			"target_position": _position_dict(pos),
			"expected_damage": 0,
			"lethal": false,
			"nearest_enemy_distance": future["nearest_enemy_distance"],
			"best_attack_damage_after_move": future["best_attack_damage_after_move"],
			"attack_available_after_move": future["attack_available_after_move"],
			"height": int(manager.tactical_grid.get_tile(pos).get("height", 0)),
		})
	return actions


func _future_attack_features(manager: BattleManager, unit: Unit, pos: Vector2i) -> Dictionary:
	var nearest_distance := 999999
	var best_damage := 0
	var attack_available := false
	var atk_min: int = unit.unit_data.base_stats.attack_range_min
	var atk_max: int = unit.unit_data.base_stats.attack_range_max
	for uid in manager.units.keys():
		var target: Unit = manager._living_unit(str(uid))
		if target == null or target.team == unit.team or target.hp <= 0:
			continue
		var distance := GridSystem.manhattan(pos, target.grid_pos)
		nearest_distance = mini(nearest_distance, distance)
		if distance < atk_min or distance > atk_max:
			continue
		attack_available = true
		var damage := manager._predict_attack_damage(
			unit,
			target,
			manager.tactical_grid.get_tile(pos),
			manager.tactical_grid.get_tile(target.grid_pos)
		)
		best_damage = maxi(best_damage, damage)
	return {
		"nearest_enemy_distance": nearest_distance,
		"best_attack_damage_after_move": best_damage,
		"attack_available_after_move": attack_available,
	}


func _nearest_enemy_distance(manager: BattleManager, pos: Vector2i, team: String) -> int:
	var best := 999999
	for uid in manager.units.keys():
		var target: Unit = manager._living_unit(str(uid))
		if target and target.team != team and target.hp > 0:
			best = mini(best, GridSystem.manhattan(pos, target.grid_pos))
	return best


func _sort_key(action: Dictionary) -> String:
	var pos: Dictionary = action.get("target_position", {})
	return "%s|%s|%s|%05d|%05d" % [
		str(action.get("kind", "")),
		str(action.get("target_id", "")),
		str(action.get("action_id", "")),
		int(pos.get("x", -1)) + 10000,
		int(pos.get("y", -1)) + 10000,
	]


func _position_dict(pos: Vector2i) -> Dictionary:
	return {"x": pos.x, "y": pos.y}


func _dict_position(raw: Variant) -> Vector2i:
	if raw is Vector2i:
		return raw
	if raw is Dictionary:
		return Vector2i(int(raw.get("x", -1)), int(raw.get("y", -1)))
	return Vector2i(-1, -1)
