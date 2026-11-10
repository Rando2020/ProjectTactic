extends "res://tests/test_zane_impact_actions.gd"
## Controlled real-manager tests. No substitute damage or initiative implementation.
var battle
var manager
var capture_dir := ""
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir=arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
	VFX.child_entered_tree.connect(observe)
	GameState._init_defaults()
	GameState.save()
	var ownership := skill_ownership()
	var saved := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	await boot()
	check(manager.units.size()==4,"only the existing four fighters spawn")
	check("haste" in manager.units.zane.unit_data.abilities,"Zane has Haste without learning or save edits")
	check("delay_strike" in manager.units.kael.unit_data.abilities,"Kael has Delay Strike")
	check("heavy_slash" in manager.units.kael.unit_data.abilities,"Kael has Heavy Slash")
	if failures.size()>0:
		await cleanup()
		finish()
		return
	for id in ["fire","thunderstrike","void_pulse"]:
		check(id in manager.units.zane.unit_data.abilities,"Zane retains "+id)
	for id in ["mighty_strike","defend"]:
		check(id in manager.units.kael.unit_data.abilities,"Kael retains "+id)
	check(AbilityDB.get_ability("fireball")==AbilityDB.get_ability("fire"),"Fire alias unchanged")
	await haste_case()
	await strike_case("delay_strike")
	await strike_case("heavy_slash")
	await miss_case("delay_strike")
	await miss_case("heavy_slash")
	await interruption_case()
	await defeat_cases()
	check(skill_ownership()==ownership,"practice loadout never changes saved skill ownership")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH)==saved,"practice actions leave save bytes unchanged")
	await cleanup()
	await boot()
	check(manager.units.kael.ct>=0 and not manager.units.kael.has_status("haste"),"fresh encounter clears delay debt and Haste")
	check("heavy_slash" in manager.units.kael.unit_data.abilities,"fresh encounter restores test skill loadout")
	await cleanup()
	finish()
func skill_ownership() -> Dictionary:
	var result: Dictionary={}
	for id in ["zane","kael"]:
		result[id]={}
		for key in ["base_abilities","learned_abilities","equipped_abilities"]:
			result[id][key]=GameState.unit_registry[id].get(key,[]).duplicate(true)
	return result
func finish() -> void:
	print("Hero skills: %d checks, %d failures" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
func boot() -> void:
	if not GameState.practice_session.is_empty():GameState.leave_practice()
	GameState.practice_session={}
	battle=load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
	get_tree().root.add_child(battle)
	manager=battle.battle_manager
	for frame in 600:
		if manager.current_phase==BattleManager.Phase.PLAYER_TURN:break
		await get_tree().process_frame
	manager.combat_resolver.combat_resolved.connect(func(value):outcomes.append(value))
func cleanup() -> void:
	await manager._recover_action()
	battle.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
func fixture(actor_id: String) -> void:
	for unit: Unit in manager.units.values():
		unit.hp=2000;unit.mp=200;unit.temper=0;unit.ether=0;unit.ct=0
		unit.unit_data.base_stats.hp=2000
		unit.statuses.clear();unit.has_acted=false;unit.has_moved=false
	manager.units.zane.grid_pos=Vector2i(3,8)
	manager.units.kael.grid_pos=Vector2i(4,8)
	manager.units.Enemy_1.grid_pos=Vector2i(4,7)
	manager.units.Enemy_2.grid_pos=Vector2i(6,8)
	for unit: Unit in manager.units.values():
		manager.tactical_grid.tiles[unit.grid_pos].height=0
		unit.position=manager.tactical_grid._grid_to_local(unit.grid_pos)
	manager.current_phase=BattleManager.Phase.PLAYER_TURN
	manager.active_unit_id=actor_id;manager.active_unit_has_acted=false;manager.active_unit_has_moved=false
	manager.units.Enemy_1.set_facing(CombatFormula.FACING_OPPOSITE[CombatFormula.attack_direction(manager.units.kael.grid_pos,manager.units.Enemy_1.grid_pos)])
	manager.turn_started.emit(actor_id,"player")
	manager.cancel_pending_action()
	battle.battle_ui._selection.select_unit(actor_id)
	outcomes.clear();controllers.clear()
func settle() -> void:
	for frame in 600:
		if not manager.is_resolving_action:return
		await get_tree().create_timer(0.02).timeout
	check(false,"action settles")
func stage(id: String, target: Unit) -> void:
	manager.select_command("ability")
	var found := false
	for button in battle.battle_ui._ability_list.get_children():
		if not button is Button or button.is_queued_for_deletion():continue
		for label in button.find_children("*","Label",true,false):
			if label.text==AbilityDB.get_ability(id).display_name:
				button.pressed.emit()
				found=true
				break
		if found:break
	check(found,id+" selected from its real Skills button")
	battle.battle_ui._selection.set_cursor(target.grid_pos)
	battle.battle_ui._selection.activate_cursor()
func haste_case() -> void:
	fixture("zane")
	manager.select_command("ability")
	await capture("zane-skills")
	var caster: Unit=manager.units.zane
	var target: Unit=manager.units.kael
	var speed:=target.get_effective_speed()
	stage("haste",target)
	check(battle.battle_ui._selection.has_review(),"Haste stages actual ally review")
	await capture("haste-review")
	var before: Array=manager.turn_order.get_projected_order(8)
	battle.battle_ui._selection.go_back()
	check(caster.mp==200 and not target.has_status("haste"),"cancel Haste spends no resources")
	stage("haste",target)
	battle.battle_ui._selection.confirm_review();battle.battle_ui._selection.confirm_review()
	await settle()
	check(caster.mp==190 and target.hp==2000,"Haste spends 10 MP once with no damage")
	check(target.has_status("haste") and target.get_effective_speed()==int(speed*1.5),"Haste changes actual speed by 1.5x")
	check(manager.turn_order.get_projected_order(8)!=before,"Haste changes projected initiative")
	check(caster.ct==0 and target.ct==0,"Haste does not immediately spend or add CT")
	await capture("haste-applied")
	target.end_turn()
	manager.active_unit_has_acted=false
	stage("haste",caster)
	check(not battle.battle_ui._selection.has_review(),"Haste cannot self target")
	manager.cancel_pending_action()
	stage("haste",target)
	battle.battle_ui._selection.confirm_review()
	await settle()
	check(caster.mp==180 and target.get_effective_speed()==int(speed*1.5),"repeated Haste pays cost without stacking speed")
	for i in 2:target.end_turn()
	check(not target.has_status("haste") and target.get_effective_speed()==speed,"Haste expires after three target end turns")
func strike_case(id: String) -> void:
	fixture("kael")
	if id=="delay_strike":
		manager.select_command("ability")
		await capture("kael-skills")
	var caster: Unit=manager.units.kael
	var target: Unit=manager.units.Enemy_1
	var ability:=AbilityDB.get_ability(id)
	var forecast: Dictionary=manager._ability_preview_for_tile(target.grid_pos,ability)
	# Range is established through the real skill command before reading forecast.
	stage(id,target)
	forecast=manager._ability_preview_for_tile(target.grid_pos,ability)
	check(battle.battle_ui._selection.has_review(),id+" review accepted")
	check(str(forecast.get("note","")).contains("30 CT"),id+" preview explains exact turn delay")
	check(battle.battle_ui._preview_note_label.text.contains("30 CT"),id+" delay visible in real HUD")
	check(bool(forecast.get("can_counter",false)),id+" forecasts physical counter risk")
	check(not ability.has("aoe_type"),id+" is single target regardless of weapon")
	await capture(id+"-review")
	var before: Array=manager.turn_order.get_projected_order(12)
	battle.battle_ui._selection.go_back()
	check(caster.ct==0 and target.ct==0 and caster.mp==200,id+" cancel leaves CT and MP untouched")
	stage(id,target)
	battle.battle_ui._selection.confirm_review();battle.battle_ui._selection.confirm_review()
	await settle()
	check(caster.mp==200-int(ability.mp_cost),id+" pays exactly one MP cost")
	check(target.hp<2000 and outcomes.filter(func(value):return value.has("feedback_owner")).size()==1,id+" resolves one damaging hit")
	check(manager.active_unit_has_acted and not manager.active_unit_has_moved,id+" consumes action and retains move")
	check(target.ct==(-30 if id=="delay_strike" else 0),id+" shifts target CT only as designed")
	check(caster.ct==(-30 if id=="heavy_slash" else 0),id+" shifts actor CT only as designed")
	check(manager.turn_order.get_projected_order(12)!=before,id+" changes real projected order")
	check(not target.has_status("slow") and target.get_effective_speed()==target.unit_data.base_stats.speed,id+" is a direct delay, not Slow")
	check(not controllers.is_empty(),id+" uses authored melee presentation")
	if not controllers.is_empty():
		var owner=controllers.back().get_ref()
		var labels:=""
		if is_instance_valid(owner):
			for fx in owner._fx:
				if is_instance_valid(fx) and fx is Label:labels+=fx.text
		check(labels.contains("30 CT"),id+" contact feedback identifies turn delay")
	if id=="heavy_slash":
		var heavy:=ForecastCalculator.spell(caster,target,ability)
		var mighty:=ForecastCalculator.spell(caster,target,AbilityDB.get_ability("mighty_strike"))
		check(heavy.damage>mighty.damage,"Heavy Slash trades greater damage for self delay")
	# Actual scheduler starts from exactly the same immutable projection state.
	var predicted: Array=manager.turn_order.get_projected_order(4)
	for i in 4:
		var next: Unit=manager.turn_order.tick_until_ready()
		check(next.unit_id==predicted[i].unit_id,id+" scheduler agrees with delayed preview "+str(i))
func miss_case(id: String) -> void:
	fixture("kael")
	var caster: Unit=manager.units.kael
	var target: Unit=manager.units.Enemy_1
	var blind:=StatusEffect.new();blind.status_id="blind";blind.duration=2;caster.apply_status(blind)
	target.set_facing(CombatFormula.attack_direction(caster.grid_pos,target.grid_pos))
	var ability:=AbilityDB.get_ability(id)
	var hit:=int(CombatFormula.calculate_physical_attack(caster,target,{}, {},{"base_power":ability.base_power}).hit_pct)
	var miss_seed:=0
	while true:
		seed(miss_seed)
		if randi_range(1,100)>hit:break
		miss_seed+=1
	seed(miss_seed)
	var execution: Dictionary=await manager._execute_ability_with_result(caster,target,ability)
	check(execution.executed and execution.outcome.get("missed",false),id+" deterministic real miss")
	check(target.ct==0,id+" miss never delays target")
	check(caster.ct==(-30 if id=="heavy_slash" else 0),id+" self commitment applies even on miss")
	await manager._recover_action()
func interruption_case() -> void:
	fixture("kael")
	manager.units.kael.mp=0
	manager.select_ability("heavy_slash")
	check(manager.selected_ability_id=="" and manager.units.kael.ct==0,"unaffordable skill changes neither turn order nor action")
	manager.units.kael.mp=200
	stage("delay_strike",manager.units.zane)
	check(not battle.battle_ui._selection.has_review(),"Delay Strike cannot target ally")
	manager.cancel_pending_action()
	manager.select_ability("heavy_slash")
	manager._execute_ability(manager.units.kael,manager.units.Enemy_1,AbilityDB.get_ability("heavy_slash"))
	manager.action_lifecycle.cancel()
	await settle()
	check(manager.units.kael.mp==200 and manager.units.kael.ct==0 and manager.units.Enemy_1.hp==2000,"cancelled anticipation spends no MP, damage or CT")
func defeat_cases() -> void:
	for id in ["delay_strike","heavy_slash"]:
		fixture("kael")
		var caster: Unit=manager.units.kael
		var target: Unit=manager.units.Enemy_1
		target.hp=1
		var result: Dictionary=await manager._execute_ability_with_result(caster,target,AbilityDB.get_ability(id))
		check(target.hp==0 and target.ct==0 and not result.outcome.has("target_ct_delay"),id+" never delays a defeated target")
		await cleanup()
		await boot()
		fixture("kael")
		caster=manager.units.kael;target=manager.units.Enemy_1
		caster.hp=1
		var found_seed:=0
		while true:
			seed(found_seed)
			randi_range(1,100);randi_range(1,100)
			if randf()<0.25:break
			found_seed+=1
		stage(id,target)
		seed(found_seed)
		battle.battle_ui._selection.confirm_review()
		await settle()
		check(caster.hp==0,id+" fixture counter defeats actor")
		check(caster.ct==0,id+" does not assign recovery debt to a defeated actor")
		# Scheduler may pass through enemy turns; it must never stay on dead Kael.
		check(manager.current_phase!=BattleManager.Phase.PLAYER_TURN or manager.active_unit_id!="kael",id+" counter-KO cannot strand dead actor's turn")
		for i in 1200:
			if manager.current_phase==BattleManager.Phase.PLAYER_TURN and manager.active_unit_id=="zane":break
			await get_tree().create_timer(0.01).timeout
		check(manager.current_phase==BattleManager.Phase.PLAYER_TURN and manager.active_unit_id=="zane",id+" counter-KO reaches surviving ally")
		await cleanup()
		await boot()
func capture(label: String) -> void:
	if capture_dir.is_empty():return
	# Allow the preceding controlled action's nonblocking banner to retire.
	await get_tree().create_timer(1.5).timeout
	for i in 5:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label+".png"))==OK,"capture "+label)
