extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+label)
func _ready() -> void: call_deferred("run")
func key(code: Key, echo := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	get_viewport().push_input(event)
	await get_tree().process_frame
func run() -> void:
	GameState.begin_illustrated_chapel_practice()
	GameState.practice_session["rotatable_stage"] = false
	var battle = preload("res://prototypes/isometric/Skirmish.tscn").instantiate()
	get_tree().root.add_child(battle)
	get_tree().current_scene = battle
	for i in 1000:
		if battle.battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().create_timer(0.025).timeout
	var manager = battle.battle_manager
	var grid = battle.tactical_grid
	var ui = battle.battle_ui
	var hp: int = manager.units.zane.hp
	var mp: int = manager.units.zane.mp
	var order = manager.turn_order.get_projected_order(4).duplicate(true)
	check(not grid.rotatable_mode,"fresh battle retains painted default")
	check(battle._rotate_left.visible and battle._rotate_right.visible,"painted stage exposes rotation buttons")
	check(battle._angle_label.text.contains("switch + rotate"),"painted stage explains mode switch")
	await key(KEY_E)
	print("Actual viewport E from painted: mode=",grid.rotatable_mode," quarter=",grid.quarter_turn)
	check(grid.rotatable_mode and grid.quarter_turn==1,"E from painted activates and rotates stage")
	await key(KEY_Q)
	check(grid.rotatable_mode and grid.quarter_turn==0,"Q reverses rotation")
	await key(KEY_E,true)
	check(grid.quarter_turn==0,"key repeat does not spin stage")
	ui._selection.select_unit("zane")
	ui._move_btn.grab_focus()
	await key(KEY_E)
	check(grid.quarter_turn==1,"Q/E works with command button keyboard focus")
	check(ui._selection.selected_id=="zane","rotation preserves selected unit")
	ui._on_ability()
	await get_tree().process_frame
	await get_tree().process_frame
	await key(KEY_E)
	check(grid.quarter_turn==2,"Q/E works with focused skills list")
	manager.select_ability("fire")
	ui._selection.refresh()
	var cell: Vector2i = ui._selection.cursor_cell
	await key(KEY_E)
	check(grid.quarter_turn==3,"Q/E works while choosing a spell target")
	check(manager.active_command=="ability_target" and ui._selection.cursor_cell==cell,"targeting and logical cursor preserved")
	await key(KEY_ESCAPE)
	await key(KEY_Q)
	check(grid.quarter_turn==2 and manager.active_command.is_empty(),"cancel then rotate stays responsive")
	ui._settings_overlay.show()
	await key(KEY_E)
	check(grid.quarter_turn==2,"settings modal prevents battlefield shortcut")
	ui._settings_overlay.hide()
	manager.is_resolving_action = true
	await key(KEY_E)
	check(grid.quarter_turn==2,"active action blocks rotation")
	manager.is_resolving_action = false
	battle.set_stage_mode(false)
	manager.is_resolving_action = true
	await key(KEY_E)
	check(not grid.rotatable_mode,"active action cannot switch stage")
	manager.is_resolving_action = false
	battle._rotate_left.pressed.emit()
	check(grid.rotatable_mode,"visible rotation button activates stage")
	check(battle._rotate_left.visible and battle._rotate_right.visible,"rotation buttons remain discoverable")
	check(manager.units.zane.hp==hp and manager.units.zane.mp==mp,"rotation spends no resources")
	check(manager.turn_order.get_projected_order(4)==order,"rotation preserves turn order")
	battle.queue_free()
	await get_tree().create_timer(1).timeout
	print("RotationInputTest: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
