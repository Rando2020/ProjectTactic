## Independent late-windup regression: longer cosmetics must not spend early.
extends "res://prototypes/isometric/SkillCompletionLifecycleTest.gd"
func run() -> void:
	VFX.child_entered_tree.connect(observe)
	for id in ["fire","thunderstrike","void_pulse","dark_breath","shadow_mend","defend"]:
		await late_cancel_case(id)
	print("Slow cast lifecycle: %d checks, %d failures" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func late_cancel_case(id: String) -> void:
	var battle = await boot()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.kael if id=="defend" else manager.units.zane
	var target: Unit = actor if id in ["shadow_mend","defend"] else manager.units.Enemy_1
	if id=="shadow_mend": actor.hp=1900
	var ability := AbilityDB.get_ability(id)
	var mp := actor.mp
	var hp := target.hp
	var ct := actor.ct
	var late_checks := {"seen":false}
	get_tree().create_timer(0.50).timeout.connect(func():
		late_checks.seen=true
		check(manager.action_lifecycle.phase=="anticipation",id+" still anticipates at0.50s")
		check(actor.mp==mp and target.hp==hp and outcomes.is_empty(),id+" late casting has no early contact or MP cost")
		manager.action_lifecycle.cancel()
	)
	var area := id in ["fire","thunderstrike"]
	var accepted := await manager._execute_aoe_ability(actor,target.grid_pos,ability) if area else await manager._execute_ability(actor,target,ability)
	check(late_checks.seen and not accepted,id+" late cancellation rejects action")
	check(actor.mp==mp and target.hp==hp and actor.ct==ct and outcomes.is_empty(),id+" late abort preserves resources and initiative")
	await manager._recover_action()
	check(manager.action_lifecycle.phase=="idle",id+" late abort releases input lifecycle")
	accepted = await manager._execute_aoe_ability(actor,target.grid_pos,ability) if area else await manager._execute_ability(actor,target,ability)
	check(accepted,id+" immediate retry admitted")
	check(actor.mp==mp-int(ability.mp_cost) and actor.ct==ct,id+" retry spends once, no initiative shift")
	check(outcomes.size()==(0 if id=="defend" else (2 if area else 1)),id+" retry has exact authoritative outcome count")
	await manager._recover_action()
	battle.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.9).timeout
	for reference in controllers: check(not is_instance_valid(reference.get_ref()),id+" cancel/retry leaves no visual owner")
