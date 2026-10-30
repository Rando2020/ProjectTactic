extends Node

# Run as a scene so GameState is registered before terrain scripts compile:
# godot --headless --path godot res://tests/test_terrain_cleanup.tscn

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var grid := TacticalGrid.new()
	var highlights := Node2D.new()
	highlights.name = "HighlightLayer"
	grid.add_child(highlights)
	var units := Node2D.new()
	units.name = "UnitLayer"
	grid.add_child(units)
	get_tree().root.add_child(grid)
	var map := MapData.new()
	map.map_width = 2
	map.map_height = 2
	map.default_terrain = "grass"
	grid.initialize_from_map(map)
	for cycle in range(10):
		grid.set_terrain_3d(true)
		var view = grid.terrain_view
		if not _expect(is_instance_valid(view) and view.visible, "Enabled terrain view must be visible"):
			return
		grid.redraw_base_tiles()
		await get_tree().process_frame
		grid.set_terrain_3d(false)
		if not _expect(not is_instance_valid(view), "Disabled terrain view must be freed"):
			return
		await get_tree().process_frame
	grid.free()
	map = null
	await get_tree().process_frame
	print("Terrain cleanup: 10 enable/redraw/disable cycles passed")
	get_tree().quit(0)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		get_tree().quit(1)
	return condition
