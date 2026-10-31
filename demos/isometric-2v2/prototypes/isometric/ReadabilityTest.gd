extends Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _ready() -> void: call_deferred("run")
func settle() -> void:
	for i in 5: await get_tree().process_frame
func verify_labels(battle, description: String) -> void:
	var ui = battle.battle_ui
	var overlay = ui._battlefield_labels
	overlay.refresh()
	var occupied: Array[Rect2] = []
	for id in overlay.rows:
		var row: Label = overlay.rows[id]
		var unit: Unit = battle.battle_manager.units[id]
		check(row.text == unit.display_name,description+" full name "+id)
		check(row.get_theme_font_size("font_size") >= 22,description+" readable font "+id)
		check(row.mouse_filter == Control.MOUSE_FILTER_IGNORE,description+" non-interactive "+id)
		check(row.get_theme_stylebox("normal") is StyleBoxFlat,description+" contrast backing "+id)
		check(ui.get_viewport().get_visible_rect().encloses(row.get_rect()),description+" label bounds "+id)
		check(row.get_rect().end.x <= ui._right_panel_bg.position.x,description+" rail separate "+id)
		for previous in occupied:
			check(not previous.intersects(row.get_rect()),description+" labels separate "+id)
		occupied.append(row.get_rect())
		var expected: Vector2 = unit.get_global_transform_with_canvas() * Vector2(0,unit._hud_bar_y-5)
		check(overlay.anchors[id].distance_to(expected)<0.1,description+" anchor follows "+id)
		for child in unit.get_children():
			if child is Label and child.text == unit.display_name.left(6):
				check(not child.visible,description+" legacy name hidden "+id)
func run() -> void:
	Engine.time_scale = 4
	var battle := preload("res://prototypes/isometric/Skirmish.tscn").instantiate()
	add_child(battle)
	for i in 1000:
		if battle.battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().create_timer(0.025).timeout
	get_window().content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(390,844),Vector2i(844,390),Vector2i(1180,812),Vector2i(1920,1080)]:
		get_window().size = dimensions
		await settle()
		for rotated in [false,true]:
			battle.set_stage_mode(rotated)
			for angle in 4:
				if rotated: battle.rotate_stage(1)
				await settle()
				verify_labels(battle,"%s mode%s angle%d" % [dimensions,rotated,angle])
				# Cluster actors near adjacent cells, then restore physical positions.
				var saved: Dictionary = {}
				var positions := [Vector2i(1,1),Vector2i(1,2),Vector2i(2,1),Vector2i(2,2)]
				var n := 0
				for unit: Unit in battle.battle_manager.units.values():
					saved[unit.unit_id] = unit.position
					unit.position = battle.tactical_grid._unit_foot_pos(positions[n])
					n += 1
				await settle()
				verify_labels(battle,"cluster %s mode%s angle%d" % [dimensions,rotated,angle])
				for unit: Unit in battle.battle_manager.units.values(): unit.position = saved[unit.unit_id]
				await settle()
	var ui = battle.battle_ui
	battle.set_compact_skins(false)
	for id in ["kael","storm_imp","void_cultist"]:
		var texture: Texture2D = ui._framed_portrait(id)
		check(texture is AtlasTexture,"portrait crop "+id)
		if texture is AtlasTexture:
			check(Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region),"crop within original "+id)
			check(texture.region.size.y <= 80,"upper body framing "+id)
		check(ui._framed_portrait(id) == texture,"cached portrait "+id)
	check(not ui._framed_portrait("zane") is AtlasTexture,"authored Zane portrait preserved")
	var unit: Unit = battle.battle_manager.units["Enemy_2"]
	unit.hp = 0
	await settle()
	check(not ui._battlefield_labels.rows.has("Enemy_2"),"KO removes label")
	unit.hp = 80
	await settle()
	check(ui._battlefield_labels.rows.has("Enemy_2"),"restore creates label")
	check(battle.battle_manager.active_unit_id == "zane" and not battle.battle_manager.active_unit_has_acted,"presentation spends no action")
	# Reproduce the resolver's short window where a freed actor remains in units.
	# Refresh must guard the Variant before any typed Unit assignment can occur.
	unit.free()
	check(battle.battle_manager.units.has("Enemy_2") and not is_instance_valid(battle.battle_manager.units["Enemy_2"]),"freed actor remains in registry fixture")
	ui._battlefield_labels.refresh()
	check(not ui._battlefield_labels.rows.has("Enemy_2"),"freed registry actor removes stale label")
	check(ui._battlefield_labels.rows.size() == 3,"freed registry actor preserves survivors")
	battle.battle_manager.units.erase("Enemy_2")
	battle.queue_free()
	await get_tree().create_timer(1).timeout
	var retry := preload("res://prototypes/isometric/Skirmish.tscn").instantiate()
	add_child(retry)
	await settle()
	check(retry.battle_ui._battlefield_labels.rows.size() == 4,"new battle restores four labels")
	retry.queue_free()
	await get_tree().create_timer(1).timeout
	print("Readability: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
