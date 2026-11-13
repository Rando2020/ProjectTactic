extends SceneTree
func _initialize() -> void:
	var script = load("res://scripts/vfx/FireballSprite.gd")
	var sprite = script.new()
	sprite.configure(0, 4, 0.20, 36.0)
	var sheet = sprite.SHEET.get_image()
	assert(sheet.get_size() == Vector2i(1443,1090))
	assert(sheet.get_pixel(0,0).a == 0.0)
	for index in 16:
		sprite._set_frame(index)
		var region: Rect2 = sprite.texture.region
		assert(Rect2(0,0,1443,1090).encloses(region))
		assert(region.has_area())
		var image = sheet.get_region(Rect2i(region))
		assert(not image.is_invisible())
		assert(image.get_used_rect().has_area())
	sprite.configure(4, 4, 0.22, 42.0)
	sprite._process(0.12)
	assert(sprite._displayed == 6)
	sprite.free()
	print("Fireball atlas: all 16 regions nonempty/in bounds, transparent source, flight progression passed")
	quit()
