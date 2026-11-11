extends Node
## Real battle timeline: detailed identity, uniform geometry, unchanged scheduler.
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func frames(count: int = 5) -> void:
	for i in count: await get_tree().process_frame
func _ready() -> void: run.call_deferred()
func assert_timeline(ui, manager) -> void:
	var expected: Array[String] = [manager.active_unit_id]
	for entry in manager.turn_order.get_projected_order(4): expected.append(entry.unit_id)
	for i in expected.size():
		var row: Dictionary = ui._turn_rows[i]
		var unit = manager.units[expected[i]]
		check(row.unit_id == expected[i], "timeline preserves scheduler slot %d" % i)
		check(row.portrait.texture == ui._status_portrait(unit.unit_data.id), "timeline uses matching detailed/fallback portrait for " + expected[i])
		check(row.when.text.begins_with("NOW" if i == 0 else str(i)), "slot label remains current/future")
		check(row.panel.tooltip_text.contains(unit.display_name), "tooltip preserves unit identity")
func assert_geometry(ui, viewport: Vector2i) -> void:
	var first: Control = ui._turn_rows[0].panel
	for row in ui._turn_rows:
		check(row.panel.size.is_equal_approx(first.size), "all timeline frames are equal: %s vs %s" % [row.panel.size,first.size])
		var label: Label = row.when
		var width := label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
		check(label.size.x >= width, "full turn/target label fits")
		check(row.panel.get_global_rect().encloses(row.portrait.get_global_rect()), "portrait fits frame")
		check(not row.portrait.get_global_rect().intersects(label.get_global_rect()), "portrait and turn label stay separate")
	check(ui.gameplay_rect(viewport).encloses(ui._bloom_turn_strip.get_rect()), "timeline stays in gameplay area")
	check(not ui._bloom_turn_strip.get_rect().intersects(ui._bloom_objective_panel.get_rect()), "timeline stays clear of objective")
func run() -> void:
	var battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
	add_child(battle)
	await frames(20)
	var ui = battle.battle_ui
	var manager = battle.battle_manager
	var settings = load("res://scripts/ui/UISettings.gd").shared()
	for compact in [true,false,true]:
		battle.set_compact_skins(compact)
		await frames()
		assert_timeline(ui,manager)
	for viewport in [Vector2i(960,540),Vector2i(1366,768),Vector2i(1920,1080)]:
		get_window().content_scale_size = viewport
		get_window().size = viewport
		for mode in [1,2,3,1]:
			settings.set_mode(mode,false)
			for collapsed in [false,true]:
				ui.set_tester_collapsed(collapsed)
				for affected in [false,true]:
					ui._preview_affected = {"zane":{"role":"target"},"Enemy_1":{"role":"affected"}} if affected else {}
					ui._refresh_preview_connections()
					ui._layout_persistent_hud()
					await frames()
					assert_geometry(ui,viewport)
					check(ui._turn_rows[0].panel.get_theme_stylebox("panel").border_width_left >= 2, "active frame retains distinct border")
	ui._clear_preview_connections()
	ui._selection.select_unit(manager.active_unit_id)
	ui._on_wait()
	ui._on_confirm()
	for i in 1000:
		if manager.active_unit_id == "kael" and manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().create_timer(0.025).timeout
	await frames()
	check(manager.active_unit_id == "kael", "real wait advances to Kael")
	assert_timeline(ui,manager)
	assert_geometry(ui,Vector2i(1920,1080))
	battle.queue_free()
	await frames()
	print("Courtyard timeline portraits: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
