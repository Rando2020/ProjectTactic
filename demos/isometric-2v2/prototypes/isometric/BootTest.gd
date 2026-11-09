extends Node
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	await get_tree().process_frame
	var battle := get_parent() as BattleScene
	var valid := battle.tactical_grid.map_data.id == "painted_chapel_practice" and battle.battle_manager.units.size() == 4 and GameState.is_zane_duel_practice()
	if not valid:
		printerr("FAIL: direct boot must open four-fighter painted skirmish, including with existing save")
	print("Isometric direct boot: " + ("PASS" if valid else "FAIL"))
	get_tree().quit(0 if valid else 1)
