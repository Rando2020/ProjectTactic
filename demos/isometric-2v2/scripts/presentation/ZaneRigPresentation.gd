## Original Zane profile using the same authored rig and presentation contract.
extends "res://scripts/presentation/SharedRigPresentation.gd"

const MODEL_PATH := "res://assets/3d/characters/zane_v2/zane_v2.glb"

func _init() -> void:
	skin_id = "zane"
	asset_path = MODEL_PATH
	cast_socket_name = "Kael_v2_cast_socket" # Authored shared-rig socket, not character identity.
