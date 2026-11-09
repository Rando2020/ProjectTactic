extends Node
var checks:=0
var failures:=0
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok: failures+=1;printerr("FAIL: ",message)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var path:="res://prototypes/blooming/walls/WallKit.gd"
 check(ResourceLoader.exists(path),"shared wall kit exists")
 if failures: finish();return
 var kit=load(path)
 for kind in ["straight","corner","end"]:
  var piece: Dictionary=kit.definition(kind)
  check(piece.sockets.size()==2,"two exact sockets: "+kind)
  check(piece.height==1.25,"shared cap height: "+kind)
  check(piece.width==.26,"shared body width: "+kind)
  check(piece.cap_width==.34,"shared cap width: "+kind)
  for socket in piece.sockets:
   check(socket.width==.26 and socket.cap_width==.34 and socket.height==1.25,"socket cross-section: "+kind)
  var faces: Array=kit.faces(kind,Vector2.ZERO,0,4.0)
  check(not faces.is_empty(),"projected solid faces: "+kind)
  for face in faces:
   for point in face.points:
    check(point.y>=4.0 and point.y<=5.25,"all vertices respect shared rise: "+kind)
 var grid:=TacticalGrid.new()
 var highlights:=Node2D.new();highlights.name="HighlightLayer";grid.add_child(highlights)
 var units:=Node2D.new();units.name="UnitLayer";grid.add_child(units)
 add_child(grid)
 grid.initialize_from_map(preload("res://prototypes/blooming/BloomingMap.gd").create_map())
 grid.tile_size=Vector2i(128,64);grid.height_step=32.0
 var terrain=preload("res://prototypes/blooming/BloomingTerrain.gd").new()
 grid.terrain_view=terrain;grid.add_child(terrain);terrain.configure(grid)
 var before:=grid.tiles.duplicate(true)
 var install=load("res://prototypes/blooming/walls/WallCandidate.gd").new()
 grid.add_child(install);install.configure(grid)
 check(install.pieces.size()==8,"eight connected review pieces")
 for pair in [[0,0,1,0],[2,1,3,0],[3,1,4,0],[4,1,5,0],[6,1,7,0]]:
  var a: Dictionary=install.pieces[pair[0]].socket_data[pair[1]]
  var b: Dictionary=install.pieces[pair[2]].socket_data[pair[3]]
  check(a.position==b.position,"joined socket exact position")
  check(a.normal==-b.normal,"joined socket opposed normal")
  check(a.base==b.base and a.height==b.height,"joined socket shared cap elevation")
  for width in [a.width,a.cap_width]:
   var tangent: Vector2=Vector2(-a.normal.y,a.normal.x)*width*.5
   check((a.position+tangent)==(b.position-Vector2(-b.normal.y,b.normal.x)*width*.5),"joined cross-section edge exact")
 for p in install.pieces:
  for f in p.faces:
   for point in f.polygon:check(point.is_finite(),"finite projected geometry")
 var piece=install.pieces[2]
 check(piece.z_index>0,"wall follows depth-sorted unit layer")
 var solid: Vector2=piece.faces[-1].polygon[0].lerp(piece.faces[-1].polygon[2],.5)
 check(piece.contains_projected(solid),"solid cap detected")
 check(not piece.contains_projected(Vector2(-9999,-9999)),"clear space excluded")
 var unit:=Unit.new();unit.unit_id="wall_probe";grid.unit_layer.add_child(unit)
 unit.position=solid+Vector2(0,32);unit.z_index=piece.z_index-1
 piece.refresh_occlusion()
 check(piece.occluded_unit_ids==["wall_probe"] and is_equal_approx(piece.modulate.a,.3),"behind solid wall fades")
 unit.position=Vector2(-9999,-9999);piece.refresh_occlusion()
 check(piece.occluded_unit_ids.is_empty() and piece.modulate.a==1.,"moving actor restores wall")
 unit.position=solid+Vector2(0,32);unit.z_index=piece.z_index+1;piece.refresh_occlusion()
 check(piece.modulate.a==1.,"front actor does not fade wall")
 unit.z_index=piece.z_index-1;unit.hide();piece.refresh_occlusion()
 check(piece.modulate.a==1.,"hidden actor does not fade wall")
 unit.queue_free()
 for x in [2,3,8,9]:
  for y in range(2,7):
   var cell:=Vector2i(x,y)
   check(terrain.pick_cell(terrain.projected_point(Vector2(cell)))==cell,"stair/landing picking preserved %s"%cell)
 for i in 3:install.configure(grid)
 check(install.pieces.size()==8,"repeat configure no duplicates")
 check(grid.tiles==before,"authoritative map unchanged")
 var wall: Sprite2D
 for decor: Sprite2D in terrain.decoration_nodes:
  if decor.name=="Bloom_low-wall":wall=decor
 check(wall!=null and not wall.visible,"original wall hidden only during opt-in review")
 install.uninstall()
 check(wall.visible,"uninstall restores original wall")
 check(install.pieces.is_empty(),"uninstall removes all pieces")
 grid.queue_free();await get_tree().process_frame
 finish()
func finish() -> void:
 print("Joinable wall contract: %d checks, %d failures"%[checks,failures])
 get_tree().quit(0 if failures==0 else 1)
