## Original deterministic procedural sound design, not third-party recordings.
## Each call is an owner-scoped one-shot. Retain the voice and stop/free it on
## phase cancellation, or free its presentation owner to cancel all its voices.
extends RefCounted
const RATE := 22050
const GAIN_DB := -12.0
const PEAK := 0.70
const ABILITIES := ["haste", "defend", "thunderstrike", "void_pulse", "dark_breath", "shadow_mend", "mighty_strike", "delay_strike", "heavy_slash"]
# Match physical windups so cancellation at phase end does not clip the envelope.
const CHARGE_DURATIONS := {"mighty_strike": 0.34, "delay_strike": 0.28, "heavy_slash": 0.46}
const DURATIONS := {"charge": 0.60, "release": 0.20, "contact": 0.28, "heal": 0.42}
static var _streams: Dictionary = {}

static func play(ability_id: String, phase: String, owner: Node) -> AudioStreamPlayer:
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion():
		return null
	var ability := ability_id.strip_edges().to_lower().replace(" ", "_")
	if not ability in ABILITIES or not DURATIONS.has(phase):
		return null
	var key := ability + ":" + phase
	if not _streams.has(key):
		_streams[key] = _synthesize(ability, phase)
	var voice := AudioStreamPlayer.new()
	voice.stream = _streams[key]
	voice.bus = "FX"
	voice.volume_db = GAIN_DB
	owner.add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()
	return voice

static func _synthesize(ability: String, phase: String) -> AudioStreamWAV:
	var duration: float = CHARGE_DURATIONS.get(ability, 0.60) if phase == "charge" else DURATIONS[phase]
	var count := int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var peak := 0.001
	# Phase pitch/envelope changes retain the skill's timbre through its action.
	var pitch: float = {"charge": 0.78, "release": 1.35, "contact": 0.60, "heal": 1.0}[phase]
	for i in count:
		var t := float(i) / RATE
		var p := float(i) / float(count - 1)
		var u := t * pitch
		var noise := sin(t * 29317.0) * sin(t * 18719.0)
		var signal_value := 0.0
		match ability:
			"haste":
				# Accelerating bright bell steps and airy shimmer.
				var chirp := TAU * (620.0 * u + 950.0 * u * u)
				signal_value = sin(chirp) * 0.60 + sin(chirp * 1.5) * 0.22 + noise * 0.10
			"defend":
				# Rounded bronze shield resonance with a short metallic overtone.
				signal_value = sin(TAU * 185.0 * u) * 0.60 + sin(TAU * 479.0 * u) * exp(-p * 4.0) * 0.28
			"thunderstrike":
				# Electrical buzz, crackle and a descending thunder body.
				signal_value = noise * 0.48 + sin(TAU * (140.0 * u - 50.0 * u * p)) * 0.42 + sin(TAU * 1100.0 * u) * sin(TAU * 75.0 * t) * 0.18
			"void_pulse":
				# Low beating, hollow dissonant pulse.
				signal_value = (sin(TAU * 112.0 * u) * 0.55 + sin(TAU * 119.0 * u) * 0.25 + sin(TAU * 237.0 * u) * 0.15) * (0.65 + 0.35 * cos(TAU * 12.0 * t))
			"dark_breath":
				# Rough, breathy filtered-noise texture over a wavering low tone.
				signal_value = noise * (0.45 + 0.20 * sin(TAU * 17.0 * t)) + sin(TAU * 92.0 * u + sin(TAU * 23.0 * t)) * 0.30
			"shadow_mend":
				# Soft minor-to-open chord with a high restorative chime.
				signal_value = sin(TAU * 330.0 * u) * 0.40 + sin(TAU * 392.0 * u) * 0.24 + sin(TAU * 495.0 * u) * 0.22 + sin(TAU * 990.0 * u) * 0.08
			"mighty_strike":
				# Heavy low drum, with a broad impact transient.
				signal_value = sin(TAU * (165.0 * u - 100.0 * u * p)) * 0.72 + noise * exp(-p * 7.0) * 0.32
			"delay_strike":
				# Clock-like paired ticks riding a narrow descending ring.
				var ticks := pow(0.5 + 0.5 * cos(TAU * 16.0 * t), 10.0)
				signal_value = sin(TAU * (860.0 * u - 240.0 * u * p)) * 0.42 + (sin(TAU * 1720.0 * u) * 0.25 + noise * 0.40) * ticks
			"heavy_slash":
				# Wide noisy blade sweep with a descending metallic edge.
				signal_value = noise * 0.58 + sin(TAU * (520.0 * u - 330.0 * u * p)) * 0.30 + sin(TAU * 1370.0 * u) * 0.12
		var envelope := 0.0
		match phase:
			"charge": envelope = sin(PI * p * 0.5) * minf(1.0, (1.0 - p) / 0.12)
			"release": envelope = minf(1.0, p / 0.035) * exp(-p * 2.5) * (1.0 - p)
			"contact": envelope = minf(1.0, p / 0.015) * exp(-p * 5.0) * (1.0 - p)
			"heal": envelope = sin(PI * p)
		samples[i] = signal_value * envelope
		peak = maxf(peak, absf(samples[i]))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		bytes.encode_s16(i * 2, int(samples[i] / peak * PEAK * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream
