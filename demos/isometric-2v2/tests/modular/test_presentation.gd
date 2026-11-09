extends "res://tests/test_zane_impact_actions.gd"
const FRAMES := preload("res://scripts/presentation/ModularSpellFrames.gd")
var seen: Dictionary = {}
func _process(_delta: float) -> void:
	for reference in controllers:
		var owner = reference.get_ref()
		if not is_instance_valid(owner): continue
		for fx in owner._fx:
			if is_instance_valid(fx) and fx is FRAMES and fx.visible and fx.texture != null:
				seen["%s:%s" % [fx.stage,fx.frame_index]] = true

func make_demo() -> Node:
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
		unit.hp = 2000
		unit.mp = 200
		unit.temper = 0
		unit.ether = 0
	manager.units.zane.grid_pos = Vector2i(1,2)
	manager.units.Enemy_1.grid_pos = Vector2i(3,2)
	manager.units.Enemy_2.grid_pos = Vector2i(3,3)
	manager.active_unit_id = "zane"
	return battle

func run() -> void:
	VFX.child_entered_tree.connect(observe)
	for fps in [30,8]:
		Engine.max_fps = fps
		seen.clear()
		controllers.clear()
		var battle = await make_demo()
		var manager: BattleManager = battle.battle_manager
		check(await manager._execute_aoe_ability(manager.units.zane,manager.units.Enemy_1.grid_pos,AbilityDB.get_ability("thunderstrike")),"actual chain admitted at %s FPS" % fps)
		var owner = controllers.back().get_ref()
		check(owner._tails.size()==2,"both actual chain contacts own tails")
		await manager._recover_action()
		for frame in 30: await get_tree().process_frame
		for phase in ["casting","formation","action","collision","dissipation"]:
			for frame in (4 if phase=="casting" else 3):
				check(seen.has("%s:%s" % [phase,frame]),"%s frame %s sampled at %s FPS" % [phase,frame,fps])
		check(not is_instance_valid(owner),"complete tail retires")
		battle.queue_free()
		await get_tree().process_frame
	Engine.max_fps = 30
	for ability_id in ["void_pulse","dark_breath","shadow_mend"]:
		seen.clear()
		controllers.clear()
		var battle = await make_demo()
		var manager: BattleManager = battle.battle_manager
		var caster: Unit = manager.units.zane
		var target: Unit = manager.units.Enemy_1
		if ability_id == "shadow_mend":
			caster = manager.units.Enemy_2
			target = caster
			caster.hp = 1
		check(await manager._execute_ability(caster,target,AbilityDB.get_ability(ability_id)),"complete actual %s" % ability_id)
		var owner = controllers.back().get_ref()
		check(owner._support == (ability_id == "shadow_mend"),"support feedback correctly classified")
		await manager._recover_action()
		for frame in 30: await get_tree().process_frame
		for phase in ["casting","formation","action","collision","dissipation"]:
			for frame in (4 if phase=="casting" else 3):
				check(seen.has("%s:%s" % [phase,frame]),"%s %s frame %s sampled" % [ability_id,phase,frame])
		check(not is_instance_valid(owner),"%s tail retires" % ability_id)
		battle.queue_free()
		await get_tree().process_frame
	Engine.max_fps = 60
	for cancel_phase in ["casting","formation","action"]:
		cues.clear()
		var battle = await make_demo()
		var manager: BattleManager = battle.battle_manager
		var caster: Unit = manager.units.zane
		var target: Unit = manager.units.Enemy_1
		var callback := func(node: Node):
			if node.has_signal("phase_presented"):
				node.phase_presented.connect(func(phase: String):
					if phase == cancel_phase: manager.action_lifecycle.cancel()
				)
		VFX.child_entered_tree.connect(callback)
		check(not await manager._execute_aoe_ability(caster,target.grid_pos,AbilityDB.get_ability("thunderstrike")),"cancel %s prevents contact" % cancel_phase)
		check(caster.mp==200 and target.hp==2000,"cancel spends and damages nothing")
		check(not cues.has("modular_release"),"cancel before release never emits late audio")
		if cancel_phase=="casting": check(cues.is_empty(),"synchronous casting cancellation emits no cue")
		VFX.child_entered_tree.disconnect(callback)
		await manager._recover_action()
		battle.queue_free()
		await get_tree().process_frame
	print("Modular presentation: %s checks, %s failures" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
