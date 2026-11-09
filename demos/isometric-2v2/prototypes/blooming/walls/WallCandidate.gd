extends Node
## Opt-in only; does not change map, source art, default scenes or unit state.
const Piece=preload("res://prototypes/blooming/walls/WallPiece.gd")
const LAYOUT := [
 {"kind":"end","origin":Vector2(1,2),"turn":3},
 {"kind":"corner","origin":Vector2(1,2),"turn":1},
 {"kind":"straight","origin":Vector2(3.5,2.5),"turn":0},
 {"kind":"straight","origin":Vector2(4.5,2.5),"turn":0},
 {"kind":"straight","origin":Vector2(5.5,2.5),"turn":0},
 {"kind":"straight","origin":Vector2(6.5,2.5),"turn":0},
 {"kind":"corner","origin":Vector2(9.5,2.5),"turn":0},
 {"kind":"end","origin":Vector2(10,2),"turn":3},
]
var pieces: Array[Node2D]=[]
var grid: TacticalGrid
var original_wall: Sprite2D
var original_visible:=true
func configure(p_grid: TacticalGrid) -> void:
 if not pieces.is_empty():return
 grid=p_grid
 for decor: Sprite2D in grid.terrain_view.decoration_nodes:
  if decor.name=="Bloom_low-wall":
   original_wall=decor;original_visible=decor.visible;decor.hide()
 for item in LAYOUT:
  var piece:=Piece.new()
  piece.name="JoinableWall_%d"%pieces.size()
  grid.unit_layer.add_child(piece)
  piece.configure(grid,item.kind,item.origin,item.turn,4.0)
  pieces.append(piece)
 set_process(true)
func _process(_delta: float) -> void:
 for piece in pieces:
  if is_instance_valid(piece):piece.refresh_occlusion()
func uninstall() -> void:
 for piece in pieces:
  if is_instance_valid(piece):
   piece.get_parent().remove_child(piece);piece.queue_free()
 pieces.clear()
 if is_instance_valid(original_wall):original_wall.visible=original_visible
 set_process(false)
func _exit_tree() -> void:uninstall()
