extends Node

const SHARED := "res://scripts/presentation/SharedRigPresentation.gd"
const KAEL := "res://scripts/presentation/KaelRigPresentation.gd"
const ORIGINAL := "res://tests/fixtures/KaelRigPresentation90cd781.gd"
var checks := 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		printerr("FAIL: " + message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	check(ResourceLoader.exists(SHARED), "shared implementation can load configured original-character scenes")
	if failures.is_empty():
		check(FileAccess.get_sha256(ORIGINAL) == "f039d9e7bc3d2fb0306fc335e26a60b590cd9131989219588f4244fc08cfd4f6", "independent original source remains byte-frozen")
		compare_original_kael()
		check_configured_socket()
	await get_tree().process_frame
	print("Shared rig presentation: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func make_anchor() -> Node2D:
	var anchor := Node2D.new()
	anchor.position = Vector2(230, 120)
	anchor.scale = Vector2(1.25, 0.8)
	anchor.rotation = 0.17
	add_child(anchor)
	return anchor

func compare_original_kael() -> void:
	var anchor := make_anchor()
	var original = load(ORIGINAL).new()
	var current = load(KAEL).new()
	anchor.add_child(original)
	anchor.add_child(current)
	original.set_process(false)
	current.set_process(false)
	check(original.is_available() and current.is_available(), "both implementations use actual frozen imported Kael")
	if not original.is_available() or not current.is_available():
		anchor.free()
		return
	check(current.skin_id == "kael" and current.asset_path == load(ORIGINAL).MODEL_PATH, "compatibility profile keeps original defaults")
	for pixel in [true, false]:
		for quality in [false, true]:
			for rig in [original, current]:
				rig.set_pixel_style(pixel)
				rig.set_high_quality(quality)
			check(current.viewport.size == original.viewport.size and current.viewport.msaa_3d == original.viewport.msaa_3d and current.output.texture_filter == original.output.texture_filter, "render mode equals original")
			check(current.output.transform.is_equal_approx(original.output.transform), "canvas footprint and foot origin equal original")
	for direction in [Vector2i.ZERO, Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		original.face(direction)
		current.face(direction)
		check(current.model.transform.is_equal_approx(original.model.transform), "facing equals original: " + str(direction))
		compare_pose(original, current, "face " + str(direction))
	# Defeat last: the existing irreversible presentation latch must remain intact.
	for phase in ["idle", "anticipation", "contact", "recovery", "cast_anticipation", "cast_release", "cast_recovery", "hit", "walk", "unknown", "defeat"]:
		original.play(phase)
		current.play(phase)
		compare_pose(original, current, phase + " immediate")
		for elapsed in [-0.1, 0.001, 0.1, 0.20, 0.22, 0.24, 0.50, 0.65, 1.0, 10.0]:
			original._process(elapsed)
			current._process(elapsed)
			compare_pose(original, current, "%s +%s" % [phase, elapsed])
	for interruption in ["idle", "hit", "walk", "cast_release"]:
		original.play(interruption)
		current.play(interruption)
		compare_pose(original, current, "defeat refuses " + interruption)
	anchor.free()

func compare_pose(original, current, label: String) -> void:
	check(current.state == original.state and is_equal_approx(current.age, original.age), label + " state and phase age equal original")
	check(current.player.current_animation == original.player.current_animation and is_equal_approx(current.player.current_animation_position, original.player.current_animation_position), label + " authored clip/time equal original")
	check(current.hand_world_position().distance_to(original.hand_world_position()) < 0.0001, label + " synchronous projected socket equals original")
	check(current.cast_socket.global_transform.is_equal_approx(original.cast_socket.global_transform), label + " socket transform equals original")
	for bone in original.skeleton.get_bone_count():
		check(current.skeleton.get_bone_pose(bone).is_equal_approx(original.skeleton.get_bone_pose(bone)), "%s bone %s equals original" % [label, original.skeleton.get_bone_name(bone)])

func check_configured_socket() -> void:
	# A real imported scene with a renamed socket proves configuration is actually used.
	var scene := (load(load(KAEL).MODEL_PATH) as PackedScene).instantiate()
	scene.find_child("Kael_v2_cast_socket", true, false).name = "Shared_test_cast_socket"
	var packed := PackedScene.new()
	var path := "user://shared-renamed-socket-test.tscn"
	check(packed.pack(scene) == OK and ResourceSaver.save(packed, path) == OK, "renamed real scene packs")
	scene.free()
	var configured = load(SHARED).new()
	configured.asset_path = path
	configured.cast_socket_name = "Shared_test_cast_socket"
	add_child(configured)
	configured.set_process(false)
	check(configured.is_available(), "configured socket accepts non-Kael scene contract")
	if configured.is_available():
		configured.play("cast_release")
		check(is_equal_approx(configured.player.current_animation_position, 0.875), "configured scene retains exact release sample")
		check(configured.cast_socket.name == "Shared_test_cast_socket" and configured.hand_world_position().is_finite(), "configured origin uses actual renamed socket")
	configured.free()
	var wrong = load(SHARED).new()
	wrong.asset_path = path
	wrong.cast_socket_name = "Kael_v2_cast_socket"
	add_child(wrong)
	check(not wrong.is_available(), "wrong socket profile refuses replacement instead of guessing")
	wrong.free()
	DirAccess.remove_absolute(path)
