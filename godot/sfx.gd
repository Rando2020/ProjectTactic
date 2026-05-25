# ============================================================
#  THE APPOINTED - SFX
#  Autoload register name: Sfx
#
#  Missing audio files are allowed. Add the wav files later and
#  the cues will start playing without changing this script.
# ============================================================
extends Node

const CUE_PATHS := {
	"nav": "res://assets/audio/nav.wav",
	"select": "res://assets/audio/select.wav",
	"confirm": "res://assets/audio/confirm.wav",
	"cancel": "res://assets/audio/cancel.wav",
	"page": "res://assets/audio/page.wav",
	"sacred": "res://assets/audio/sacred.wav",
	"tick": "res://assets/audio/tick.wav",
	"crack": "res://assets/audio/crack.wav",
}

const POOL_SIZE := 8

var muted: bool = false
var _pool: Array[AudioStreamPlayer] = []
var _cues: Dictionary = {}


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	_load_cues()
	if FileAccess.file_exists("user://audio_muted.cfg"):
		var f := FileAccess.open("user://audio_muted.cfg", FileAccess.READ)
		muted = f.get_var() as bool
		f.close()


func _load_cues() -> void:
	_cues.clear()
	for cue_name in CUE_PATHS.keys():
		var path: String = str(CUE_PATHS[cue_name])
		if ResourceLoader.exists(path):
			_cues[cue_name] = load(path)


func play(name: String) -> void:
	if muted:
		return
	if not _cues.has(name):
		return
	var player := _free_player()
	player.stream = _cues[name]
	player.play()


func set_muted(v: bool) -> void:
	muted = v
	var f := FileAccess.open("user://audio_muted.cfg", FileAccess.WRITE)
	f.store_var(muted)
	f.close()


func _free_player() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	return _pool[0]
