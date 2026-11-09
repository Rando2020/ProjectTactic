extends "res://tests/test_zane_impact_actions.gd"
const FRAMES := preload("res://scripts/presentation/FireballFrames.gd")
func run() -> void:
	if "--demo-fire-only" in OS.get_cmdline_user_args():
		VFX.child_entered_tree.connect(observe)
		await skirmish_dispatch_contract()
		print("Actual Skirmish Fire: %d checks, %d failures" % [checks,failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1)
		return
	frame_contract()
	VFX.child_entered_tree.connect(observe)
	await fire_fixtures()
	await interruptions()
	await stale_ticket_overlap()
	await actor_dies_after_resolution()
	await fan_recipient_removed()
	await bridge_cancel_contract()
	await postcontact_cancel_contract()
	await cosmetic_rng()
	await skirmish_dispatch_contract()
	await get_tree().process_frame
	print("Fireball sheet: %d checks, %d failures" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func frame_contract() -> void:
	var sprite := FRAMES.new()
	check(sprite.available(), "all sixteen authored textures load")
	for texture in sprite._frames:
		check(texture.get_size() == Vector2(512,512), "uniform 512 frame dimensions")
	for stage_index in 4:
		var stage_name: String = ["charge","travel","impact","dissipate"][stage_index]
		sprite.set_stage(stage_name)
		for progress in [-1.0,0.0,0.24,0.25,0.5,0.75,1.0,2.0]:
			sprite.show_progress(progress)
			check(sprite.frame_index == stage_index*4+mini(3,int(clampf(progress,0,1)*4)), "stage boundaries clamp to four authored frames")
	for direction in [Vector2(2,1),Vector2(-2,1),Vector2(-2,-1),Vector2(2,-1)]:
		sprite.set_stage("travel",direction)
		check(is_equal_approx(sprite.rotation+FRAMES.SOURCE_TRAVEL_ANGLE,direction.angle()), "projectile follows each projected direction")
		check(sprite.offset == Vector2(-64,0), "projectile head pivot retained")
		for stage_name in ["charge","impact","dissipate"]:
			sprite.set_stage(stage_name,direction)
			check(is_zero_approx(sprite.rotation) and sprite.offset == Vector2(0,-144), "ground ring stays upright with fixed ground pivot")
	for hit in [true,false]:
		sprite.show()
		sprite.start_tail(hit)
		var previous: int = sprite.frame_index
		for step in int(FRAMES.TAIL_DURATION * 100.0) - 1:
			sprite._process(0.01)
			check(sprite.frame_index >= previous, "tail never rewinds authored frames")
			previous = sprite.frame_index
		check(sprite.visible and sprite.frame_index == 15, "tail reaches final dissipate frame before retirement")
		sprite._process(0.02)
		check(not sprite.visible and not sprite._tail, "tail retires at bounded duration")
	sprite.free()

func interruptions() -> void:
	for fixture: String in ["before release", "during travel", "actor death", "target removal", "silence", "repeated click", "scene exit"]:
		print("Interruption fixture: " + fixture)
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var caster: Unit = manager.units.zane
		var target: Unit = recipients(manager)[0]
		schedule_action_interruption(fixture,func():
			if fixture == "during travel":
				var owner = controllers.back().get_ref()
				check(is_instance_valid(owner) and not is_instance_valid(owner._trail), "Authored Fire travels without a competing procedural trail")
				check(is_instance_valid(owner) and is_instance_valid(owner._projectile) and owner._projectile is Sprite2D and owner._projectile.available(), "one projectile uses the complete local authored frame set")
			match fixture:
				"actor death": caster.receive_damage(99999,"magical")
				"target removal": target.queue_free()
				"silence":
					var status := StatusEffect.new()
					status.status_id = "silence"
					caster.apply_status(status)
				"repeated click": check(not await manager.call("_present_action",caster,target.grid_pos,"cast",target,"fire"), "repeated admission cannot replace active ticket")
				"scene exit": battle.queue_free()
				_: manager.action_lifecycle.cancel()
		)
		if fixture == "scene exit":
			# Godot cancels freed Node-owned coroutine continuations. Observe surviving
			# VFX ownership, rather than awaiting a return from a deliberately freed Node.
			manager._execute_ability(caster,target,AbilityDB.get_ability("fire"))
			await get_tree().create_timer(0.55).timeout
			check(not is_instance_valid(battle) and outcomes.is_empty(), "scene exit cancels before contact without a late result")
			await dispose(null)
			continue
		var executed := await manager._execute_ability(caster,target,AbilityDB.get_ability("fire"))
		if fixture == "repeated click": check(executed and outcomes.size() == 1 and caster.mp == 88, "repeated input leaves exactly one original result/spend")
		if fixture != "repeated click": check(not executed and outcomes.is_empty(), fixture + ": no contact/damage after invalidation")
		if is_instance_valid(caster) and fixture != "repeated click": check(caster.mp == 100, fixture + ": no late MP spend")
		if fixture == "before release": check(not cues.has("fire_release"), "cancel before release prevents late cue")
		if is_instance_valid(battle):
			await manager._recover_action()
			var previous_cues := cues.size()
			if fixture in ["before release", "during travel"]:
				check(await manager.call("_present_action",caster,Vector2i(5,4),"cast",null,"fire"), "cancel permits a new independent ticket")
				check(cues.size() > previous_cues, "new ticket owns fresh cues")
		await dispose(battle)


func make_battle() -> Node:
	var battle := super.make_battle()
	GameState.practice_session["isolated_isometric"] = true
	return battle


func skirmish_dispatch_contract() -> void:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.practice_session = {}
	var battle := preload("res://prototypes/isometric/Skirmish.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	for frame in 300:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().process_frame
	check(manager.current_phase == BattleManager.Phase.PLAYER_TURN, "actual Skirmish reaches player input")
	var actor: Unit = manager.units.zane
	var target: Unit = manager.units.Enemy_2
	check(not actor.has_zane_impact_presentation(), "Skirmish is genuinely 2D, not legacy rig presenter")
	check(bool(GameState.practice_session.get("isolated_isometric",false)), "actual demo opts into authored Fire")
	actor.grid_pos = Vector2i(2,3)
	actor.mp = 200
	target.grid_pos = Vector2i(4,3)
	target.hp = 2000
	manager.units.Enemy_1.grid_pos = Vector2i(0,0)
	var demo_results: Array[Dictionary] = []
	manager.combat_resolver.combat_resolved.connect(func(result: Dictionary): demo_results.append(result))
	var observed := {"charge":0,"travel":0}
	var observe_demo := func(node: Node):
		if not node.has_signal("phase_presented"): return
		node.phase_presented.connect(func(phase: String):
			if phase == "charge":
				observed.charge += 1
				check(bool(node.context.get("authored_fire_sheet",false)) and node._charge is FRAMES, "actual Skirmish dispatches authored charge")
				check(node._charge.global_position.distance_to(battle.tactical_grid.to_global(battle.tactical_grid._unit_foot_pos(actor.grid_pos))) < 0.1, "actual charge matches projected ground anchor")
				check(not battle.rotate_stage(1) and not battle.set_stage_mode(not battle.tactical_grid.rotatable_mode), "rotation and stage mode locked during real Fire")
			if phase == "release": inspect_demo_travel(node, observed)
		)
	VFX.child_entered_tree.connect(observe_demo)
	for view in 5:
		check(battle.set_stage_mode(view > 0), "switch view while idle")
		if view > 1: check(battle.rotate_stage(1), "rotate idle stage")
		if view > 0: check(battle.tactical_grid.quarter_turn == view-1, "actual camera covers each quarter turn")
		await get_tree().process_frame
		var mp := actor.mp
		var hp := target.hp
		var ct := actor.ct
		demo_results.clear()
		check(await manager._execute_aoe_ability(actor,target.grid_pos,AbilityDB.get_ability("fire")), "actual Skirmish Fire accepted view %d" % view)
		var owner = controllers.back().get_ref()
		var authored_tails := 0
		if is_instance_valid(owner):
			for effect in owner._fx:
				if is_instance_valid(effect) and effect is FRAMES and effect.stage in ["impact","dissipate"]:
					authored_tails += 1
		check(authored_tails == 1, "actual Skirmish produces one authored outcome tail")
		check(actor.mp == mp-12 and actor.ct == ct, "actual view spends MP12 exactly once without CT write")
		check(demo_results.size() == 1 and target.hp < hp, "actual view resolves one target damage once")
		await manager._recover_action()
		await get_tree().create_timer(0.65).timeout
		check(not manager.is_resolving_action and manager.action_lifecycle.phase == "idle", "actual view returns to command-ready state")
	check(observed.charge == 5 and observed.travel == 5, "painted plus all four rotations use authored stages")
	var mp := actor.mp
	var hp := target.hp
	demo_results.clear()
	get_tree().create_timer(0.08).timeout.connect(manager.action_lifecycle.cancel)
	check(not await manager._execute_aoe_ability(actor,target.grid_pos,AbilityDB.get_ability("fire")), "actual demo cancellation rejects contact")
	check(actor.mp == mp and target.hp == hp and demo_results.is_empty(), "cancelled actual demo does not spend or damage")
	await manager._recover_action()
	check(battle.rotate_stage(1), "rotation unlocks after actual demo cancellation")
	VFX.child_entered_tree.disconnect(observe_demo)
	await dispose(battle)

func inspect_demo_travel(owner: Node, observed: Dictionary) -> void:
	await get_tree().process_frame
	if not is_instance_valid(owner):
		check(false,"actual demo travel owner survives release")
		return
	observed.travel += 1
	check(owner._projectile is FRAMES and owner._projectile.stage == "travel", "actual demo dispatches authored projectile")
	check(is_equal_approx(owner._projectile.rotation+FRAMES.SOURCE_TRAVEL_ANGLE,owner._flight_direction.angle()), "actual demo trajectory matches projected direction")
