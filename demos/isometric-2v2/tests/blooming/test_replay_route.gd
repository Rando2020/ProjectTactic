extends Node
var failures:=0
func check(ok: bool,label: String)->void:
 if not ok:failures+=1;printerr("FAIL: "+label)
func _ready()->void:
 var results=load("res://scripts/ui/ResultsScreen.gd").new()
 check(results.has_method("_practice_battle_scene"),"practice replay has isolated destination selector")
 if results.has_method("_practice_battle_scene"):
  var before=GameState.practice_session.duplicate(true)
  results._gs=GameState
  GameState.practice_session={"blooming_ruins":true}
  check(results._practice_battle_scene()=="res://prototypes/blooming/BloomingBattle.tscn","Blooming replay remains Blooming")
  GameState.practice_session={}
  check(results._practice_battle_scene()=="res://prototypes/isometric/Skirmish.tscn","legacy replay unchanged")
  GameState.practice_session=before
 results.free()
 print("Blooming replay route failures: ",failures)
 get_tree().quit(1 if failures else 0)
