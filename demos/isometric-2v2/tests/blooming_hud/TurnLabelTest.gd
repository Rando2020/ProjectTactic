extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	var battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
	add_child(battle)
	for i in 20: await get_tree().process_frame
	var ui = battle.battle_ui
	var settings = load("res://scripts/ui/UISettings.gd").shared()
	for viewport in [Vector2i(960,540), Vector2i(1920,1080)]:
		get_window().content_scale_size = viewport
		get_window().size = viewport
		for mode in [1,2,3,1,3]:
			settings.set_mode(mode,false)
			for affected in [false,true]:
				ui._preview_affected = {"zane": {"role":"target"}} if affected else {}
				ui._refresh_preview_connections()
				ui._layout_persistent_hud()
				for i in 5: await get_tree().process_frame
				var label: Label = ui._turn_rows[0].when
				var width: float = label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
				check(label.text.begins_with("NOW"), "current turn remains NOW")
				check(label.size.x >= width, "complete current-turn label fits %s mode%d affected%s width%s/%s" % [viewport,mode,affected,width,label.size.x])
				check(ui.gameplay_rect(viewport).encloses(ui._bloom_turn_strip.get_rect()), "turn strip stays on board")
				check(not ui._bloom_turn_strip.get_rect().intersects(ui._bloom_objective_panel.get_rect()), "turn strip stays clear of objective")
	ui._refresh_appearance_control()
	check(not ui._bloom_skin_toggle.text.contains("↔"), "appearance label avoids unavailable Web arrow glyph")
	check(ui._bloom_skin_toggle.text == "Characters: Compact", "appearance label retains current skin identity")
	battle.queue_free()
	await get_tree().process_frame
	print("Courtyard turn labels: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
