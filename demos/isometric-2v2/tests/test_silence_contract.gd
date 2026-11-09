extends Node
var checks := 0
var failures := 0
var interrupt_actor: Unit
var interrupt_armed := false
var offered_abilities: Array = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func silence(unit: Unit) -> void:
	var status := StatusEffect.new()
	status.status_id = "silence"
	status.duration = 2
	unit.apply_status(status)

func _interrupt_on_admission(_move: bool, _act: bool, _pending: bool) -> void:
	if interrupt_armed:
		interrupt_armed = false
		silence(interrupt_actor)

func run() -> void:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	var player: Unit = manager.units.kael
	var enemy: Unit
	for unit: Unit in manager.units.values():
		if unit.team == "enemy" and enemy == null:
			enemy = unit
		elif unit.team == "player" and unit != player:
			unit.grid_pos = Vector2i(8, 8)
	for unit in [player, enemy]:
		unit.unit_data = unit.unit_data.duplicate(true)
		unit.unit_data.base_stats.hp = 2000
		unit.unit_data.base_stats.magic = 60
		unit.hp = 2000
		unit.mp = 100
		unit.temper = 0
		unit.ether = 0
		unit.statuses.clear()
	player.grid_pos = Vector2i(3, 3)
	enemy.grid_pos = Vector2i(3, 2)
	var magic := AbilityDB.get_ability("void_pulse")
	var physical := AbilityDB.get_ability("mighty_strike")
	var heal := AbilityDB.get_ability("cure")
	var chain := AbilityDB.get_ability("thunder")
	var buff := AbilityDB.get_ability("protect")
	enemy.unit_data.abilities.assign(["void_pulse"])
	var planned := manager._evaluate_enemy_intent(enemy)
	check(planned.kind == "spell", "unsilenced fixture plans actual Void Pulse")
	check(manager._enemy_intent_is_valid(enemy, planned), "unsilenced magical intent is valid")
	silence(enemy)
	check(not manager._enemy_intent_is_valid(enemy, planned), "Silence invalidates previously planned magical cast")
	player.hp = 1
	check(manager._find_kill_spell(enemy).is_empty(), "silenced enemy has no lethal magical candidate")
	player.hp = 2000
	check(manager._find_best_spell_intent(enemy).is_empty(), "silenced enemy has no best magical candidate")
	var silenced_plan := manager._evaluate_enemy_intent(enemy)
	check(silenced_plan.kind != "spell", "silenced enemy plans physical or movement fallback, not magic")
	seed(12345)
	await manager._execute_enemy_intent(enemy, planned)
	check(enemy.mp == 100, "stale magical intent never spends magical MP")
	check(manager._last_enemy_intents[enemy.unit_id].get("replanned", false), "stale intent is visibly replanned")
	check(not player.has_status("silence"), "rejected Void Pulse applies no spell status")
	await manager._recover_action()
	# Direct rejection must not reserve or consume an action, including heal and AoE.
	for ability in [magic, heal, chain, buff, {}, {"display_name": "Missing classification", "type": "attack", "mp_cost": 9}, {"display_name": "Unknown", "spell_type": "unclassified", "mp_cost": 9}]:
		enemy.mp = 100
		enemy.hp = 1500
		player.hp = 2000
		manager.active_unit_has_acted = false
		var recipient: Unit = enemy if ability.get("target_type", "enemy") in ["ally", "self"] else player
		var accepted: bool
		if ability.has("aoe_type"):
			accepted = await manager._execute_aoe_ability(enemy, player.grid_pos, ability)
		else:
			accepted = await manager._execute_ability(enemy, recipient, ability)
		check(not accepted, "silenced execution rejects " + str(ability.get("display_name", "Missing ability")))
		check(enemy.mp == 100 and player.hp == 2000 and enemy.hp == 1500, "rejected cast changes no MP or HP: " + str(ability.get("display_name", "Missing ability")))
		check(not manager.active_unit_has_acted, "rejected cast consumes no action: " + str(ability.get("display_name", "Missing ability")))
		await manager._recover_action()
	enemy.unit_data.abilities.assign(["cure"])
	check(manager._find_enemy_ability(enemy, "cure", "ally").is_empty(), "silenced enemy healing planner excludes Cure")
	var heal_plan := manager._enemy_intent(enemy, "heal", enemy, "Cure", "fixture", heal)
	check(not manager._enemy_intent_is_valid(enemy, heal_plan), "Silence invalidates healing intent")
	# Silence arriving during presentation must be checked at contact before any cost.
	manager.action_state_changed.connect(_interrupt_on_admission)
	for ability in [magic, chain, heal]:
		enemy.statuses.clear()
		player.statuses.clear()
		enemy.hp = 1500
		enemy.mp = 100
		player.hp = 2000
		manager.active_unit_has_acted = false
		var is_heal: bool = ability.spell_type == "cure"
		var intent := manager._enemy_intent(enemy, "heal" if is_heal else "spell", enemy if is_heal else player, ability.display_name, "fixture", ability)
		check(manager._enemy_intent_is_valid(enemy, intent), "pre-interruption intent valid: " + str(ability.get("display_name", "Missing ability")))
		interrupt_actor = enemy
		interrupt_armed = true
		await manager._execute_enemy_intent(enemy, intent)
		check(enemy.has_status("silence"), "Silence applied during presentation: " + str(ability.get("display_name", "Missing ability")))
		check(enemy.mp == 100 and player.hp == 2000 and enemy.hp == 1500, "interrupted cast changes no MP or HP: " + str(ability.get("display_name", "Missing ability")))
		check(not manager.active_unit_has_acted, "interrupted cast consumes no action: " + str(ability.get("display_name", "Missing ability")))
		await manager._recover_action()
		check(not manager.is_resolving_action and manager.action_lifecycle.phase == "idle", "interrupted cast releases lifecycle: " + str(ability.get("display_name", "Missing ability")))
	manager.action_state_changed.disconnect(_interrupt_on_admission)
	# Physical classification is shared across player selection and enemy candidates.
	enemy.unit_data.abilities.assign(["mighty_strike"])
	enemy.hp = 2000
	enemy.mp = 100
	player.hp = 2000
	check(not manager._find_best_spell_intent(enemy).is_empty(), "silenced enemy can plan physical skill")
	var physical_plan := manager._enemy_intent(enemy, "spell", player, "Mighty Strike", "fixture", physical)
	check(manager._enemy_intent_is_valid(enemy, physical_plan), "silenced physical intent remains valid")
	seed(12345)
	await manager._execute_enemy_intent(enemy, physical_plan)
	check(enemy.mp == 100 - int(physical.mp_cost) and manager.active_unit_has_acted, "silenced physical skill executes with ordinary one-time cost")
	await manager._recover_action()
	manager.current_phase = BattleManager.Phase.PLAYER_TURN
	manager.active_unit_id = player.unit_id
	manager.active_unit_has_acted = false
	manager.active_unit_has_moved = false
	player.unit_data.abilities.assign(["void_pulse", "mighty_strike", "defend", "cure"])
	player.statuses.clear()
	silence(player)
	player.mp = 100
	manager.active_command = ""
	manager.selected_ability_id = ""
	manager.ability_mode_started.connect(func(ids: Array): offered_abilities = ids)
	manager.select_command("ability")
	check("mighty_strike" in offered_abilities and "defend" in offered_abilities, "silenced player menu retains physical skill and Defend")
	check(not "void_pulse" in offered_abilities and not "cure" in offered_abilities, "silenced player menu excludes magic and heal")
	manager.cancel_pending_action()
	manager.select_ability("void_pulse")
	check(manager.selected_ability_id.is_empty() and player.mp == 100 and not manager.active_unit_has_acted, "silenced player magical selection rejected without cost")
	manager.select_ability("mighty_strike")
	check(manager.selected_ability_id == "mighty_strike" and manager.active_command == "ability_target", "silenced player selects physical skill normally")
	seed(12345)
	await manager._on_unit_clicked(enemy.unit_id)
	check(manager.active_unit_has_acted and player.mp == 100 - int(physical.mp_cost), "silenced player executes physical skill with ordinary cost")
	manager.active_unit_has_acted = false
	await manager.select_ability("defend")
	check(player.has_status("defending") and manager.active_unit_has_acted, "silenced player can execute Defend")
	check(player.has_status("silence"), "physical skill use does not remove Silence")
	manager.active_unit_has_acted = false
	player.remove_status("silence")
	manager.select_command("ability")
	check("void_pulse" in offered_abilities and "cure" in offered_abilities, "removing Silence restores magical menu choices")
	manager.cancel_pending_action()
	battle.queue_free()
	await get_tree().process_frame
	print("Silence contract: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
