extends Node
func _ready() -> void:
 var ui = load("res://prototypes/isometric/BattleUI.gd").new()
 var ok: bool = ui.has_method("_make_selection_controller")
 ui.free()
 print("Blooming HUD factory: ", "PASS" if ok else "FAIL: selection creation has no override seam")
 get_tree().quit(0 if ok else 1)
