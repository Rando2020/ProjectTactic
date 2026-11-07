extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var files := DirAccess.get_files_at("res://models")
	var count := 0
	for file in files:
		if file.ends_with(".glb"):
			var packed := load("res://models/" + file) as PackedScene
			assert(packed != null)
			var object := packed.instantiate()
			assert(object != null)
			object.free()
			count += 1
	assert(count == 7)
	var preview := (load("res://godot-preview/preview.tscn") as PackedScene).instantiate()
	root.add_child(preview)
	await process_frame
	assert(preview.camera.current)
	var old_position: Vector3 = preview.camera.position
	preview.azimuth += 1.0
	preview.update_camera()
	assert(not preview.camera.position.is_equal_approx(old_position))
	print("CHAPEL_PREVIEW_PASS: 7 GLBs load; scene initializes; orbit updates")
	quit()
