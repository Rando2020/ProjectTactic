extends Node

const PRESENTER := "res://scripts/presentation/ZaneActionPresentation.gd"
const OWNER := &"zane_impact_v1"
var checks := 0
var failures: Array[String] = []
var outcomes: Array[Dictionary] = []
var cues: Array[String] = []
var phases: Array[String] = []
var controllers: Array[WeakRef] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _ready() -> void:
	call_deferred("run")

func observe(node: Node) -> void:
	if node.has_signal("phase_presented"):
		controllers.append(weakref(node))
		node.connect("phase_presented", func(phase: String): phases.append(phase))
		node.connect("cue_started", func(cue: String): cues.append(cue))

func make_battle() -> Node:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.selected_map_index = 0
	GameState.practice_session = {"rig3d":true, "reduced_zane_motion":false}
	var battle := preload("res://scenes/Battle.tscn").instantiate()
	get_tree().root.add_child(battle)
	var manager: BattleManager = battle.battle_manager
	for unit: Unit in manager.units.values():
		unit.unit_data = unit.unit_data.duplicate(true)
		unit.grid_pos = Vector2i.ZERO
		unit.hp = 2000
		unit.unit_data.base_stats.hp = 2000
		unit.unit_data.base_stats.physical_resistance = 0
		unit.unit_data.base_stats.magic_resistance = 0
		unit.temper = 0
		unit.ether = 0
		unit.statuses.clear()
	var caster: Unit = manager.units.zane
	caster.grid_pos = Vector2i(3,4)
	caster.mp = 100
	caster.ct = 69
	var index := 0
	for unit: Unit in manager.units.values():
		if unit.team == "enemy":
			unit.grid_pos = [Vector2i(5,4),Vector2i(5,5),Vector2i(5,3)][index]
			index += 1
	for pos in [Vector2i(3,4),Vector2i(5,4),Vector2i(5,5),Vector2i(5,3)]:
		manager.tactical_grid.tiles[pos]["height"] = 0
		manager.tactical_grid.tiles[pos]["terrain"] = "grass"
	manager.current_phase = BattleManager.Phase.PLAYER_TURN
	manager.active_unit_id = caster.unit_id
	manager.active_unit_has_acted = false
	manager.active_unit_has_moved = false
	manager.combat_resolver.combat_resolved.connect(func(result: Dictionary): outcomes.append(result.duplicate(true)))
	outcomes.clear()
	cues.clear()
	phases.clear()
	controllers.clear()
	return battle

func recipients(manager: BattleManager) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit: Unit in manager.units.values():
		if unit.team == "enemy": result.append(unit)
	return result

func dispose(battle: Variant) -> void:
	if is_instance_valid(battle):
		await battle.battle_manager._recover_action()
		battle.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.71).timeout
	check(not get_tree().paused, "cleanup never leaves existing hit pause stuck")
	for reference in controllers:
		check(not is_instance_valid(reference.get_ref()), "all action owners and voices retire within 0.70s plus a frame")

func run() -> void:
	if "--socket-frame-probe" in OS.get_cmdline_user_args():
		VFX.child_entered_tree.connect(observe)
		await fire_socket_frame_contract()
		print("Fire socket frame regression: %d checks, %d failures" % [checks,failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1)
		return
	if "--travel-observer-probe" in OS.get_cmdline_user_args():
		VFX.child_entered_tree.connect(observe)
		await travel_observer_frame_delta_contract()
		print("Travel observer regression: %d checks, %d failures" % [checks,failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1)
		return
	if "--outcome-layout-probe" in OS.get_cmdline_user_args():
		VFX.child_entered_tree.connect(observe)
		await outcome_label_cluster_contract()
		await outcome_label_mixed_contract()
		print("Outcome label layout probe: %d checks, %d failures" % [checks,failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1)
		return
	if "--review-fix-probe" in OS.get_cmdline_user_args():
		VFX.child_entered_tree.connect(observe)
		await bridge_cancel_contract()
		await postcontact_cancel_contract()
		await drawable_flash_contract()
		await caster_pose_handoff_contract()
		await get_tree().process_frame # Retire the final timeout emission before process shutdown.
		print("Task4 review fix probe: %d checks, %d failures" % [checks,failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1)
		return
	if "--exit-order-probe" in OS.get_cmdline_user_args():
		VFX.child_entered_tree.connect(observe)
		await exit_callback_order_contract()
		print("Exit ordering probe: %d checks, %d failures" % [checks,failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1)
		return
	if "--scoped-exit-child" in OS.get_cmdline_user_args():
		VFX.child_entered_tree.connect(observe)
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		manager._execute_ability(manager.units.zane,recipients(manager)[0],AbilityDB.get_ability("fire"))
		get_tree().create_timer(0.26).timeout.connect(battle.queue_free)
		await get_tree().create_timer(0.96).timeout
		await get_tree().process_frame
		var clean := not is_instance_valid(battle) and outcomes.is_empty() and not get_tree().paused
		for reference in controllers: clean = clean and not is_instance_valid(reference.get_ref())
		print("Scoped scene exit clean: ",clean)
		get_tree().quit(0 if clean else 1)
		return
	if "--reaction-owner-probe" in OS.get_cmdline_user_args():
		VFX.child_entered_tree.connect(observe)
		await reaction_owner_contract()
		print("Reaction owner probe: %d checks, %d failures" % [checks,failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1)
		return
	if "--selector-removal-probe" in OS.get_cmdline_user_args():
		await selector_removal_contract()
		print("Owner-empty selector removal: %d checks, %d failures" % [checks,failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1)
		return
	if "--fan-removal-probe" in OS.get_cmdline_user_args():
		VFX.child_entered_tree.connect(observe)
		await fan_recipient_removed()
		await selector_removal_contract()
		print("Fan removal probe: %d checks, %d failures" % [checks,failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1)
		return
	check(ResourceLoader.exists(PRESENTER), "one ticket-owned action presenter exists")
	if failures.is_empty():
		VFX.child_entered_tree.connect(observe)
		await outcome_label_cluster_contract()
		await outcome_label_mixed_contract()
		await fire_socket_frame_contract()
		await fire_fixtures()
		await sword_fixtures()
		await primary_counter_input()
		await travel_observer_frame_delta_contract()
		await interruptions()
		await bridge_cancel_contract()
		await postcontact_cancel_contract()
		await drawable_flash_contract()
		await caster_pose_handoff_contract()
		check_scene_exit_resources()
		await exit_callback_order_contract()
		await stale_ticket_overlap()
		await fan_recipient_removed()
		await selector_removal_contract()
		await cosmetic_rng()
		await actor_dies_after_resolution()
		await reduced_motion_contract()
		await legacy_parity()
		await armor_record_contract()
		await reaction_owner_contract()
		VFX.child_entered_tree.disconnect(observe)
	await get_tree().process_frame # Do not confuse last-timeout teardown with persistent resource retention.
	print("Zane impact actions: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func fire_fixtures() -> void:
	for id in ["fire", "fireball"]:
		var fire := AbilityDB.get_ability(id)
		check(fire.id == "fire" and fire.mp_cost == 12 and fire.range == 3 and fire.base_power == 100 and fire.aoe_type == "fan" and fire.fan_width == 1 and fire.status_effect.duration == 2 and is_equal_approx(fire.status_effect.magnitude, 0.07), "canonical Fire literals and alias stay frozen")
	for fixture: String in ["three hits", "mixed", "all miss", "all immune", "empty", "neutral zero", "armor", "overkill"]:
		print("Fire fixture: " + fixture)
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var caster: Unit = manager.units.zane
		check(caster.has_zane_impact_presentation(), "real final variant admits scoped action")
		var targets := recipients(manager)
		for target in targets:
			target.unit_data.elemental_affinities.fire = 1.0
			if fixture == "all immune": target.unit_data.elemental_affinities.fire = 0.0
			if fixture == "empty": target.grid_pos = Vector2i.ZERO
			if fixture == "neutral zero": target.unit_data.base_stats.magic_resistance = 999
			if fixture == "armor": target.ether = 90
			if fixture == "overkill": target.hp = 1
		if fixture == "all miss":
			var blind := StatusEffect.new()
			blind.status_id = "blind"
			caster.apply_status(blind)
			for candidate in range(10000):
				seed(candidate)
				if randi_range(1,100) > 65 and randi_range(1,100) > 65 and randi_range(1,100) > 65:
					seed(candidate)
					break
		if fixture == "mixed":
			var blind := StatusEffect.new()
			blind.status_id = "blind"
			blind.duration = 3
			caster.apply_status(blind)
			targets[2].unit_data.elemental_affinities.fire = 0.0
			# New cosmetic code consumes no global rolls: actual resolver order is stable.
			for candidate in range(10000):
				seed(candidate)
				var rolls := [randi_range(1,100), randi_range(1,100), randi_range(1,100)]
				if rolls[0] <= 65 and rolls[1] > 65 and rolls[2] <= 65:
					seed(candidate)
					break
		var accepted := await manager._execute_aoe_ability(caster, Vector2i(5,4), AbilityDB.get_ability("fire"))
		check(accepted and caster.mp == 88 and caster.ct == 69, fixture + ": one accepted spend, unchanged CT")
		check(not manager.active_unit_has_acted and not caster.has_acted, fixture + ": helper does not steal caller action-flag authority")
		check(outcomes.size() == (0 if fixture == "empty" else 3), fixture + ": one real result per recipient")
		check(cues.count("fire_charge") == 1 and cues.count("fire_release") == 1 and phases.count("release") == 1, fixture + ": one charge/release, not per target")
		var damaging := fixture in ["three hits", "mixed", "armor", "overkill"]
		check(cues.count("fire_hit") == (1 if damaging else 0) and phases.count("pause") == (1 if damaging else 0), fixture + ": one actual-impact tail and one existing pause maximum")
		check(cues.count("fire_hit") + cues.count("fire_immune") + cues.count("fire_miss") == 1, fixture + ": exactly one aggregate outcome tail")
		for i in outcomes.size():
			var result := outcomes[i]
			check(result.get("feedback_owner") == OWNER, fixture + ": tagged resolver signal retained")
			check(result.get("defeated", false) == (fixture == "overkill"), fixture + ": lethal copied directly from receive_damage")
			if fixture == "overkill": check(result.applied_hp_damage == 1 and targets[i].is_defeated, "overkill displays actual HP loss and keeps logical death")
			if fixture in ["all immune", "neutral zero", "all miss"]: check(targets[i].hp == 2000, fixture + ": no inferred damage")
			if fixture == "all miss": check(result.get("missed",false) and not targets[i].has_status("burn"), "all misses dissipate without hurt/status invention")
			if fixture == "armor": check(result.ether_damage > 0 and targets[i].ether < 90, "actual armor loss retained")
			if fixture != "empty":
				check(manager.tactical_grid.get_tile(targets[i].grid_pos).terrain == "burning", fixture + ": existing terrain authority retained even on miss/immune")
			if not result.get("missed", false) and fixture != "overkill":
				check(targets[i].has_status("burn"), fixture + ": existing hit-secondary burn retained")
		if fixture == "mixed":
			check(not outcomes[0].get("missed",false) and outcomes[1].get("missed",false) and outcomes[2].affinity == 0, "mixed fixture uses real hit/miss/immune rolls")
			check(not targets[1].has_status("burn"), "miss retains secondary-status gate")
			check(phases.count("hurt:" + targets[1].unit_id) == 0 and phases.count("hurt:" + targets[2].unit_id) == 0, "mixed miss/immune never receive hurt pose/wobble")
		if not damaging: check(phases.count("kick") == 0, fixture + ": no camera kick for no loss")
		await dispose(battle)

func sword_fixtures() -> void:
	for fixture: String in ["hit", "miss", "critical", "counter"]:
		print("Sword fixture: " + fixture)
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var caster: Unit = manager.units.zane
		var target: Unit = recipients(manager)[0]
		target.grid_pos = caster.grid_pos + Vector2i.RIGHT
		target.facing = "W"
		var blind := StatusEffect.new()
		blind.status_id = "blind"
		caster.apply_status(blind)
		var formula := CombatFormula.calculate_physical_attack(caster,target,{"height":0},{"height":0})
		for candidate in range(100000):
			seed(candidate)
			var hit := randi_range(1,100) <= int(formula.hit_pct)
			var critical := randi_range(1,100) <= int(formula.crit_pct)
			var counter := randf() < 0.25
			if (fixture == "miss" and not hit) or (hit and ((fixture == "hit" and not critical) or (fixture == "critical" and critical) or (fixture == "counter" and counter))):
				seed(candidate)
				break
		check(await manager._present_action(caster,target.grid_pos,"slash",target), "real lifecycle admits sword")
		var result: Dictionary = manager.combat_resolver.call("resolve_attack",caster,target,{"height":0},{"height":0},"slash",false,{},OWNER)
		var records: Array[Dictionary] = [manager.call("_presentation_record", target, result)]
		manager.call("_present_action_outcomes", records)
		check(cues.count("sword_load") == 1 and cues.count("sword_release") == 1, fixture + ": sword tension and air cut exactly once")
		check(cues.count("sword_hit") == (0 if fixture == "miss" else 1), fixture + ": miss gets no contact thunk")
		check(phases.count("pause") == (0 if fixture == "miss" else 1), fixture + ": sword one 80ms pause only on actual loss")
		if fixture == "critical": check(result.critical and phases.count("critical") == 1, "actual crit controls critical accent")
		if fixture == "counter": check(result.counter, "original counter roll remains authoritative")
		await dispose(battle)

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
				check(is_instance_valid(owner) and is_instance_valid(owner._trail) and owner._trail.width_curve != null and owner._trail.gradient != null, "Fire travels with one directionally tapered ember trail")
				check(is_instance_valid(owner) and is_instance_valid(owner._projectile) and owner._projectile.material is ShaderMaterial, "one projectile carries a local hot-core treatment, not a screen flash")
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

func cosmetic_rng() -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var caster: Unit = manager.units.zane
	seed(17121)
	var expected := randi()
	seed(17121)
	check(await manager.call("_present_action",caster,Vector2i(5,4),"cast",null,"fire"), "cosmetic lead-in uses real ticket")
	check(randi() == expected, "new charge/projectile/audio/camera cosmetics leave global RNG unchanged")
	await dispose(battle)

func legacy_parity() -> void:
	# Compare one actual resolver result with the same seed. Legacy effects consume
	# cosmetic RNG after spell resolution, so compare direct mechanics, not later rolls.
	var snapshots: Array[Dictionary] = []
	for scoped in [false,true]:
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var caster: Unit = manager.units.zane
		var target: Unit = recipients(manager)[0]
		target.unit_data.elemental_affinities.fire = 0.5
		target.ether = 90
		seed(5123)
		var result: Dictionary = manager.combat_resolver.call("resolve_spell",caster,target,"fire",100,OWNER if scoped else &"")
		result.erase("feedback_owner")
		result.erase("defeated")
		snapshots.append({"result":result,"hp":target.hp,"ether":target.ether,"mp":caster.mp,"ct":caster.ct})
		await dispose(battle)
	check(snapshots[0] == snapshots[1], "scoped policy preserves identical real spell mechanics under controlled combat roll")
	for fixture in ["other actor", "other skill"]:
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var actor: Unit = manager.units.kael if fixture == "other actor" else manager.units.zane
		var target: Unit = recipients(manager)[0]
		var ability_id := "" if fixture == "other actor" else "thunderstrike"
		check(await manager.call("_present_action",actor,target.grid_pos,"slash" if ability_id.is_empty() else "cast",target,ability_id), "legacy action remains admitted")
		check(controllers.is_empty() and cues.is_empty(), fixture + ": not routed through new controller/audio")
		var result: Dictionary = manager.combat_resolver.call("resolve_spell",actor,target,"thunder",100)
		check(not result.has("feedback_owner"), fixture + ": original feedback/results retained")
		await dispose(battle)

func armor_record_contract() -> void:
	# Current armor formula always leaks at least1HP for positive incoming damage.
	# This defensive record-boundary case tests presentation honesty, not a fake resolver.
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var caster: Unit = manager.units.zane
	var target: Unit = recipients(manager)[0]
	check(await manager._present_action(caster,target.grid_pos,"slash",target), "armor record uses real lifecycle")
	var hp_before := target.hp
	var records: Array[Dictionary] = [manager.call("_presentation_record",target,{"applied_hp_damage":0,"temper_damage":4,"feedback_owner":OWNER,"defeated":false})]
	manager.call("_present_action_outcomes",records)
	check(target.hp == hp_before and target.temper == 0, "armor feedback record never applies/invents gameplay loss")
	check(phases.count("armor") == 1 and cues.count("sword_hit") == 1 and phases.count("pause") == 1, "armor-only contact is distinct and still one real-contact accent")
	await dispose(battle)

func actor_dies_after_resolution() -> void:
	print("Interruption fixture: actor dies from real result callback")
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var caster: Unit = manager.units.zane
	for target in recipients(manager): target.unit_data.elemental_affinities.fire = 1.0
	manager.combat_resolver.combat_resolved.connect(func(_result: Dictionary):
		if caster.hp > 0: caster.receive_damage(99999,"magical")
	)
	check(await manager._execute_aoe_ability(caster,Vector2i(5,4),AbilityDB.get_ability("fire")), "accepted real contact is not undone by a subsequent actor death")
	check(caster.mp == 88 and outcomes.size() == 1 and caster.is_defeated, "actor death preserves one actual resolution/spend and original remaining-recipient validation")
	check(not cues.has("fire_hit") and phases.count("pause") == 0 and phases.count("kick") == 0, "actor death during result callback prevents late new impact cue/pause/kick")
	await dispose(battle)

func primary_counter_input() -> void:
	print("Sword fixture: real primary input, repeated click, legacy counter")
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var target: Unit = recipients(manager)[0]
	target.grid_pos = actor.grid_pos + Vector2i.RIGHT
	target.set_facing("W")
	actor.set_facing("E")
	manager.tactical_grid.tiles[target.grid_pos]["height"] = 0
	manager.select_command("attack")
	manager.tactical_grid.attack_tiles.assign([target.grid_pos])
	var attack_formula := CombatFormula.calculate_physical_attack(actor,target,{"height":0},{"height":0})
	var counter_formula := CombatFormula.calculate_physical_attack(target,actor,{"height":0},{"height":0})
	for candidate in range(100000):
		seed(candidate)
		var hit := randi_range(1,100)
		randi_range(1,100) # real critical roll
		var counter := randf()
		var counter_hit := randi_range(1,100)
		if hit <= int(attack_formula.hit_pct) and counter < 0.25 and counter_hit <= int(counter_formula.hit_pct):
			seed(candidate)
			break
	get_tree().create_timer(0.08).timeout.connect(func(): manager._on_unit_clicked(target.unit_id))
	await manager._on_unit_clicked(target.unit_id)
	check(outcomes.size() == 2 and outcomes[0].get("feedback_owner") == OWNER and not outcomes[1].has("feedback_owner"), "one scoped primary plus one unchanged legacy counter result")
	check(outcomes[0].counter and not outcomes[1].counter and actor.hp < 2000 and target.hp < 2000, "actual counter executes once and cannot recursively counter")
	check(cues.count("sword_load") == 1 and cues.count("sword_release") == 1 and cues.count("sword_hit") == 1 and phases.count("pause") == 1, "real repeated input never duplicates scoped action feedback")
	check(manager.active_unit_has_acted and not manager.active_unit_has_moved and actor.ct == 69 and actor.mp == 100 and manager.active_unit_id == actor.unit_id, "primary caller retains normal action/CT/MP/turn ownership")
	await dispose(battle)

func reduced_motion_contract() -> void:
	var snapshots: Array[Dictionary] = []
	for reduced in [false,true]:
		print("Fire fixture: reduced motion " + str(reduced))
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var caster: Unit = manager.units.zane
		GameState.practice_session.reduced_zane_motion = reduced
		for target in recipients(manager): target.unit_data.elemental_affinities.fire = 1.0
		await get_tree().process_frame # Measure the same warm frame, not synchronous fixture import.
		seed(6671)
		for i in 3: randi_range(1,100) # Only the three actual magical hit rolls.
		var expected_next := randi()
		seed(6671)
		var start := Time.get_ticks_msec()
		check(await manager._execute_aoe_ability(caster,Vector2i(5,4),AbilityDB.get_ability("fire")), "both motion policies resolve real Fire")
		var elapsed := Time.get_ticks_msec()-start
		print("Motion prepare/travel wall ms: ",elapsed)
		check(elapsed >= 400 and elapsed <= 750, "reduced motion preserves prepare/travel timing, not a skipped lead-in")
		var owner = controllers.back().get_ref()
		check(is_instance_valid(owner) and owner.context.reduced_motion == reduced and owner._reactions.is_empty() == reduced, "only new target wobble/flash ownership follows motion policy")
		check((battle._zane_kick_remaining == 0) == reduced and phases.count("kick") == (0 if reduced else 1), "only new deterministic kick follows motion policy")
		check(cues.count("fire_hit") == 1 and phases.count("pause") == 1, "motion reduction preserves sound and one real pause")
		check(owner.find_children("*","Polygon2D",true,false).size() <= 9, "bounded projectile/ember polygon budget")
		await get_tree().create_timer(0.14,true,false,true).timeout
		check(randi() == expected_next, "new outcome numbers/embers/reactions/kick leave global combat RNG unchanged")
		snapshots.append({"outcomes":outcomes.duplicate(true),"mp":caster.mp,"ct":caster.ct})
		await dispose(battle)
	check(snapshots[0] == snapshots[1], "reduced motion never changes real results/resources/CT")

func stale_ticket_overlap() -> void:
	print("Interruption fixture: old cancellation overlaps a new ticket")
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var old_results: Array[bool] = []
	var old_action := func() -> void:
		var accepted: bool = await manager.call("_present_action",actor,Vector2i(5,4),"cast",null,"fire")
		old_results.append(accepted)
	old_action.call()
	await get_tree().create_timer(0.08).timeout
	var old_ticket: int = manager.action_lifecycle.ticket
	manager.action_lifecycle.cancel()
	check(await manager.call("_present_action",actor,Vector2i(5,4),"cast",null,"fire"), "new ticket survives the old coroutine's late return")
	check(old_results == [false] and manager.action_lifecycle.ticket > old_ticket and manager.action_lifecycle.phase == "contact", "old callback cannot grant contact or finish the newer lifecycle")
	check(manager._action_presentation_context.ticket == manager.action_lifecycle.ticket and VFX._action_presenters.size() == 1, "only newer keyed owner remains registered")
	check(cues.count("fire_charge") == 2 and cues.count("fire_release") == 1 and not cues.has("fire_hit"), "cancelled charge cannot release or attach a late impact to a newer action")
	await dispose(battle)

func fan_recipient_removed() -> void:
	print("Interruption fixture: one fan recipient disappears during travel")
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var removed: Unit = recipients(manager)[0]
	var removed_id := removed.unit_id
	var removed_pos := removed.grid_pos
	for target in recipients(manager): target.unit_data.elemental_affinities.fire = 1.0
	get_tree().create_timer(0.26).timeout.connect(removed.queue_free)
	check(await manager._execute_aoe_ability(actor,Vector2i(5,4),AbilityDB.get_ability("fire")), "fan preserves accepted tile targeting despite recipient removal")
	print("Fan removal actual: MP=",actor.mp," results=",outcomes.size()," master-hit=",cues.count("fire_hit"))
	check(actor.mp == 88 and outcomes.size() == 2 and phases.count("hurt:"+removed_id) == 0, "remaining real recipients resolve once with no removed-target recoil")
	check(manager.tactical_grid.get_tile(removed_pos).terrain == "grass", "fan cosmetics never invent removed-recipient terrain effects")
	check(cues.count("fire_hit") == 1 and phases.count("pause") == 1, "changed recipient set still has one master impact/pause")
	await dispose(battle)

func selector_removal_contract() -> void:
	# Owner-empty path uses the unchanged released selection helper. This proves
	# the stale-key correctness repair is not manufactured by new presentation.
	for fixture in ["first","middle","all"]:
		print("Owner-empty freed recipient fixture: ",fixture)
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var actor: Unit = manager.units.zane
		actor.disable_3d_prototype()
		var targets := recipients(manager)
		var expected: Array[String] = []
		var resolved: Array[String] = []
		for i in targets.size():
			var target: Unit = targets[i]
			var id := target.unit_id
			if fixture == "all" or i == (0 if fixture == "first" else 1):
				target.free()
			else:
				expected.append(id)
				target.unit_data.elemental_affinities.fire = 1.0
				target.hp_changed.connect(func(_id: String,_hp: int,_max_hp: int): resolved.append(id))
		check(await manager._execute_aoe_ability(actor,Vector2i(5,4),AbilityDB.get_ability("fire")), "owner-empty removed-recipient action remains accepted")
		check(outcomes.size() == expected.size() and resolved == expected, fixture + ": each remaining valid recipient resolves exactly once in original insertion order")
		check(actor.mp == 88 and actor.ct == 69 and not manager.active_unit_has_acted and not manager.active_unit_has_moved, fixture + ": removal repair preserves helper resource/CT/action-flag authority")
		for result in outcomes: check(not result.has("feedback_owner"), "owner-empty removal fixture retains legacy resolver policy")
		for id in expected:
			var target: Unit = manager.units[id]
			check(target.has_status("burn") and manager.tactical_grid.get_tile(target.grid_pos).terrain == "burning", fixture + ": unchanged actual-recipient status and terrain policy")
		await dispose(battle)

func reaction_owner_contract() -> void:
	print("Interruption fixture: old reaction cleanup cannot overwrite a new owner")
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var target: Unit = recipients(manager)[0]
	target.grid_pos = actor.grid_pos + Vector2i.RIGHT
	target.set_facing("W")
	actor.set_facing("E")
	for candidate in range(10000):
		seed(candidate)
		var first := randi_range(1,100)
		randi_range(1,100)
		var second := randi_range(1,100)
		if first <= 88 and second <= 88:
			seed(candidate)
			break
	check(await manager._present_action(actor,target.grid_pos,"slash",target), "first reaction ticket admitted")
	var first: Dictionary = manager.combat_resolver.call("resolve_attack",actor,target,{"height":0},{"height":0},"slash",true,{},OWNER)
	var records: Array[Dictionary] = [manager.call("_presentation_record",target,first)]
	manager.call("_present_action_outcomes",records)
	var old_owner = controllers.back().get_ref()
	await manager._recover_action()
	check(await manager._present_action(actor,target.grid_pos,"slash",target), "second reaction ticket admitted while first tail remains")
	var second: Dictionary = manager.combat_resolver.call("resolve_attack",actor,target,{"height":0},{"height":0},"slash",true,{},OWNER)
	records = [manager.call("_presentation_record",target,second)]
	manager.call("_present_action_outcomes",records)
	var visual: Node2D = target.visual
	var neutral_scale: Vector2 = old_owner._reactions[0].scale
	var neutral_color: Color = old_owner._reactions[0].color
	var deadline := Time.get_ticks_msec()+180
	while visual.scale.is_equal_approx(neutral_scale) and visual.self_modulate.is_equal_approx(neutral_color) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(not visual.scale.is_equal_approx(neutral_scale) or not visual.self_modulate.is_equal_approx(neutral_color), "newer reaction is visibly active before stale cleanup probe")
	var scale_before: Vector2 = visual.scale
	var color_before: Color = visual.self_modulate
	check(is_instance_valid(old_owner), "old completed tail is still observable during newer reaction")
	if is_instance_valid(old_owner): old_owner.cancel()
	check(visual.scale.is_equal_approx(scale_before) and visual.self_modulate.is_equal_approx(color_before), "stale reaction cleanup cannot reset a newer action's visual ownership")
	await dispose(battle)

func check_scene_exit_resources() -> void:
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(),PackedStringArray(["--headless","--verbose","--path",ProjectSettings.globalize_path("res://"),"res://tests/test_zane_impact_actions.tscn","--","--scoped-exit-child"]),output,true)
	var captured := "\n".join(output)
	check(code == 0 and captured.contains("Scoped scene exit clean: true"), "scene exit retires owned nodes/voices within0.70s plus a frame")
	check(not captured.contains("SCRIPT ERROR:"), "scene exit produces zero late script errors")
	check(not captured.contains("ObjectDB instances leaked") and not captured.contains("resources still in use"), "scoped scene exit retires pending coroutine/lifecycle resources, not only visible nodes")
	if captured.contains("resources still in use"): printerr(captured.substr(captured.find("WARNING: ObjectDB"),2000))

func exit_callback_order_contract() -> void:
	print("Interruption fixture: synchronous exit wake while actor/manager remain valid")
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var target: Unit = recipients(manager)[0]
	var returned: Array[bool] = []
	var start := func() -> void:
		var accepted: bool = await manager._execute_ability(actor,target,AbilityDB.get_ability("fire"))
		returned.append(accepted)
	start.call()
	await get_tree().create_timer(0.26).timeout
	var ticket: int = manager.action_lifecycle.ticket
	check(manager.action_lifecycle.phase == "anticipation" and actor.is_inside_tree() and target.is_inside_tree() and actor.hp > 0 and target.hp > 0, "exit-order fixture starts during travel with otherwise contact-eligible live nodes")
	# Invoke the actual exit callback before freeing nodes: maximum-danger ordering.
	manager._exit_tree()
	check(is_instance_valid(manager) and manager.is_inside_tree() and actor.is_inside_tree(), "actor/manager remain temporarily valid during synchronous cancellation wake")
	check(returned == [false] and manager.action_lifecycle.ticket > ticket and manager.action_lifecycle.phase == "idle" and not manager.action_lifecycle.contact(ticket), "lifecycle invalidation precedes synchronous wake and old contact is impossible")
	check(actor.mp == 100 and target.hp == 2000 and outcomes.is_empty() and not manager.is_resolving_action, "synchronous exit wake cannot spend MP, apply damage or emit a late result")
	await get_tree().create_timer(0.30).timeout
	check(actor.mp == 100 and target.hp == 2000 and outcomes.is_empty() and not cues.has("fire_hit"), "normal post-exit frames cannot resurrect contact or late feedback")
	await dispose(battle)

func bridge_cancel_contract() -> void:
	for fixture in ["fire prepare","fire travel","sword"]:
		print("Review cancellation fixture: ",fixture)
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var actor: Unit = manager.units.zane
		var target: Unit = recipients(manager)[0]
		target.unit_data.elemental_affinities.fire = 1.0
		var returned: Array[bool] = []
		var launch := func() -> void:
			if fixture == "sword":
				var accepted: bool = await manager._present_action(actor,target.grid_pos,"slash",target)
				if accepted:
					var result: Dictionary = manager.combat_resolver.call("resolve_attack",actor,target,{"height":0},{"height":0},"slash",true,{},OWNER)
					var records: Array[Dictionary] = [manager.call("_presentation_record",target,result)]
					manager.call("_present_action_outcomes",records)
				returned.append(accepted)
			else:
				returned.append(await manager._execute_ability(actor,target,AbilityDB.get_ability("fire")))
		await get_tree().process_frame
		launch.call()
		var cancel_at := Time.get_ticks_msec() + (260 if fixture == "fire travel" else 80)
		while Time.get_ticks_msec() < cancel_at: await get_tree().process_frame
		var old_key := str(manager._action_presentation_context.action_key)
		VFX.cancel_action(old_key)
		check(returned == [false] and manager.action_lifecycle.phase == "idle" and not manager.is_resolving_action, fixture + ": direct bridge cancellation refuses rather than grants contact")
		check(actor.mp == 100 and target.hp == 2000 and outcomes.is_empty(), fixture + ": direct cancel cannot spend resources, roll damage or emit outcomes")
		check(actor._rig3d.state == "idle" and actor.melee_pose == "idle", fixture + ": alive caster leaves its preparation/cast pose after refusal")
		check(not cues.has("fire_hit") and not cues.has("sword_hit") and phases.count("pause") == 0, fixture + ": no cancelled impact tail/pause")
		if fixture != "fire travel": check(not cues.has("fire_release") and not cues.has("sword_release"), fixture + ": no late release after pre-release cancellation")
		check(VFX.has_method("action_lead_in_completed") and not bool(VFX.call("action_lead_in_completed",old_key)), "cancelled key has no completed lead-in permit")
		check(await manager._execute_ability(actor,target,AbilityDB.get_ability("fire")), "following action remains usable after direct bridge cancellation")
		var new_key := str(manager._action_presentation_context.action_key)
		VFX.cancel_action(old_key)
		check(new_key != old_key and VFX.has_method("action_lead_in_completed") and bool(VFX.call("action_lead_in_completed",new_key)) and manager.action_lifecycle.phase == "contact", "stale old bridge key cannot invalidate newer completed lead-in")
		check(actor.mp == 88 and target.hp < 2000 and outcomes.size() == 1, "only the following valid action spends/resolves once")
		await dispose(battle)

func postcontact_cancel_contract() -> void:
	print("Review cancellation fixture: post-contact visual cancellation preserves turn finish")
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var target: Unit = recipients(manager)[0]
	for recipient in recipients(manager): recipient.unit_data.elemental_affinities.fire = 1.0
	manager.set_process(false)
	# Give the real scheduler a ready next PLAYER; do not tear down a newly
	# started legacy enemy-turn coroutine while testing presentation recovery.
	for unit: Unit in manager.units.values(): unit.ct = 0
	actor.ct = 69
	manager.units.lyra.ct = 100
	manager.active_command = "ability_target"
	manager.selected_ability_id = "fire"
	manager.tactical_grid.ability_tiles.assign([target.grid_pos])
	manager.active_unit_has_moved = true
	var cancelled: Array[String] = []
	var ended: Array[String] = []
	var turn_phases: Array[String] = []
	manager.phase_changed.connect(func(phase: String): turn_phases.append(phase))
	manager.turn_ended.connect(func(id: String): ended.append(id))
	manager.combat_resolver.combat_resolved.connect(func(_result: Dictionary):
		if cancelled.is_empty():
			var key := str(manager._action_presentation_context.action_key)
			cancelled.append(key)
			VFX.cancel_action(key)
	)
	await manager._on_unit_clicked(target.unit_id)
	check(outcomes.size() == 3 and actor.mp == 88 and cancelled.size() == 1, "post-contact visual cancel never refunds or duplicates actual fan results/spend")
	check(ended == [actor.unit_id] and turn_phases.count("RESOLVE") == 1 and turn_phases.count("TICK") == 1 and manager.active_unit_id == "lyra" and manager.current_phase == BattleManager.Phase.PLAYER_TURN and manager.action_lifecycle.phase == "idle" and not manager.is_resolving_action, "post-contact cancel preserves normal recovery and turn advance")
	check(actor._rig3d.state == "idle" and actor.melee_pose == "idle", "post-contact visual cancel preserves caster recovery back to grounded idle")
	for result in outcomes: check(result.get("feedback_owner") == OWNER, "accepted action keeps its scoped outcome policy after visual cancellation")
	await dispose(battle)

func drawable_flash_contract() -> void:
	for reduced in [false,true]:
		print("Review 3D drawable flash fixture: reduced=",reduced)
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var actor: Unit = manager.units.zane
		var target: Unit
		for candidate in recipients(manager):
			if candidate.get_meta("archetype_id","") == "void_cultist": target = candidate
		check(is_instance_valid(target) and is_instance_valid(target._rig3d), "actual supported void cultist is a 3D recipient")
		if not is_instance_valid(target) or not is_instance_valid(target._rig3d):
			await dispose(battle)
			continue
		GameState.practice_session.reduced_zane_motion = reduced
		target.unit_data.elemental_affinities.fire = 1.0
		var output: Sprite2D = target._rig3d.get("output") as Sprite2D
		var original: Color = output.self_modulate
		var wrapper_color: Color = target._rig3d.self_modulate
		check(await manager._execute_ability(actor,target,AbilityDB.get_ability("fire")), "real Fire resolves against visible 3D output")
		var deadline := Time.get_ticks_msec()+180
		while output.self_modulate.is_equal_approx(original) and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		check(output.self_modulate.is_equal_approx(original) == reduced, "flash actually tints drawable Sprite2D output only in standard motion")
		check(target._rig3d.self_modulate.is_equal_approx(wrapper_color), "undrawn wrapper does not masquerade as visible flash evidence")
		var hp := target.hp
		VFX.cancel_action(str(manager._action_presentation_context.action_key))
		check(output.self_modulate.is_equal_approx(original) and target.hp == hp and actor.mp == 88, "keyed drawable restoration never refunds gameplay outcomes")
		await dispose(battle)

func caster_pose_handoff_contract() -> void:
	print("Review caster pose fixture: move begins after recovery while old tail retires")
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var target: Unit = recipients(manager)[0]
	target.unit_data.elemental_affinities.fire = 1.0
	check(await manager._execute_ability(actor,target,AbilityDB.get_ability("fire")), "real cast completes before a following move")
	var old_owner: WeakRef = controllers.back()
	await manager._recover_action()
	check(actor._rig3d.state == "idle" and manager.action_lifecycle.phase == "idle", "existing recovery callback returns caster to idle before movement")
	var grid: TacticalGrid = manager.tactical_grid
	var from := actor.grid_pos
	var to := from+Vector2i(3,0)
	for position in grid.unit_positions.keys():
		if grid.unit_positions[position] == actor.unit_id: grid.unit_positions.erase(position)
	grid.unit_positions[from] = actor.unit_id
	actor.position = grid._unit_foot_pos(from)
	actor.move_to(to)
	var completed: Array[bool] = []
	var move := func() -> void:
		await grid.move_unit_visual(actor.unit_id,from,to)
		completed.append(true)
	move.call()
	var deadline := Time.get_ticks_msec()+750
	while is_instance_valid(old_owner.get_ref()) and completed.is_empty() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(not is_instance_valid(old_owner.get_ref()) and completed.is_empty() and actor._rig3d.state == "walk" and actor._rig3d.walk_distance_px > 0, "old action retirement cannot reset a newer actual-distance walk pose")
	while completed.is_empty(): await get_tree().process_frame
	deadline = Time.get_ticks_msec()+250
	while actor._rig3d.state != "idle" and Time.get_ticks_msec() < deadline: await get_tree().process_frame
	check(actor._rig3d.state == "idle" and actor.grid_pos == to and actor.position.is_equal_approx(grid._unit_foot_pos(to)), "following movement completes and settles normally after old tail cleanup")
	check(actor.mp == 88 and actor.hp == 2000 and actor.ct == 69 and outcomes.size() == 1, "caster move/tail handoff never duplicates spell resources or damage")
	await dispose(battle)

# Native Task4 fire-action-03/04: adjacent fan recipients displayed these exact
# two resolver-derived strings at fixed offsets and their actual Label bounds collided.
func outcome_label_cluster_contract() -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	actor.grid_pos = Vector2i(4,5)
	var targets := recipients(manager)
	targets[0].grid_pos = Vector2i(6,5)
	targets[1].grid_pos = Vector2i(6,4)
	outcome_align_fixture_units(manager)
	await get_tree().process_frame
	check(await manager._present_action(actor,targets[0].grid_pos,"cast",null,"fire"), "native close-cluster label probe admits one real Fire ticket")
	var records: Array[Dictionary] = [
		manager._presentation_record(targets[0],{"applied_hp_damage":44,"ether_damage":17,"affinity":1.0}),
		manager._presentation_record(targets[1],{"applied_hp_damage":33,"ether_damage":13,"affinity":0.5}),
	]
	manager._present_action_outcomes(records)
	var owner = controllers.back().get_ref()
	var labels: Array[Label] = []
	for fx in owner._fx:
		if is_instance_valid(fx) and fx is Label and fx.get_meta("zane_effect_role","") == "outcome": labels.append(fx)
	check(labels.size() == 2, "close-cluster has exactly one outcome per actual recipient")
	if labels.size() == 2:
		check(labels[0].text == "-44 HP\n-17 Ether" and labels[1].text == "-33 HP\n-13 Ether [RESIST]", "native outcome strings remain truthful and complete")
		for i in labels.size():
			check(labels[i].get_theme_font_size("font_size") == 20, "cluster repair never shrinks the original outcome font")
			var bounds: Rect2 = labels[i].get_global_transform_with_canvas()*Rect2(Vector2.ZERO,labels[i].get_combined_minimum_size()).grow(4)
			for header: Rect2 in outcome_actual_unit_headers(targets[i]): check(not bounds.intersects(header), "native callout clears actual scaled recipient name/HP/status Controls")
		print("Real-ticket close-cluster screen rectangles: ",labels[0].get_global_transform_with_canvas()*Rect2(Vector2.ZERO,labels[0].get_combined_minimum_size())," / ",labels[1].get_global_transform_with_canvas()*Rect2(Vector2.ZERO,labels[1].get_combined_minimum_size()))
		for sample in range(5):
			var a: Rect2 = labels[0].get_global_transform_with_canvas() * Rect2(Vector2.ZERO,labels[0].get_combined_minimum_size()).grow(4)
			var b: Rect2 = labels[1].get_global_transform_with_canvas() * Rect2(Vector2.ZERO,labels[1].get_combined_minimum_size()).grow(4)
			check(not a.intersects(b), "native adjacent fan multiline outcomes do not overlap at float sample %d: %s vs %s" % [sample,a,b])
			for bounds: Rect2 in [a,b]:
				check(owner.get_viewport_rect().grow(-4).encloses(bounds), "native full label/outline remains inside viewport through float")
				for hud: Rect2 in outcome_expected_hud_rects(battle): check(not bounds.intersects(hud), "native full label/outline avoids actual visible HUD through float")
			await get_tree().create_timer(0.08).timeout
	owner.cancel()
	await dispose(battle)

func outcome_label_mixed_contract() -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var targets := recipients(manager)
	outcome_align_fixture_units(manager)
	# Expanded real comparison controls, not assumed hard-coded exclusion bounds.
	battle.comparison_panel.toggle.get_parent().show()
	await get_tree().process_frame
	await get_tree().process_frame
	check(await manager._present_action(actor,Vector2i(5,4),"cast",null,"fire"), "three-label mixed probe admits real Fire ticket")
	var records: Array[Dictionary] = [
		manager._presentation_record(targets[0],{"applied_hp_damage":999,"temper_damage":123,"ether_damage":456,"critical":true,"affinity":1.5}),
		manager._presentation_record(targets[1],{"missed":true,"applied_hp_damage":0,"affinity":1.0}),
		manager._presentation_record(targets[2],{"applied_hp_damage":0,"affinity":0.0}),
	]
	var hp_before := [targets[0].hp,targets[1].hp,targets[2].hp]
	manager._present_action_outcomes(records)
	var owner = controllers.back().get_ref()
	var labels: Array[Label] = []
	var links: Array[Line2D] = []
	for fx in owner._fx:
		if not is_instance_valid(fx): continue
		if fx is Label and fx.get_meta("zane_effect_role","") == "outcome": labels.append(fx)
		if fx is Line2D and fx.get_meta("zane_effect_role","") == "outcome_link": links.append(fx)
	check(labels.size() == 3, "three actual recipients retain exactly three callouts")
	check(links.size() > 0 and links.size() <= 3, "only displaced callouts get small ticket-owned association links")
	if labels.size() == 3:
		check(labels[0].text == "-999 HP\n-123 Temper\n-456 Ether\nCRIT [WEAK]" and labels[1].text == "MISS" and labels[2].text == "IMMUNE", "mixed long/miss/immune labels preserve every actual record field without inference")
		var previous_positions: Array[Vector2] = []
		for link in links: previous_positions.append(link.points[0])
		for sample in range(5):
			for i in labels.size():
				var bounds: Rect2 = labels[i].get_global_transform_with_canvas()*Rect2(Vector2.ZERO,labels[i].get_combined_minimum_size()).grow(4)
				check(labels[i].get_theme_font_size("font_size") == 20, "long mixed labels never shrink fonts")
				for header: Rect2 in outcome_actual_unit_headers(targets[i]): check(not bounds.intersects(header), "mixed callouts clear actual scaled recipient name/HP/status Controls")
				check(owner.get_viewport_rect().grow(-4).encloses(bounds), "three mixed labels remain inside viewport through float")
				for hud: Rect2 in outcome_expected_hud_rects(battle): check(not bounds.intersects(hud), "three mixed labels avoid actual expanded HUD through float")
				for j in range(i):
					var other: Rect2 = labels[j].get_global_transform_with_canvas()*Rect2(Vector2.ZERO,labels[j].get_combined_minimum_size()).grow(4)
					check(not bounds.intersects(other), "three mixed multiline labels stay separated through float")
			await get_tree().create_timer(0.08).timeout
		for i in links.size():
			check(links[i].points[0].y < previous_positions[i].y, "leader start follows the existing upward label float")
			var associated := false
			for j in labels.size():
				var label_bounds := Rect2(labels[j].position,labels[j].get_combined_minimum_size()).grow(4.01)
				var endpoint: Vector2 = owner.get_global_transform_with_canvas()*links[i].points[1]
				var hp: Rect2 = targets[j]._hp_bar.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,targets[j]._hp_bar.size)
				var top := INF
				for header: Rect2 in outcome_actual_unit_headers(targets[j]): top = minf(top,header.position.y)
				if label_bounds.has_point(links[i].points[0]) and absf(endpoint.x-hp.get_center().x) < 0.1 and endpoint.y <= top and endpoint.y >= top-50: associated = true
			check(associated, "leader endpoint remains attached to the same actual recipient as its callout")
	check([targets[0].hp,targets[1].hp,targets[2].hp] == hp_before and actor.mp == 100, "label layout never changes target HP or spends resources")
	owner.cancel()
	for fx in labels+links: check(not fx.visible, "keyed owner cancellation immediately hides callouts and association links")
	await dispose(battle)

# Expected exclusions come from independently selected fixture controls, not the
# production exclusion helper (which could otherwise silently return an empty list).
func outcome_expected_hud_rects(battle: Node) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for control: Control in [battle.battle_ui._right_panel_bg,battle.battle_ui._loadout_panel,battle.comparison_panel.get_child(0)]:
		if control.is_visible_in_tree() and control.modulate.a > 0.01:
			result.append(control.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,control.size))
	for unit: Unit in battle.battle_manager.units.values(): result.append_array(outcome_actual_unit_headers(unit))
	return result

# Physically align the real scene with edited fixture grid positions. Unit.scale
# is deliberately left at the production 1.35, not normalized away by the test.
func outcome_align_fixture_units(manager: BattleManager) -> void:
	for unit: Unit in manager.units.values():
		unit.position = manager.tactical_grid._unit_foot_pos(unit.grid_pos)
		if unit.team == "enemy":
			var burn := StatusEffect.new()
			burn.status_id = "burn"
			burn.duration = 2
			unit.apply_status(burn)

# Actual Control transforms/sizes, independently of the presenter's anchor math.
func outcome_actual_unit_headers(unit: Unit) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for control: Control in unit.find_children("*","Control",true,false):
		if control.z_index >= 13 and control.is_visible_in_tree():
			var rect := Rect2(Vector2.ZERO,control.size)
			if control is Label: rect = rect.grow(control.get_theme_constant("outline_size"))
			result.append(control.get_global_transform_with_canvas()*rect)
	return result

func schedule_action_interruption(fixture: String, interrupt: Callable) -> void:
	if fixture == "during travel":
		interrupt_after_observed_fire_release(interrupt)
	else:
		get_tree().create_timer(0.08 if fixture == "before release" else 0.26).timeout.connect(interrupt)

func interrupt_after_observed_fire_release(interrupt: Callable) -> void:
	var deadline := Time.get_ticks_msec()+2000
	while not phases.has("release") and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(phases.has("release"),"travel observer reaches real release within a bounded wait")
	interrupt.call()

# A timer created partway through a long frame consumes that frame's simulation
# delta even though Fire's per-phase monotonic clock started much later.
func travel_observer_frame_delta_contract() -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var caster: Unit = manager.units.zane
	var target: Unit = recipients(manager)[0]
	var started := Time.get_ticks_msec()
	schedule_action_interruption("during travel",func() -> void:
		var controller = controllers.back().get_ref()
		print("Delayed-frame travel observer: wall=%dms release=%s charge_valid=%s" % [Time.get_ticks_msec()-started,phases.has("release"),is_instance_valid(controller._charge)])
		check(is_instance_valid(controller) and is_instance_valid(controller._trail) and controller._trail.width_curve != null and controller._trail.gradient != null,"Fire travels with one directionally tapered ember trail")
		check(is_instance_valid(controller) and is_instance_valid(controller._projectile) and controller._projectile.material is ShaderMaterial,"one projectile carries a local hot-core treatment, not a screen flash")
		manager.action_lifecycle.cancel()
	)
	OS.delay_msec(300) # Controlled cold/load frame; never changes production timing.
	check(not await manager._execute_ability(caster,target,AbilityDB.get_ability("fire")),"observed-flight interruption remains a rejected precontact action")
	check(outcomes.is_empty() and caster.mp == 100,"observed-flight interruption leaves no result or resource spend")
	await dispose(battle)


func fire_socket_frame_contract() -> void:
	# A former same-priority VFX-before-rig order lagged one full pose. Catch it
	# with the actual action owner and imported hand, not a manual _process call
	# or a prior-frame socket comparison. Stable controls must still agree.
	for stable in [true, false]:
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var caster: Unit = manager.units.zane
		var rig = caster._rig3d
		var geometry := [caster.position, caster.scale, rig.output.position, rig.output.scale,
			rig.camera.transform, rig.camera.size, rig.viewport.size]
		var original_time_scale := Engine.time_scale
		if stable: rig.set_process(false) # Deliberate stationary-pose control only.
		var probe := preload("res://tests/fixtures/FireSocketFrameObserver.gd").new()
		probe.actor = caster
		probe.slow_frame_ms = 75 if not stable else 0
		add_child(probe)
		VFX.child_entered_tree.connect(probe.observe)
		var accepted := await manager._execute_ability(caster, recipients(manager)[0], AbilityDB.get_ability("fire"))
		VFX.child_entered_tree.disconnect(probe.observe)
		var charge_count := 0
		var projectile_count := 0
		var max_error := 0.0
		var max_motion := 0.0
		var max_delta := 0.0
		for row: Dictionary in probe.samples:
			if row.stage != "process_end": continue
			if row.role == "charge":
				charge_count += 1
				max_error = maxf(max_error, row.error)
				max_motion = maxf(max_motion, row.motion)
				max_delta = maxf(max_delta, row.delta)
			elif row.role == "projectile":
				if projectile_count == 0: check(row.error <= 16, "first actual launch stays within existing 16 px of same-frame hand")
				projectile_count += 1
		var label := "stable" if stable else "moving slow-frame"
		print("Fire socket %s: %s" % [label, JSON.stringify({"samples":probe.samples,"render_phases":probe.render_phases})])
		check(charge_count >= 2 and projectile_count > 0, label + ": observes multiple actual charge frames and real launch")
		check(max_error <= 8, label + ": every end-of-process charge is within existing 8 px of CURRENT hand (max %.5f)" % max_error)
		check(max_motion < 0.001 if stable else max_motion > 8, label + ": stationary control or meaningful imported hand movement (%.5f px)" % max_motion)
		if not stable: check(max_delta >= 0.05, "moving probe includes actual slow engine frame, not a fabricated pose/delta")
		check(geometry == [caster.position, caster.scale, rig.output.position, rig.output.scale,
			rig.camera.transform, rig.camera.size, rig.viewport.size], label + ": no foot, camera or display-footprint changes")
		check(Engine.time_scale == original_time_scale, label + ": no global time-scale changes")
		check(accepted and caster.mp == 88 and outcomes.size() == 1, label + ": same accepted real action, one cost and one outcome")
		probe.free()
		if stable: rig.set_process(true)
		await dispose(battle)
