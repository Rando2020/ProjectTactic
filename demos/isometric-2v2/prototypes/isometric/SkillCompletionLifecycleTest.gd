extends "res://tests/test_zane_impact_actions.gd"

func run() -> void:
	VFX.child_entered_tree.connect(observe)
	for spec in [["thunderstrike",14,""],["void_pulse",12,"silence"],["dark_breath",18,"poison"],["shadow_mend",16,""],["mighty_strike",8,""],["defend",0,"defending"]]:
		await skill_case(spec, false)
		if spec[0] in ["thunderstrike","void_pulse","dark_breath","shadow_mend"]: await skill_case(spec,true)
	for scenario in ["cancel","duplicate","actor_ko","silence","target_removed"]:
		await interrupt_case(scenario)
	print("Skill completion lifecycle: %d checks, %d failures" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func boot() -> Node:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.practice_session = {}
	var battle := preload("res://prototypes/isometric/Skirmish.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	for i in 300:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().process_frame
	for unit: Unit in manager.units.values():
		unit.unit_data = unit.unit_data.duplicate(true)
		unit.unit_data.base_stats.hp = 2000
		unit.hp = 2000
		unit.mp = 200
		unit.temper = 0
		unit.ether = 0
		unit.statuses.clear()
	manager.units.zane.grid_pos = Vector2i(1,2)
	manager.units.kael.grid_pos = Vector2i(1,3)
	manager.units.Enemy_1.grid_pos = Vector2i(2,2)
	manager.units.Enemy_2.grid_pos = Vector2i(2,3)
	manager.combat_resolver.combat_resolved.connect(func(result: Dictionary): outcomes.append(result))
	outcomes.clear(); controllers.clear(); cues.clear(); phases.clear()
	return battle

func skill_case(spec: Array, enemy: bool) -> void:
	var battle = await boot()
	var manager: BattleManager = battle.battle_manager
	var id := str(spec[0])
	var ability := AbilityDB.get_ability(id)
	var actor: Unit = manager.units.Enemy_2 if enemy else (manager.units.kael if id in ["mighty_strike","defend"] else manager.units.zane)
	var target: Unit = manager.units.zane if enemy else manager.units.Enemy_1
	if id in ["shadow_mend","defend"]: target = actor
	if id == "shadow_mend": actor.hp = 1990
	if id == "mighty_strike":
		# Deterministic contact fixture: back attack uses the existing 100% hit rule.
		target.set_facing(CombatFormula.FACING_OPPOSITE[CombatFormula.attack_direction(actor.grid_pos,target.grid_pos)])
		manager.tactical_grid.tiles[actor.grid_pos]["height"] = 0
		manager.tactical_grid.tiles[target.grid_pos]["height"] = 0
	var hp := target.hp
	var ct := actor.ct
	var accepted := true
	if enemy:
		var kind := "heal" if id == "shadow_mend" else "spell"
		var intent := manager._enemy_intent(actor,kind,target,str(ability.display_name),"QA fixture",ability)
		await manager._execute_enemy_intent(actor,intent)
	else:
		accepted = await manager._execute_aoe_ability(actor,target.grid_pos,ability) if id=="thunderstrike" else await manager._execute_ability(actor,target,ability)
	var prefix := ("AI " if enemy else "player ")+id
	check(accepted, prefix+" admitted")
	check(actor.mp == 200-int(spec[1]),prefix+" spends exact MP once")
	check(actor.ct == ct,prefix+" presentation does not shift initiative")
	check(controllers.size()==1,prefix+" has exactly one presentation owner")
	var owner = controllers.back().get_ref() if not controllers.is_empty() else null
	check(is_instance_valid(owner) and owner._outcomes_presented,prefix+" receives contact outcome")
	var labels := ""
	if is_instance_valid(owner):
		for fx in owner._fx:
			if is_instance_valid(fx) and fx is Label: labels += fx.text+" "
	if id == "shadow_mend":
		check(target.hp==2000 and outcomes.size()==1 and outcomes[0].get("healed",0)==10,prefix+" reports capped actual healing")
		check("+10 HP" in labels and "-" not in labels,prefix+" heal not presented as damage")
		check("modular_heal" in cues and "pause" not in phases,prefix+" support feedback")
	elif id=="defend":
		check(target.hp==hp and outcomes.is_empty(),prefix+" does not damage")
		check("GUARD" in labels,prefix+" guard callout")
	else:
		check(target.hp<hp,prefix+" damages actual recipient")
		check(outcomes.size()==(2 if id=="thunderstrike" else 1),prefix+" outcome count")
	if not str(spec[2]).is_empty():
		check(target.has_status(str(spec[2])),prefix+" actual status applied")
		for status in target.statuses:
			if status.status_id == str(spec[2]): check(status.duration==(3 if id=="dark_breath" else 2),prefix+" exact existing status duration")
		if id!="defend": check(str(spec[2]).capitalize() in labels,prefix+" status label matches applied status")
		else: check("Until next turn" in labels,prefix+" guard expiry understandable")
	await manager._recover_action()
	check(manager.action_lifecycle.phase=="idle",prefix+" recovers")
	check(battle.set_stage_mode(true) and battle.rotate_stage(1),prefix+" rotation unlocked after recovery")
	check(battle.set_compact_skins(false),prefix+" skin switch unlocked")
	for angle in 3: check(battle.rotate_stage(1),prefix+" remaining camera rotation %d" % angle)
	await get_tree().create_timer(0.9).timeout
	for ref in controllers: check(not is_instance_valid(ref.get_ref()),prefix+" visual owner retires")
	battle.queue_free()
	await get_tree().process_frame

func interrupt_case(scenario: String) -> void:
	var battle = await boot()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var target: Unit = manager.units.Enemy_1
	var hp := target.hp
	get_tree().create_timer(0.08).timeout.connect(func():
		match scenario:
			"cancel": manager.action_lifecycle.cancel()
			"actor_ko": actor.hp=0
			"target_removed": target.queue_free()
			"silence":
				var status := StatusEffect.new()
				status.status_id="silence"
				actor.apply_status(status)
			"duplicate": check(not await manager._execute_ability(actor,target,AbilityDB.get_ability("void_pulse")),"duplicate rejected during windup")
	)
	var accepted := await manager._execute_ability(actor,target,AbilityDB.get_ability("void_pulse"))
	if scenario=="duplicate": check(accepted and actor.mp==188 and outcomes.size()==1,"duplicate cannot repeat spend/contact")
	else: check(not accepted and actor.mp==200 and (not is_instance_valid(target) or target.hp==hp) and outcomes.is_empty(),scenario+" abort has no contact/spend")
	await manager._recover_action()
	check(manager.action_lifecycle.phase=="idle",scenario+" releases lifecycle")
	if scenario in ["cancel","actor_ko","silence"]:
		actor.hp=2000
		actor.statuses.clear()
		check(await manager._execute_ability(actor,target,AbilityDB.get_ability("void_pulse")),scenario+" immediate retry succeeds")
		check(actor.mp==188 and outcomes.size()==1,scenario+" retry spends and contacts once")
		await manager._recover_action()
	battle.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	for ref in controllers: check(not is_instance_valid(ref.get_ref()),scenario+" no lingering visual owner")
