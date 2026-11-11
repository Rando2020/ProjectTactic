extends Node
## The real courtyard keeps a detailed, same-appearance status portrait.
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func frames(count: int = 4) -> void:
	for i in count: await get_tree().process_frame
func _ready() -> void: run.call_deferred()
func run() -> void:
	var battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
	add_child(battle)
	await frames(20)
	var ui = battle.battle_ui
	check(ui.has_method("_status_portrait"), "courtyard has dedicated detailed status portraits")
	if not ui.has_method("_status_portrait"):
		get_tree().quit(1)
		return
	var manager = battle.battle_manager
	var active_id: String = manager.active_unit_id
	var before_hp: int = manager.units.zane.hp
	var before_mp: int = manager.units.zane.mp
	for compact in [true,false,true]:
		check(battle.set_compact_skins(compact), "appearance can change")
		for id in ["zane","kael"]:
			var portrait: Texture2D = ui._status_portrait(id)
			check(portrait != null, "status portrait exists for " + id)
			if compact:
				check(portrait is AtlasTexture, "approved painterly crop for " + id)
				if portrait is AtlasTexture:
					check(portrait.atlas.resource_path.contains("painterly/originals/"), "source is detailed same-appearance art")
					check(portrait.region.size.x >= 240 and portrait.region.size.y >= 300, "high-detail source crop")
					check(Rect2(Vector2.ZERO,portrait.atlas.get_size()).encloses(portrait.region), "crop within source")
				check(portrait != ui._framed_portrait(id), "status does not upscale the compact sprite crop")
			else:
				check(portrait == ui._framed_portrait(id), "original mode preserves original identity")
			check(portrait == ui._status_portrait(id), "status crop cached")
		check(ui._active_portrait.texture == ui._status_portrait(active_id), "appearance toggle refreshes active status immediately")
	for id in ["storm_imp","void_cultist"]:
		check(ui._status_portrait(id) == ui._framed_portrait(id), "enemy retains authored identity fallback")
	check(ui._status_portrait("missing_character") == null, "unknown identity safely returns empty")
	ui._selection.select_unit("kael")
	await frames()
	check(ui._active_portrait.texture == ui._status_portrait(active_id), "inspecting inactive ally does not mismatch active resources")
	ui._selection.select_unit("Enemy_1")
	await frames()
	check(ui._active_portrait.texture == ui._status_portrait(active_id), "enemy inspection does not overwrite active portrait")
	check(manager.active_unit_id == active_id and manager.units.zane.hp == before_hp and manager.units.zane.mp == before_mp, "portrait changes never spend combat resources")
	for viewport in [Vector2i(1920,1080),Vector2i(1366,768),Vector2i(960,540)]:
		get_window().content_scale_size = viewport
		get_window().size = viewport
		await frames()
		for collapsed in [false,true]:
			ui.set_tester_collapsed(collapsed)
			await frames()
			check(ui._active_portrait.size.x >= 100 and ui._active_portrait.size.y >= 130, "readable detailed portrait " + str(viewport))
			check(ui._bloom_active_panel.get_global_rect().encloses(ui._active_portrait.get_global_rect()), "portrait inside status card")
			check(not ui._bloom_active_panel.get_rect().intersects(ui._chapel_command_panel.get_rect()), "status card clear of command dock")
			check(ui.gameplay_rect(viewport).encloses(ui._bloom_active_panel.get_rect()), "status card inside gameplay area")
			check(ui._active_portrait.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "detailed art uses smooth filtering")
	# A real wait/confirmation must advance the panel to Kael, not just change a label.
	ui._selection.select_unit(active_id)
	ui._on_wait()
	ui._on_confirm()
	for i in 1000:
		if manager.active_unit_id == "kael" and manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().create_timer(0.025).timeout
	await frames()
	check(manager.active_unit_id == "kael", "normal turn advances to Kael")
	check(ui._active_portrait.texture == ui._status_portrait("kael"), "turn refresh shows Kael detailed status portrait")
	battle.queue_free()
	await frames()
	print("Detailed status portraits: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
