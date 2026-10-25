## Original manifest cues. Owners own handles; this helper never owns combat state.
extends RefCounted

const MANIFEST := "res://assets/audio/zane_impact_v1/manifest.json"
const MAX_VOICES := 3
static var _voices: Array[WeakRef] = []
static var _cues: Dictionary = {}

static func play_cue(cue_id: String, owner: Node) -> AudioStreamPlayer:
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion():
		return null
	var alive: Array[WeakRef] = []
	for reference in _voices:
		var voice = reference.get_ref()
		if is_instance_valid(voice) and not voice.is_queued_for_deletion() and voice.playing:
			alive.append(reference)
	_voices = alive
	if _voices.size() >= MAX_VOICES:
		return null
	if _cues.is_empty():
		if not FileAccess.file_exists(MANIFEST): return null
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if not parsed is Dictionary or parsed.get("schema_version") != 1 or parsed.get("profile_id") != "zane_impact_v1": return null
		if not parsed.get("cues", {}) is Dictionary: return null
		_cues = parsed.get("cues", {})
	if not _cues.get(cue_id, {}) is Dictionary: return null
	var cue: Dictionary = _cues.get(cue_id, {})
	if cue.is_empty() or not ResourceLoader.exists(str(cue.get("path", ""))): return null
	var stream := load(str(cue.path)) as AudioStreamWAV
	if stream == null: return null
	stream = stream.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.bus = "FX"
	voice.volume_db = float(cue.get("gain_db", -12))
	owner.add_child(voice)
	voice.finished.connect(voice.queue_free)
	# A receiver-bound callable auto-disconnects if a finished voice is freed first.
	owner.tree_exiting.connect(voice.stop, CONNECT_ONE_SHOT)
	_voices.append(weakref(voice))
	voice.play()
	if owner.has_signal("cue_started"):
		owner.emit_signal("cue_started", cue_id)
	return voice
