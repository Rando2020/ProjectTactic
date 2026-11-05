extends Node
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	var ui = load("res://prototypes/blooming/BloomingHUD.gd").new()
	add_child(ui)
	var settings = load("res://scripts/ui/UISettings.gd").shared()
	for viewport in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
		get_window().content_scale_size = viewport
		get_window().size = viewport
		await get_tree().process_frame
		for mode in [1,2,3,0,3,1,3]:
			settings.set_mode(mode,false)
			for collapsed in [false,true]:
				ui.set_tester_collapsed(collapsed)
				ui._objective_label.text = "Defeat both enemies"
				ui._unit_name.text = "Rapha\nCleric"
				ui._hp_label.text = "HP 100 / 100"
				ui._mp_label.text = "MP 100 / 100"
				ui._bloom_armor.text = "Armor · TMP 10 / ETH 10"
				ui._bloom_armor.show()
				ui._chapel_command_panel.show()
				for button in [ui._move_btn,ui._attack_btn,ui._ability_btn,ui._wait_btn,ui._cancel_btn]: button.show()
				for i in range(4): await get_tree().process_frame
				var factor: float = settings.effective_scale(viewport)
				check(ui._mission_label.get_theme_font_size("font_size") == roundi(18*factor), "font changes without drift: %s mode %s" % [viewport,mode])
				check(ui._objective_label.size.y >= ui._objective_label.get_theme_font("font").get_height(ui._objective_label.get_theme_font_size("font_size")), "objective line fits")
				check(ui._unit_name.max_lines_visible != 1, "active class is not trimmed")
				check(ui._move_btn.get_theme_font_size("font_size") == roundi(17*factor), "command uses courtyard base font")
				check(Rect2(Vector2.ZERO,viewport).encloses(ui._bloom_rail_toggle.get_rect()), "rail toggle contained")
				var area: Rect2 = ui.gameplay_rect(viewport)
				for panel in [ui._bloom_objective_panel,ui._bloom_active_panel,ui._bloom_turn_strip,ui._chapel_command_panel]:
					check(area.encloses(panel.get_rect()), "panel contained %s %s mode%s %s" % [viewport,panel.name,mode,panel.get_rect()])
				for pair in [[ui._mission_label,ui._bloom_objective_panel],[ui._objective_label,ui._bloom_objective_panel],[ui._unit_name,ui._bloom_active_panel],[ui._hp_label,ui._bloom_active_panel],[ui._mp_label,ui._bloom_active_panel],[ui._bloom_armor,ui._bloom_active_panel]]:
					var label: Label = pair[0]
					check(pair[1].get_global_rect().encloses(label.get_global_rect()), "label contained %s %s" % [viewport,label.text])
					check(label.size.x >= label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x, "label not trimmed %s %s mode%s" % [viewport,label.text,mode])
				for button in [ui._move_btn,ui._attack_btn,ui._ability_btn,ui._wait_btn,ui._cancel_btn]:
					check(ui._chapel_command_panel.get_global_rect().encloses(button.get_global_rect()), "command accessible %s %s mode%s" % [viewport,button.text,mode])
				check(collapsed or ui._right_panel_root.size.x <= ui._right_panel_scroll.size.x, "rail content fits width %s mode%s collapsed%s root%s scroll%s" % [viewport,mode,collapsed,ui._right_panel_root.size,ui._right_panel_scroll.size])
				ui._ability_panel.show()
				ui._proof_skills_panel.show()
				ui._preview_panel.show()
				ui._layout_forecast()
				for i in range(3): await get_tree().process_frame
				check(not ui._preview_panel.get_rect().intersects(ui._proof_skills_panel.get_rect()),"forecast/skills separate")
				for panel in [ui._preview_panel,ui._proof_skills_panel]:
					check(not panel.get_rect().intersects(ui._chapel_command_panel.get_rect()),"preview/commands separate")
					check(not panel.get_rect().intersects(ui._bloom_active_panel.get_rect()),"preview/resources separate")
				ui._ability_panel.hide()
				ui._proof_skills_panel.hide()
				ui._preview_panel.hide()
	print("Blooming HUD scale: ", "PASS" if failures == 0 else "FAIL %d" % failures)
	get_tree().quit(0 if failures == 0 else 1)
