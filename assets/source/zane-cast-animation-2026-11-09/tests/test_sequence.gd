extends SceneTree
var failures := 0
func expect(value: bool, message: String):
 if not value:
  failures += 1
  printerr('FAIL: ' + message)
func _initialize():
 var source = load('res://CastState.gd')
 var state = source.new()
 state.start_cast()
 var points = [0.0,0.079,0.081,0.199,0.201,0.279,0.281,0.519,0.521,0.599,0.601,0.679,0.681,0.759]
 var names = ['cast-lift-se','cast-lift-se','cast-windup-se','cast-windup-se','cast-extend-se','cast-extend-se','cast-release-se','cast-release-se','cast-extend-se','cast-extend-se','cast-windup-se','cast-windup-se','cast-lift-se','cast-lift-se']
 for i in range(points.size()):
  state.elapsed = points[i]
  expect(state.pose() == names[i], 'pose at ' + str(points[i]) + 's')
 state.elapsed = 0.0
 expect(state.advance(-1.0) == 0 and state.elapsed == 0.0, 'negative delta ignored')
 expect(state.advance(0.76) == 1 and state.pose() == 'se', '760ms completion, one release')
 expect(state.advance(1.0) == 0 and state.pose() == 'se', 'no delayed duplicate')
 state.start_cast()
 state.advance(0.3)
 state.cancel()
 expect(not state.active and state.advance(1.0) == 0, 'cancel after release returns idle')
 print('SEQUENCE CHECKS: 18; failures: ', failures)
 quit(0 if failures == 0 else 1)
