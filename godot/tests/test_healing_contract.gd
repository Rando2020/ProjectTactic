extends Node

var checks := 0
var failures := 0
var hp_signals := 0
var resolved_signals := 0
var status_signals := 0
var last_result: Dictionary = {}

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func unit_snapshot(unit: Unit) -> Dictionary:
	var meta := {}
	for key in unit.get_meta_list():
		meta[key] = unit.get_meta(key)
	var stats := {}
	for property in unit.unit_data.base_stats.get_property_list():
		if property.usage & PROPERTY_USAGE_STORAGE and property.name != "script":
			stats[property.name] = unit.unit_data.base_stats.get(property.name)
	var statuses := []
	for status: StatusEffect in unit.statuses:
		statuses.append([status.status_id, status.duration, status.magnitude, status.damage_type])
	return {"hp": unit.hp, "mp": unit.mp, "temper": unit.temper, "ether": unit.ether,
		"ct": unit.ct, "acted": unit.has_acted, "moved": unit.has_moved,
		"defeated": unit.is_defeated, "facing": unit.facing, "position": unit.grid_pos,
		"stats": stats, "statuses": statuses, "meta": meta.duplicate(true)}

func snapshot(manager: BattleManager) -> Dictionary:
	var units := {}
	for uid in manager.units:
		units[uid] = unit_snapshot(manager.units[uid])
	return {"units": units, "run": GameState.active_run.to_dict().duplicate(true),
		"registry": GameState.unit_registry.duplicate(true), "gold": GameState.gold,
		"jp": GameState.run_jp_earned, "save": FileAccess.get_sha256(GameState.SAVE_PATH),
		"preview_state": [manager.active_unit_id, manager.selected_ability_id,
			manager.tactical_grid.ability_tiles.duplicate(), manager.tactical_grid.aoe_preview_tiles.duplicate()],
		"counters": [manager._ruinous_hit_counter, manager._wrath_crescendo_stacks,
			manager._iron_momentum_primed, manager.active_unit_has_acted, manager.active_command],
		"signals": [hp_signals, resolved_signals, status_signals],
		"effects": [VFX.get_child_count(), AudioSettings.get_child_count(),
			get_tree().get_processed_tweens().size()]}

func run() -> void:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	var caster: Unit = manager.units.mira
	var target: Unit = manager.units.kael
	var outside: Unit = manager.units.zane
	var enemy: Unit
	for unit: Unit in manager.units.values():
		unit.unit_data = unit.unit_data.duplicate(true)
		unit.unit_data.base_stats.hp = 2000
		unit.hp = 100
		unit.mp = 100
		unit.statuses.clear()
		unit.grid_pos = Vector2i(9, 9)
		unit.hp_changed.connect(func(_id, _hp, _max): hp_signals += 1)
		unit.status_applied.connect(func(_id, _status): status_signals += 1)
		unit.status_removed.connect(func(_id, _status): status_signals += 1)
		if unit.team == "enemy" and enemy == null:
			enemy = unit
	caster.grid_pos = Vector2i(3, 3)
	target.grid_pos = Vector2i(3, 2)
	manager.combat_resolver.combat_resolved.connect(func(result: Dictionary):
		last_result = result
		resolved_signals += 1)
	GameState.active_run = RunState.new()
	var boons := BoonSystem.new()
	var light := boons.get_boon("luminarch_light").duplicate(true)
	var one_shot: Dictionary = {}
	for boon: Dictionary in BoonSystem.BOONS:
		if boon.get("effect", {}).get("type", "") == "once_per_battle":
			one_shot = boon.duplicate(true)
			break
	check(not one_shot.is_empty(), "fixture loads authored one-shot boon")
	check(not light.is_empty(), "fixture loads authored Luminarch's Light")
	# Real one-shot/tactical state must survive previews, even while primed.
	caster.set_meta("phoenix_used", false)
	target.set_meta("first_hit_guard_used", false)
	manager._iron_momentum_primed = true
	manager._ruinous_hit_counter = 2
	manager._wrath_crescendo_stacks = 3
	var save := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	save.store_string("healing-preview-must-not-write-this-save")
	save.close()
	# Break caught: magic-scaled forecasts or uncapped headline amounts disagree
	# with authored flat execution. Expected numbers are literal balance fixtures.
	for fixture in [["cure", 80, 8], ["cura", 130, 14], ["mass_cure", 60, 40]]:
		var ability := AbilityDB.get_ability(fixture[0])
		for modifier in [[0, []], [15, [light]], [30, [light, light]]]:
			GameState.active_run.active_boons = modifier[1].duplicate(true)
			GameState.active_run.active_boons.append(one_shot)
			for magic in [0, 54, 200]:
				caster.unit_data.base_stats.magic = magic
				for hp_case in [[100, int(fixture[1]) + int(modifier[0])], [1995, 5], [2000, 0]]:
					target.hp = hp_case[0]
					var expected: int = hp_case[1]
					var label := "%s magic=%d bonus=%d hp=%d" % [fixture[0], magic, modifier[0], hp_case[0]]
					manager.active_unit_id = caster.unit_id
					manager.tactical_grid.ability_tiles.assign([target.grid_pos])
					var before := snapshot(manager)
					seed(61024)
					var next_random := randi()
					seed(61024)
					var preview := ForecastCalculator.spell(caster, target, ability)
					var decorated := manager._ability_preview_for_tile(target.grid_pos, ability)
					for repeat in range(4):
						check(ForecastCalculator.spell(caster, target, ability) == preview and manager._ability_preview_for_tile(target.grid_pos, ability) == decorated, label + " repeat raw and displayed previews deterministic")
					var intent := manager._enemy_intent_details(caster, "heal", target, ability)
					check(randi() == next_random, label + " preview does not consume RNG")
					check(snapshot(manager) == before, label + " previews preserve units, run, counters, save, MP, signals and effects")
					check(preview.heal == expected, label + " forecast reports capped flat healing")
					check(decorated.get("heal", -1) == expected and decorated.get("hp_after", -1) == int(hp_case[0]) + expected, label + " displayed targeted preview preserves amount and final HP")
					check(not str(decorated.get("modifier_breakdown", [])).contains("Boon Holy") and not str(decorated.get("run_bonus_notes", [])).contains("Holy"), label + " displayed targeted heal excludes damage-only holy note")
					check(preview.hp_after == int(hp_case[0]) + expected, label + " projected HP matches flat healing")
					check(intent.damage == -expected and intent.target_hp_after == int(hp_case[0]) + expected, label + " enemy detail uses same heal and cap")
					check(preview.damage == 0 and preview.mp_cost == fixture[2], label + " healing keeps damage and authored MP fields")
					check(preview.boon_mult == 1.0 and preview.boon_bonus_pct == 0, label + " heal preview does not advertise holy damage scaling")
					check(not str(preview.modifier_breakdown).contains("Boon Holy"), label + " heal explanation excludes damage-only modifier")
					var execution: Dictionary = await manager._execute_ability_with_result(caster, target, ability, true)
					check(execution.executed and execution.outcome == {"healed": expected}, label + " real heal preserves result shape and balance")
					check(target.hp == int(hp_case[0]) + expected, label + " actual HP matches forecast")
					check(hp_signals == int(before.signals[0]) + 1 and resolved_signals == int(before.signals[1]) + 1, label + " execution retains HP and resolver signals")
					var heal_numbers := 0
					for effect: Node in VFX.get_children().slice(int(before.effects[0])):
						if effect is Label and effect.text == str(expected):
							heal_numbers += 1
					check(heal_numbers == 1 and AudioSettings.get_child_count() == int(before.effects[1]) + 1, label + " execution retains exactly one heal number and sound")
					check([manager._ruinous_hit_counter, manager._wrath_crescendo_stacks, manager._iron_momentum_primed] == before.counters.slice(0, 3), label + " execution does not consume attack-only counters")
		# Fully admitted single-target casts retain their cost; no area/setup bypass.
		if fixture[0] != "mass_cure":
			target.hp = 100
			caster.mp = 100
			GameState.active_run.active_boons = [light]
			var execution: Dictionary = await manager._execute_ability_with_result(caster, target, ability)
			check(execution.executed and execution.outcome.healed == int(fixture[1]) + 15, str(fixture[0]) + " admitted cast restores unchanged amount")
			check(caster.mp == 100 - int(fixture[2]), str(fixture[0]) + " admitted cast spends authored MP once")
			await manager._recover_action()
	# Mass Cure's existing radius-2 diamond and team filter must stay unchanged.
	var mass := AbilityDB.get_ability("mass_cure")
	var center := Vector2i(3, 2)
	caster.grid_pos = Vector2i(3, 4) # edge: distance 2, included
	target.grid_pos = center
	outside.grid_pos = Vector2i(5, 3) # distance 3, excluded
	enemy.grid_pos = Vector2i(4, 2) # in footprint, wrong team
	for unit in [caster, target, outside, enemy]:
		unit.hp = 100
	caster.mp = 100
	GameState.active_run.active_boons = [light]
	var area_targets := manager._get_aoe_targets(center, mass, caster)
	check(area_targets.size() == 2 and caster in area_targets and target in area_targets, "Mass Cure retains radius-2 allied footprint including caster at edge")
	check(manager._aoe_tiles(center, mass, caster).size() == 13, "Mass Cure retains 13-tile diamond")
	check(await manager._execute_aoe_ability(caster, center, mass), "actual Mass Cure area cast admitted")
	check(caster.hp == 175 and target.hp == 175 and outside.hp == 100 and enemy.hp == 100, "actual Mass Cure heals only in-area allies for 60+15")
	check(caster.mp == 60, "Mass Cure charges 40 MP exactly once for all targets")
	await manager._recover_action()
	# Existing statuses have no heal multiplier or cleanse effect in this runtime.
	for status_id in ["blessed", "protect", "defending", "burn", "silence"]:
		var status := StatusEffect.new()
		status.status_id = status_id
		status.duration = 2
		target.statuses.append(status)
	target.hp = 100
	var status_before: Array = unit_snapshot(target).statuses
	var preview := ForecastCalculator.spell(caster, target, AbilityDB.get_ability("cure"))
	var result := manager.combat_resolver.resolve_heal(caster, target, 80)
	check(preview.heal == 95 and result.healed == 95, "recipient statuses neither scale nor block existing Cure healing")
	check(unit_snapshot(target).statuses == status_before, "healing does not cleanse, consume or tick recipient statuses")
	# Preserve rejection rules rather than invent resurrection or Silence bypass.
	target.hp = 0
	caster.mp = 100
	check(not await manager._execute_ability(caster, target, AbilityDB.get_ability("cure")), "Cure still rejects a defeated target")
	check(target.hp == 0 and caster.mp == 100, "rejected Cure has no resurrection or MP cost")
	var silence := StatusEffect.new()
	silence.status_id = "silence"
	silence.duration = 2
	caster.statuses.append(silence)
	target.hp = 100
	check(not await manager._execute_ability(caster, target, AbilityDB.get_ability("cure")), "silenced caster still cannot use Cure")
	check(target.hp == 100 and caster.mp == 100, "silenced Cure changes no HP or MP")
	GameState.active_run = null
	await get_tree().create_timer(1.5).timeout
	battle.queue_free()
	await get_tree().process_frame
	print("Healing contract: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
