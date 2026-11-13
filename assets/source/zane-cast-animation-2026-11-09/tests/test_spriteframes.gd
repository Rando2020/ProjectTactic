extends SceneTree
var failures := 0
func check(value: bool, message: String):
 if not value:
  failures += 1
  printerr('FAIL: ' + message)
func _initialize():
 if not FileAccess.file_exists('res://zane-se-spriteframes.tres'):
  printerr('FAIL: importable SpriteFrames resource missing')
  quit(1)
  return
 var frames = load('res://zane-se-spriteframes.tres') as SpriteFrames
 check(frames != null, 'SpriteFrames loads')
 check(frames.get_frame_count('cast-se') == 7, 'seven timed cast segments')
 check(is_equal_approx(frames.get_animation_speed('cast-se'),50.0), '50fps timing grid')
 check(not frames.get_animation_loop('cast-se'), 'cast does not loop')
 check(frames.get_frame_count('idle-se') == 1, 'idle frame present')
 var expected=[4.0,6.0,4.0,12.0,4.0,4.0,4.0]
 var total := 0.0
 for i in range(7):
  check(is_equal_approx(frames.get_frame_duration('cast-se',i),expected[i]), 'duration ' + str(i))
  check(frames.get_frame_texture('cast-se',i).get_size()==Vector2(1254,1254),'texture size ' + str(i))
  total+=frames.get_frame_duration('cast-se',i)/50.0
 check(is_equal_approx(total,0.76),'760ms cast')
 print('SPRITEFRAMES CHECKS: 20; failures: ', failures)
 quit(0 if failures == 0 else 1)
