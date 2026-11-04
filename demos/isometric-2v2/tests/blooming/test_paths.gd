extends Node
func _ready() -> void: call_deferred("run")
func run() -> void:
 var grid := TacticalGrid.new()
 var highlights := Node2D.new(); highlights.name="HighlightLayer";grid.add_child(highlights)
 var units := Node2D.new(); units.name="UnitLayer";grid.add_child(units)
 add_child(grid)
 grid.initialize_from_map(load("res://prototypes/blooming/BloomingMap.gd").create_map())
 var checked:=0
 var failures:=0
 for origin: Vector2i in grid.tiles:
  if grid.tiles[origin].blocks_movement:continue
  var reachable = GridSystem.get_move_range(origin,8,grid.tiles,[],12,11,2)
  for target: Vector2i in reachable:
   var path = GridSystem.find_path(origin,target,grid.tiles,[],12,11)
   for i in range(1,path.size()):
    checked+=1
    if absi(grid.tiles[path[i]].height-grid.tiles[path[i-1]].height)>2:
     failures+=1
     if failures<6:printerr("FAIL: reachable target %s from %s gets illegal cliff edge %s -> %s"%[target,origin,path[i-1],path[i]])
 for x in [2,3,8,9]:
  var stair_path=GridSystem.find_path(Vector2i(x,6),Vector2i(x,2),grid.tiles,[],12,11)
  if stair_path.size()!=5:
   failures+=1;printerr("FAIL: stair lane is not four contiguous moves")
  var reachable=GridSystem.get_move_range(Vector2i(x,6),8,grid.tiles,[],12,11,2)
  if not Vector2i(x,2) in reachable:
   failures+=1;printerr("FAIL: full stair ascent not reachable at exact height-inclusive cost")
  var short=GridSystem.get_move_range(Vector2i(x,6),7,grid.tiles,[],12,11,2)
  if Vector2i(x,2) in short:
   failures+=1;printerr("FAIL: stair cost ignores ascent height")
 print("Blooming path edge checks: %d, failures: %d"%[checked,failures])
 grid.queue_free();await get_tree().process_frame
 get_tree().quit(1 if failures else 0)
