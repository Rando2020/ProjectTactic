extends SceneTree
const Layout = preload("res://scripts/ui/BattleHudLayout.gd")
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	expect(Layout.right_sidebar_rect(Vector2(1920, 1080)).size.x >= 500, "1080p rail reserves readable text width")
	var script = load("res://scripts/ui/UISettings.gd")
	expect(script != null, "UI preference policy exists")
	if script == null:
		quit(1)
		return
	var prefs = script.new()
	prefs.settings_path = "user://ui-test.cfg"
	for malformed in [null, {}, "huge", -1, 99, 1.5]:
		prefs.set_mode(malformed, false)
		expect(prefs.mode == 0, "Malformed mode falls back to Auto")
		var bad_config := ConfigFile.new()
		bad_config.set_value("accessibility", "ui_size", malformed)
		bad_config.save(prefs.settings_path)
		prefs.load_settings()
		expect(prefs.mode == 0, "Malformed persisted value loads safely as Auto")
	prefs.set_mode(3)
	var restored = script.new()
	restored.settings_path = prefs.settings_path
	restored.load_settings()
	expect(restored.mode == 3, "UI preference roundtrips independently")
	prefs.set_mode(0, false)
	expect(is_equal_approx(prefs.effective_scale(Vector2(1920,1080)), 1.25), "Auto 1080p is 125 percent")
	expect(is_equal_approx(prefs.effective_scale(Vector2(3840,2160)), 1.5), "Auto native 4K is 150 percent")
	prefs.set_mode(3, false)
	expect(prefs.effective_scale(Vector2(1280,720)) <= 1.0, "Small viewport clamps extra large")
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 10)
	prefs.apply_tree(label, Vector2(1920,1080))
	expect(label.get_theme_font_size("font_size") == 24, "Tiny captions enlarged to readable baseline")
	prefs.apply_tree(label, Vector2(1920,1080))
	expect(label.get_theme_font_size("font_size") == 24, "Repeated apply does not compound")
	prefs.set_mode(1, false)
	prefs.apply_tree(label, Vector2(1920,1080))
	expect(label.get_theme_font_size("font_size") == 16, "Shrinking restores base typography")
	var icon_button := Button.new()
	icon_button.icon = load("res://assets/ui/appointed/move.svg")
	icon_button.add_theme_constant_override("icon_max_width", 24)
	prefs.set_mode(3, false)
	prefs.apply_tree(icon_button, Vector2(1920,1080))
	expect(icon_button.get_theme_constant("icon_max_width") == 36, "Command icons scale with text")
	icon_button.free()
	label.free()
	await _check_populated_loadout(script.shared())
	var hud = load("res://scripts/battle/BattleUI.gd").new()
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1920,1080)
	root.add_child(hud)
	await process_frame
	await process_frame
	expect(hud._objective_label.get_theme_font_size("font_size") >= 20, "Real HUD body is at least 20px at 1080p")
	expect(hud._right_panel_scroll.follow_focus, "HUD scroll follows keyboard focus")
	expect(hud._preview_panel.get_parent() == hud._right_panel_root, "Forecast stays within reserved rail")
	hud._toggle_settings_overlay()
	await process_frame
	var selector = hud._settings_overlay.find_child("UISizeSelector", true, false)
	expect(selector != null, "Battle settings exposes keyboard UI size selector")
	var shared = script.shared()
	for viewport_size in [Vector2i(1280,720), Vector2i(1328,861), Vector2i(1366,768), Vector2i(1920,1080), Vector2i(3840,2160)]:
		root.size = viewport_size
		for mode in range(4):
			shared.set_mode(mode, false)
			hud._on_timeline_updated([{"display_name": "Zane"}, {"display_name": "Storm Imp"}, {"display_name": "Void Cultist"}, {"display_name": "Kael"}, {"display_name": "Mira"}])
			hud._unit_name.text = "Kael • Ancient Warden of Ashvale"
			hud._on_action_preview_changed({"visible": true, "actor_name": "Kael • Ancient Warden", "target_name": "Guardian of the Hollow Descent", "ability_name": "A remarkably long ability display name", "hp_before": 9999, "hp_after": 999, "max_hp": 9999})
			hud._on_ability_mode_started(["fireball", "heal"])
			await process_frame
			await process_frame
			await process_frame
			for timeline_label in hud._timeline_labels:
				expect(timeline_label.get_line_count() == 1, "Native regression: full turn name stays on one readable line at %s: %s (%d lines)" % [viewport_size, timeline_label.text, timeline_label.get_line_count()])
			var rail: Rect2 = hud._right_panel_scroll.get_global_rect()
			expect(Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(rail), "Rail stays inside %s mode %d: %s" % [viewport_size, mode, rail])
			_check_horizontal(hud._right_panel_root, rail, "%s mode %d" % [viewport_size, mode])
			expect(Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(hud._loadout_panel.get_global_rect()), "Loadout remains anchored inside viewport")
			var ability_button: Button = hud._ability_list.get_child(hud._ability_list.get_child_count() - 1)
			ability_button.grab_focus()
			await process_frame
			await process_frame
			expect(rail.encloses(ability_button.get_global_rect()), "Keyboard focus scrolls full ability button into view")
			var select_rect: Rect2 = selector.get_global_rect()
			expect(Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(select_rect), "Settings selector stays onscreen")
			for button in [hud._move_btn, hud._attack_btn, hud._wait_btn, hud._ability_btn]:
				var text_width: float = button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
				var margins: float = button.get_theme_stylebox("normal").get_minimum_size().x
				expect(text_width + margins <= button.size.x, "Command text fits without clipping at %s" % viewport_size)
			selector.grab_focus()
			expect(root.gui_get_focus_owner() == selector, "Settings selector receives keyboard focus")
	hud._on_timeline_updated([{"unit_id": "imp_a", "display_name": "Storm Imp", "team": "enemy"}, {"unit_id": "imp_b", "display_name": "Storm Imp", "team": "enemy"}, {"unit_id": "imp_a", "display_name": "Storm Imp", "team": "enemy"}])
	expect(hud._timeline_labels[0].text.contains("Storm Imp #1"), "First same-name enemy has stable visible identifier")
	expect(hud._timeline_labels[1].text.contains("Storm Imp #2"), "Second same-name enemy is distinguishable")
	expect(hud._timeline_labels[2].text.contains("Storm Imp #1"), "Repeated turn retains the same unit identity")
	expect(hud._timeline_labels[1].tooltip_text.contains("imp_b"), "Full identity available in tooltip")
	shared.set_mode(0, false)
	hud.show_spoils({"gold": 10, "jp": 12}, [])
	await process_frame
	var continue_button: Button
	for candidate in hud._spoils_overlay.find_children("*", "Button", true, false):
		if candidate.text == "Continue": continue_button = candidate
	expect(continue_button != null and continue_button.get_theme_font_size("font_size") >= 20, "Dynamic spoils controls get readable type")
	hud.queue_free()
	await process_frame
	var start = load("res://scenes/StartScreen.tscn").instantiate()
	root.add_child(start)
	await process_frame
	expect(start.find_child("UISizeSelector", true, false) != null, "Title exposes UI size before combat")
	start.music_player.stop()
	start.queue_free()
	await process_frame
	var gs = root.get_node("GameState")
	gs.begin_practice()
	gs.practice_session["state"] = "lost"
	var results = load("res://scenes/ResultsScreen.tscn").instantiate()
	root.add_child(results)
	await process_frame
	expect(results.find_child("UISizeSelector", true, false) != null, "Results exposes UI size")
	for viewport_size in [Vector2i(1280,720), Vector2i(1920,1080), Vector2i(3840,2160)]:
		root.size = viewport_size
		for mode in range(4):
			shared.set_mode(mode, false)
			await process_frame
			await process_frame
			_check_horizontal(results, Rect2(Vector2.ZERO, Vector2(viewport_size)), "Results %s mode %d" % [viewport_size, mode])
	shared.set_mode(0, false)
	results.queue_free()
	await process_frame
	gs.leave_practice()
	gs.begin_practice()
	var battle = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	var comparison = battle.comparison_panel
	expect(comparison.find_child("UISizeSelector", true, false) != null, "Practice has UI size independent of world quality")
	var saved_session: Dictionary = gs.practice_session.duplicate(true)
	shared.set_mode(3, false)
	await process_frame
	expect(gs.practice_session == saved_session, "UI preference does not modify practice or High/Standard quality")
	shared.set_mode(0, false)
	battle.queue_free()
	await process_frame
	gs.leave_practice()
	await create_timer(0.1).timeout
	print("UI readability: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _check_horizontal(node: Node, rail: Rect2, context: String) -> void:
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		expect(rect.position.x >= rail.position.x - 1 and rect.end.x <= rail.end.x + 1, "%s fits rail: %s (%s within %s)" % [context, node.get_class(), rect, rail])
	for child in node.get_children():
		_check_horizontal(child, rail, context)

func _check_populated_loadout(prefs: RefCounted) -> void:
	var gs = root.get_node("GameState")
	var previous_run = gs.active_run
	for populated_boons in [false, true]:
		gs.active_run = RunState.new()
		if populated_boons:
			gs.active_run.active_boons = BoonSystem.BOONS.slice(0, 8).duplicate(true)
		root.content_scale_size = Vector2i.ZERO
		root.size = Vector2i(1366, 768)
		prefs.set_mode(0, false)
		var hud = load("res://scripts/battle/BattleUI.gd").new()
		root.add_child(hud)
		for frame in range(5): await process_frame
		expect(hud._loadout_items_box.get_child_count() >= 2, "Populated regression uses actual vow and sigil controls")
		for viewport_size in [Vector2i(1366,768), Vector2i(1920,1080), Vector2i(1280,720), Vector2i(3840,2160)]:
			root.size = viewport_size
			for mode in [0, 3, 1]:
				prefs.set_mode(mode, false)
				for button in hud._loadout_items_box.get_children():
					# Real mouse-entered callback uses the actual vow/sigil/boon description.
					button.mouse_entered.emit()
					for frame in range(5): await process_frame
					var rect: Rect2 = hud._loadout_panel.get_global_rect()
					expect(Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(rect), "Populated loadout after hover/scale stays inside %s mode %d: %s" % [viewport_size, mode, rect])
					expect(is_equal_approx(rect.end.y, viewport_size.y - 12), "Populated loadout retains bottom margin after content settles")
		hud.queue_free()
		await process_frame
	gs.active_run = previous_run
	prefs.set_mode(0, false)
