extends Node

var checks := 0
var failures := 0
var logs: Array[String] = []
var outcomes: Array[Dictionary] = []
var detached_vfx: Node

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func enemy(manager: BattleManager, archetype: String) -> Unit:
	for unit: Unit in manager.units.values():
		if unit.get_meta("archetype_id", "") == archetype:
			return unit
	return null

func make_battle() -> Node:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	for unit: Unit in manager.units.values():
		unit.unit_data = unit.unit_data.duplicate(true)
		unit.grid_pos = Vector2i(0, 0)
		unit.hp = 2000
		unit.unit_data.base_stats.hp = 2000
		unit.unit_data.base_stats.physical_resistance = 0
		unit.unit_data.base_stats.magic_resistance = 0
		unit.temper = 0
		unit.ether = 0
		unit.statuses.clear()
	var actor: Unit = manager.units.zane
	actor.grid_pos = Vector2i(3, 4)
	actor.mp = 100
	actor.unit_data.abilities.assign(["pin_shot", "eagle_eye", "void_pulse", "blizzard", "fire", "haste", "cure", "smoke_screen"])
	enemy(manager, "storm_imp").grid_pos = Vector2i(5, 4)
	enemy(manager, "null_drake").grid_pos = Vector2i(6, 4)
	for pos in [actor.grid_pos, Vector2i(5, 4), Vector2i(6, 4)]:
		manager.tactical_grid.tiles[pos]["height"] = 0
	manager.current_phase = BattleManager.Phase.PLAYER_TURN
	manager.active_unit_id = actor.unit_id
	manager.active_unit_has_acted = false
	manager.active_unit_has_moved = false
	manager.log_message.connect(func(message: String): logs.append(message))
	manager.combat_resolver.combat_resolved.connect(func(outcome: Dictionary): outcomes.append(outcome))
	logs.clear()
	outcomes.clear()
	return battle

func dispose(battle: Node) -> void:
	await battle.battle_manager._recover_action()
	battle.queue_free()
	await get_tree().process_frame

func blind(unit: Unit) -> void:
	var status := StatusEffect.new()
	status.status_id = "blind"
	status.duration = 5
	unit.apply_status(status)

# Search the engine's seeded RNG, not a substitute combat resolver. The same
# first roll is then consumed by the real action. VFX alone is detached because
# its cosmetic randomness is irrelevant to this deterministic combat fixture.
func seed_rolls(first_misses: bool, second_misses: bool = false, pair: bool = false) -> void:
	for candidate in range(10000):
		seed(candidate)
		var first := randi_range(1, 100)
		var second := randi_range(1, 100)
		if (first > 65) == first_misses and (not pair or (second > 65) == second_misses):
			seed(candidate)
			return
	check(false, "deterministic RNG fixture found")

func player_cast(manager: BattleManager, ability_id: String, target: Unit) -> void:
	manager.select_ability(ability_id)
	check(manager.selected_ability_id == ability_id, ability_id + " admitted through real selection")
	await manager._on_unit_clicked(target.unit_id)
	check(manager.active_unit_has_acted, ability_id + " spends the real player action")
	check(not manager.active_unit_has_moved, ability_id + " leaves movement available")
	check(not manager.is_resolving_action and manager.action_lifecycle.phase == "idle", ability_id + " recovers normal action lifecycle")

# Breaks caught: unconditional status-on-miss, damage>0 gating, shared AoE hit
# outcome, a second accuracy roll, lost action/MP cost, or false status logs.
func run() -> void:
	detached_vfx = get_tree().root.get_node("VFX")
	get_tree().root.remove_child(detached_vfx)
	for fixture in [
		{"id": "pin_shot", "status": "slow", "cost": 0},
		{"id": "eagle_eye", "status": "blind", "cost": 10},
		{"id": "void_pulse", "status": "silence", "cost": 12},
	]:
		await check_single_miss(fixture)
	await check_area_mixed()
	await check_chain_mixed()
	await check_zero_power_chain_miss()
	await check_hit_from_same_roll()
	await check_readiness_exceptions()
	check_forecast_wording()
	await check_zero_damage_hit("void_pulse", "silence", true)
	await check_zero_damage_hit("pin_shot", "slow", false)
	await check_support()
	await check_ground_on_miss()
	get_tree().root.add_child(detached_vfx)
	print("Hit secondary status: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func check_single_miss(fixture: Dictionary) -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var target := enemy(manager, "storm_imp")
	blind(actor)
	seed_rolls(true)
	await player_cast(manager, fixture.id, target)
	check(outcomes.size() == 1 and outcomes[0].get("missed", false), fixture.id + " actual resolver misses once")
	check(actor.mp == 100 - fixture.cost, fixture.id + " miss pays exact normal MP")
	check(target.hp == 2000 and target.temper == 0 and target.ether == 0, fixture.id + " miss changes no HP or armor")
	check(not target.has_status(fixture.status), fixture.id + " miss applies no secondary status")
	check(not str(logs).contains("is now"), fixture.id + " miss never claims status application")
	if fixture.id == "void_pulse":
		check(logs.has("Zane casts Void Pulse on Storm Imp! MISS (0 HP)"), "magical miss keeps truthful outcome log")
	# A spent miss cannot be selected again or charged a second time this turn.
	manager.select_ability(fixture.id)
	check(manager.selected_ability_id.is_empty() and actor.mp == 100 - fixture.cost, fixture.id + " spent action cannot repeat")
	await dispose(battle)

func check_area_mixed() -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var primary := enemy(manager, "storm_imp")
	var targets := manager._get_aoe_targets(primary.grid_pos, AbilityDB.get_ability("blizzard"), actor)
	check(targets.size() == 2, "Blizzard cross contains two actual enemies")
	blind(actor)
	seed_rolls(true, false, true)
	await player_cast(manager, "blizzard", primary)
	check(actor.mp == 88, "Blizzard costs 12 MP once for two recipients")
	check(outcomes.size() == 2 and outcomes[0].get("missed", false) and not outcomes[1].get("missed", false), "area uses distinct actual miss/hit outcomes")
	check(not targets[0].has_status("slow"), "area missed recipient gets no Slow")
	check(targets[1].has_status("slow"), "area hit recipient still gets Slow")
	check(not logs.has("%s is now SLOW!" % targets[0].display_name), "area logs no status for missed recipient")
	check(logs.count("%s is now SLOW!" % targets[1].display_name) == 1, "area logs exactly one applied status")
	await dispose(battle)

func check_chain_mixed() -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var primary := enemy(manager, "storm_imp")
	var secondary := enemy(manager, "null_drake")
	# No authored chain currently carries a status. Retain the established
	# feedback suite's injected Slow to protect generic chain dispatch.
	var ability := AbilityDB.get_ability("thunderstrike")
	ability["status_effect"] = {"id": "slow", "duration": 2}
	blind(actor)
	seed_rolls(true, false, true)
	manager.active_unit_has_acted = await manager._execute_aoe_ability(actor, primary.grid_pos, ability)
	await manager._finish_player_action()
	check(manager.active_unit_has_acted and actor.mp == 86, "mixed chain spends action and 14 MP exactly once")
	check(outcomes.size() == 2 and outcomes[0].get("missed", false) and not outcomes[1].get("missed", false), "chain uses each hop's real miss/hit")
	check(primary.hp == 2000 and not primary.has_status("slow"), "missed chain primary has no damage or status")
	check(secondary.hp == 1970 and secondary.has_status("slow"), "hit chain secondary retains 30 damage and status")
	check(logs.has("Storm Imp: MISS (0 HP)") and logs.has("arcs to Null Drake: -30 HP"), "chain feedback retains actual per-target outcomes")
	check(not logs.has("Storm Imp is now SLOW!") and logs.count("Null Drake is now SLOW!") == 1, "chain claims only applied status")
	await dispose(battle)

func check_zero_damage_hit(ability_id: String, status_id: String, affinity_immune: bool) -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var target := enemy(manager, "storm_imp")
	if affinity_immune:
		target.unit_data.elemental_affinities.dark = 0.0
	else:
		target.unit_data.base_stats.physical_resistance = 1000
		target.facing = "E" # back attack guarantees physical hit
	seed_rolls(false)
	await player_cast(manager, ability_id, target)
	check(outcomes.size() == 1 and not outcomes[0].get("missed", false) and outcomes[0].applied_hp_damage == 0, ability_id + " hit with zero actual damage is not a miss")
	check(target.hp == 2000 and target.has_status(status_id), ability_id + " zero-damage hit still applies authored status")
	check(logs.count("Storm Imp is now %s!" % status_id.to_upper()) == 1, ability_id + " zero-damage hit logs actual status once")
	if affinity_immune:
		check(logs.has("Zane casts Void Pulse on Storm Imp! IMMUNE to damage (0 HP)"), "immunity feedback remains truthful")
	var status: StatusEffect = target.statuses.filter(func(s): return s.status_id == status_id)[0]
	check(status.duration == 2, ability_id + " authored duration remains 2")
	target.tick_statuses()
	check(target.has_status(status_id) and status.duration == 1, ability_id + " status survives first tick")
	target.tick_statuses()
	check(not target.has_status(status_id), ability_id + " status expires on second tick")
	await dispose(battle)

func check_support() -> void:
	for fixture in [{"id": "haste", "cost": 10}, {"id": "cure", "cost": 8}, {"id": "smoke_screen", "cost": 15}]:
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var actor: Unit = manager.units.zane
		var target: Unit = enemy(manager, "storm_imp") if fixture.id == "smoke_screen" else manager.units.kael
		if fixture.id != "smoke_screen":
			target.grid_pos = Vector2i(3, 5)
		blind(actor)
		target.hp = 1500
		seed_rolls(true)
		await player_cast(manager, fixture.id, target)
		check(actor.mp == 100 - fixture.cost, fixture.id + " support pays normal MP")
		if fixture.id == "haste":
			check(target.has_status("haste") and outcomes.is_empty(), "pure buff bypasses damaging hit gate")
		elif fixture.id == "cure":
			check(target.hp == 1580 and outcomes[0].healed == 80, "Cure keeps real healing value while blinded")
		else:
			check(outcomes[0].get("missed", false) and target.has_status("blind"), "zero-power pure status action keeps legacy unconditional status")
		await dispose(battle)

func check_ground_on_miss() -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var primary := enemy(manager, "storm_imp")
	manager.tactical_grid.tiles[primary.grid_pos]["terrain"] = "grass"
	blind(actor)
	seed_rolls(true)
	await player_cast(manager, "fire", primary)
	check(outcomes[0].get("missed", false) and not primary.has_status("burn"), "Fire miss has no direct authored Burn")
	check(manager.tactical_grid.get_tile(primary.grid_pos).get("terrain", "") == "burning", "Fire miss preserves existing ground ignition")
	await dispose(battle)

func check_hit_from_same_roll() -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var target := enemy(manager, "storm_imp")
	blind(actor)
	seed_rolls(false, true, true)
	await player_cast(manager, "void_pulse", target)
	check(not outcomes[0].get("missed", false) and target.has_status("silence"), "secondary uses actual successful resolver hit, not next would-miss roll")
	await dispose(battle)

func check_zero_power_chain_miss() -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var actor: Unit = manager.units.zane
	var primary := enemy(manager, "storm_imp")
	var secondary := enemy(manager, "null_drake")
	var ability := AbilityDB.get_ability("thunderstrike")
	ability["base_power"] = 1
	ability["status_effect"] = {"id": "slow", "duration": 2}
	blind(actor)
	seed_rolls(true, true, true)
	manager.active_unit_has_acted = await manager._execute_aoe_ability(actor, primary.grid_pos, ability)
	await manager._finish_player_action()
	check(manager.active_unit_has_acted and actor.mp == 86, "rounded-zero chain retains normal action and cost")
	check(outcomes.size() == 2 and outcomes[0].get("missed", false) and outcomes[1].get("missed", false), "rounded-zero chain fixture actually misses both hops")
	check(not primary.has_status("slow") and not secondary.has_status("slow"), "falloff to zero power does not reclassify damaging chain as pure status")
	await dispose(battle)

func check_readiness_exceptions() -> void:
	for fixture in [
		{"id": "blaze_counter", "status": "blaze_counter_ready", "preserve": true},
		{"id": "arc_counter", "status": "arc_counter_ready", "preserve": true},
		{"id": "void_pulse", "status": "other_counter_ready", "preserve": false},
	]:
		var battle := make_battle()
		var manager: BattleManager = battle.battle_manager
		var actor: Unit = manager.units.zane
		var target := enemy(manager, "storm_imp")
		var ability := AbilityDB.get_ability(fixture.id)
		if not fixture.preserve:
			ability["status_effect"] = {"id": fixture.status, "duration": 2}
		blind(actor)
		seed_rolls(true)
		manager.active_unit_has_acted = await manager._execute_ability(actor, target, ability)
		await manager._finish_player_action()
		check(outcomes[0].get("missed", false), fixture.id + " readiness fixture actually misses")
		check(target.has_status(fixture.status) == fixture.preserve, fixture.status + " only the two approved readiness effects preserve legacy application")
		check(manager.active_unit_has_acted and actor.mp == (100 if fixture.preserve else 88), fixture.id + " readiness fixture keeps action and cost")
		await dispose(battle)

func check_forecast_wording() -> void:
	for ability_id in ["pin_shot", "eagle_eye", "void_pulse", "fire", "blizzard"]:
		var preview := ForecastCalculator._status_preview(AbilityDB.get_ability(ability_id))
		check(preview.to_lower().contains("on hit"), ability_id + " forecast identifies hit-conditioned status")
		check(not preview.contains("%"), ability_id + " status preview invents no independent probability")
	for ability_id in ["haste", "protect", "smoke_screen", "blaze_counter", "arc_counter"]:
		check(not ForecastCalculator._status_preview(AbilityDB.get_ability(ability_id)).to_lower().contains("on hit"), ability_id + " non-hit-gated effect has no on-hit claim")
