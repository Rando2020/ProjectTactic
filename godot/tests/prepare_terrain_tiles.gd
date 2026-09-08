## Offline packaging of generated top-face art. Never used during gameplay.
## Arguments: source PNG, destination PNG. Samples an inset to exclude baked matte.
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	assert(args.size() == 2)
	var source := Image.load_from_file(args[0])
	assert(source != null)
	var source_size := source.get_size()
	# All source diamonds were visually checked. This inset excludes their rims
	# and checkerboard matte, including downsampling filter support.
	var area := Rect2i(int(source_size.x * 0.08), int(source_size.y * 0.10), int(source_size.x * 0.84), int(source_size.y * 0.80))
	var sample := source.get_region(area)
	sample.resize(96, 48, Image.INTERPOLATE_LANCZOS)
	sample.convert(Image.FORMAT_RGBA8)
	for y in 48:
		for x in 96:
			var inside := absf((x + 0.5 - 48) / 48.0) + absf((y + 0.5 - 24) / 24.0) < 1.0
			var color := sample.get_pixel(x, y)
			color.a = 1.0 if inside else 0.0
			if not inside: color = Color.TRANSPARENT
			sample.set_pixel(x, y, color)
	DirAccess.make_dir_recursive_absolute(args[1].get_base_dir())
	assert(sample.save_png(args[1]) == OK)
	print("Packaged 96x48 RGBA diamond: ", args[1])
	quit()
