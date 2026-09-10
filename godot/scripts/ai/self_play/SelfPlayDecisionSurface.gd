class_name SelfPlayDecisionSurface
extends RefCounted

## Adapter between BattleManager's real tactical state and interchangeable self-play policies.
## It does not own combat rules. Legal moves, attacks, and opt-in abilities come from the
## same GridSystem, AbilityDB, ForecastCalculator, TacticalGrid, and BattleManager paths
## used by gameplay.


func legal_actions(manager: BattleManager, include_abilities: bool = false) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if manager == null or manager.current_phase != BattleManager.Phase.PLAYER_TURN:
		return actions
	var unit: Unit = manager._living_unit(manager.active_unit_id)
	if unit == null:
		return actions

	if not manager.active_unit_has_acted:
		actions.append_array(_attack_actions(manager, unit))
		if include_abilities:
			actions.append_array(_ability_actions(manager, unit))
	if not manager.active_unit_has_moved:
		actions.append_array(_move_actions(manager, unit))

	actions.append({
		"kind": "wait",
		"actor_id": unit.unit_id,
		"action_id": "wait",
		"target_id": "",
		"target_position": _position_dict(unit.grid_pos),
		"expected_damage": 0,
		"expected_heal": 0,
		"lethal": false,
		"lethal_target_count": 0,
		"target_count": 0,
		"status_target_count": 0,
		"mp_cost": 0,
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
		"ability":
			var ability_id := str(action.get("ability_id", ""))
			if ability_id.is_empty():
				return
			var ability := AbilityDB.get_ability(ability_id)
			manager.select_command("ability")
			manager.select_ability(ability_id)
			# Self-cast/range-0 abilities resolve inside select_ability().
			if manager.current_phase != BattleManager.Phase.PLAYER_TURN \
					or manager.active_command != "ability_target":
				return
			var target_pos := _dict_position(action.get("target_position", {}))
			if ability.has("aoe_type"):
				await manager._on_tile_clicked(target_pos)
			else:
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
			"expected_heal": 0,
			"lethal": damage >= target.hp,
			"lethal_target_count": 1 if damage >= target.hp else 0,
			"target_count": 1,
			"status_target_count": 0,
			"mp_cost": 0,
			"target_hp": target.hp,
			"nearest_enemy_distance": distance,
			"best_attack_damage_after_move": damage,
			"attack_available_after_move": true,
		})
	return actions


func _ability_actions(manager: BattleManager, unit: Unit) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if unit.unit_data == null or unit.has_status("silence"):
		return actions
	var ability_ids: Array[String] = []
	for raw_id in unit.unit_data.abilities:
		ability_ids.append(str(raw_id))
	ability_ids.sort()

	for ability_id in ability_ids:
		var ability: Dictionary = AbilityDB.get_ability(ability_id)
		if ability.is_empty():
			continue
		var mp_cost := int(ability.get("mp_cost", 0))
		if unit.mp < mp_cost:
			continue
		var range_max := int(ability.get("range", 1))
		var range_min := int(ability.get("min_range", 1))
		var target_type := str(ability.get("target_type", "enemy"))

		if target_type == "self" or range_max == 0:
			var self_action := _ability_action_for_center(manager, unit, ability_id, ability, unit.grid_pos, unit)
			if not self_action.is_empty():
				actions.append(self_action)
			continue

		if ability.has("aoe_type"):
			var centers := GridSystem.get_attack_range(
				unit.grid_pos,
				range_min,
				range_max,
				manager.map_data.map_width,
				manager.map_data.map_height
			)
			for raw_center in centers:
				var center: Vector2i = raw_center
				if manager.tactical_grid.get_tile(center).is_empty():
					continue
				var primary := manager._unit_at_pos(center)
				var action := _ability_action_for_center(manager, unit, ability_id, ability, center, primary)
				if not action.is_empty():
					actions.append(action)
			continue

		for uid in manager.units.keys():
			var target: Unit = manager._living_unit(str(uid))
			if target == null or target.hp <= 0 or not _valid_ability_target(unit, target, target_type):
				continue
			var distance := GridSystem.manhattan(unit.grid_pos, target.grid_pos)
			if distance < range_min or distance > range_max:
				continue
			var action := _ability_action_for_center(manager, unit, ability_id, ability, target.grid_pos, target)
			if not action.is_empty():
				actions.append(action)
	return actions


func _ability_action_for_center(
	manager: BattleManager,
	caster: Unit,
	ability_id: String,
	ability: Dictionary,
	center: Vector2i,
	explicit_target: Unit
) -> Dictionary:
	var targets: Array[Unit] = []
	if ability.has("aoe_type"):
		targets = manager._get_aoe_targets(center, ability, caster)
	elif explicit_target != null:
		targets.append(explicit_target)

	# Buff/heal self-casts with target_type omitted are represented by the caster.
	if targets.is_empty() and center == caster.grid_pos:
		var target_type := str(ability.get("target_type", "enemy"))
		if target_type in ["self", "ally"]:
			targets.append(caster)
	if targets.is_empty():
		return {}

	var expected_damage := 0
	var expected_heal := 0
	var lethal_count := 0
	var status_count := 0
	var useful_targets := 0
	var primary_target_id := ""
	for target in targets:
		if target == null or target.hp <= 0:
			continue
		var forecast := ForecastCalculator.spell(
			caster,
			target,
			ability,
			manager.tactical_grid.get_tile(caster.grid_pos),
			manager.tactical_grid.get_tile(target.grid_pos)
		)
		var damage := int(forecast.get("damage", 0))
		var heal := int(forecast.get("heal", 0))
		var actual_heal := mini(heal, maxi(int(forecast.get("max_hp", target.hp)) - target.hp, 0))
		var status_text := str(forecast.get("status_preview", ""))
		var target_useful := damage > 0 or actual_heal > 0 or not status_text.is_empty() or bool(forecast.get("is_buff", false))
		if not target_useful:
			continue
		useful_targets += 1
		expected_damage += damage
		expected_heal += actual_heal
		if damage >= target.hp and damage > 0:
			lethal_count += 1
		if not status_text.is_empty() or bool(forecast.get("is_buff", false)):
			status_count += 1
		if primary_target_id.is_empty():
			primary_target_id = target.unit_id
	if useful_targets == 0:
		return {}

	return {
		"kind": "ability",
		"actor_id": caster.unit_id,
		"action_id": "ability:%s" % ability_id,
		"ability_id": ability_id,
		"ability_name": str(ability.get("display_name", ability_id)),
		"spell_type": str(ability.get("spell_type", ability.get("type", "unknown"))),
		"target_id": primary_target_id,
		"target_position": _position_dict(center),
		"expected_damage": expected_damage,
		"expected_heal": expected_heal,
		"lethal": lethal_count > 0,
		"lethal_target_count": lethal_count,
		"target_count": useful_targets,
		"status_target_count": status_count,
		"mp_cost": int(ability.get("mp_cost", 0)),
		"nearest_enemy_distance": _nearest_enemy_distance(manager, caster.grid_pos, caster.team),
		"best_attack_damage_after_move": 0,
		"attack_available_after_move": false,
	}


func _valid_ability_target(caster: Unit, target: Unit, target_type: String) -> bool:
	match target_type:
		"enemy":
			return target.team != caster.team
		"ally":
			return target.team == caster.team
		"self":
			return target == caster
		_:
			return target.team != caster.team


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
			"expected_heal": 0,
			"lethal": false,
			"lethal_target_count": 0,
			"target_count": 0,
			"status_target_count": 0,
			"mp_cost": 0,
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
