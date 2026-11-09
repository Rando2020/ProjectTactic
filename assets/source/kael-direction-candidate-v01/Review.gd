extends Node2D
const DIRECTIONS := ["se", "sw", "ne", "nw"]
var manifest: Dictionary
func _ready() -> void:
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	RenderingServer.set_default_clear_color(Color("171e29"))
	label_at("KAEL / DIRECTIONAL IDLE CANDIDATES", Vector2(34, 20), 28)
	label_at("Four authored images. No mirroring. Source-only review, not approved game artwork.", Vector2(34, 58), 16)
	for i in range(DIRECTIONS.size()):
		var direction: String = DIRECTIONS[i]
		var entry: Dictionary = manifest.directions[direction]
		var x := 185.0 + i * 355.0
		label_at(direction.to_upper(), Vector2(x - 20, 92), 22)
		for row in range(3):
			var factor: float = [1.0, 2.0, 4.0][row]
			var baseline: float = [255.0, 485.0, 850.0][row]
			var actor := Sprite2D.new()
			actor.texture = load("res://" + entry.file)
			actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			actor.scale = Vector2.ONE * float(entry.display_scale) * factor
			actor.position = Vector2(x, baseline)
			actor.offset = Vector2(entry.centered_sprite_offset_px[0], entry.centered_sprite_offset_px[1])
			actor.flip_h = false
			add_child(actor)
			label_at(str(int(86 * factor)) + " px body", Vector2(x - 44, baseline + 17), 13)
	queue_redraw()
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://qa/godot-scale-review.png")
		get_tree().quit()
func label_at(value: String, at: Vector2, size: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	add_child(label)
func _draw() -> void:
	for i in range(4):
		var x := 185.0 + i * 355.0
		for y in [255.0, 485.0, 850.0]:
			var diamond := PackedVector2Array([Vector2(x,y-32), Vector2(x+64,y), Vector2(x,y+32), Vector2(x-64,y)])
			draw_colored_polygon(diamond, Color("334156"))
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color("63758a"), 1.0)
			draw_line(Vector2(x-5,y),Vector2(x+5,y),Color("ffca72"),1.0)
			draw_line(Vector2(x,y-5),Vector2(x,y+5),Color("ffca72"),1.0)
