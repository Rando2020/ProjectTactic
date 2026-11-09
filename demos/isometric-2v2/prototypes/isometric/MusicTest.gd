extends SceneTree

const EXPECTED := {
 "steel-march-echo-battle": ["54e61534979952bbbdc8c3a225657bdda4d603c79eb3194addf4af38e7e4782e", "ba035d9647c9e4bf9ebe4868976f3e27269b4792511bf6a64b4ec9b11ac10d0c"],
 "gold-severance": ["34e1a99a5296f0a92dc0ef1cb37bd45ea15cb24f3a3bcf27230b6192c6a2dcdf", "1b81f4eded908c084bd088fdcd0798c1e096436f4b30dca8f02df6d38d0a5f94"]
}

func sha(bytes: PackedByteArray) -> String:
 var hash := HashingContext.new()
 hash.start(HashingContext.HASH_SHA256)
 hash.update(bytes)
 return hash.finish().hex_encode()

func _initialize() -> void:
 for track in EXPECTED:
  var bytes := PackedByteArray()
  for index in range(1, 4):
   bytes.append_array(FileAccess.get_file_as_bytes("res://assets/music/%s.%d.wavpart" % [track, index]))
  if sha(bytes) != EXPECTED[track][0]:
   printerr("FAIL: original WAV identity " + track)
   quit(1)
   return
  var stream = load("res://prototypes/isometric/PackedMusic.gd").load_track(track)
  if stream == null or stream.mix_rate != 48000 or not stream.stereo or stream.get_length() < 100.0 or sha(stream.data) != EXPECTED[track][1]:
   printerr("FAIL: decoded PCM identity " + track)
   quit(1)
   return
 print("Music packaging: both original WAV and decoded PCM identities PASS")
 quit(0)
