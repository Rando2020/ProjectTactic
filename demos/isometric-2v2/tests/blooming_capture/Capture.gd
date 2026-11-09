extends Node
## Real scene, real commands, normal engine timing. No forced rolls or post-dub audio.
var output_dir := "user://blooming-capture"
var diagnostics_only := false
var battle: BattleScene
var records: Array[Dictionary] = []
var failures: Array[String] = []
var started := 0
var simulation_seconds := 0.0
func _process(delta: float) -> void:
	simulation_seconds += delta
func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): output_dir = arg.trim_prefix("--capture-dir=")
		if arg == "--headless-diagnostics": diagnostics_only = true
	call_deferred("run")
func fail(message: String) -> void:
	failures.append(message)
	printerr("CAPTURE FAIL: ", message)
func capture(label: String) -> void:
	if not diagnostics_only:
		await RenderingServer.frame_post_draw
		var result := get_viewport().get_texture().get_image().save_png(output_dir.path_join(label+".png"))
		if result != OK: fail("PNG save failed: "+label)
	var manager := battle.battle_manager
	var record := {"label":label,"wall_elapsed_ms":Time.get_ticks_msec()-started,"simulation_seconds":simulation_seconds,"time_scale":Engine.time_scale,
		"active":manager.active_unit_id,"command":manager.active_command,"resolving":manager.is_resolving_action,
		"zane_mp":manager.units.zane.mp,"imp_hp":manager.units.Enemy_1.hp,
		"objective_text":battle.battle_ui._objective_label.text,"objective_visible":battle.battle_ui._objective_label.is_visible_in_tree(),
		"objective_rect":str(battle.battle_ui._objective_label.get_global_rect())}
	records.append(record)
	print("CAPTURE ",JSON.stringify(record))
func wait_player() -> bool:
	for i in 600:
		if battle.battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN and not battle.battle_manager.is_resolving_action: return true
		await get_tree().process_frame
	fail("No normal player turn")
	return false
func fire_sprite() -> Node:
	for node in get_node("/root/VFX").find_children("*","Sprite2D",true,false):
		if node.get_script() and node.get_script().resource_path == "res://scripts/presentation/FireballFrames.gd" and node.is_visible_in_tree():
			return node
	return null
func run() -> void:
	if DisplayServer.get_name() == "headless" and not diagnostics_only:
		fail("Native rendering required for PNG capture; headless diagnostics does not claim images")
		get_tree().quit(1)
		return
	if Engine.time_scale != 1.0:
		fail("Capture requires existing normal time scale")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	started = Time.get_ticks_msec()
	battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
	add_child(battle)
	if not await wait_player(): finish(); return
	await get_tree().create_timer(4.0).timeout
	await capture("01_initial")
	var manager := battle.battle_manager
	var ui = battle.battle_ui
	ui._selection.select_unit("zane")
	await get_tree().create_timer(0.6).timeout
	await capture("02_commands")
	ui._move_btn.pressed.emit()
	await manager._on_tile_clicked(Vector2i(4,8))
	await get_tree().create_timer(0.3).timeout
	if manager.units.zane.grid_pos != Vector2i(4,8): fail("Real approach movement did not complete"); finish(); return
	ui._selection.select_unit("zane")
	ui._ability_btn.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	await capture("03_skills")
	var fire_button: Button
	var fire_name := str(AbilityDB.get_ability("fire").get("display_name","fire"))
	for button in ui._ability_list.get_children():
		if not button is Button or button.is_queued_for_deletion(): continue
		for label in button.find_children("*","Label",true,false):
			if label.text == fire_name: fire_button = button
	if not fire_button: fail("Actual Fire skill button not found"); finish(); return
	fire_button.pressed.emit()
	var target: Vector2i = manager.units.Enemy_1.grid_pos
	if not target in battle.tactical_grid.ability_tiles: fail("Actual Fire target not legal"); finish(); return
	ui._selection.set_cursor(target)
	await get_tree().create_timer(0.7).timeout
	await capture("04_forecast")
	var before_mp: int = manager.units.zane.mp
	manager._on_tile_clicked(target)
	var captured := {}
	var phase_names := {"charge":"05_charge","travel":"06_release","impact":"07_impact","dissipate":"08_decay"}
	var phase_elapsed := 0.0
	while phase_elapsed < 10.0:
		var sprite := fire_sprite()
		if sprite and phase_names.has(sprite.stage) and not captured.has(sprite.stage) and sprite.frame_index % 4 >= 1:
			var stage: String = sprite.stage
			captured[stage] = true
			await capture(phase_names[stage])
		if captured.size()==4: break
		await get_tree().process_frame
		phase_elapsed += get_process_delta_time()
	for stage in phase_names:
		if not captured.has(stage): fail("Phase not observed: "+stage+" (a real miss/immune outcome may omit impact)")
	await get_tree().create_timer(2.0).timeout
	await capture("09_recovery")
	if manager.units.zane.mp != before_mp-12: fail("Fire did not spend exactly twelve MP once")
	finish()
func finish() -> void:
	var file := FileAccess.open(output_dir.path_join("capture-evidence.json"),FileAccess.WRITE)
	if file: file.store_string(JSON.stringify({"normal_engine_timing":true,"diagnostics_only":diagnostics_only,"captures":records,"failures":failures},"\t"))
	print("Blooming capture: ",records.size()," records, ",failures.size()," failures")
	if is_instance_valid(battle):
		battle.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
