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
	await _check_first_battle()
	quit(1 if failures else 0)

func _check_first_battle() -> void:
	var gs: Node = root.get_node("GameState")
	root.get_node("RunManager").start_new_run(0, 42)
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	var grid: TacticalGrid = battle.tactical_grid
	check(grid.terrain_textures.size() == 5, "real floor-one battle enables five terrain aliases")
	check(battle.battle_manager.units.size() > 4 and grid.unit_positions.size() == battle.battle_manager.units.size(), "real battle starts party and enemy roster")
	var party_ok := true
	for id in ["zane", "mira", "kael", "lyra"]:
		var unit: Unit = battle.battle_manager.units.get(id)
		party_ok = party_ok and unit != null and unit.unit_data.sprite_sheet != null
		if unit:
			party_ok = party_ok and unit.position == grid._unit_foot_pos(unit.grid_pos)
	check(party_ok, "four actual party sprites load and retain their foot alignment")
	var original_tiles := grid.tiles.duplicate(true)
	var original_positions := grid.unit_positions.duplicate()
	var gold: int = gs.gold
	var run_before: Dictionary = root.get_node("SaveSystem")._serialize().duplicate(true)
	run_before.erase("saved_at")
	var selection_ok := true
	for zoom in [0.6, 1.0, 1.5]:
		battle._set_camera_zoom(zoom)
		battle._battle_camera.force_update_scroll()
		var transform := grid.get_global_transform_with_canvas()
		for pos: Vector2i in grid.tiles:
			var screen_center: Vector2 = transform * grid._grid_to_local(pos)
			var picked: Vector2i = grid._local_to_grid(transform.affine_inverse() * screen_center)
			selection_ok = selection_ok and picked == pos
	check(selection_ok, "all 80 tile centers round-trip at min, 1x and max battle zoom including heights")
	var highlight_pos := Vector2i(3, 3)
	grid.show_move_range([highlight_pos])
	var highlight_ok := false
	for item in grid.highlight_layer.get_children():
		if item is Polygon2D and item.position == grid._grid_to_local(highlight_pos):
			highlight_ok = true
	check(highlight_ok, "movement highlight sits at the terrain center")
	# Compare render-only cost on the identical map; warm caches before sampling.
	for enabled in [false, true]:
		battle.use_first_battle_terrain = enabled
		battle._configure_terrain_art(gs.active_run)
		grid.redraw_base_tiles()
		await process_frame
		var samples: Array[int] = []
		for i in 9:
			var start := Time.get_ticks_usec()
			grid.redraw_base_tiles()
			samples.append(Time.get_ticks_usec() - start)
			await process_frame
		samples.sort()
		print("PROFILE art=", enabled, " redraw_median_us=", samples[4], " grid_children=", grid.get_child_count())
	check(grid.tiles == original_tiles and grid.unit_positions == original_positions, "art comparison leaves terrain rules and unit occupancy unchanged")
	var run_after: Dictionary = root.get_node("SaveSystem")._serialize().duplicate(true)
	run_after.erase("saved_at")
	check(gs.gold == gold and run_before == run_after, "art toggle does not mutate save, party, nodes or currencies")
	var grass: Texture2D = grid._texture_for_terrain("grass")
	check(grass == Kit.first_battle_textures()["grass"], "terrain references reuse imported texture resources")
	grid.terrain_textures["grass"] = null
	check(grid._texture_for_terrain("grass") != null, "null candidate texture falls back to existing grass art")
	grid.terrain_textures.erase("grass")
	check(grid._texture_for_terrain("grass") != null, "absent candidate texture falls back to existing grass art")
	grid.ignite_tile(Vector2i(0, 0))
	check(grid.tiles[Vector2i(0, 0)].terrain == "burning" and not grid.terrain_textures.has("burning"), "fire mutation uses original hazard art and rules")
	var run := RunState.create(42)
	run.current_floor = 2
	battle._configure_terrain_art(run)
	check(grid.terrain_textures.is_empty(), "later floors retain original art")
	battle._configure_terrain_art(null)
	check(grid.terrain_textures.is_empty(), "standalone maps retain original art")
	run.current_floor = 1
	run.completed = true
	battle._configure_terrain_art(run)
	check(grid.terrain_textures.is_empty(), "completed runs retain original art")
	run.completed = false
	battle.use_first_battle_terrain = false
	battle._configure_terrain_art(run)
	check(grid.terrain_textures.is_empty(), "explicit opt-out retains original art on floor one")
	battle.queue_free()
	await process_frame
