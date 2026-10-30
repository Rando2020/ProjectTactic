extends "res://scripts/vfx/BattleJuiceEffects.gd"
## Proof-local bridge to the current production API: BattleManager owns units.
## Never retain actors/camera from an earlier battle across replay/exit.

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _current_unit(unit_id: String) -> Unit:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene): return null
	var manager := scene.get_node_or_null("BattleManager")
	if manager == null or not manager is BattleManager: return null
	var unit = manager.units.get(unit_id)
	return unit if is_instance_valid(unit) and not unit.is_queued_for_deletion() else null

func trigger_flash(unit_id: String, duration_ms: int = 300) -> void:
	var unit := _current_unit(unit_id)
	if unit == null: return
	var visual := unit.visual as CanvasItem
	if not is_instance_valid(visual): return
	visual.self_modulate = Color(1.4, 1.3, 0.9, 1)
	# Actor-owned tween is discarded with its actor, so an old effect cannot
	# recolor the same ID's replacement in a later encounter.
	var tween := visual.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(visual, "self_modulate", Color.WHITE, float(duration_ms) / 1000.0)

func _update_unit_flash_state(unit_id: String, is_flashing: bool) -> void:
	var unit := _current_unit(unit_id)
	if unit != null and is_instance_valid(unit.visual):
		unit.visual.self_modulate = Color(1.4, 1.3, 0.9, 1) if is_flashing else Color.WHITE

func trigger_wobble(unit_id: String, duration_ms: int = 150) -> void:
	var unit := _current_unit(unit_id)
	if unit == null: return
	var visual := unit.visual as Node2D
	if not is_instance_valid(visual): return
	var rest := visual.scale
	var tween := visual.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var duration := float(duration_ms) / 1000.0
	tween.tween_property(visual, "scale", rest * 1.10, duration * 0.25)
	tween.tween_property(visual, "scale", rest, duration * 0.75)

func trigger_shake(intensity: int = 4, duration_ms: int = 150) -> void:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene) or not scene.has_method("_camera_shake"): return
	# Shared scene's existing camera shake owns/restores its base position.
	scene._camera_shake(float(intensity), float(duration_ms) / 1000.0)
