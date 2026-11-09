extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var battle = load("res://prototypes/isometric/Skirmish.tscn").instantiate()
	get_tree().root.add_child(battle)
	get_tree().current_scene = battle
	for i in 120:
		await get_tree().process_frame
		if battle.battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
	var ui = battle.battle_ui
	check(ui.has_method("_refresh_preview_connections"), "preview connects targets to actual turn portraits")
	if not ui.has_method("_refresh_preview_connections"):
		get_tree().quit(1)
		return
	var manager = battle.battle_manager
	var target: Unit = manager.units.Enemy_1
	var second: Unit = manager.units.Enemy_2
	var hp := target.hp
	var mp: int = manager.units.zane.mp
	var order = manager.turn_order.get_projected_order(4).duplicate(true)
	# Exercise the real cursor -> manager forecast -> prototype UI signal path.
	for ability_id in ["thunderstrike", "void_pulse", "fire"]:
		manager.select_ability(ability_id)
		manager._on_tile_hovered(target.grid_pos)
		check(ui._preview_primary == target.unit_id, ability_id + " real hover target identity")
		check(ui._preview_target_portrait.texture != null, ability_id + " real hover portrait")
		check(ui._preview_affected.has(target.unit_id), ability_id + " real hover primary queue link")
		check(ui._preview_intent_label.text.begins_with("CURRENT PLAN"), ability_id + " current enemy intent")
		if ability_id == "thunderstrike":
			check(ui._preview_affected.has(second.unit_id), "real chain collateral identity")
			var chain_ability := AbilityDB.get_ability("thunderstrike").duplicate(true)
			chain_ability.base_power = int(float(chain_ability.base_power) * 0.6)
			var expected := ForecastCalculator.spell(manager.units.zane, second, chain_ability)
			check(ui._preview_affected[second.unit_id].hp_after == expected.hp_after, "real chain forecast uses falloff")
		manager.cancel_pending_action()
		check(ui._preview_primary.is_empty(), ability_id + " real cancel clears connections")
	check(target.hp == hp and manager.units.zane.mp == mp, "real hovering spends no resources")
	manager.select_ability("fire")
	var area_cell := Vector2i(-1,-1)
	for cell in manager.tactical_grid.ability_tiles:
		if manager._unit_at_pos(cell) == null and not manager._get_aoe_targets(cell,AbilityDB.get_ability("fire"),manager.units.zane).is_empty():
			area_cell = cell
			break
	check(area_cell.x >= 0,"empty fan center fixture exists")
	if area_cell.x >= 0:
		var area_preview: Dictionary = manager._ability_preview_for_tile(area_cell,AbilityDB.get_ability("fire"))
		check(not area_preview.get("affected_targets",[]).is_empty(),"empty fan center lists real affected targets")
		check(str(area_preview.get("target_id","")) == "", "empty fan center has no invented target")
		check(int(area_preview.get("damage",0)) == 0, "empty center does not invent generic damage")
		ui._on_action_preview_changed(area_preview)
		check(ui._preview_target_portrait.texture == null,"empty center has no fake portrait")
	manager.cancel_pending_action()
	manager.active_unit_id = "kael"
	manager.active_command = "ability"
	var guard: Dictionary = manager._ability_preview_for_tile(manager.units.kael.grid_pos,AbilityDB.get_ability("defend"))
	check(bool(guard.get("is_buff",false)),"Defend previews self guard")
	check(guard.get("target_id","") == "kael","Defend links own portrait")
	check(int(guard.get("hp_after",0)) == manager.units.kael.hp,"Defend predicts no damage")
	ui._selection.select_unit("kael")
	ui._on_ability()
	for frame in 3: await get_tree().process_frame
	var buttons: Array[Button] = []
	for row in ui._ability_list.get_children():
		if row is Button and not row.is_queued_for_deletion(): buttons.append(row)
	buttons[-1].focus_entered.emit()
	check(ui._preview_primary == "kael", "Defend menu focus previews own portrait")
	check(ui._preview_amount_label.text == "BUFF", "Defend menu focus shows buff not attack damage")
	manager.active_unit_id = "zane"
	manager.cancel_pending_action()
	var preview := {"visible":true,"target_id":target.unit_id,"target_name":target.display_name,"actor_name":"Zane","ability_name":"Thunderstrike","hp_before":hp,"hp_after":maxi(0,hp-20),"max_hp":hp,"damage":20,"affected_targets":[{"unit_id":target.unit_id,"target_name":target.display_name,"role":"primary","hp_before":hp,"hp_after":maxi(0,hp-20)},{"unit_id":second.unit_id,"target_name":second.display_name,"role":"chain","hp_before":second.hp,"hp_after":maxi(0,second.hp-12)}],"target_intent":{"action":"Thunderstrike","target":"Zane"}}
	ui._on_action_preview_changed(preview)
	await get_tree().process_frame
	check(ui._preview_target_portrait.texture != null, "selected enemy portrait populated from identity")
	check(ui._preview_target_portrait.get_parent().size.y <= 108, "portrait frame does not stretch through whole forecast")
	check(ui._preview_target_portrait.size.x >= 80, "portrait has recognizable width")
	check(ui._preview_connection_label.text.contains("CHAIN"), "collateral chain shown")
	check(ui._preview_intent_label.text.contains("may change"), "intent is changeable forecast")
	check(ui._preview_intent_label.text.contains("Thunderstrike"), "current enemy plan visible")
	for row in ui._turn_rows:
		if row.unit_id in [target.unit_id,second.unit_id]:
			check(row.panel.get_meta("preview_affected",false), "affected queue entry highlighted")
			check(row.when.text.contains("TARGET") or row.when.text.contains("CHAIN"), "affected queue entry explicitly labeled")
	get_window().content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(390,844),Vector2i(844,390),Vector2i(1920,1080)]:
		get_window().size = dimensions
		for frame in 5: await get_tree().process_frame
		ui._layout_forecast()
		check(ui.get_viewport().get_visible_rect().encloses(ui._preview_panel.get_rect()), "forecast fits " + str(dimensions))
	check(target.hp == hp and manager.units.zane.mp == mp, "preview spends no HP or MP")
	check(manager.turn_order.get_projected_order(4) == order, "preview never moves actual queue")
	ui._on_action_preview_changed({})
	for row in ui._turn_rows:
		check(not row.panel.get_meta("preview_affected",false), "cancel clears queue highlight")
	check(ui._preview_intent_label.text.is_empty(), "cancel clears enemy plan")
	ui._on_action_preview_changed(preview)
	manager.is_resolving_action = true
	ui._on_action_state_changed(false,false,false)
	for row in ui._turn_rows:
		check(not row.panel.get_meta("preview_affected",false), "commit clears queue highlight")
	manager.is_resolving_action = false
	ui._on_action_preview_changed(preview)
	target.hp = 0
	ui._refresh_turn_portraits()
	check(not ui._preview_panel.visible, "defeat clears stale primary forecast")
	print("SkillPreviewTest: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
