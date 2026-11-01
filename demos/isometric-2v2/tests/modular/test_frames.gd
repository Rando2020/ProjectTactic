extends SceneTree
func _init() -> void:
	var path := "res://scripts/presentation/ModularSpellFrames.gd"
	if not ResourceLoader.exists(path):
		push_error("Missing modular frame player")
		quit(1)
		return
	var frames = load(path).new()
	frames.configure("thunderstrike", "casting")
	assert(frames.available())
	assert(frames.frame_count() == 4)
	frames.show_progress(1.0)
	assert(frames.frame_index == 3)
	for ability in ["thunderstrike","void_pulse","dark_breath","shadow_mend"]:
		for stage in ["formation", "action", "collision", "dissipation"]:
			frames.configure(ability,stage)
			assert(frames.frame_count() == 3)
			frames.show_progress(1.0)
			assert(frames.frame_index == 2)
			assert(frames.texture != null)
	frames.free()
	print("Modular frame stages: PASS")
	quit(0)
