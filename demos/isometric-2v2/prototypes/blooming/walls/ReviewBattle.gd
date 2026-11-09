extends "res://prototypes/blooming/BloomingBattle.gd"
func _ready() -> void:
 super._ready()
 var candidate:=preload("res://prototypes/blooming/walls/WallCandidate.gd").new()
 add_child(candidate)
 candidate.configure(tactical_grid)
