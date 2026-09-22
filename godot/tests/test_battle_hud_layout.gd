extends SceneTree

const BattleHudLayout := preload("res://scripts/ui/BattleHudLayout.gd")

var assertions := 0
var failures := 0


func _initialize() -> void:
	_check_layout(Vector2(1920, 1080), 360.0)
	_check_layout(Vector2(1600, 900), 360.0)
	_check_layout(Vector2(1366, 768), 320.0)
	_check_layout(Vector2(1280, 720), 320.0)
	if assertions == 0:
		push_error("Battle HUD layout contract executed no assertions")
		quit(1)
		return
	if failures > 0:
		push_error("Battle HUD layout contract failed: %d/%d assertions" % [failures, assertions])
		quit(1)
		return
	print("Battle HUD layout contract: OK (%d assertions)" % assertions)
	quit(0)


func _check_layout(viewport_size: Vector2, expected_width: float) -> void:
	var rect: Rect2 = BattleHudLayout.right_sidebar_rect(viewport_size)
	var command_button_width: float = BattleHudLayout.command_button_width(rect.size.x)
	_expect_eq(rect.size.x, expected_width, "%dx%d selects expected rail width" % [viewport_size.x, viewport_size.y])
	_expect_true(rect.position.x >= viewport_size.x * 0.70, "%dx%d keeps rail in rightmost 30 percent" % [viewport_size.x, viewport_size.y])
	_expect_true(rect.end.x <= viewport_size.x, "%dx%d keeps rail inside viewport width" % [viewport_size.x, viewport_size.y])
	_expect_true(rect.end.y <= viewport_size.y, "%dx%d keeps rail inside viewport height" % [viewport_size.x, viewport_size.y])
	_expect_true(rect.size.y > 0.0, "%dx%d keeps a usable rail height" % [viewport_size.x, viewport_size.y])
	_expect_true(command_button_width >= 70.0, "%dx%d keeps four command buttons readable" % [viewport_size.x, viewport_size.y])


func _expect_true(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect_true(actual == expected, "%s: expected %s, got %s" % [message, expected, actual])
