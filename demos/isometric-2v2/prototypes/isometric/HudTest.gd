extends Node
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var battle := preload("res://prototypes/isometric/Battle.tscn").instantiate()
	add_child(battle)
	await get_tree().process_frame
	await get_tree().process_frame
	var ui: BattleUI = battle.battle_ui
	var manager: BattleManager = battle.battle_manager
	check(not ui._loadout_panel.visible, "hide empty campaign loadout")
	check(not ui._temper_label.visible and not ui._ether_label.visible, "compact HP MP only")
	check(ui._right_panel_scroll.size.x <= 400, "compact rail reserves board space")
	check(ui._cancel_btn.get_parent() == ui._chapel_command_buttons, "Cancel is in fixed command dock")
	check(ui._preview_panel.get_parent() == ui, "forecast independent of scroll rail")
	for i in 200:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().create_timer(0.025).timeout
	ui._preview_panel.size.y = 1000
	manager.select_command("move")
	manager._on_tile_hovered(Vector2i(2,3))
	await get_tree().process_frame
	await get_tree().process_frame
	check(ui._preview_panel.visible, "hover shows actual forecast")
	check(ui._preview_panel.size.y <= 480, "forecast shrinks stale expanded panel to compact contents")
	await manager._on_tile_clicked(Vector2i(2,3))
	check(not ui._preview_panel.visible, "completed move clears stale forecast")
	manager.select_ability("fire")
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	ui._unhandled_input(event)
	check(manager.active_command.is_empty() and not ui._preview_panel.visible, "Escape cancels targeting not settings")
	battle.queue_free()
	await get_tree().create_timer(2.0).timeout
	print("Isometric HUD: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
