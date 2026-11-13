extends SceneTree

func _initialize() -> void:
	var root_path: String = get_script().resource_path.get_base_dir().get_base_dir()
	var data = JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join('manifest.json')))
	if not data is Dictionary:
		push_error('Manifest read failed')
		quit(1)
		return
	var counts: Array = []
	for pose in data.poses.slice(0,3):
		var image := Image.load_from_file(root_path.path_join(pose.file))
		if image == null or image.is_empty():
			push_error('Cannot load '+pose.file)
			quit(1)
			return
		assert(image.get_size() == Vector2i(1254,1254))
		assert(image.detect_alpha() != Image.ALPHA_NONE)
		var texture := ImageTexture.create_from_image(image)
		assert(texture.get_size() == Vector2(1254,1254))
		counts.append({'pose':pose.id, 'png_decode':'pass', 'alpha_detected':'pass', 'texture_creation':'pass'})
	var out := FileAccess.open(root_path.path_join('qa/godot-validation.json'),FileAccess.WRITE)
	out.store_string(JSON.stringify(counts, '  '))
	print(JSON.stringify(counts))
	quit(0)
