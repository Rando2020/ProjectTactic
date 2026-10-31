extends Node

const BATTLE := "res://prototypes/isometric/Battle.tscn"
var checks := 0
var failures: Array[String] = []
var original_scene: Node
var saved_bytes: PackedByteArray

func _ready() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: " + label)

func wait_scene(path: String) -> bool:
	for i in 1200:
		if is_instance_valid(get_tree().current_scene) and get_tree().current_scene.scene_file_path == path:
			return true
		await get_tree().create_timer(0.025).timeout
	check(false, "transition to " + path)
	return false

func wait_idle(manager: BattleManager) -> void:
	for i in 1000:
		if not is_instance_valid(manager): return
		if not manager.is_resolving_action and manager.current_phase == BattleManager.Phase.PLAYER_TURN: return
		await get_tree().create_timer(0.025).timeout
	check(false, "idle player turn")

func button(root: Node, label: String) -> Button:
	for child in root.find_children("*", "Button", true, false):
		if child.text == label: return child
	return null

func fresh_battle() -> BattleScene:
	var battle := get_tree().current_scene as BattleScene
	await wait_idle(battle.battle_manager)
	# Preserve the legacy original-appearance contract; compact is tested separately.
	battle.set_compact_skins(false)
	check(battle.tactical_grid.map_data.id == "painted_chapel_practice", "painted map on entry/retry")
	check(battle.battle_manager.units.size() == 2, "two real fighters")
	check(not is_instance_valid(battle.tactical_grid.terrain_view), "no 3D terrain")
	var zane: Unit = battle.battle_manager.units.zane
	check(not is_instance_valid(zane._rig3d), "no character rig")
	check(zane.grid_pos == Vector2i(1, 3) and zane.hp == 320 and zane.mp == 90, "initial position HP MP restored")
	check(zane._sprite.texture.resource_path.contains("prototypes/isometric/assets/zane-"), "approved scarf-and-coat sprite, not plate fallback")
	for direction in ["N", "E", "S", "W"]:
		zane.set_facing(direction)
		check(zane._sprite.scale.is_equal_approx(Vector2.ONE * 86.0 / 1080.0), "small sprite scale retained on " + direction)
		check(zane._sprite.position == Vector2.ZERO, "foot origin retained on " + direction)
	zane.set_facing("E")
	return battle

func replay(expected: String) -> BattleScene:
	check(GameState.practice_session.get("state") == expected, "real " + expected + " result")
	var result := get_tree().current_scene
	var retry := button(result, "Replay Fight")
	check(retry != null, "retry button exists")
	if retry == null: return null
	retry.pressed.emit()
	retry.pressed.emit()
	check(not GameState.retry_practice(), "double retry rejected")
	if not await wait_scene(BATTLE): return null
	return await fresh_battle()

func run() -> void:
	Engine.time_scale = 5.0
	original_scene = get_tree().current_scene
	get_tree().current_scene = null
	GameState.practice_session.clear()
	get_tree().change_scene_to_file.call_deferred(BATTLE)
	if not await wait_scene(BATTLE):
		finish()
		return
	var battle := await fresh_battle()
	saved_bytes = FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	var manager := battle.battle_manager
	var zane: Unit = manager.units.zane
	var enemy: Unit = manager.units.Enemy_1
	var events := {"enemy": 0, "resolved": 0, "player_mp": 90}
	manager.turn_started.connect(func(_id: String, team: String):
		if team == "enemy": events.enemy += 1)
	manager.combat_resolver.combat_resolved.connect(func(_result: Dictionary):
		events.resolved += 1
		if manager.active_unit_id == "zane": events.player_mp = manager.units.zane.mp)
	var before := [zane.hp, zane.mp, zane.grid_pos, enemy.hp]
	manager.select_ability("fire")
	check(enemy.grid_pos in battle.tactical_grid.ability_tiles, "Fire target highlighted")
	await get_tree().create_timer(1.0).timeout
	check(events.enemy == 0 and before == [zane.hp,zane.mp,zane.grid_pos,enemy.hp], "preview cannot advance enemy or spend resources")
	manager.cancel_pending_action()
	check(not manager.active_unit_has_acted and zane.mp == 90, "cancel keeps action and MP")
	manager.select_command("attack")
	await manager._on_tile_clicked(enemy.grid_pos)
	check(not manager.active_unit_has_acted and enemy.hp == 90, "out of range attack rejected")
	manager.select_command("move")
	await manager._on_tile_clicked(Vector2i(2,3))
	check(zane.grid_pos == Vector2i(2,3), "actual move to selected square")
	manager.select_command("attack")
	await manager._on_tile_clicked(enemy.grid_pos)
	check(events.resolved == 1 and zane.mp == 90, "sword resolves once without MP")
	await wait_idle(manager)
	check(events.enemy > 0 and events.resolved > 1, "enemy takes its own actual resolving turn")
	var mp_before := zane.mp
	manager.select_ability("fire")
	manager._on_tile_clicked(enemy.grid_pos)
	manager._on_tile_clicked(enemy.grid_pos)
	for i in 1000:
		if not is_instance_valid(manager) or not manager.is_resolving_action: break
		await get_tree().create_timer(0.025).timeout
	check(events.player_mp == mp_before - 12, "double confirm spends Fire MP exactly once")
	if is_instance_valid(manager):
		manager.auto_battle_enabled = true
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN:
			manager._run_auto_player_turn(manager.active_unit_id)
	if await wait_scene("res://scenes/ResultsScreen.tscn"):
		battle = await replay("won")
	if is_instance_valid(battle):
		manager = battle.battle_manager
		# Deliberate lifecycle fixture, not a natural-loss/balance claim.
		manager.units.zane.receive_damage(99999, "pure")
		manager._set_phase(BattleManager.Phase.CHECK_OBJECTIVE)
		if await wait_scene("res://scenes/ResultsScreen.tscn"):
			battle = await replay("lost")
	if is_instance_valid(battle):
		manager = battle.battle_manager
		manager.units.zane.receive_damage(99999, "pure")
		manager._set_phase(BattleManager.Phase.CHECK_OBJECTIVE)
		if await wait_scene("res://scenes/ResultsScreen.tscn"):
			var leave := button(get_tree().current_scene, "Return to Hearth")
			check(leave != null, "exit button exists")
			if leave:
				leave.pressed.emit()
				leave.pressed.emit()
				await wait_scene("res://prototypes/isometric/Title.tscn")
				check(GameState.practice_session.is_empty(), "exit clears proof session")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == saved_bytes, "combat retry exit preserve saved profile bytes")
	finish()

func finish() -> void:
	if is_instance_valid(get_tree().current_scene):
		get_tree().current_scene.queue_free()
	get_tree().current_scene = original_scene
	Engine.time_scale = 1.0
	for voice in get_node("/root/AudioSettings").get_children():
		if voice is AudioStreamPlayer:
			voice.stop()
			voice.stream = null
	await get_tree().create_timer(2.0).timeout
	print("Isometric proof: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
