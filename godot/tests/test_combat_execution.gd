extends Node

var checks := 0
var failures := 0
var last_result: Dictionary = {}
var latest_timeline: Array = []
var timeline_updates := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	GameState.active_run = null
	GameState.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	var caster: Unit = manager.units["kael"]
	var target: Unit
	for candidate: Unit in manager.units.values():
		if candidate.team != caster.team:
			target = candidate
			break
	# Real scene, real units and resolver; isolate damage from counter/death outcomes.
	caster.grid_pos = Vector2i(2, 2)
	target.grid_pos = Vector2i(2, 3)
	target.facing = "N"
	target.unit_data = target.unit_data.duplicate(true)
	target.unit_data.base_stats.hp = 2000
	target.unit_data.base_stats.physical_resistance = 0
	caster.unit_data = caster.unit_data.duplicate(true)
	caster.unit_data.base_stats.physical = 50
	manager.combat_resolver.combat_resolved.connect(func(result: Dictionary): last_result = result)
	for ability_id in ["mighty_strike", "pin_shot", "aimed_shot"]:
		var ability := AbilityDB.get_ability(ability_id).duplicate(true)
		ability["vfx_mode"] = "arrow" # same physical resolver, no random counter
		target.hp = 2000
		target.temper = 65
		target.statuses.clear()
		caster.mp = 100
		var tile_c := manager.tactical_grid.get_tile(caster.grid_pos)
		var tile_t := manager.tactical_grid.get_tile(target.grid_pos)
		var expected := CombatFormula.calculate_physical_attack(caster, target, tile_c, tile_t, {"base_power": ability.base_power})
		var forecast := ForecastCalculator.spell(caster, target, ability, tile_c, tile_t)
		check(forecast.damage == expected.hp_damage, ability_id + " forecast honors declared physical power")
		check(forecast.damage_min == expected.hp_damage, ability_id + " displayed minimum is exact normal damage")
		check(forecast.damage_max == expected.crit_damage, ability_id + " displayed maximum is exact critical damage")
		check(forecast.get("crit_damage", -1) == expected.crit_damage, ability_id + " exposes exact critical damage")
		check(manager._predict_spell_damage(caster, target, ability) == expected.hp_damage, ability_id + " AI honors declared physical power")
		seed(12345)
		check(await manager._execute_ability(caster, target, ability), ability_id + " admitted")
		check(not last_result.get("missed", false), ability_id + " deterministic fixture hits")
		var expected_damage: int = expected.crit_damage if last_result.get("critical", false) else expected.hp_damage
		check(last_result.get("hp_damage", -1) == expected_damage, ability_id + " resolver honors declared physical power")
		check(2000 - target.hp == expected_damage, ability_id + " HP loss matches forecast outcome")
		check(caster.mp == 100 - int(ability.mp_cost), ability_id + " MP charged once")
		await manager._recover_action()
	target.hp = 2000
	target.temper = 65
	target.ether = 65
	target.statuses.clear()
	var basic_formula := CombatFormula.calculate_physical_attack(caster, target, {}, {})
	var basic_preview := ForecastCalculator.attack(caster, target, {}, {})
	check(basic_preview.damage_min == basic_formula.hp_damage, "basic attack displays exact normal damage")
	check(basic_preview.damage_max == basic_formula.crit_damage, "basic attack displays exact critical damage")
	var spell := AbilityDB.get_ability("thunder")
	var magic_formula := CombatFormula.calculate_magical_attack(caster, target, spell.spell_type, spell.base_power)
	var magic_preview := ForecastCalculator.spell(caster, target, spell)
	check(magic_preview.damage_min == magic_formula.hp_damage, "magic minimum has no fictional variance")
	check(magic_preview.damage_max == magic_formula.hp_damage, "magic maximum has no fictional variance")
	# Existing fixed contracts: positive support magnitude is not DoT; chain cost once.
	for sid in ["defending", "quickstep", "barrier"]:
		target.statuses.clear()
		target.hp = 2000
		var status := StatusEffect.new()
		status.status_id = sid
		status.magnitude = 60.0
		status.duration = 2
		target.statuses.append(status)
		target.tick_statuses()
		check(target.hp == 2000, sid + " magnitude is not DoT")
	caster.mp = 100
	target.hp = 2000
	target.statuses.clear()
	var chain := AbilityDB.get_ability("thunder").duplicate(true)
	check(await manager._execute_aoe_ability(caster, target.grid_pos, chain), "Thunder admitted")
	check(caster.mp == 100 - int(chain.mp_cost), "Thunder chain charges exactly one MP cost")
	await manager._recover_action()
	# A visible timeline must refresh during an action, not only next activation.
	for unit: Unit in manager.turn_order.units:
		unit.ct = 0
	caster.unit_data.base_stats.speed = 8
	target.unit_data.base_stats.speed = 12
	caster.ct = 90
	target.ct = 80
	caster.statuses.clear()
	manager.turn_order.timeline_updated.connect(func(order: Array):
		latest_timeline = order
		timeline_updates += 1)
	latest_timeline = manager.turn_order.get_projected_order()
	var original_order := latest_timeline.duplicate(true)
	var ct_before: Array = manager.turn_order.units.map(func(u): return u.ct)
	check(await manager._execute_ability(caster, caster, AbilityDB.get_ability("haste")), "Haste admitted while timeline visible")
	check(manager.turn_order.get_projected_order() != original_order, "Haste fixture changes upcoming order")
	check(timeline_updates == 1 and latest_timeline == manager.turn_order.get_projected_order(), "Haste refreshes visible timeline immediately")
	check(ct_before == manager.turn_order.units.map(func(u): return u.ct), "Haste timeline refresh does not advance CT")
	await manager._recover_action()
	caster.remove_status("haste")
	check(timeline_updates == 2 and latest_timeline == original_order, "removing Haste refreshes visible timeline immediately")
	manager._try_apply_status(target, {"id": "slow", "duration": 1})
	check(timeline_updates == 3 and latest_timeline == manager.turn_order.get_projected_order(), "Slow refreshes visible timeline immediately")
	target.tick_statuses()
	check(timeline_updates == 4 and latest_timeline == manager.turn_order.get_projected_order(), "speed status expiry refreshes visible timeline immediately")
	check(ct_before == manager.turn_order.units.map(func(u): return u.ct), "status apply/remove/expiry never advances CT")
	# Defend lasts through the waiting interval, clears next turn and can be chosen again.
	caster.statuses.clear()
	caster.hp = 300
	caster.temper = 0
	check(await manager._execute_ability(caster, caster, AbilityDB.get_ability("defend")), "first Defend admitted")
	await manager._recover_action()
	caster.end_turn()
	check(caster.has_status("defending"), "first Defend protects waiting interval")
	caster.begin_turn()
	check(not caster.has_status("defending"), "Defend expires at next own turn")
	check(await manager._execute_ability(caster, caster, AbilityDB.get_ability("defend")), "consecutive Defend admitted")
	await manager._recover_action()
	caster.end_turn()
	check(caster.has_status("defending"), "consecutive Defend protects second waiting interval")
	check(caster.receive_damage(66, "physical").hp_damage == 33, "enemy hit after consecutive Defend is halved")
	battle.queue_free()
	await get_tree().process_frame
	print("Combat execution: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
