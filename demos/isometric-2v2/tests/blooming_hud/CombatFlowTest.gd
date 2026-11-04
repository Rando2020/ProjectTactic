extends Node
var checks := 0
var failures := 0
var capture_dir := ""
func capture(label: String) -> void:
	if capture_dir.is_empty(): return
	if DisplayServer.get_name() == "headless":
		check(false, "capture requires a real rendering display")
		return
	for i in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label + ".png")) == OK, "save actual engine capture " + label)
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func press(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().process_frame
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
	Engine.time_scale = 4
	var battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
	add_child(battle)
	var manager = battle.battle_manager
	var ui = battle.battle_ui
	var selection = ui._selection
	for i in 1000:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().create_timer(0.025).timeout
	check(not ui._intro_banner.visible, "Blooming avoids duplicate intro banner overlapping objective and hint")
	selection.select_unit("Enemy_1")
	await capture("enemy-inspection")
	check(selection._inspect.is_visible_in_tree(), "Blooming exposes selected enemy inspection")
	selection.select_unit(manager.active_unit_id)
	check(selection._help.text.contains("Choose a command"), "selected ally hint describes available commands")
	var actor = manager.units[manager.active_unit_id]
	var start: Vector2i = actor.grid_pos
	ui._on_move()
	var destination: Vector2i = manager.tactical_grid.move_tiles[0]
	selection.set_cursor(destination)
	selection.activate_cursor()
	check(actor.grid_pos == start and not manager.is_resolving_action, "first target click only stages move")
	check(ui._preview_actor_label.text.begins_with("UNIT"), "move forecast labels unit rather than attacker")
	check(ui._preview_target_label.text.begins_with("DESTINATION"), "move forecast labels destination")
	check(not ui._preview_amount_label.visible and not ui._preview_hit_label.visible and not ui._preview_crit_label.visible, "move forecast omits damage hit and JP fields")
	check(ui._preview_panel.size.y <= 180 and ui._preview_panel.size.x <= 680, "movement review stays compact")
	check(not ui._bloom_objective_panel.get_rect().intersects(ui._bloom_hint.get_rect()), "objective and hint do not overlap")
	await capture("move-review")
	check(ui._confirm_btn.is_visible_in_tree() and not ui._confirm_btn.disabled, "staged move has explicit confirmation")
	if actor.grid_pos == start:
		selection.set_cursor(start)
		check(selection.cursor_cell == destination, "review freezes target while pointer moves")
		selection.activate_cursor()
		check(actor.grid_pos == start, "repeated target click cannot commit")
		selection.select_unit("Enemy_1")
		check(manager.active_command.is_empty() and not ui._confirm_btn.visible, "changing selection cancels review and targeting")
		selection.select_unit(actor.unit_id)
		ui._on_move()
		selection.set_cursor(destination)
		selection.activate_cursor()
		selection.go_back()
		check(manager.active_command == "move" and not ui._confirm_btn.visible, "cancel review returns aiming without spending move")
		check(not ui._preview_mode_label.text.begins_with("REVIEW"), "cancel review restores aiming forecast title")
		selection.activate_cursor()
		ui._on_confirm()
		ui._on_confirm()
	for i in 1000:
		if not manager.is_resolving_action: break
		await get_tree().create_timer(0.025).timeout
	selection.refresh()
	check(actor.grid_pos == destination and manager.active_unit_has_moved, "confirmation commits real move once")
	selection.go_back()
	selection.select_unit(actor.unit_id)
	var old_facing: String = actor.facing
	ui._on_wait()
	check(manager.active_unit_id == actor.unit_id and manager.current_phase == BattleManager.Phase.PLAYER_TURN, "Wait opens facing choice without ending turn")
	await capture("wait-facing")
	ui._on_attack()
	check(manager.active_command.is_empty(), "command shortcuts cannot bypass facing choice")
	if selection.has_method("choose_facing"):
		for i in 5: await get_tree().process_frame
		await press(KEY_RIGHT)
		check(ui.get_viewport().gui_get_focus_owner() == selection._facing_row.get_child(1), "Right from North focuses East, never End turn")
		await press(KEY_ENTER)
		check(selection._chosen_facing == "E" and selection._waiting_facing, "Enter on facing chooses direction without ending turn")
		selection.choose_facing("N")
		check(actor.facing == old_facing, "facing choice is only a preview before confirmation")
		selection.go_back()
		check(actor.facing == old_facing and selection.can_command(), "cancel facing preserves actor and turn")
		ui._on_wait()
		selection.choose_facing("E")
		ui._on_confirm()
		check(actor.facing == "E", "confirmed Wait applies chosen facing")
	await get_tree().process_frame
	for i in 2000:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN and not manager.is_resolving_action: break
		await get_tree().create_timer(0.025).timeout
	battle.queue_free()
	await get_tree().create_timer(2).timeout
	print("Blooming combat flow: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
