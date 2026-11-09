extends Node
## Check the real mesh/material binding, not a standalone test-plane assumption.
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok: failures+=1; printerr("FAIL: ",message)
func _ready() -> void: call_deferred("run")
func run() -> void:
 var grid:=TacticalGrid.new()
 var highlights:=Node2D.new(); highlights.name="HighlightLayer"; grid.add_child(highlights)
 var units:=Node2D.new(); units.name="UnitLayer"; grid.add_child(units)
 add_child(grid)
 grid.initialize_from_map(preload("res://prototypes/blooming/BloomingMap.gd").create_map())
 grid.tile_size=Vector2i(128,64); grid.height_step=32.0
 var terrain=preload("res://prototypes/blooming/BloomingTerrain.gd").new()
 grid.terrain_view=terrain; grid.add_child(terrain); terrain.configure(grid)
 for cell in [Vector2i(6,6),Vector2i(6,7)]:
  var floor_node: MeshInstance3D=terrain._visual_root.get_node("Floor_%s"%cell)
  var world_top:=floor_node.to_global(Vector3(0,floor_node.mesh.get_aabb().end.y,0)).y
  var material:=floor_node.material_override as ShaderMaterial
  check(absf(world_top)<.0001,"actual lower floor is world y=0")
  check(absf(material.get_shader_parameter("soil_floor_y")-world_top)<.0001,"soil plane matches actual mesh top")
  check(material.get_shader_parameter("surface")== (1 if cell.y==6 else 0),"gameplay material tag retained")
 check(grid.tiles[Vector2i(6,6)].terrain=="road" and grid.tiles[Vector2i(6,7)].terrain=="stone","gameplay terrain tags retained")
 check(grid._height_at(Vector2i(2,2))==4 and grid._height_at(Vector2i(2,6))==0,"four-level staircase retained")
 grid.queue_free()
 await get_tree().process_frame
 print("Blooming ground contract: %d checks, %d failures"%[checks,failures])
 get_tree().quit(0 if failures==0 else 1)
