extends Node
var checks := 0
var failures: Array[String] = []
var outcomes: Array[Dictionary] = []
var phases: Array[String] = []
var enemy_turns := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  printerr("FAIL: " + message)
func _ready() -> void: call_deferred("run")
func settle(manager: BattleManager) -> void:
 for i in 1000:
  if not is_instance_valid(manager) or (not manager.is_resolving_action and manager.current_phase == BattleManager.Phase.PLAYER_TURN): return
  await get_tree().create_timer(0.02).timeout
 check(false, "bounded action/AI completion")
func run() -> void:
 var original := get_tree().current_scene
 get_tree().current_scene = null
 GameState.practice_session.clear()
 check(GameState.begin_illustrated_chapel_practice(), "production chapel admission")
 GameState.practice_session["review_hero_art"] = true
 var battle := preload("res://scenes/Battle.tscn").instantiate()
 get_tree().root.add_child(battle)
 get_tree().current_scene = battle
 var manager: BattleManager = battle.battle_manager
 var zane: Unit = manager.units.zane
 var enemy: Unit
 for u: Unit in manager.units.values():
  if u.team == "enemy": enemy = u
 manager.combat_resolver.combat_resolved.connect(func(result: Dictionary): outcomes.append(result.duplicate(true)))
 manager.phase_changed.connect(func(phase: String):
  if phase == "ENEMY_TURN": enemy_turns += 1)
 VFX.child_entered_tree.connect(func(node: Node):
  if node.has_signal("phase_presented"):
   node.connect("phase_presented", func(phase: String): phases.append(phase)))
 await settle(manager)
 var before_mp := zane.mp
 var ticket := manager.action_lifecycle.ticket
 manager.select_ability("fire")
 check(enemy.grid_pos in battle.tactical_grid.ability_tiles, "Fire target is legally highlighted")
 manager._on_tile_clicked(enemy.grid_pos)
 check(manager.is_resolving_action, "Fire acquires action guard")
 manager._on_tile_clicked(enemy.grid_pos)
 manager.select_command("wait")
 await settle(manager)
 check(zane.mp == before_mp - 12, "double click spends Fire MP exactly once")
 check(manager.action_lifecycle.ticket == ticket + 1, "Fire admits one ticket")
 check(phases.count("charge") == 1 and phases.count("release") == 1, "2D Fire has one charge/release")
 check(zane.melee_pose == "idle", "Fire restores 2D idle")
 var primary := 0
 for outcome in outcomes:
  if outcome.get("feedback_owner", "") == "zane_impact_v1": primary += 1
 check(primary == 1, "one authoritative Fire outcome")
 manager.select_command("wait")
 await get_tree().create_timer(0.1).timeout
 await settle(manager)
 check(enemy_turns > 0, "actual enemy AI responds")
 if is_instance_valid(manager) and is_instance_valid(enemy) and enemy.hp > 0:
  var distance := absi(zane.grid_pos.x-enemy.grid_pos.x)+absi(zane.grid_pos.y-enemy.grid_pos.y)
  if distance > 1:
   manager.select_command("move")
   var best := zane.grid_pos
   for cell: Vector2i in battle.tactical_grid.move_tiles:
    var d := absi(cell.x-enemy.grid_pos.x)+absi(cell.y-enemy.grid_pos.y)
    if d < distance:
     best = cell
     distance = d
   if best != zane.grid_pos: await manager._on_tile_clicked(best)
  before_mp = zane.mp
  manager.select_command("attack")
  await manager._on_tile_clicked(enemy.grid_pos)
  check(zane.mp == before_mp, "sword has zero MP cost")
  check(phases.count("charge") >= 2, "sword uses 2D anticipation")
 if is_instance_valid(manager):
  manager.auto_battle_enabled = true
  if manager.current_phase == BattleManager.Phase.PLAYER_TURN and not manager.is_resolving_action:
   manager._run_auto_player_turn(manager.active_unit_id)
 for i in 2000:
  if get_tree().current_scene is ResultsScreen: break
  await get_tree().create_timer(0.03).timeout
 check(get_tree().current_scene is ResultsScreen, "real combat reaches results")
 check(GameState.practice_session.get("state") == "won", "chapel resolves victory")
 if is_instance_valid(get_tree().current_scene):
  get_tree().current_scene.queue_free()
 await get_tree().process_frame
 get_tree().current_scene = original
 await get_tree().create_timer(0.8).timeout
 print("Chapel combat flow: %d checks, %d failures" % [checks, failures.size()])
 get_tree().quit(0 if failures.is_empty() else 1)
