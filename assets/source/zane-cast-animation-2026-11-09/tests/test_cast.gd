extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String):
 if not value:
  printerr('FAIL: ' + message)
  failures += 1
  quit(1)
  return false
 checks += 1
 return true
func _initialize():
 if not check(FileAccess.file_exists('res://CastState.gd'), 'cast state implementation exists'):
  return
 var source = load('res://CastState.gd')
 if not check(source != null, 'cast state loads'):
  return
 var state = source.new()
 check(state.pose() == 'se', 'initial SE idle')
 check(state.start_cast(), 'first cast accepted')
 check(not state.start_cast(), 'repeated cast ignored')
 check(not state.set_facing('NW'), 'direction locked during cast')
 check(state.pose() == 'cast-lift-se', 'lift frame at start')
 check(state.advance(0.279) == 0, 'no release before 280 ms')
 check(state.advance(0.0011) == 1, 'one release after 280 ms')
 check(state.pose() == 'cast-release-se', 'release frame active')
 check(state.advance(0.001) == 0, 'release not duplicated')
 state.advance(0.3)
 check(state.pose() == 'cast-extend-se', 'recovery extension pose')
 state.advance(1.0)
 check(state.pose() == 'se' and not state.active, 'returns to idle')
 state.start_cast()
 state.cancel()
 check(state.advance(2.0) == 0 and state.pose() == 'se', 'cancel before release')
 state.start_cast()
 check(state.advance(4.0) == 1 and state.pose() == 'se', 'large delta emits once and completes')
 check(state.set_facing('SW'), 'SW idle available')
 check(not state.start_cast(), 'unsupported SW cast refused')
 check(not state.set_facing('bad') and state.direction == 'SW', 'invalid direction rejected')
 for d in ['SE', 'SW', 'NE', 'NW']:
  check(state.set_facing(d) and state.pose() == d.to_lower(), 'real facing ' + d)
 print('PASS: ', checks, ' cast timing, repeat, cancel, direction and delta checks')
 quit(0 if failures == 0 else 1)
