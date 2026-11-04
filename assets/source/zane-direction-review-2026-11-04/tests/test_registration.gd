extends SceneTree
func _initialize():
	if not FileAccess.file_exists('res://registration.json'):
		printerr('FAIL: registration manifest missing')
		quit(1)
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string('res://registration.json'))
	assert(data.views.size() == 4, 'Four view records required')
	var directions = []
	for v in data.views:
		directions.append(v.direction)
		assert(v.flip_h == false, 'No mirrored directions')
		assert(v.accepted == false or v.direction == 'SE', 'Candidates are not accepted')
		var source = Image.load_from_file('res://' + v.file)
		assert(source != null and source.get_width() == 1254 and source.get_height() == 1254)
		assert(FileAccess.get_sha256('res://' + v.file) == v.sha256, 'Source bytes changed')
		var bounds = v.alpha_bounds
		var scale_factor = data.target_height / float(bounds[3] - bounds[1])
		assert(abs(scale_factor * (bounds[3] - bounds[1]) - 85.0) < 0.001)
		assert(v.anchor[1] == bounds[3], 'Review baseline must align with lowest substantial sole')
		assert(v.anchor[0] > bounds[0] and v.anchor[0] < bounds[2])
	assert(directions == ['SE','SW','NE','NW'])
	print('PASS: four unique sources; no mirrors; source hashes; 85px height; review baseline; approval labels')
	quit(0)
