extends Node
## QA-only pre-battle setup. Uses existing public Practice3D entry flags only.
## No party, initiative, resources, combat rolls or post-setup controls are changed.
func _ready() -> void:
	if not GameState.begin_practice():
		push_error("QA Practice3D bootstrap requires a fresh disposable profile")
		return
	GameState.practice_session["rig3d"] = true
	var fixture := preload("res://tests/browser_qa/BattleBrowserQA.tscn").instantiate()
	get_tree().root.add_child.call_deferred(fixture)
	queue_free()
