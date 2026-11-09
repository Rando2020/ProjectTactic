extends Node

var checks := 0
var failures := 0
var manager: BattleManager
var ui: BattleUI
var scout: Unit
var enemy: Unit
var interrupt_kind := ""
var last_result: Dictionary = {}
var turns_ended := 0
var offered: Array = []
var latest_preview: Dictionary = {}
var latest_hint := ""

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func reset_turn() -> void:
	manager.current_phase = BattleManager.Phase.PLAYER_TURN
	manager.active_unit_id = scout.unit_id
	manager.active_unit_has_moved = false
	manager.active_unit_has_acted = false
	scout.begin_turn()
	scout.grid_pos = Vector2i(1, 4)
	scout.mp = 30
	scout.hp = scout.unit_data.base_stats.hp
	scout.statuses.clear()
	enemy.hp = 2000
	enemy.temper = 0
	enemy.ether = 0
	enemy.statuses.clear()
	enemy.facing = "E"
	manager.cancel_pending_action()

func on_admission(_move: bool, _act: bool, _pending: bool) -> void:
	if not manager.is_resolving_action or interrupt_kind.is_empty():
		return
	var kind := interrupt_kind
	interrupt_kind = ""
	if kind == "range":
		enemy.grid_pos = scout.grid_pos + Vector2i(2, 0)
	elif kind == "mp":
		scout.mp = 4
	elif kind == "acted":
		manager.active_unit_has_acted = true
	elif kind == "turn":
		manager.current_phase = BattleManager.Phase.ENEMY_TURN
		manager.active_unit_id = enemy.unit_id
	elif kind == "new_turn":
		manager._begin_player_turn()
		manager.active_unit_has_moved = true
		scout.has_moved = true
	elif kind == "free":
		scout.queue_free()
	elif kind == "access":
		scout.unit_data.abilities.assign(["long_shot"])

func test_long_shot() -> void:
	var shot := AbilityDB.get_ability("long_shot")
	check(shot.get("min_range", -1) == 3 and shot.range == 5, "Long Shot exposes canonical 3–5 range")
	check(AbilityDB.get_ability("not-an-ability").is_empty(), "unknown ID remains truly empty")
	var db: RefCounted = AbilityDB.new()
	check(db.has_method("get_range"), "range aliases have one shared normalizer")
	if db.has_method("get_range"):
		check(db.call("get_range", {"min_range": 2, "range": 4, "attack_range_min": 3, "attack_range_max": 8}) == Vector2i(2, 4), "canonical fields take precedence over aliases")
		check(db.call("get_range", {"attack_range_min": 3, "attack_range_max": 5}) == Vector2i(3, 5), "alias-only ranges normalize without retuning")
		check(db.call("get_range", {"range": 0}) == Vector2i(0, 0), "self range remains zero")
		check(db.call("get_range", {"range": 4}) == Vector2i(1, 4), "ordinary player range defaults to one")
	for distance in [1, 2, 3, 5, 6]:
		reset_turn()
		enemy.grid_pos = scout.grid_pos + Vector2i(distance, 0)
		var legal: bool = distance in [3, 5]
		manager.select_ability("long_shot")
		check((enemy.grid_pos in manager.tactical_grid.ability_tiles) == legal, "Long Shot highlights legal distance %d" % distance)
		var preview := manager._ability_preview_for_tile(enemy.grid_pos, shot)
		check((not preview.is_empty()) == legal, "Long Shot forecast agrees at distance %d" % distance)
		check(manager._ability_target_in_range(scout, enemy, shot) == legal, "shared range agrees at distance %d" % distance)
		# Real tile-click signal forwards occupied tiles through unit input.
		manager.tactical_grid.tile_clicked.emit(enemy.grid_pos)
		await settle()
		check((enemy.hp < 2000) == legal, "player target click respects dead zone at distance %d" % distance)
		check(manager.active_unit_has_acted == legal and scout.mp == 30, "only a legal Long Shot consumes action; remains free at distance %d" % distance)
		if legal:
			check(preview.hit_pct == 100 and not last_result.get("missed", false), "Long Shot fixture guarantees contact")
			var expected: int = preview.damage_max if last_result.get("critical", false) else preview.damage_min
			check(2000 - enemy.hp == expected, "Long Shot forecast matches realized damage at distance %d" % distance)
		# AI sees only the same target; all other player units are out of range.
		enemy.unit_data.abilities.assign(["long_shot"])
		enemy.mp = 30
		var intent := manager._enemy_intent(enemy, "spell", scout, "Long Shot", "fixture", shot)
		check(manager._enemy_intent_is_valid(enemy, intent) == legal, "AI intent agrees at distance %d" % distance)
		check((not manager._find_best_spell_intent(enemy).is_empty()) == legal, "AI selection agrees at distance %d" % distance)
		# Primary execution cannot bypass the range contract.
		enemy.hp = 2000
		var accepted: bool = await manager._execute_ability(scout, enemy, shot)
		check(accepted == legal, "direct primary contact respects distance %d" % distance)
		await manager._recover_action()
	reset_turn()
	enemy.grid_pos = scout.grid_pos + Vector2i(3, 0)
	manager.select_ability("long_shot")
	scout.grid_pos += Vector2i(2, 0)
	check(manager._ability_preview_for_tile(enemy.grid_pos, shot).is_empty(), "stale Long Shot highlight cannot preview a newly adjacent target")
	reset_turn()
	enemy.grid_pos = scout.grid_pos + Vector2i(3, 0)
	interrupt_kind = "range"
	var accepted: bool = await manager._execute_ability(scout, enemy, shot)
	check(not accepted and enemy.hp == 2000 and scout.mp == 30, "target entering dead zone during anticipation is rejected at contact")
	await manager._recover_action()

func ability_button(ability_name: String) -> Button:
	for button in ui._ability_list.get_children():
		if button.is_queued_for_deletion():
			continue
		for label: Label in button.find_children("*", "Label", true, false):
			if label.text == ability_name:
				return button as Button
	return null

func test_quickstep() -> void:
	var quickstep := AbilityDB.get_ability("quickstep")
	var original_abilities: Array[String] = scout.unit_data.abilities.duplicate()
	# Direct execution and actual menu share eligibility, before any cost/presentation.
	for scenario in ["early", "acted", "poor", "unequipped"]:
		reset_turn()
		manager.active_unit_has_moved = scenario != "early"
		scout.has_moved = manager.active_unit_has_moved
		manager.active_unit_has_acted = scenario == "acted"
		if scenario == "poor": scout.mp = 4
		if scenario == "unequipped": scout.unit_data.abilities.assign(["long_shot"])
		var mp_before := scout.mp
		var moved_before := manager.active_unit_has_moved
		var acted_before := manager.active_unit_has_acted
		if not acted_before:
			manager.select_command("ability")
			check("quickstep" not in offered, "Quickstep menu rejects " + scenario)
		var accepted: bool = await manager._execute_ability(scout, scout, quickstep)
		check(not accepted, "Quickstep execution rejects " + scenario)
		check(scout.mp == mp_before and manager.active_unit_has_moved == moved_before and manager.active_unit_has_acted == acted_before, "rejected Quickstep preserves MP and action state: " + scenario)
		check(not scout.has_status("quickstep"), "rejected Quickstep applies no status: " + scenario)
		await manager._recover_action()
		scout.unit_data.abilities = original_abilities.duplicate()
	# Private execution must not admit unsupported AI, other recipients or area hops.
	reset_turn()
	manager.active_unit_has_moved = true
	scout.has_moved = true
	for recipient in [enemy, scout]:
		var accepted: bool = await manager._execute_ability(scout, recipient, quickstep, recipient == scout)
		check(not accepted and scout.mp == 30 and not manager.active_unit_has_acted, "Quickstep rejects other target or secondary-hop invocation")
	check(not await manager._execute_ability(enemy, enemy, quickstep) and enemy.mp == 30, "Quickstep does not add unsupported enemy utility execution")
	# Recheck eligibility after asynchronous presentation, not just in the menu.
	for scenario in ["mp", "acted", "turn", "new_turn", "access"]:
		reset_turn()
		manager.active_unit_has_moved = true
		scout.has_moved = true
		interrupt_kind = scenario
		var accepted: bool = await manager._execute_ability(scout, scout, quickstep)
		check(not accepted and manager.active_unit_has_moved, "Quickstep contact rejects changed " + scenario)
		check(scout.mp == (4 if scenario == "mp" else 30) and not scout.has_status("quickstep"), "interrupted Quickstep has no added cost or status: " + scenario)
		await manager._recover_action()
		check(not manager.is_resolving_action and manager.action_lifecycle.phase == "idle", "interrupted Quickstep releases presentation: " + scenario)
		scout.unit_data.abilities = original_abilities.duplicate()
	reset_turn()
	manager.active_unit_has_moved = true
	scout.has_moved = true
	interrupt_kind = "acted"
	await manager.select_ability("quickstep")
	check(manager.active_unit_has_acted and manager.active_unit_has_moved and scout.mp == 30, "self-select failure never overwrites a consumed action during contact")
	reset_turn()
	var stats_before: Dictionary = {"speed": scout.unit_data.base_stats.speed, "move": scout.unit_data.base_stats.move, "physical": scout.unit_data.base_stats.physical}
	var speed_before := scout.get_effective_speed()
	var hp_before := scout.hp
	var status := StatusEffect.new()
	status.status_id = "guard_fixture"
	status.duration = 2
	scout.apply_status(status)
	manager._emit_action_state()
	ui._press_if_ready(ui._move_btn, ui._on_move)
	var first_destination: Vector2i = manager.tactical_grid.move_tiles[0]
	manager.tactical_grid.tile_clicked.emit(first_destination)
	await settle()
	check(manager.active_unit_has_moved and not manager.active_unit_has_acted, "real first move spends movement only")
	ui._press_if_ready(ui._ability_btn, ui._on_ability)
	await get_tree().process_frame
	var button := ability_button("Quickstep")
	check(button != null, "Quickstep becomes available after moving through actual UI")
	var forecast := ForecastCalculator.spell(scout, scout, quickstep)
	check(forecast.mp_cost == 5 and forecast.damage == 0 and forecast.jp_gain == 0, "Quickstep forecast shows actual MP/no damage/no JP")
	check(forecast.get("consumes_action", false) and forecast.get("movement_granted", 0) == 1, "Quickstep forecast exposes one movement for the action")
	check(not str(forecast.status_preview).contains("Applies:"), "Quickstep forecast does not promise a timed status")
	if button:
		button.mouse_entered.emit()
		check(latest_preview.get("consumes_action", false) and latest_preview.get("movement_granted", 0) == 1 and ui._preview_panel.visible, "actual ability hover shows Quickstep tradeoff forecast before spending")
		check(ui._preview_note_label.text.contains("5 MP"), "visible Quickstep forecast includes the MP cost")
		button.focus_entered.emit()
		check(latest_preview.get("mp_cost", -1) == 5, "keyboard focus shows same Quickstep cost forecast")
		check(button.tooltip_text.contains("action") and button.tooltip_text.contains("5"), "Quickstep button explains cost before immediate self-cast")
		button.pressed.emit()
		button.pressed.emit()
		manager.select_ability("quickstep")
		manager.select_command("wait")
		var reached_recovery := await wait_for_action_phase("recovery")
		check(reached_recovery, "Quickstep reaches real recovery before recovery-duplicate input")
		if reached_recovery:
			var recovery_ticket: int = manager.action_lifecycle.ticket
			var recovery_turns := turns_ended
			var recovery_pos := scout.grid_pos
			check(scout.mp == 25 and manager.active_unit_has_acted and not manager.active_unit_has_moved, "Quickstep commits one cost and movement grant before recovery")
			button.pressed.emit()
			manager.select_ability("quickstep")
			manager.select_command("wait")
			manager.select_command("move")
			manager.cancel_pending_action()
			manager.tactical_grid.tile_clicked.emit(first_destination)
			check(manager.is_resolving_action and manager.action_lifecycle.phase == "recovery" and manager.action_lifecycle.ticket == recovery_ticket, "recovery duplicates cannot restart or cancel the admitted lifecycle")
			check(scout.mp == 25 and manager.active_unit_has_acted and not manager.active_unit_has_moved and scout.has_acted and not scout.has_moved, "recovery duplicates spend no extra MP and refresh neither action nor movement")
			check(scout.grid_pos == recovery_pos and turns_ended == recovery_turns, "recovery duplicate Move/Wait/cancel inputs cannot move or end the turn")
		await settle()
		check(not manager.is_resolving_action and manager.action_lifecycle.phase == "idle" and manager.active_unit_id == scout.unit_id and manager.current_phase == BattleManager.Phase.PLAYER_TURN, "Quickstep recovery completes normally after duplicate inputs")
	check(scout.mp == 25, "repeated Quickstep clicks charge exactly 5 MP once")
	check(manager.active_unit_has_acted and not manager.active_unit_has_moved, "Quickstep consumes action and reopens movement, not attack")
	check(scout.has_acted and not scout.has_moved and not scout.can_act() and scout.can_move(), "Unit action gates agree with Quickstep manager state")
	check(scout.hp == hp_before and scout.get_effective_speed() == speed_before and not scout.has_status("quickstep"), "Quickstep changes no HP or speed and applies no stat status")
	check(scout.unit_data.base_stats.speed == stats_before.speed and scout.unit_data.base_stats.move == stats_before.move and scout.unit_data.base_stats.physical == stats_before.physical, "Quickstep never mutates base stats")
	check(status.duration == 2, "Quickstep does not prematurely tick owner statuses")
	check(not ui._move_btn.disabled and ui._attack_btn.disabled and ui._ability_btn.disabled, "UI offers Move/Wait but no attack or ability after Quickstep")
	manager.select_command("attack")
	check(manager.active_command != "attack", "Quickstep cannot recover an attack through direct command selection")
	var second_use: bool = await manager._execute_ability(scout, scout, quickstep)
	check(not second_use and scout.mp == 25 and manager.active_unit_has_acted, "repeated direct Quickstep cannot reset consumed action")
	ui._press_if_ready(ui._move_btn, ui._on_move)
	ui._press_if_ready(ui._cancel_btn, ui._on_cancel)
	check(scout.mp == 25 and manager.active_unit_has_acted and not manager.active_unit_has_moved, "cancelling second-move targeting does not refund action or consume remaining move")
	check(not latest_hint.contains("Attack") and not latest_hint.contains("Ability"), "post-Quickstep cancellation hint offers no spent action")
	ui._press_if_ready(ui._move_btn, ui._on_move)
	if not manager.tactical_grid.move_tiles.is_empty():
		var second_destination: Vector2i = manager.tactical_grid.move_tiles[0]
		var movement_preview := manager._move_preview(second_destination)
		check(movement_preview.get("ends_turn", false), "post-Quickstep movement forecast says the turn ends")
		var old_turns := turns_ended
		manager.tactical_grid.tile_clicked.emit(second_destination)
		manager.tactical_grid.tile_clicked.emit(first_destination)
		await settle()
		check(scout.grid_pos == second_destination and turns_ended == old_turns + 1, "one second movement ends exactly one turn despite repeated tile clicks")
		check(status.duration == 1, "normal owner end-turn expiry still ticks once")
		check(manager.active_unit_id == scout.unit_id and not manager.active_unit_has_acted and not manager.active_unit_has_moved and scout.can_act() and scout.can_move(), "next natural turn resets ordinary action and movement")
	else:
		check(false, "Quickstep supplies a legal second movement")
	# Waiting forfeits the reopened move, rather than banking it for a later turn.
	reset_turn()
	manager.active_unit_has_moved = true
	scout.has_moved = true
	await manager.select_ability("quickstep")
	var before_wait := turns_ended
	manager.select_command("wait")
	check(turns_ended == before_wait + 1 and not manager.active_unit_has_acted and not manager.active_unit_has_moved, "Wait ends Quickstep turn and starts ordinary next turn")
	var mp_after_wait := scout.mp
	await manager.select_ability("quickstep")
	check(scout.mp == mp_after_wait and not manager.active_unit_has_acted, "stale Quickstep callback cannot spend before moving on next turn")
	reset_turn()
	manager.active_unit_has_moved = true
	scout.has_moved = true
	scout.mp = 5
	var silence := StatusEffect.new()
	silence.status_id = "silence"
	silence.duration = 2
	scout.apply_status(silence)
	await manager.select_ability("quickstep")
	check(scout.mp == 0 and manager.active_unit_has_acted and not manager.active_unit_has_moved, "exactly 5 MP funds one physical Quickstep even under Silence")
	check(scout.has_status("silence") and silence.duration == 2, "Quickstep does not remove or prematurely expire Silence")

func wait_for_action_phase(expected: String) -> bool:
	var deadline := Time.get_ticks_msec() + 5000
	while manager.is_resolving_action and manager.action_lifecycle.phase != expected and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return manager.is_resolving_action and manager.action_lifecycle.phase == expected

func settle() -> void:
	for index in range(500):
		await get_tree().process_frame
		if not manager.is_resolving_action:
			return
	check(false, "action settled within fixture deadline")

func run() -> void:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	manager = battle.battle_manager
	ui = battle.get_node("BattleUI")
	scout = manager.units.lyra
	for unit: Unit in manager.units.values():
		unit.unit_data = unit.unit_data.duplicate(true)
		if unit.team == "enemy" and enemy == null:
			enemy = unit
		elif unit != scout:
			unit.grid_pos = Vector2i(9, 0)
	enemy.unit_data.base_stats.hp = 2000
	enemy.unit_data.base_stats.physical_resistance = 0
	for pos in manager.tactical_grid.tiles:
		manager.tactical_grid.tiles[pos]["height"] = 0
	manager.action_state_changed.connect(on_admission)
	manager.action_preview_changed.connect(func(preview: Dictionary): latest_preview = preview)
	manager.command_hint_changed.connect(func(hint: String): latest_hint = hint)
	manager.combat_resolver.combat_resolved.connect(func(result: Dictionary): last_result = result)
	await test_long_shot()
	for unit: Unit in manager.units.values():
		unit.unit_data.base_stats.speed = 0 if unit != scout else 6
		unit.ct = 0
	manager.turn_ended.connect(func(_id: String): turns_ended += 1)
	manager.ability_mode_started.connect(func(ids: Array): offered = ids)
	await test_quickstep()
	reset_turn()
	manager.active_unit_has_moved = true
	scout.has_moved = true
	interrupt_kind = "free"
	manager.select_ability("quickstep")
	await settle()
	check(not manager.active_unit_has_acted and manager.action_lifecycle.phase == "idle", "actor deletion during Quickstep leaves no consumed action or stuck lifecycle")
	battle.queue_free()
	await get_tree().process_frame
	print("Scout tradeoff: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
