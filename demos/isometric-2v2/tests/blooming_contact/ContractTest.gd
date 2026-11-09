extends Node
var checks:=0
var failures:=0
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok: failures+=1;printerr("FAIL: ",message)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var grid:=TacticalGrid.new()
 var highlights:=Node2D.new();highlights.name="HighlightLayer";grid.add_child(highlights)
 var units:=Node2D.new();units.name="UnitLayer";grid.add_child(units)
 add_child(grid)
 grid.initialize_from_map(preload("res://prototypes/blooming/BloomingMap.gd").create_map())
 grid.tile_size=Vector2i(128,64);grid.height_step=32.0
 var before:=grid.tiles.duplicate(true)
 var terrain=preload("res://prototypes/blooming/BloomingTerrain.gd").new()
 grid.terrain_view=terrain;grid.add_child(terrain);terrain.configure(grid)
 var points=terrain.get("contact_points")
 check(typeof(points)==TYPE_PACKED_VECTOR4_ARRAY,"contact list exists")
 if typeof(points)==TYPE_PACKED_VECTOR4_ARRAY:
  check(points.size()==10,"ten supported props only")
  for p: Vector4 in points:
   var cell:=Vector2i(roundi(p.x/2),roundi(p.y/2))
   var support: Vector3=terrain._visual_root.to_global(Vector3(cell.x*2,terrain.BASE_TILE_TOP_Y+grid._height_at(cell)*terrain.MODEL_HEIGHT_STEP,cell.y*2))
   check(absf(p.z-support.y)<.0001,"contact matches transformed support height")
   check(p.w>=.25 and p.w<=.8,"small bounded footprint")
  for i in 4:terrain.configure(grid)
  check(terrain.contact_points==points,"reconfigure does not duplicate or lose contacts")
  for material: ShaderMaterial in terrain._materials.values():check(material.get_shader_parameter("contact_count")==10,"material receives all contacts")
  check(terrain._viewport.render_target_update_mode==SubViewport.UPDATE_ONCE,"cached viewport refresh requested")
 check(grid.tiles==before,"authoritative tiles unchanged")
 grid.queue_free();await get_tree().process_frame
 print("Blooming contact contract: %d checks, %d failures"%[checks,failures])
 get_tree().quit(0 if failures==0 else 1)
