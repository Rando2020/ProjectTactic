extends SceneTree

const Kit := preload("res://scripts/data/TerrainArtKit.gd")
var failures := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	print("PASS " if ok else "FAIL ", message)
	if not ok: failures += 1

func inside(x: int, y: int, w: int, h: int) -> bool:
	return absf((x + 0.5 - w / 2.0) / (w / 2.0)) + absf((y + 0.5 - h / 2.0) / (h / 2.0)) < 1.0

func _run() -> void:
	var textures := Kit.textures()
	var proof := Image.create(960, 500, false, Image.FORMAT_RGBA8)
	proof.fill(Color(0.055, 0.065, 0.085))
	for i in Kit.NAMES.size():
		var terrain: String = Kit.NAMES[i]
		var texture: Texture2D = textures[terrain]
		check(texture != null and texture.get_size() == Vector2(96, 48), terrain + ": imported 96x48 texture")
		if texture == null: continue
		var tile := texture.get_image()
		var alpha_ok := true
		for y in 48:
			for x in 96:
				if tile.get_pixel(x, y).a != (1.0 if inside(x, y, 96, 48) else 0.0): alpha_ok = false
		check(alpha_ok, terrain + ": exact opaque diamond and transparent exterior")
		var coverage := PackedInt32Array()
		coverage.resize(192 * 96)
		for offset in [Vector2i(48, 0), Vector2i(96, 24), Vector2i(0, 24), Vector2i(48, 48)]:
			for y in 48:
				for x in 96:
					if tile.get_pixel(x, y).a == 1.0: coverage[(y + offset.y) * 192 + x + offset.x] += 1
		var seam_ok := true
		for y in 96:
			for x in 192:
				if coverage[y * 192 + x] != (1 if inside(x, y, 192, 96) else 0): seam_ok = false
		check(seam_ok, terrain + ": 2x2 adjacency has no gaps or overlapping opaque pixels")
		# Pixel proof: six repeating 3x3 panels, with existing 80px character art.
		var origin := Vector2i(160 + (i % 3) * 320, 40 + (i / 3) * 240)
		for y in 3:
			for x in 3:
				proof.blend_rect(tile, Rect2i(0, 0, 96, 48), origin + Vector2i((x-y)*48-48, (x+y)*24))
		var sprite_texture: Texture2D = load("res://assets/tiles/terrain_v2/review_%s.png" % ["zane", "mira", "kael"][i % 3])
		var sprite := sprite_texture.get_image()
		sprite.resize(80, 80, Image.INTERPOLATE_LANCZOS)
		proof.blend_rect(sprite, Rect2i(0, 0, 80, 80), origin + Vector2i(-40, 5))
	if OS.get_cmdline_user_args().has("--proof"):
		DirAccess.make_dir_recursive_absolute("res://../docs/art")
		check(proof.save_png("res://../docs/art/terrain-v2-proof.png") == OK, "saved native-size pixel proof")
	var saves := root.get_node("SaveSystem")
	var before: Dictionary = saves._serialize().duplicate(true)
	before.erase("saved_at")
	var lab: Node = load("res://scenes/TerrainArtLab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	check(lab.grid.tiles.size() == 64 and lab.grid.terrain_textures.size() == 6, "lab uses 64 cells and all six opt-in textures")
	var units_loaded: bool = lab.grid.unit_layer.get_child_count() == 6
	for unit in lab.grid.unit_layer.get_children():
		units_loaded = units_loaded and unit is Sprite2D and unit.texture != null
	check(units_loaded, "existing unit textures actually load on all materials")
	lab._select_tile(Vector2i(7, 0))
	check(lab.grid.active_unit_tile == Vector2i(7, 0) and lab.grid.tiles[Vector2i(7, 0)].height == 1, "height-step selection works")
	var after: Dictionary = saves._serialize().duplicate(true)
	after.erase("saved_at")
	check(after == before, "lab leaves run, progression and rewards unchanged")
	lab.queue_free()
	await process_frame
	quit(1 if failures else 0)
