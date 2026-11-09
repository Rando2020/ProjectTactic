extends RefCounted
## Geometric source in (cell x, logical height, cell y). No source image edits.
const WIDTH := .26
const CAP_WIDTH := .34
const HEIGHT := 1.25
const CAP_RISE := .18
static func definition(kind: String) -> Dictionary:
 assert(kind in ["straight","corner","end"])
 var end:=Vector2(.5,-.5) if kind=="corner" else Vector2(1,0)
 var outward:=Vector2(0,-1) if kind=="corner" else Vector2(1,0)
 return {"height":HEIGHT,"width":WIDTH,"cap_width":CAP_WIDTH,"sockets":[
  {"position":Vector2.ZERO,"normal":Vector2(-1,0),"width":WIDTH,"cap_width":CAP_WIDTH,"height":HEIGHT},
  {"position":end,"normal":outward,"width":WIDTH,"cap_width":CAP_WIDTH,"height":HEIGHT,"closed":kind=="end"}]}
static func footprint(kind: String, width: float) -> PackedVector2Array:
 var w:=width*.5
 if kind=="corner":
  return PackedVector2Array([Vector2(0,-w),Vector2(.5-w,-w),Vector2(.5-w,-.5),Vector2(.5+w,-.5),Vector2(.5+w,w),Vector2(0,w)])
 return PackedVector2Array([Vector2(0,-w),Vector2(1,-w),Vector2(1,w),Vector2(0,w)])
static func transform_point(point: Vector2, origin: Vector2, quarter_turn: int) -> Vector2:
 for i in posmod(quarter_turn,4):point=Vector2(-point.y,point.x)
 return origin+point
static func sockets(kind: String, origin: Vector2, quarter_turn: int, base: float) -> Array:
 var result: Array=[]
 for source in definition(kind).sockets:
  var socket: Dictionary=source.duplicate()
  socket.position=transform_point(source.position,origin,quarter_turn)
  socket.normal=transform_point(source.normal,Vector2.ZERO,quarter_turn)
  socket.base=base
  result.append(socket)
 return result
static func faces(kind: String, origin: Vector2, quarter_turn: int, base: float) -> Array:
 var result: Array=[]
 for layer in [{"width":WIDTH,"bottom":base,"top":base+HEIGHT-CAP_RISE,"cap":false},{"width":CAP_WIDTH,"bottom":base+HEIGHT-CAP_RISE,"top":base+HEIGHT,"cap":true}]:
  var outline:=PackedVector2Array()
  for point in footprint(kind,layer.width):outline.append(transform_point(point,origin,quarter_turn))
  for i in outline.size():
   var a:=outline[i];var b:=outline[(i+1)%outline.size()]
   var normal:=Vector2(b.y-a.y,a.x-b.x).normalized()
   if normal.x+normal.y<=0.001:continue
   result.append({"points":PackedVector3Array([Vector3(a.x,layer.bottom,a.y),Vector3(b.x,layer.bottom,b.y),Vector3(b.x,layer.top,b.y),Vector3(a.x,layer.top,a.y)]),"top":false,"axis_x":absf(normal.y)>.5,"cap":layer.cap,"shade":.86 if normal.y>.5 else .73})
  if layer.cap:
   var points:=PackedVector3Array()
   for point in outline:points.append(Vector3(point.x,layer.top,point.y))
   result.append({"points":points,"top":true,"axis_x":false,"cap":true,"shade":1.0})
 return result
