extends "res://prototypes/isometric/RotatableGrid.gd"
## Fixed-view bridge. Authoritative cells and combat remain in TacticalGrid.
func initialize_from_map(data: MapData) -> void:
 tile_size=Vector2i(128,64)
 height_step=32.0
 map_origin=Vector2.ZERO
 super.initialize_from_map(data)

func _draw_base_tiles() -> void:
 if not is_instance_valid(terrain_view):
  terrain_view=preload("res://prototypes/blooming/BloomingTerrain.gd").new()
  add_child(terrain_view)
  terrain_view.configure(self)
 else:
  terrain_view.rebuild()

func _unit_foot_pos(cell: Vector2i) -> Vector2:
 return _grid_to_local(cell)

func _local_to_grid(point: Vector2) -> Vector2i:
 return terrain_view.pick_cell(point) if is_instance_valid(terrain_view) else Vector2i(-1,-1)

func get_board_bounds() -> Rect2:
 return terrain_view.get_board_bounds() if is_instance_valid(terrain_view) else Rect2(-600,-200,1400,1000)

func _add_highlight(cell: Vector2i, color: Color, highlight_scale: float=0.86, animate: bool=false, _overlay_id: String="") -> void:
 if not is_instance_valid(terrain_view):return
 var tint:=color
 if animate:tint.a*=0.6+0.4*(sin(_highlight_animation_time)*0.5+0.5)
 for surface: PackedVector2Array in terrain_view.surface_polygons(cell):
  var center:=Vector2.ZERO
  for point in surface:center+=point
  center/=surface.size()
  var points:=PackedVector2Array()
  for point in surface:points.append(center+(point-center)*highlight_scale)
  var fill:=Polygon2D.new()
  fill.polygon=points;fill.color=Color(tint.r,tint.g,tint.b,minf(tint.a,0.28));fill.z_index=_depth_for(cell)+50
  highlight_layer.add_child(fill)
  var rim:=Line2D.new()
  rim.points=points;rim.add_point(points[0]);rim.width=1.5
  rim.default_color=Color(tint.r,tint.g,tint.b,minf(1,tint.a+0.22))
  rim.z_index=fill.z_index+1
  highlight_layer.add_child(rim)

func set_rotatable(_enabled: bool) -> void:
 pass
func rotate_view(_step: int) -> void:
 pass

func set_terrain_3d(_enabled: bool) -> void:
 # Legacy comparison setup may request its old mode; this opt-in stage owns its presenter.
 pass
