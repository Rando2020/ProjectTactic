extends Node
## Read-only bounded snapshots. No setters, combat callbacks or RNG overrides.
var elapsed := 0.0
var enemy_turns := 0
var last_phase := ""
func point(value: Vector2) -> Array:
 return [value.x, value.y]
func _process(delta: float) -> void:
 if not OS.has_feature("web"): return
 elapsed += delta
 if elapsed < 0.025: return
 elapsed = 0.0
 var scene := get_tree().current_scene
 if not is_instance_valid(scene): return
 var state := {"scene":scene.scene_file_path, "viewport":point(get_viewport().get_visible_rect().size), "buttons":[], "enemy_turns":enemy_turns}
 for button in scene.find_children("*", "Button", true, false):
  if button.is_visible_in_tree() and not button.disabled:
   state.buttons.append({"text":button.text, "point":point(button.get_global_rect().get_center())})
 if scene is BattleScene:
  var manager: BattleManager = scene.battle_manager
  var grid: TacticalGrid = scene.tactical_grid
  state.phase = BattleManager.Phase.keys()[manager.current_phase]
  if state.phase == "ENEMY_TURN" and last_phase != state.phase: enemy_turns += 1
  last_phase = state.phase
  state.busy = manager.is_resolving_action
  state.ticket = manager.action_lifecycle.ticket
  state.action_phase = manager.action_lifecycle.phase
  state.command = manager.active_command
  state.units = []
  for unit: Unit in manager.units.values():
   var screen := unit.get_global_transform_with_canvas() * Vector2.ZERO
   state.units.append({"id":unit.unit_id,"team":unit.team,"hp":unit.hp,"mp":unit.mp,"facing":unit.facing,"pose":unit.melee_pose,"grid":[unit.grid_pos.x,unit.grid_pos.y],"point":point(screen),"moved":unit.has_moved,"acted":unit.has_acted})
  state.moves = []
  for cell: Vector2i in grid.move_tiles:
   state.moves.append({"grid":[cell.x,cell.y],"point":point(grid.get_global_transform_with_canvas()*grid._grid_to_local(cell))})
  state.abilities = []
  for cell: Vector2i in grid.ability_tiles:
   state.abilities.append([cell.x,cell.y])
  state.preview = scene.get_node("BattleUI")._preview_amount_label.text
  state.intro = scene.get_node("BattleUI")._intro_banner.visible
 elif scene is ResultsScreen:
  state.result = GameState.practice_session.get("state", "")
 JavaScriptBridge.eval("window.__chapelQA = " + JSON.stringify(state) + ";", true)
