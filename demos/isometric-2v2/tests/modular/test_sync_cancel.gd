extends "res://tests/modular/test_presentation.gd"
func run() -> void:
	VFX.child_entered_tree.connect(observe)
	var battle = await make_demo()
	var manager: BattleManager = battle.battle_manager
	var callback := func(node: Node):
		if node.has_signal("phase_presented"):
			node.phase_presented.connect(func(phase: String):
				if phase=="impact": manager.action_lifecycle.cancel()
			)
	VFX.child_entered_tree.connect(callback)
	check(await manager._execute_aoe_ability(manager.units.zane,manager.units.Enemy_1.grid_pos,AbilityDB.get_ability("thunderstrike")),"admitted contact still resolves authoritative result")
	check(not get_tree().paused,"synchronous impact cancel cannot apply stale hit-pause")
	check(is_zero_approx(battle._zane_kick_remaining),"synchronous impact cancel cannot apply stale kick")
	check(not cues.has("thunderstrike_contact"),"synchronous impact cancel cannot emit late contact cue")
	VFX.child_entered_tree.disconnect(callback)
	get_tree().paused = false
	await manager._recover_action()
	battle.queue_free()
	await get_tree().process_frame
	battle = await make_demo()
	manager = battle.battle_manager
	var cue_callback := func(node: Node):
		if node.has_signal("cue_started"):
			node.cue_started.connect(func(cue: String):
				if cue=="thunderstrike_contact": manager.action_lifecycle.cancel()
			)
	VFX.child_entered_tree.connect(cue_callback)
	check(await manager._execute_aoe_ability(manager.units.zane,manager.units.Enemy_1.grid_pos,AbilityDB.get_ability("thunderstrike")),"contact cue cancellation preserves admitted resolution")
	check(not get_tree().paused,"contact cue observer cancellation cannot apply stale pause")
	check(is_zero_approx(battle._zane_kick_remaining),"contact cue observer cancellation cannot apply stale kick")
	VFX.child_entered_tree.disconnect(cue_callback)
	get_tree().paused = false
	await manager._recover_action()
	battle.queue_free()
	await get_tree().process_frame
	battle = await make_demo()
	manager = battle.battle_manager
	var state := {"rings":0}
	var guard_callback := func(node: Node):
		if node.has_signal("phase_presented"):
			node.child_entered_tree.connect(func(fx: Node):
				if fx.get_meta("zane_effect_role","")=="support_ring": state.rings += 1
			)
			node.phase_presented.connect(func(phase: String):
				if phase=="casting": manager.action_lifecycle.cancel()
			)
	VFX.child_entered_tree.connect(guard_callback)
	check(not await manager._execute_ability(manager.units.kael,manager.units.kael,AbilityDB.get_ability("defend")),"guard cancelled before contact")
	check(state.rings==0,"cancelled casting phase cannot create a stale fallback ring")
	VFX.child_entered_tree.disconnect(guard_callback)
	await manager._recover_action()
	battle.queue_free()
	await get_tree().process_frame
	print("Modular synchronous cancel: %s checks, %s failures" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
