class_name SelfPlayController
extends RefCounted

signal stalled(reason: String)

var _manager: BattleManager = null
var _policy: RefCounted = null
var _telemetry: BattleTelemetry = null
var _surface := SelfPlayDecisionSurface.new()
var _max_player_turns := 120
var _player_turns := 0
var _driving := false
var _stopped := false
var _pending_player_unit_id := ""


func attach(
	manager: BattleManager,
	policy: RefCounted,
	telemetry: BattleTelemetry,
	max_player_turns: int = 120
) -> void:
	detach()
	_manager = manager
	_policy = policy
	_telemetry = telemetry
	_max_player_turns = maxi(max_player_turns, 1)
	_player_turns = 0
	_driving = false
	_stopped = false
	_pending_player_unit_id = ""
	# Disable the legacy built-in auto player only for this explicit self-play run.
	_manager.auto_battle_enabled = false
	if not _manager.turn_started.is_connected(_on_turn_started):
		_manager.turn_started.connect(_on_turn_started)
	if not _manager.battle_won.is_connected(_on_battle_finished):
		_manager.battle_won.connect(_on_battle_finished)
	if not _manager.battle_lost.is_connected(_on_battle_lost):
		_manager.battle_lost.connect(_on_battle_lost)


func detach() -> void:
	if _manager != null and is_instance_valid(_manager):
		if _manager.turn_started.is_connected(_on_turn_started):
			_manager.turn_started.disconnect(_on_turn_started)
		if _manager.battle_won.is_connected(_on_battle_finished):
			_manager.battle_won.disconnect(_on_battle_finished)
		if _manager.battle_lost.is_connected(_on_battle_lost):
			_manager.battle_lost.disconnect(_on_battle_lost)
	_manager = null
	_policy = null
	_telemetry = null
	_driving = false
	_stopped = true
	_pending_player_unit_id = ""


func player_turn_count() -> int:
	return _player_turns


func _on_turn_started(unit_id: String, team: String) -> void:
	if _stopped or team != "player":
		return
	_player_turns += 1
	if _player_turns > _max_player_turns:
		_stopped = true
		_pending_player_unit_id = ""
		stalled.emit("Exceeded %d player turns without battle completion." % _max_player_turns)
		return
	# BattleManager can synchronously resolve a Wait/Attack into the next unit's
	# turn before the current self-play coroutine has unwound. Preserve that turn
	# instead of dropping it while `_driving` is true.
	if _driving:
		_pending_player_unit_id = unit_id
		return
	_drive_turn.call_deferred(unit_id)


func _drive_turn(unit_id: String) -> void:
	if _stopped or _manager == null or _policy == null:
		return
	_driving = true
	# One normal turn can contain a move followed by an attack or wait.
	for _step in range(3):
		if _stopped or _manager.current_phase != BattleManager.Phase.PLAYER_TURN:
			break
		if _manager.active_unit_id != unit_id:
			break
		var actions := _surface.legal_actions(_manager)
		if actions.is_empty():
			_stopped = true
			stalled.emit("No legal action was available for active player unit %s." % unit_id)
			break
		var action: Dictionary = _policy.call("choose_action", actions)
		if action.is_empty():
			_stopped = true
			stalled.emit("Policy returned no action for active player unit %s." % unit_id)
			break
		_record_decision(unit_id, action, actions.size())
		await _surface.execute_action(_manager, action)
		if _manager != null and is_instance_valid(_manager):
			await _manager.get_tree().process_frame
		if str(action.get("kind", "")) != "move":
			break

	if not _stopped and _manager != null and is_instance_valid(_manager) \
			and _manager.current_phase == BattleManager.Phase.PLAYER_TURN \
			and _manager.active_unit_id == unit_id:
		# Guard against malformed policies that keep selecting only moves.
		var forced_wait := {
			"kind": "wait",
			"action_id": "wait",
			"target_id": "",
			"target_position": {"x": -1, "y": -1},
			"expected_damage": 0,
		}
		_record_decision(unit_id, forced_wait, 1, true)
		_manager.select_command("wait")
	_driving = false
	_dispatch_pending_turn()


func _dispatch_pending_turn() -> void:
	if _stopped or _pending_player_unit_id.is_empty():
		return
	if _manager == null or not is_instance_valid(_manager):
		_pending_player_unit_id = ""
		return
	var pending_unit_id := _pending_player_unit_id
	_pending_player_unit_id = ""
	# Only drive the queued unit if it is still the live player turn. If an enemy
	# turn or battle completion superseded it, the normal future signal will drive
	# the next player turn instead.
	if _manager.current_phase == BattleManager.Phase.PLAYER_TURN \
			and _manager.active_unit_id == pending_unit_id:
		_drive_turn.call_deferred(pending_unit_id)


func _record_decision(unit_id: String, action: Dictionary, legal_action_count: int, forced := false) -> void:
	if _telemetry == null:
		return
	var pos_raw: Dictionary = action.get("target_position", {})
	var pos := Vector2i(int(pos_raw.get("x", -1)), int(pos_raw.get("y", -1)))
	_telemetry.record_decision(
		unit_id,
		str(_policy.get("policy_id")),
		str(action.get("action_id", action.get("kind", "unknown"))),
		str(action.get("target_id", "")),
		pos,
		action.get("expected_damage", null),
		{
			"kind": str(action.get("kind", "")),
			"legal_action_count": legal_action_count,
			"lethal": bool(action.get("lethal", false)),
			"nearest_enemy_distance": int(action.get("nearest_enemy_distance", -1)),
			"best_attack_damage_after_move": int(action.get("best_attack_damage_after_move", 0)),
			"forced": forced,
		}
	)


func _on_battle_finished(_rewards: Dictionary) -> void:
	_stopped = true
	_pending_player_unit_id = ""


func _on_battle_lost() -> void:
	_stopped = true
	_pending_player_unit_id = ""
