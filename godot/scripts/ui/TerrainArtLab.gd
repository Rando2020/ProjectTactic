## Isolated interactive art battlefield. Never creates, advances or rewards a run.
extends Node2D

const Kit := preload("res://scripts/data/TerrainArtKit.gd")
var grid: TacticalGrid
var caption: Label

func _ready() -> void:
	grid = TacticalGrid.new()
	grid.name = "TerrainGrid"
	grid.map_origin = Vector2(0, 0)
	grid.terrain_textures = Kit.textures()
	grid.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for layer_name in ["HighlightLayer", "UnitLayer"]:
		var layer := Node2D.new()
		layer.name = layer_name
		grid.add_child(layer)
	add_child(grid)
	grid.initialize_from_map(Kit.test_map())
	grid.tile_clicked.connect(_select_tile)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var box := VBoxContainer.new()
	box.position = Vector2(36, 24)
	canvas.add_child(box)
	caption = Label.new()
	caption.text = "TERRAIN LAB | 96 x 48 | Click tiles to inspect selection"
	caption.add_theme_font_size_override("font_size", 24)
	box.add_child(caption)
	var hint := Label.new()
	hint.text = "Grass / dirt / stone above. Cracked stone / water / scorched below. No run progress changes."
	box.add_child(hint)
	var row := HBoxContainer.new()
	box.add_child(row)
	for zoom in [1, 2]:
		var button := Button.new()
		button.text = "%dx actual pixels" % zoom
		button.pressed.connect(_set_zoom.bind(zoom))
		row.add_child(button)
	var back := Button.new()
	back.text = "Return to title"
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/StartScreen.tscn"))
	row.add_child(back)
	for i in 6:
		var pos := Vector2i([1, 4, 6][i % 3], 2 if i < 3 else 5)
		var unit := Sprite2D.new()
		unit.texture = load("res://assets/tiles/terrain_v2/review_%s.png" % ["zane", "mira", "kael"][i % 3])
		unit.scale = Vector2.ONE * 0.625
		unit.position = grid._unit_foot_pos(pos) - Vector2(0, 40)
		unit.z_index = grid._unit_depth_for(pos)
		grid.unit_layer.add_child(unit)
	_set_zoom(1)
	_select_tile(Vector2i(4, 3))

func _set_zoom(value: int) -> void:
	grid.scale = Vector2.ONE * value
	grid.position = Vector2(get_viewport_rect().size.x / 2, 220)

func _select_tile(pos: Vector2i) -> void:
	grid.show_active_unit(pos, "player")
	caption.text = "TERRAIN LAB | %s | height %d | 96 x 48 pixels" % [grid.tiles[pos].terrain, grid.tiles[pos].height]
