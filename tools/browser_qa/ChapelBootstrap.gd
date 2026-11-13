extends Node
## QA-only bootstrap; all interaction afterward comes from browser input.
func _ready() -> void:
 if not GameState.begin_illustrated_chapel_practice():
  push_error("Chapel QA requires a fresh profile")
  return
 GameState.practice_session["review_hero_art"] = true
 var observer := preload("res://tests/browser_qa/ChapelObserver.gd").new()
 get_tree().root.add_child.call_deferred(observer)
 get_tree().change_scene_to_file.call_deferred("res://scenes/Battle.tscn")
