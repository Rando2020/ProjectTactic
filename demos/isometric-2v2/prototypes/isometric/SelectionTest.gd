extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+label)
func _ready() -> void:
	call_deferred("run")
func key(controller: Node, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	controller.handle_input(event)
func run() -> void:
	Engine.time_scale = 4
	var battle := preload("res://prototypes/isometric/Skirmish.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	var ui = battle.battle_ui
	var selection = ui._selection
	for i in 1000:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().create_timer(0.025).timeout
	await get_tree().process_frame
	check(manager.active_unit_id == "zane", "normal initiative starts Zane")
	check(selection.selected_id == "" and not ui._chapel_command_panel.visible, "commands hidden until explicit selection")
	check(selection.cursor_cell == manager.units.zane.grid_pos, "cursor starts on active unit")
	check(not battle.tactical_grid.is_processing_input(), "legacy pre-GUI click dispatcher disabled")
	var before: Vector2 = battle._battle_camera.position
	key(selection,KEY_RIGHT)
	check(selection.cursor_cell == Vector2i(2,3), "arrow moves grid cursor")
	check(battle._battle_camera.position == before, "cursor does not pan camera")
	key(selection,KEY_ENTER)
	check(selection.selected_id == "", "empty tile does not open commands")
	selection.select_unit("kael")
	check(selection.selected_id == "kael" and ui._chapel_command_panel.visible, "inactive ally inspect popup")
	check(not selection.can_command() and not ui._move_btn.visible, "inactive ally has no commands")
	ui._on_move()
	check(manager.active_command.is_empty() and manager.active_unit_id == "zane", "inactive unit cannot bypass turn")
	selection.select_unit("Enemy_1")
	check(selection._inspect.text.contains("Enemy") and not ui._attack_btn.visible, "enemy inspection only")
	selection.go_back()
	check(selection.selected_id.is_empty() and not ui._chapel_command_panel.visible, "close inspection")
	selection.set_cursor(manager.units.zane.grid_pos)
	key(selection,KEY_ENTER)
	check(selection.can_command() and ui._move_btn.visible, "confirm active unit opens command popup")
	selection.select_unit("zane")
	check(ui._chapel_command_panel.visible, "repeated unit selection stable")
	check(ui.get_viewport().gui_get_focus_owner() == ui._move_btn, "menu starts focused on available Move")
	key(selection,KEY_ENTER)
	check(manager.active_command == "move" and not ui._move_btn.visible and ui._cancel_btn.visible, "move enters target mode with back")
	selection.set_cursor(Vector2i(2,3))
	check(ui._preview_panel.visible, "cursor shows move forecast")
	var mp: int = manager.units.zane.mp
	selection.go_back()
	check(manager.active_command.is_empty() and not manager.active_unit_has_moved and manager.units.zane.mp == mp, "cancel move has no cost")
	check(selection.can_command() and ui._move_btn.visible, "cancel returns selected unit menu")
	ui._on_move()
	selection.set_cursor(manager.units.kael.grid_pos)
	selection.activate_cursor()
	check(manager.units.zane.grid_pos == Vector2i(1,3), "occupied destination rejected")
	var screen: Vector2 = battle.tactical_grid.get_global_transform_with_canvas() * battle.tactical_grid._grid_to_local(Vector2i(2,3))
	check(selection._pointed_cell(screen) == Vector2i(2,3), "move hit test uses ground despite overlapping sprite")
	selection.set_cursor(Vector2i(2,3))
	selection.activate_cursor()
	selection.activate_cursor()
	check(manager.is_resolving_action, "double movement gated during resolution")
	for i in 1000:
		if not manager.is_resolving_action: break
		await get_tree().create_timer(0.025).timeout
	await get_tree().process_frame
	selection.refresh()
	check(manager.units.zane.grid_pos == Vector2i(2,3) and manager.active_unit_has_moved, "legal cursor move commits once")
	check(selection.selected_id == "zane" and ui._chapel_command_panel.visible and ui._move_btn.disabled, "post-move menu retains selected actor and spent move")
	ui._on_attack()
	selection.set_cursor(manager.units.kael.grid_pos)
	selection.activate_cursor()
	check(not manager.active_unit_has_acted, "friendly attack target rejected")
	key(selection,KEY_ESCAPE)
	check(manager.active_command.is_empty() and not ui._preview_panel.visible, "Escape clears targeting and preview")
	ui._on_ability()
	check(ui._ability_panel.visible, "skills list shown from selected unit")
	selection.select_unit("Enemy_1")
	check(manager.active_command.is_empty() and not ui._ability_panel.visible, "changing selection closes pending skill menu")
	selection.select_unit("zane")
	ui._on_ability()
	selection.clear_selection()
	selection.select_unit("zane")
	check(manager.active_command.is_empty() and ui._move_btn.visible, "close skill menu never strands selection")
	ui._on_ability()
	manager.select_ability("fire")
	selection.refresh()
	check(selection.is_targeting() and not ui._ability_panel.visible, "skill selection enters target mode")
	selection.go_back()
	check(manager.units.zane.mp == mp and not manager.active_unit_has_acted, "cancel skill costs no MP/action")
	selection.go_back()
	check(selection.selected_id.is_empty() and not ui._chapel_command_panel.visible, "second back returns browse")
	ui._on_wait()
	check(manager.active_unit_id == "zane", "hidden wait callback cannot act unselected")
	selection.select_unit("zane")
	ui._on_wait()
	check(selection.selected_id.is_empty(), "end turn clears selection")
	for i in 2000:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN and manager.active_unit_id != "zane": break
		await get_tree().create_timer(0.025).timeout
	check(manager.active_unit_id == "kael" and selection.selected_id.is_empty(), "next ally requires own selection")
	selection.select_unit("kael")
	check(selection.can_command() and selection._header.text == "KAEL", "Kael commands open on his real turn")
	manager.units.kael.receive_damage(99999,"pure")
	check(selection.selected_id.is_empty(), "selected KO clears popup")
	battle.queue_free()
	await get_tree().create_timer(2).timeout
	print("Selection flow: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
