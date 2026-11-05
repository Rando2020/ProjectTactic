extends Node
## Regression: decorative GO badges must not eat board-target mouse input.
## All actions enter through Input.parse_input_event and the real GUI dispatch.
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	print("BADGE ", label, ": ", ok)
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
func click(point: Vector2) -> void:
	await hover(point)
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
	var manager = battle.battle_manager
	var ui = battle.battle_ui
	var selection = ui._selection
	var grid = battle.tactical_grid
	await frames(20)
	var actor = manager.units["zane"]
	check(actor.grid_pos == Vector2i(3,8) and actor.hp == 320 and actor.mp == 90, "fresh courtyard fixture")
	await key(KEY_ENTER)
	check(selection.selected_id == "zane", "real Enter selects active ally")
	print("BADGE viewport=", get_viewport().get_visible_rect(), " button=", ui._move_btn.get_global_rect())
	await click(ui._move_btn.get_global_rect().get_center())
	check(manager.active_command == "move", "real GUI click selects Move")
	var destination := Vector2i(4,8)
	var point: Vector2 = grid.get_global_transform_with_canvas() * grid._grid_to_local(destination)
	await hover(point)
	check(selection.cursor_cell == destination, "mouse hover targets legal destination")
	var badge: Label
	for child in grid.highlight_layer.get_children():
		if child is Label and child.text == "GO" and not child.is_queued_for_deletion(): badge = child
	check(is_instance_valid(badge), "hover renders GO badge")
	if is_instance_valid(badge):
		point = badge.get_global_transform_with_canvas() * (badge.size * 0.5)
		print("BADGE click viewport point=", point, " destination=", destination)
		await click(point)
		check(selection.has_review() and ui._confirm_btn.is_visible_in_tree(), "GO badge center click opens review")
		check(actor.grid_pos == Vector2i(3,8) and not manager.active_unit_has_moved and actor.mp == 90, "review spends no move or MP")
		if selection.has_review():
			await click(point)
			check(selection.has_review() and actor.grid_pos == Vector2i(3,8), "repeated badge click never commits")
			await click(ui._confirm_btn.get_global_rect().get_center())
			for i in 600:
				if not manager.is_resolving_action: break
				await get_tree().create_timer(0.025).timeout
			check(actor.grid_pos == destination and manager.active_unit_has_moved and not manager.active_unit_has_acted, "GUI Confirm commits one legal move")
			check(actor.hp == 320 and actor.mp == 90, "movement preserves combat resources")
	battle.queue_free()
	await get_tree().create_timer(1).timeout
	print("Badge input: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
