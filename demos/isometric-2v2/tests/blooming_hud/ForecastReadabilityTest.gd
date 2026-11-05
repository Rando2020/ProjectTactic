extends Node
## Populated layout contract: the first page must show the decision, not only
## repeated instructions. This drives the actual HUD and inherited forecast formatter.
var checks := 0
var failures := 0
var capture_dir := ""
var measurements: Array[Dictionary] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func settle() -> void:
	for i in 8: await get_tree().process_frame

func _ready() -> void: run.call_deferred()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
	var ui = load("res://prototypes/blooming/BloomingHUD.gd").new()
	add_child(ui)
	var settings = load("res://scripts/ui/UISettings.gd").shared()
	var preview := {"visible":true,"mode":"Ability","actor":"Zane","action":"Thunderstrike","target":"Void Cultist","hp_before":80,"hp_after":35,"max_hp":80,"damage":45,"hit_pct":100,"crit_pct":10,"jp_gain":6,"status_preview":"Shocked","can_counter":true,"range_label":"Range 4","aoe_note":"3 tiles","note":"Read the complete explanation before committing.","actor_portrait":"res://assets/characters/portraits/zane-portrait-illustrated.png","target_portrait":"res://assets/sprites/units/void_cultist.png"}
	for viewport in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
		get_window().content_scale_size = viewport
		get_window().size = viewport
		await settle()
		for mode in [1,2,3,1,3]:
			settings.set_mode(mode,false)
			ui._unit_name.text = "Zane\nArcanist"
			ui._hp_label.text = "HP: 277/320"
			ui._mp_label.text = "MP: 66"
			ui._bloom_armor.text = "Armor · TMP 80 / ETH 94"
			ui._bloom_armor.show()
			ui._chapel_command_panel.show()
			for button in [ui._move_btn,ui._attack_btn,ui._ability_btn,ui._wait_btn]: button.hide()
			ui._cancel_btn.show()
			ui._confirm_btn.show()
			ui._on_action_preview_changed(preview)
			ui._preview_mode_label.text = "REVIEW · Confirm to commit · Esc to retarget"
			ui._preview_scroll.scroll_vertical = 0
			await settle()
			var tag := "%s mode%s" % [viewport,mode]
			var clip: Rect2 = ui._preview_scroll.get_global_rect()
			for label in [ui._preview_action_label,ui._preview_target_label,ui._preview_amount_label,ui._preview_hit_label]:
				check(clip.encloses(label.get_global_rect()),tag + " initially shows " + label.text)
			check(ui._preview_action_label.get_line_count() == 1,tag + " Thunderstrike stays unbroken")
			check(ui._preview_action_label.get_theme_font_size("font_size") == roundi(17 * settings.effective_scale(viewport)),tag + " selected action type size preserved")
			check(not ui._preview_scroll.get_h_scroll_bar().visible,tag + " no horizontal scroll")
			measurements.append({"viewport":str(viewport),"mode":mode,"panel":str(ui._preview_panel.get_rect()),"action_lines":ui._preview_action_label.get_line_count(),"action_font":ui._preview_action_label.get_theme_font_size("font_size"),"target":ui._preview_target_label.text,"scroll_page":ui._preview_scroll.get_v_scroll_bar().page,"scroll_max":ui._preview_scroll.get_v_scroll_bar().max_value})
			if not capture_dir.is_empty() and viewport == Vector2i(1920,1080) and mode == 3:
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png(capture_dir.path_join("forecast-150.png"))
			# The complete forecast remains available, including warnings, healing,
			# move destinations, long names, secondary AoE victims and current intent.
			for fixture in [preview.merged({"action":"Resonance Fracture","target":"Hollow Lancer Captain","hp_after":0},true),preview.merged({"is_heal":true,"heal":70,"hp_before":120,"hp_after":190,"target":"Kael","action":"Greater Heal"},true),preview.merged({"mode":"Move","action":"Move","target":"(5, 7)","status_preview":"2 steps"},true)]:
				fixture["affected_targets"] = [{"unit_id":"secondary","target_name":"Storm Imp","role":"secondary","hp_before":90,"hp_after":45,"status_preview":"Shocked"}]
				fixture["target_intent"] = {"action":"Void Pulse","target":"Kael"}
				fixture["note"] = "Complete forecast details. ".repeat(8) + "FINAL DETAIL"
				ui._on_action_preview_changed(fixture)
				await settle()
				check(ui._preview_target_label.text.contains(str(fixture.target)),tag + " full target name preserved")
				check(ui._preview_note_label.text.ends_with("FINAL DETAIL"),tag + " full note preserved")
				check(ui._preview_note_label.max_lines_visible == -1,tag + " notes not line-limited")
				if fixture.mode != "Move":
					check(ui._preview_note_label.text.contains("Counter possible"),tag + " counter warning preserved")
					check(ui._preview_note_label.text.contains("Shocked"),tag + " status preserved")
					check(ui._preview_target_label.text.contains("HP %d -> %d" % [fixture.hp_before,fixture.hp_after]),tag + " authoritative HP preserved")
				else:
					check(ui._preview_target_label.text.begins_with("DESTINATION"),tag + " move destination identified")
					check(not ui._preview_amount_label.visible and not ui._preview_hit_label.visible,tag + " no misleading damage for move")
				var bar: VScrollBar = ui._preview_scroll.get_v_scroll_bar()
				ui._preview_scroll.scroll_vertical = roundi((bar.max_value-bar.page)*0.5)
				await settle()
				var retained: int = ui._preview_scroll.scroll_vertical
				ui._on_action_preview_changed(fixture)
				await settle()
				check(abs(ui._preview_scroll.scroll_vertical-retained) <= 1,tag + " refresh does not fight detail scrolling")
				ui._preview_scroll.scroll_vertical = roundi(bar.max_value)
				await settle()
				check(ui._preview_connection_label.text.contains("Storm Imp") and ui._preview_intent_label.text.contains("Void Pulse"),tag + " AoE and intent preserved")
				clip = ui._preview_scroll.get_global_rect()
				check(ui._preview_connection_label.get_global_rect().end.y <= clip.end.y+1 and ui._preview_intent_label.get_global_rect().end.y <= clip.end.y+1,tag + " last details reachable by vertical scroll")
				ui._proof_skills_panel.show()
				ui._layout_forecast()
				await settle()
				check(not ui._preview_panel.get_rect().intersects(ui._proof_skills_panel.get_rect()),tag + " narrow skills separation")
				check(not ui._preview_scroll.get_h_scroll_bar().visible,tag + " narrow forecast never requires horizontal scroll")
				for label in [ui._preview_action_label,ui._preview_target_label,ui._preview_note_label,ui._preview_connection_label,ui._preview_intent_label]:
					check(label.get_global_rect().end.x <= ui._preview_scroll.get_global_rect().end.x+1,tag + " narrow content fits " + label.text.left(20))
				ui._proof_skills_panel.hide()
				ui._layout_forecast()
	if not capture_dir.is_empty():
		var file := FileAccess.open(capture_dir.path_join("forecast-measurements.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify(measurements,"\t"))
	ui.queue_free()
	await get_tree().process_frame
	print("Forecast readability: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
