extends Node
## Read-only test instrumentation. This directory is absent from production exports.

var _events: Array[Dictionary] = []
var _animation_samples: Array[Dictionary] = []
var _presenters: Array[WeakRef] = []
var _sampled_stages: Dictionary = {}

func _ready() -> void:
	# node_added fires before present(), so even the first cast phase is captured.
	get_tree().node_added.connect(_observe_node)

func _observe_node(node: Node) -> void:
	if node.has_signal("phase_presented") and node.has_signal("cue_started"):
		_presenters.append(weakref(node))
		node.phase_presented.connect(_record_event.bind("phase", node))
		node.cue_started.connect(_record_event.bind("cue", node))

func _record_event(value: String, kind: String, presenter: Node) -> void:
	var context: Dictionary = presenter.context
	var actor = presenter._actor.get_ref() if presenter._actor != null else null
	var effects: Array[String] = []
	var visuals: Array[Dictionary] = []
	var voices: Array[Dictionary] = []
	for child in presenter.get_children():
		if child is CanvasItem and child.is_visible_in_tree() and not child.is_queued_for_deletion():
			var role := str(child.get_meta("zane_effect_role", ""))
			if not role.is_empty(): effects.append(role)
			if child.has_method("available") and child.has_method("show_progress"):
				visuals.append({"stage": str(child.stage), "available": child.available(),
					"progress": float(child.progress) if "progress" in child else -1.0,
					"frame_index": int(child.frame_index) if "frame_index" in child else -1})
		if child is AudioStreamPlayer:
			voices.append({"playing": child.playing, "bus": str(child.bus), "stream": child.stream != null})
	var pose := ""
	if is_instance_valid(actor) and is_instance_valid(actor._rig3d): pose = str(actor._rig3d.state)
	_events.append({"frame": Engine.get_process_frames(), "kind": kind, "name": value,
		"action_key": str(context.get("action_key", "")), "ability_id": str(context.get("ability_id", "")),
		"actor_id": str(context.get("actor_id", "")), "pose": pose, "effects": effects, "visuals": visuals, "voices": voices})

func _sample_animation() -> void:
	for reference in _presenters:
		var presenter = reference.get_ref()
		if not is_instance_valid(presenter): continue
		for child in presenter.get_children():
			if not child is CanvasItem or not child.is_visible_in_tree() or child.is_queued_for_deletion(): continue
			if not child.has_method("available") or not "progress" in child: continue
			var key := str(presenter.context.get("action_key", ""))
			var stage := str(child.stage)
			var sample_key := key + ":" + stage
			if float(child.progress) < 0.25 or _sampled_stages.has(sample_key): continue
			_sampled_stages[sample_key] = true
			_animation_samples.append({"action_key": key, "stage": stage, "progress": float(child.progress),
				"available": child.available(), "frame": Engine.get_process_frames()})
	_presenters = _presenters.filter(func(reference): return is_instance_valid(reference.get_ref()))

func unit_record(member) -> Dictionary:
	var statuses: Array[String] = []
	for status in member.statuses: statuses.append(str(status.status_id))
	return {"position": [member.grid_pos.x, member.grid_pos.y], "hp": member.hp,
		"mp": member.mp, "team": member.team, "statuses": statuses}

func _process(_delta: float) -> void:
	_sample_animation()
	if not OS.has_feature("web"):
		return
	var state = snapshot()
	if not state.is_empty():
		JavaScriptBridge.eval("window.__courtyardQA = " + JSON.stringify(state) + ";", true)

func button_record(button: BaseButton) -> Dictionary:
	var rect: Rect2 = button.get_global_rect()
	return {"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"visible": button.is_visible_in_tree(), "disabled": button.disabled}

func menu_records(ui) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if not ui._ability_panel.is_visible_in_tree(): return records
	for child in ui._ability_list.get_children():
		if not child is Button or child.is_queued_for_deletion(): continue
		var record := button_record(child)
		record["ability_id"] = str(child.get_meta("ability_id", ""))
		record["magic_school"] = str(child.get_meta("magic_school", ""))
		record["text"] = child.text
		records.append(record)
	return records

func snapshot() -> Dictionary:
	var battle = get_tree().current_scene
	if not is_instance_valid(battle) or not (battle is BattleScene):
		return {}
	var manager = battle.battle_manager
	var ui = battle.battle_ui
	if not is_instance_valid(manager) or not is_instance_valid(ui) or not is_instance_valid(ui._selection):
		return {}
	var unit = manager.units.get(manager.active_unit_id)
	if not is_instance_valid(unit):
		return {}
	var selection = ui._selection
	var focused = get_viewport().gui_get_focus_owner()
	var units: Dictionary = {}
	for id in manager.units:
		var member = manager.units[id]
		if is_instance_valid(member):
			units[id] = unit_record(member)
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	return {
		"schema": 3, "frame": Engine.get_process_frames(), "viewport": [viewport.x, viewport.y],
		"scene": battle.scene_file_path, "unit_count": manager.units.size(),
		"units": units, "events": _events.duplicate(true), "animation_samples": _animation_samples.duplicate(true),
		"phase": BattleManager.Phase.keys()[manager.current_phase], "resolving": manager.is_resolving_action,
		"selected": selection.selected_id, "command": manager.active_command,
		"review": selection.has_review(), "settings": ui._settings_overlay.visible,
		"waiting_facing": selection._waiting_facing,
		"category": ui._command_category, "school": ui._magic_school,
		"ability_id": manager.selected_ability_id,
		"menu_visible": ui._ability_panel.is_visible_in_tree(), "entries": menu_records(ui),
		"focus": {"ability_id": str(focused.get_meta("ability_id", "")),
			"magic_school": str(focused.get_meta("magic_school", ""))} if focused else {},
		"cursor": [selection.cursor_cell.x, selection.cursor_cell.y],
		"unit": {"id": unit.unit_id, "position": [unit.grid_pos.x, unit.grid_pos.y],
			"hp": unit.hp, "mp": unit.mp, "moved": manager.active_unit_has_moved,
			"acted": manager.active_unit_has_acted, "abilities": unit.unit_data.abilities.duplicate()},
		"confirm": button_record(ui._confirm_btn),
		"buttons": {"magic": button_record(ui._magic_btn), "skills": button_record(ui._ability_btn),
			"back": button_record(ui._cancel_btn), "wait": button_record(ui._wait_btn)},
	}
