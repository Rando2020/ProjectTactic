extends Node

const BattleSceneResource := preload("res://scenes/Battle.tscn")
const TelemetryRecorder := preload("res://scripts/ai/BattleTelemetry.gd")
const Controller := preload("res://scripts/ai/self_play/SelfPlayController.gd")
const GreedyPolicy := preload("res://scripts/ai/self_play/GreedyDamagePolicy.gd")
const RandomPolicy := preload("res://scripts/ai/self_play/RandomLegalPolicy.gd")
const AbilityPolicy := preload("res://scripts/ai/self_play/AbilityAwarePolicy.gd")
const ScenarioMatrix := preload("res://scripts/ai/self_play/SelfPlayScenarioMatrix.gd")

var _outcome := ""
var _stall_reason := ""
var _pass := 0
var _fail := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := str(args[0]) if not args.is_empty() else "greedy"
	var scenario_id := str(args[1]) if args.size() > 1 else "ashvale-debug-map"
	if mode not in ["greedy", "random", "ability"]:
		_fail += 1
		print("FAIL unknown real self-play mode: %s" % mode)
		_finish()
		return
	var scenario: Dictionary = {}
	if scenario_id != "ashvale-debug-map":
		scenario = ScenarioMatrix.get_scenario(scenario_id)
		if scenario.is_empty():
			_fail += 1
			print("FAIL unknown tactical scenario: %s" % scenario_id)
			_finish()
			return
		if not _configure_game_state_for_scenario(scenario):
			_finish()
			return
	await _run_real_battle(mode, scenario_id, scenario)
	# Allow the completed coroutine frame and its RefCounted locals to release
	# before asking the SceneTree to shut down.
	await get_tree().process_frame
	_finish()


func _configure_game_state_for_scenario(scenario: Dictionary) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		_fail += 1
		print("FAIL GameState autoload is required for tactical scenario selection")
		return false

	# Every process starts from a clean evaluation state. Debug scenarios use the
	# shipped debug map selector; generated scenarios use the real RunState and
	# MapGenerator path that BattleScene already uses in normal roguelike runs.
	gs.active_run = null
	gs.selected_map_index = int(scenario.get("map_index", 0))
	if gs.get("unit_registry") is Dictionary:
		gs.unit_registry.clear()
	if str(scenario.get("source", "debug_map")) == "generated_run_floor":
		var run_seed := int(scenario.get("run_seed", 4242))
		var floor_num := int(scenario.get("floor", 1))
		var run := RunState.create(run_seed)
		run.current_floor = floor_num
		run.heat_level = int(scenario.get("heat", 0))
		var selected_index := -1
		for index in range(run.floor_plan.size()):
			var node: Dictionary = run.floor_plan[index]
			if int(node.get("floor", 0)) != floor_num:
				continue
			if str(node.get("type", "")) in ["battle", "elite"]:
				selected_index = index
				break
		if selected_index < 0:
			for index in range(run.floor_plan.size()):
				if int(run.floor_plan[index].get("floor", 0)) == floor_num:
					selected_index = index
					break
		if selected_index < 0:
			_fail += 1
			print("FAIL scenario could not select run node for floor %d" % floor_num)
			return false
		run.current_node = selected_index
		gs.active_run = run
	return true


func _run_real_battle(mode: String, scenario_id: String, scenario: Dictionary) -> void:
	_outcome = ""
	_stall_reason = ""
	# Ability-aware uses the same gameplay seed as greedy so differences are due to
	# policy/action access rather than a different global combat RNG sequence.
	var policy_seed := 27183 if mode == "random" else 7319
	seed(policy_seed)

	var battle_scene := BattleSceneResource.instantiate()
	# Camera shake uses global random values for presentation. Disabling only the
	# BattleScene process callback prevents visual RNG from changing combat RNG.
	battle_scene.set_process(false)
	battle_scene.set_process_unhandled_input(false)
	if scenario_id == "ashvale-debug-map":
		battle_scene.map_index = 0
	else:
		battle_scene.map_index = int(scenario.get("map_index", 0))
	var manager := battle_scene.get_node("BattleManager") as BattleManager
	manager.auto_battle_enabled = false

	var telemetry := TelemetryRecorder.new()
	var policy: RefCounted
	if mode == "greedy":
		policy = GreedyPolicy.new()
	elif mode == "ability":
		policy = AbilityPolicy.new()
	else:
		var random_policy := RandomPolicy.new()
		random_policy.configure(policy_seed)
		policy = random_policy

	telemetry.attach(manager, {
		"scenario_id": scenario_id,
		"seed": policy_seed,
		"build_sha": "selfplay-scenario-matrix",
		"source": "self_play",
		"policy_id": str(policy.get("policy_id")),
		"run_id": "%s-%s" % [scenario_id, mode],
		"include_timing": false,
	})
	var controller := Controller.new()
	controller.attach(manager, policy, telemetry, 120)
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

	var controller_idle: bool = await controller.wait_until_idle(30)
	_true(controller_idle, "%s/%s controller quiesces before teardown" % [scenario_id, mode])

	var output_path := "user://ai-self-play/%s.json" % mode
	if scenario_id != "ashvale-debug-map":
		output_path = "user://ai-self-play/%s/%s.json" % [scenario_id, mode]
	var exported := telemetry.export_evidence(output_path)
	_true(not exported.is_empty(), "%s/%s exports telemetry evidence" % [scenario_id, mode])
	_true(FileAccess.file_exists(output_path), "%s/%s evidence file exists" % [scenario_id, mode])
	var evidence: Variant = JSON.parse_string(FileAccess.get_file_as_string(output_path))
	_true(typeof(evidence) == TYPE_DICTIONARY, "%s/%s evidence is valid JSON" % [scenario_id, mode])
	if typeof(evidence) == TYPE_DICTIONARY:
		var metrics: Dictionary = evidence.get("metrics", {})
		_true(int(metrics.get("decision_count", 0)) > 0, "%s/%s records explicit decisions" % [scenario_id, mode])
		_true(int(metrics.get("turn_count_player", 0)) > 0, "%s/%s exercises real player turns" % [scenario_id, mode])
		_eq(evidence.get("source"), "self_play", "%s/%s uses self_play source" % [scenario_id, mode])
		_eq(evidence.get("scenario_id"), scenario_id, "%s/%s preserves scenario identity" % [scenario_id, mode])
		_eq(evidence.get("context", {}).get("policy_id"), str(policy.get("policy_id")), "%s/%s preserves policy identity" % [scenario_id, mode])
		if scenario_id == "ashvale-debug-map" and mode != "random":
			_true(not _outcome.is_empty(), "%s policy completes the real Ashvale battle within the bounded run" % mode)
		else:
			_true(not _outcome.is_empty() or not _stall_reason.is_empty(), "%s/%s terminates with an outcome or bounded stall" % [scenario_id, mode])
		if mode == "ability" and scenario_id == "ashvale-debug-map":
			_true(_count_ability_decisions(evidence) > 0, "ability-aware policy records at least one real ability decision")
		print("SELF_PLAY_RESULT %s" % JSON.stringify({
			"scenario": scenario_id,
			"policy": str(policy.get("policy_id")),
			"outcome": metrics.get("outcome", "incomplete"),
			"player_turns": metrics.get("turn_count_player", 0),
			"decisions": metrics.get("decision_count", 0),
			"ability_decisions": _count_ability_decisions(evidence),
			"hp_lost_player_team": metrics.get("hp_lost_player_team", 0),
			"stall_reason": _stall_reason,
		}))

	if controller.stalled.is_connected(_on_stalled):
		controller.stalled.disconnect(_on_stalled)
	if manager.battle_won.is_connected(_on_battle_won):
		manager.battle_won.disconnect(_on_battle_won)
	if manager.battle_lost.is_connected(_on_battle_lost):
		manager.battle_lost.disconnect(_on_battle_lost)
	controller.detach()
	telemetry.detach()
	Engine.time_scale = 1.0

	remove_child(battle_scene)
	battle_scene.free()
	manager = null
	policy = null
	controller = null
	telemetry = null
	await get_tree().process_frame


func _count_ability_decisions(evidence: Dictionary) -> int:
	var count := 0
	for event in evidence.get("context", {}).get("events", []):
		if not event is Dictionary or event.get("type", "") != "decision":
			continue
		var action_id := str(event.get("payload", {}).get("action_id", ""))
		if action_id.begins_with("ability:"):
			count += 1
	return count


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
