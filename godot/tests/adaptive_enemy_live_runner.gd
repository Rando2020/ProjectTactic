extends Node

const BattleSceneResource := preload("res://scenes/Battle.tscn")
const OpponentModel := preload("res://scripts/ai/enemy/AdaptiveOpponentModel.gd")

var _pass := 0
var _fail := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var battle_scene := BattleSceneResource.instantiate()
	battle_scene.set_process(false)
	battle_scene.set_process_unhandled_input(false)
	var manager = battle_scene.get_node("BattleManager")
	_true(manager is AdaptiveBattleManager, "Battle scene uses AdaptiveBattleManager subclass")
	_true(manager.adaptive_enemy_enabled == false, "adaptive enemy behavior is opt-in by default")
	manager.auto_battle_enabled = false
	add_child(battle_scene)

	var enemy: Unit = null
	for uid in manager.units.keys():
		var candidate: Unit = manager.units.get(uid)
		if candidate and is_instance_valid(candidate) and candidate.team == "enemy" and candidate.hp > 0:
			enemy = candidate
			break
	_true(enemy != null, "real Ashvale battle exposes a living enemy for adaptive intent test")
	if enemy:
		var baseline: Dictionary = manager._evaluate_enemy_intent(enemy)
		_true(baseline.get("adaptation", {}).is_empty(), "disabled adaptive mode preserves ordinary intent output")

		var learned = OpponentModel.new()
		for actor_id in ["zane", "mira", "kael", "lyra"]:
			for _i in range(6):
				learned.observe_action(actor_id, "ability", {
					"range": 4,
					"actor_hp_ratio": 0.8,
					"damage": 50,
					"element": "fire",
				})
		learned.observe_turn_end([Vector2i(1, 6), Vector2i(2, 6), Vector2i(1, 7), Vector2i(2, 7)])
		manager.load_adaptive_profile(learned.to_dict())
		manager.adaptive_enemy_enabled = true
		var adapted: Dictionary = manager._evaluate_enemy_intent(enemy)
		_true(not adapted.get("adaptation", {}).is_empty(), "learned profile can influence a real enemy intent transparently")
		_true(str(adapted.get("note", "")).contains("Adapted"), "adapted live intent telegraphs why learned behavior mattered")
		_true(float(manager.adaptive_signals().get("confidence", 0.0)) >= 0.99, "live manager exposes inspectable opponent-model confidence")

	manager.adaptive_enemy_enabled = false
	remove_child(battle_scene)
	battle_scene.free()
	Engine.time_scale = 1.0
	await get_tree().process_frame
	print("Adaptive live intent tests: %d pass, %d fail" % [_pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)


func _true(value: bool, label: String) -> void:
	if value:
		print("PASS %s" % label)
		_pass += 1
	else:
		print("FAIL %s" % label)
		_fail += 1
