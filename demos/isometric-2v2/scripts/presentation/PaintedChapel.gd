extends RefCounted
## Flat, fixed-camera art lane. The outer architecture is scenery, not terrain.

const BACKGROUND := "res://assets/environments/ruined-chapel/chapel-painted-background.png"
const GRID_ORIGIN := Vector2(960, 474)

static func create_map() -> MapData:
	var map := MapData.new()
	map.id = "painted_chapel_practice"
	map.display_name = "The Painted Chapel"
	map.map_width = 5
	map.map_height = 5
	map.default_terrain = "stone"
	map.environment_theme_id = "ruined-chapel"
	map.painted_background = BACKGROUND
	map.painted_grid_origin = GRID_ORIGIN
	map.painted_tile_size = Vector2i(128, 64)
	map.objective_type = "defeat_all"
	map.objective_label = "Defeat the Storm Imp | Lower floor arena"
	map.reward_gold = 150
	map.reward_jp = 40
	return map


static func draw_background(grid: Node2D) -> bool:
	var texture := load(grid.map_data.painted_background) as Texture2D
	if texture == null:
		push_warning("Painted chapel unavailable; using normal terrain fallback")
		return false
	var plate := Sprite2D.new()
	plate.name = "PaintedBackground"
	plate.set_meta("painted_background", true)
	plate.texture = texture
	plate.centered = false
	plate.position = grid.map_origin - grid.map_data.painted_grid_origin
	plate.z_index = -100
	grid.add_child(plate)
	# Preserve visible terrain mutations without drawing opaque tiles over the art.
	for pos: Vector2i in grid.tiles:
		var terrain: String = grid.tiles[pos].get("terrain", "stone")
		if terrain != "stone":
			grid._add_soft_terrain_tint(pos, grid._grid_to_local(pos),
				grid._terrain_color(terrain, 0), grid._depth_for(pos))
	return true
