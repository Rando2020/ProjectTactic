extends SceneTree
func _initialize() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	var checks := 0
	for direction in ["se", "sw", "ne", "nw"]:
		var entry: Dictionary = manifest.directions[direction]
		var path: String = "res://" + entry.file
		var image := Image.new()
		assert(image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK); checks += 1
		assert(image != null and not image.is_empty()); checks += 1
		assert(image.get_size() == Vector2i(1199, 1312)); checks += 1
		assert(image.detect_alpha() != Image.ALPHA_NONE); checks += 1
		var tex: Texture2D = load(path)
		assert(tex != null and tex.get_size() == Vector2(1199, 1312)); checks += 1
		var actor := Sprite2D.new()
		actor.texture = tex
		actor.scale = Vector2.ONE * float(entry.display_scale)
		actor.offset = Vector2(entry.centered_sprite_offset_px[0], entry.centered_sprite_offset_px[1])
		actor.flip_h = false
		var pivot := Vector2(entry.foot_pivot_px[0], entry.foot_pivot_px[1])
		var local_foot := (pivot - tex.get_size() * 0.5 + actor.offset) * actor.scale
		assert(local_foot.length() < 0.001); checks += 1
		assert(not actor.flip_h); checks += 1
		actor.free()
	var review_script: GDScript = load("res://Review.gd")
	assert(review_script.can_instantiate()); checks += 1
	assert(load("res://Review.tscn") != null); checks += 1
	var report := {"godot_version": Engine.get_version_info().string, "checks":checks, "failures":0, "scope":"Four imported Texture2D resources, RGBA decode, dimensions, unmirrored Sprite2D foot-origin arithmetic. Not gameplay acceptance."}
	FileAccess.open("res://qa/godot-validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print(JSON.stringify(report))
	quit(0)
