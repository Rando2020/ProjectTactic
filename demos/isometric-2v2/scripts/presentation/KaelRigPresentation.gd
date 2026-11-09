## Compatibility profile; all presentation behavior lives in the shared adapter.
extends "res://scripts/presentation/SharedRigPresentation.gd"

const MODEL_PATH := "res://assets/3d/characters/kael_v2/kael_v2.glb"

func _init() -> void:
	skin_id = "kael"
	asset_path = MODEL_PATH
	cast_socket_name = "Kael_v2_cast_socket"
