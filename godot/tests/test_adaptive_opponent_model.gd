extends SceneTree

const OpponentModel := preload("res://scripts/ai/enemy/AdaptiveOpponentModel.gd")
const IntentBias := preload("res://scripts/ai/enemy/AdaptiveIntentBias.gd")

var _pass := 0
var _fail := 0


func _init() -> void:
	_test_learning_and_bounded_bias()
	_test_style_shift_and_serialization()
	print("Adaptive opponent tests: %d pass, %d fail" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _test_learning_and_bounded_bias() -> void:
	var model = OpponentModel.new()
	var cold_candidates: Array[Dictionary] = [
		{"candidate_id":"near", "base_score":100.0, "target_id":"kael", "area_target_count":1},
		{"candidate_id":"carry", "base_score":98.0, "target_id":"mira", "area_target_count":1},
	]
	var cold_ranked := IntentBias.rank_candidates(cold_candidates, model)
	_eq(cold_ranked[0].get("candidate_id"), "near", "cold model preserves base tactical ranking")
	_eq(float(cold_ranked[0].get("adaptive_delta", -1.0)), 0.0, "cold model contributes no hidden bias")

	for _i in range(12):
		model.observe_action("mira", "ability", {
			"range": 4,
			"actor_hp_ratio": 0.8,
			"damage": 75,
			"element": "fire",
		})
		model.observe_action("kael", "basic_attack", {
			"range": 1,
			"actor_hp_ratio": 0.9,
			"damage": 18,
		})
	model.observe_turn_end([Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2), Vector2i(6, 6)])
	model.observe_turn_end([Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 1), Vector2i(6, 6)])

	_true(model.confidence() >= 0.99, "repeated completed actions build opponent-model confidence")
	_true(model.target_priority("mira") > model.target_priority("kael"), "high-contribution unit becomes a learned priority")
	_true(float(model.signals().get("ranged_preference", 0.0)) > 0.45, "model learns repeated ranged pressure")
	_true(model.aoe_adaptation_signal() > 0.0, "model learns player clustering from completed turns")

	var warm_ranked := IntentBias.rank_candidates(cold_candidates, model)
	_eq(warm_ranked[0].get("candidate_id"), "carry", "bounded learned bias can break a close tactical tie toward the observed carry")
	_true(float(warm_ranked[0].get("adaptive_delta", 0.0)) <= IntentBias.MAX_TOTAL_DELTA, "adaptive influence respects the hard absolute cap")
	_true(float(warm_ranked[0].get("adaptive_delta", 0.0)) <= float(warm_ranked[0].get("base_score", 0.0)) * IntentBias.MAX_RELATIVE_DELTA + 0.001, "adaptive influence respects the relative cap")
	_true(not warm_ranked[0].get("adaptation", {}).is_empty(), "meaningful adaptation exposes a player-readable explanation")

	var area_candidates: Array[Dictionary] = [
		{"candidate_id":"single", "base_score":105.0, "target_id":"kael", "area_target_count":1},
		{"candidate_id":"area", "base_score":100.0, "target_id":"mira", "area_target_count":3},
	]
	var area_ranked := IntentBias.rank_candidates(area_candidates, model)
	_eq(area_ranked[0].get("candidate_id"), "area", "observed clustering can make a close AoE option more attractive")


func _test_style_shift_and_serialization() -> void:
	var model = OpponentModel.new()
	for _i in range(10):
		model.observe_action("lyra", "ability", {"range":4, "actor_hp_ratio":0.75, "damage":35})
	var initial_ranged := float(model.signals().get("ranged_preference", 0.0))
	for _turn in range(8):
		model.observe_turn_end([Vector2i(0, 0), Vector2i(5, 5)])
		for _i in range(3):
			model.observe_action("lyra", "basic_attack", {"range":1, "actor_hp_ratio":0.8, "damage":28})
	var shifted_ranged := float(model.signals().get("ranged_preference", 0.0))
	_true(shifted_ranged < initial_ranged, "new behavior plus decay lets the player escape a stale opponent read")

	var saved: Dictionary = model.to_dict()
	var restored = OpponentModel.new()
	restored.load_dict(saved)
	_eq(restored.to_dict(), saved, "opponent profile round-trips for future run/save persistence")

	var invalid = OpponentModel.new()
	invalid.load_dict({"version":999, "observation_count":999})
	_eq(int(invalid.signals().get("observations", -1)), 0, "unknown profile versions fail closed instead of importing stale behavior")


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
