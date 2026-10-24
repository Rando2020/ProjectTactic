extends Node

const ADAPTER := "res://scripts/presentation/ZaneRigPresentation.gd"
const ASSET := "res://assets/3d/characters/zane_v2/zane_v2.glb"
# Builder-authoritative frozen original, independently hash-verified before copying.
const FROZEN_SHA256 := "9f0ce05497200bcd20ca9b37ca502f008862744887b8fbdf56ec82a147eb66c5"
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
	check(ResourceLoader.exists(ADAPTER), "Zane profile loads the original shared-rig scene")
	if failures.is_empty():
		check(FileAccess.get_sha256(ASSET) == FROZEN_SHA256, "Zane bytes match authoritative frozen original")
		check_real_scene()
		await check_unit_integration()
	await get_tree().process_frame
	print("Zane presentation: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func check_real_scene() -> void:
	var anchor := Node2D.new()
	anchor.position = Vector2(230, 120)
	anchor.scale = Vector2(1.25, 1.25)
	add_child(anchor)
	var rig = load(ADAPTER).new()
	anchor.add_child(rig)
	rig.set_process(false)
	check(rig.is_available(), "real Zane import satisfies clips and socket contract")
	if not rig.is_available():
		anchor.free()
		return
	check(rig.skin_id == "zane" and rig.asset_path == ASSET, "profile keeps Zane identity and original source")
	check(rig.skeleton.get_bone_count() == 16, "Zane retains shared sixteen-bone skeleton")
	var durations := {"idle": 35.0 / 24.0, "slash": 35.0 / 24.0, "thrust": 35.0 / 24.0, "heavy": 41.0 / 24.0, "cast": 41.0 / 24.0, "hit": 29.0 / 24.0, "recovery": 29.0 / 24.0, "walk": 1.0, "defeat": 2.0}
	check(rig.player.get_animation_list().size() == 9, "exactly nine original authored clips import")
	for clip in durations:
		check(rig.player.has_animation(clip) and is_equal_approx(rig.player.get_animation(clip).length, durations[clip]), "Zane retains authored duration: " + clip)
	for pixel in [true, false]:
		for quality in [false, true]:
			rig.set_pixel_style(pixel)
			rig.set_high_quality(quality)
			var expected := 160 if pixel else (384 if quality else 192)
			check(rig.viewport.size == Vector2i(expected, expected), "Zane uses shared render resolution")
			check((rig.output.scale * Vector2(rig.viewport.size)).distance_to(Vector2.ONE * 138.24) < 0.001, "Zane preserves existing canvas footprint")
			check(rig.output.texture_filter == (CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR), "Zane uses independent pixel/clean profile")
	for direction in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		rig.face(direction)
		check((rig.model.global_basis * Vector3.BACK).normalized().dot(Vector3(direction.x, 0, direction.y)) > 0.999, "Zane model front follows tile facing")
		check(rig.output.to_global(rig.camera.unproject_position(Vector3.ZERO)).distance_to(anchor.global_position) < 0.001, "Zane projected feet remain Unit anchor")
	rig.play("anticipation")
	rig._process(10)
	check(rig.state == "anticipation" and rig.player.current_animation_position < 0.625, "Zane windup never grants contact")
	rig.play("contact")
	check(is_equal_approx(rig.player.current_animation_position, 0.625), "Zane contact samples exact authored impact")
	rig.play("recovery")
	rig._process(0.22)
	check(is_equal_approx(rig.player.current_animation_position, 35.0 / 24.0), "Zane recovery samples same attack tail")
	rig.play("cast_anticipation")
	rig._process(0.20)
	rig.play("cast_release")
	check(is_equal_approx(rig.player.current_animation_position, 0.875), "Zane cast release seeks authored frame immediately")
	check(rig.cast_socket.name == "Kael_v2_cast_socket", "original shared socket name is respected, not relabeled identity")
	check(rig.hand_world_position().distance_to(rig.output.to_global(rig.camera.unproject_position(rig.cast_socket.global_position))) < 0.001, "Zane origin is canvas-global animated socket under parent scale")
	var release: Transform3D = rig.cast_socket.global_transform
	rig.play("idle")
	check(not release.is_equal_approx(rig.cast_socket.global_transform), "Zane socket updates synchronously without next-frame lag")
	rig.play("cast_recovery")
	rig._process(0.22)
	check(is_equal_approx(rig.player.current_animation_position, 41.0 / 24.0), "Zane cast recovery samples authored tail")
	rig.play("hit")
	rig._process(0.24)
	check(rig.state == "idle", "Zane hit presentation returns idle without gameplay callbacks")
	var idle: Array[Transform3D] = []
	for bone in rig.skeleton.get_bone_count():
		idle.append(rig.skeleton.get_bone_pose(bone))
	rig.play("walk")
	var start: Transform3D = rig.skeleton.get_bone_pose(rig.skeleton.find_bone("thigh.R"))
	rig._process(0.125)
	check(not rig.skeleton.get_bone_pose(rig.skeleton.find_bone("thigh.R")).is_equal_approx(start), "authored Zane walk moves legs")
	check(rig.skeleton.get_bone_pose_position(rig.skeleton.find_bone("root")).is_zero_approx() and rig.position.is_zero_approx() and rig.model.position.is_zero_approx(), "Zane walk consumes no root motion")
	rig._process(0.375)
	check(rig.skeleton.get_bone_pose(rig.skeleton.find_bone("thigh.R")).is_equal_approx(start), "Zane authored gait fits existing half-second move")
	rig.play("idle")
	for bone in rig.skeleton.get_bone_count():
		check(rig.skeleton.get_bone_pose(bone).is_equal_approx(idle[bone]), "Zane walk/idle resets bone " + rig.skeleton.get_bone_name(bone))
	rig.play("defeat")
	rig._process(0.65)
	check(is_equal_approx(rig.player.current_animation_position, 2.0), "Zane collapse finishes before existing Unit removal")
	var dead: Transform3D = rig.skeleton.get_bone_pose(rig.skeleton.find_bone("pelvis"))
	check(not dead.is_equal_approx(idle[rig.skeleton.find_bone("pelvis")]), "Zane defeat is authored collapse, not standing idle")
	rig.play("idle")
	rig.play("hit")
	rig._process(10)
	check(rig.state == "defeat" and rig.skeleton.get_bone_pose(rig.skeleton.find_bone("pelvis")).is_equal_approx(dead), "Zane defeat endpoint stays clamped and cannot be interrupted")
	anchor.free()
	check_asset_variants()

func check_asset_variants() -> void:
	var missing = load(ADAPTER).new()
	missing.asset_path = "res://assets/does-not-exist.glb"
	add_child(missing)
	check(not missing.is_available() and missing.hand_world_position().is_finite(), "missing Zane asset refuses replacement with finite fallback origin")
	missing.free()
	for variant in ["optional", "required", "socket"]:
		var scene := (load(ASSET) as PackedScene).instantiate()
		var animator := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var library := animator.get_animation_library("").duplicate() as AnimationLibrary
		for clip in (["walk", "defeat"] if variant == "optional" else (["slash"] if variant == "required" else [])):
			library.remove_animation(clip)
		animator.remove_animation_library("")
		animator.add_animation_library("", library)
		if variant == "socket":
			scene.find_child("Kael_v2_cast_socket", true, false).free()
		var packed := PackedScene.new()
		var path: String = "user://zane-" + variant + "-test.tscn"
		check(packed.pack(scene) == OK and ResourceSaver.save(packed, path) == OK, "real Zane variant packs: " + variant)
		scene.free()
		var changed = load(ADAPTER).new()
		changed.asset_path = path
		add_child(changed)
		if variant == "optional":
			check(changed.is_available(), "Zane seven-clip variant retains supported fallback")
			changed.play("walk")
			check(changed.player.current_animation == "idle", "missing Zane walk uses honest idle fallback")
			changed.play("defeat")
			changed._process(10)
			check(changed.state == "defeat" and changed.player.current_animation == "idle", "missing Zane defeat retains fade-only fallback")
		else:
			check(not changed.is_available(), "missing Zane " + variant + " contract rejects replacement")
		changed.free()
		DirAccess.remove_absolute(path)

func make_unit(id: String, archetype := "") -> Unit:
	var unit := preload("res://scenes/Unit.tscn").instantiate() as Unit
	unit.unit_id = id
	unit.hp = 100
	unit.mp = 25
	unit.grid_pos = Vector2i(2, 3)
	if not archetype.is_empty():
		unit.set_meta("archetype_id", archetype)
	unit._sprite = Sprite2D.new()
	unit.add_child(unit._sprite)
	add_child(unit)
	return unit

func check_unit_integration() -> void:
	var gs := get_node("/root/GameState")
	var baseline: Dictionary = gs.serialize_state().duplicate(true)
	var previous: Dictionary = gs.practice_session.duplicate(true)
	gs.practice_session = {"rig3d": false, "baseline": baseline}
	for id in ["kael", "mira", "zane", "void_cultist", "lyra"]:
		var sprite_unit := make_unit(id)
		check(sprite_unit._rig3d == null and sprite_unit._sprite.visible, "opt-out retains original sprite: " + id)
		sprite_unit.free()
	gs.practice_session = {"rig3d": true, "baseline": baseline}
	var unit := make_unit("zane")
	check(is_instance_valid(unit._rig3d), "existing practice flag now supports original Zane")
	if not is_instance_valid(unit._rig3d):
		unit.free()
		gs.practice_session = previous
		return
	check(unit._rig3d.get_script().resource_path == ADAPTER and not unit._sprite.visible, "validated Zane profile alone hides original sprite")
	var position_before := unit.position
	var grid_before := unit.grid_pos
	var lifecycle = preload("res://scripts/battle/ActionLifecycle.gd").new()
	var ticket: int = lifecycle.begin(unit)
	unit.set_melee_pose("anticipation")
	unit._rig3d._process(1)
	check(lifecycle.phase == "anticipation", "Zane animation never advances real gameplay lifecycle")
	check(lifecycle.contact(ticket), "only real lifecycle permits Zane contact")
	unit.set_melee_pose("contact")
	check(lifecycle.recover(ticket) and unit._rig3d.state == "recovery", "Unit recovery hook reaches shared Zane facade")
	lifecycle.finish(ticket)
	check(unit._rig3d.state == "idle", "Zane finish returns idle")
	var effects := get_node("/root/VFX") as VFXManager
	var origins: Array[float] = []
	var observe := func(node: Node) -> void:
		if node is Polygon2D:
			origins.append(node.global_position.distance_to(unit.cast_origin_world()))
	effects.child_entered_tree.connect(observe)
	ticket = lifecycle.begin(unit)
	await effects.present_action(unit, Vector2i(3, 3), "spell", func() -> bool: return lifecycle.presentation_valid(ticket))
	check(origins.size() == 1 and origins[0] < 0.001, "actual VFX projectile starts at animated Zane socket")
	check(lifecycle.phase == "anticipation" and unit._rig3d.state == "cast_release", "Zane VFX completion cannot grant authoritative contact")
	check(lifecycle.contact(ticket), "Zane projectile arrives before permitted contact")
	lifecycle.recover(ticket)
	check(unit._rig3d.state == "cast_recovery", "real lifecycle uses Zane cast recovery")
	lifecycle.finish(ticket)
	ticket = lifecycle.begin(unit)
	get_tree().create_timer(0.25).timeout.connect(lifecycle.cancel)
	await effects.present_action(unit, Vector2i(3, 3), "spell", func() -> bool: return lifecycle.presentation_valid(ticket))
	await get_tree().process_frame
	check(not lifecycle.contact(ticket) and unit._rig3d.state == "idle", "canceled Zane projectile cannot resurrect contact")
	check(effects.get_child_count() == 0, "canceled Zane projectile is cleaned up")
	effects.child_entered_tree.disconnect(observe)
	check(unit.hp == 100 and unit.mp == 25 and unit.grid_pos == grid_before and unit.position == position_before, "Zane presentation leaves health/resources/tile/Unit anchor unchanged")
	for cycle in range(5):
		var old_rig := unit._rig3d
		unit.disable_3d_prototype()
		check(unit._rig3d == null and not old_rig.is_inside_tree() and unit._sprite.visible, "disable synchronously detaches Zane viewport and restores sprite")
		unit.enable_3d_prototype()
		check(unit._rig3d.get_script().resource_path == ADAPTER, "re-enable selects Zane profile")
		await get_tree().process_frame
		check(not is_instance_valid(old_rig), "old Zane viewport owner is freed")
	unit.free()
	var alias := make_unit("practice-zane-1", "zane")
	check(alias.supports_3d_presentation() and alias._rig3d.get_script().resource_path == ADAPTER, "archetype alias selects Zane without changing actor identity")
	check(alias.unit_id == "practice-zane-1", "presentation preserves actor id")
	alias.free()
	for entry in [["kael", "KaelRigPresentation.gd"], ["mira", "MiraRigPresentation.gd"], ["void_cultist", "Humanoid3D.gd"]]:
		var other := make_unit(entry[0])
		check(other._rig3d.get_script().resource_path.ends_with(entry[1]), "other existing actor keeps its reviewed presentation: " + entry[0])
		other.free()
	var unsupported := make_unit("lyra")
	check(not unsupported.supports_3d_presentation() and unsupported._rig3d == null and unsupported._sprite.visible, "other unsupported actor remains sprite-backed")
	unsupported.free()
	var original := load(ASSET) as PackedScene
	var broken := PackedScene.new()
	var empty := Node3D.new()
	broken.pack(empty)
	empty.free()
	broken.take_over_path(ASSET)
	var fallback := make_unit("zane")
	check(fallback._rig3d == null and fallback._sprite.visible, "real invalid imported Zane scene retains visible Unit sprite")
	fallback.free()
	original.take_over_path(ASSET)
	check(gs.serialize_state() == baseline, "Zane practice presentation does not change saved gameplay")
	gs.practice_session = previous
