extends "res://tests/blooming_skills/HeroSkillsTest.gd"
## Extra independent coverage for new skill outcomes and counter-death cleanup.
func run() -> void:
	GameState._init_defaults()
	for id in ["delay_strike", "heavy_slash"]:
		await boot()
		fixture("kael")
		var caster: Unit = manager.units.kael
		var target: Unit = manager.units.Enemy_1
		target.hp = 1
		seed(0)
		var result: Dictionary = await manager._execute_ability_with_result(caster, target, AbilityDB.get_ability(id), true)
		check(result.executed and target.hp == 0, id + " fixture produces target KO")
		check(target.ct == 0 and not result.outcome.has("target_ct_delay"), id + " dead target has no delay debt")
		check(caster.ct == (-30 if id == "heavy_slash" else 0), id + " target KO preserves living actor recovery commitment")
		await cleanup()
		await boot()
		fixture("kael")
		caster = manager.units.kael
		target = manager.units.Enemy_1
		caster.hp = 1
		# Back hit has 100% accuracy. Select a real resolver counter roll.
		var counter_seed := 0
		while true:
			seed(counter_seed)
			randi_range(1, 100)
			randi_range(1, 100)
			if randf() < 0.25: break
			counter_seed += 1
		var saw_target_delay := [false]
		manager.turn_order.timeline_updated.connect(func(_order):
			if target.ct == -30: saw_target_delay[0] = true
		)
		stage(id, target)
		seed(counter_seed)
		battle.battle_ui._selection.confirm_review()
		await settle()
		await get_tree().create_timer(0.05).timeout
		check(caster.hp == 0, id + " real review execution counter-KOs actor")
		check(caster.ct == 0, id + " dead actor has no recovery debt")
		check(saw_target_delay[0] == (id == "delay_strike"), id + " surviving target receives correct contact delay")
		check(not manager.is_resolving_action, id + " counter KO releases action lock")
		check(not (manager.current_phase == BattleManager.Phase.PLAYER_TURN and manager.active_unit_id == "kael"), id + " counter KO does not strand dead actor in player turn")
		await cleanup()
	finish()
