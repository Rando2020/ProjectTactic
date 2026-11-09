extends Node2D
const Kit=preload("res://prototypes/blooming/walls/WallKit.gd")
var faces: Array[Polygon2D]=[]
var socket_data: Array=[]
var grid: TacticalGrid
var occluded_unit_ids: Array[String]=[]
func configure(p_grid: TacticalGrid, kind: String, origin: Vector2, turn: int, base: float) -> void:
 grid=p_grid
 socket_data=Kit.sockets(kind,origin,turn,base)
 var center: Vector2=(socket_data[0].position+socket_data[1].position)*.5
 z_index=roundi((center.x+center.y)*10+base*2)+112
 var texture=preload("res://assets/environments/blooming-ruins-v2/surfaces.png")
 for source in Kit.faces(kind,origin,turn,base):
  var face:=Polygon2D.new()
  var points:=PackedVector2Array();var uv:=PackedVector2Array()
  for p: Vector3 in source.points:
   points.append(grid.terrain_view.projected_point(Vector2(p.x,p.z),p.y))
   var q:=Vector2(p.x,p.z) if source.top else Vector2(p.x if source.axis_x else p.z,-p.y*.82/2.)
   uv.append(q*.65*Vector2(texture.get_size()))
  face.polygon=points;face.uv=uv;face.texture=texture
  face.color=Color(source.shade,source.shade,source.shade,1.)
  var material:=ShaderMaterial.new();material.shader=preload("res://prototypes/blooming/walls/WallPaint.gdshader")
  material.set_shader_parameter("coping",source.cap)
  face.material=material;face.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  add_child(face);faces.append(face)
func contains_projected(point: Vector2) -> bool:
 for face in faces:
  if Geometry2D.is_point_in_polygon(point,face.polygon):return true
 return false
func refresh_occlusion() -> void:
 occluded_unit_ids.clear()
 for unit in grid.unit_layer.get_children():
  if not unit is Unit or not unit.is_visible_in_tree() or _body_depth(unit)>=z_index:continue
  for offset in [Vector2(0,-32),Vector2(0,-16)]:
   if contains_projected(to_local(unit.to_global(offset))):
    occluded_unit_ids.append(str(unit.unit_id));break
 modulate.a=.30 if not occluded_unit_ids.is_empty() else 1.0
func _body_depth(unit: Unit) -> int:
 var depth:=unit.z_index
 for key in ["_sprite","_rig3d","_body_rect"]:
  var body=unit.get(key)
  if is_instance_valid(body) and body is CanvasItem and body.is_visible_in_tree():
   depth=maxi(depth,unit.z_index+body.z_index if body.z_as_relative else body.z_index)
 return depth
