extends Node
const Cues := preload("res://scripts/presentation/ModularSpellAudio.gd")
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: "+message)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var settings := get_node("/root/AudioSettings")
	var initial_count := AudioServer.bus_count
	settings._ensure_audio_buses()
	check(AudioServer.bus_count == initial_count,"bus setup is idempotent")
	for pair in [["Game","Master"],["FX","Game"],["Music","Game"]]:
		var index := AudioServer.get_bus_index(pair[0])
		check(index > 0 and AudioServer.get_bus_send(index) == pair[1],"bus sends retain settings hierarchy")
	settings._apply_bus_volume("FX",0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("FX")),"user zero volume stays muted")
	settings._apply_bus_volume("FX",100)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("FX")),"explicit user volume restores FX")
	var hashes := {}
	for cue in ["charge","release","contact","heal"]:
		var voice := Cues.play(cue,self)
		var stream := voice.stream as AudioStreamWAV
		check(stream != null and stream.data.size()>0,"cue has actual PCM")
		check(voice.bus == "FX","cue respects FX controls")
		if cue=="charge": check(stream.get_length() >= 0.55 and stream.get_length() <= 0.65,"charge builds throughout visible casting")
		var peak := 0.0
		var sum := 0.0
		for index in stream.data.size()/2:
			var sample := float(stream.data.decode_s16(index*2))/32768.0 * db_to_linear(voice.volume_db)
			peak = maxf(peak,absf(sample))
			sum += sample*sample
		var rms := sqrt(sum/(stream.data.size()/2))
		print("AUDIO ",cue," seconds=",stream.get_length()," peak_db=",linear_to_db(peak)," rms_db=",linear_to_db(rms))
		check(peak > db_to_linear(-20.0) and peak < db_to_linear(-3.0),"cue is audible with safe headroom")
		var digest := stream.data.hex_encode().sha256_text()
		check(not hashes.has(digest),"phase cues use distinct PCM")
		hashes[digest]=true
		await get_tree().create_timer(0.05).timeout
		voice.stop()
		voice.stream = null
		voice.queue_free()
	var owner := preload("res://scripts/presentation/ZaneActionPresentation.gd").new()
	add_child(owner)
	owner.set_process(false)
	owner.context = {"authored_fire_sheet":true}
	var ids: Array[String] = []
	owner.cue_started.connect(func(id: String): ids.append(id))
	var fire_voice := preload("res://scripts/presentation/ZaneImpactAudio.gd").play_cue("fire_charge",owner)
	check(fire_voice.stream.get_length() >= 0.55,"authored demo Fire charge spans visible windup")
	check(ids == ["fire_charge"],"Fire preserves exactly one existing cue identity")
	await get_tree().create_timer(0.05).timeout
	owner._stop_voice(fire_voice)
	check(not fire_voice.playing and fire_voice.stream == null,"phase-end/cancel stops synthetic Fire voice")
	owner.context = {}
	var legacy := preload("res://scripts/presentation/ZaneImpactAudio.gd").play_cue("fire_charge",owner)
	check(is_equal_approx(legacy.stream.get_length(),0.196),"legacy Fire retains original WAV")
	await get_tree().create_timer(0.05).timeout
	owner._stop_voice(legacy)
	owner.queue_free()
	await get_tree().create_timer(0.2).timeout
	print("Modular audio: %s checks, %s failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
