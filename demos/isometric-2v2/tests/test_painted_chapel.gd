extends Node

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func run() -> void:
	GameState.practice_session.clear()
	check(GameState.begin_illustrated_chapel_practice(), "practice admitted")
	GameState.practice_session["painted_chapel"] = true
	var before := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	var battle := preload("res://scenes/Battle.tscn").instantiate() as BattleScene
	add_child(battle)
	await get_tree().process_frame
	await get_tree().process_frame
	var grid := battle.tactical_grid
	var manager := battle.battle_manager
	check(grid.map_data.id == "painted_chapel_practice", "painted demo map loaded")
	check(grid.tiles.size() == 25, "only lower-floor 5x5 arena is playable")
	check(grid.tile_size == Vector2i(128, 64), "grid scale matches plate calibration")
	check(grid.has_node("PaintedBackground"), "background loaded in actual scene")
	if grid.has_node("PaintedBackground"):
		check(grid.get_node("PaintedBackground").texture.get_size() == Vector2(1536,1024), "actual approved image dimensions")
	for pos: Vector2i in grid.tiles:
		check(grid._local_to_grid(grid._grid_to_local(pos)) == pos, "cell center picking round trip %s" % pos)
		check(grid.tiles[pos].height == 0, "painted stairs confer no hidden elevation")
	check(grid._local_to_grid(grid.map_origin + Vector2(0,-100)) == Vector2i(-1,-1), "scenery above grid cannot be picked")
	check(manager.units.size() == 2, "exactly two fighters")
	var zane: Unit = manager.units.zane
	var enemy: Unit = manager.units.Enemy_1
	check(zane.grid_pos == Vector2i(1,3) and enemy.grid_pos == Vector2i(3,3), "legal compact spawns")
	for i in 300:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN and not manager.is_resolving_action: break
		await get_tree().create_timer(0.025).timeout
	manager.select_command("move")
	check(Vector2i(2,3) in grid.move_tiles, "sword approach is reachable")
	for pos: Vector2i in grid.move_tiles:
		check(grid.tiles.has(pos), "movement stays inside painted arena")
	manager.cancel_pending_action()
	var mp := zane.mp
	manager.select_ability("fire")
	check(enemy.grid_pos in grid.ability_tiles, "Fire reaches target from initial spawn")
	manager.cancel_pending_action()
	check(zane.mp == mp and not manager.active_unit_has_acted, "cancel spends no MP or action")
	manager.select_command("move")
	await manager._on_tile_clicked(Vector2i(2,3))
	for i in 300:
		if not manager.is_resolving_action: break
		await get_tree().create_timer(0.025).timeout
	check(zane.grid_pos == Vector2i(2,3), "actual command moves actor to selected cell")
	manager.select_ability("fire")
	manager._on_tile_clicked(enemy.grid_pos)
	for i in 600:
		if not manager.is_resolving_action: break
		await get_tree().create_timer(0.025).timeout
	check(zane.mp == mp - 12, "actual Fire spends canonical 12 MP")
	check(enemy.hp < 90, "actual Fire damages enemy")
	for i in 3:
		grid.redraw_base_tiles()
		await get_tree().process_frame
	check(grid.get_children().filter(func(child): return child.has_meta("painted_background")).size() == 1, "redraw leaves one background")
	battle.queue_free()
	await get_tree().process_frame
	GameState.practice_session["state"] = "won"
	check(GameState.retry_practice(), "retry restores checkpoint")
	check(GameState.practice_session.get("painted_chapel", false), "retry retains painted mode")
	var retry := preload("res://scenes/Battle.tscn").instantiate() as BattleScene
	add_child(retry)
	await get_tree().process_frame
	check(retry.tactical_grid.map_data.id == "painted_chapel_practice", "retry reloads same map")
	check(retry.battle_manager.units.zane.grid_pos == Vector2i(1,3), "retry restores initial spawn")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == before, "fight and retry preserve saved profile")
	retry.queue_free()
	await get_tree().process_frame
	GameState.practice_session.clear()
	for voice in get_node("/root/AudioSettings").get_children():
		if voice is AudioStreamPlayer:
			voice.stop()
			voice.stream = null
			voice.queue_free()
	await get_tree().create_timer(2.0).timeout
	print("Painted chapel: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
