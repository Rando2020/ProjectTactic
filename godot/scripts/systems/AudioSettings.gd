extends Node

signal volume_changed(bus_name: String, value: int)

const SETTINGS_PATH := "user://settings.cfg"
const BUS_GAME := "Game"
const BUS_MUSIC := "Music"
const BUS_FX := "FX"

const SFX_STREAMS := {
	"ui_confirm": preload("res://assets/audio/sfx/ui-confirm.wav"),
	"attack_impact": preload("res://assets/audio/sfx/attack-impact.wav"),
	"spell_cast": preload("res://assets/audio/sfx/spell-cast.wav"),
	"victory": preload("res://assets/audio/sfx/victory-chime.wav"),
	"defeat": preload("res://assets/audio/sfx/defeat-sting.wav"),
}

var game_volume: int = 100
var music_volume: int = 80
var fx_volume: int = 100


func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	apply_all()


func set_game_volume(value: float) -> void:
	game_volume = _clamp_volume(value)
	_apply_bus_volume(BUS_GAME, game_volume)
	save_settings()
	volume_changed.emit(BUS_GAME, game_volume)


func set_music_volume(value: float) -> void:
	music_volume = _clamp_volume(value)
	_apply_bus_volume(BUS_MUSIC, music_volume)
	save_settings()
	volume_changed.emit(BUS_MUSIC, music_volume)


func set_fx_volume(value: float) -> void:
	fx_volume = _clamp_volume(value)
	_apply_bus_volume(BUS_FX, fx_volume)
	save_settings()
	volume_changed.emit(BUS_FX, fx_volume)


func get_volume(bus_name: String) -> int:
	match bus_name:
		BUS_GAME:
			return game_volume
		BUS_MUSIC:
			return music_volume
		BUS_FX:
			return fx_volume
		_:
			return 100


func play_sfx(sfx_id: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = SFX_STREAMS.get(sfx_id)
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = BUS_FX
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func apply_all() -> void:
	_apply_bus_volume(BUS_GAME, game_volume)
	_apply_bus_volume(BUS_MUSIC, music_volume)
	_apply_bus_volume(BUS_FX, fx_volume)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "game_volume", game_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "fx_volume", fx_volume)
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("AudioSettings: could not save settings.cfg.")


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return
	game_volume = _clamp_volume(config.get_value("audio", "game_volume", game_volume))
	music_volume = _clamp_volume(config.get_value("audio", "music_volume", music_volume))
	fx_volume = _clamp_volume(config.get_value("audio", "fx_volume", fx_volume))


func _ensure_audio_buses() -> void:
	_ensure_bus(BUS_GAME, "Master")
	_ensure_bus(BUS_MUSIC, BUS_GAME)
	_ensure_bus(BUS_FX, BUS_GAME)


func _ensure_bus(bus_name: String, send_to: String) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, send_to)


func _apply_bus_volume(bus_name: String, value: int) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, _volume_to_db(value))
	AudioServer.set_bus_mute(bus_index, value <= 0)


func _volume_to_db(value: int) -> float:
	if value <= 0:
		return -80.0
	return linear_to_db(float(value) / 100.0)


func _clamp_volume(value: Variant) -> int:
	return clampi(int(round(float(value))), 0, 100)
