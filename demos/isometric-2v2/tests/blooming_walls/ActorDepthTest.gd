extends Node
var checks:=0
var failures:=0
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: ",message)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var battle=preload("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
 add_child(battle)
 for i in 600:
  if battle.battle_manager.current_phase==BattleManager.Phase.PLAYER_TURN:break
  await get_tree().process_frame
 var installer=preload("res://prototypes/blooming/walls/WallCandidate.gd").new()
 battle.add_child(installer);installer.configure(battle.tactical_grid)
 var wall=installer.pieces[2]
 var actor: Unit=battle.battle_manager.units.zane
 check(is_instance_valid(actor._sprite) and actor._sprite.z_index==10,"actual authored sprite has relative body depth")
 actor.z_index=battle.tactical_grid._unit_depth_for(Vector2i(4,2))
 check(wall.z_index>actor.z_index+actor._sprite.z_index,"upper-terrace body actually sorts behind wall")
 var solid: Vector2=wall.faces[-1].polygon[0].lerp(wall.faces[-1].polygon[2],.5)
 actor.position=solid-actor.transform.basis_xform(Vector2(0,-32))
 wall.refresh_occlusion()
 check(wall.occluded_unit_ids.has("zane") and is_equal_approx(wall.modulate.a,.3),"actual behind actor fades solid wall")
 actor.z_index=wall.z_index-5
 wall.refresh_occlusion()
 check(wall.modulate.a==1.,"body in front does not fade despite root behind")
 actor.z_index=wall.z_index-20;actor.hide();wall.refresh_occlusion()
 check(wall.modulate.a==1.,"hidden actual sprite leaves wall opaque")
 actor.show();actor.position=Vector2(-9999,-9999);wall.refresh_occlusion()
 check(wall.modulate.a==1.,"moved actual actor restores wall")
 battle.queue_free();await get_tree().process_frame;await get_tree().process_frame
 print("Actual wall actor depth: %d checks, %d failures"%[checks,failures])
 get_tree().quit(0 if failures==0 else 1)
