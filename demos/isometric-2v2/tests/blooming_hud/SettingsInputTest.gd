extends Node
## Regression: courtyard settings remain reachable without leaking combat input.
## All actions enter through Input.parse_input_event and the real GUI dispatch.
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	print("SETTINGS ", label, ": ", ok)
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func frames(count: int = 3) -> void:
	for i in count: await get_tree().process_frame
func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames()
func hover(point: Vector2) -> void:
	point = get_viewport().get_screen_transform() * point
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	Input.parse_input_event(event)
	await frames()
func click(point: Vector2, move_first: bool = true) -> void:
	if move_first: await hover(point)
	point = get_viewport().get_screen_transform() * point
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames()
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	get_window().size = Vector2i(1920,1080)
	var battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
	add_child(battle)
	await frames(20)
	var manager = battle.battle_manager
	var ui = battle.battle_ui
	var selection = ui._selection
	var actor = manager.units["zane"]
	check(selection.selected_id.is_empty() and not ui._settings_overlay.visible, "fresh board starts unselected with settings closed")
	await key(KEY_ESCAPE)
	check(ui._settings_overlay.visible, "Escape from unselected board opens existing settings")
	if ui._settings_overlay.visible:
		check(get_viewport().gui_get_focus_owner() == ui._ui_size_selector, "settings owns keyboard focus")
		await key(KEY_M)
		await key(KEY_S)
		await key(KEY_W)
		var volume_before: int = ui._audio_settings().music_volume
		await click(ui._music_slider.get_global_rect().get_center())
		check(ui._audio_settings().music_volume != volume_before and absi(ui._audio_settings().music_volume - 50) <= 2, "real mouse changes existing music-volume control")
		var point: Vector2 = battle.tactical_grid.get_global_transform_with_canvas() * battle.tactical_grid._grid_to_local(actor.grid_pos)
		await click(point)
		check(selection.selected_id.is_empty(), "settings backdrop blocks board clicks")
		check(ui._settings_overlay.get_index() == ui.get_child_count()-1, "settings modal stays above the persistent HUD")
		check(selection.selected_id.is_empty() and manager.active_command.is_empty() and actor.mp == 90, "settings keyboard cannot select or issue combat commands")
		# Close the settings modal without changing combat selection.
		await key(KEY_ESCAPE)
		check(not ui._settings_overlay.visible, "Escape closes settings from browse")
	await key(KEY_ENTER)
	check(selection.selected_id == "zane", "combat selection remains available after settings")
	await key(KEY_M)
	check(manager.active_command == "move", "movement shortcut remains available")
	await key(KEY_RIGHT)
	await key(KEY_ENTER)
	check(selection.has_review(), "movement target still opens review")
	await key(KEY_ESCAPE)
	check(not selection.has_review() and manager.active_command == "move" and not ui._settings_overlay.visible, "Escape cancels review before settings can open")
	await key(KEY_ESCAPE)
	check(manager.active_command.is_empty() and selection.selected_id == "zane" and not ui._settings_overlay.visible, "Escape from command returns to menu without opening settings")
	await key(KEY_ESCAPE)
	check(selection.selected_id.is_empty() and not ui._settings_overlay.visible, "Escape from selection returns to board without opening settings")
	await key(KEY_ESCAPE)
	check(ui._settings_overlay.visible, "next Escape opens settings again")
	if ui._settings_overlay.visible:
		var return_button: Button
		for button in ui._settings_overlay.find_children("*", "Button", true, false):
			if button.text == "Return": return_button = button
		check(is_instance_valid(return_button), "existing Return button is available")
		if is_instance_valid(return_button): await click(return_button.get_global_rect().get_center())
		check(not ui._settings_overlay.visible and selection.selected_id.is_empty(), "mouse Return closes settings without selecting a unit")
	check(actor.mp == 90 and not manager.active_unit_has_moved and not manager.active_unit_has_acted, "settings and cancellation preserve all combat resources")
	battle.queue_free()
	await get_tree().create_timer(1).timeout
	print("Settings input: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
