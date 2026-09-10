class_name BattleTelemetry
extends RefCounted

## Development-only battle observer for AI evaluation and future self-play.
##
## This recorder is intentionally passive. It connects to existing battle/unit signals,
## snapshots serializable state, and exports the shared ProjectTactic AI evidence shape.
## It never changes battle state, RNG, AI decisions, saves, or rendering.

const SCHEMA_VERSION := 1
const DEFAULT_OUTPUT_DIR := "user://ai-telemetry"

var _manager: Node = null
var _config: Dictionary = {}
var _events: Array[Dictionary] = []
var _tracked_units: Array[Node] = []
var _tracked_unit_ids: Dictionary = {}
var _last_hp: Dictionary = {}
var _initial_state: Dictionary = {}
var _final_state: Dictionary = {}
var _outcome := ""
var _started_tick_ms := 0
var _finished_tick_ms := 0
var _turn_count_player := 0
var _turn_count_enemy := 0
var _move_count := 0
var _decision_count := 0
var _enemy_intent_count := 0
var _status_application_count := 0
var _hp_lost_player_team := 0
var _hp_lost_enemy_team := 0
var _defeated_player_units := 0
var _defeated_enemy_units := 0


func attach(manager: Node, config: Dictionary = {}) -> void:
	if _manager != null:
		detach()
	_reset()
	_manager = manager
	_config = config.duplicate(true)
	_started_tick_ms = Time.get_ticks_msec()
	_connect_manager_signal("battle_started", "_on_battle_started")
	_connect_manager_signal("turn_started", "_on_turn_started")
	_connect_manager_signal("turn_ended", "_on_turn_ended")
	_connect_manager_signal("unit_moved", "_on_unit_moved")
	_connect_manager_signal("unit_defeated", "_on_unit_defeated")
	_connect_manager_signal("battle_won", "_on_battle_won")
	_connect_manager_signal("battle_lost", "_on_battle_lost")
	_connect_manager_signal("enemy_intent_changed", "_on_enemy_intent_changed")


func detach() -> void:
	if _manager != null:
		_disconnect_manager_signal("battle_started", "_on_battle_started")
		_disconnect_manager_signal("turn_started", "_on_turn_started")
		_disconnect_manager_signal("turn_ended", "_on_turn_ended")
		_disconnect_manager_signal("unit_moved", "_on_unit_moved")
		_disconnect_manager_signal("unit_defeated", "_on_unit_defeated")
		_disconnect_manager_signal("battle_won", "_on_battle_won")
		_disconnect_manager_signal("battle_lost", "_on_battle_lost")
		_disconnect_manager_signal("enemy_intent_changed", "_on_enemy_intent_changed")
	for unit in _tracked_units:
		_disconnect_unit_signal(unit, "hp_changed", "_on_hp_changed")
		_disconnect_unit_signal(unit, "status_applied", "_on_status_applied")
		_disconnect_unit_signal(unit, "status_removed", "_on_status_removed")
	_tracked_units.clear()
	_tracked_unit_ids.clear()
	_manager = null


func record_decision(
	actor_id: String,
	policy_id: String,
	action_id: String,
	target_id: String = "",
	target_position: Vector2i = Vector2i(-1, -1),
	expected_value: Variant = null,
	extra: Dictionary = {}
) -> void:
	_decision_count += 1
	var payload := {
		"actor_id": actor_id,
		"policy_id": policy_id,
		"action_id": action_id,
		"target_id": target_id,
		"target_position": _position_to_dict(target_position),
		"expected_value": expected_value,
		"extra": _json_safe(extra),
	}
	_record_event("decision", payload)


func record_checkpoint(label: String, extra: Dictionary = {}) -> void:
	_record_event("checkpoint", {
		"label": label,
		"units": _snapshot_units(),
		"extra": _json_safe(extra),
	})


func to_evidence() -> Dictionary:
	var scenario_id := str(_config.get("scenario_id", "unknown-scenario"))
	var seed: Variant = _config.get("seed", null)
	var build_sha := str(_config.get("build_sha", "unknown00"))
	var evidence_id := str(_config.get(
		"evidence_id",
		"battle-telemetry:%s:%s:%s" % [scenario_id, str(seed), str(_config.get("run_id", "local"))]
	))
	var completed_status := "pass" if not _outcome.is_empty() else "unknown"
	var identity_status := "pass" if scenario_id != "unknown-scenario" and seed != null else "unknown"
	var metrics := {
		"outcome": _outcome if not _outcome.is_empty() else "incomplete",
		"event_count": _events.size(),
		"turn_count_player": _turn_count_player,
		"turn_count_enemy": _turn_count_enemy,
		"move_count": _move_count,
		"decision_count": _decision_count,
		"enemy_intent_count": _enemy_intent_count,
		"status_application_count": _status_application_count,
		"hp_lost_player_team": _hp_lost_player_team,
		"hp_lost_enemy_team": _hp_lost_enemy_team,
		"defeated_player_units": _defeated_player_units,
		"defeated_enemy_units": _defeated_enemy_units,
	}
	if bool(_config.get("include_timing", false)) and _finished_tick_ms > 0:
		metrics["duration_ms"] = _finished_tick_ms - _started_tick_ms

	var observations: Array[Dictionary] = []
	if _decision_count == 0:
		observations.append({
			"id": "telemetry-no-explicit-decisions",
			"kind": "coverage",
			"severity": "info",
			"dimension": "discovery_coverage",
			"summary": "Battle events were captured, but no explicit policy decisions were recorded.",
			"evidence": "Attach record_decision calls from a self-play policy or decision adapter to measure action choice distributions.",
			"hypothesis": "Adding explicit decision records will unlock strategy-dominance and meaningful-turn evaluation.",
		})

	return {
		"schema_version": SCHEMA_VERSION,
		"evidence_id": evidence_id,
		"build_sha": build_sha,
		"source": str(_config.get("source", "godot_test")),
		"scenario_id": scenario_id,
		"seed": seed,
		"timestamp_utc": Time.get_datetime_string_from_system(true),
		"metrics": metrics,
		"checks": [
			{
				"name": "battle_telemetry_event_stream",
				"status": "pass" if _events.size() > 0 else "fail",
				"dimension": "correctness",
				"details": "%d structured events captured." % _events.size(),
			},
			{
				"name": "battle_completed",
				"status": completed_status,
				"dimension": "correctness",
				"details": "Outcome: %s" % (_outcome if not _outcome.is_empty() else "not observed"),
			},
			{
				"name": "deterministic_scenario_identity",
				"status": identity_status,
				"dimension": "discovery_coverage",
				"details": "scenario_id=%s seed=%s" % [scenario_id, str(seed)],
			},
		],
		"observations": observations,
		"context": {
			"policy_id": str(_config.get("policy_id", "observer-only")),
			"run_id": str(_config.get("run_id", "local")),
			"initial_state": _initial_state,
			"final_state": _final_state,
			"events": _events,
		},
	}


func export_evidence(path: String = "") -> String:
	var output_path := path
	if output_path.is_empty():
		var scenario := _safe_filename(str(_config.get("scenario_id", "unknown-scenario")))
		var seed := _safe_filename(str(_config.get("seed", "no-seed")))
		var run_id := _safe_filename(str(_config.get("run_id", "local")))
		var absolute_dir := ProjectSettings.globalize_path(DEFAULT_OUTPUT_DIR)
		var mkdir_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
		if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
			push_error("BattleTelemetry could not create output directory: %s" % absolute_dir)
			return ""
		output_path = "%s/%s-%s-%s.json" % [DEFAULT_OUTPUT_DIR, scenario, seed, run_id]
	else:
		var parent := output_path.get_base_dir()
		if not parent.is_empty():
			var absolute_parent := ProjectSettings.globalize_path(parent)
			var mkdir_error := DirAccess.make_dir_recursive_absolute(absolute_parent)
			if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
				push_error("BattleTelemetry could not create output directory: %s" % absolute_parent)
				return ""

	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("BattleTelemetry could not open output file: %s" % output_path)
		return ""
	file.store_string(JSON.stringify(to_evidence(), "  ", true))
	file.close()
	return output_path


func events() -> Array[Dictionary]:
	return _events.duplicate(true)


func _reset() -> void:
	_events.clear()
	_tracked_units.clear()
	_tracked_unit_ids.clear()
	_last_hp.clear()
	_initial_state.clear()
	_final_state.clear()
	_outcome = ""
	_started_tick_ms = 0
	_finished_tick_ms = 0
	_turn_count_player = 0
	_turn_count_enemy = 0
	_move_count = 0
	_decision_count = 0
	_enemy_intent_count = 0
	_status_application_count = 0
	_hp_lost_player_team = 0
	_hp_lost_enemy_team = 0
	_defeated_player_units = 0
	_defeated_enemy_units = 0


func _connect_manager_signal(signal_name: StringName, method_name: StringName) -> void:
	if _manager == null or not _manager.has_signal(signal_name):
		return
	var callback := Callable(self, method_name)
	if not _manager.is_connected(signal_name, callback):
		_manager.connect(signal_name, callback)


func _disconnect_manager_signal(signal_name: StringName, method_name: StringName) -> void:
	if _manager == null or not _manager.has_signal(signal_name):
		return
	var callback := Callable(self, method_name)
	if _manager.is_connected(signal_name, callback):
		_manager.disconnect(signal_name, callback)


func _connect_unit_signal(unit: Node, signal_name: StringName, method_name: StringName) -> void:
	if not unit.has_signal(signal_name):
		return
	var callback := Callable(self, method_name)
	if not unit.is_connected(signal_name, callback):
		unit.connect(signal_name, callback)


func _disconnect_unit_signal(unit: Variant, signal_name: StringName, method_name: StringName) -> void:
	# Defeated units can be freed before the observer detaches. Keep the argument
	# dynamic so a stale Object reference can be rejected before typed dispatch.
	if not is_instance_valid(unit) or not unit.has_signal(signal_name):
		return
	var callback := Callable(self, method_name)
	if unit.is_connected(signal_name, callback):
		unit.disconnect(signal_name, callback)


func _track_units() -> void:
	if _manager == null:
		return
	var raw_units: Variant = _manager.get("units")
	if typeof(raw_units) != TYPE_DICTIONARY:
		return
	for uid in raw_units:
		var candidate: Variant = raw_units[uid]
		if not candidate is Node:
			continue
		var unit := candidate as Node
		var instance_id := unit.get_instance_id()
		if _tracked_unit_ids.has(instance_id):
			continue
		_tracked_unit_ids[instance_id] = true
		_tracked_units.append(unit)
		_last_hp[str(unit.get("unit_id"))] = int(unit.get("hp"))
		_connect_unit_signal(unit, "hp_changed", "_on_hp_changed")
		_connect_unit_signal(unit, "status_applied", "_on_status_applied")
		_connect_unit_signal(unit, "status_removed", "_on_status_removed")


func _on_battle_started(display_name: String, objective: String) -> void:
	_track_units()
	_initial_state = _snapshot_units()
	_record_event("battle_started", {
		"display_name": display_name,
		"objective": objective,
		"units": _initial_state,
	})


func _on_turn_started(unit_id: String, team: String) -> void:
	if team == "player":
		_turn_count_player += 1
	elif team == "enemy":
		_turn_count_enemy += 1
	_record_event("turn_started", {
		"unit_id": unit_id,
		"team": team,
		"unit": _snapshot_unit_by_id(unit_id),
	})


func _on_turn_ended(unit_id: String) -> void:
	_record_event("turn_ended", {
		"unit_id": unit_id,
		"unit": _snapshot_unit_by_id(unit_id),
	})


func _on_unit_moved(unit_id: String, from: Vector2i, to: Vector2i) -> void:
	_move_count += 1
	_record_event("unit_moved", {
		"unit_id": unit_id,
		"from": _position_to_dict(from),
		"to": _position_to_dict(to),
		"distance": absi(to.x - from.x) + absi(to.y - from.y),
	})


func _on_unit_defeated(unit_id: String) -> void:
	var team := _team_for_unit(unit_id)
	if team == "player":
		_defeated_player_units += 1
	elif team == "enemy":
		_defeated_enemy_units += 1
	_record_event("unit_defeated", {
		"unit_id": unit_id,
		"team": team,
	})


func _on_battle_won(rewards: Dictionary) -> void:
	_outcome = "victory"
	_finished_tick_ms = Time.get_ticks_msec()
	_final_state = _snapshot_units()
	_record_event("battle_won", {
		"rewards": _json_safe(rewards),
		"units": _final_state,
	})


func _on_battle_lost() -> void:
	_outcome = "defeat"
	_finished_tick_ms = Time.get_ticks_msec()
	_final_state = _snapshot_units()
	_record_event("battle_lost", {
		"units": _final_state,
	})


func _on_enemy_intent_changed(intent: Dictionary) -> void:
	_enemy_intent_count += 1
	_record_event("enemy_intent", _json_safe(intent))


func _on_hp_changed(unit_id: String, new_hp: int, max_hp: int) -> void:
	var previous_hp := int(_last_hp.get(unit_id, new_hp))
	var hp_lost := maxi(previous_hp - new_hp, 0)
	var team := _team_for_unit(unit_id)
	if team == "player":
		_hp_lost_player_team += hp_lost
	elif team == "enemy":
		_hp_lost_enemy_team += hp_lost
	_last_hp[unit_id] = new_hp
	var last_ability := ""
	if _manager != null:
		var raw_ability: Variant = _manager.get("last_ability_used")
		if raw_ability != null:
			last_ability = str(raw_ability)
	_record_event("hp_changed", {
		"unit_id": unit_id,
		"team": team,
		"previous_hp": previous_hp,
		"new_hp": new_hp,
		"max_hp": max_hp,
		"hp_lost": hp_lost,
		"last_ability_used": last_ability,
	})


func _on_status_applied(unit_id: String, status_id: String) -> void:
	_status_application_count += 1
	_record_event("status_applied", {
		"unit_id": unit_id,
		"team": _team_for_unit(unit_id),
		"status_id": status_id,
	})


func _on_status_removed(unit_id: String, status_id: String) -> void:
	_record_event("status_removed", {
		"unit_id": unit_id,
		"team": _team_for_unit(unit_id),
		"status_id": status_id,
	})


func _record_event(event_type: String, payload: Dictionary) -> void:
	var event := {
		"seq": _events.size(),
		"type": event_type,
		"payload": _json_safe(payload),
	}
	if bool(_config.get("include_timing", false)) and _started_tick_ms > 0:
		event["elapsed_ms"] = Time.get_ticks_msec() - _started_tick_ms
	_events.append(event)


func _snapshot_units() -> Dictionary:
	var snapshot := {}
	if _manager == null:
		return snapshot
	var raw_units: Variant = _manager.get("units")
	if typeof(raw_units) != TYPE_DICTIONARY:
		return snapshot
	var ids: Array[String] = []
	for uid in raw_units:
		ids.append(str(uid))
	ids.sort()
	for uid in ids:
		var candidate: Variant = raw_units.get(uid)
		if candidate is Node:
			snapshot[uid] = _snapshot_unit(candidate as Node)
	return snapshot


func _snapshot_unit_by_id(unit_id: String) -> Dictionary:
	if _manager == null:
		return {}
	var raw_units: Variant = _manager.get("units")
	if typeof(raw_units) != TYPE_DICTIONARY:
		return {}
	var candidate: Variant = raw_units.get(unit_id)
	if candidate is Node:
		return _snapshot_unit(candidate as Node)
	return {}


func _snapshot_unit(unit: Node) -> Dictionary:
	var pos: Variant = unit.get("grid_pos")
	var position := {"x": -1, "y": -1}
	if pos is Vector2i:
		position = _position_to_dict(pos)
	return {
		"unit_id": str(unit.get("unit_id")),
		"team": str(unit.get("team")),
		"hp": int(unit.get("hp")),
		"mp": int(unit.get("mp")) if unit.get("mp") != null else 0,
		"temper": int(unit.get("temper")) if unit.get("temper") != null else 0,
		"ether": int(unit.get("ether")) if unit.get("ether") != null else 0,
		"ct": int(unit.get("ct")) if unit.get("ct") != null else 0,
		"position": position,
		"facing": str(unit.get("facing")) if unit.get("facing") != null else "",
		"job_id": str(unit.get("current_job_id")) if unit.get("current_job_id") != null else "",
	}


func _team_for_unit(unit_id: String) -> String:
	var snapshot := _snapshot_unit_by_id(unit_id)
	return str(snapshot.get("team", "unknown"))


func _position_to_dict(position: Vector2i) -> Dictionary:
	return {"x": position.x, "y": position.y}


func _json_safe(value: Variant) -> Variant:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_STRING_NAME:
			return str(value)
		TYPE_VECTOR2I:
			return _position_to_dict(value)
		TYPE_VECTOR2:
			return {"x": value.x, "y": value.y}
		TYPE_ARRAY:
			var out_array: Array = []
			for item in value:
				out_array.append(_json_safe(item))
			return out_array
		TYPE_DICTIONARY:
			var out_dict := {}
			var keys: Array[String] = []
			for key in value:
				keys.append(str(key))
			keys.sort()
			for key in keys:
				out_dict[key] = _json_safe(value.get(key))
			return out_dict
		_:
			return str(value)


func _safe_filename(value: String) -> String:
	var result := value.to_lower()
	for character in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|", " "]:
		result = result.replace(character, "-")
	return result
