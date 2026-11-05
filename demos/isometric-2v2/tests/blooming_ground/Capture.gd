extends Node
## Before/after actual integrated scene, same start state and native render size.
var output_dir := "user://ground-capture"
var label := "review"
var original_ground := false
var battle: BattleScene
func _ready() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--capture-dir="): output_dir=arg.trim_prefix("--capture-dir=")
  if arg.begins_with("--label="): label=arg.trim_prefix("--label=")
  if arg=="--original-ground": original_ground=true
 call_deferred("run")
func capture(suffix: String) -> void:
 for i in 3: await RenderingServer.frame_post_draw
 assert(get_viewport().get_texture().get_image().save_png(output_dir.path_join(label+"-"+suffix+".png"))==OK)
func run() -> void:
 if DisplayServer.get_name()=="headless":
  printerr("FAIL: native display required for ground captures")
  get_tree().quit(2); return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
 battle=load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
 add_child(battle)
 var ready := false
 for i in 600:
  if battle.battle_manager.current_phase==BattleManager.Phase.PLAYER_TURN and not battle.battle_manager.is_resolving_action:
   ready=true; break
  await get_tree().process_frame
 if not ready: printerr("FAIL: player turn unavailable"); get_tree().quit(1); return
 if original_ground:
  var terrain=battle.tactical_grid.terrain_view
  for material: ShaderMaterial in terrain._materials.values():
   material.shader=preload("res://tests/blooming_ground/OriginalSurface.gdshader")
  terrain._viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
 await get_tree().create_timer(.5).timeout
 await capture("overview")
 battle.battle_ui._selection.select_unit("zane")
 battle.battle_ui._move_btn.pressed.emit()
 await get_tree().create_timer(.2).timeout
 await capture("movement-highlights")
 var grid:=battle.tactical_grid
 var checks:={"tile_size":str(grid.tile_size),"height_step":grid.height_step,"stair_landing_height":grid._height_at(Vector2i(2,2)),"stair_foot_height":grid._height_at(Vector2i(2,6)),"move_highlights":grid.highlight_layer.get_child_count(),"zane_cell":str(battle.battle_manager.units.zane.grid_pos),"map_road_6_6":str(grid.tiles[Vector2i(6,6)].terrain),"map_stone_6_7":str(grid.tiles[Vector2i(6,7)].terrain)}
 var file:=FileAccess.open(output_dir.path_join(label+"-state.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(checks,"\t"))
 print("CAPTURE: ",JSON.stringify(checks))
 battle.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 get_tree().quit()
