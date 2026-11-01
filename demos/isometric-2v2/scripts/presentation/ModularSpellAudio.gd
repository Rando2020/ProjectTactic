## Original deterministic synthesized cues; no recordings/network/combat ownership.
extends RefCounted
const RATE := 22050
const GAIN_DB := -8.0
const PEAK := 0.75

static func play(kind: String, owner: Node) -> AudioStreamPlayer:
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion(): return null
	var duration: float = {"charge":0.60,"release":0.20,"contact":0.23,"heal":0.40}.get(kind,0.20)
	var samples := PackedFloat32Array()
	samples.resize(int(duration*RATE))
	var peak := 0.001
	for i in samples.size():
		var t := float(i)/RATE
		var p := t/duration
		var sample := 0.0
		match kind:
			"charge":
				# Rising harmonic body: audible build across all four casting poses.
				var phase := TAU*(170.0*t+360.0*t*t/(2.0*duration))
				var envelope := sin(PI*p*0.5)*minf(1.0,(1.0-p)/0.12)
				sample = (sin(phase)*0.65+sin(phase*2.0)*0.20+sin(phase*3.0)*0.10)*envelope
			"contact":
				# Low descending impact plus deterministic crackle, not the cast tone.
				var phase := TAU*(190.0*t-120.0*t*t/(2.0*duration))
				var envelope := minf(1.0,t/0.003)*exp(-p*5.0)*(1.0-p)
				sample = (sin(phase)*0.72+sin(t*29317.0)*sin(t*18719.0)*0.28)*envelope
			"heal":
				var envelope := sin(PI*p)
				sample = (sin(TAU*440.0*t)*0.45+sin(TAU*554.37*t)*0.30+sin(TAU*659.25*t)*0.20)*envelope
			_:
				# Short upward release/fizzle chirp, clearly separate from the build.
				var phase := TAU*(650.0*t+500.0*t*t/(2.0*duration))
				var envelope := minf(1.0,t/0.005)*exp(-p*3.5)*(1.0-p)
				sample = (sin(phase)*0.7+sin(phase*1.5)*0.2)*envelope
		samples[i] = sample
		peak = maxf(peak,absf(sample))
	var bytes := PackedByteArray()
	bytes.resize(samples.size()*2)
	for i in samples.size(): bytes.encode_s16(i*2,int(samples[i]/peak*PEAK*32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.bus = "FX"
	voice.volume_db = GAIN_DB
	owner.add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()
	return voice
