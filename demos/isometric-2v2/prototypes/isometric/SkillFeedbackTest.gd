extends "res://tests/test_zane_impact_actions.gd"

func run() -> void:
	VFX.child_entered_tree.connect(observe)
	GameState._init_defaults()
	GameState.active_run = null
	GameState.practice_session = {}
	var battle := preload("res://prototypes/isometric/Skirmish.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	for i in 300:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().process_frame
	var actor: Unit = manager.units.zane
	var target: Unit = manager.units.Enemy_1
	var second: Unit = manager.units.Enemy_2
	actor.grid_pos = Vector2i(1,2)
	target.grid_pos = Vector2i(3,2)
	second.grid_pos = Vector2i(3,3)
	for unit: Unit in manager.units.values():
		unit.hp = 2000
		unit.mp = 200
		unit.temper = 0
		unit.ether = 0
	manager.active_unit_id = actor.unit_id
	manager.tactical_grid.ability_tiles = [target.grid_pos]
	var before_ct := actor.ct
	var fc := manager._ability_preview_for_tile(target.grid_pos, AbilityDB.get_ability("thunderstrike"))
	check(fc.get("target_id", "") == target.unit_id, "preview identifies actual target")
	check(fc.get("affected_targets", []).size() == 2, "preview identifies both ordered chain recipients")
	check(fc.get("target_intent", {}).has("action"), "preview contains current enemy plan")
	check(actor.mp == 200 and actor.ct == before_ct and target.hp == 2000, "preview is read only")
	var banners: Array[Dictionary] = []
	manager.action_clash_started.connect(func(value: Dictionary): banners.append(value))
	outcomes.clear()
	manager.combat_resolver.combat_resolved.connect(func(result: Dictionary): outcomes.append(result))
	check(await manager._execute_aoe_ability(actor,target.grid_pos,AbilityDB.get_ability("thunderstrike")), "actual chain executes")
	check(banners.size() == 1 and banners[0].get("target_id", "") == target.unit_id, "chain action banner identifies its real primary")
	check(actor.mp == 186 and outcomes.size() == 2, "one MP14 spend and two authoritative recipients")
	check(manager._action_presentation_context.get("authored_spell_sheet", false), "actual chain opts into complete spell presentation")
	for result in outcomes:
		check(result.get("feedback_owner", "") == "zane_impact_v1", "chain damage has one feedback owner")
	await manager._recover_action()
	await get_tree().create_timer(0.8).timeout
	battle.queue_free()
	await get_tree().process_frame
	print("Skill feedback: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
