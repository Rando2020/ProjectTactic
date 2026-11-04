extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var scene: Control = load("res://review.tscn").instantiate()
 root.add_child(scene)
 root.size = Vector2i(1280,900)
 await process_frame
 await process_frame
 var buttons: Array[Node] = scene.find_children("Button*", "Button", true, false)
 check(buttons.size() == 11, "Expected 11 specimen buttons")
 for node in buttons:
  var button := node as Button
  check(button.size.y >= 48, "Button below 48 px: " + button.name)
  check(button.focus_mode == Control.FOCUS_ALL, "Button missing keyboard focus")
  check(button.get_signal_connection_list("pressed").is_empty(), "Specimen must not bind gameplay")
  check(button.get_global_rect().end.y <= 900, "Button below viewport: " + str(button.get_global_rect()))
 for file in ["confirmation-card", "enemy-inspector", "facing-selector", "context-hint"]:
  var packed: PackedScene = load("res://components/" + file + ".tscn")
  check(packed != null, "Cannot load component " + file)
  var component: Control = packed.instantiate()
  check(component is PanelContainer, "Component root type")
  component.free()
 var theme: Theme = scene.theme
 for state in ["normal","hover","pressed","disabled","focus"]:
  check(theme.has_stylebox(state,"Button"), "Missing button state " + state)
 check(theme.get_stylebox("focus","Button") != theme.get_stylebox("hover","Button"), "Focus must differ from hover")
 print("NATIVE_UI_CONTRACT failures=",failures," buttons=",buttons.size())
 scene.queue_free()
 await process_frame
 quit(failures)
