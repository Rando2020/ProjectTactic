extends PracticeTerrain3D
## Fixed camera textured geometry plus separately depth-sorted painted cutouts.
## Gameplay remains entirely in TacticalGrid. All picking uses rendered tread tops.
const Map = preload("res://prototypes/blooming/BloomingMap.gd")
const ART := "res://assets/environments/blooming-ruins-v2/"
var decoration_nodes: Array[Sprite2D] = []
var occluded_unit_ids: Array[String] = []
var _materials: Dictionary = {}
var _regions: Dictionary = {}

func configure(p_grid: TacticalGrid) -> void:
 if is_instance_valid(_viewport):
  assert(grid == p_grid, "Blooming terrain cannot be rebound to a different board")
  rebuild()
  return
 var manifest = JSON.parse_string(FileAccess.get_file_as_string(ART+"manifest.json"))
 for asset in manifest.assets:
  for key in asset.get("regions", {}):
   _regions[key] = asset.regions[key].duplicate()
   _regions[key]["file"] = asset.file
 super.configure(p_grid)
 _add_garden()
 set_process(true)

func projected_point(cell: Vector2, height: float = NAN) -> Vector2:
 if is_nan(height): height = grid._height_at(Vector2i(cell.round()))
 return grid.map_origin + Vector2((cell.x-cell.y)*grid.tile_size.x*.5,(cell.x+cell.y)*grid.tile_size.y*.5-height*grid.height_step)

func surface_polygons(cell: Vector2i) -> Array[PackedVector2Array]:
 var result: Array[PackedVector2Array] = []
 var h: float = grid._height_at(cell)
 if Map.is_stair(cell):
  for i in 3:
   var lo := -.5+float(i)/3.0
   var hi := lo+1.0/3.0
   result.append(_rect_polygon(Vector2(cell)+Vector2(-.5,lo),Vector2(cell)+Vector2(.5,hi),h+(1.0-i)/3.0))
 else:
  result.append(_rect_polygon(Vector2(cell)-Vector2(.5,.5),Vector2(cell)+Vector2(.5,.5),h))
 return result

func _rect_polygon(lo: Vector2, hi: Vector2, h: float) -> PackedVector2Array:
 return PackedVector2Array([projected_point(lo,h),projected_point(Vector2(hi.x,lo.y),h),projected_point(hi,h),projected_point(Vector2(lo.x,hi.y),h)])

func surface_polygon(cell: Vector2i) -> PackedVector2Array:
 var points := PackedVector2Array()
 for polygon in surface_polygons(cell): points.append_array(polygon)
 return Geometry2D.convex_hull(points)

func pick_cell(point: Vector2) -> Vector2i:
 var chosen := Vector2i(-1,-1)
 var front := -INF
 for cell: Vector2i in grid.tiles:
  for polygon in surface_polygons(cell):
   if Geometry2D.is_point_in_polygon(point,polygon):
    var depth := float(cell.x+cell.y)
    if depth > front:
     front=depth; chosen=cell
 return chosen

func get_board_bounds() -> Rect2:
 var bounds := Rect2(projected_point(Vector2.ZERO),Vector2.ZERO)
 for cell: Vector2i in grid.tiles:
  for point in surface_polygon(cell): bounds=bounds.expand(point)
 # Include architecture above the upper landing, not the decorative distant sky.
 return bounds.grow_individual(70,220,70,60)

func _material(surface: int) -> ShaderMaterial:
 if not _materials.has(surface):
  var material := ShaderMaterial.new()
  material.shader=preload("res://prototypes/blooming/BloomingSurface.gdshader")
  material.set_shader_parameter("atlas",load(ART+"surfaces.png"))
  material.set_shader_parameter("surface",surface)
  material.set_shader_parameter("soil_floor_y",_visual_root.to_global(Vector3(0,BASE_TILE_TOP_Y,0)).y)
  _materials[surface]=material
 return _materials[surface]

func _box(center: Vector3, size: Vector3, surface: int, label: String) -> void:
 var instance := MeshInstance3D.new()
 var mesh := BoxMesh.new(); mesh.size=size
 instance.mesh=mesh; instance.material_override=_material(surface)
 instance.position=center; instance.name=label
 _visual_root.add_child(instance)

func _add_terrain_tile(cell: Vector2i, tile: Dictionary) -> void:
 var h := float(tile.get("height",0))
 var surface := 1 if tile.get("terrain","")=="road" else 0
 if Map.is_stair(cell):
  for i in 3:
   var top := BASE_TILE_TOP_Y+(h+(1.0-i)/3.0)*MODEL_HEIGHT_STEP
   _box(Vector3(cell.x*2,top*.5,cell.y*2+(-1.0+float(i))/3.0*2.0),Vector3(2,top,2.0/3.0),3,"Tread_%s_%d"%[cell,i])
 else:
  var top := BASE_TILE_TOP_Y+h*MODEL_HEIGHT_STEP
  _box(Vector3(cell.x*2,top*.5,cell.y*2),Vector3(2,top,2),surface,"Floor_%s"%cell)

func _add_map_prop(_prop_data: Dictionary, _tiles: Dictionary) -> void: pass

func _decorate(key: String, cell: Vector2, pixel_height: float, anchor_height: float = NAN) -> void:
 var region: Dictionary = _regions[key]
 var r: Array = region.rect
 var atlas := AtlasTexture.new()
 atlas.atlas=load(ART+region.file)
 atlas.region=Rect2(r[0],r[1],r[2],r[3])
 var sprite := Sprite2D.new()
 sprite.name="Bloom_"+key
 sprite.texture=atlas; sprite.centered=false
 var cutout := ShaderMaterial.new()
 cutout.shader=preload("res://prototypes/blooming/BloomingCutout.gdshader")
 sprite.material=cutout
 sprite.offset=Vector2(-r[2]*.5,0 if region.pivot=="top-center" else -r[3])
 sprite.scale=Vector2.ONE*pixel_height/float(r[3])
 sprite.position=projected_point(cell,anchor_height)
 sprite.z_index=grid._unit_depth_for(Vector2i(cell.round()))+2
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 grid.unit_layer.add_child(sprite)
 decoration_nodes.append(sprite)

func _add_garden() -> void:
 _decorate("arch",Vector2(7,.1),210)
 for x in [1.0,10.0]:
  _decorate("banner",Vector2(x,1),154)
 for cell in [Vector2(0,1),Vector2(11,1),Vector2(0,4),Vector2(11,5),Vector2(0,8),Vector2(11,9)]:
  _decorate("cypress",cell,205)
 for cell in [Vector2(1,0),Vector2(4,0),Vector2(10,0),Vector2(0,6),Vector2(11,7),Vector2(1,10),Vector2(10,10)]:
  _decorate("pink-shrub",cell,80)
 for cell in [Vector2(0,2),Vector2(11,3),Vector2(1,7),Vector2(9,8)]:
  _decorate("pink-flowers",cell,52)
 _decorate("column",Vector2(0,6),144)
 _decorate("ruined-pier",Vector2(11,6),136)
 _decorate("broken-column",Vector2(5,6),78)
 _decorate("low-wall",Vector2(6,3),80)
 _decorate("hanging-ivy",Vector2(5,2.5),65,4.0)
 _decorate("pots",Vector2(1,7),56)

func _process(_delta: float) -> void: refresh_occlusion()

func refresh_occlusion() -> void:
 occluded_unit_ids.clear()
 if not is_instance_valid(grid) or not is_instance_valid(grid.unit_layer): return
 for decor in decoration_nodes:
  if not is_instance_valid(decor): continue
  var obscures := false
  var rect := decor.get_rect()
  for unit in grid.unit_layer.get_children():
   if not unit is Unit or not unit.visible or unit.z_index>=decor.z_index: continue
   var head: Vector2=decor.to_local(unit.to_global(Vector2(0,-32)))
   if rect.has_point(head):
    obscures=true
    var id := str(unit.get("unit_id"))
    if not id in occluded_unit_ids: occluded_unit_ids.append(id)
  decor.modulate.a=.30 if obscures else 1.0

func _exit_tree() -> void:
 for decor in decoration_nodes:
  if is_instance_valid(decor): decor.queue_free()
 decoration_nodes.clear()
