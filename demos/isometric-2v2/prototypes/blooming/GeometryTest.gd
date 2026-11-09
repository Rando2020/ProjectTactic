extends Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  printerr("FAIL: ",message)
func _ready() -> void: call_deferred("run")
func run() -> void:
 check(ResourceLoader.exists("res://prototypes/blooming/BloomingMap.gd"),"Blooming map contract exists")
 check(ResourceLoader.exists("res://prototypes/blooming/BloomingTerrain.gd"),"Blooming terrain presenter exists")
 if failures:
  finish(); return
 var map = load("res://prototypes/blooming/BloomingMap.gd").create_map()
 check(map.map_width == 12 and map.map_height == 11,"bounded courtyard dimensions")
 check(map.objective_type == "defeat_all","reuse implemented objective")
 check(map.reward_gold == 0 and map.reward_jp == 0,"practice no reward")
 var grid := TacticalGrid.new()
 var highlights := Node2D.new(); highlights.name="HighlightLayer"; grid.add_child(highlights)
 var units := Node2D.new(); units.name="UnitLayer"; grid.add_child(units)
 add_child(grid)
 grid.initialize_from_map(map)
 grid.tile_size=Vector2i(128,64); grid.height_step=32.0
 for x in [2,3,8,9]:
  for y in range(2,7):
   check(grid._height_at(Vector2i(x,y))==maxi(0,6-y),"stair height %s"%Vector2i(x,y))
 var terrain = load("res://prototypes/blooming/BloomingTerrain.gd").new()
 grid.terrain_view=terrain; grid.add_child(terrain); terrain.configure(grid)
 await get_tree().process_frame
 for pos: Vector2i in grid.tiles:
  if grid.tiles[pos].blocks_movement:continue
  var point: Vector2=terrain.projected_point(Vector2(pos))
  check(terrain.projected_tile_center(pos).distance_to(point)<0.2,"actual camera matches logical surface %s"%pos)
  check(point.distance_to(grid._grid_to_local(pos))<0.1,"height projection alignment %s"%pos)
  check(terrain.pick_cell(point)==pos,"height-aware center picking %s got %s"%[pos,terrain.pick_cell(point)])
  check(Geometry2D.is_point_in_polygon(point,terrain.surface_polygon(pos)),"center inside top footprint %s"%pos)
 check(terrain.pick_cell(Vector2(-99999,-99999))==Vector2i(-1,-1),"outside rejected")
 check(terrain.get_board_bounds().has_point(terrain.projected_point(Vector2(2,2))),"upper landing bounded")
 for x in [2,3,8,9]:
  for y in [3,4,5]:
   var cell := Vector2i(x,y)
   check(terrain.surface_polygons(cell).size()==3,"three real tread footprints %s"%cell)
   for i in 3:
    var tread_cell := Vector2(cell)+Vector2(0,(-1.0+i)/3.0)
    var h := float(grid._height_at(cell))+(1.0-i)/3.0
    var p: Vector2=terrain.projected_point(tread_cell,h)
    check(terrain.pick_cell(p)==cell,"every narrow tread picks logical cell %s/%d"%[cell,i])
 var count: int=terrain.decoration_nodes.size()
 terrain.configure(grid)
 check(terrain.decoration_nodes.size()==count,"reconfigure does not duplicate art")
 check(terrain.decoration_nodes.size()>=20,"painted environment pieces present")
 var ivy_found := false
 for piece: Sprite2D in terrain.decoration_nodes:
  if piece.name=="Bloom_hanging-ivy":
   ivy_found=true
   check(piece.position.distance_to(terrain.projected_point(Vector2(5,2.5),4.0))<0.1,"ivy top pivot attaches to actual h4 terrace lip")
 check(ivy_found,"hanging ivy present")
 var decor: Sprite2D=terrain.decoration_nodes[0]
 var known := Unit.new(); known.unit_id="occlusion_probe"
 grid.unit_layer.add_child(known)
 known.position=decor.position+Vector2(0,-100)+Vector2(0,32)
 known.z_index=decor.z_index-1
 terrain.refresh_occlusion()
 check(terrain.occluded_unit_ids.has("occlusion_probe"),"known unit occlusion recorded")
 check(decor.modulate.a<0.5,"foreground fades to reveal known unit")
 known.position=Vector2(-99999,-99999)
 terrain.refresh_occlusion()
 check(terrain.occluded_unit_ids.is_empty(),"occlusion clears outside art")
 check(is_equal_approx(decor.modulate.a,1.0),"foreground restores after unit moves")
 grid.queue_free(); await get_tree().process_frame
 finish()
func finish() -> void:
 print("Blooming geometry: %d checks, %d failures"%[checks,failures])
 get_tree().quit(0 if failures==0 else 1)
