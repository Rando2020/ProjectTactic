extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var grid := TacticalGrid.new()
	var highlights := Node2D.new()
	highlights.name = "HighlightLayer"
	grid.add_child(highlights)
	var units := Node2D.new()
	units.name = "UnitLayer"
	grid.add_child(units)
	root.add_child(grid)
	var map := MapData.new()
	map.map_width = 2
	map.map_height = 2
	map.default_terrain = "grass"
	grid.initialize_from_map(map)
	for cycle in range(10):
		grid.set_terrain_3d(true)
		var view = grid.terrain_view
		assert(view.visible)
		grid.redraw_base_tiles()
		await process_frame
		grid.set_terrain_3d(false)
		assert(not is_instance_valid(view))
		await process_frame
	grid.free()
	map = null
	await process_frame
	print("Terrain cleanup: 10 enable/redraw/disable cycles passed")
	quit()
