extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var scene = load("res://preview.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.cells.size() == 25)
	assert(scene.can_step(Vector2i(2,4), Vector2i(2,3)))
	assert(not scene.can_step(Vector2i(3,2), Vector2i(4,2)))
	assert(not scene.can_step(Vector2i(3,1), Vector2i(3,0)))
	assert(scene.can_step(Vector2i(2,1), Vector2i(2,0)))
	assert(scene.can_step(Vector2i(2,0), Vector2i(2,1)))
	assert(not scene.can_step(Vector2i(1,1), Vector2i(2,1)))
	assert(not scene.can_step(Vector2i(0,0), Vector2i(-1,0)))
	assert(not scene.can_step(Vector2i(2,4), Vector2i(3,3)))
	assert(scene.cell_world(Vector2i(2,0)) == Vector3(0,1,-4))
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_UP
	scene._unhandled_key_input(key)
	assert(scene.current == Vector2i(2,3))
	assert(scene.token.position == scene.cell_world(scene.current) + Vector3(0,.25,0))
	print("ACT1_GRID_BRIDGE_PASS")
	quit()

