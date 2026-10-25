extends Node
## QA-only admission, using production duel setup without gameplay overrides.
func _ready() -> void:
	if not GameState.begin_zane_duel_practice():
		push_error("QA duel bootstrap requires a fresh disposable profile")
		return
	GameState.practice_session["rig3d"] = true
	var sentinel := preload("res://tests/browser_qa/ZaneDuelSentinel.gd").new()
	sentinel.name = "ZaneDuelTerminalSentinel"
	get_tree().root.add_child.call_deferred(sentinel)
	# Unlike an orphan Battle under root, current_scene is normally removed when
	# real gameplay reaches Results. The sentinel only reports that boundary.
	get_tree().change_scene_to_file.call_deferred("res://tests/browser_qa/ZaneDuelBattleQA.tscn")
