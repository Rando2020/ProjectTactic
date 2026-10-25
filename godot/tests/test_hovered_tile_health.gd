extends Node

# Run only with isolated XDG data/config/cache. Edge fixtures below are NOT natural play.
var checks := 0
var failures: Array[String] = []
var hover_count := 0
var preview_count := 0
var info_count := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _ready() -> void:
	call_deferred("run")

func make_battle(duel: bool) -> BattleScene:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.practice_session.clear()
	check(GameState.begin_zane_duel_practice() if duel else GameState.begin_practice(), "isolated practice admission succeeds")
	if duel:
		GameState.practice_session["rig3d"] = true
	var battle := preload("res://scenes/Battle.tscn").instantiate() as BattleScene
	add_child(battle)
	for i in 120:
		if battle.battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	hover_count = 0
	preview_count = 0
	info_count = 0
	battle.tactical_grid.tile_hovered.connect(func(_pos: Vector2i) -> void: hover_count += 1)
	battle.battle_manager.action_preview_changed.connect(func(_preview: Dictionary) -> void: preview_count += 1)
	battle.battle_manager.tile_info_changed.connect(func(_text: String) -> void: info_count += 1)
	return battle

func inspect_tile(battle: BattleScene, pos: Vector2i) -> void:
	var grid := battle.tactical_grid
	var motion := InputEventMouseMotion.new()
	motion.position = grid.get_global_transform_with_canvas() * grid._grid_to_local(pos)
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	check(grid.selected_tile == pos and hover_count == 1, "one real viewport motion inspects the intended tile")

func check_hp(battle: BattleScene, unit: Unit, context: String) -> void:
	var actual := battle.battle_ui._tile_info_label.text
	var suffix := "%s %d/%d HP" % [unit.display_name, unit.hp, unit.unit_data.base_stats.hp]
	check(actual.ends_with(suffix), context + " shows authoritative live HP in the actual tile label; got " + actual)

func control_snapshot(battle: BattleScene) -> Dictionary:
	var manager := battle.battle_manager
	var grid := battle.tactical_grid
	var actor: Unit = manager.units[manager.active_unit_id]
	return {
		"command": manager.active_command, "ability": manager.selected_ability_id,
		"phase": manager.current_phase, "actor": manager.active_unit_id,
		"resolving": manager.is_resolving_action, "lifecycle": manager.action_lifecycle.phase,
		"ticket": manager.action_lifecycle.ticket,
		"acted": manager.active_unit_has_acted, "moved": manager.active_unit_has_moved,
		"actor_actions": [actor.has_acted, actor.has_moved],
		"actor_resources": [actor.hp, actor.mp, actor.temper, actor.ether, actor.ct, actor.grid_pos],
		"selection": grid.selected_tile, "target": grid.target_tile,
		"path": grid.path_preview_tiles.duplicate(), "aoe": grid.aoe_preview_tiles.duplicate(),
		"ranges": [grid.move_tiles.duplicate(), grid.attack_tiles.duplicate(), grid.ability_tiles.duplicate()],
		"preview_events": preview_count, "hover_events": hover_count,
		"run_rng": RunManager.rng.state,
	}

func check_unchanged(battle: BattleScene, before: Dictionary, context: String) -> void:
	check(control_snapshot(battle) == before, context + " preserves command/lifecycle/actions/resources/target/path/AoE/previews/RNG")

func dispose_battle(battle: BattleScene) -> void:
	battle.queue_free()
	await get_tree().process_frame
	GameState.leave_practice()
	await get_tree().create_timer(0.8).timeout

func real_fire() -> void:
	var battle := await make_battle(true)
	var manager := battle.battle_manager
	var zane: Unit = manager.units.zane
	var enemy: Unit = manager.units.Enemy_1
	check(manager.active_unit_id == "zane" and "fire" in zane.unit_data.abilities, "fresh duel naturally reaches Zane with ordinary Fire")
	manager.select_ability("fire")
	check(enemy.grid_pos in battle.tactical_grid.ability_tiles, "original Fire is legal from original duel spawns")
	inspect_tile(battle, enemy.grid_pos)
	check_hp(battle, enemy, "initial inspection")
	var hp_before := enemy.hp
	var mp_before := zane.mp
	var resolutions := {"count": 0}
	manager.combat_resolver.combat_resolved.connect(func(_result: Dictionary) -> void: resolutions.count += 1)
	battle.tactical_grid.tile_clicked.emit(enemy.grid_pos)
	for i in 300:
		if not manager.is_resolving_action: break
		await get_tree().create_timer(0.02).timeout
	check(not manager.is_resolving_action and resolutions.count == 1, "normal legal Fire completes exactly once")
	check(enemy.hp > 0 and enemy.hp < hp_before and zane.mp == mp_before - 12, "real Fire damages target and spends original 12 MP; no roll outcome is hardcoded")
	check(battle.tactical_grid.selected_tile == Vector2i(-1,-1), "ordinary action clears highlight selection")
	check_hp(battle, enemy, "same-cell Fire after highlight clearing")
	var before_heal := control_snapshot(battle)
	# Explicit post-action heal fixture proves the inspected cell survives cleared highlights.
	enemy.heal(10)
	check_hp(battle, enemy, "post-action heal with selection cleared")
	check_unchanged(battle, before_heal, "post-action heal notification")
	check(hover_count == 1, "Fire refresh does not synthesize another hover")
	await dispose_battle(battle)

func hp_and_occupancy_fixtures() -> void:
	var battle := await make_battle(true)
	var manager := battle.battle_manager
	var enemy: Unit = manager.units.Enemy_1
	manager.select_ability("fire")
	inspect_tile(battle, enemy.grid_pos)
	check(battle.tactical_grid.target_tile == enemy.grid_pos and not battle.tactical_grid.aoe_preview_tiles.is_empty(), "fixture starts with real Fire target lock and fan preview")
	var before := control_snapshot(battle)
	var armor := [enemy.mp, enemy.temper, enemy.ether]
	# Explicit deterministic Unit edge fixtures, not naturally played turns.
	enemy.receive_damage(20, "pure")
	check(enemy.hp == 70, "pure-damage fixture applies exactly twenty HP")
	check_hp(battle, enemy, "same-cell direct damage")
	check_unchanged(battle, before, "damage notification")
	seed(90210)
	var expected_next_random := randi()
	seed(90210)
	enemy.heal(10)
	check(randi() == expected_next_random, "heal display refresh consumes no global RNG")
	check(enemy.hp == 80, "heal fixture restores ten HP")
	check_hp(battle, enemy, "same-cell heal")
	check_unchanged(battle, before, "heal notification")
	var burn := StatusEffect.new()
	burn.status_id = "burn"
	burn.duration = 1
	burn.magnitude = 0.1
	enemy.apply_status(burn)
	enemy.tick_statuses()
	check(enemy.hp == 71 and not enemy.has_status("burn"), "real Burn tick loses nine HP and expires normally")
	check_hp(battle, enemy, "same-cell Burn tick")
	check_unchanged(battle, before, "Burn notification")
	check([enemy.mp, enemy.temper, enemy.ether] == armor, "HP-only fixtures leave target MP and armor intact")
	var inspected := enemy.grid_pos
	enemy.move_to(Vector2i(7,5))
	check(not battle.battle_ui._tile_info_label.text.contains(enemy.display_name), "moving out clears the inspected cell's occupant")
	check_unchanged(battle, before, "occupant move out")
	enemy.move_to(inspected)
	check_hp(battle, enemy, "moving back into inspected cell")
	check_unchanged(battle, before, "occupant move in")
	# PLAYER_TURN keeps the normal objective transition pending while we inspect synchronously.
	enemy.receive_damage(9999, "pure")
	check(enemy.hp == 0 and enemy.is_defeated, "lethal fixture follows ordinary defeat authority")
	check(not battle.battle_ui._tile_info_label.text.contains(enemy.display_name), "lethal HP clears occupant before death animation finishes")
	check_unchanged(battle, before, "lethal notification")
	check(hover_count == 1, "all edge fixtures retain exactly one real hover")
	await dispose_battle(battle)

func full_party_removal_fixture() -> void:
	var battle := await make_battle(false)
	var manager := battle.battle_manager
	var enemy: Unit = manager.units.Enemy_2
	check(manager.units.size() == 7, "ordinary practice retains full party and three enemies")
	enemy.heal(0)
	check(info_count == 0, "HP notification before any inspection does not invent a hovered tile")
	inspect_tile(battle, enemy.grid_pos)
	check_hp(battle, enemy, "full-party initial inspection")
	var before := control_snapshot(battle)
	# Explicit removal fixture: leave a freed unrelated registry entry to catch display cleanup mutations.
	var unrelated: Unit = manager.units.Enemy_3
	unrelated.free()
	var registry_keys := manager.units.keys()
	enemy.receive_damage(7, "pure")
	check_hp(battle, enemy, "full-party damage with unrelated freed registry entry")
	check(manager.units.keys() == registry_keys, "display refresh skips invalid entries without mutating registry")
	check_unchanged(battle, before, "full-party HP refresh")
	enemy.get_parent().remove_child(enemy)
	check(not battle.battle_ui._tile_info_label.text.contains(enemy.display_name), "tree removal clears still-living inspected occupant")
	check(manager.units.keys() == registry_keys, "removal refresh leaves registry ownership unchanged")
	check_unchanged(battle, before, "full-party removal refresh")
	enemy.free()
	await dispose_battle(battle)

func survival_boon_fixture() -> void:
	var battle := await make_battle(false)
	var zane: Unit = battle.battle_manager.units.zane
	inspect_tile(battle, zane.grid_pos)
	# Explicit existing-boon edge fixture, not a naturally earned boon or fight.
	GameState.active_run = RunState.new()
	for boon: Dictionary in BoonSystem.BOONS:
		if boon.id == "phoenix_vitality":
			GameState.active_run.active_boons.append(boon)
	var before := control_snapshot(battle)
	zane.receive_damage(9999, "pure")
	check(zane.hp == 1 and zane.has_meta("phoenix_used"), "existing survival handler supplies its final authoritative HP")
	check_hp(battle, zane, "post-defeat survival callback")
	check_unchanged(battle, before, "survival display notification")
	GameState.active_run = null
	await dispose_battle(battle)

func run() -> void:
	get_viewport().content_scale_size = Vector2i.ZERO
	get_viewport().size = Vector2i(1920,1080)
	await real_fire()
	await hp_and_occupancy_fixtures()
	await full_party_removal_fixture()
	await survival_boon_fixture()
	for voice in get_node("/root/AudioSettings").get_children():
		if voice is AudioStreamPlayer:
			voice.stop()
			voice.stream = null
			voice.queue_free()
	await get_tree().create_timer(0.25).timeout
	print("Hovered tile health: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
