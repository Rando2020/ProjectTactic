extends Node

var checks := 0
var failures := 0
var latest_preview: Dictionary = {}

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	var ui: BattleUI = battle.get_node("BattleUI")
	var scout: Unit = manager.units.lyra
	var enemy: Unit
	for unit: Unit in manager.units.values():
		unit.unit_data = unit.unit_data.duplicate(true)
		unit.grid_pos = Vector2i(9, 0)
		if enemy == null and unit.team == "enemy":
			enemy = unit
	scout.grid_pos = Vector2i(1, 4)
	scout.hp = 10
	scout.mp = 30
	scout.begin_turn()
	scout.has_moved = true
	scout.set_meta("moved_this_turn", true)
	scout.set_meta("tiles_moved_this_turn", 3)
	enemy.grid_pos = Vector2i(4, 4)
	enemy.hp = 10
	enemy.temper = 100000
	enemy.unit_data.base_stats.physical_resistance = 100000
	manager.current_phase = BattleManager.Phase.PLAYER_TURN
	manager.active_unit_id = scout.unit_id
	manager.active_unit_has_moved = true
	manager.active_unit_has_acted = false
	manager._iron_momentum_primed = true
	GameState.active_run = RunState.new()
	var boons := BoonSystem.new()
	for id in ["battle_fury", "iron_momentum", "coup_de_grace", "cleaving_strikes", "piercing_rush", "jp_accelerator"]:
		var boon := boons.get_boon(id)
		check(not boon.is_empty(), "authored boon fixture exists: " + id)
		GameState.active_run.active_boons.append(boon.duplicate(true))
	var quickstep := AbilityDB.get_ability("quickstep")
	var shot := AbilityDB.get_ability("long_shot")
	check(AbilityDB.get_range(quickstep) == Vector2i.ZERO and AbilityDB.get_range(shot) == Vector2i(3, 5), "combined helpers retain Scout ranges")
	check(not AbilityDB.secondary_status_requires_hit(quickstep), "non-damaging movement is not a damaging secondary")
	var decorated_shot := shot.duplicate(true)
	decorated_shot["status_effect"] = {"id": "blind", "duration": 2}
	check(AbilityDB.secondary_status_requires_hit(decorated_shot) and AbilityDB.get_range(decorated_shot) == Vector2i(3, 5), "range normalization and hit predicate compose without changing either contract")
	manager.action_preview_changed.connect(func(preview: Dictionary): latest_preview = preview)
	manager._emit_action_state()
	manager.select_command("ability")
	await get_tree().process_frame
	var button: Button
	for child in ui._ability_list.get_children():
		if child.is_queued_for_deletion(): continue
		for label: Label in child.find_children("*", "Label", true, false):
			if label.text == "Quickstep": button = child as Button
	check(button != null, "real Quickstep menu remains available with active attack boons")
	if button:
		button.mouse_entered.emit()
		check(latest_preview.get("movement_granted", 0) == 1 and latest_preview.get("mp_cost", -1) == 5, "real hover retains one movement and five MP")
		check(not ui._preview_note_label.text.contains("Boon") and latest_preview.get("jp_gain", -1) == 0, "real hover does not advertise damage or JP bonuses")
	var before := [scout.hp, scout.mp, scout.has_moved, scout.has_acted, enemy.hp, enemy.temper,
		manager.active_unit_has_moved, manager.active_unit_has_acted, manager._iron_momentum_primed,
		GameState.active_run.to_dict().duplicate(true)]
	manager.tactical_grid.ability_tiles.assign([scout.grid_pos, enemy.grid_pos])
	seed(61024)
	var next_random := randi()
	seed(61024)
	var raw := ForecastCalculator.spell(scout, scout, quickstep)
	var preview := manager._ability_preview_for_tile(scout.grid_pos, quickstep)
	print("Quickstep decorated notes: ", preview.get("run_bonus_notes", []))
	check(preview.get("damage", -1) == 0 and preview.get("jp_gain", -1) == 0, "decorated Quickstep retains no damage and no JP")
	check(preview.get("run_bonus_notes", []).is_empty(), "generic decoration must not promise attack or JP bonuses for movement")
	check(preview.get("modifier_breakdown", []).is_empty(), "generic movement breakdown must not contain damage-only boon notes")
	check(preview.get("note", "") == raw.note and preview.get("movement_granted", 0) == 1 and preview.get("consumes_action", false), "decoration retains the exact action/movement tradeoff")
	for repeat in range(4):
		check(manager._ability_preview_for_tile(scout.grid_pos, quickstep) == preview, "repeated movement decoration is deterministic")
	check(randi() == next_random, "combined forecast does not consume RNG")
	check([scout.hp, scout.mp, scout.has_moved, scout.has_acted, enemy.hp, enemy.temper,
		manager.active_unit_has_moved, manager.active_unit_has_acted, manager._iron_momentum_primed,
		GameState.active_run.to_dict().duplicate(true)] == before, "preview preserves HP/MP/action/movement/run and primed damage-boon state")
	var attack := manager._ability_preview_for_tile(enemy.grid_pos, shot)
	check(attack.get("damage", -1) == 0, "resisted Long Shot control projects zero HP damage")
	for note in ["Battle Fury", "Iron Momentum", "Coup de Grace", "Cleave", "Piercing", "JP"]:
		check(str(attack.get("run_bonus_notes", [])).contains(note), "zero-HP-damage attack still retains applicable bonus context: " + note)
	var marked := manager._ability_preview_for_tile(enemy.grid_pos, decorated_shot)
	check(str(marked.get("status_preview", "")).begins_with("On hit:"), "combined Long Shot preview uses shared hit-secondary wording")
	battle.queue_free()
	await get_tree().process_frame
	print("Tactical contract integration: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
