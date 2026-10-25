## Approved Zane-only timing and distance phase. No root motion or gameplay callbacks.
extends "res://scripts/presentation/SharedRigPresentation.gd"

signal cue_started(cue_id: String)

const PROFILE := "zane_impact_v1"
const MODEL := "res://assets/3d/characters/zane_impact_v1/zane_impact_v1.glb"
const PAINTERLY_PROFILE := "zane_painterly_v1"
const PAINTERLY_MODEL := "res://assets/3d/characters/zane_painterly_v1/zane_painterly_v1.glb"
const MOTION_SOURCE_SHA := "669244b98a1ba99dde3996b3b4834fb142081fe5d1661e5f2be5e748529e4a90"
const INHERITED_CLIPS := ["idle", "slash", "thrust", "heavy", "cast", "hit", "recovery", "walk", "defeat"]
const BASELINE_SHA := "9f0ce05497200bcd20ca9b37ca502f008862744887b8fbdf56ec82a147eb66c5"
const Audio := preload("res://scripts/presentation/ZaneImpactAudio.gd")
var metadata_path := "res://assets/3d/characters/zane_impact_v1/presentation.json"
var profile_id := PROFILE
var _configured_profile := PROFILE
var _profile_locked := false
var metadata: Dictionary = {}
var walk_distance_px := 0.0
var walk_step_px := 0.0
var walk_facing := "S"
var _walking := false
var _walk_clock := 0.0
var _last_step_clock := -100.0
var _plant_index := 0
var _settle_sample := 0.0
var _step_handles: Array[AudioStreamPlayer] = []

func _init() -> void:
	# VFX lives in an earlier autoload subtree. Sample this presentation-only
	# pose/bones before its default-priority charge follower, not one frame later.
	process_priority = -1
	skin_id = "zane"
	asset_path = MODEL
	cast_socket_name = "Kael_v2_cast_socket"

## Only explicit approved profiles may configure this exact action-capable adapter.
## Never reuse an entered adapter for a different model, even after detaching it.
func configure_profile(profile: String) -> bool:
	if _profile_locked or profile not in [PROFILE, PAINTERLY_PROFILE]: return false
	_configured_profile = profile
	profile_id = profile
	asset_path = PAINTERLY_MODEL if profile == PAINTERLY_PROFILE else MODEL
	metadata_path = "res://assets/3d/characters/%s/presentation.json" % profile
	_pixel_style = profile != PAINTERLY_PROFILE
	return true

func _enter_tree() -> void:
	_profile_locked = true

func _ready() -> void:
	if not _validate_metadata(): return
	super._ready()
	if not _available: return
	if player.get_animation_list().size() != 9:
		_available = false
	for clip in metadata.clip_durations:
		if not player.has_animation(clip) or not is_equal_approx(player.get_animation(clip).length, float(metadata.clip_durations[clip])):
			_available = false

func _validate_metadata() -> bool:
	if _configured_profile not in [PROFILE, PAINTERLY_PROFILE] or profile_id != _configured_profile: return false
	var approved_model := PAINTERLY_MODEL if _configured_profile == PAINTERLY_PROFILE else MODEL
	if asset_path != approved_model: return false
	if not FileAccess.file_exists(metadata_path): return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
	if not parsed is Dictionary: return false
	metadata = parsed
	for key in ["schema_version", "authoring_fps"]:
		if not metadata.get(key) is int and not metadata.get(key) is float: return false
	for key in ["profile_id", "model", "baseline_sha256", "root_motion", "forward_axis", "cast_socket", "model_sha256", "compatibility_report_sha256"]:
		if not metadata.get(key) is String: return false
	for key in ["changed_clips", "unchanged_clips", "walk_contacts"]:
		if not metadata.get(key) is Array: return false
	for key in ["changed_clips", "unchanged_clips"]:
		for value in metadata[key]:
			if not value is String: return false
	for contact in metadata.walk_contacts:
		if not contact is int and not contact is float: return false
	if metadata.get("schema_version") != 1 or metadata.get("profile_id") != _configured_profile or metadata.get("model") != asset_path or metadata.get("baseline_sha256") != BASELINE_SHA: return false
	if _configured_profile == PAINTERLY_PROFILE:
		var source = metadata.get("motion_source")
		if not source is Dictionary: return false
		if not source.get("profile_id") is String or not source.get("model_sha256") is String or not source.get("unchanged_clips") is Array: return false
		if source.get("profile_id") != PROFILE or source.get("model_sha256") != MOTION_SOURCE_SHA or source.get("unchanged_clips") != INHERITED_CLIPS: return false
	if metadata.get("authoring_fps") != 24 or metadata.get("root_motion") != "in_place" or metadata.get("forward_axis") != "+Z" or metadata.get("cast_socket") != cast_socket_name: return false
	if metadata.get("changed_clips") != ["walk", "slash", "cast"] or metadata.get("unchanged_clips") != ["idle", "thrust", "heavy", "hit", "recovery", "defeat"]: return false
	for key in ["runtime", "source_markers", "marker_frames", "gait_calibration", "clip_durations"]:
		if not metadata.get(key, {}) is Dictionary: return false
	if not metadata.get("gait_calibration", {}).get("step_canvas_px", {}) is Dictionary: return false
	var sha := str(metadata.get("model_sha256", ""))
	if sha.length() != 64 or str(metadata.get("compatibility_report_sha256", "")).length() != 64: return false
	# Exported PCKs may retain the imported resource/remap instead of raw GLB bytes.
	if FileAccess.file_exists(asset_path) and FileAccess.get_sha256(asset_path) != sha: return false
	var expected := {"prepare":0.20, "snap":0.04, "travel":0.22, "recovery":0.22, "walk_speed_px_s":180.0, "walk_min":0.50, "walk_max":1.00, "walk_settle":0.10}
	var timing: Dictionary = metadata.get("runtime", {})
	for key in expected:
		if not timing.get(key) is float and not timing.get(key) is int: return false
		if not is_equal_approx(float(timing.get(key, -1)), expected[key]): return false
	var frames := {"slash_load":10, "slash_contact":16, "cast_load":12, "cast_release":22, "cast_recoil":28}
	var markers: Dictionary = metadata.get("source_markers", {})
	var marker_frames: Dictionary = metadata.get("marker_frames", {})
	for key in frames:
		if not markers.get(key) is float and not markers.get(key) is int: return false
		if not marker_frames.get(key) is int and not marker_frames.get(key) is float: return false
		if marker_frames.get(key) != frames[key] or not is_equal_approx(float(markers.get(key, -1)), (frames[key] - 1.0) / 24.0): return false
	if metadata.get("walk_contacts") != [0.0, 0.5]: return false
	var steps: Dictionary = metadata.get("gait_calibration", {}).get("step_canvas_px", {})
	for direction in ["N", "E", "S", "W"]:
		if not steps.get(direction) is float and not steps.get(direction) is int: return false
		if not is_finite(float(steps.get(direction, 0))) or float(steps.get(direction, 0)) <= 0: return false
	var durations: Dictionary = metadata.get("clip_durations", {})
	if durations.size() != 9: return false
	for clip in ["idle", "slash", "thrust", "heavy", "cast", "hit", "recovery", "walk", "defeat"]:
		if not durations.get(clip) is float and not durations.get(clip) is int: return false
		if not is_finite(float(durations[clip])) or float(durations[clip]) <= 0: return false
	return true

func play(next: String) -> void:
	if state == "defeat":
		super.play(next)
		return
	if next == "defeat":
		_walking = false
		_stop_steps()
	super.play(next)

func _phase_sample() -> Dictionary:
	var markers: Dictionary = metadata.source_markers
	var clip := "slash"
	var time := 0.0
	match state:
		"anticipation", "cast_anticipation":
			var casting := state == "cast_anticipation"
			clip = "cast" if casting else "slash"
			var load_time := float(markers.cast_load if casting else markers.slash_load)
			var contact_time := float(markers.cast_release if casting else markers.slash_contact)
			if age <= 0.16:
				time = lerpf(0.0, load_time, clampf(age / 0.16, 0, 1))
			else:
				time = lerpf(load_time, contact_time, clampf((age - 0.16) / 0.04, 0, 1))
		"contact": time = markers.slash_contact
		"recovery": time = lerpf(markers.slash_contact, player.get_animation(clip).length, clampf(age / 0.22, 0, 1))
		"cast_release":
			clip = "cast"
			time = lerpf(markers.cast_release, markers.cast_recoil, clampf(age / 0.22, 0, 1))
		"cast_recovery":
			clip = "cast"
			time = lerpf(markers.cast_recoil, player.get_animation(clip).length, clampf(age / 0.22, 0, 1))
		"walk":
			clip = "walk"
			time = fmod(walk_distance_px / (2.0 * walk_step_px), 1.0) * player.get_animation(clip).length if walk_step_px > 0 else 0.0
		"walk_settle":
			clip = "walk"
			time = lerpf(_settle_sample, ceilf(_settle_sample * 2.0) / 2.0, clampf(age / 0.10, 0, 1))
		_: return super._phase_sample()
	return {"clip":clip, "time":time}

func _process(dt: float) -> void:
	if state == "walk_settle" and age + maxf(0, dt) >= 0.10:
		play("idle")
		return
	super._process(dt)

func begin_walk(direction: Vector2i, distance_px: float) -> float:
	if not _available or state == "defeat": return 0.50
	_stop_steps()
	var unit_owner := get_parent() as Node2D
	var directions := {"N":Vector2i.UP, "E":Vector2i.RIGHT, "S":Vector2i.DOWN, "W":Vector2i.LEFT}
	if unit_owner != null and unit_owner.has_method("advance_walk_presentation"):
		# Unit.move_to alone owns canonical facing/bonuses, including axis ties.
		walk_facing = str(unit_owner.get("facing"))
	elif direction != Vector2i.ZERO:
		walk_facing = ("E" if direction.x > 0 else "W") if absi(direction.x) >= absi(direction.y) else ("S" if direction.y > 0 else "N")
	face(directions[walk_facing])
	walk_step_px = float(metadata.gait_calibration.step_canvas_px[walk_facing])
	# The existing Unit HP scale is uniform and local to grid displacement space.
	# Do not multiply global scale or camera zoom a second time.
	if unit_owner != null and unit_owner.has_method("advance_walk_presentation"):
		walk_step_px *= absf(unit_owner.scale.x)
	walk_distance_px = 0
	_walk_clock = 0
	_last_step_clock = -100
	_plant_index = 0
	_walking = distance_px > 0
	play("walk")
	return clampf(maxf(0, distance_px) / float(metadata.runtime.walk_speed_px_s), float(metadata.runtime.walk_min), float(metadata.runtime.walk_max))

func advance_walk(distance_delta_px: float, elapsed_delta_s: float) -> void:
	if not _walking or state != "walk": return
	_walk_clock += maxf(0, elapsed_delta_s)
	var increment := maxf(0, distance_delta_px)
	if increment <= 0: return
	walk_distance_px += increment
	var crossed := int(floor(walk_distance_px / walk_step_px + 0.00001))
	if crossed > _plant_index and _walk_clock - _last_step_clock >= 0.14:
		var handle := Audio.play_cue("step_a" if crossed % 2 == 1 else "step_b", self)
		if is_instance_valid(handle): _step_handles.append(handle)
		_last_step_clock = _walk_clock
	_plant_index = crossed # Discard missed plants; never play a catch-up burst.
	_sample()

func end_walk(cancelled: bool = false) -> void:
	_walking = false
	_stop_steps()
	if state == "defeat" or not _available: return
	if cancelled:
		play("idle")
	else:
		_settle_sample = float(_phase_sample().time)
		play("walk_settle")

func _stop_steps() -> void:
	for voice in _step_handles:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
			voice.queue_free()
	_step_handles.clear()
