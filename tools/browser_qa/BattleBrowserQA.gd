extends Node
## Test-only observer. Staged for QA export; never part of the production project.
## No commands, setters, synthetic Godot input, or callable JavaScript callbacks.

@onready var battle: BattleScene = get_parent()
const EVIDENCE_LIMIT := 512
var _events: Array[Dictionary] = []
var _samples: Array[Dictionary] = []
var _sample_counts: Dictionary = {}
var _rig_connections: Dictionary = {}
var _overflow := false

func _ready() -> void:
	var manager: BattleManager = battle.get_node("BattleManager")
	manager.combat_resolver.combat_resolved.connect(_on_outcome)
	var effects := get_node_or_null("/root/VFX")
	if effects != null:
		effects.child_entered_tree.connect(_on_presenter_added)

func _on_presenter_added(owner: Node) -> void:
	if owner.has_signal("phase_presented") and owner.has_signal("cue_started"):
		owner.phase_presented.connect(_on_presentation_signal.bind("phase", weakref(owner)))
		owner.cue_started.connect(_on_presentation_signal.bind("cue", weakref(owner)))

func _retain(destination: Array[Dictionary], value: Dictionary) -> void:
	if destination.size() >= EVIDENCE_LIMIT:
		_overflow = true
		return
	destination.append(value)

func _on_presentation_signal(value: String, kind: String, reference: WeakRef) -> void:
	var owner = reference.get_ref()
	if not is_instance_valid(owner): return
	var context: Dictionary = owner.context
	_retain(_events, {"frame": Engine.get_process_frames(), "key": str(context.get("action_key", "")),
		"actor_id": context.get("actor_id", ""), "ability_id": context.get("ability_id", ""),
		"kind": kind, "value": value})

func _on_outcome(result: Dictionary) -> void:
	var context: Dictionary = battle.get_node("BattleManager")._action_presentation_context
	if context.is_empty(): return
	_retain(_events, {"frame": Engine.get_process_frames(), "key": str(context.action_key),
		"kind": "outcome", "result": result.duplicate(true)})

func _on_step(cue: String, identity: String) -> void:
	_retain(_events, {"frame": Engine.get_process_frames(), "key": "walk:" + identity,
		"kind": "cue", "value": cue, "actor_id": "zane", "ability_id": ""})

func _zane_unit() -> Unit:
	for unit: Unit in battle.get_node("BattleManager").units.values():
		if is_instance_valid(unit) and unit.unit_id == "zane": return unit
	return null

func _hand(unit: Unit) -> Vector2:
	# Read existing socket transforms. Do NOT call hand_world_position(): that
	# convenience getter forces bone updates; the observer must not do so.
	var rig = unit._rig3d
	if is_instance_valid(rig) and is_instance_valid(rig.cast_socket):
		return rig.output.to_global(rig.camera.unproject_position(rig.cast_socket.global_position))
	return unit.global_position

func _owners() -> Array[Node]:
	var result: Array[Node] = []
	var effects := get_node_or_null("/root/VFX")
	if effects == null: return result
	for owner in effects.get_children():
		if owner.has_signal("phase_presented") and not owner.is_queued_for_deletion(): result.append(owner)
	return result

func _observe_presentations() -> void:
	var unit := _zane_unit()
	if is_instance_valid(unit) and unit.has_zane_impact_presentation():
		var rig = unit._rig3d
		var identity := str(rig.get_instance_id())
		if not _rig_connections.has(identity):
			rig.cue_started.connect(_on_step.bind(identity))
			_rig_connections[identity] = true
	for owner in _owners():
		var context: Dictionary = owner.context
		if context.is_empty(): continue
		for child in owner.get_children():
			if not child is CanvasItem or child.is_queued_for_deletion() or not child.is_visible_in_tree(): continue
			var role := str(child.get_meta("zane_effect_role", ""))
			if role not in ["charge", "projectile", "outcome"]: continue
			var identity := str(child.get_instance_id())
			var count := int(_sample_counts.get(identity, 0))
			if count >= (1 if role == "outcome" else 8): continue
			_sample_counts[identity] = count + 1
			var sample := {"frame": Engine.get_process_frames(), "key": str(context.action_key), "role": role,
				"instance_id": identity, "point": _point(child.global_position)}
			if role == "outcome": sample["text"] = child.text
			elif is_instance_valid(unit): sample["hand"] = _point(_hand(unit))
			if role == "projectile": sample["origin"] = _point(owner.to_global(owner._flight_start))
			_retain(_samples, sample)

func _zane_snapshot() -> Dictionary:
	var manager: BattleManager = battle.get_node("BattleManager")
	var unit := _zane_unit()
	var profile := {}
	if is_instance_valid(unit) and unit.has_zane_impact_presentation():
		var rig = unit._rig3d
		profile = {"available": rig.is_available(), "profile_id": rig.profile_id, "asset_path": rig.asset_path,
			"model_sha256": rig.metadata.get("model_sha256", ""), "model_instance_id": str(rig.model.get_instance_id()),
			"skeleton_bones": rig.skeleton.get_bone_count(), "output_visible": rig.output.is_visible_in_tree(),
			"state": rig.state, "hand": _point(_hand(unit)), "walk_distance_px": rig.walk_distance_px}
	var reaction_marks := 0
	for candidate: Unit in manager.units.values():
		if is_instance_valid(candidate) and candidate.visual.has_meta(&"zane_impact_reaction"): reaction_marks += 1
	var cleanup := {"reaction_marks": reaction_marks, "camera_kick_remaining": battle._zane_kick_remaining,
		"rig_state": str(profile.get("state", "unavailable"))}
	var owners: Array = []
	for owner in _owners():
		var roles: Array[String] = []
		var voices := 0
		for child in owner.get_children():
			if child is CanvasItem and not child.is_queued_for_deletion(): roles.append(str(child.get_meta("zane_effect_role", "")))
			if child is AudioStreamPlayer and child.playing: voices += 1
		owners.append({"key": str(owner.context.get("action_key", "")), "roles": roles, "playing_voices": voices})
	return {"profile": profile, "lifecycle": {"ticket": manager.action_lifecycle.ticket, "phase": manager.action_lifecycle.phase},
		"cleanup": cleanup, "owners": owners, "events": _events.duplicate(true), "samples": _samples.duplicate(true), "overflow": _overflow}

func _process(_delta: float) -> void:
	_observe_presentations()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__projectTacticQA = " + JSON.stringify(snapshot()) + ";", true)

func _point(value: Vector2) -> Array:
	return [value.x, value.y]

func _label(label: Label) -> Dictionary:
	return {"instance_id": str(label.get_instance_id()),
		"text": label.text, "visible": label.is_visible_in_tree()}

func _button(button: Button) -> Dictionary:
	var labels: Array[String] = [button.text]
	for label: Label in button.find_children("*", "Label", true, false):
		labels.append(label.text)
	var transform := button.get_global_transform_with_canvas()
	var start: Vector2 = transform * Vector2.ZERO
	var end: Vector2 = transform * button.size
	return {
		"rect": [start.x, start.y, end.x - start.x, end.y - start.y],
		"visible": button.is_visible_in_tree(),
		"disabled": button.disabled, "labels": labels,
	}

func snapshot() -> Dictionary:
	var manager: BattleManager = battle.battle_manager
	var ui: BattleUI = battle.battle_ui
	var grid: TacticalGrid = battle.tactical_grid
	var unit: Unit = manager.units.get(manager.active_unit_id)
	var unit_state := {}
	if is_instance_valid(unit):
		unit_state = _unit_record(unit)
		unit_state["moved"] = manager.active_unit_has_moved
		unit_state["acted"] = manager.active_unit_has_acted
	var roster := {}
	for candidate: Unit in manager.units.values():
		if is_instance_valid(candidate):
			roster[str(candidate.get_instance_id())] = _unit_record(candidate)
	var abilities: Array = []
	for child in ui._ability_list.get_children():
		if child is Button and not child.is_queued_for_deletion():
			abilities.append(_button(child))
	var legal_moves: Array = []
	for pos: Vector2i in grid.move_tiles:
		if grid.unit_positions.has(pos):
			continue
		var center: Vector2 = grid.get_global_transform_with_canvas() * grid._grid_to_local(pos)
		legal_moves.append({"position": [pos.x, pos.y], "point": _point(center)})
	var legal_targets: Array = []
	for candidate: Unit in manager.units.values():
		if is_instance_valid(candidate) and candidate.hp > 0 and candidate.grid_pos in grid.ability_tiles:
			var target := _unit_record(candidate)
			target["point"] = _point(grid.get_global_transform_with_canvas() * grid._grid_to_local(candidate.grid_pos))
			legal_targets.append(target)
	return {
		"zane": _zane_snapshot(), "legal_ability_targets": legal_targets,
		"schema": 2, "frame": Engine.get_process_frames(),
		"viewport": _point(get_viewport().get_visible_rect().size),
		"phase": BattleManager.Phase.keys()[manager.current_phase],
		"unit": unit_state, "roster": roster, "player_turn_serial": manager._player_turn_serial,
		"active_hud": {"name": _label(ui._unit_name), "mp": _label(ui._mp_label)},
		"command": manager.active_command,
		"ability_id": manager.selected_ability_id, "resolving": manager.is_resolving_action,
		"menu_visible": ui._ability_panel.is_visible_in_tree(),
		"intro_visible": ui._intro_banner.is_visible_in_tree(),
		"buttons": {"ability": _button(ui._ability_btn), "cancel": _button(ui._cancel_btn), "move": _button(ui._move_btn), "attack": _button(ui._attack_btn), "wait": _button(ui._wait_btn)},
		"abilities": abilities, "legal_moves": legal_moves,
		"highlights": {"ability": grid.ability_tiles.size(), "move": grid.move_tiles.size(),
			"attack": grid.attack_tiles.size(), "aoe": grid.aoe_preview_tiles.size(), "path": grid.path_preview_tiles.size()},
	}

func _unit_record(unit: Unit) -> Dictionary:
	return {
		"instance_id": str(unit.get_instance_id()), "id": unit.unit_id, "team": unit.team, "temper": unit.temper, "ether": unit.ether,
		"position": [unit.grid_pos.x, unit.grid_pos.y], "hp": unit.hp, "mp": unit.mp,
	}
