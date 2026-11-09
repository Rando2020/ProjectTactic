extends Node
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	var script = load("res://prototypes/blooming/BloomingHUD.gd")
	if script == null:
		print("Blooming HUD layout: FAIL: implementation absent")
		get_tree().quit(1)
		return
	var ui = script.new()
	add_child(ui)
	await get_tree().process_frame
	check(ui.has_method("_make_selection_controller"), "selection adapter seam")
	var selection = ui._make_selection_controller()
	check(selection.has_method("layout_popup"), "anchored selection adapter")
	selection.free()
	for size in [Vector2(1280,720), Vector2(1920,1080), Vector2(960,540)]:
		get_window().content_scale_size = size
		get_window().size = size
		await get_tree().process_frame
		for collapsed in [false,true]:
			ui.set_tester_collapsed(collapsed)
			ui._layout_persistent_hud()
			await get_tree().process_frame
			var area: Rect2 = ui.gameplay_rect(size)
			check(area.size.x > 400, "gameplay area remains usable")
			for panel in [ui._bloom_objective_panel, ui._bloom_active_panel,ui._bloom_turn_strip,ui._chapel_command_panel]:
				check(area.encloses(panel.get_rect()), "HUD stays inside gameplay area at %s: %s %s" % [size,panel.name,panel.get_rect()])
			check(ui._right_panel_scroll.visible == not collapsed, "rail collapse visibility")
			ui._ability_panel.show()
			ui._proof_skills_panel.show()
			ui._preview_panel.show()
			ui._layout_forecast()
			await get_tree().process_frame
			check(not ui._proof_skills_panel.get_rect().intersects(ui._preview_panel.get_rect()), "skills and forecast must not overlap")
			check(area.encloses(ui._proof_skills_panel.get_rect()), "skills contained")
			check(area.encloses(ui._preview_panel.get_rect()), "forecast contained")
			ui._ability_panel.hide()
			ui._preview_panel.hide()
	check(ui._preview_note_label.max_lines_visible == -1, "forecast rules are never ellipsized")
	get_window().content_scale_size = Vector2i(1920,1080)
	get_window().size = Vector2i(1920,1080)
	await get_tree().process_frame
	ui._proof_skills_panel.hide()
	ui._layout_forecast()
	check(ui._preview_panel.position.y > 128, "forecast docks below board actors")
	check(ui._objective_label.size.y >= 20, "objective has readable line height")
	check(ui._turn_portraits.visible == false, "legacy vertical timeline hidden")
	check(ui._move_btn.get_parent() == ui._bloom_command_row, "real Move button reused")
	check(ui._ability_btn.get_parent() == ui._bloom_command_row, "real Skills button reused")
	print("Blooming HUD layout: ", "PASS" if failures == 0 else "FAIL %d" % failures)
	get_tree().quit(0 if failures == 0 else 1)
