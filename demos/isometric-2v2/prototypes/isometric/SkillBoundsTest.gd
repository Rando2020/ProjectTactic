extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _ready() -> void: call_deferred("run")
func settle() -> void:
	for i in 4: await get_tree().process_frame
func run() -> void:
	Engine.time_scale = 4
	var battle := preload("res://prototypes/isometric/Skirmish.tscn").instantiate()
	add_child(battle)
	var manager = battle.battle_manager
	var ui = battle.battle_ui
	for i in 1000:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().create_timer(0.025).timeout
	get_window().content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(1180,812),Vector2i(844,390),Vector2i(390,844),Vector2i(1920,1080)]:
		get_window().size = dimensions
		await settle()
		for rotated in [false,true]:
			battle.set_stage_mode(rotated)
			for angle in 4:
				if rotated: battle.rotate_stage(1)
				ui._selection.select_unit(manager.active_unit_id)
				ui._on_ability()
				await settle()
				ui._selection.layout_popup()
				await settle()
				var panel: Rect2 = ui._proof_skills_panel.get_rect()
				var viewport: Rect2 = ui.get_viewport().get_visible_rect()
				check(viewport.encloses(panel), "skills within viewport %s angle%d" % [dimensions,angle])
				check(not panel.intersects(ui._chapel_command_panel.get_rect()), "Back remains separate")
				check(ui._proof_skills_scroll.follow_focus, "keyboard focus scrolls")
				# Long future lists must also be usable; selecting the last row scrolls into view.
				ui._ability_panel.custom_minimum_size.y = 1600
				ui._selection.layout_popup()
				await settle()
				check(viewport.encloses(ui._proof_skills_panel.get_rect()), "long list bounded")
				check(ui._proof_skills_scroll.get_v_scroll_bar().max_value > ui._proof_skills_scroll.size.y, "long list scrollable")
				ui._ability_panel.custom_minimum_size.y = 0
				ui._selection.go_back()
				await settle()
				check(manager.active_command.is_empty() and not ui._proof_skills_panel.visible, "cancel restores commands")
				check(viewport.encloses(ui._chapel_command_panel.get_rect()), "command menu bounded after cancel")
				check(manager.active_unit_id == "zane" and not manager.active_unit_has_acted, "layout spends no action")
	battle.queue_free()
	await get_tree().create_timer(2).timeout
	print("Skill bounds: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
