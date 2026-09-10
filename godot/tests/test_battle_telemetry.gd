extends SceneTree

const BattleTelemetryRecorder := preload("res://scripts/ai/BattleTelemetry.gd")

class FakeUnit:
	extends Node
	signal hp_changed(unit_id: String, new_hp: int, max_hp: int)
	signal status_applied(unit_id: String, status_id: String)
	signal status_removed(unit_id: String, status_id: String)

	var unit_id := ""
	var team := "player"
	var hp := 100
	var mp := 20
	var temper := 50
	var ether := 25
	var ct := 0
	var grid_pos := Vector2i.ZERO
	var facing := "S"
	var current_job_id := ""

	func configure(p_id: String, p_team: String, p_pos: Vector2i, p_job: String) -> void:
		unit_id = p_id
		team = p_team
		grid_pos = p_pos
		current_job_id = p_job


class FakeManager:
	extends Node
	signal battle_started(display_name: String, objective: String)
	signal turn_started(unit_id: String, team: String)
	signal turn_ended(unit_id: String)
	signal unit_moved(unit_id: String, from: Vector2i, to: Vector2i)
	signal unit_defeated(unit_id: String)
	signal battle_won(rewards: Dictionary)
	signal battle_lost()
	signal enemy_intent_changed(intent: Dictionary)

	var units: Dictionary = {}
	var last_ability_used := ""


var _pass := 0
var _fail := 0


func _init() -> void:
	_run_tests()
	print("Battle telemetry tests: %d pass, %d fail" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _run_tests() -> void:
	var manager := FakeManager.new()
	var player := FakeUnit.new()
	player.configure("zane", "player", Vector2i(1, 2), "vanguard")
	var enemy := FakeUnit.new()
	enemy.configure("grave-warden", "enemy", Vector2i(4, 2), "warden")
	manager.units = {player.unit_id: player, enemy.unit_id: enemy}
	manager.add_child(player)
	manager.add_child(enemy)
	root.add_child(manager)

	var recorder = BattleTelemetryRecorder.new()
	recorder.attach(manager, {
		"scenario_id": "telemetry-smoke",
		"seed": 424242,
		"build_sha": "abcdef123456",
		"source": "godot_test",
		"policy_id": "fixture-policy",
		"run_id": "smoke-1",
		"include_timing": false,
	})

	manager.battle_started.emit("Telemetry Test", "Defeat all enemies")
	manager.turn_started.emit("zane", "player")
	recorder.record_decision("zane", "fixture-policy", "basic-attack", "grave-warden", Vector2i(4, 2), 28.0)
	manager.unit_moved.emit("zane", Vector2i(1, 2), Vector2i(2, 2))
	player.grid_pos = Vector2i(2, 2)
	manager.last_ability_used = "basic-attack"
	enemy.hp = 72
	enemy.hp_changed.emit(enemy.unit_id, enemy.hp, 100)
	enemy.status_applied.emit(enemy.unit_id, "exposed")
	manager.turn_ended.emit("zane")
	manager.turn_started.emit("grave-warden", "enemy")
	manager.enemy_intent_changed.emit({
		"unit_id": "grave-warden",
		"action": "attack",
		"target_id": "zane",
		"target_position": Vector2i(2, 2),
	})
	manager.last_ability_used = "cleave"
	player.hp = 89
	player.hp_changed.emit(player.unit_id, player.hp, 100)
	manager.turn_ended.emit("grave-warden")
	enemy.hp = 0
	enemy.hp_changed.emit(enemy.unit_id, enemy.hp, 100)
	manager.unit_defeated.emit(enemy.unit_id)
	manager.battle_won.emit({"gold": 42, "job_xp": 10})

	var evidence: Dictionary = recorder.to_evidence()
	_eq(evidence.get("schema_version"), 1, "shared evidence schema version")
	_eq(evidence.get("source"), "godot_test", "source is preserved")
	_eq(evidence.get("scenario_id"), "telemetry-smoke", "scenario id is preserved")
	_eq(evidence.get("seed"), 424242, "seed is preserved")
	var metrics: Dictionary = evidence.get("metrics", {})
	_eq(metrics.get("outcome"), "victory", "victory outcome captured")
	_eq(metrics.get("turn_count_player"), 1, "player turn counted")
	_eq(metrics.get("turn_count_enemy"), 1, "enemy turn counted")
	_eq(metrics.get("move_count"), 1, "movement counted")
	_eq(metrics.get("decision_count"), 1, "explicit decision counted")
	_eq(metrics.get("enemy_intent_count"), 1, "enemy intent counted")
	_eq(metrics.get("status_application_count"), 1, "status application counted")
	_eq(metrics.get("hp_lost_player_team"), 11, "player-team HP loss counted")
	_eq(metrics.get("hp_lost_enemy_team"), 100, "enemy-team HP loss counted across events")
	_eq(metrics.get("defeated_enemy_units"), 1, "enemy defeat counted")
	_eq(evidence.get("observations", []).size(), 0, "explicit decisions remove decision coverage warning")

	var context: Dictionary = evidence.get("context", {})
	var event_stream: Array = context.get("events", [])
	_true(event_stream.size() >= 10, "structured event stream captured")
	var deterministic_sequence := true
	for i in range(event_stream.size()):
		if int(event_stream[i].get("seq", -1)) != i:
			deterministic_sequence = false
			break
	_true(deterministic_sequence, "event sequence is deterministic when timing is disabled")
	_true(not event_stream[0].has("elapsed_ms"), "wall-clock timing omitted by default")

	var output_path := "user://ai-telemetry-test/evidence.json"
	_eq(recorder.export_evidence(output_path), output_path, "evidence export returns requested path")
	_true(FileAccess.file_exists(output_path), "evidence file is written")
	var exported_text := FileAccess.get_file_as_string(output_path)
	var exported: Variant = JSON.parse_string(exported_text)
	_true(typeof(exported) == TYPE_DICTIONARY, "exported telemetry is valid JSON")
	if typeof(exported) == TYPE_DICTIONARY:
		_eq(exported.get("evidence_id"), evidence.get("evidence_id"), "exported evidence identity matches")
		_eq(exported.get("metrics", {}).get("decision_count"), 1, "exported metrics match in-memory evidence")

	recorder.detach()
	manager.queue_free()


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
