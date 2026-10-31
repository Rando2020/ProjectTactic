extends Node2D
## Persistent cursor, independent of transient movement/target highlights.
var grid: TacticalGrid
var cell := Vector2i(-1, -1)
var selection_cell := Vector2i(-1, -1)
func _draw() -> void:
	if not is_instance_valid(grid): return
	if grid.tiles.has(selection_cell):
		var selected := grid._diamond_polygon(1.02)
		for i in selected.size(): selected[i] += grid._grid_to_local(selection_cell)
		draw_colored_polygon(selected, Color(1.0, 0.83, 0.3, 0.16))
		selected.append(selected[0])
		draw_polyline(selected, Color("e6bd62"), 3.0, true)
	if not grid.tiles.has(cell): return
	var center := grid._grid_to_local(cell)
	var poly := grid._diamond_polygon(1.23)
	for i in 4:
		var corner: Vector2 = poly[i] + center
		var previous: Vector2 = poly[(i+3)%4] + center
		var next: Vector2 = poly[(i+1)%4] + center
		draw_polyline(PackedVector2Array([corner.lerp(previous,0.3),corner,corner.lerp(next,0.3)]), Color(0,0,0,0.8),7.0,true)
		draw_polyline(PackedVector2Array([corner.lerp(previous,0.3),corner,corner.lerp(next,0.3)]), Color("fff2c5"),3.5,true)
