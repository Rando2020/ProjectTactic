## BattleJuiceEffects.gd
## Visual feedback system for combat actions - FFT/Disgaea style polish
## Provides: hit pauses, target flashes, camera shake, impact wobble
## Autoloaded as BattleJuiceEffects. Call via the singleton:
## BattleJuiceEffects.trigger_hit(...)

extends Node

## Intensity presets for hit effects
const INTENSITY_PRESETS = {
	"light": {"shake": 2, "wobble": 0.1, "pause": 60},
	"normal": {"shake": 4, "wobble": 0.15, "pause": 80},
	"heavy": {"shake": 6, "wobble": 0.2, "pause": 100},
	"critical": {"shake": 8, "wobble": 0.25, "pause": 120},
}

var _is_paused: bool = false
var _camera: Camera2D
var _tactical_grid: Node
var _flashing_units: Dictionary = {}  # unit_id -> end_time
var _wobbling_units: Dictionary = {}  # unit_id -> tween


func _ready() -> void:
	# Get camera reference (will be in BattleScene)
	_camera = get_tree().root.get_node_or_null("BattleScene/Camera2D")
	_tactical_grid = get_tree().root.get_node_or_null("BattleScene/BattleManager/TacticalGrid")


func _process(_delta: float) -> void:
	# Update flashing units (remove expired ones)
	var now = Time.get_ticks_msec() / 1000.0
	for unit_id in _flashing_units.keys():
		if _flashing_units[unit_id] < now:
			_flashing_units.erase(unit_id)
			_update_unit_flash_state(unit_id, false)


## Main entry point: trigger all effects for a hit
func trigger_hit(target_unit_ids: Array, intensity: String = "normal",
		pause_duration: int = 80, flash_duration: int = 300,
		shake_duration: int = 150) -> void:

	var preset = INTENSITY_PRESETS.get(intensity, INTENSITY_PRESETS["normal"])

	# Trigger pause (brief freeze)
	trigger_pause(pause_duration)

	# Flash targets
	for unit_id in target_unit_ids:
		trigger_flash(unit_id, flash_duration)

	# Camera shake
	trigger_shake(preset["shake"], shake_duration)

	# Wobble each target
	for unit_id in target_unit_ids:
		trigger_wobble(unit_id, shake_duration)


## Hit pause - freezes physics/animations briefly
func trigger_pause(duration_ms: int = 80) -> void:
	_is_paused = true
	get_tree().paused = true

	# This timer must process while the tree is paused, or combat can freeze forever.
	await get_tree().create_timer(duration_ms / 1000.0, true, false, true).timeout
	get_tree().paused = false
	_is_paused = false


## Target flash - golden glow effect
func trigger_flash(unit_id: String, duration_ms: int = 300) -> void:
	if not _tactical_grid:
		return

	var unit = _unit_node(unit_id)
	if not unit:
		return

	# Record flash time
	var now = Time.get_ticks_msec() / 1000.0
	_flashing_units[unit_id] = now + (duration_ms / 1000.0)
	_update_unit_flash_state(unit_id, true)

	# Animated fade out
	await get_tree().create_timer(duration_ms / 1000.0, true, false, true).timeout
	if _flashing_units.get(unit_id, -1) > now + (duration_ms / 1000.0) - 0.01:
		_update_unit_flash_state(unit_id, false)


## Apply visual flash to a unit (modulate effect)
func _update_unit_flash_state(unit_id: String, is_flashing: bool) -> void:
	if not _tactical_grid:
		return

	var unit = _unit_node(unit_id)
	if not unit or not unit.visual:
		return

	if is_flashing:
		# Golden glow + brightness boost
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		unit.visual.modulate = Color(1.4, 1.3, 0.9, 1.0)
		tween.tween_property(unit.visual, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	else:
		# Reset to normal
		unit.visual.self_modulate = Color(1.0, 1.0, 1.0, 1.0)


## Camera shake - screenshake effect with damping
func trigger_shake(intensity: int = 4, duration_ms: int = 150) -> void:
	if not _camera:
		return

	var start_pos = _camera.global_position
	var steps = int(duration_ms / 30.0)

	for i in range(steps):
		if not is_instance_valid(_camera):
			return

		var progress = float(i) / float(steps)
		var damping = 1.0 - progress  # Reduce shake over time

		# Random offset each frame
		var offset_x = randf_range(-1.0, 1.0) * intensity * damping
		var offset_y = randf_range(-1.0, 1.0) * intensity * damping

		_camera.global_position = start_pos + Vector2(offset_x, offset_y)

		await get_tree().create_timer(0.03, true, false, true).timeout

	# Restore original position
	if is_instance_valid(_camera):
		_camera.global_position = start_pos


## Impact wobble - scale + rotation bounce effect
func trigger_wobble(unit_id: String, duration_ms: int = 150) -> void:
	if not _tactical_grid:
		return

	var unit = _unit_node(unit_id)
	if not unit or not unit.visual:
		return

	# Cancel any existing wobble tween
	if unit_id in _wobbling_units:
		var existing_tween = _wobbling_units[unit_id]
		if existing_tween and existing_tween.is_valid():
			existing_tween.kill()

	var visual = unit.visual
	var duration = duration_ms / 1000.0
	var original_scale = visual.scale

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	_wobbling_units[unit_id] = tween

	# Compress, then expand with slight overshoot
	tween.tween_property(visual, "scale", original_scale * Vector2(1.15, 1.15), duration * 0.2)
	tween.tween_property(visual, "scale", original_scale * Vector2(0.95, 0.95), duration * 0.3)
	tween.tween_property(visual, "scale", original_scale, duration * 0.5)

	tween.tween_callback(func() -> void:
		_wobbling_units.erase(unit_id)
		visual.scale = original_scale
	)


## Check if currently in pause state
func is_paused() -> bool:
	return _is_paused


## Get set of currently flashing unit IDs
func get_flashing_units() -> Array:
	return _flashing_units.keys()


func _unit_node(unit_id: String) -> Unit:
	if not _tactical_grid or not is_instance_valid(_tactical_grid):
		return null
	var layer: Node = _tactical_grid.get_node_or_null("UnitLayer")
	if not layer:
		return null
	for child in layer.get_children():
		if child is Unit and child.get("unit_id") == unit_id:
			return child as Unit
	return null
