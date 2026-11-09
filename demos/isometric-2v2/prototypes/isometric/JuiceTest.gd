extends Node
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var previous := get_tree().current_scene
	var battle := preload("res://prototypes/isometric/Battle.tscn").instantiate()
	get_tree().root.add_child(battle)
	get_tree().current_scene = battle
	await get_tree().process_frame
	var effects := get_node("/root/BattleJuiceEffects")
	# Reproduce native direct-launch reference discovery missed by Test->Battle.
	effects._tactical_grid = battle.tactical_grid
	effects._camera = battle._battle_camera
	var target: Unit = battle.battle_manager.units.Enemy_1
	effects.trigger_flash("Enemy_1", 30)
	effects.trigger_wobble("Enemy_1", 30)
	await get_tree().create_timer(0.06).timeout
	# Retry/exit while old visual effects are still retiring must be safe.
	effects.trigger_flash("Enemy_1", 200)
	battle.queue_free()
	get_tree().current_scene = previous
	await get_tree().process_frame
	effects.trigger_flash("Enemy_1", 10)
	effects.trigger_wobble("Enemy_1", 10)
	await get_tree().create_timer(0.3).timeout
	print("Isometric juice native-reference regression completed")
	get_tree().quit()
