extends RefCounted

## Lossless transport packaging only: concatenate the original WAV bytes.
static func load_battle_music() -> AudioStreamWAV:
	return load_track("steel-march-echo-battle")

static func load_title_music() -> AudioStreamWAV:
	return load_track("gold-severance")

static func load_track(track: String) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	for index in range(1, 4):
		var path := "res://assets/music/%s.%d.wavpart" % [track, index]
		if not FileAccess.file_exists(path):
			push_error("Missing demo music part: " + path)
			return null
		bytes.append_array(FileAccess.get_file_as_bytes(path))
	return AudioStreamWAV.load_from_buffer(bytes)
