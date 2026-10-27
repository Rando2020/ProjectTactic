extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var preview = load("res://preview.tscn").instantiate()
	root.add_child(preview)
	await process_frame
	assert(preview.camera != null)
	assert(preview.get_child(0).find_children("*", "MeshInstance3D", true, false).size() == 5)
	print("COURTYARD_IMPORT_PASS")
	quit()
