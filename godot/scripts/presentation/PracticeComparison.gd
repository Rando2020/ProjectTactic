## Local-only practice comparison controls. Never writes canonical save state.
extends CanvasLayer

const UISettings := preload("res://scripts/ui/UISettings.gd")

const SAMPLE_LIMIT := 180
var manager: BattleManager
var toggle: Button
var quality_toggle: Button
var terrain_toggle: Button
var readout: Label
var samples: Array[float] = []
var last_tick := 0
var warmup_until := 0
var focused := true
var report_elapsed := 0.0

func _ready() -> void:
	layer = 25
	var panel := PanelContainer.new()
	panel.theme = preload("res://scripts/ui/AppointedTheme.gd").build()
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(290, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var reveal := Button.new()
	reveal.text = "View & quality settings"
	box.add_child(reveal)
	var options := VBoxContainer.new()
	options.visible = false
	box.add_child(options)
	reveal.pressed.connect(func() -> void: options.visible = not options.visible)
	box = options
	UISettings.shared().add_selector(box)
	toggle = Button.new()
	toggle.custom_minimum_size.y = 36
	toggle.pressed.connect(switch_mode)
	box.add_child(toggle)
	terrain_toggle = Button.new()
	terrain_toggle.custom_minimum_size.y = 36
	terrain_toggle.pressed.connect(switch_terrain)
	box.add_child(terrain_toggle)
	manager.tactical_grid.set_terrain_3d(bool(GameState.practice_session.get("terrain3d", GameState.practice_session.get("rig3d", false))))
	quality_toggle = Button.new()
	quality_toggle.custom_minimum_size.y = 36
	quality_toggle.pressed.connect(switch_quality)
	box.add_child(quality_toggle)
	readout = Label.new()
	readout.add_theme_font_size_override("font_size", 14)
	readout.tooltip_text = "Rolling wall-clock frame intervals, not GPU time. Compare the same camera and actions. Switching clears samples and waits one second."
	box.add_child(readout)
	var reset := Button.new()
	reset.text = "Reset timing sample"
	reset.pressed.connect(reset_samples)
	box.add_child(reset)
	reset_samples()
	_update_controls()
	UISettings.shared().changed.connect(_apply_ui_size)
	get_viewport().size_changed.connect(_apply_ui_size)
	_apply_ui_size()

func can_switch() -> bool:
	return is_instance_valid(manager) and not manager.is_resolving_action and manager.current_phase == BattleManager.Phase.PLAYER_TURN and not GameState.practice_session.is_empty()

func switch_mode() -> bool:
	if not can_switch():
		return false
	var enabled := not bool(GameState.practice_session.get("rig3d", false))
	# Remove old viewports synchronously from their tree before creating replacements.
	for unit: Unit in manager.units.values():
		if is_instance_valid(unit) and unit.supports_3d_presentation() and not unit.is_defeated:
			if enabled:
				unit.enable_3d_prototype()
			else:
				unit.disable_3d_prototype()
	GameState.practice_session["rig3d"] = enabled
	reset_samples()
	_update_controls()
	return true

func switch_terrain() -> bool:
	if not can_switch(): return false
	var enabled := not is_instance_valid(manager.tactical_grid.terrain_view)
	manager.tactical_grid.set_terrain_3d(enabled)
	GameState.practice_session["terrain3d"] = enabled
	reset_samples()
	_update_controls()
	return true

func switch_quality() -> bool:
	if not can_switch(): return false
	var enabled := not bool(GameState.practice_session.get("high_quality", false))
	GameState.practice_session["high_quality"] = enabled
	var terrain = manager.tactical_grid.terrain_view
	if is_instance_valid(terrain): terrain.set_high_quality(enabled)
	for unit: Unit in manager.units.values():
		if is_instance_valid(unit) and is_instance_valid(unit._rig3d):
			unit._rig3d.set_high_quality(enabled)
	reset_samples()
	_update_controls()
	return true

func reset_samples() -> void:
	samples.clear()
	last_tick = 0
	warmup_until = Time.get_ticks_usec() + 1000000
	if is_instance_valid(readout):
		readout.text = "Frame intervals: warming up...\nSwitch during your idle turn."

func record_interval(milliseconds: float) -> void:
	if milliseconds <= 0.0:
		return
	samples.append(milliseconds)
	if samples.size() > SAMPLE_LIMIT:
		samples.pop_front()

func timing_summary() -> Dictionary:
	if samples.is_empty():
		return {}
	var total := 0.0
	var worst := 0.0
	for value in samples:
		total += value
		worst = maxf(worst, value)
	return {"mean_ms": total / samples.size(), "worst_ms": worst, "frames": samples.size()}

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused = false
		reset_samples()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true
		reset_samples()

func _process(delta: float) -> void:
	_update_controls()
	var tick := Time.get_ticks_usec()
	if focused and tick >= warmup_until and last_tick > 0:
		record_interval(float(tick - last_tick) / 1000.0)
	last_tick = tick if focused and tick >= warmup_until else 0
	report_elapsed += delta
	if report_elapsed < 0.5:
		return
	report_elapsed = 0
	var summary := timing_summary()
	if not summary.is_empty():
		readout.text = "Frames: %.1f ms avg / %.1f ms worst\n%d samples | not GPU timing" % [summary.mean_ms, summary.worst_ms, summary.frames]

func _update_controls() -> void:
	if not is_instance_valid(toggle):
		return
	var enabled := bool(GameState.practice_session.get("rig3d", false))
	toggle.text = "3D active → Show sprites" if enabled else "Sprites active → Show 3D"
	toggle.disabled = not can_switch()
	if is_instance_valid(quality_toggle):
		quality_toggle.text = "Quality: High → Standard" if bool(GameState.practice_session.get("high_quality", false)) else "Quality: Standard → High"
		quality_toggle.disabled = not can_switch()
	if is_instance_valid(terrain_toggle):
		var view = manager.tactical_grid.terrain_view
		terrain_toggle.text = "Terrain: 3D → Show 2D" if is_instance_valid(view) else "Terrain: 2D → Show 3D"
		if is_instance_valid(view) and not view.visible:
			terrain_toggle.text = "Terrain fallback (missing mesh) → Disable 3D"
		terrain_toggle.disabled = not can_switch()


func _apply_ui_size() -> void:
	UISettings.shared().apply_tree(self, get_viewport().get_visible_rect().size)
