## Real adapter contracts. --configuration-only uses labeled metadata unit fixtures;
## the default run requires the actual exported painterly asset (never a placeholder).
extends Node

const ADAPTER := preload("res://scripts/presentation/ZaneImpactRigPresentation.gd")
const IMPACT := "res://assets/3d/characters/zane_impact_v1/zane_impact_v1.glb"
const CANDIDATE := "res://assets/3d/characters/zane_painterly_v1/zane_painterly_v1.glb"
const IMPACT_METADATA := "res://assets/3d/characters/zane_impact_v1/presentation.json"
const CANDIDATE_METADATA := "res://assets/3d/characters/zane_painterly_v1/presentation.json"
const MOTION_SHA := "669244b98a1ba99dde3996b3b4834fb142081fe5d1661e5f2be5e748529e4a90"
const CLIPS := ["idle", "slash", "thrust", "heavy", "cast", "hit", "recovery", "walk", "defeat"]
var checks := 0
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--fallback="):
			await check_fallback_probe(argument.trim_prefix("--fallback="))
			print("Painterly fallback: %d checks, %d failures" % [checks, failures.size()])
			get_tree().quit(0 if failures.is_empty() else 1)
			return
	if "--metadata-probe" in OS.get_cmdline_user_args():
		check_metadata_unit_fixtures()
		print("Painterly metadata unit fixtures: %d checks, %d failures" % [checks, failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1)
		return
	var rig = ADAPTER.new()
	check(rig.has_method("configure_profile"), "exact existing adapter supports explicit pre-tree profiles")
	rig.free()
	if failures.is_empty():
		check_configuration()
		var output: Array = []
		var code := OS.execute(OS.get_executable_path(), PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "res://tests/test_zane_painterly_rig.tscn", "--", "--metadata-probe"]), output, true)
		var captured := "\n".join(output)
		check(code == 0 and captured.contains("162 checks, 0 failures"), "candidate metadata unit fixtures reject malformed fields/provenance")
		check(not captured.contains("ERROR:"), "malformed candidate metadata emits no engine/script errors")
		if code != 0 or captured.contains("ERROR:"): printerr(captured)
	if failures.is_empty() and "--configuration-only" not in OS.get_cmdline_user_args():
		check_actual_candidate()
		check_routing()
		if failures.is_empty(): await check_duel_lifecycle()
	await get_tree().process_frame
	print("Zane painterly rig: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func check_configuration() -> void:
	var rig = ADAPTER.new()
	check(rig.profile_id == "zane_impact_v1" and rig.asset_path == IMPACT and rig.metadata_path == IMPACT_METADATA and rig._pixel_style, "default adapter stays exact impact/pixel")
	for unknown in ["", "zane", "zane_v2", "ZANE_PAINTERLY_V1", "../zane_painterly_v1", CANDIDATE]:
		check(not rig.configure_profile(unknown), "unknown profile rejected: " + unknown)
		check(rig.profile_id == "zane_impact_v1" and rig.asset_path == IMPACT and rig._pixel_style, "rejected profile cannot partially mutate defaults")
	check(rig.configure_profile("zane_painterly_v1"), "approved candidate profile accepted before tree entry")
	check(rig.profile_id == "zane_painterly_v1" and rig.asset_path == CANDIDATE and rig.metadata_path == CANDIDATE_METADATA and not rig._pixel_style, "candidate chooses only approved paths and existing nonpixel mode")
	check(rig.configure_profile("zane_impact_v1") and rig._pixel_style and rig.asset_path == IMPACT and rig.metadata_path == IMPACT_METADATA, "pre-tree impact configuration restores original defaults")
	add_child(rig)
	check(rig.is_available(), "default actual impact still imports")
	check(not rig.configure_profile("zane_painterly_v1") and rig.profile_id == "zane_impact_v1", "tree-entered adapter rejects profile replacement")
	remove_child(rig)
	check(not rig.configure_profile("zane_painterly_v1") and rig.profile_id == "zane_impact_v1", "detaching does not reopen profile configuration")
	rig.free()

func metadata_fixture() -> Dictionary:
	# Unit fixture only: synthetic identity/provenance over actual impact metadata.
	# This is NOT evidence of painterly model availability, rendering or acceptance.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(IMPACT_METADATA))
	data.profile_id = "zane_painterly_v1"
	data.model = CANDIDATE
	data.motion_source = {"profile_id":"zane_impact_v1", "model_sha256":MOTION_SHA, "unchanged_clips":CLIPS}
	if FileAccess.file_exists(CANDIDATE): data.model_sha256 = FileAccess.get_sha256(CANDIDATE)
	return data

func validate_fixture(data: Variant, profile: String = "zane_painterly_v1", changed_path: String = "") -> bool:
	var path := "user://painterly-metadata-unit-fixture.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var rig = ADAPTER.new()
	rig.configure_profile(profile)
	rig.metadata_path = path
	if not changed_path.is_empty(): rig.asset_path = changed_path
	var valid: bool = rig._validate_metadata()
	rig.free()
	DirAccess.remove_absolute(path)
	return valid

func check_metadata_unit_fixtures() -> void:
	var valid := metadata_fixture()
	check(validate_fixture(valid), "labeled candidate metadata unit fixture accepts inherited schema and provenance")
	check(not validate_fixture(valid, "zane_impact_v1"), "candidate metadata cannot self-select on default impact adapter")
	var spoofed := valid.duplicate(true)
	spoofed.model = IMPACT
	spoofed.model_sha256 = MOTION_SHA
	check(not validate_fixture(spoofed, "zane_painterly_v1", IMPACT), "candidate config rejects model-path substitution even with matching metadata/hash")
	for field in ["schema_version", "profile_id", "model", "baseline_sha256", "authoring_fps", "root_motion", "forward_axis", "cast_socket", "changed_clips", "unchanged_clips", "runtime", "source_markers", "marker_frames", "gait_calibration", "clip_durations", "model_sha256", "compatibility_report_sha256", "walk_contacts", "motion_source"]:
		for wrong in [null, true, 999, 0.333, "wrong", [], {}]:
			var malformed := valid.duplicate(true)
			malformed[field] = wrong
			check(not validate_fixture(malformed), "malformed candidate field rejected without exception: " + field + " / " + str(wrong))
	for field in ["profile_id", "model_sha256", "unchanged_clips"]:
		for wrong in [null, true, 999, 0.333, "wrong", [], {}]:
			var malformed := valid.duplicate(true)
			malformed.motion_source[field] = wrong
			check(not validate_fixture(malformed), "malformed nested motion provenance rejected: " + field + " / " + str(wrong))
	for field in ["profile_id", "model_sha256", "unchanged_clips"]:
		var malformed := valid.duplicate(true)
		malformed.motion_source.erase(field)
		check(not validate_fixture(malformed), "missing motion provenance rejected: " + field)
	var forged := valid.duplicate(true)
	forged.motion_source.model_sha256 = "a".repeat(64)
	check(not validate_fixture(forged), "different but well-formed source digest rejects")
	forged = valid.duplicate(true)
	forged.motion_source.unchanged_clips = ["walk", "slash", "cast"]
	check(not validate_fixture(forged), "all nine inherited clips required, not changed-from-original subset")

func check_actual_candidate() -> void:
	var rig = ADAPTER.new()
	rig.configure_profile("zane_painterly_v1")
	add_child(rig)
	rig.set_process(false)
	check(rig.is_available(), "actual candidate GLB and metadata import (not a unit fixture)")
	if not rig.is_available():
		rig.free()
		return
	check(FileAccess.get_sha256(CANDIDATE) == rig.metadata.model_sha256, "actual candidate bytes match metadata")
	check(rig.skeleton.get_bone_count() == 16 and rig.player.get_animation_list().size() == 9, "actual candidate retains sixteen bones and nine imported clips")
	for socket_name in ["Kael_v2_cast_socket", "Kael_v2_weapon_socket", "Kael_v2_shield_socket"]:
		check(rig.model.find_child(socket_name, true, false) is Node3D, "actual candidate preserves socket " + socket_name)
	var impact = ADAPTER.new()
	add_child(impact)
	impact.set_process(false)
	for bone in 16:
		check(rig.skeleton.get_bone_name(bone) == impact.skeleton.get_bone_name(bone) and rig.skeleton.get_bone_parent(bone) == impact.skeleton.get_bone_parent(bone) and rig.skeleton.get_bone_rest(bone).is_equal_approx(impact.skeleton.get_bone_rest(bone)), "actual candidate inherits imported bone/rest " + str(bone))
	for clip in CLIPS:
		check(is_equal_approx(rig.player.get_animation(clip).length, impact.player.get_animation(clip).length), "actual candidate inherits imported duration " + clip)
		var inherited: Animation = impact.player.get_animation(clip)
		var actual: Animation = rig.player.get_animation(clip)
		check(actual.get_track_count() == inherited.get_track_count(), "candidate imports same animation channel count: " + clip)
		for track in inherited.get_track_count():
			var same := track < actual.get_track_count()
			if same:
				same = actual.track_get_type(track) == inherited.track_get_type(track) and actual.track_get_path(track) == inherited.track_get_path(track) and actual.track_get_key_count(track) == inherited.track_get_key_count(track)
			if same:
				for key in inherited.track_get_key_count(track):
					same = same and is_equal_approx(actual.track_get_key_time(track,key), inherited.track_get_key_time(track,key)) and actual.track_get_key_value(track,key) == inherited.track_get_key_value(track,key)
			check(same, "candidate imports unchanged target/times/values: %s channel %d" % [clip,track])
	check(is_equal_approx(rad_to_deg(rig.camera.rotation.x), -30) and is_equal_approx(rad_to_deg(rig.camera.rotation.y), 45), "candidate keeps exact orthographic pitch30/yaw45")
	impact.free()
	var textured := 0
	var colored := 0
	for mesh_instance in rig.model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh_instance.mesh.get_surface_count():
			var material = mesh_instance.get_active_material(surface)
			check(material is BaseMaterial3D, "candidate imports Compatibility-friendly standard material")
			if not material is BaseMaterial3D: continue
			if material.albedo_texture != null:
				textured += 1
				check(material.albedo_texture.get_width() > 0 and material.albedo_texture.get_height() > 0, "candidate atlas exists on actual imported albedo material")
			var arrays: Array = mesh_instance.mesh.surface_get_arrays(surface)
			if arrays[Mesh.ARRAY_COLOR] != null and arrays[Mesh.ARRAY_COLOR].size() > 0:
				colored += 1
				check(material.vertex_color_use_as_albedo, "imported authored vertex colors participate in albedo")
	check(textured > 0 and colored > 0, "actual candidate has both imported texture and vertex-color surfaces")
	print("Actual painterly import: %d textured surfaces, %d vertex-color surfaces" % [textured,colored])
	for high in [false, true, false]:
		rig.set_high_quality(high)
		var resolution := 384 if high else 192
		check(rig.viewport.size == Vector2i(resolution, resolution) and rig.output.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "painterly uses existing clean Standard/High resolution")
		check(rig.viewport.msaa_3d == (Viewport.MSAA_4X if high else Viewport.MSAA_DISABLED), "painterly retains existing quality MSAA")
		check((rig.output.scale * Vector2(rig.viewport.size)).distance_to(Vector2.ONE * 138.24) < 0.001 and is_equal_approx(rig.camera.size, 3.2), "quality never changes display footprint or camera framing")
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		rig.face(direction)
		check((rig.model.global_basis * Vector3.BACK).normalized().dot(Vector3(direction.x, 0, direction.y)) > 0.999, "candidate preserves cardinal facing")
		check(rig.output.to_global(rig.camera.unproject_position(Vector3.ZERO)).distance_to(rig.global_position) < 0.001, "candidate foot projection preserves actor anchor")
		rig.begin_walk(direction, 100)
		var feet_before := projected_feet(rig)
		rig.advance_walk(rig.walk_step_px, 0.2)
		var feet_after := projected_feet(rig)
		var measured := (feet_before[0].distance_to(feet_after[0]) + feet_before[1].distance_to(feet_after[1])) / 2.0
		check(absf(measured - rig.walk_step_px) < 0.001, "candidate metadata gait ruler matches actual imported projected stance excursion")
		rig.end_walk(true)
		rig.play("cast_anticipation")
		rig._process(0.20)
		rig.play("cast_release")
		check(is_equal_approx(rig.player.current_animation_position, 0.875), "candidate cast release samples inherited exact time")
		check(rig.hand_world_position().distance_to(rig.output.to_global(rig.camera.unproject_position(rig.cast_socket.global_position))) < 0.001, "candidate cast origin is synchronous actual imported socket")
	rig.free()

func projected_feet(rig) -> Array[Vector2]:
	var feet: Array[Vector2] = []
	for bone_name in ["foot.L", "foot.R"]:
		var bone: int = rig.skeleton.find_bone(bone_name)
		var point: Vector3 = rig.skeleton.to_global(rig.skeleton.get_bone_global_pose(bone).origin)
		feet.append(rig.output.to_global(rig.camera.unproject_position(point)))
	return feet

func make_unit() -> Unit:
	var unit := preload("res://scenes/Unit.tscn").instantiate() as Unit
	var data := UnitData.new()
	data.id = "zane"
	data.display_name = "Zane"
	data.base_stats = UnitStats.new()
	data.base_stats.hp = 320
	data.sprite_sheet = AssetRegistry.load_first_texture(AssetRegistry.get_character_candidates("zane"))
	unit.unit_data = data
	add_child(unit)
	return unit

func check_routing() -> void:
	var previous: Dictionary = GameState.practice_session.duplicate(true)
	var baseline: Dictionary = GameState.serialize_state().duplicate(true)
	for mode in ["", "practice", "zane_showcase", "zane_duel"]:
		GameState.practice_session = {"rig3d":true, "mode":mode, "zane_showcase":mode == "zane_showcase"}
		var unit := make_unit()
		var expected := "zane_painterly_v1" if mode == "zane_duel" else "zane_impact_v1"
		check(unit.has_zane_impact_presentation() and unit._rig3d.profile_id == expected, "only existing duel mode selects painterly; same action adapter identity: " + mode)
		if is_instance_valid(unit._rig3d):
			check(unit._rig3d._pixel_style == (mode != "zane_duel"), "fresh route keeps its own pixel/clean default: " + mode)
		unit.free()
	check(GameState.serialize_state() == baseline, "profile routing never mutates canonical state")
	GameState.practice_session = previous

func check_fallback_probe(expected: String) -> void:
	var damaged_import: PackedScene
	if "--broken-import" in OS.get_cmdline_user_args():
		# Unit fixture: damage an instance of the REAL imported candidate, not GLB bytes.
		# This reaches cleanup after SharedRig has already allocated a viewport/model.
		var source := (load(CANDIDATE) as PackedScene).instantiate()
		source.find_child("Kael_v2_cast_socket", true, false).free()
		damaged_import = PackedScene.new()
		check(damaged_import.pack(source) == OK, "damaged actual-import fixture packs")
		source.free()
		damaged_import.take_over_path(CANDIDATE)
	GameState.practice_session = {"rig3d":true, "mode":"zane_duel", "high_quality":true}
	var baseline: Dictionary = GameState.serialize_state().duplicate(true)
	var unit := make_unit()
	for attempt in 3:
		if attempt > 0: unit.enable_3d_prototype()
		if expected == "sprite":
			check(unit._rig3d == null and unit._sprite.visible and unit._sprite.texture != null, "all failures retain actual visible sprite texture")
		else:
			check(is_instance_valid(unit._rig3d) and unit._rig3d.is_available(), "fallback has an actual available imported rig")
			if not is_instance_valid(unit._rig3d): break
			var path := IMPACT if expected == "impact" else "res://assets/3d/characters/zane_v2/zane_v2.glb"
			check(unit._rig3d.asset_path == path, "ordered fallback selects " + expected)
			check(unit._rig3d._pixel_style and unit._rig3d.viewport.size == Vector2i(160,160) and unit._rig3d.output.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "fresh fallback retains original pixel defaults, not candidate clean style")
			check(unit.has_zane_impact_presentation() == (expected == "impact"), "fallback preserves exact appropriate action-controller identity")
			check(not unit._sprite.visible, "only a successful imported fallback hides sprite")
		var attached := 0
		for child in unit.get_children():
			if child.get_script() != null and child.get_script().resource_path in ["res://scripts/presentation/ZaneImpactRigPresentation.gd", "res://scripts/presentation/ZaneRigPresentation.gd"]: attached += 1
		check(attached == (0 if expected == "sprite" else 1), "failed adapters detach before replacement")
		await get_tree().process_frame
		check(unit.find_children("*", "SubViewport", true, false).size() == (0 if expected == "sprite" else 1), "no failed viewport survives replacement")
		unit.disable_3d_prototype()
		await get_tree().process_frame
		check(unit._rig3d == null and unit._sprite.visible and unit.find_children("*", "SubViewport", true, false).is_empty(), "fallback toggle fully cleans up and restores visible sprite")
	check(GameState.serialize_state() == baseline, "fallback never changes canonical resources/progression")
	unit.free()
	GameState.practice_session.clear()
	await get_tree().process_frame

func check_duel_lifecycle() -> void:
	GameState._init_defaults()
	GameState.practice_session.clear()
	GameState.active_run = null
	var baseline: Dictionary = GameState.serialize_state().duplicate(true)
	GameState.save()
	var canonical := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	check(GameState.begin_zane_duel_practice(), "candidate uses existing duel admission")
	# Match the existing StartScreen entry; admission itself intentionally sets no visual flags.
	GameState.practice_session["rig3d"] = true
	GameState.practice_session["terrain3d"] = true
	var battle := preload("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	var actor: Unit = battle.battle_manager.units.zane
	check(actor.has_zane_impact_presentation(), "real duel initializes an available action-capable imported rig")
	if not actor.has_zane_impact_presentation():
		battle.free()
		GameState.leave_practice()
		return
	check(actor._rig3d.profile_id == "zane_painterly_v1" and is_equal_approx(actor.scale.x, 1.35), "real duel actor uses candidate and original HP-derived Unit scale")
	var before := [actor.hp, actor.mp, actor.ct, actor.grid_pos, actor.position]
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		actor.set_facing({Vector2i.UP:"N", Vector2i.RIGHT:"E", Vector2i.DOWN:"S", Vector2i.LEFT:"W"}[direction])
		actor.begin_walk_presentation(direction, 135)
		var step: float = actor._rig3d.walk_step_px
		check(is_equal_approx(step, float(actor._rig3d.metadata.gait_calibration.step_canvas_px[actor.facing]) * 1.35), "candidate gait uses exactly one Unit-scale ruler")
		battle._battle_camera.zoom = Vector2.ONE * 0.75
		battle.scale = Vector2.ONE * 1.17
		actor.begin_walk_presentation(direction, 135)
		check(is_equal_approx(step, actor._rig3d.walk_step_px), "parent transform/Camera2D zoom never double-scale candidate gait")
		actor.advance_walk_presentation(step, 0.2)
		check(is_equal_approx(actor._rig3d.player.current_animation_position, 0.5), "one actual candidate gait step reaches inherited half-cycle plant")
		actor.end_walk_presentation(true)
	check(before == [actor.hp, actor.mp, actor.ct, actor.grid_pos, actor.position], "candidate presentation leaves resources, CT, grid and anchor untouched")
	battle.scale = Vector2.ONE
	battle._battle_camera.zoom = Vector2.ONE
	var panel = battle.comparison_panel
	for i in 300:
		if panel.can_switch(): break
		await get_tree().process_frame
	check(panel.switch_quality(), "existing quality control accepts candidate")
	check(actor._rig3d.viewport.size == Vector2i(384,384) and not actor._rig3d._pixel_style, "real existing High control retains candidate clean384")
	check(panel.switch_mode() and actor._rig3d == null and actor._sprite.visible, "real existing sprite toggle restores original visual")
	await get_tree().process_frame
	check(panel.switch_mode() and actor._rig3d.profile_id == "zane_painterly_v1" and actor._rig3d.viewport.size == Vector2i(384,384), "real existing Show3D reselects candidate with session High")
	check(panel.switch_reduced_motion() and bool(GameState.practice_session.get("reduced_zane_motion")), "existing reduced-motion flag remains session-only")
	battle.free()
	await get_tree().process_frame
	check(GameState.finish_practice(false) and GameState.retry_practice(), "existing terminal/replay API still admits original checkpoint")
	battle = preload("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	actor = battle.battle_manager.units.zane
	check(actor._rig3d.profile_id == "zane_painterly_v1" and actor._rig3d.viewport.size == Vector2i(384,384) and bool(GameState.practice_session.get("reduced_zane_motion")), "replay reconstructs candidate and preserves session quality/motion")
	battle.free()
	await get_tree().process_frame
	check(GameState.leave_practice() and GameState.practice_session.is_empty() and GameState.serialize_state() == baseline, "exit restores canonical state and clears candidate session")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == canonical, "candidate toggles/replay/exit never modify canonical save bytes")
	await get_tree().create_timer(0.25).timeout
