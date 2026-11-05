extends Node2D
## Standalone diagnostic only. No gameplay integration or visual acceptance.
const META_PATH = "res://proposed-registration.json"
var meta: Dictionary
var sprites: Array[Sprite2D] = []
var markers: Array[Vector2] = []
var panels: Array[Vector2] = [Vector2(235,260),Vector2(735,260),Vector2(1190,260),Vector2(350,680),Vector2(1030,680)]

func iso(cell: Vector2) -> Vector2:
 return Vector2((cell.x-cell.y)*48.0,(cell.x+cell.y)*24.0)

func label_at(text: String, pos: Vector2, size: int = 18) -> void:
 var l := Label.new()
 l.text=text; l.position=pos; l.add_theme_font_size_override("font_size",size)
 l.z_index=2000
 add_child(l)

func make_sprite(key: String, anchor: Vector2, multiplier: float = 1.0) -> Sprite2D:
 var d: Dictionary = meta.assets[key]
 var s := Sprite2D.new()
 s.texture=load("res://assets/"+d.file)
 s.centered=false
 if d.has("region"):
  s.region_enabled=true
  var r: Array=d.region
  s.region_rect=Rect2(r[0],r[1],r[2],r[3])
 s.offset=-Vector2(d.pivot[0],d.pivot[1])
 s.scale=Vector2.ONE*float(d.scale)*multiplier
 s.position=anchor
 s.z_index=int(anchor.y)
 # Match existing Blooming alpha cutoff. Originals remain byte-for-byte unchanged.
 var shader := Shader.new()
 shader.code="shader_type canvas_item; void fragment(){if(texture(TEXTURE,UV).a<0.5)discard;}"
 var material := ShaderMaterial.new(); material.shader=shader; s.material=material
 add_child(s); sprites.append(s); markers.append(anchor)
 return s

func probe_head(s: Sprite2D, global_head: Vector2) -> Dictionary:
 var p: Vector2=s.to_local(global_head)
 var in_rect: bool=s.get_rect().has_point(p)
 var pixel: Vector2=p-s.offset
 if s.region_enabled: pixel+=s.region_rect.position
 var im: Image=s.texture.get_image()
 var opaque := false
 if in_rect and pixel.x>=0 and pixel.y>=0 and pixel.x<im.get_width() and pixel.y<im.get_height():
  opaque=im.get_pixelv(Vector2i(pixel)).a>=0.5
 return {"rectangle":in_rect,"alpha":opaque}

func actor(pos: Vector2) -> void:
 var body := Polygon2D.new()
 body.polygon=PackedVector2Array([Vector2(-10,0),Vector2(10,0),Vector2(8,-32),Vector2(0,-46),Vector2(-8,-32)])
 body.color=Color("57cddd"); body.position=pos; body.z_index=int(pos.y)
 add_child(body)

func _ready() -> void:
 meta=JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
 label_at("BLOOMING TERRAIN | ISOLATED ASSEMBLY PROOF",Vector2(28,18),26)
 label_at("96 x 48 grid. Cyan crosses = proposed anchors. Candidate art and registration are NOT approved.",Vector2(28,54))
 label_at("1  Native 80px visible height",Vector2(35,100))
 label_at("2  Shared source scale 0.18",Vector2(530,100))
 label_at("3  Proposed join attempt",Vector2(1000,100))
 var keys: Array[String]=["existing","corner","end"]
 for i in 3:
  var key: String=keys[i]
  var d: Dictionary=meta.assets[key]
  var vheight: float=d.visible_size[1]
  var s:=make_sprite(key,panels[0]+Vector2((i-1)*135,0),80.0/(vheight*float(d.scale)))
  label_at(key,Vector2(s.position.x-40,340),16)
  make_sprite(key,panels[1]+Vector2((i-1)*135,0),0.18/float(d.scale))
 # Anchor a candidate branch terminator at the corner's visually measured right socket.
 # This aligns one base point, deliberately does not claim compatible cap height/thickness.
 make_sprite("corner",panels[2])
 var socket: Vector2=panels[2]+Vector2(432,-220)*0.18
 var end_anchor: Vector2=socket-Vector2(-351,-148)*0.18
 make_sprite("end",end_anchor)
 label_at("One base point aligned; inspect caps,",Vector2(995,355),16)
 label_at("thickness and silhouette overlap.",Vector2(995,378),16)
 label_at("4  Footprint and ground-overlay test",Vector2(35,450))
 make_sprite("corner",panels[3])
 make_sprite("scatter",panels[3]+iso(Vector2(2,0)))
 actor(panels[3]+iso(Vector2(0,-1)))
 actor(panels[3]+iso(Vector2(0,1)))
 label_at("Outlined cells are diagnostic proposals, not collision.",Vector2(35,805),16)
 label_at("5  Existing rectangle occlusion vs alpha probe",Vector2(755,450))
 var occluder:=make_sprite("corner",panels[4])
 var clear_head: Vector2=occluder.to_global(occluder.offset+Vector2(887,120))
 var solid_head: Vector2=occluder.to_global(occluder.offset+Vector2(887,550))
 actor(clear_head+Vector2(0,32)); actor(solid_head+Vector2(0,32))
 var clear_test:=probe_head(occluder,clear_head)
 var solid_test:=probe_head(occluder,solid_head)
 label_at("Transparent head: box=%s / alpha=%s"%[clear_test.rectangle,clear_test.alpha],Vector2(755,805),16)
 label_at("Stone head: box=%s / alpha=%s"%[solid_test.rectangle,solid_test.alpha],Vector2(755,830),16)
 label_at("Box-only fading falsely detects transparent canvas.",Vector2(755,855),16)
 label_at("No rotations, pixel edits, inferred collision, or live asset replacements. Blue actors are scale/occlusion probes.",Vector2(28,945),18)
 assert(iso(Vector2(1,0))==Vector2(48,24))
 assert(iso(Vector2(0,1))==Vector2(-48,24))
 assert(clear_test.rectangle and not clear_test.alpha)
 assert(solid_test.rectangle and solid_test.alpha)
 print("PASS: 96x48 projection, transparent-canvas false-positive reproduced, solid alpha probe detected, source textures loaded")
 for arg in OS.get_cmdline_user_args():
  if arg=="--self-test": get_tree().quit(); return
  if arg.begins_with("--capture-dir="):
   if DisplayServer.get_name()=="headless":
    push_error("Rendered evidence requires a display; headless output is not a screenshot")
    get_tree().quit(2); return
   await RenderingServer.frame_post_draw
   var dir: String=arg.trim_prefix("--capture-dir=")
   DirAccess.make_dir_recursive_absolute(dir)
   var error:=get_viewport().get_texture().get_image().save_png(dir+"/terrain-assembly.png")
   assert(error==OK)
   print("CAPTURE: "+dir+"/terrain-assembly.png")
   get_tree().quit()

func _draw() -> void:
 for origin in panels:
  for x in range(-2,3):
   for y in range(-2,3):
    var c:=origin+iso(Vector2(x,y))
    var poly:=PackedVector2Array([c+Vector2(0,-24),c+Vector2(48,0),c+Vector2(0,24),c+Vector2(-48,0),c+Vector2(0,-24)])
    draw_colored_polygon(poly,Color(0.30,0.26,0.22,0.7))
    draw_polyline(poly,Color(0.65,0.57,0.4,0.5),1)
 for cell in [Vector2.ZERO,Vector2(-1,0),Vector2(0,-1)]:
  var c:=panels[3]+iso(cell)
  draw_polyline(PackedVector2Array([c+Vector2(0,-24),c+Vector2(48,0),c+Vector2(0,24),c+Vector2(-48,0),c+Vector2(0,-24)]),Color.CORAL,3)
 for p in markers:
  draw_line(p-Vector2(6,0),p+Vector2(6,0),Color.CYAN,2)
  draw_line(p-Vector2(0,6),p+Vector2(0,6),Color.CYAN,2)
