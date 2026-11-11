extends Node
const BATTLE := "res://prototypes/blooming/BloomingBattle.tscn"
var checks := 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  printerr("FAIL: "+message)
func _ready() -> void: call_deferred("run")
func run() -> void:
 check(ResourceLoader.exists(BATTLE), "opt-in Blooming battle scene exists")
 if not ResourceLoader.exists(BATTLE):
  finish();return
 var scene = load(BATTLE).instantiate()
 add_child(scene)
 await get_tree().process_frame
 check(scene is BattleScene, "Blooming uses existing production BattleScene")
 check(scene.get("battle_manager") is BattleManager, "existing BattleManager owns combat")
 check(scene.get("tactical_grid") is TacticalGrid, "existing TacticalGrid owns the board")
 var manager = scene.battle_manager
 var grid = scene.tactical_grid
 check(manager.units.size()==4,"exact 2v2 roster, no separate ArtPreview encounter")
 var positions := {}
 for unit in manager.units.values():
  check(not positions.has(unit.grid_pos),"distinct actor cells")
  positions[unit.grid_pos]=true
  check(grid.tiles.has(unit.grid_pos) and not grid.tiles[unit.grid_pos].blocks_movement,"walkable spawn")
  check(unit.position.distance_to(grid._unit_foot_pos(unit.grid_pos))<0.1,"actor feet match authoritative height")
  var textures := {}
  for facing in ["N","E","S","W"]:
   unit.set_facing(facing)
   check(unit._sprite.texture!=null,"facing has texture")
   check(unit.facing==facing,"logical facing updates")
   if unit._sprite.texture:textures[unit._sprite.texture.resource_path+str(unit._sprite.flip_h)]=true
  if unit.unit_id in ["zane","kael"]:check(textures.size()==4,"four compact allied directional identities")
 var terrain=grid.terrain_view
 check(is_instance_valid(terrain) and terrain.has_method("refresh_occlusion"),"known-unit visibility presenter exists")
 if is_instance_valid(terrain) and terrain.has_method("refresh_occlusion"):
  var probe=manager.units.zane
  var previous_position:Vector2=probe.position
  var previous_depth:int=probe.z_index
  var encountered:=false
  for cell:Vector2i in grid.tiles:
   if grid.tiles[cell].blocks_movement:continue
   probe.position=grid._unit_foot_pos(cell)
   probe.z_index=grid._unit_depth_for(cell)
   terrain.refresh_occlusion()
   if "zane" in terrain.occluded_unit_ids:
    encountered=true
    var faded:=false
    for decor in terrain.decoration_nodes:
     if decor.modulate.a<0.99:faded=true
    check(faded,"known obstructed actor triggers decoration fade")
    break
  check(encountered,"some legal cell exercises actual known-unit occlusion")
  probe.position=previous_position;probe.z_index=previous_depth
  terrain.refresh_occlusion()
 # Explicit navigation fixture: reaching the stair needs temporary sideways motion.
 var cultist=manager.units.Enemy_2
 var target_unit=manager.units.zane
 var saved_enemy_cell:Vector2i=cultist.grid_pos
 var saved_target_cell:Vector2i=target_unit.grid_pos
 cultist.grid_pos=Vector2i(4,2);target_unit.grid_pos=Vector2i(4,8)
 check(manager._best_advance_tile(cultist,target_unit)!=cultist.grid_pos,"enemy escapes Manhattan local minimum via real staircase route")
 cultist.grid_pos=saved_enemy_cell;target_unit.grid_pos=saved_target_cell
 var initial_turn: String=manager.active_unit_id
 for compact in [true,false,true]:
  check(scene.set_compact_skins(compact),"appearance comparison accepted")
  check(manager.active_unit_id==initial_turn,"appearance does not spend turn")
  var active=manager.units.get(initial_turn)
  if is_instance_valid(active):
   check(scene.battle_ui._active_portrait.texture==scene.battle_ui._status_portrait(active.unit_data.id),"active portrait follows skin")
 var ui=scene.battle_ui
 var original_skin:bool=GameState.practice_session.get("compact_skins",true)
 var skin_mp:int=manager.units[initial_turn].mp
 ui._bloom_skin_toggle.pressed.emit()
 check(bool(GameState.practice_session.get("compact_skins",true))!=original_skin,"real tester appearance button switches profile")
 ui._bloom_skin_toggle.pressed.emit()
 check(bool(GameState.practice_session.get("compact_skins",true))==original_skin,"real appearance button restores profile")
 check(manager.active_unit_id==initial_turn and manager.units[initial_turn].mp==skin_mp,"appearance button preserves active turn and MP")
 manager.is_resolving_action=true
 await get_tree().process_frame
 check(ui._bloom_skin_toggle.disabled,"appearance control disabled during resolution")
 manager.is_resolving_action=false
 await get_tree().process_frame
 ui._selection.select_unit(initial_turn)
 var selected_before:String=ui._selection.selected_id
 var position_before:Vector2i=manager.units[initial_turn].grid_pos
 var mp_before:int=manager.units[initial_turn].mp
 for key in [KEY_Q,KEY_E,KEY_Q,KEY_E]:
  var event:=InputEventKey.new();event.pressed=true;event.keycode=key
  scene._unhandled_input(event)
  check(ui._bloom_hint.text.contains("Fixed courtyard"),"Q/E gives explicit fixed-camera feedback")
  check(manager.active_unit_id==initial_turn and ui._selection.selected_id==selected_before,"Q/E preserves turn and selection")
  check(manager.units[initial_turn].grid_pos==position_before and manager.units[initial_turn].mp==mp_before,"Q/E does not move or spend resources")
 ui._magic_btn.pressed.emit()
 var black_button:Button
 for button in ui._ability_list.get_children():
  if button is Button and str(button.get_meta("magic_school", "")) == "black":black_button=button
 check(black_button!=null,"Magic exposes Black Magic school")
 if black_button:black_button.pressed.emit()
 var fire_button:Button
 for button in ui._ability_list.get_children():
  if button is Button and str(button.get_meta("ability_id", "")) == "fire":fire_button=button
 check(fire_button!=null,"Black Magic exposes Fire leaf")
 if fire_button:fire_button.pressed.emit()
 ui._selection.go_back()
 check(get_viewport().gui_get_focus_owner()!=ui._wait_btn,"cancel focus never poised on Wait")
 check(manager.units[initial_turn].mp==mp_before and not manager.active_unit_has_acted,"menu cancel preserves MP/action")
 scene.queue_free()
 await get_tree().process_frame
 for voice in get_node("/root/AudioSettings").get_children():
  if voice is AudioStreamPlayer:voice.stop();voice.stream=null
 await get_tree().create_timer(0.5).timeout
 finish()
func finish() -> void:
 print("Blooming integration: %d checks, %d failures" % [checks, failures.size()])
 get_tree().quit(0 if failures.is_empty() else 1)
