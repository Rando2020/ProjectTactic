## Integration regression: real 2D Skirmish input must dispatch authored melee,
## without changing authoritative resolution, costs, turns, or miss behavior.
extends "res://tests/test_zane_impact_actions.gd"

func run() -> void:
	VFX.child_entered_tree.connect(observe)
	frame_contract()
	await actual_demo_contract()
	print("Melee sheet: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func role_count(owner: Variant, role: String) -> int:
	if not is_instance_valid(owner): return 0
	var count := 0
	for fx in owner._fx:
		if is_instance_valid(fx) and str(fx.get_meta("zane_effect_role", "")) == role: count += 1
	return count

func choose_roll(actor: Unit, target: Unit, manager: BattleManager, miss: bool) -> void:
	var formula := CombatFormula.calculate_physical_attack(actor, target, manager.tactical_grid.get_tile(actor.grid_pos), manager.tactical_grid.get_tile(target.grid_pos))
	for candidate in 100000:
		seed(candidate)
		var hit := randi_range(1,100) <= int(formula.hit_pct)
		randi_range(1,100)
		var counter := randf() < 0.25
		if hit != miss and not counter:
			seed(candidate)
			return
	check(false,"can choose deterministic hit/miss without changing combat rules")

func arm(manager: BattleManager, actor: Unit, target: Unit) -> void:
	manager.active_unit_id = actor.unit_id
	manager.current_phase = BattleManager.Phase.PLAYER_TURN
	manager.active_unit_has_acted = false
	manager.active_unit_has_moved = false
	manager.select_command("attack")
	manager.tactical_grid.attack_tiles.assign([target.grid_pos])
	outcomes.clear()
	cues.clear()
	phases.clear()

func actual_demo_contract() -> void:
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
	var actor: Unit = manager.units.kael
	var target: Unit = manager.units.Enemy_1
	for unit: Unit in manager.units.values():
		unit.unit_data = unit.unit_data.duplicate(true)
		unit.hp = 10000
		unit.unit_data.base_stats.hp = 10000
		unit.temper = 0
		unit.ether = 0
		unit.statuses.clear()
	actor.grid_pos = Vector2i(2,3)
	target.grid_pos = Vector2i(3,3)
	manager.units.zane.grid_pos = Vector2i(0,0)
	manager.units.Enemy_2.grid_pos = Vector2i(5,5)
	for tile in [actor.grid_pos,target.grid_pos]:
		manager.tactical_grid.tiles[tile]["height"] = 0
		manager.tactical_grid.tiles[tile]["terrain"] = "grass"
	check(not actor.has_zane_impact_presentation(), "real melee actor is 2D, not legacy rig")
	manager.combat_resolver.combat_resolved.connect(func(result: Dictionary): outcomes.append(result.duplicate(true)))
	for compact in [true,false]:
		check(battle.set_compact_skins(compact), "switch skin while idle")
		for view in 5:
			check(battle.set_stage_mode(view > 0), "switch stage while idle")
			if view > 1: check(battle.rotate_stage(1), "rotate idle stage")
			await get_tree().process_frame
			actor.set_facing("E")
			target.set_facing("W")
			arm(manager,actor,target)
			choose_roll(actor,target,manager,false)
			var hp := target.hp
			var mp := actor.mp
			var ct := actor.ct
			get_tree().create_timer(0.08).timeout.connect(func():
				check(target.hp == hp and outcomes.is_empty(), "no early damage during anticipation")
				check(not battle.rotate_stage(1) and not battle.set_compact_skins(not compact), "presentation locks view and skin switches")
				manager._on_unit_clicked(target.unit_id))
			await manager._on_unit_clicked(target.unit_id)
			var owner = controllers.back().get_ref() if not controllers.is_empty() else null
			check(is_instance_valid(owner) and bool(owner.context.get("authored_melee_sheet",false)), "actual click dispatches authored melee")
			check(role_count(owner,"melee_sheet_slash") == 1, "one authored slash per accepted basic attack")
			check(role_count(owner,"melee_sheet_impact") == 1, "one authored impact per actual damaged target")
			var proxies: Array[WeakRef] = []
			if is_instance_valid(owner):
				for fx in owner._fx:
					if is_instance_valid(fx) and str(fx.get_meta("zane_effect_role", "")).begins_with("melee_sheet_"):
						check(is_instance_valid(fx._proxy) == (view > 0), "rotatable effects use stage depth; painted effects retain 2D path")
						if is_instance_valid(fx._proxy): proxies.append(weakref(fx._proxy))
					if is_instance_valid(fx) and str(fx.get_meta("zane_effect_role", "")) == "melee_sheet_slash":
						var delta: Vector2 = battle.tactical_grid._unit_foot_pos(target.grid_pos)-battle.tactical_grid._unit_foot_pos(actor.grid_pos)
						check(Vector2.from_angle(fx.rotation).dot(delta.normalized()) > 0.999, "slash follows actual projected attack direction")
			check(outcomes.size() == 1 and target.hp < hp, "duplicate click produces exactly one combat resolution")
			check(actor.mp == mp and actor.ct == ct and manager.active_unit_id == actor.unit_id, "melee leaves MP CT and active turn unchanged")
			check(manager.active_unit_has_acted and not manager.active_unit_has_moved, "normal action budget consumed once")
			check(not manager.is_resolving_action and manager.action_lifecycle.phase == "idle", "real click returns command-ready")
			await get_tree().create_timer(0.65).timeout
			for proxy in proxies: check(not is_instance_valid(proxy.get_ref()), "retired action leaves no orphan stage effect cards")
	# Miss must retain the swing but never invent a hit burst or damage.
	var blind := StatusEffect.new()
	blind.status_id = "blind"
	actor.apply_status(blind)
	arm(manager,actor,target)
	choose_roll(actor,target,manager,true)
	var hp := target.hp
	await manager._on_unit_clicked(target.unit_id)
	var owner = controllers.back().get_ref() if not controllers.is_empty() else null
	check(outcomes.size() == 1 and outcomes[0].get("missed",false) and target.hp == hp, "real miss preserves authoritative HP")
	check(role_count(owner,"melee_sheet_slash") == 1 and role_count(owner,"melee_sheet_impact") == 0, "miss swings without false impact")
	await get_tree().create_timer(0.65).timeout
	# Cancellation before contact spends nothing and a new input can proceed.
	arm(manager,actor,target)
	var mp := actor.mp
	hp = target.hp
	get_tree().create_timer(0.08).timeout.connect(manager.action_lifecycle.cancel)
	await manager._on_unit_clicked(target.unit_id)
	check(outcomes.is_empty() and actor.mp == mp and target.hp == hp and not manager.active_unit_has_acted, "cancelled actual input has no damage or action spend")
	await get_tree().create_timer(0.65).timeout
	check(battle.rotate_stage(1), "cancel unlocks stage controls")
	actor.statuses.clear()
	arm(manager,actor,target)
	choose_roll(actor,target,manager,false)
	await manager._on_unit_clicked(target.unit_id)
	check(outcomes.size() == 1 and manager.active_unit_has_acted, "fresh input succeeds after cancelled ticket")
	await get_tree().create_timer(0.65).timeout
	# Exercise the actual enemy caller, not a fabricated presenter context.
	outcomes.clear()
	choose_roll(target,actor,manager,false)
	var enemy_mp := target.mp
	var enemy_ct := target.ct
	await manager._enemy_attack(target,actor)
	owner = controllers.back().get_ref()
	check(role_count(owner,"melee_sheet_slash") == 1 and role_count(owner,"melee_sheet_impact") == 1, "actual enemy melee dispatches both authored effects")
	check(outcomes.size() == 1 and target.mp == enemy_mp and target.ct == enemy_ct, "enemy hit resolves once without cosmetic resource writes")
	if not outcomes.is_empty():
		var records: Array[Dictionary] = [manager._presentation_record(actor,outcomes[0])]
		manager._present_action_outcomes(records)
		manager._present_action_outcomes(records)
		check(role_count(owner,"melee_sheet_slash") == 1 and role_count(owner,"melee_sheet_impact") == 1, "duplicate outcome delivery cannot duplicate slash or impact")
	await manager._recover_action()
	await get_tree().create_timer(0.65).timeout
	# Fire already owns its impact; adding melee must not attach a second burst.
	var mage: Unit = manager.units.zane
	mage.grid_pos = Vector2i(2,4)
	mage.mp = 200
	outcomes.clear()
	check(await manager._execute_aoe_ability(mage,target.grid_pos,AbilityDB.get_ability("fire")), "existing actual Fire still dispatches")
	owner = controllers.back().get_ref()
	check(role_count(owner,"melee_sheet_slash") == 0 and role_count(owner,"melee_sheet_impact") == 0, "Fire never receives duplicate melee art")
	check(role_count(owner,"fire_sheet_impact") + role_count(owner,"fire_sheet_dissipate") == 1, "Fire retains exactly its own outcome tail")
	await manager._recover_action()
	await get_tree().create_timer(0.65).timeout
	# A new ticket can begin in the same frame as the old cancellation.
	check(battle.set_compact_skins(true), "compact skin for overlapping body motion")
	var body_origin: Vector2 = actor.visual.position
	var old_results: Array[bool] = []
	var begin_old := func():
		old_results.append(await manager._present_action(actor,target.grid_pos,"slash",target))
	begin_old.call()
	await get_tree().create_timer(0.08).timeout
	var old_ticket := manager.action_lifecycle.ticket
	manager.action_lifecycle.cancel()
	check(await manager._present_action(actor,target.grid_pos,"slash",target), "new melee ticket survives old cancellation")
	check(old_results == [false] and manager.action_lifecycle.ticket > old_ticket, "stale melee callback cannot claim newer contact")
	await manager._recover_action()
	await get_tree().create_timer(0.70).timeout
	check(actor.visual.position.distance_to(body_origin) < 0.01, "overlapping old/new body motion restores true baseline, not partial old lunge")
	# KO may free the victim; its contact burst belongs to the action ticket.
	arm(manager,actor,target)
	target.hp = 1
	choose_roll(actor,target,manager,false)
	await manager._on_unit_clicked(target.unit_id)
	owner = controllers.back().get_ref()
	check(outcomes.size() == 1 and outcomes[0].get("defeated",false), "actual lethal input resolves one KO")
	check(role_count(owner,"melee_sheet_impact") == 1, "KO retains one safely owned impact")
	await dispose(battle)

func frame_contract() -> void:
	var script = load("res://scripts/presentation/MeleeFrames.gd")
	check(script != null, "authored melee playback script loads")
	if script == null: return
	var sprite = script.new()
	for effect in ["slash","impact"]:
		for direction in [Vector2(2,1),Vector2(-2,1),Vector2(-2,-1),Vector2(2,-1)]:
			sprite.configure(effect,direction)
			sprite.show()
			check(sprite.available(), "complete authored " + effect + " set loads")
			for texture in sprite._frames:
				check(texture.get_size() == Vector2(1024,1024), "shared padded canvas prevents frame-origin jumps")
			var previous := -1
			for step in 40:
				sprite.show_progress(float(step)/100.0)
				check(sprite.frame_index >= previous and sprite.frame_index < 4, "effect frames advance monotonically and stay in bounds")
				previous = sprite.frame_index
			check(not sprite.visible and sprite.frame_index == 3, "finite cosmetic tail retires after final frame")
			if effect == "impact": check(is_zero_approx(sprite.rotation), "recipient burst stays upright")
	sprite.free()
