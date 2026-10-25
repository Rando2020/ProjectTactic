extends Node

const ADAPTER := "res://scripts/presentation/ZaneImpactRigPresentation.gd"
const ORIGINAL := "res://scripts/presentation/ZaneRigPresentation.gd"
const AUDIO := "res://scripts/presentation/ZaneImpactAudio.gd"
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
	if "--metadata-probe" in OS.get_cmdline_user_args():
		metadata_probe()
		return
	check(ResourceLoader.exists(ADAPTER), "new validated distance-driven adapter exists")
	check(ResourceLoader.exists(AUDIO), "manifest audio helper exists")
	if failures.is_empty():
		check_metadata_errors()
		check_arbitrary_facing()
		check_invalid_metadata()
		check_audio()
		await check_variant()
		if failures.is_empty(): check_actor_scale()
	await get_tree().create_timer(0.25).timeout
	print("Zane impact rig: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func check_variant() -> void:
	var anchor := Node2D.new()
	anchor.position = Vector2(217, 94)
	anchor.scale = Vector2(1.23, 0.91)
	anchor.rotation = 0.13
	add_child(anchor)
	var rig = load(ADAPTER).new()
	anchor.add_child(rig)
	rig.set_process(false)
	check(rig.is_available(), "final exported GLB and metadata validate")
	if not rig.is_available():
		anchor.free()
		return
	check(rig.profile_id == "zane_impact_v1", "variant exposes only approved identity")
	var cues: Array[String] = []
	rig.cue_started.connect(func(id: String): cues.append(id))
	for fixture in [["anticipation", 0.16, 0.375], ["anticipation", 0.20, 0.625], ["contact", 0.0, 0.625], ["cast_anticipation", 0.16, 11.0/24.0], ["cast_anticipation", 0.20, 21.0/24.0], ["cast_release", 0.22, 27.0/24.0], ["recovery", 0.22, 35.0/24.0], ["cast_recovery", 0.22, 41.0/24.0]]:
		rig.play(fixture[0])
		rig._process(fixture[1])
		check(is_equal_approx(rig.player.current_animation_position, fixture[2]), "exact load/snap/recoil/tail: " + fixture[0] + " at " + str(fixture[1]))
	rig.play("cast_release")
	check(rig.hand_world_position().distance_to(rig.output.to_global(rig.camera.unproject_position(rig.cast_socket.global_position))) < 0.001, "socket samples current release under transformed parent")
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var duration: float = rig.begin_walk(direction, 300)
		check(duration >= 0.50 and duration <= 1.00, "bounded variant movement duration")
		var step: float = rig.walk_step_px
		check(step > 0 and is_equal_approx(step, rig.metadata.gait_calibration.step_canvas_px[rig.walk_facing]), "runtime consumes measured per-facing step")
		var before := cues.size()
		rig.advance_walk(0, 0.2)
		check(cues.size() == before and is_zero_approx(rig.walk_distance_px), "stationary beginning emits no footstep or gait progress")
		rig.advance_walk(step * 0.6, 0.05)
		var sampled: float = rig.player.current_animation_position
		rig._process(0.2)
		check(is_equal_approx(rig.player.current_animation_position, sampled), "wall time alone cannot drive moving gait")
		rig.advance_walk(step * 0.4, 0.1)
		check(cues.size() == before + 1, "actual nonuniform accumulated displacement crosses one plant")
		rig.advance_walk(step * 9.0, 0.01)
		check(cues.size() == before + 1, "minimum wall-clock cue cadence discards backlog")
		rig.advance_walk(0, 0.5)
		check(cues.size() == before + 1, "standing cannot drain crossed-plant backlog")
		rig.advance_walk(step, 0.15)
		check(cues.size() == before + 2, "next genuinely moving plant emits once")
		check(rig.skeleton.get_bone_pose_position(rig.skeleton.find_bone("root")).is_zero_approx() and rig.position.is_zero_approx() and rig.model.position.is_zero_approx(), "distance-driven gait consumes no root motion")
		rig.end_walk()
		check(rig.state == "walk_settle", "variant has a bounded soft stop")
		rig._process(0.10)
		check(rig.state == "idle", "stop settles inside existing post-move wait")
		before = cues.size()
		rig.advance_walk(step, 1)
		check(cues.size() == before, "stopped movement emits no late cue")
	check(is_equal_approx(rig.begin_walk(Vector2i.RIGHT, 18), 0.5), "short move minimum half second")
	check(is_equal_approx(rig.begin_walk(Vector2i.RIGHT, 135), 0.75), "uncapped distance uses 180px/s pacing")
	rig.end_walk(true)
	check(rig.state == "idle", "cancel skips settle and stops handles")
	var helper = load(AUDIO)
	seed(26123)
	var expected_random := randi()
	seed(26123)
	var voices: Array[AudioStreamPlayer] = []
	for i in 3:
		var voice: AudioStreamPlayer = helper.play_cue("step_a", rig)
		check(voice != null and voice.bus == "FX" and voice.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "manifest cue uses FX and never loops")
		if voice != null: voices.append(voice)
	check(helper.play_cue("step_b", rig) == null, "new audio enforces three active voice cap")
	check(helper.play_cue("missing", rig) == null, "missing cue is a safe null")
	check(randi() == expected_random, "new audio never consumes combat RNG")
	for voice in voices:
		voice.stop()
		voice.free()
	rig.begin_walk(Vector2i.RIGHT, 100)
	rig.play("defeat")
	var dead_cues := cues.size()
	rig.advance_walk(1000, 1)
	rig.end_walk()
	rig.play("hit")
	rig._process(10)
	check(rig.state == "defeat" and cues.size() == dead_cues, "defeat is irreversible and cancels all future plants")
	anchor.free()
	var bad = load(ADAPTER).new()
	bad.metadata_path = "res://does-not-exist.json"
	add_child(bad)
	check(not bad.is_available(), "missing metadata rejects variant")
	bad.free()
	var original = load(ORIGINAL).new()
	add_child(original)
	check(original.is_available(), "original remains a real visible second fallback")
	original.free()
	var missing = load(ORIGINAL).new()
	missing.asset_path = "res://does-not-exist.glb"
	add_child(missing)
	check(not missing.is_available(), "missing original rejects empty replacement for sprite fallback")
	missing.free()
	var gs := get_node("/root/GameState")
	var previous: Dictionary = gs.practice_session.duplicate(true)
	var baseline: Dictionary = gs.serialize_state().duplicate(true)
	gs.practice_session = {"rig3d": true}
	var unit := preload("res://scenes/Unit.tscn").instantiate() as Unit
	unit.unit_id = "zane"
	unit.hp = 100
	unit.mp = 25
	unit.ct = 47
	unit.grid_pos = Vector2i(2, 3)
	unit._sprite = Sprite2D.new()
	unit.add_child(unit._sprite)
	add_child(unit)
	check(unit.has_zane_impact_presentation(), "existing Show 3D selects validated variant by default")
	var start := unit.position
	unit.begin_walk_presentation(Vector2i.RIGHT, 150)
	unit.advance_walk_presentation(37, 0.2)
	unit.end_walk_presentation(true)
	check(unit.hp == 100 and unit.mp == 25 and unit.ct == 47 and unit.grid_pos == Vector2i(2,3) and unit.position == start, "presentation never changes Unit resources, CT or grid anchor")
	var grid := TacticalGrid.new()
	var highlight := Node2D.new()
	highlight.name = "HighlightLayer"
	grid.add_child(highlight)
	var units := Node2D.new()
	units.name = "UnitLayer"
	grid.add_child(units)
	add_child(grid)
	var from := unit.grid_pos
	var to := from + Vector2i(3,1)
	grid.tiles[from] = {"height":0}
	grid.tiles[to] = {"height":2}
	remove_child(unit)
	grid.place_unit(unit, from)
	unit.move_to(to) # Existing caller alone owns the logical move/facing.
	var expected_distance: float = grid._unit_foot_pos(from).distance_to(grid._unit_foot_pos(to))
	var updates: Array[Vector2] = []
	grid.unit_visual_position_changed.connect(func(_id: String, pos: Vector2): updates.append(pos))
	await grid.move_unit_visual(unit.unit_id, from, to)
	check(is_equal_approx(unit._rig3d.walk_distance_px, expected_distance), "real eased elevated segment supplies accumulated actual displacement")
	check(updates.size() > 2 and unit.position.is_equal_approx(grid._unit_foot_pos(to)), "existing grid segment and destination remain unchanged")
	check(not grid.unit_positions.has(from) and grid.unit_positions.get(to) == unit.unit_id and unit.grid_pos == to and unit.hp == 100 and unit.mp == 25 and unit.ct == 47, "real grid movement preserves logical occupancy/cost/HP/MP/CT contract")
	grid.unit_layer.remove_child(unit)
	add_child(unit)
	grid.free()
	unit.disable_3d_prototype()
	await get_tree().process_frame
	check(unit._rig3d == null and unit._sprite.visible, "toggle synchronously detaches and frees variant, restores sprite")
	check(gs.serialize_state() == baseline, "variant never writes canonical state")
	unit.free()
	gs.practice_session = previous

func check_audio() -> void:
	var rig = load(ADAPTER).new()
	rig.metadata_path = "res://missing-metadata.json"
	add_child(rig)
	var observed: Array[String] = []
	rig.cue_started.connect(func(id: String): observed.append(id))
	var helper = load(AUDIO)
	var handles: Array[AudioStreamPlayer] = []
	for id in ["fire_charge", "fire_release", "fire_hit"]:
		var voice: AudioStreamPlayer = helper.play_cue(id, rig)
		check(voice != null and voice.bus == "FX" and not voice.stream.loop_mode, "actual final WAV routes once, unlooped: " + id)
		if voice != null: handles.append(voice)
	check(observed == ["fire_charge", "fire_release", "fire_hit"], "helper signals actual starts on owner")
	check(helper.play_cue("step_a",rig) == null, "fourth actual simultaneous voice safely rejected")
	rig.free()

func check_invalid_metadata() -> void:
	var data := {"schema_version":1,"profile_id":"zane_impact_v1","model":"res://assets/3d/characters/zane_impact_v1/zane_impact_v1.glb","baseline_sha256":"9f0ce05497200bcd20ca9b37ca502f008862744887b8fbdf56ec82a147eb66c5","authoring_fps":24,"root_motion":"in_place","forward_axis":"+Z","cast_socket":"Kael_v2_cast_socket","changed_clips":["walk","slash","cast"],"unchanged_clips":["idle","thrust","heavy","hit","recovery","defeat"],"model_sha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","compatibility_report_sha256":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","runtime":"not-a-dictionary"}
	var file := FileAccess.open("user://malformed-presentation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var rig = load(ADAPTER).new()
	rig.metadata_path = "user://malformed-presentation.json"
	add_child(rig)
	check(not rig.is_available(), "malformed metadata refuses variant without hiding sprite")
	rig.free()
	var actual = JSON.parse_string(FileAccess.get_file_as_string("res://assets/3d/characters/zane_impact_v1/presentation.json"))
	for field in ["clip_durations", "source_markers", "gait_calibration"]:
		var malformed: Dictionary = actual.duplicate(true)
		match field:
			"clip_durations": malformed.clip_durations.idle = []
			"source_markers": malformed.source_markers.cast_release = "bad"
			"gait_calibration": malformed.gait_calibration.step_canvas_px.N = 0
		file = FileAccess.open("user://malformed-presentation.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(malformed))
		file.close()
		rig = load(ADAPTER).new()
		rig.metadata_path = "user://malformed-presentation.json"
		add_child(rig)
		check(not rig.is_available(), "invalid field cleanly rejects variant: " + field)
		rig.free()
	DirAccess.remove_absolute("user://malformed-presentation.json")

func check_actor_scale() -> void:
	var previous: Dictionary = GameState.practice_session.duplicate(true)
	GameState.practice_session = {"rig3d":true}
	var battle := preload("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	var actor: Unit = battle.battle_manager.units.zane
	check(is_equal_approx(actor.scale.x,1.35), "real Zane retains baseline HP-derived Unit scale")
	actor.set_facing("E")
	actor.begin_walk_presentation(Vector2i.RIGHT,100)
	var measured: float = actor._rig3d.metadata.gait_calibration.step_canvas_px.E
	check(is_equal_approx(actor._rig3d.walk_step_px,measured * actor.scale.x), "real actor's measured step is mapped once into grid-displacement space")
	var effective: float = actor._rig3d.walk_step_px
	battle.scale = Vector2.ONE * 1.17
	battle._battle_camera.zoom = Vector2.ONE * 0.75
	actor.begin_walk_presentation(Vector2i.RIGHT,100)
	check(is_equal_approx(actor._rig3d.walk_step_px,effective), "camera zoom and parent canvas transforms never double-scale gait")
	actor.advance_walk_presentation(effective,0.2)
	check(is_equal_approx(actor._rig3d.player.current_animation_position,0.5), "one actual grid-space step reaches one half-cycle plant at real Unit scale")
	actor.end_walk_presentation(true)
	for direction in [Vector2i(1,1),Vector2i(1,-1),Vector2i(3,1),Vector2i(-1,3),Vector2i(-3,1),Vector2i(1,-3)]:
		actor.move_to(actor.grid_pos + direction)
		var logical_facing := actor.facing
		actor.begin_walk_presentation(direction,100)
		actor.end_walk_presentation()
		actor._rig3d._process(0.10)
		var cardinal: Vector2i = {"N":Vector2i.UP,"E":Vector2i.RIGHT,"S":Vector2i.DOWN,"W":Vector2i.LEFT}[logical_facing]
		check(actor.facing == logical_facing and actor._rig3d.walk_facing == logical_facing, "logical facing remains authoritative after a multi-axis move")
		check(absf(actor._rig3d.model.rotation.y - atan2(float(cardinal.x),float(cardinal.y))) < 0.00001, "post-stop visual yaw agrees with canonical Unit facing: " + str(direction))
	battle.free()
	GameState.practice_session = previous

func projected_feet(rig) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for name in ["foot.L","foot.R"]:
		var bone: int = rig.skeleton.find_bone(name)
		var point: Vector3 = rig.skeleton.to_global(rig.skeleton.get_bone_global_pose(bone).origin)
		result.append(rig.output.to_global(rig.camera.unproject_position(point)))
	return result

func check_arbitrary_facing() -> void:
	var rig = load(ADAPTER).new()
	add_child(rig)
	rig.set_process(false)
	for direction in [Vector2i(1,1),Vector2i(1,-1),Vector2i(3,1),Vector2i(-1,3),Vector2i(-3,1),Vector2i(1,-3)]:
		rig.begin_walk(direction,100)
		var cardinal: Vector2i = {"N":Vector2i.UP,"E":Vector2i.RIGHT,"S":Vector2i.DOWN,"W":Vector2i.LEFT}[rig.walk_facing]
		check((rig.model.global_basis * Vector3.BACK).normalized().dot(Vector3(cardinal.x,0,cardinal.y)) > 0.99999, "multi-axis move preserves existing dominant-cardinal rendered facing: " + str(direction))
		var start := projected_feet(rig)
		rig.walk_distance_px = rig.walk_step_px
		rig._sample()
		var end := projected_feet(rig)
		var measured := (start[0].distance_to(end[0]) + start[1].distance_to(end[1])) / 2.0
		check(absf(measured - rig.walk_step_px) < 0.001, "multi-axis gait ruler matches actual rendered imported stride: " + str(direction))
		rig.end_walk(true)
	rig.free()

func check_metadata_errors() -> void:
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(),PackedStringArray(["--headless","--path",ProjectSettings.globalize_path("res://"),"res://tests/test_zane_impact_rig.tscn","--","--metadata-probe"]),output,true)
	var captured := "\n".join(output)
	check(code == 0 and captured.contains("Metadata safety: 126 rejected"), "all malformed scalar/array/dictionary fields are refused")
	check(not captured.contains("SCRIPT ERROR:"), "malformed metadata fallback must emit zero SCRIPT ERROR diagnostics")
	if captured.contains("SCRIPT ERROR:"): printerr(captured)

func metadata_probe() -> void:
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/3d/characters/zane_impact_v1/presentation.json"))
	var rejected := 0
	for field in ["schema_version","profile_id","model","baseline_sha256","authoring_fps","root_motion","forward_axis","cast_socket","changed_clips","unchanged_clips","runtime","source_markers","marker_frames","gait_calibration","clip_durations","model_sha256","compatibility_report_sha256","walk_contacts"]:
		for value in [null,true,999,0.333,"wrong",[],{}]:
			var malformed: Dictionary = original.duplicate(true)
			malformed[field] = value
			var file := FileAccess.open("user://metadata-safety-probe.json",FileAccess.WRITE)
			file.store_string(JSON.stringify(malformed))
			file.close()
			var rig = load(ADAPTER).new()
			rig.metadata_path = "user://metadata-safety-probe.json"
			if not rig._validate_metadata(): rejected += 1
			rig.free()
	DirAccess.remove_absolute("user://metadata-safety-probe.json")
	print("Metadata safety: %d rejected" % rejected)
	get_tree().quit(0 if rejected == 126 else 1)
