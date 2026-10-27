extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var packed := load("res://godot-preview/preview.tscn") as PackedScene
	assert(packed != null)
	var preview := packed.instantiate()
	root.add_child(preview)
	await process_frame
	assert(preview.player != null)
	var clips: Array = []
	for clip in ["idle", "walk", "attack"]:
		assert(preview.player.has_animation(clip))
		preview.player.play(clip)
		preview.player.advance(0.5)
		clips.append(clip)
	preview.move_cell(Vector2i(1, 0))
	await create_timer(1.2).timeout
	assert(preview.cell == Vector2i(3, 2))
	assert(preview.actor.position.is_equal_approx(Vector3(1, 0, -1)))
	assert(is_equal_approx(preview.actor.rotation.y, PI / 2.0))
	assert(not preview.busy)
	preview.move_cell(Vector2i(1, 0))
	assert(preview.cell == Vector2i(3, 2))
	preview.attack()
	await create_timer(1.2).timeout
	assert(not preview.busy)
	print("ASSET_PREVIEW_PASS: clips=", clips, "; move=2m; boundary=blocked; attack=returns_idle")
	quit(0)
