extends Node
## Full encounter through the real selection/review/confirm controls.
## No forced turns, damage, stat edits, auto-battle, or direct result transitions.
## Catches deadlocked initiative, noncommitting review, unreachable surviving foes,
## premature victory, wrong Replay route, and practice leaking into saved progress.
const BATTLE := "res://prototypes/blooming/BloomingBattle.tscn"
const RESULTS := "res://scenes/ResultsScreen.tscn"
var candidate_textures := {}
var checks := 0
var failures := 0
var original_scene: Node
var saved_bytes: PackedByteArray
var turns := {}
var moves := {}
var actions := {}
var defeated: Array[String] = []
var casts := 0
var decisions := 0
var battle_instances := 0
var test_seed := 20261109

func _process(_delta: float) -> void:
 var battle := current_battle()
 if battle == null: return
 for unit in battle.battle_manager.units.values():
  if is_instance_valid(unit) and is_instance_valid(unit._sprite):
   var path: String = unit._sprite.texture.resource_path
   if '/candidate_assets/' in path: candidate_textures[path] = true

func _ready() -> void:
    run.call_deferred()

func check(ok: bool, label: String) -> bool:
    checks += 1
    if not ok:
        failures += 1
        printerr("FAIL: " + label)
    return ok

func current_battle() -> BattleScene:
    var scene := get_tree().current_scene
    if is_instance_valid(scene) and scene.scene_file_path == BATTLE:
        return scene as BattleScene
    return null

func wait_scene(path: String) -> bool:
    var deadline := Time.get_ticks_msec() + 10000
    while Time.get_ticks_msec() < deadline:
        var scene := get_tree().current_scene
        if is_instance_valid(scene) and scene.scene_file_path == path: return true
        await get_tree().process_frame
    return check(false, "transition reaches " + path)

func wait_decision() -> bool:
    var deadline := Time.get_ticks_msec() + 12000
    while Time.get_ticks_msec() < deadline:
        var battle := current_battle()
        if battle == null:
            var scene := get_tree().current_scene
            if is_instance_valid(scene) and scene.scene_file_path == RESULTS: return true
        else:
            var manager := battle.battle_manager
            if manager.current_phase == BattleManager.Phase.PLAYER_TURN and not manager.is_resolving_action:
                return true
        await get_tree().process_frame
    return check(false, "encounter returns to a player decision or results without deadlock")

func resource_state(manager: BattleManager) -> Dictionary:
    var result := {}
    for id in manager.units:
        var unit: Unit = manager.units[id]
        if is_instance_valid(unit):
            var statuses := []
            for status: StatusEffect in unit.statuses:
                statuses.append([status.status_id,status.display_name,status.duration,status.magnitude,status.damage_type])
            result[id] = [unit.grid_pos,unit.hp,unit.mp,unit.facing,unit.temper,unit.ether,statuses]
    return result

func stage_and_confirm(battle: BattleScene, cell: Vector2i, cancel_once: bool = false) -> bool:
    var manager := battle.battle_manager
    var ui = battle.battle_ui
    var selection = ui._selection
    var before := resource_state(manager)
    var moved := manager.active_unit_has_moved
    var acted := manager.active_unit_has_acted
    selection.set_cursor(cell)
    selection.activate_cursor()
    if not check(selection.has_review(), "legal target opens explicit review"): return false
    check(resource_state(manager) == before and manager.active_unit_has_moved == moved and manager.active_unit_has_acted == acted,
        "review does not spend resources, move actors, or change facing")
    if cancel_once:
        selection.go_back()
        check(not selection.has_review() and resource_state(manager) == before and manager.active_unit_has_moved == moved and manager.active_unit_has_acted == acted,
            "cancelled spell review leaves all four combatants unchanged")
        selection.activate_cursor()
        if not check(selection.has_review(), "same target can be reviewed again after cancel"): return false
    ui._on_confirm()
    return true

func enemies_by_distance(manager: BattleManager, actor: Unit) -> Array[Unit]:
    var enemies: Array[Unit] = []
    for candidate: Unit in manager.units.values():
        if is_instance_valid(candidate) and candidate.team != actor.team and candidate.hp > 0:
            enemies.append(candidate)
    enemies.sort_custom(func(a: Unit, b: Unit) -> bool:
        var da := GridSystem.manhattan(actor.grid_pos, a.grid_pos)
        var db := GridSystem.manhattan(actor.grid_pos, b.grid_pos)
        return a.unit_id < b.unit_id if da == db else da < db)
    return enemies

func try_action(battle: BattleScene, actor: Unit, enemies: Array[Unit]) -> bool:
    var manager := battle.battle_manager
    if manager.active_unit_has_acted: return false
    var ui = battle.battle_ui
    var selection = ui._selection
    # Exercise an existing spell, but fall back naturally if Silence or MP disallows it.
    if actor.unit_id == "zane" and actor.mp >= 12:
        ui._on_ability()
        selection.select_skill("fire")
        if manager.active_command == "ability_target":
            for enemy in enemies:
                if enemy.grid_pos in battle.tactical_grid.ability_tiles and not selection._preview_for_cell(enemy.grid_pos).is_empty():
                    var mp_before := actor.mp
                    if not await stage_and_confirm(battle, enemy.grid_pos, casts == 0): return false
                    casts += 1
                    await wait_decision()
                    if is_instance_valid(actor): check(actor.mp == mp_before - 12, "confirmed Fire spends exactly twelve MP")
                    return true
        selection.go_back()
    ui._on_attack()
    for enemy in enemies:
        if enemy.grid_pos in battle.tactical_grid.attack_tiles and not selection._preview_for_cell(enemy.grid_pos).is_empty():
            if not await stage_and_confirm(battle, enemy.grid_pos): return false
            await wait_decision()
            return true
    selection.go_back()
    return false

func play_decision(battle: BattleScene) -> void:
    var manager := battle.battle_manager
    var actor := manager._living_unit(manager.active_unit_id)
    if not check(actor != null and actor.team == "player", "only the current living ally receives commands"): return
    var ui = battle.battle_ui
    var selection = ui._selection
    selection.select_unit(actor.unit_id)
    var enemies := enemies_by_distance(manager, actor)
    if not check(not enemies.is_empty(), "a playable turn still has a living enemy"): return
    if await try_action(battle, actor, enemies): return
    if not manager.active_unit_has_moved:
        # This is a command-selection policy only. The real highlighted range,
        # selection controller, review and BattleManager still decide legality.
        var destination: Vector2i = manager._best_reachable_tile(actor, enemies[0], false)
        if destination != actor.grid_pos:
            ui._on_move()
            if not check(destination in battle.tactical_grid.move_tiles, "planned approach is a legal highlighted move"): return
            if not await stage_and_confirm(battle, destination): return
            await wait_decision()
            return
    ui._on_wait()
    if not check(selection._waiting_facing, "Wait requires explicit facing confirmation"): return
    selection.choose_facing("N")
    ui._on_confirm()
    await wait_decision()

func button(root: Node, caption: String) -> Button:
    for candidate in root.find_children("*", "Button", true, false):
        if candidate.text == caption: return candidate
    return null

func check_roster(battle: BattleScene, label: String) -> void:
    var manager := battle.battle_manager
    check(manager.units.size() == 4, label + ": four combatants restored")
    var expected := {"zane": [Vector2i(3,8),320,90,80,110], "kael": [Vector2i(2,9),380,55,110,70],
        "Enemy_1": [Vector2i(6,7),90,50,50,90], "Enemy_2": [Vector2i(8,2),80,80,40,100]}
    for id in expected:
        var unit: Unit = manager.units.get(id)
        check(is_instance_valid(unit), label + ": original combatant " + id)
        if is_instance_valid(unit):
            check([unit.grid_pos,unit.hp,unit.mp,unit.temper,unit.ether] == expected[id], label + ": original spawn, HP, MP and armor for " + id)
            check(unit.statuses.is_empty(), label + ": no stale status for " + id)
    check(not manager.auto_battle_enabled, label + ": player commands remain manual")

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--seed="): test_seed = int(arg.trim_prefix("--seed="))
    seed(test_seed)
    Engine.time_scale = 8.0
    GameState.save()
    saved_bytes = FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
    if not check(not saved_bytes.is_empty(), "saved-progress sentinel exists before practice"):
        await finish(); return
    get_tree().node_added.connect(func(node: Node):
        if node.scene_file_path == BATTLE: battle_instances += 1)
    original_scene = get_tree().current_scene
    get_tree().current_scene = null
    get_tree().change_scene_to_file.call_deferred(BATTLE)
    if not await wait_scene(BATTLE): await finish(); return
    var battle := current_battle()
    check_roster(battle, "initial")
    if failures > 0: await finish(); return
    var manager := battle.battle_manager
    if manager.current_phase == BattleManager.Phase.PLAYER_TURN:
        turns[manager.active_unit_id] = 1
    manager.turn_started.connect(func(id: String, _team: String): turns[id] = int(turns.get(id,0)) + 1)
    manager.unit_moved.connect(func(id: String, _from: Vector2i, _to: Vector2i): moves[id] = int(moves.get(id,0)) + 1)
    manager.unit_defeated.connect(func(id: String): defeated.append(id))
    manager.combat_resolver.combat_resolved.connect(func(_result: Dictionary):
        actions[manager.active_unit_id] = int(actions.get(manager.active_unit_id,0)) + 1)
    if not await wait_decision(): await finish(); return
    seed(test_seed)
    while current_battle() != null and decisions < 80 and failures == 0:
        decisions += 1
        await play_decision(current_battle())
    if failures > 0: await finish(); return
    if not check(current_battle() == null, "normal confirmed commands finish the encounter within 80 decisions"):
        await finish(); return
    if not await wait_scene(RESULTS): await finish(); return
    check(GameState.practice_session.get("state") == "won", "normal combat reaches victory")
    check(defeated.has("Enemy_1") and defeated.has("Enemy_2"), "both enemies were defeated before victory")
    check(turns.has("zane") and turns.has("kael"), "both allies receive ordinary initiative turns")
    check(actions.has("Enemy_1") or actions.has("Enemy_2"), "enemy AI resolves a real combat action")
    check(moves.has("zane") and moves.has("kael"), "both allies traverse the courtyard using confirmed moves")
    check(casts > 0, "fight includes a confirmed Fire cast")
    check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == saved_bytes, "complete fight leaves saved progress unchanged")
    var retry := button(get_tree().current_scene, "Replay Fight")
    if not check(retry != null and not retry.disabled, "victory offers an enabled real Replay control"):
        await finish(); return
    retry.pressed.emit()
    retry.pressed.emit()
    if not await wait_scene(BATTLE): await finish(); return
    check(battle_instances == 2, "duplicate Replay press creates only one new battle")
    battle = current_battle()
    check_roster(battle, "replay")
    check(GameState.practice_session.get("state") == "playing", "Replay resets lifecycle to playing")
    check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == saved_bytes, "Replay preserves saved progress")
    if not await wait_decision(): await finish(); return
    manager = battle.battle_manager
    check(not manager.active_unit_has_moved and not manager.active_unit_has_acted,
        "replayed ally starts with both move and action available")
    var actor := manager._living_unit(manager.active_unit_id)
    var ui = battle.battle_ui
    ui._selection.select_unit(actor.unit_id)
    ui._on_move()
    if check(not battle.tactical_grid.move_tiles.is_empty(), "replayed ally has legal movement"):
        var destination: Vector2i = battle.tactical_grid.move_tiles[0]
        if await stage_and_confirm(battle, destination):
            await wait_decision()
            check(actor.grid_pos == destination and manager.active_unit_has_moved and not manager.active_unit_has_acted,
                "replayed selection and confirmation commit a fresh move without spending action")
    check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == saved_bytes, "post-Replay command preserves saved progress")
    await finish()

func finish() -> void:
    check(candidate_textures.size() >= 3, 'full encounter actually used candidate source textures')
    print('Candidate textures observed in live match: ' + str(candidate_textures.keys()))
    print("Courtyard match evidence: seed=%d decisions=%d casts=%d turns=%s moves=%s actions=%s defeated=%s replays=%d" %
        [test_seed,decisions,casts,str(turns),str(moves),str(actions),str(defeated),maxi(0,battle_instances - 1)])
    if is_instance_valid(get_tree().current_scene) and get_tree().current_scene != original_scene:
        get_tree().current_scene.queue_free()
    get_tree().current_scene = original_scene
    Engine.time_scale = 1.0
    for voice in get_node("/root/AudioSettings").get_children():
        if voice is AudioStreamPlayer:
            voice.stop()
            voice.stream = null
    await get_tree().create_timer(1.0).timeout
    print("Courtyard full match: %d checks, %d failures" % [checks,failures])
    get_tree().quit(0 if failures == 0 else 1)
