extends Node

var failures: Array[String] = []
var checks := 0
const ADAPTER := "res://scripts/presentation/KaelRigPresentation.gd"

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		printerr("FAIL: " + message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	check(ResourceLoader.exists(ADAPTER), "Kael imported presentation adapter exists")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	check(FileAccess.get_sha256("res://assets/3d/characters/kael_v2/kael_v2.glb") == "c82138050f2c0e23899ed4aa10b67802724cfdc94c61a49f9d31175004e76117", "GLB matches frozen independently verified asset checksum")
	var script = load(ADAPTER)
	var parent := Node2D.new()
	parent.position = Vector2(230, 120)
	parent.scale = Vector2(1.25, 1.25)
	get_tree().root.add_child(parent)
	var rig = script.new()
	parent.add_child(rig)
	check(rig.is_available(), "real GLB loads required clips and cast socket")
	if not rig.is_available():
		parent.free()
		get_tree().quit(1)
		return
	check(rig.has_method("set_pixel_style") and rig.has_method("set_high_quality"), "pixel and quality controls exist independently")
	if not failures.is_empty():
		parent.free()
		get_tree().quit(1)
		return
	rig.set_pixel_style(true)
	rig.set_high_quality(false)
	var pixel_size: Vector2i = rig.viewport.size
	check(pixel_size == Vector2i(160, 160), "controlled 160px source profile")
	check(rig.output.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "pixel profile uses nearest output")
	rig.set_high_quality(true)
	check(rig.viewport.size == pixel_size, "high quality does not redefine pixel grid")
	check((rig.output.scale * Vector2(rig.viewport.size)).distance_to(Vector2.ONE * 138.24) < 0.001, "quality preserves canvas footprint")
	rig.set_pixel_style(false)
	check(rig.viewport.size == Vector2i(384, 384), "clean high quality doubles source resolution")
	rig.set_high_quality(false)
	check(rig.viewport.size == Vector2i(192, 192), "clean standard retains prior viewport footprint")
	rig.set_pixel_style(true)
	rig.set_process(false)
	check(rig.skeleton.get_bone_count() == 16, "one tested 16-bone rig")
	for clip in ["idle", "slash", "thrust", "heavy", "cast", "hit", "recovery"]:
		check(rig.player.has_animation(clip), "required clip: " + clip)
	var durations := {"idle": 35.0 / 24.0, "slash": 35.0 / 24.0, "thrust": 35.0 / 24.0, "heavy": 41.0 / 24.0, "cast": 41.0 / 24.0, "hit": 29.0 / 24.0, "recovery": 29.0 / 24.0, "walk": 1.0, "defeat": 2.0}
	for clip in durations:
		check(rig.player.has_animation(clip) and is_equal_approx(rig.player.get_animation(clip).length, durations[clip]), "verified authored duration retained: " + clip)
	rig.play("anticipation")
	rig._process(0.20)
	check(rig.state == "anticipation", "presentation never grants its own contact")
	check(rig.player.current_animation_position < 15.0 / 24.0, "windup holds before authored contact")
	rig.play("contact")
	check(is_equal_approx(rig.player.current_animation_position, 15.0 / 24.0), "contact seeks exact authored impact")
	rig.play("recovery")
	rig._process(0.22)
	check(is_equal_approx(rig.player.current_animation_position, 35.0 / 24.0), "recovery samples attack tail")
	rig.play("anticipation")
	rig._process(0.1)
	rig.play("idle")
	rig._process(0.5)
	check(rig.state == "idle" and rig.player.current_animation == "idle", "cancel reset cannot restart contact")
	rig.play("cast_anticipation")
	rig._process(0.20)
	rig.play("cast_release")
	check(is_equal_approx(rig.player.current_animation_position, 21.0 / 24.0), "cast release seeks authored frame immediately")
	var origin: Vector2 = rig.hand_world_position()
	var expected: Vector2 = rig.output.to_global(rig.camera.unproject_position(rig.cast_socket.global_position))
	check(origin.distance_to(expected) < 0.001, "socket returns canvas-global coordinates including parent scale")
	var before: Transform3D = rig.cast_socket.global_transform
	rig.play("idle")
	check(not before.is_equal_approx(rig.cast_socket.global_transform), "socket follows seek without waiting a frame")
	for direction in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		rig.face(direction)
		var forward: Vector3 = rig.model.global_basis * Vector3.BACK
		var desired := Vector3(direction.x, 0, direction.y)
		check(forward.normalized().dot(desired) > 0.999, "model +Z front faces tile " + str(direction))
		var feet: Vector2 = rig.output.to_global(rig.camera.unproject_position(Vector3.ZERO))
		check(feet.distance_to(parent.global_position) < 0.001, "projected feet stay on Unit anchor")
	check(rig.player.has_animation("walk") and rig.player.has_animation("defeat"), "frozen nine-clip asset supplies authored walk and defeat")
	var idle_poses: Array[Transform3D] = []
	for bone in rig.skeleton.get_bone_count():
		idle_poses.append(rig.skeleton.get_bone_pose(bone))
	rig.play("walk")
	check(rig.player.current_animation == "walk", "movement selects authored walk, not idle fallback")
	var walk_start: Transform3D = rig.skeleton.get_bone_pose(rig.skeleton.find_bone("thigh.R"))
	rig._process(0.125)
	check(not rig.skeleton.get_bone_pose(rig.skeleton.find_bone("thigh.R")).is_equal_approx(walk_start), "authored walk actually moves legs")
	check(rig.skeleton.get_bone_pose_position(rig.skeleton.find_bone("root")).is_zero_approx() and rig.position.is_zero_approx() and rig.model.position.is_zero_approx(), "walking never consumes root motion or moves tile anchor")
	rig._process(0.375)
	check(rig.skeleton.get_bone_pose(rig.skeleton.find_bone("thigh.R")).is_equal_approx(walk_start), "one walk loop fits existing half-second visual move")
	rig.play("idle")
	for bone in rig.skeleton.get_bone_count():
		check(rig.skeleton.get_bone_pose(bone).is_equal_approx(idle_poses[bone]), "walk to idle resets bone " + rig.skeleton.get_bone_name(bone))
	rig.play("defeat")
	check(rig.player.current_animation == "defeat", "defeat selects authored collapse")
	rig._process(0.65)
	check(is_equal_approx(rig.player.current_animation_position, 2.0), "collapse reaches final pose before Unit fade/removal completes")
	var dead_pose: Transform3D = rig.skeleton.get_bone_pose(rig.skeleton.find_bone("pelvis"))
	check(not dead_pose.is_equal_approx(idle_poses[rig.skeleton.find_bone("pelvis")]), "defeated pose is not standing idle")
	rig.play("idle")
	rig.play("hit")
	rig._process(10.0)
	check(rig.state == "defeat" and rig.skeleton.get_bone_pose(rig.skeleton.find_bone("pelvis")).is_equal_approx(dead_pose), "defeat clamps endpoint and cannot be interrupted")
	parent.free()
	var missing = script.new()
	missing.asset_path = "res://assets/does-not-exist.glb"
	add_child(missing)
	check(not missing.is_available(), "missing asset refuses replacement")
	check(missing.hand_world_position().is_finite(), "unavailable adapter offers finite origin fallback")
	missing.free()
	var invalid_scene := PackedScene.new()
	var empty := Node3D.new()
	invalid_scene.pack(empty)
	empty.free()
	ResourceSaver.save(invalid_scene, "user://kael-invalid-test.tscn")
	var invalid = script.new()
	invalid.asset_path = "user://kael-invalid-test.tscn"
	add_child(invalid)
	check(not invalid.is_available(), "scene lacking skeleton/clips/socket refuses replacement")
	invalid.free()
	DirAccess.remove_absolute("user://kael-invalid-test.tscn")
	await get_tree().process_frame
	for variant in ["optional", "required", "socket"]:
		var path: String = "user://kael-" + variant + "-test.tscn"
		write_asset_variant(path, ["walk", "defeat"] if variant == "optional" else (["slash"] if variant == "required" else []), variant == "socket")
		var changed = script.new()
		changed.asset_path = path
		add_child(changed)
		if variant == "optional":
			check(changed.is_available(), "original seven-clip variant remains compatible")
			changed.play("walk")
			check(changed.player.current_animation == "idle", "missing optional walk uses honest idle fallback")
			changed.play("defeat")
			changed._process(10)
			check(changed.state == "defeat" and changed.player.current_animation == "idle", "missing optional defeat retains Unit fade-only fallback")
		else:
			check(not changed.is_available(), "missing " + variant + " contract refuses replacement")
		changed.free()
		DirAccess.remove_absolute(path)
	await check_unit_integration()
	print("Kael presentation: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func make_unit(id: String) -> Unit:
	var unit := preload("res://scenes/Unit.tscn").instantiate() as Unit
	unit.unit_id = id
	unit.hp = 100
	unit.mp = 25
	unit.grid_pos = Vector2i(2, 3)
	unit._sprite = Sprite2D.new()
	unit.add_child(unit._sprite)
	add_child(unit)
	return unit

func check_unit_integration() -> void:
	var gs := get_node("/root/GameState")
	var baseline: Dictionary = gs.serialize_state().duplicate(true)
	var previous: Dictionary = gs.practice_session.duplicate(true)
	gs.practice_session = {"rig3d": true, "baseline": baseline}
	var unit := make_unit("kael")
	check(is_instance_valid(unit._rig3d) and unit._rig3d.get_script().resource_path == ADAPTER, "existing practice flag selects imported Kael only")
	if unit._rig3d.get_script().resource_path != ADAPTER:
		unit.free()
		gs.practice_session = previous
		return
	check(not unit._sprite.visible, "validated replacement hides original sprite")
	var position_before := unit.position
	var grid_before := unit.grid_pos
	var lifecycle = preload("res://scripts/battle/ActionLifecycle.gd").new()
	var ticket: int = lifecycle.begin(unit)
	unit.set_melee_pose("anticipation")
	unit._rig3d._process(1)
	check(lifecycle.phase == "anticipation", "animation alone does not advance actual lifecycle")
	check(lifecycle.contact(ticket), "real lifecycle permits contact")
	unit.set_melee_pose("contact")
	check(lifecycle.recover(ticket), "real lifecycle enters recovery")
	check(unit._rig3d.state == "recovery", "Unit recovery hook reaches imported facade")
	lifecycle.finish(ticket)
	check(unit._rig3d.state == "idle", "finish returns imported facade to idle")
	ticket = lifecycle.begin(unit)
	unit.set_cast_pose("anticipation")
	lifecycle.cancel()
	check(not lifecycle.contact(ticket), "cancel invalidates late contact")
	check(unit._rig3d.state == "idle", "cancel resets imported cast state")
	var effects := get_node("/root/VFX") as VFXManager
	var observed_origins: Array[float] = []
	var observe := func(node: Node) -> void:
		if node is Polygon2D:
			observed_origins.append(node.global_position.distance_to(unit.cast_origin_world()))
	effects.child_entered_tree.connect(observe)
	ticket = lifecycle.begin(unit)
	await effects.present_action(unit, Vector2i(3, 3), "spell", func() -> bool: return lifecycle.presentation_valid(ticket))
	check(observed_origins.size() == 1 and observed_origins[0] < 0.001, "real VFX projectile starts at imported animated cast socket")
	check(lifecycle.phase == "anticipation" and unit._rig3d.state == "cast_release", "VFX completion still requires authoritative contact permit")
	check(lifecycle.contact(ticket), "projectile travel ends before permitted contact")
	lifecycle.recover(ticket)
	check(unit._rig3d.state == "cast_recovery", "real lifecycle uses imported cast recovery")
	lifecycle.finish(ticket)
	ticket = lifecycle.begin(unit)
	get_tree().create_timer(0.25).timeout.connect(lifecycle.cancel)
	await effects.present_action(unit, Vector2i(3, 3), "spell", func() -> bool: return lifecycle.presentation_valid(ticket))
	await get_tree().process_frame
	check(not lifecycle.contact(ticket) and unit._rig3d.state == "idle", "mid-projectile cancellation cannot resurrect cast contact")
	check(effects.get_child_count() == 0, "cancelled cast projectile is cleaned up")
	effects.child_entered_tree.disconnect(observe)
	check(unit.hp == 100 and unit.mp == 25 and unit.grid_pos == grid_before and unit.position == position_before, "presentation leaves hp/mp/tile and Unit anchor untouched")
	for cycle in range(5):
		var old_rig := unit._rig3d
		unit.disable_3d_prototype()
		check(unit._rig3d == null and not old_rig.is_inside_tree() and unit._sprite.visible, "disable detaches viewport synchronously and restores sprite")
		unit.enable_3d_prototype()
		check(unit._rig3d.get_script().resource_path == ADAPTER, "re-enable selects Kael adapter")
		await get_tree().process_frame
		check(not is_instance_valid(old_rig), "old viewport owner is freed")
	unit.free()
	var other := make_unit("zane")
	check(other._rig3d.get_script().resource_path.ends_with("Humanoid3D.gd"), "other supported characters keep their existing rig")
	other.free()
	# Substitute a real invalid PackedScene in the resource cache, not a mock adapter.
	# This exercises the Unit factory failure branch without renaming production files.
	var model_path: String = load(ADAPTER).MODEL_PATH
	var original := load(model_path) as PackedScene
	var broken := PackedScene.new()
	var empty := Node3D.new()
	broken.pack(empty)
	empty.free()
	broken.take_over_path(model_path)
	var fallback := make_unit("kael")
	check(fallback._rig3d == null and fallback._sprite.visible, "invalid imported scene preserves visible Unit sprite")
	fallback.free()
	original.take_over_path(model_path)
	check(gs.serialize_state() == baseline, "practice presentation does not alter serialized gameplay")
	gs.practice_session = previous
	await get_tree().process_frame

func write_asset_variant(path: String, removed_clips: Array, remove_socket: bool) -> void:
	var scene := (load(load(ADAPTER).MODEL_PATH) as PackedScene).instantiate()
	var animator := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var library := animator.get_animation_library("").duplicate() as AnimationLibrary
	for clip in removed_clips:
		library.remove_animation(clip)
	animator.remove_animation_library("")
	animator.add_animation_library("", library)
	if remove_socket:
		scene.find_child("Kael_v2_cast_socket", true, false).free()
	var packed := PackedScene.new()
	check(packed.pack(scene) == OK and ResourceSaver.save(packed, path) == OK, "real variant scene packs: " + path)
	scene.free()
