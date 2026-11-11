extends SceneTree
# Catches missing skill cues, shared waveform routing, clipping and orphan voices.
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var path := "res://scripts/presentation/CourtyardSkillAudio.gd"
	check(ResourceLoader.exists(path), "skill-specific synthesized audio exists")
	if failures:
		quit(1)
		return
	var cues = load(path)
	var owner := Node.new()
	root.add_child(owner)
	var settings := root.get_node("AudioSettings")
	settings._ensure_audio_buses()
	settings._apply_bus_volume("FX", 0)
	var fx := AudioServer.get_bus_index("FX")
	var hashes := {}
	for ability in ["haste", "defend", "thunderstrike", "void_pulse", "dark_breath", "shadow_mend", "mighty_strike", "delay_strike", "heavy_slash"]:
		for phase in ["charge", "release", "contact", "heal"]:
			var voice: AudioStreamPlayer = cues.play(ability, phase, owner)
			check(voice != null, ability + " " + phase + " has a voice")
			if voice == null: continue
			var stream := voice.stream as AudioStreamWAV
			check(stream != null and stream.data.size() > 2000, "audible-length PCM")
			check(voice.bus == "FX" and AudioServer.is_bus_mute(fx), "cue respects mute and FX bus")
			check(stream.get_length() >= 0.12 and stream.get_length() <= 0.8, "bounded one-shot duration")
			if phase == "charge":
				var expected_duration: float = {"mighty_strike": 0.34, "delay_strike": 0.28, "heavy_slash": 0.46}.get(ability, 0.60)
				check(absf(stream.get_length() - expected_duration) < 1.0 / 22050.0, ability + " charge fits authored windup without truncating its envelope")
			var peak := 0.0
			var energy := 0.0
			for i in stream.data.size()/2:
				var sample := float(stream.data.decode_s16(i*2))/32768.0
				peak = maxf(peak, absf(sample))
				energy += sample * sample
			check(peak > 0.3 and peak < 0.8, "PCM has level and headroom")
			check(peak * db_to_linear(voice.volume_db) < 0.2, "phase overlap retains mix headroom")
			check(sqrt(energy/(stream.data.size()/2)) > 0.015, "cue is not effectively silent")
			check(stream.data.decode_s16(0) == 0 and stream.data.decode_s16(stream.data.size()-2) == 0, "click-free waveform ends")
			var digest := stream.data.hex_encode().sha256_text()
			check(not hashes.has(digest), ability + " " + phase + " distinct waveform")
			hashes[digest] = true
			var repeat: AudioStreamPlayer = cues.play(ability, phase, owner)
			check(repeat.stream.data == stream.data, "repeatable deterministic synthesis")
			repeat.free()
			voice.stop()
			check(not voice.playing, "returned voice supports immediate cancellation")
			voice.free()
	check(cues.play("unknown", "charge", owner) == null, "unknown skills do not get generic wrong cues")
	check(cues.play("fire", "charge", owner) == null, "Fire remains legacy-owned")
	check(cues.play("haste", "unknown", owner) == null, "unknown phases are rejected")
	check(cues.play("haste", "charge", null) == null, "null owner rejected")
	var detached := Node.new()
	check(cues.play("haste", "charge", detached) == null, "detached owner rejected")
	detached.free()
	var alias: AudioStreamPlayer = cues.play("Mighty Strike", "charge", owner)
	check(alias != null, "display names normalize to ability IDs")
	alias.free()
	var natural: AudioStreamPlayer = cues.play("haste", "contact", owner)
	await create_timer(1.0).timeout
	check(not is_instance_valid(natural), "completed voice is reclaimed")
	var voice: AudioStreamPlayer = cues.play("haste", "charge", owner)
	owner.queue_free()
	check(cues.play("haste", "release", owner) == null, "queued owner rejected")
	await process_frame
	check(not is_instance_valid(voice), "owner cancellation reclaims voice")
	# Let the mixer retire its last playback before shutting down the engine.
	await create_timer(0.1).timeout
	print("Skill audio: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
