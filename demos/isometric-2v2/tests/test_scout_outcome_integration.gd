extends Node

var checks := 0
var failures := 0
var manager: BattleManager
var scout: Unit
var enemy: Unit
var secondary: Unit
var logs: Array[String] = []
var results: Array[Dictionary] = []
var interruption := ""

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func prepare(moved: bool = true) -> void:
	manager.current_phase = BattleManager.Phase.PLAYER_TURN
	manager.active_unit_id = scout.unit_id
	manager.active_unit_has_moved = moved
	manager.active_unit_has_acted = false
	scout.begin_turn()
	scout.has_moved = moved
	scout.grid_pos = Vector2i(1, 4)
	scout.mp = 30
	scout.hp = scout.unit_data.base_stats.hp
	scout.statuses.clear()
	enemy.grid_pos = Vector2i(4, 4)
	enemy.facing = "E"
	enemy.hp = 2000
	enemy.temper = 0
	enemy.ether = 0
	enemy.statuses.clear()
	logs.clear()
	results.clear()

func interrupt_contact(_move: bool, _act: bool, _pending: bool) -> void:
	if not manager.is_resolving_action or interruption.is_empty():
		return
	var kind := interruption
	interruption = ""
	match kind:
		"mp": scout.mp = 4
		"acted": manager.active_unit_has_acted = true
		"turn":
			manager.current_phase = BattleManager.Phase.ENEMY_TURN
			manager.active_unit_id = enemy.unit_id
		"range": enemy.grid_pos = Vector2i(3, 4)

func check_quickstep() -> void:
	var ability := AbilityDB.get_ability("quickstep")
	for bool_wrapper in [false, true]:
		for scenario in ["early", "success", "mp", "acted", "turn", "hop"]:
			prepare(scenario != "early")
			interruption = scenario if scenario in ["mp", "acted", "turn"] else ""
			var label := "Quickstep %s via %s" % [scenario, "bool" if bool_wrapper else "result"]
			var accepted: bool
			if bool_wrapper:
				accepted = await manager._execute_ability(scout, scout, ability, scenario == "hop")
			else:
				var execution: Dictionary = await manager._execute_ability_with_result(scout, scout, ability, scenario == "hop")
				accepted = execution.get("executed", false)
				check(execution == {"executed": scenario == "success", "outcome": {}}, label + " returns the exact non-damage admission envelope")
			check(accepted == (scenario == "success"), label + " preserves admission truth through wrapper")
			var expected_mp := 25 if scenario == "success" else (4 if scenario == "mp" else 30)
			check(scout.mp == expected_mp and results.is_empty() and not scout.has_status("quickstep"), label + " has no duplicate cost, resolver result or buff")
			check(manager.active_unit_has_acted == (scenario in ["success", "acted"]), label + " preserves consumed or rejected action state")
			check(manager.active_unit_has_moved == (scenario not in ["early", "success"]), label + " grants movement only on accepted Quickstep")
			check(logs.size() == (1 if scenario == "success" else 0), label + " emits no rejected or duplicate outcome log")
			await manager._recover_action()
			check(manager.action_lifecycle.phase == "idle" and not manager.is_resolving_action, label + " releases lifecycle")

func check_long_shot() -> void:
	var ability := AbilityDB.get_ability("long_shot")
	for bool_wrapper in [false, true]:
		for scenario in ["dead_zone", "contact", "legal"]:
			prepare(false)
			if scenario == "dead_zone": enemy.grid_pos = Vector2i(3, 4)
			interruption = "range" if scenario == "contact" else ""
			var label := "Long Shot %s via %s" % [scenario, "bool" if bool_wrapper else "result"]
			var accepted: bool
			if bool_wrapper:
				accepted = await manager._execute_ability(scout, enemy, ability)
			else:
				var execution: Dictionary = await manager._execute_ability_with_result(scout, enemy, ability)
				accepted = execution.get("executed", false)
				if scenario == "legal":
					check(results.size() == 1 and execution.outcome == results[0], label + " forwards the authoritative physical result unchanged")
				else:
					check(execution == {"executed": false, "outcome": {}}, label + " rejects with an empty outcome envelope")
			check(accepted == (scenario == "legal"), label + " preserves admission truth through wrapper")
			check(scout.mp == 30, label + " preserves zero MP cost")
			if scenario == "legal":
				check(results.size() == 1 and results[0].get("applied_hp_damage", -1) == 2000 - enemy.hp and enemy.hp < 2000, label + " retains applied damage and one resolver event")
				check(logs.size() == 1, label + " keeps one physical action log")
			else:
				check(enemy.hp == 2000 and results.is_empty() and logs.is_empty(), label + " rejects without damage, result or damage claim")
			await manager._recover_action()

func check_secondary_semantics() -> void:
	for ability_id in ["fire", "thunderstrike"]:
		prepare(false)
		for unit: Unit in manager.units.values():
			if unit != scout: unit.grid_pos = Vector2i(0, 0)
		enemy.grid_pos = Vector2i(4, 4) if ability_id == "fire" else Vector2i(5, 4)
		secondary.grid_pos = Vector2i(4, 5) if ability_id == "fire" else Vector2i(6, 4)
		for target in [enemy, secondary]:
			target.hp = 2000
			target.ether = 0
			target.unit_data.base_stats.magic_resistance = 0
			target.unit_data.elemental_affinities.fire = 1.0
			target.unit_data.elemental_affinities.thunder = 1.0
		var ability := AbilityDB.get_ability(ability_id)
		check(manager._ability_target_in_range(scout, enemy, ability) and not manager._ability_target_in_range(scout, secondary, ability), ability_id + " fixture has a legal primary and secondary outside caster range")
		check(await manager._execute_aoe_ability(scout, enemy.grid_pos, ability), ability_id + " preserves actual fan/chain execution")
		check(scout.mp == (18 if ability_id == "fire" else 16), ability_id + " charges its declared MP exactly once")
		check(results.size() == 2 and enemy.hp < 2000 and secondary.hp < 2000, ability_id + " retains out-of-primary-range secondary damage")
		check(results[0].has("applied_hp_damage") and results[1].has("applied_hp_damage"), ability_id + " retains per-target applied outcomes")
		check(logs.size() == 3 and (ability_id != "fire" or (enemy.has_status("burn") and secondary.has_status("burn"))), ability_id + " retains wrapper and existing status/outcome logs")
		await manager._recover_action()
	prepare(false)
	scout.hp -= 20
	var heal: Dictionary = await manager._execute_ability_with_result(scout, scout, AbilityDB.get_ability("cure"))
	check(heal.executed and heal.outcome.get("healed", -1) == 20, "self-heal still returns actual healing despite ordinary nonzero cast range")
	check(scout.mp == 22 and scout.hp == scout.unit_data.base_stats.hp and logs.size() == 1, "self-heal preserves one cost and one log")
	await manager._recover_action()

func run() -> void:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	manager = battle.battle_manager
	scout = manager.units.lyra
	for unit: Unit in manager.units.values():
		unit.unit_data = unit.unit_data.duplicate(true)
		if unit.team == "enemy":
			if enemy == null: enemy = unit
			elif secondary == null: secondary = unit
	enemy.unit_data.base_stats.hp = 2000
	enemy.unit_data.base_stats.physical_resistance = 0
	for tile in manager.tactical_grid.tiles.values():
		tile.height = 0
	manager.action_state_changed.connect(interrupt_contact)
	manager.log_message.connect(func(message: String): logs.append(message))
	manager.combat_resolver.combat_resolved.connect(func(result: Dictionary): results.append(result))
	await check_quickstep()
	await check_long_shot()
	await check_secondary_semantics()
	battle.queue_free()
	await get_tree().process_frame
	print("Scout outcome integration: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
