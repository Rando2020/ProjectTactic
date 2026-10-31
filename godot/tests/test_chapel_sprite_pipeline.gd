extends Node
var failures: Array[String] = []
var checks := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  printerr("FAIL: " + message)
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 GameState.practice_session = {"state":"playing", "mode":"zane_duel", "illustrated_chapel":true}
 var battle := preload("res://scenes/Battle.tscn").instantiate()
 get_tree().root.add_child(battle)
 await get_tree().process_frame
 var manager: BattleManager = battle.battle_manager
 var zane: Unit = manager.units.zane
 for id in ["zane", "kael", "mira", "lyra"]:
  var paths := AssetRegistry.get_character_direction_candidates(id, "S")
  check(not paths[0].contains("iso-v02"), "unapproved artwork never silently replaces " + id)
 zane.grid_pos = Vector2i(4,5)
 for pair in [[Vector2i(4,4),"N"], [Vector2i(5,5),"E"], [Vector2i(4,6),"S"], [Vector2i(3,5),"W"]]:
  zane.face_action(pair[0])
  check(zane.facing == pair[1], "2D attack faces target " + pair[1])
 check(zane.set_melee_pose("anticipation"), "2D Zane supports anticipation")
 check(zane.set_melee_pose("contact"), "2D Zane supports contact")
 zane.reset_melee_pose()
 check(zane.melee_pose == "idle", "pose reset restores idle")
 check(is_instance_valid(battle.get_node("BattleUI").get("_unit_status_panel")), "Status inspection panel exists")
 # Provisional views must resolve independently, with a common actual foot origin.
 GameState.practice_session["review_hero_art"] = true
 var textures := {}
 for direction in ["N", "E", "S", "W"]:
  zane.set_facing(direction)
  textures[zane._sprite.texture.get_instance_id()] = true
  var foot := zane._sprite.transform * (Vector2(128,245) - zane._sprite.texture.get_size() * 0.5 + zane._sprite.offset)
  check(foot.length() < 0.01, "candidate foot anchor remains fixed " + direction)
  check(not zane._sprite.flip_h, "direction never mirrors " + direction)
 check(textures.size() == 4, "four independent candidate textures")
 check(battle.tactical_grid.unit_layer.z_index == 0, "chapel units share prop depth space")
 battle.queue_free()
 await get_tree().process_frame
 print("Chapel sprite pipeline: %d checks, %d failures" % [checks, failures.size()])
 get_tree().quit(0 if failures.is_empty() else 1)
