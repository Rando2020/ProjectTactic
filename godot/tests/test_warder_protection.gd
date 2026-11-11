extends Node
## Real factories, manager, combat math and owner-turn lifecycle.
var checks := 0
var failures := 0
var factory: BattleScene
var manager: BattleManager
var guard: Unit
var ally: Unit
var enemy: Unit
var created: Array[Unit] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
func _ready() -> void:
	call_deferred("run")
func make(id: String, faction: String, pos: Vector2i) -> Unit:
	var unit := factory._make_unit(id, id.capitalize(), faction, pos, 2000, 100, 4, 2, 6, 100, 100, 100, 100, ["cover_ally", "iron_wall", "mighty_strike"])
	add_child(unit)
	unit.temper = 0; unit.ether = 0
	created.append(unit)
	return unit
func status(unit: Unit, id: String, duration: int = 4) -> void:
	var effect := StatusEffect.new()
	effect.status_id = id; effect.duration = duration
	unit.apply_status(effect)
func reset() -> void:
	manager.action_lifecycle.cancel()
	manager.is_resolving_action = false
	manager.current_phase = BattleManager.Phase.PLAYER_TURN
	manager.active_unit_id = guard.unit_id
	manager.active_unit_has_acted = false; manager.active_unit_has_moved = false
	manager.active_command = ""; manager.selected_ability_id = ""
	for unit in [guard, ally, enemy]:
		unit.statuses.clear(); unit.hp = 2000; unit.mp = 100
		unit.has_acted = false; unit.has_moved = false; unit.is_defeated = false
		unit.temper = 0; unit.ether = 0; unit.job_mastery = {}
		unit.unit_data.base_stats.physical_resistance = 0; unit.unit_data.base_stats.magic_resistance = 0
		unit.unit_data.elemental_affinities = {}
	guard.team = "player"; ally.team = "player"; enemy.team = "enemy"
	guard.grid_pos = Vector2i(3,3); ally.grid_pos = Vector2i(4,3); enemy.grid_pos = Vector2i(3,2)
func run() -> void:
	GameState._init_defaults(); GameState.active_run = null; GameState.practice_session.clear()
	GameState.selected_map_index = 0
	factory = load("res://scenes/Battle.tscn").instantiate()
	add_child(factory)
	manager = factory.battle_manager
	guard = make("guard", "player", Vector2i(3,3))
	ally = make("ally", "player", Vector2i(4,3))
	enemy = make("enemy", "enemy", Vector2i(3,2))
	manager.units = {guard.unit_id:guard, ally.unit_id:ally, enemy.unit_id:enemy}
	manager.turn_order.initialize([guard, ally, enemy])
	await iron_wall_cases()
	await cover_cases()
	await review_integration_cases()
	await protection_edges()
	await manager._recover_action()
	for unit in created:
		if is_instance_valid(unit): unit.queue_free()
	factory.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(2.5).timeout
	print("Warder protection: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
func iron_wall_cases() -> void:
	reset()
	var ability := AbilityDB.get_ability("iron_wall")
	var cast: Dictionary = await manager._execute_ability_with_result(guard,guard,ability)
	check(cast.executed and guard.mp == 90 and guard.has_status("iron_wall"), "Iron Wall spends 10 MP once and establishes real self status")
	await manager._recover_action()
	check(guard.receive_damage(100,"physical").hp_damage == 60, "Iron Wall reduces normal physical damage by 40 percent")
	check(guard.receive_damage(100,"magical").hp_damage == 60, "Iron Wall reduces normal magical damage by 40 percent")
	check(guard.receive_damage(100,"true").hp_damage == 100, "Iron Wall does not change true damage")
	guard.job_mastery = {"phys_resist":0.25}; status(guard,"protect"); status(guard,"defending")
	check(guard.receive_damage(100,"physical").hp_damage == 16, "mastery Protect Defend Iron Wall stack with ordered rounding")
	check(guard.receive_damage(100,"magical").hp_damage == 30, "magical mitigation excludes physical-only mastery and Protect")
	guard.remove_status("protect"); guard.remove_status("defending"); guard.job_mastery = {}
	var preview := ForecastCalculator.attack(enemy,guard,{}, {})
	seed(991)
	var hit := manager.combat_resolver.resolve_attack(enemy,guard,{}, {},"slash",false,{"base_hit":100,"base_crit":0},&"test")
	check(preview.damage == hit.hp_damage, "Iron Wall forecast and actual armor loss agree")
	check(str(preview.formula_explain).contains("Iron Wall"), "forecast explains the active damage reduction")
	check(not guard.can_act() and guard.can_move(), "Iron Wall blocks action but keeps movement")
	var before := enemy.hp
	var blocked: Dictionary = manager.combat_resolver.resolve_attack(guard,enemy,{}, {},"slash",false,{},&"test")
	check(blocked.get("blocked",false) and enemy.hp == before, "direct attack resolver refuses Iron Wall attacker")
	var blocked_spell: Dictionary = manager.combat_resolver.resolve_spell(guard,enemy,"holy",100,&"test")
	check(blocked_spell.get("blocked",false) and enemy.hp == before, "direct spell resolver refuses Iron Wall caster")
	manager.select_command("attack")
	check(manager.active_command.is_empty(), "player attack command is blocked")
	manager.select_command("ability")
	check(manager.active_command.is_empty(), "player ability command is blocked")
	var repeated: Dictionary = await manager._execute_ability_with_result(guard,guard,ability)
	check(not repeated.executed and guard.mp == 90, "Iron Wall cannot refresh itself or spend MP while locked")
	var intent := manager._evaluate_enemy_intent(guard)
	check(intent.kind == "hold", "enemy planner holds instead of acting through Iron Wall")
	check(not await manager._auto_try_attack(guard), "auto-battle cannot act through Iron Wall")
	manager._execute_counter_attack(guard,enemy)
	check(enemy.hp == before, "Iron Wall prevents real counter dispatch")
	check(manager.action_lifecycle.begin(guard,enemy) == 0, "primary action lifecycle rejects locked actor")
	manager.select_command("move")
	check(manager.active_command == "move", "Iron Wall still admits Move command")
	guard.end_turn()
	guard.begin_turn()
	check(guard.has_status("iron_wall") and not guard.can_act(), "Iron Wall survives cast end and first future turn start")
	guard.end_turn(); guard.begin_turn()
	check(guard.has_status("iron_wall") and not guard.can_act(), "Iron Wall survives through second future turn")
	guard.end_turn(); guard.begin_turn()
	check(not guard.has_status("iron_wall") and guard.can_act(), "Iron Wall ends after exactly two future owner end turns")
	guard.has_acted = true
	check(CombatFormula.counter_chance(guard) == 0.25, "ordinary spent-action units retain baseline counter chance")
	# A status arriving during anticipation cancels contact, not just new admission.
	guard.has_acted = false
	var ticket := manager.action_lifecycle.begin(guard,enemy)
	status(guard,"iron_wall")
	check(ticket > 0 and not manager.action_lifecycle.contact(ticket), "Iron Wall arriving during anticipation blocks contact")

func cast_cover() -> Dictionary:
	var result: Dictionary = await manager._execute_ability_with_result(guard,ally,AbilityDB.get_ability("cover_ally"))
	await manager._recover_action()
	return result
func cover_cases() -> void:
	reset()
	var cover := AbilityDB.get_ability("cover_ally")
	manager.select_ability("cover_ally")
	check(Vector2i(4,3) in manager.tactical_grid.ability_tiles and Vector2i(5,3) not in manager.tactical_grid.ability_tiles, "unmastered Cover selects adjacency only")
	guard.job_mastery = JobTreeData.runtime_mastery_bonuses({"warder":800})
	manager.select_ability("cover_ally")
	check(Vector2i(5,3) in manager.tactical_grid.ability_tiles and Vector2i(6,3) not in manager.tactical_grid.ability_tiles, "earned Warder mastery extends actual Cover selection to two tiles")
	guard.job_mastery = {}
	ally.grid_pos = Vector2i(5,3)
	var denied: Dictionary = await cast_cover()
	check(not denied.executed and guard.mp == 100, "unmastered two-tile Cover is rejected at execution")
	ally.grid_pos = Vector2i(4,3)
	var cast: Dictionary = await cast_cover()
	check(cast.executed and guard.has_status("covering") and not ally.has_status("covering"), "Cover belongs to protector not ally")
	check(guard.mp == 100, "Cover preserves catalog zero MP cost")
	var repeat: Dictionary = await cast_cover()
	check(not repeat.executed, "duplicate Cover cannot stack or refresh")
	var wrong: Dictionary = await manager._execute_ability_with_result(enemy,ally,cover)
	check(not wrong.executed, "Cover cannot protect an enemy")
	wrong = await manager._execute_ability_with_result(guard,guard,cover)
	check(not wrong.executed, "Cover cannot self target")
	guard.end_turn(); ally.end_turn(); ally.end_turn()
	check(guard.has_status("covering"), "Cover persists across cast end and arbitrary ally turns")
	enemy.grid_pos = Vector2i(4,2); ally.set_facing("N")
	guard.unit_data.base_stats.physical_resistance = 20
	ally.unit_data.base_stats.physical_resistance = 60
	guard.temper = 100
	var before_hp := guard.hp
	var preview := ForecastCalculator.attack(enemy,ally,{}, {})
	check(preview.target_name == guard.display_name and preview.damage == 91, "Cover forecast uses protector identity defense and Temper")
	check(preview.hp_before == guard.hp and preview.hp_after == guard.hp-91, "Cover forecast projects protector HP rather than ally HP")
	check(str(preview.get("note","")).contains(ally.display_name), "Cover forecast names the protected ally")
	seed(102)
	var outcome := manager.combat_resolver.resolve_attack(enemy,ally,{}, {},"arrow",false,{"base_hit":100,"base_crit":0},&"test")
	check(outcome.get("recipient_id","") == guard.unit_id and outcome.hp_damage == 91, "real ranged hit follows the same protector as forecast")
	check(ally.hp == 2000 and ally.temper == 0 and guard.hp == before_hp-91 and guard.temper == 65, "only protector HP and armor absorb redirected hit")
	var record := manager._presentation_record(ally,outcome)
	check(record.target_id == guard.unit_id and record.grid_pos == guard.grid_pos and record.target_ref.get_ref() == guard, "damage feedback is anchored to actual protector")
	guard.begin_turn()
	check(not guard.has_status("covering"), "Cover expires at protector next turn start")
	var plain := ForecastCalculator.attack(enemy,ally,{}, {})
	check(plain.target_name == ally.display_name and plain.damage == 60, "expired Cover restores ordinary target math")
	reset(); await cast_cover()
	guard.unit_data.base_stats.magic_resistance = 20
	guard.unit_data.elemental_affinities = {"holy":0.5}
	ally.unit_data.elemental_affinities = {"holy":2.0}
	guard.ether = 100
	var spell := {"id":"fixture_holy", "type":"spell", "spell_type":"holy", "base_power":100, "mp_cost":0, "range":4}
	preview = ForecastCalculator.spell(enemy,ally,spell)
	check(preview.target_name == guard.display_name and preview.damage == 36 and preview.affinity == 0.5, "single-target spell forecast uses protector affinity and Ether")
	outcome = manager.combat_resolver.resolve_spell(enemy,ally,"holy",100,&"test")
	check(outcome.hp_damage == 36 and ally.hp == 2000 and guard.hp == 1964 and guard.ether == 86, "direct spell actually spends protector Ether and HP only")
	# Explicit area spells must ignore Cover in forecast and per-recipient resolution.
	spell["aoe_type"] = "radius"; spell["aoe_radius"] = 1
	preview = ForecastCalculator.spell(enemy,ally,spell)
	check(preview.target_name == ally.display_name and preview.damage == 200, "area forecast does not redirect onto protector")
	var area: Dictionary = await manager._execute_ability_with_result(enemy,ally,spell,true)
	check(area.executed and ally.hp == 1800 and guard.hp == 1964, "area recipient resolution bypasses Cover")
	reset(); await cast_cover()
	guard.grid_pos = Vector2i(2,3)
	check(ForecastCalculator.attack(enemy,ally,{}, {}).target_name == ally.display_name, "moving outside range suspends Cover")
	guard.grid_pos = Vector2i(3,3)
	check(ForecastCalculator.attack(enemy,ally,{}, {}).target_name == guard.display_name, "returning to range restores unexpired Cover")
	status(guard,"stun")
	check(ForecastCalculator.attack(enemy,ally,{}, {}).target_name == ally.display_name, "stunned protector cannot intercept")
	guard.remove_status("stun"); status(guard,"petrify")
	check(ForecastCalculator.attack(enemy,ally,{}, {}).target_name == ally.display_name, "petrified protector cannot intercept")
	guard.remove_status("petrify"); guard.hp = 0
	check(ForecastCalculator.attack(enemy,ally,{}, {}).target_name == ally.display_name, "defeated protector cannot intercept")
	reset(); await cast_cover()
	guard.unit_data.base_stats.magic_resistance = 0
	guard.unit_data.elemental_affinities = {}
	var hostile := AbilityDB.get_ability("mighty_strike")
	hostile["status_effect"] = {"id":"slow", "duration":2, "magnitude":0.5}
	# Force a back hit through the real manager without substituting a resolver.
	enemy.grid_pos = Vector2i(4,2); ally.set_facing("S")
	var contact: Dictionary = await manager._execute_ability_with_result(enemy,ally,hostile)
	await manager._recover_action()
	check(contact.executed and guard.has_status("slow") and not ally.has_status("slow"), "redirected hit secondary status follows protector")
	var details := manager._enemy_intent_details(enemy,"attack",ally)
	check(details.get("recipient_id","") == guard.unit_id and details.target_hp_after == guard.hp-int(details.damage), "enemy intent projects damage onto the actual protector")

func protection_edges() -> void:
	reset(); await cast_cover()
	enemy.grid_pos = Vector2i(4,2); ally.set_facing("N")
	ally.hp = 1
	check(manager._find_kill_attack(enemy) == null, "AI does not promise to finish an ally whose protector survives")
	enemy.unit_data.abilities = ["blizzard"]
	check(not manager._find_kill_spell(enemy).is_empty(), "AI correctly sees a lethal area spell bypassing Cover")
	enemy.unit_data.abilities = ["holy"]
	check(manager._find_kill_spell(enemy).is_empty(), "AI lethal spell search checks protector HP")
	ally.hp = 2000
	guard.unit_data.elemental_affinities = {"holy":0.5}
	ally.unit_data.elemental_affinities = {"holy":2.0}
	var area := {"id":"fixture_area","type":"spell","spell_type":"holy","base_power":100,"aoe_type":"radius","aoe_radius":1}
	check(manager._predict_spell_damage(enemy,ally,area) == 200, "AI area predictor bypasses Cover just like actual area damage")
	reset(); status(guard,"iron_wall")
	ally.hp = 1000
	var healed := manager.combat_resolver.resolve_heal(guard,ally,80)
	check(healed.get("blocked",false) and ally.hp == 1000, "direct healing resolver cannot bypass Iron Wall action lock")
	reset(); await cast_cover()
	enemy.grid_pos = Vector2i(4,2); ally.set_facing("N")
	var before := [guard.hp,ally.hp,guard.temper,guard.ether,guard.mp]
	seed(31); var expected_rng := randi(); seed(31)
	for i in 3: ForecastCalculator.attack(enemy,ally,{}, {})
	check(randi() == expected_rng and before == [guard.hp,ally.hp,guard.temper,guard.ether,guard.mp], "repeated Cover forecasts consume no RNG or combat resources")
	var miss_seed := 0
	while true:
		seed(miss_seed)
		if randi_range(1,100)>20: break
		miss_seed+=1
	seed(miss_seed)
	var missed := manager.combat_resolver.resolve_attack(enemy,ally,{}, {},"arrow",false,{"base_hit":20,"base_crit":0},&"test")
	check(missed.missed and guard.hp == 2000 and ally.hp == 2000 and guard.has_status("covering"), "miss preserves Cover and damages neither unit")
	var critical := manager.combat_resolver.resolve_attack(enemy,ally,{}, {},"arrow",false,{"base_hit":100,"base_crit":100},&"test")
	check(critical.critical and critical.hp_damage == 180 and guard.hp == 1820 and ally.hp == 2000, "critical scales redirected incoming damage once")
	reset(); await cast_cover()
	guard.has_acted = true; guard.job_mastery = {"counter_chance_bonus":0.75}
	var counter := manager.combat_resolver.resolve_attack(enemy,ally,{}, {},"slash",false,{"base_hit":100,"base_crit":0},&"test")
	check(counter.counter and counter.get("recipient_id","") == guard.unit_id, "spent-action protector supplies its own counter eligibility")
	counter = manager.combat_resolver.resolve_attack(enemy,ally,{}, {},"slash",true,{"base_hit":100,"base_crit":0},&"test")
	check(not counter.counter and counter.get("recipient_id","") == guard.unit_id, "incoming counter can be covered without counter recursion")
	reset(); await cast_cover()
	var reciprocal: Dictionary = await manager._execute_ability_with_result(ally,guard,AbilityDB.get_ability("cover_ally"))
	await manager._recover_action()
	check(reciprocal.executed, "reciprocal links are admitted without creating recursive resolution")
	var once := manager.combat_resolver.resolve_attack(enemy,ally,{}, {},"arrow",false,{"base_hit":100,"base_crit":0},&"test")
	check(once.get("recipient_id","") == guard.unit_id and guard.hp < 2000 and ally.hp == 2000, "reciprocal Cover redirects only one hop")
	reset(); await cast_cover()
	var second := make("second_guard","player",Vector2i(4,4))
	check(not second.cover_ally(ally), "a second protector cannot silently replace an active link")
	guard.begin_turn()
	check(second.cover_ally(ally), "expired protector releases ally for another protector")
	second.free()
	check(ally.get_damage_recipient(enemy) == ally, "freed protector reference safely falls back to original ally")
	created = created.filter(func(unit): return is_instance_valid(unit))
	reset(); await cast_cover()
	ally.receive_damage(100,"true")
	var poison := StatusEffect.new(); poison.status_id="poison"; poison.magnitude=0.1; poison.duration=1
	ally.apply_status(poison); ally.end_turn()
	check(ally.hp == 1700 and guard.hp == 2000, "true and ongoing damage stay on protected ally")
	reset(); await cast_cover()
	enemy.set_meta("prefixes",[{"on_hit":{"type":"mp_drain","amount":7}}])
	manager.combat_resolver.resolve_attack(enemy,ally,{}, {},"arrow",false,{"base_hit":100,"base_crit":0},&"test")
	check(guard.mp == 93 and ally.mp == 100, "elite on-hit effect follows redirected recipient")
	enemy.remove_meta("prefixes")
	reset()
	get_tree().create_timer(0.02).timeout.connect(func(): ally.grid_pos=Vector2i(7,3))
	var stale: Dictionary = await cast_cover()
	check(not stale.executed and guard.mp == 100 and not guard.has_status("covering"), "Cover target leaving range during anticipation cancels without commitment")
	reset()
	get_tree().create_timer(0.02).timeout.connect(func(): manager.action_lifecycle.cancel())
	var cancel: Dictionary = await manager._execute_ability_with_result(guard,guard,AbilityDB.get_ability("iron_wall"))
	await manager._recover_action()
	check(not cancel.executed and guard.mp == 100 and not guard.has_status("iron_wall"), "cancelled Iron Wall anticipation spends no MP or status")
	reset()
	guard.job_mastery = JobTreeData.runtime_mastery_bonuses({"warder":800})
	ally.grid_pos = Vector2i(5,3)
	var mastered: Dictionary = await cast_cover()
	check(mastered.executed and ally.get_damage_recipient(enemy) == guard, "earned mastery admits and intercepts an actual two-tile Cover")
	reset()
	guard.team = "enemy"; ally.team = "enemy"; enemy.team = "player"
	await cast_cover()
	enemy.grid_pos = Vector2i(4,2); ally.set_facing("S")
	GameState.active_run = RunState.new()
	GameState.active_run.active_boons = [{"id":"fixture_ruin","effect":{"type":"tactical","id":"ruinous_field","interval":1}}]
	manager._ruinous_hit_counter = 0
	manager.tactical_grid.tiles[ally.grid_pos]["terrain"] = "grass"
	manager.tactical_grid.tiles[guard.grid_pos]["terrain"] = "grass"
	manager.active_unit_id = enemy.unit_id
	manager.select_command("attack")
	await manager._on_unit_clicked(ally.unit_id)
	check(manager.tactical_grid.get_tile(ally.grid_pos).terrain == "burning" and manager.tactical_grid.get_tile(guard.grid_pos).terrain == "grass", "redirected basic hit leaves its ground boon on originally aimed tile")
	GameState.active_run = null
	reset(); await cast_cover()
	guard.hp = 1
	var lethal := manager.combat_resolver.resolve_attack(enemy,ally,{}, {},"arrow",false,{"base_hit":100,"base_crit":0},&"test")
	check(guard.hp == 0 and ally.hp == 2000 and lethal.applied_hp_damage == 1, "overkill defeats protector and reports actual one HP loss")
	var record := manager._presentation_record(ally,lethal)
	check(record.target_id == guard.unit_id and record.outcome.defeated, "KO feedback retains protector identity")
	check(ally.get_damage_recipient(enemy) == ally, "defeated protector no longer intercepts following hits")
	# Echo is a direct follow-up; its redirected kill belongs to the interceptor.
	ally.team = "enemy"; enemy.team = "player"; enemy.hp = 1000
	enemy.grid_pos = Vector2i(4,2); ally.grid_pos = Vector2i(4,3); ally.set_facing("S")
	var echo_guard := make("echo_guard","enemy",Vector2i(3,3))
	echo_guard.hp = 1; echo_guard.set_meta("elite_tier","elite")
	check(echo_guard.cover_ally(ally), "fresh protector can cover after previous protector defeat")
	manager.units[echo_guard.unit_id] = echo_guard
	GameState.active_run = RunState.new()
	GameState.active_run.active_boons = [{"id":"fixture_grit","effect":{"type":"on_elite_kill","heal_hp":17}}]
	manager._apply_tactical_boons(enemy,ally,{"echo_strike_chance":1.0},100)
	check(echo_guard.hp == 0 and ally.hp == 2000 and enemy.hp == 1017, "Echo applies elite kill reward from actual defeated protector")
	GameState.active_run = null

func review_integration_cases() -> void:
	# Terrain keeps its existing Defend/Ether handling but bypasses the new stance.
	reset()
	manager.tactical_grid.tiles[guard.grid_pos]["terrain"] = "burning"
	manager._process_terrain_hazards(guard)
	var baseline_hp := guard.hp
	guard.hp = 2000; status(guard,"iron_wall")
	manager._process_terrain_hazards(guard)
	check(guard.hp == baseline_hp, "Iron Wall does not reduce burning ground")
	guard.remove_status("iron_wall"); status(guard,"defending")
	guard.hp = 2000; guard.ether = 100
	manager._process_terrain_hazards(guard)
	baseline_hp = guard.hp
	var baseline_ether := guard.ether
	guard.hp = 2000; guard.ether = 100; status(guard,"iron_wall")
	manager._process_terrain_hazards(guard)
	check(guard.hp == baseline_hp and guard.ether == baseline_ether, "terrain bypass preserves baseline Defend and Ether mitigation")
	manager.tactical_grid.tiles[guard.grid_pos]["terrain"] = "grass"
	reset(); guard.cover_ally(ally); guard.hp = 1
	enemy.grid_pos = Vector2i(4,2); enemy.unit_data.abilities = []
	var intent := manager._evaluate_enemy_intent(enemy)
	check(intent.note == "Can defeat Guard.", "Finish intent does not falsely promise the protected ally KO")
	enemy.unit_data.abilities = ["cover_ally", "iron_wall", "mighty_strike"]
	# Exercise real basic-attack dispatch, not a direct boon helper invocation.
	var outcomes: Array[Dictionary] = []
	var capture := func(value: Dictionary): outcomes.append(value.duplicate(true))
	manager.combat_resolver.combat_resolved.connect(capture)
	for scenario in ["living", "reciprocal", "lethal"]:
		reset(); outcomes.clear()
		var echo_guard := make("echo_"+scenario+"_guard","enemy",Vector2i(3,3))
		var echo_ally := make("echo_"+scenario+"_ally","enemy",Vector2i(4,3))
		var echo_actor := make("echo_"+scenario+"_actor","player",Vector2i(4,2))
		echo_ally.set_facing("S"); echo_guard.set_facing("N")
		echo_guard.job_mastery = {"counter_chance_bonus":-0.25}
		echo_guard.cover_ally(echo_ally)
		if scenario == "reciprocal": echo_ally.cover_ally(echo_guard)
		if scenario == "lethal": echo_guard.hp = 1
		manager.units = {echo_guard.unit_id:echo_guard,echo_ally.unit_id:echo_ally,echo_actor.unit_id:echo_actor}
		manager.turn_order.initialize([echo_guard,echo_ally,echo_actor])
		GameState.active_run = RunState.new()
		GameState.active_run.active_boons = [{"id":"fixture_echo","effect":{"type":"tactical","id":"echo_strike","chance":1.0}}]
		manager.active_unit_id = echo_actor.unit_id
		manager.select_command("attack")
		seed(102)
		await manager._on_unit_clicked(echo_ally.unit_id)
		check(outcomes.size() == 2, "real Echo dispatch resolves twice after "+scenario+" Cover")
		if scenario == "lethal":
			check(echo_guard.hp == 0 and echo_ally.hp < 2000, "Echo resumes original aim after interceptor dies")
		else:
			check(echo_ally.hp == 2000 and echo_guard.hp < 2000, "each Echo hit redirects one hop from original aim for "+scenario)
			check(outcomes.size() == 2 and outcomes[0].flank == "back" and outcomes[1].flank == "back", "Echo keeps original aim facing for "+scenario)
	GameState.active_run = null
	manager.combat_resolver.combat_resolved.disconnect(capture)
	manager.units = {guard.unit_id:guard,ally.unit_id:ally,enemy.unit_id:enemy}
	manager.turn_order.initialize([guard,ally,enemy])
