extends Node

const BattleSceneResource := preload("res://scenes/Battle.tscn")
const TelemetryRecorder := preload("res://scripts/ai/BattleTelemetry.gd")
const Controller := preload("res://scripts/ai/self_play/SelfPlayController.gd")
const GreedyPolicy := preload("res://scripts/ai/self_play/GreedyDamagePolicy.gd")
const RandomPolicy := preload("res://scripts/ai/self_play/RandomLegalPolicy.gd")

var _outcome := ""
var _stall_reason := ""
var _pass := 0
var _fail := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := str(args[0]) if not args.is_empty() else "greedy"
	if mode != "greedy" and mode != "random":
		_fail += 1
		print("FAIL unknown real self-play mode: %s" % mode)
		_finish()
		return
	await _run_real_battle(mode)
	# Allow the completed coroutine frame and its RefCounted locals to release
	# before asking the SceneTree to shut down.
	await get_tree().process_frame
	_finish()


func _run_real_battle(mode: String) -> void:
	_outcome = ""
	_stall_reason = ""
	var policy_seed := 7319 if mode == "greedy" else 27183
	seed(policy_seed)

	var battle_scene := BattleSceneResource.instantiate()
	# Camera shake uses global random values for presentation. Disabling only the
	# BattleScene process callback prevents visual RNG from changing combat RNG.
	battle_scene.set_process(false)
	battle_scene.set_process_unhandled_input(false)
	battle_scene.map_index = 0
	var manager := battle_scene.get_node("BattleManager") as BattleManager
	manager.auto_battle_enabled = false

	var telemetry := TelemetryRecorder.new()
	var policy: RefCounted
	if mode == "greedy":
		policy = GreedyPolicy.new()
	else:
		var random_policy := RandomPolicy.new()
		random_policy.configure(policy_seed)
		policy = random_policy

	telemetry.attach(manager, {
		"scenario_id": "ashvale-debug-map",
		"seed": policy_seed,
		"build_sha": "selfplay-baseline",
		"source": "self_play",
		"policy_id": str(policy.get("policy_id")),
		"run_id": "%s-baseline" % mode,
		"include_timing": false,
	})
	var controller := Controller.new()
	controller.attach(manager, policy, telemetry, 90)
	controller.stalled.connect(_on_stalled)
	manager.battle_won.connect(_on_battle_won)
	manager.battle_lost.connect(_on_battle_lost)

	add_child(battle_scene)
	Engine.time_scale = 12.0

	var started_ms := Time.get_ticks_msec()
	while _outcome.is_empty() and _stall_reason.is_empty() and Time.get_ticks_msec() - started_ms < 30000:
		await get_tree().process_frame

	if _outcome.is_empty() and _stall_reason.is_empty():
		_stall_reason = "Wall-clock timeout before battle completion."
		telemetry.record_checkpoint("self-play-timeout", {"reason": _stall_reason})

	# A battle result can be emitted while the controller is still unwinding the
	# action coroutine that caused it. Stop scheduling new choices and wait for the
	# in-flight coroutine to become idle before reading final evidence or teardown.
	var controller_idle: bool = await controller.wait_until_idle(30)
	_true(controller_idle, "%s self-play controller quiesces before teardown" % mode)

	var output_path := "user://ai-self-play/%s.json" % mode
	var exported := telemetry.export_evidence(output_path)
	_true(not exported.is_empty(), "%s real battle exports telemetry evidence" % mode)
	_true(FileAccess.file_exists(output_path), "%s real battle evidence file exists" % mode)
	var evidence: Variant = JSON.parse_string(FileAccess.get_file_as_string(output_path))
	_true(typeof(evidence) == TYPE_DICTIONARY, "%s exported evidence is valid JSON" % mode)
	if typeof(evidence) == TYPE_DICTIONARY:
		var metrics: Dictionary = evidence.get("metrics", {})
		_true(int(metrics.get("decision_count", 0)) > 0, "%s records explicit self-play decisions" % mode)
		_true(int(metrics.get("turn_count_player", 0)) > 0, "%s exercises real player turns" % mode)
		_eq(evidence.get("source"), "self_play", "%s evidence uses self_play source" % mode)
		_eq(evidence.get("context", {}).get("policy_id"), str(policy.get("policy_id")), "%s evidence preserves policy identity" % mode)
		if mode == "greedy":
			_true(not _outcome.is_empty(), "greedy policy completes the real Ashvale battle within the bounded run")
		else:
			_true(not _outcome.is_empty() or not _stall_reason.is_empty(), "random policy terminates with an outcome or bounded stall")
		print("SELF_PLAY_RESULT %s" % JSON.stringify({
			"policy": str(policy.get("policy_id")),
			"outcome": metrics.get("outcome", "incomplete"),
			"player_turns": metrics.get("turn_count_player", 0),
			"decisions": metrics.get("decision_count", 0),
			"hp_lost_player_team": metrics.get("hp_lost_player_team", 0),
		}))

	# Disconnect every harness-owned edge before freeing the battle. Defeated units
	# may already have been freed, which BattleTelemetry handles independently.
	if controller.stalled.is_connected(_on_stalled):
		controller.stalled.disconnect(_on_stalled)
	if manager.battle_won.is_connected(_on_battle_won):
		manager.battle_won.disconnect(_on_battle_won)
	if manager.battle_lost.is_connected(_on_battle_lost):
		manager.battle_lost.disconnect(_on_battle_lost)
	controller.detach()
	telemetry.detach()
	Engine.time_scale = 1.0

	# `queue_free()` plus immediate SceneTree.quit can leave destruction deferred
	# until after Godot has started resource shutdown. The headless harness owns the
	# battle scene exclusively, so synchronous free is safe and makes cleanup exact.
	remove_child(battle_scene)
	battle_scene.free()
	manager = null
	policy = null
	controller = null
	telemetry = null
	await get_tree().process_frame


func _on_battle_won(_rewards: Dictionary) -> void:
	_outcome = "victory"


func _on_battle_lost() -> void:
	_outcome = "defeat"


func _on_stalled(reason: String) -> void:
	_stall_reason = reason


func _eq(got: Variant, expected: Variant, label: String) -> void:
	if got == expected:
		print("PASS %s" % label)
		_pass += 1
	else:
		print("FAIL %s (got=%s expected=%s)" % [label, str(got), str(expected)])
		_fail += 1


func _true(value: bool, label: String) -> void:
	if value:
		print("PASS %s" % label)
		_pass += 1
	else:
		print("FAIL %s" % label)
		_fail += 1


func _finish() -> void:
	Engine.time_scale = 1.0
	print("Real self-play baseline tests: %d pass, %d fail" % [_pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
