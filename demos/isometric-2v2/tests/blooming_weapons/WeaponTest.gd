extends Node
## Controlled positioning probes use the real controller, forecast and damage resolver.
var checks := 0
var failures: Array[String] = []
var battle: BattleScene
var manager
var capture_dir := ""
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)
func _ready() -> void:
	run.call_deferred()
func boot() -> void:
	battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
	get_tree().root.add_child(battle)
	manager = battle.battle_manager
	for i in 600:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: return
		await get_tree().process_frame
	check(false,"player turn reached")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
	GameState.unit_registry.zane.jp = 37
	GameState.save()
	var registry_before := GameState.unit_registry.duplicate(true)
	var save_before := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	await boot()
	check(manager.has_method("equip_test_weapon"),"courtyard heroes expose selectable test weapons")
	check(battle.battle_ui.has_method("_refresh_test_weapons"),"actual courtyard HUD exposes test loadout controls")
	if not manager.has_method("equip_test_weapon"):
		battle.queue_free()
		await get_tree().process_frame
		finish()
		return
	var patterns = load("res://prototypes/blooming/weapons/WeaponPatterns.gd")
	var open: Dictionary = {}
	for y in 5:
		for x in 5: open[Vector2i(x,y)] = {"blocks_movement":false,"blocks_line_of_sight":false}
	var origin := Vector2i(2,2)
	var cases := [
		[Vector2i(2,1),[Vector2i(2,1),Vector2i(2,0)],[Vector2i(2,1),Vector2i(1,1),Vector2i(3,1)]],
		[Vector2i(3,2),[Vector2i(3,2),Vector2i(4,2)],[Vector2i(3,2),Vector2i(3,1),Vector2i(3,3)]],
		[Vector2i(2,3),[Vector2i(2,3),Vector2i(2,4)],[Vector2i(2,3),Vector2i(3,3),Vector2i(1,3)]],
		[Vector2i(1,2),[Vector2i(1,2),Vector2i(0,2)],[Vector2i(1,2),Vector2i(1,3),Vector2i(1,1)]]]
	for row in cases:
		check(patterns.footprint("sword",origin,row[0],open)==[row[0]],"sword one cardinal tile %s" % row[0])
		check(patterns.footprint("spear",origin,row[0],open)==row[1],"spear two straight tiles %s" % row[0])
		check(patterns.footprint("greatsword",origin,row[0],open)==row[2],"greatsword three front tiles %s" % row[0])
	for weapon in ["sword","spear","greatsword"]:
		check(patterns.footprint(weapon,origin,origin,open).is_empty(),weapon+" rejects self aim")
		check(patterns.footprint(weapon,origin,Vector2i(3,3),open).is_empty(),weapon+" rejects diagonal aim")
		check(patterns.footprint(weapon,origin,Vector2i(2,-1),open).is_empty(),weapon+" rejects distant aim")
	check(patterns.footprint("spear",origin,Vector2i(2,0),open)==[Vector2i(2,1),Vector2i(2,0)],"spear second-cell aim keeps near-to-far footprint")
	check(patterns.footprint("greatsword",Vector2i(0,0),Vector2i(1,0),open)==[Vector2i(1,0),Vector2i(1,1)],"greatsword clips board edge")
	check(patterns.footprint("spear",Vector2i(0,0),Vector2i(0,1),open)==[Vector2i(0,1),Vector2i(0,2)],"spear near board corner remains bounded")
	open[Vector2i(2,1)].blocks_line_of_sight = true
	check(patterns.footprint("spear",origin,Vector2i(2,0),open).is_empty(),"wall stops spear before second cell")
	check(patterns.footprint("greatsword",origin,Vector2i(2,1),open).is_empty(),"wall at front center blocks greatsword")
	check(patterns.footprint("unknown",origin,Vector2i(3,2),open).is_empty(),"unknown weapon cannot create an area")
	check(manager.units.size()==4,"existing 2v2 roster unchanged")
	check(manager.test_weapon_options("zane")==["sword","spear"],"Zane exposes only two test loadouts")
	check(manager.test_weapon_options("kael")==["sword","greatsword"],"Kael exposes only two test loadouts")
	check(manager.test_weapon_options("Enemy_1").is_empty(),"enemies receive no player test equipment")
	check(manager.test_weapon_id("zane")=="sword" and manager.test_weapon_id("kael")=="sword","fresh encounter starts both heroes with sword")
	var zane: Unit = manager.units.zane
	var kael: Unit = manager.units.kael
	var enemy: Unit = manager.units.Enemy_1
	var other: Unit = manager.units.Enemy_2
	enemy.hp=1000;other.hp=1000
	enemy.unit_data.base_stats.hp=1000;other.unit_data.base_stats.hp=1000
	var selection = battle.battle_ui._selection
	pose(zane,Vector2i(4,8));pose(enemy,Vector2i(4,7));pose(other,Vector2i(4,6));pose(kael,Vector2i(3,7))
	selection.select_unit("zane")
	battle.battle_ui._refresh_test_weapons()
	check(battle.battle_ui._weapon_buttons[0].is_visible_in_tree() and battle.battle_ui._weapon_buttons[1].is_visible_in_tree(),"two actual weapon controls visible for active hero")
	await capture("loadout-controls")
	check(not manager.equip_test_weapon("kael","greatsword"),"cannot equip inactive ally")
	check(not manager.equip_test_weapon("zane","greatsword"),"cannot equip weapon outside hero pair")
	manager.select_command("attack")
	check(manager._attack_preview_for_tile(other.grid_pos).is_empty(),"sword cannot reach second cell")
	selection.set_cursor(enemy.grid_pos);selection.activate_cursor()
	check(selection.has_review(),"sword stages actual review")
	var before := resources()
	check(manager.equip_test_weapon("zane","spear"),"swap before action accepted")
	selection.confirm_review()
	check(not manager.is_resolving_action and resources()==before,"swap invalidates stale sword confirmation")
	check(not selection.has_review(),"swap clears stale review")
	manager.select_command("attack")
	selection.set_cursor(enemy.grid_pos)
	check(manager.tactical_grid.aoe_preview_tiles==[Vector2i(4,7),Vector2i(4,6)],"visible spear area equals both actual hit cells")
	var forecast: Dictionary = manager._attack_preview_for_tile(enemy.grid_pos)
	check(forecast.affected_targets.map(func(t):return t.unit_id)==["Enemy_1","Enemy_2"],"forecast lists both near-to-far spear recipients")
	var far_forecast: Dictionary=manager._attack_preview_for_tile(other.grid_pos)
	check(bool(far_forecast.get("can_counter",false)),"far spear aim still warns about near collateral counter")
	selection.activate_cursor()
	check(battle.battle_ui._preview_note_label.text.contains("Storm Imp") and battle.battle_ui._preview_note_label.text.contains("Void Cultist"),"first-page weapon summary names all actual recipients")
	await capture("spear-review")
	selection.go_back()
	check(resources()==before and not manager.active_unit_has_acted,"cancel preserves action and all resources")
	selection.activate_cursor()
	var resolved: Array = []
	manager.combat_resolver.combat_resolved.connect(func(result):resolved.append(result))
	seed(17)
	selection.confirm_review();selection.confirm_review()
	check(not manager.equip_test_weapon("zane","sword"),"cannot swap while resolving")
	await settle()
	check(resolved.filter(func(r):return r.has("feedback_owner")).size()==2,"one spear confirmation resolves each enemy once, no duplicate action")
	check(enemy.hp+enemy.temper < before.Enemy_1[0]+before.Enemy_1[2] and other.hp+other.temper < before.Enemy_2[0]+before.Enemy_2[2],"real spear resolver damages both enemies")
	check(kael.hp==before.kael[0] and kael.temper==before.kael[2],"spear leaves allied resources untouched")
	check(zane.mp==before.zane[1] and manager.active_unit_has_acted,"weapon spends one action and no MP")
	check(not manager.active_unit_has_moved,"weapon leaves independent movement available")
	check(not manager.equip_test_weapon("zane","sword"),"cannot swap after acting")
	manager.active_unit_has_acted=false
	selection.select_unit("zane")
	battle.battle_ui._refresh_test_weapons()
	battle.battle_ui._weapon_buttons[0].pressed.emit()
	check(manager.test_weapon_id("zane")=="sword","actual equipment button switches back to sword")
	manager.select_command("attack");selection.set_cursor(enemy.grid_pos);selection.activate_cursor()
	before=resources();resolved.clear();seed(17)
	selection.confirm_review();selection.confirm_review();await settle()
	check(resolved.filter(func(r):return r.has("feedback_owner")).size()==1,"sword produces exactly one primary damage outcome")
	check(other.hp==before.Enemy_2[0] and other.temper==before.Enemy_2[2],"sword cannot damage the second enemy in line")
	# Controlled turn-state/position probe, not a claim of full-match manual input.
	manager.active_unit_id="kael";manager.active_unit_has_acted=false;manager.active_unit_has_moved=false
	manager.turn_started.emit("kael","player")
	await get_tree().create_timer(1.5).timeout
	pose(kael,Vector2i(4,8));pose(zane,Vector2i(4,7));pose(enemy,Vector2i(3,7));pose(other,Vector2i(5,7))
	selection.select_unit("kael")
	check(manager.equip_test_weapon("kael","greatsword"),"Kael equips greatsword")
	battle.battle_ui._refresh_test_weapons()
	await capture("kael-loadout")
	manager.select_command("attack");selection.set_cursor(Vector2i(4,7))
	check(manager.tactical_grid.aoe_preview_tiles==[Vector2i(4,7),Vector2i(3,7),Vector2i(5,7)],"greatsword shows entire three-cell front row, including safe ally tile")
	forecast=manager._attack_preview_for_tile(Vector2i(4,7))
	check(forecast.affected_targets.map(func(t):return t.unit_id)==["Enemy_1","Enemy_2"],"greatsword skips ally center and previews both flank enemies")
	pose(zane,Vector2i(6,8))
	check(not manager._attack_preview_for_tile(Vector2i(4,7)).is_empty(),"empty greatsword center legal when row contains enemies")
	check(manager._attack_preview_for_tile(Vector2i(5,7)).is_empty(),"diagonal occupied tile cannot choose ambiguous facing")
	selection.set_cursor(Vector2i(4,7));selection.activate_cursor()
	check(not battle.battle_ui._preview_crit_label.text.contains("JP"),"test weapon forecast does not promise unearned progression")
	for frame in 5:await get_tree().process_frame
	var grid=battle.tactical_grid
	for cell in grid.aoe_preview_tiles:
		var center: Vector2=grid.get_global_transform_with_canvas()*grid._grid_to_local(cell)
		var half: Vector2=Vector2(grid.tile_size)*grid.get_global_transform_with_canvas().get_scale()*0.5
		check(not battle.battle_ui._preview_panel.get_rect().intersects(Rect2(center-half,half*2)),"forecast leaves highlighted weapon cell visible %s" % cell)
	for node in battle.battle_ui._preview_panel.find_children("*","Control",true,false):
		if node.is_visible_in_tree():print("RECT ",node.get_class()," ",node.name," ",node.get_global_rect()," ",node.text if node is Label else "")
	await capture("greatsword-review")
	if not capture_dir.is_empty():
		await get_tree().create_timer(0.75).timeout
		await capture("greatsword-settled")
	before=resources();resolved.clear();seed(17)
	selection.confirm_review();selection.confirm_review();await settle()
	check(resolved.size()==2,"greatsword commits both enemies once from empty center")
	check(enemy.hp+enemy.temper < before.Enemy_1[0]+before.Enemy_1[2] and other.hp+other.temper < before.Enemy_2[0]+before.Enemy_2[2],"real greatsword hits both flank enemies")
	check(zane.hp==before.zane[0] and zane.temper==before.zane[2],"greatsword cannot hit allied hero")
	check(kael.facing=="N","aim sets cardinal attack facing")
	manager.active_unit_has_acted=false
	before=resources();resolved.clear();seed(17)
	var auto_attacked: bool=await manager._auto_try_attack(kael)
	await settle()
	check(auto_attacked and resolved.filter(func(r):return r.has("feedback_owner")).size()==2,"auto attack can choose empty greatsword center and hit both flank enemies")
	manager.active_unit_has_acted=false;manager.active_unit_has_moved=true
	check(manager.equip_test_weapon("kael","sword"),"swap allowed after movement before action")
	manager.select_command("attack")
	check(manager._attack_preview_for_tile(Vector2i(4,7)).is_empty(),"sword rejects empty aim")
	pose(zane,Vector2i(4,7))
	check(manager._attack_preview_for_tile(zane.grid_pos).is_empty(),"sword rejects allied target")
	check(manager.equip_test_weapon("kael","greatsword"),"can re-equip after a cancelled attack")
	manager.select_command("attack");selection.set_cursor(Vector2i(4,7))
	var hp_other: int=other.hp
	other.hp=0
	check(manager._weapon_targets(kael,Vector2i(4,7)).map(func(u):return u.unit_id)==["Enemy_1"],"defeated collateral excluded from authoritative weapon targets")
	other.hp=hp_other
	manager.select_command("ability")
	check(manager.tactical_grid.aoe_preview_tiles.is_empty(),"switching command clears weapon area")
	manager.current_phase=BattleManager.Phase.ENEMY_TURN
	check(not manager.equip_test_weapon("kael","sword"),"equipment cannot change during enemy phase")
	manager.current_phase=BattleManager.Phase.PLAYER_TURN
	manager.cancel_pending_action()
	check(GameState.unit_registry==registry_before,"test loadouts never alter saved unit registry")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH)==save_before,"save bytes unchanged by equipment and combat")
	battle.queue_free();await get_tree().process_frame;await get_tree().process_frame
	await boot()
	check(manager.test_weapon_id("zane")=="sword" and manager.test_weapon_id("kael")=="sword","fresh replay resets both test weapons")
	check(manager.units.zane.mp==90 and manager.units.kael.hp==380,"fresh encounter restores normal hero resources")
	selection=battle.battle_ui._selection
	selection.select_unit("zane")
	var ui=battle.battle_ui
	var settings=load("res://scripts/ui/UISettings.gd").shared()
	for hero in ["zane","kael"]:
		manager.active_unit_id=hero
		selection.select_unit(hero)
		manager.equip_test_weapon(hero,"spear" if hero=="zane" else "greatsword")
		for viewport in [Vector2i(960,540),Vector2i(1040,585),Vector2i(1120,630),Vector2i(1280,720),Vector2i(1440,810),Vector2i(1920,1080)]:
			get_window().content_scale_size=viewport;get_window().size=viewport
			for mode in [1,2,3]:
				settings.set_mode(mode,false)
				for collapsed in [false,true]:
					ui.set_tester_collapsed(collapsed)
					ui._refresh_test_weapons()
					ui._layout_persistent_hud()
					for frame in 5:await get_tree().process_frame
					for button in ui._weapon_buttons:
						check(ui._chapel_command_panel.get_global_rect().encloses(button.get_global_rect()),"weapon button accessible %s scale%s" % [viewport,mode])
						check(button.size.x>=button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x+12,"weapon label readable %s scale%s" % [viewport,mode])
	settings.set_mode(0,false)
	manager.active_unit_id="zane"
	selection.select_unit("zane")
	# Deterministic real-resolver counter KO: no mocked result or forced turn transition.
	zane=manager.units.zane;enemy=manager.units.Enemy_1;other=manager.units.Enemy_2
	pose(zane,Vector2i(4,8));pose(enemy,Vector2i(4,7));pose(other,Vector2i(4,6))
	zane.hp=1;enemy.hp=1000;other.hp=1000
	manager.equip_test_weapon("zane","spear")
	manager.select_command("attack");selection.set_cursor(enemy.grid_pos);selection.activate_cursor();seed(17)
	selection.confirm_review()
	await settle()
	check(zane.hp==0,"deterministic real counter defeats unmoved attacker")
	check(manager.active_unit_id!="zane" or manager.current_phase!=BattleManager.Phase.PLAYER_TURN,"counter KO cannot strand dead actor in player command phase")
	for frame in 2000:
		if manager.current_phase==BattleManager.Phase.PLAYER_TURN and manager.active_unit_id=="kael" and not manager.is_resolving_action:break
		await get_tree().create_timer(0.01).timeout
	check(manager.current_phase==BattleManager.Phase.PLAYER_TURN and manager.active_unit_id=="kael","normal scheduler reaches surviving ally after counter KO")


	battle.queue_free();await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	finish()
func pose(unit: Unit, cell: Vector2i) -> void:
	unit.move_to(cell)
	unit.position=battle.tactical_grid._grid_to_local(cell)
func resources() -> Dictionary:
	var result := {}
	for id in manager.units:
		var unit: Unit = manager.units[id]
		result[id]=[unit.hp,unit.mp,unit.temper]
	return result
func settle() -> void:
	for i in 1000:
		if not manager.is_resolving_action:return
		await get_tree().create_timer(0.01).timeout
	check(false,"action recovers before timeout")
func capture(label: String) -> void:
	if capture_dir.is_empty():return
	if DisplayServer.get_name()=="headless":check(false,"capture requires actual renderer");return
	for i in 5:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label+".png"))==OK,"rendered "+label)
func finish() -> void:
	print("Courtyard test weapons: %d checks, %d failures" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
