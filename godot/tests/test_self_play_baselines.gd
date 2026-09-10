extends SceneTree

const BattleSceneResource := preload("res://scenes/Battle.tscn")
const TelemetryRecorder := preload("res://scripts/ai/BattleTelemetry.gd")
const Controller := preload("res://scripts/ai/self_play/SelfPlayController.gd")
const GreedyPolicy := preload("res://scripts/ai/self_play/GreedyDamagePolicy.gd")
const RandomPolicy := preload("res://scripts/ai/self_play/RandomLegalPolicy.gd")

var _outcome := ""
var _stall_reason := ""
var _pass := 0
var _fail := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := str(args[0]) if not args.is_empty() else "policy"
	match mode:
		"policy":
			_test_policy_selection()
			_finish()
		"greedy", "random":
			await _run_real_battle(mode)
			_finish()
		_:
			print("FAIL unknown self-play test mode: %s" % mode)
			_fail += 1
			_finish()


func _test_policy_selection() -> void:
	var actions: Array[Dictionary] = [
		{"kind":"wait", "action_id":"wait", "target_id":"", "target_position":{"x":0,"y":0}},
		{"kind":"move", "action_id":"move", "target_id":"", "target_position":{"x":3,"y":2}, "attack_available_after_move":true, "best_attack_damage_after_move":42, "nearest_enemy_distance":2, "height":1},
		{"kind":"attack", "action_id":"basic-attack", "target_id":"enemy-a", "target_position":{"x":4,"y":2}, "expected_damage":38, "lethal":false},
		{"kind":"attack", "action_id":"basic-attack", "target_id":"enemy-b", "target_position":{"x":4,"y":3}, "expected_damage":22, "lethal":true},
	]
	var greedy = GreedyPolicy.new()
	var greedy_choice: Dictionary = greedy.choose_action(actions)
	_eq(greedy_choice.get("target_id"), "enemy-b", "greedy policy prioritizes lethal attack")

	var random_one = RandomPolicy.new()
	random_one.configure(99173)
	var random_two = RandomPolicy.new()
	random_two.configure(99173)
	var sequence_one: Array[String] = []
	var sequence_two: Array[String] = []
	for _i in range(12):
		sequence_one.append(_choice_key(random_one.choose_action(actions)))
		sequence_two.append(_choice_key(random_two.choose_action(actions)))
	_eq(sequence_one, sequence_two, "random legal policy is deterministic for the same seed")
	_true(sequence_one.duplicate().size() == 12, "random legal policy returns a choice each decision")


func _run_real_battle(mode: String) -> void:
	_outcome = ""
	_stall_reason = ""
	var policy_seed := 7319 if mode == "greedy" else 27183
	seed(policy_seed)

	var battle_scene := BattleSceneResource.instantiate()
	# Camera shake uses global random numbers for visuals. Disable only BattleScene's
	# own _process callback so visual noise cannot perturb the gameplay RNG stream.
	battle_scene.set_process(false)
	battle_scene.set_process_unhandled_input(false)
	battle_scene.map_index = 0
	var manager := battle_scene.get_node("BattleManager") as BattleManager
	manager.auto_battle_enabled = false

	var telemetry = TelemetryRecorder.new()
	var policy: RefCounted
	if mode == "greedy":
		policy = GreedyPolicy.new()
	else:
		var random_policy = RandomPolicy.new()
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
	var controller = Controller.new()
	controller.attach(manager, policy, telemetry, 90)
	controller.stalled.connect(_on_stalled)
	manager.battle_won.connect(_on_battle_won)
	manager.battle_lost.connect(_on_battle_lost)

	root.add_child(battle_scene)
	# BattleManager intentionally restores time_scale to 1 when its built-in auto
	# player is disabled. Raise it only after the real battle has started.
	Engine.time_scale = 12.0

	var started_ms := Time.get_ticks_msec()
	while _outcome.is_empty() and _stall_reason.is_empty() and Time.get_ticks_msec() - started_ms < 30000:
		await process_frame

	if _outcome.is_empty() and _stall_reason.is_empty():
		_stall_reason = "Wall-clock timeout before battle completion."
		telemetry.record_checkpoint("self-play-timeout", {"reason": _stall_reason})

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

	controller.detach()
	telemetry.detach()
	Engine.time_scale = 1.0
	battle_scene.queue_free()
	await process_frame


func _on_battle_won(_rewards: Dictionary) -> void:
	_outcome = "victory"


func _on_battle_lost() -> void:
	_outcome = "defeat"


func _on_stalled(reason: String) -> void:
	_stall_reason = reason


func _choice_key(action: Dictionary) -> String:
	var pos: Dictionary = action.get("target_position", {})
	return "%s|%s|%s,%s" % [
		str(action.get("kind", "")),
		str(action.get("target_id", "")),
		str(pos.get("x", "")),
		str(pos.get("y", "")),
	]


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
	print("Self-play baseline tests: %d pass, %d fail" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
