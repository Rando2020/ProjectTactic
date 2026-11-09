extends Node2D
const State = preload('res://CastState.gd')
var state = State.new()
var manifest: Dictionary
var actor: Sprite2D
var status: Label
var releases := 0
var textures := {}
func _ready():
 manifest = JSON.parse_string(FileAccess.get_file_as_string('res://manifest.json'))
 RenderingServer.set_default_clear_color(Color('#101b24'))
 _label('ZANE / CAST KEY-POSE REVIEW', Vector2(36,24), 28)
 _label('CANDIDATES ONLY. Five poses, seven timed segments. Preview only, not a live battle.',Vector2(36,64),18)
 _label('1 SE   2 SW   3 NE   4 NW     SPACE cast (SE only)     ESC cancel',Vector2(36,98),18)
 for key in manifest.files:
  textures[key] = load('res://' + manifest.files[key].file)
 for i in range(4):
  var d = ['se','sw','ne','nw'][i]
  _label(d.to_upper() + ' / 85 px',Vector2(52+i*160,170),17)
  _sprite(d,Vector2(106+i*160,310),1.0)
 actor = _sprite('se', Vector2(960,575),3.4)
 _label('SE timing strip / same source transform', Vector2(36,390),20)
 for i in range(5):
  var p = ['se','cast-lift-se','cast-windup-se','cast-extend-se','cast-release-se'][i]
  _sprite(p,Vector2(80+i*125,555),1.2)
  _label(['Idle','Lift 80ms','Windup 120ms','Extend 80ms','Release 240ms'][i],Vector2(24+i*125,590),13)
 status = _label('',Vector2(36,670),19)
 _label('Source images are unchanged. Boot midpoint registration is provisional. No mirroring.', Vector2(36,715),17)
 if '--smoke' in OS.get_cmdline_user_args():
  state.start_cast()
  await get_tree().create_timer(1.1).timeout
  assert(not state.active and releases == 1)
  print('PASS: review scene loaded all 8 textures; cast returned to idle; release count 1')
  get_tree().quit()
func _sprite(key: String, pos: Vector2, zoom: float) -> Sprite2D:
 var node = Sprite2D.new()
 add_child(node)
 node.position = pos
 _apply(node,key,zoom)
 return node
func _apply(node: Sprite2D,key: String,zoom: float):
 var v: Dictionary = manifest.files[key]
 node.texture = textures[key]
 node.scale = Vector2.ONE*float(v.scale)*zoom
 node.offset = Vector2(627,627)-Vector2(v.pivot[0],v.pivot[1])
 node.flip_h = false
func _label(text_value: String, pos: Vector2, font_size: int) -> Label:
 var node = Label.new()
 add_child(node)
 node.text = text_value
 node.position = pos
 node.add_theme_font_size_override('font_size',font_size)
 return node
func _process(delta: float):
 releases += state.advance(delta)
 _apply(actor,state.pose(),3.4)
 status.text = 'Facing %s | Pose %s | Release events %d' % [state.direction,state.pose(),releases]
func _unhandled_key_input(event):
 if not event.is_pressed() or event.echo:
  return
 if event.keycode == KEY_SPACE:
  state.start_cast()
 elif event.keycode == KEY_ESCAPE:
  state.cancel()
 elif event.keycode in [KEY_1,KEY_2,KEY_3,KEY_4]:
  state.set_facing(['SE','SW','NE','NW'][event.keycode-KEY_1])
func _draw():
 for x in range(4):
  for y in range(4):
   var center=Vector2(960+(x-y)*48,490+(x+y)*24)
   var polygon=PackedVector2Array([center+Vector2(0,-24),center+Vector2(48,0),center+Vector2(0,24),center+Vector2(-48,0)])
   draw_colored_polygon(polygon,Color('#263d49') if (x+y)%2 == 0 else Color('#304a57'))
   draw_polyline(PackedVector2Array([polygon[0],polygon[1],polygon[2],polygon[3],polygon[0]]),Color('#546978'),1)
