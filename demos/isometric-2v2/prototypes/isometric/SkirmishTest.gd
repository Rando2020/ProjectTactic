extends Node
var checks := 0
var failures := 0
const BATTLE := "res://prototypes/isometric/Skirmish.tscn"
var original_scene: Node
var saved_bytes: PackedByteArray

func _ready() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func wait_scene(path: String) -> bool:
	for i in 2000:
		if is_instance_valid(get_tree().current_scene) and get_tree().current_scene.scene_file_path == path: return true
		await get_tree().create_timer(0.025).timeout
	check(false, "transition to " + path)
	return false
func wait_player(manager: BattleManager) -> void:
	for i in 2000:
		if not is_instance_valid(manager): return
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN and not manager.is_resolving_action: return
		await get_tree().create_timer(0.025).timeout
	check(false, "real allied turn")
func button(root: Node, caption: String) -> Button:
	for child in root.find_children("*", "Button", true, false):
		if child.text == caption: return child
	return null
func check_roster(battle: BattleScene) -> void:
	var manager := battle.battle_manager
	check(manager.units.size() == 4, "exactly four fighters")
	check(manager.units.has("zane") and manager.units.has("kael"), "Zane and Kael are real allies")
	check(manager.units.Enemy_1.unit_data.id == "storm_imp" and manager.units.Enemy_2.unit_data.id == "void_cultist", "two distinct existing foes")
	var positions := {}
	for unit: Unit in manager.units.values():
		check(battle.tactical_grid.tiles.has(unit.grid_pos) and not positions.has(unit.grid_pos), "all four spawns legal and distinct")
		positions[unit.grid_pos] = true
		check(unit.hp == unit.unit_data.base_stats.hp and unit.mp == unit.unit_data.base_stats.mp, "full starting resources for " + unit.unit_id)
		check(not is_instance_valid(unit._rig3d), "2D actor " + unit.unit_id)
	check(manager.units.zane.grid_pos == Vector2i(1,3) and manager.units.kael.grid_pos == Vector2i(1,4), "both allied starting cells restored")
	check(battle.tactical_grid.map_data.id == "painted_chapel_practice" and battle.tactical_grid.has_node("PaintedBackground"), "same painted arena, no new map")
func replay(state: String) -> BattleScene:
	check(GameState.practice_session.get("state") == state, "actual " + state + " lifecycle")
	var retry := button(get_tree().current_scene, "Replay Fight")
	check(retry != null, "real replay available")
	if retry == null: return null
	retry.pressed.emit()
	retry.pressed.emit()
	check(not GameState.retry_practice(), "duplicate retry rejected")
	if not await wait_scene(BATTLE): return null
	var battle := get_tree().current_scene as BattleScene
	check_roster(battle)
	await wait_player(battle.battle_manager)
	return battle
func run() -> void:
	Engine.time_scale = 5
	original_scene = get_tree().current_scene
	get_tree().current_scene = null
	get_tree().change_scene_to_file.call_deferred(BATTLE)
	if not await wait_scene(BATTLE):
		finish(); return
	var battle := get_tree().current_scene as BattleScene
	check_roster(battle)
	saved_bytes = FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	var manager := battle.battle_manager
	await wait_player(manager)
	var seen := {"zane": true}
	var enemy_actions := {}
	var kael_hud := {"shown":false, "portrait":false, "moved":false}
	manager.turn_started.connect(func(id: String, team: String):
		seen[id] = true
		if id == "kael" and team == "player":
			kael_hud.shown = battle.battle_ui._unit_name.text.contains("Kael")
			kael_hud.portrait = battle.battle_ui._active_portrait.texture == battle.battle_ui._framed_portrait("kael"))
	manager.combat_resolver.combat_resolved.connect(func(_result: Dictionary):
		if manager.active_unit_id.begins_with("Enemy_"): enemy_actions[manager.active_unit_id] = true)
	var zane: Unit = manager.units.zane
	var mp := zane.mp
	manager.select_ability("fire")
	await get_tree().create_timer(0.5).timeout
	check(seen.size() == 1 and zane.mp == mp, "preview pauses initiative and costs nothing")
	manager.cancel_pending_action()
	check(zane.mp == mp and not manager.active_unit_has_acted, "cancel preserves MP action")
	manager.select_command("move")
	await manager._on_tile_clicked(Vector2i(2,3))
	check(zane.grid_pos == Vector2i(2,3), "actual Zane move")
	# Fire before the enemy cultist can legitimately Silence Zane.
	var fire_mp := {"value":-1}
	manager.combat_resolver.combat_resolved.connect(func(_result: Dictionary):
		if manager.active_unit_id == "zane": fire_mp.value = manager.units.zane.mp)
	mp = zane.mp
	manager.select_ability("fire")
	var target: Vector2i = manager.units.Enemy_2.grid_pos
	check(target in battle.tactical_grid.ability_tiles, "cultist is a legal Fire target after approach")
	manager._on_tile_clicked(target)
	manager._on_tile_clicked(target)
	for i in 1000:
		if not is_instance_valid(manager) or not manager.is_resolving_action: break
		await get_tree().create_timer(0.025).timeout
	check(fire_mp.value == mp - 12, "Fire commits once and spends twelve MP")
	await wait_player(manager)
	# Wait through ordinary initiative, never force an actor's turn.
	for i in 12:
		if manager.active_unit_id == "kael" and not kael_hud.moved:
			var zane_position: Vector2i = manager.units.zane.grid_pos
			manager.select_command("move")
			check(not battle.tactical_grid.move_tiles.is_empty(), "Kael has his own legal movement")
			if not battle.tactical_grid.move_tiles.is_empty():
				var destination: Vector2i = battle.tactical_grid.move_tiles[0]
				await manager._on_tile_clicked(destination)
				kael_hud.moved = manager.units.kael.grid_pos == destination and manager.units.zane.grid_pos == zane_position
		if kael_hud.moved and enemy_actions.has("Enemy_1") and enemy_actions.has("Enemy_2"): break
		manager.select_command("wait")
		await wait_player(manager)
	check(seen.has("kael") and kael_hud.shown and kael_hud.portrait, "second ally activates with his own name and portrait")
	check(kael_hud.moved, "Kael command moves Kael, not Zane")
	check(enemy_actions.has("Enemy_1") and enemy_actions.has("Enemy_2"), "both enemies execute their normal combat AI")
	if is_instance_valid(manager):
		manager.auto_battle_enabled = true
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: manager._run_auto_player_turn(manager.active_unit_id)
	if await wait_scene("res://scenes/ResultsScreen.tscn"):
		battle = await replay("won")
	if is_instance_valid(battle):
		manager = battle.battle_manager
		# Explicit partial-death lifecycle fixture, not a balance claim.
		manager.units.Enemy_1.receive_damage(99999,"pure")
		check(not manager.objective_tracker.is_victory(), "one dead enemy is not victory")
		manager.units.zane.receive_damage(99999,"pure")
		check(not manager.objective_tracker.is_defeat(), "one fallen ally is not defeat")
		manager.units.kael.receive_damage(99999,"pure")
		check(manager.objective_tracker.is_defeat(), "both fallen allies cause defeat")
		manager._set_phase(BattleManager.Phase.CHECK_OBJECTIVE)
		if await wait_scene("res://scenes/ResultsScreen.tscn"): battle = await replay("lost")
	if is_instance_valid(battle):
		manager = battle.battle_manager
		manager.units.Enemy_1.receive_damage(99999,"pure")
		check(not manager.objective_tracker.is_victory(), "victory still awaits second enemy after retry")
		manager.units.Enemy_2.receive_damage(99999,"pure")
		check(manager.objective_tracker.is_victory(), "both enemies defeated gives victory")
		manager._set_phase(BattleManager.Phase.CHECK_OBJECTIVE)
		if await wait_scene("res://scenes/ResultsScreen.tscn"):
			var leave := button(get_tree().current_scene,"Return to Hearth")
			leave.pressed.emit()
			await wait_scene("res://prototypes/isometric/Title.tscn")
			check(GameState.practice_session.is_empty(), "exit restores profile and clears session")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == saved_bytes, "four-unit combat retry exit preserve saved bytes")
	finish()
func finish() -> void:
	if is_instance_valid(get_tree().current_scene): get_tree().current_scene.queue_free()
	get_tree().current_scene = original_scene
	Engine.time_scale = 1
	for voice in get_node("/root/AudioSettings").get_children():
		if voice is AudioStreamPlayer:
			voice.stop(); voice.stream = null
	await get_tree().create_timer(2).timeout
	print("Isometric skirmish: %d failures (%d checks)" % [failures,checks])
	get_tree().quit(0 if failures == 0 else 1)
