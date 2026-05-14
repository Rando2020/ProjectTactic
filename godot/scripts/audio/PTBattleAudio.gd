extends Node
class_name PTBattleAudio


var manifest := {}


func load_manifest(path: String) -> void:
	var parsed := PTGameDatabase.read_json(path)
	if typeof(parsed) == TYPE_DICTIONARY:
		manifest = parsed


func play_sfx(sfx_id: String) -> void:
	# Stub for generated or recorded SFX. Keeping the hook here lets gameplay call audio now.
	print("SFX:", sfx_id)
