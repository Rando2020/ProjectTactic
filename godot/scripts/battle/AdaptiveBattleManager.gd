class_name AdaptiveBattleManager
extends BattleManager

## Opt-in BattleManager extension that observes completed player behavior and lets
## the bounded AdaptiveIntentBias nudge close enemy offensive choices.
##
## Default is OFF so swapping this script onto Battle.tscn preserves current
## production behavior until a development/test path explicitly enables it.

@export var adaptive_enemy_enabled: bool = false
var adaptive_profile_seed: Dictionary = {}
var _adaptive_model := AdaptiveOpponentModel.new()


func start_battle(p_map_data: MapData, p_units: Array[Unit]) -> void:
	_adaptive_model.reset()
	if not adaptive_profile_seed.is_empty():
		_adaptive_model.load_dict(adaptive_profile_seed)
	super.start_battle(p_map_data, p_units)


func adaptive_profile() -> Dictionary:
	return _adaptive_model.to_dict()


func load_adaptive_profile(profile: Dictionary) -> void:
	_adaptive_model.load_dict(profile)


func adaptive_signals() -> Dictionary:
	return _adaptive_model.signals()


func select_command(command: String) -> void:
	if adaptive_enemy_enabled and command == "wait" and current_phase == Phase.PLAYER_TURN:
		var waiter := _living_unit(active_unit_id)
		if waiter and waiter.team == "player":
			_adaptive_model.observe_action(waiter.unit_id, "wait")
	super.select_command(command)


func _on_tile_clicked(grid_pos: Vector2i) -> void:
	var should_observe_move := false
	var actor: Unit = null
	var old_pos := Vector2i.ZERO
	var before_distance := 0
	if adaptive_enemy_enabled and current_phase == Phase.PLAYER_TURN and active_command == "move":
		actor = _living_unit(active_unit_id)
		if actor and actor.team == "player" and grid_pos in tactical_grid.move_tiles:
			old_pos = actor.grid_pos
			before_distance = _nearest_enemy_distance_from(old_pos, actor.team)
			should_observe_move = true
	await super._on_tile_clicked(grid_pos)
	if should_observe_move and actor and is_instance_valid(actor) and actor.grid_pos != old_pos:
		var after_distance := _nearest_enemy_distance_from(actor.grid_pos, actor.team)
		_adaptive_model.observe_move(
			actor.unit_id,
			before_distance,
			after_distance,
			GridSystem.manhattan(old_pos, actor.grid_pos)
		)


func _on_unit_clicked(unit_id: String) -> void:
	var command_before := active_command
	var ability_id_before := selected_ability_id
	var actor := _living_unit(active_unit_id)
	var target := _living_unit(unit_id)
	var actor_hp_ratio := _hp_ratio(actor)
	var target_hp_before := target.hp if target else 0
	var distance_before := GridSystem.manhattan(actor.grid_pos, target.grid_pos) if actor and target else 1
	var ability_before: Dictionary = {}
	if command_before == "ability_target" and not ability_id_before.is_empty():
		ability_before = AbilityDB.get_ability(ability_id_before)

	super._on_unit_clicked(unit_id)

	if not adaptive_enemy_enabled or not actor or not is_instance_valid(actor) or actor.team != "player":
		return
	if command_before == "attack":
		var damage := 0
		if target and is_instance_valid(target):
			damage = maxi(target_hp_before - target.hp, 0)
		_adaptive_model.observe_action(actor.unit_id, "basic_attack", {
			"range": distance_before,
			"actor_hp_ratio": actor_hp_ratio,
			"damage": damage,
			"target_id": unit_id,
		})
	elif command_before == "ability_target" and not ability_before.is_empty() and not _ability_has_area_effect(ability_before):
		var target_hp_after := target.hp if target and is_instance_valid(target) else target_hp_before
		var damage := maxi(target_hp_before - target_hp_after, 0)
		var healing := maxi(target_hp_after - target_hp_before, 0)
		_adaptive_model.observe_action(actor.unit_id, "ability", {
			"range": int(ability_before.get("range", distance_before)),
			"actor_hp_ratio": actor_hp_ratio,
			"damage": damage,
			"healing": healing,
			"element": str(ability_before.get("spell_type", "")),
			"target_id": unit_id,
		})


func _execute_aoe_ability(caster: Unit, center: Vector2i, ability: Dictionary) -> void:
	var observe := adaptive_enemy_enabled and caster and caster.team == "player"
	var actor_hp_ratio := _hp_ratio(caster)
	var targets_before: Dictionary = {}
	if observe:
		for target in _get_aoe_targets(center, ability, caster):
			if target and is_instance_valid(target):
				targets_before[target.unit_id] = target.hp

	super._execute_aoe_ability(caster, center, ability)

	if not observe or not caster or not is_instance_valid(caster):
		return
	var damage := 0
	var healing := 0
	for target_id in targets_before.keys():
		var target := _living_unit(str(target_id))
		var before_hp := int(targets_before[target_id])
		var after_hp := target.hp if target and is_instance_valid(target) else 0
		damage += maxi(before_hp - after_hp, 0)
		healing += maxi(after_hp - before_hp, 0)
	_adaptive_model.observe_action(caster.unit_id, "ability", {
		"range": int(ability.get("range", 1)),
		"actor_hp_ratio": actor_hp_ratio,
		"damage": damage,
		"healing": healing,
		"element": str(ability.get("spell_type", "")),
		"area_target_count": targets_before.size(),
	})


func _end_player_turn() -> void:
	if adaptive_enemy_enabled and current_phase == Phase.PLAYER_TURN:
		var positions: Array[Vector2i] = []
		for uid in units.keys():
			var unit := _living_unit(str(uid))
			if unit and unit.team == "player" and unit.hp > 0:
				positions.append(unit.grid_pos)
		_adaptive_model.observe_turn_end(positions)
	super._end_player_turn()


func _evaluate_enemy_intent(unit: Unit) -> Dictionary:
	var base_intent := super._evaluate_enemy_intent(unit)
	if not adaptive_enemy_enabled or _adaptive_model.confidence() < AdaptiveIntentBias.MIN_CONFIDENCE:
		return base_intent

	var base_kind := str(base_intent.get("kind", "hold"))
	var base_details: Dictionary = base_intent.get("details", {})
	if base_kind in ["heal", "retreat", "hold"] or bool(base_details.get("can_ko", false)):
		return base_intent

	var candidates: Array[Dictionary] = []
	_add_intent_candidate(candidates, base_intent, "base")
	for uid in units.keys():
		var target := _living_unit(str(uid))
		if not target or target.team != "player" or target.hp <= 0:
			continue
		_add_attack_candidate(candidates, unit, target)
		_add_spell_candidates(candidates, unit, target)
		_add_advance_candidate(candidates, unit, target)

	var ranked := AdaptiveIntentBias.rank_candidates(candidates, _adaptive_model)
	if ranked.is_empty():
		return base_intent
	var winner: Dictionary = ranked[0]
	var intent: Dictionary = winner.get("intent", base_intent).duplicate(true)
	var adaptation: Dictionary = winner.get("adaptation", {})
	if not adaptation.is_empty():
		intent["adaptation"] = adaptation
		var note := str(intent.get("note", ""))
		var summary := str(adaptation.get("summary", "Adapted"))
		intent["note"] = "%s %s." % [note, summary] if not note.is_empty() else "%s." % summary
		intent["summary"] = "%s [%s]" % [str(intent.get("summary", "Enemy adapts")), summary]
	return intent


func _add_intent_candidate(candidates: Array[Dictionary], intent: Dictionary, suffix: String) -> void:
	var target_id := str(intent.get("target_id", ""))
	var area_count := 1
	var ability: Dictionary = intent.get("ability", {})
	if not ability.is_empty() and _ability_has_area_effect(ability):
		var target := _living_unit(target_id)
		var actor := _living_unit(str(intent.get("actor_id", "")))
		if target and actor:
			area_count = maxi(_get_aoe_targets(target.grid_pos, ability, actor).size(), 1)
	candidates.append({
		"candidate_id": "%s:%s:%s" % [str(intent.get("kind", "hold")), target_id, suffix],
		"base_score": _base_intent_score(intent),
		"target_id": target_id,
		"area_target_count": area_count,
		"intent": intent.duplicate(true),
	})


func _add_attack_candidate(candidates: Array[Dictionary], unit: Unit, target: Unit) -> void:
	if GridSystem.manhattan(unit.grid_pos, target.grid_pos) > unit.unit_data.base_stats.attack_range_max:
		return
	var intent := _enemy_intent(unit, "attack", target, "Attack", "Basic attack on %s." % target.display_name)
	_add_intent_candidate(candidates, intent, "attack")


func _add_spell_candidates(candidates: Array[Dictionary], unit: Unit, target: Unit) -> void:
	for ability_id in unit.unit_data.abilities:
		var ability: Dictionary = AbilityDB.get_ability(str(ability_id))
		if ability.is_empty() or str(ability.get("target_type", "enemy")) != "enemy":
			continue
		if str(ability.get("spell_type", "")) == "cure" or unit.mp < int(ability.get("mp_cost", 0)):
			continue
		if not _ability_target_in_range(unit, target, ability):
			continue
		var intent := _enemy_intent(
			unit,
			"spell",
			target,
			str(ability.get("display_name", ability_id)),
			"Adaptive candidate on %s." % target.display_name,
			ability
		)
		_add_intent_candidate(candidates, intent, "spell:%s" % str(ability_id))


func _add_advance_candidate(candidates: Array[Dictionary], unit: Unit, target: Unit) -> void:
	var move_to := _best_advance_tile(unit, target)
	if move_to == unit.grid_pos:
		return
	var can_attack := GridSystem.manhattan(move_to, target.grid_pos) <= unit.unit_data.base_stats.attack_range_max
	var action := "Advance + Attack" if can_attack else "Advance"
	var note := "Will move then attack %s." % target.display_name if can_attack else "Moving toward %s." % target.display_name
	var intent := _enemy_intent(unit, "advance", target, action, note, {}, move_to)
	_add_intent_candidate(candidates, intent, "advance")


func _base_intent_score(intent: Dictionary) -> float:
	var kind := str(intent.get("kind", "hold"))
	var details: Dictionary = intent.get("details", {})
	var damage := float(details.get("damage", 0))
	var score := damage
	if bool(details.get("can_ko", false)):
		score += 1000.0
	match kind:
		"spell":
			score += 8.0
		"attack":
			score += 5.0
		"advance":
			score += 2.0 if damage > 0.0 else -float(details.get("range", 0)) * 2.0
		"hold":
			score -= 20.0
	return score


func _nearest_enemy_distance_from(position: Vector2i, team: String) -> int:
	var best := 9999
	for uid in units.keys():
		var candidate := _living_unit(str(uid))
		if not candidate or candidate.team == team or candidate.hp <= 0:
			continue
		best = mini(best, GridSystem.manhattan(position, candidate.grid_pos))
	return best if best < 9999 else 0


func _hp_ratio(unit: Unit) -> float:
	if not unit or not unit.unit_data:
		return 1.0
	return clampf(float(unit.hp) / float(maxi(unit.unit_data.base_stats.hp, 1)), 0.0, 1.0)
