extends SceneTree

const GreedyPolicy := preload("res://scripts/ai/self_play/GreedyDamagePolicy.gd")
const RandomPolicy := preload("res://scripts/ai/self_play/RandomLegalPolicy.gd")

var _pass := 0
var _fail := 0


func _init() -> void:
	_test_policy_selection()
	print("Self-play policy tests: %d pass, %d fail" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


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
	_true(sequence_one.size() == 12, "random legal policy returns a choice each decision")


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
