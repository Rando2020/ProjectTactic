extends Node
var checks := 0
var failures := 0
var original_scene: Node
const BATTLE := "res://prototypes/isometric/Skirmish.tscn"
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _ready() -> void:
	call_deferred("run")
func verify_queue(ui, manager: BattleManager, label: String) -> void:
	check(ui._turn_rows[0].unit_id == manager.active_unit_id, label + " NOW is active actor")
	check(ui._turn_rows[0].when.text.begins_with("NOW"), label + " active label")
	var projected := manager.turn_order.get_projected_order(4)
	for i in projected.size():
		var row: Dictionary = ui._turn_rows[i+1]
		check(row.unit_id == projected[i].unit_id, label + " scheduler slot %d" % i)
		check(row.when.text.begins_with("NEXT %d" % (i+1)), label + " future label %d" % i)
		check(row.portrait.texture != null, label + " portrait %d" % i)
func wait_scene(path: String) -> bool:
	for i in 2000:
		if is_instance_valid(get_tree().current_scene) and get_tree().current_scene.scene_file_path == path: return true
		await get_tree().create_timer(0.025).timeout
	check(false, "transition to " + path)
	return false
func run() -> void:
	Engine.time_scale = 4
	original_scene = get_tree().current_scene
	get_tree().current_scene = null
	get_tree().change_scene_to_file.call_deferred(BATTLE)
	if not await wait_scene(BATTLE):
		get_tree().quit(1)
		return
	var battle := get_tree().current_scene as BattleScene
	var manager: BattleManager = battle.battle_manager
	var ui = battle.battle_ui
	for i in 1000:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().create_timer(0.025).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	check(ui._turn_portraits.is_visible_in_tree(), "portrait queue visible")
	check(not ui._timeline_labels[0].is_visible_in_tree(), "legacy text queue hidden")
	verify_queue(ui, manager, "initial")
	var scroll_rect: Rect2 = ui._right_panel_scroll.get_global_rect()
	for row in ui._turn_rows:
		check(scroll_rect.encloses(row.panel.get_global_rect()), "portrait row fits visible right rail")
		check(row.portrait.get_global_rect().size.x >= 48, "portrait keeps readable width")
	var speed_status := StatusEffect.new()
	speed_status.status_id = "haste"
	speed_status.duration = 3
	manager.units.kael.apply_status(speed_status)
	await get_tree().process_frame
	verify_queue(ui, manager, "haste")
	manager.units.kael.remove_status("haste")
	await get_tree().process_frame
	verify_queue(ui, manager, "status removed")
	var expected_next: String = ui._turn_rows[1].unit_id
	var observed: Array[String] = []
	manager.turn_started.connect(func(id: String, _team: String): observed.append(id))
	ui._selection.select_unit(manager.active_unit_id)
	ui._on_wait()
	for i in 2000:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN and manager.active_unit_id == "kael": break
		await get_tree().create_timer(0.025).timeout
	await get_tree().process_frame
	check(not observed.is_empty() and observed[0] == expected_next, "NEXT becomes actual next actor")
	verify_queue(ui, manager, "advanced")
	manager.units.Enemy_1.receive_damage(99999, "pure")
	await get_tree().process_frame
	verify_queue(ui, manager, "after KO")
	for row in ui._turn_rows:
		check(row.unit_id != "Enemy_1", "KO absent from queue")
	manager.units.Enemy_2.receive_damage(99999, "pure")
	manager._set_phase(BattleManager.Phase.CHECK_OBJECTIVE)
	if await wait_scene("res://scenes/ResultsScreen.tscn"):
		var retry: Button
		for candidate in get_tree().current_scene.find_children("*", "Button", true, false):
			if candidate.text == "Replay Fight": retry = candidate
		check(retry != null, "real Replay Fight available")
		if retry:
			retry.pressed.emit()
			if await wait_scene(BATTLE):
				battle = get_tree().current_scene as BattleScene
				manager = battle.battle_manager
				ui = battle.battle_ui
				for i in 1000:
					if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
					await get_tree().create_timer(0.025).timeout
				await get_tree().process_frame
				verify_queue(ui, manager, "replay")
				check(ui._turn_rows.size() == 5, "replay has exactly five fresh rows")
				check(manager.units.Enemy_1.hp > 0 and manager.units.Enemy_2.hp > 0, "replay restores defeated foes")
				var ids: Array[String] = []
				for row in ui._turn_rows: ids.append(row.unit_id)
				check(ids.has("Enemy_1") and ids.has("Enemy_2"), "restored foes return to portrait queue")
	if is_instance_valid(get_tree().current_scene): get_tree().current_scene.queue_free()
	get_tree().current_scene = original_scene
	await get_tree().create_timer(2).timeout
	print("Portrait turn order: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
