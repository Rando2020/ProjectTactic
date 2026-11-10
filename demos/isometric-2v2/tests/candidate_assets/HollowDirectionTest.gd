extends Node
## Catches missing/wrong enemy facing textures, handedness mirroring, stale cast
## poses after rotation, and unsafe fallback when a future facing is absent.
var checks := 0
var failures := 0
const FILES := {
 "N": "hollow-idle-ne-candidate.png",
 "E": "hollow-idle-se-candidate.png",
 "S": "enemy-hollow-stray-sw-idle-candidate-v02.png",
 "W": "hollow-idle-nw-candidate.png"
}
const ROTATED := [
 ["N", "E", "S", "W"],
 ["E", "S", "W", "N"],
 ["S", "W", "N", "E"],
 ["W", "N", "E", "S"]
]
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  printerr("FAIL: " + label)
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 var battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
 add_child(battle)
 await get_tree().process_frame
 var unit = battle.battle_manager.units["Enemy_1"]
 var before = [unit.grid_pos, unit.hp, unit.mp]
 var facings := ["N", "E", "S", "W"]
 for quarter in range(4):
  unit.set_view_quarter(quarter)
  for i in range(4):
   unit.set_facing(facings[i])
   var view: String = ROTATED[quarter][i]
   check(unit._sprite.texture.resource_path.ends_with(FILES[view]), "rotation %d/%s renders %s" % [quarter, facings[i], FILES[view]])
   check(not unit._sprite.flip_h, "equipment is not horizontally mirrored")
   check(unit._sprite.position == Vector2.ZERO, "candidate is foot-pivoted at tile origin")
   var cast_ok: bool = unit.set_cast_pose("anticipation")
   check(cast_ok == (view == "S"), "only authored SW cast is advertised")
   if cast_ok:
    check(unit._sprite.texture.resource_path.ends_with("enemy-hollow-stray-sw-cast-windup-candidate-v02.png"), "SW uses real windup")
   else:
    check(not unit.set_cast_pose("release"), "unsupported release is rejected")
    check(unit._sprite.texture.resource_path.ends_with(FILES[view]), "unsupported cast keeps correctly facing idle")
   unit.reset_melee_pose()
   check(unit._sprite.texture.resource_path.ends_with(FILES[view]), "cancel restores correct idle")
 unit.set_view_quarter(0)
 for direction in ["N", "E", "W"]:
  unit.set_facing("S")
  unit.set_cast_pose("release")
  unit.set_facing(direction)
  check(unit._sprite.texture.resource_path.ends_with(FILES[direction]), "turning out of release restores new idle")
  check(unit.candidate_pose == "idle", "turning clears cast state")
 for quarter in [1, 2, 3]:
  unit.set_view_quarter(0)
  unit.set_facing("S")
  unit.set_cast_pose("release")
  unit.set_view_quarter(quarter)
  var after_rotation: String = ["S", "W", "N", "E"][quarter]
  check(unit._sprite.texture.resource_path.ends_with(FILES[after_rotation]), "camera rotation out of release restores correct idle")
  check(unit.candidate_pose == "idle", "camera rotation clears stale cast")
 unit.set_view_quarter(0)
 # A deliberately missing optional row still takes the original safe fallback.
 var original_rows: Dictionary = unit._candidate_specs["storm_imp"].duplicate(true)
 unit._candidate_specs["storm_imp"].erase("idle-ne")
 unit.set_facing("N")
 check(unit._sprite.texture == unit.unit_data.sprite_sheet, "missing optional facing restores original art")
 check(unit._sprite.offset == Vector2.ZERO and not unit._sprite.flip_h, "fallback restores original offset and flip")
 var size: Vector2 = unit.unit_data.sprite_sheet.get_size()
 var scale_value := 95.0 / maxf(size.x, size.y)
 check(unit._sprite.scale.is_equal_approx(Vector2.ONE * scale_value), "fallback restores original scale")
 check(unit._sprite.position.is_equal_approx(Vector2(0, -size.y * scale_value * 0.5)), "fallback restores original foot position")
 unit._candidate_specs["storm_imp"] = original_rows
 unit.set_facing("N")
 check(unit._sprite.texture.resource_path.ends_with(FILES["N"]), "restored optional facing returns to candidate")
 check([unit.grid_pos, unit.hp, unit.mp] == before, "all presentation operations preserve gameplay state")
 battle.queue_free()
 await get_tree().process_frame
 print("Hollow directions: %d checks, %d failures" % [checks, failures])
 get_tree().quit(0 if failures == 0 else 1)
