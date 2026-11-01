## Original synthesized cues. No external recordings, network, or combat ownership.
extends RefCounted
static func play(kind: String, owner: Node) -> AudioStreamPlayer:
	var duration := 0.18 if kind == "contact" else 0.25
	var rate := 22050
	var bytes := PackedByteArray()
	bytes.resize(int(duration*rate)*2)
	for i in bytes.size()/2:
		var t := float(i)/rate
		var envelope := sin(PI*clampf(t/duration,0,1))*exp(-t*8)
		var frequency := 240.0 + (720.0 if kind == "heal" else 360.0)*t/duration
		var sample := sin(TAU*frequency*t) * 0.55 + sin(TAU*frequency*1.51*t)*0.22
		if kind == "contact": sample += sin(t*29317.0)*sin(t*18719.0)*0.32
		bytes.encode_s16(i*2,int(clampf(sample*envelope,-1,1)*12000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.bus = "FX"
	voice.volume_db = -15
	owner.add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()
	return voice
