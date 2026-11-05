extends Node
## Regression: area-count decoration must not swallow spell retargeting input.
## All actions enter through Input.parse_input_event and the real GUI dispatch.
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	print("AOE ", label, ": ", ok)
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
	var manager = battle.battle_manager
	var ui = battle.battle_ui
	var selection = ui._selection
	var grid = battle.tactical_grid
	await frames(20)
	var actor = manager.units["zane"]
	await key(KEY_ENTER)
	await key(KEY_S)
	check(manager.active_command == "ability", "real shortcut opens Skills")
	var fire: Button
	for button in ui._ability_list.get_children():
		if button is Button:
			for label in button.find_children("*", "Label", true, false):
				if label.text == "Fire": fire = button
	check(is_instance_valid(fire), "Skills contains named Fire button")
	if not is_instance_valid(fire):
		get_tree().quit(1)
		return
	await click(fire.get_global_rect().get_center())
	check(manager.selected_ability_id == "fire" and manager.active_command == "ability_target", "real GUI click aims Fire")
	check(actor.grid_pos == Vector2i(3, 8) and actor.mp == 90, "fresh courtyard fixture")
	# Upper-left legal target keeps the area badge clear of the forecast panel.
	var initial := Vector2i(3, 6)
	await hover(grid.get_global_transform_with_canvas() * grid._grid_to_local(initial))
	check(selection.cursor_cell == initial, "hover establishes initial spell preview")
	var badge: Label
	for child in grid.highlight_layer.get_children():
		if child is Label and child.text.begins_with("AoE:") and not child.is_queued_for_deletion(): badge = child
	check(is_instance_valid(badge), "spell preview creates area-count badge")
	if is_instance_valid(badge):
		var point: Vector2 = badge.get_global_transform_with_canvas() * (badge.size * 0.5)
		print("AOE initial=",initial," badge=",badge.text," point=",point," pointed_cell=",selection._pointed_cell(point))
		check(not ui._preview_panel.get_global_rect().has_point(point), "badge test point is outside legitimate forecast UI")
		check(selection._pointed_cell(point) == Vector2i(4, 7), "badge covers the expected legal retarget cell")
		await hover(point)
		check(selection.cursor_cell == Vector2i(4,7), "pointer crosses area-count badge to the legal cell beneath")
		# Recreate the original decoration, then press directly on it, independently
		# of the successful hover transition above.
		await hover(grid.get_global_transform_with_canvas() * grid._grid_to_local(initial))
		await click(point, false)
		check(selection.has_review() and ui._confirm_btn.is_visible_in_tree(), "click through area-count decoration stages spell review")
		check(actor.mp == 90 and not manager.active_unit_has_acted and not manager.is_resolving_action, "area review does not spend or resolve")
		if selection.has_review():
			check(selection._review.cell == Vector2i(4,7), "review uses retargeted cell rather than stale preview")
			await key(KEY_ESCAPE)
			check(not selection.has_review() and manager.active_command == "ability_target" and actor.mp == 90, "Escape returns aiming without spending")
			await hover(grid.get_global_transform_with_canvas() * grid._grid_to_local(initial))
			await click(point, false)
			check(selection.has_review(), "area badge can be clicked again after cancelling")
			await click(ui._confirm_btn.get_global_rect().get_center())
			for i in 600:
				if not manager.is_resolving_action: break
				await get_tree().create_timer(0.025).timeout
			check(actor.mp == 78 and manager.active_unit_has_acted and not manager.is_resolving_action, "GUI Confirm spends Fire cost and one action exactly once")
	battle.queue_free()
	await get_tree().create_timer(1).timeout
	print("AoE input: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
