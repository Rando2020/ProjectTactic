extends SceneTree

const OrrenArc = preload("res://scripts/story/OrrenArc.gd")
const RecurrenceStory = preload("res://scripts/story/RecurrenceStory.gd")

class FakeState:
	extends Node
	var story_flags: Array[String] = []
	func save() -> void:
		pass

var _passes := 0
var _failures := 0


func _initialize() -> void:
	var gs := FakeState.new()
	var run := RunState.create(4242)

	_expect_eq(OrrenArc.stage_id(gs), "first", "starts at first meeting")

	var first := OrrenArc.apply_choice(gs, run, "map")
	_expect_true(first.get("reward_gold", 0) > 0, "first meeting grants selected practical reward")
	_expect_true(gs.story_flags.has(OrrenArc.FLAG_MET), "first meeting persists")
	_expect_eq(OrrenArc.stage_id(gs), "sacrifice", "second meeting asks for sacrifice")

	var wait := OrrenArc.apply_choice(gs, run, "wait")
	_expect_eq(int(wait.get("reward_gold", 0)), 0, "waiting gives no gold")
	_expect_eq(run.story_move_penalty, -1, "waiting applies real movement burden")
	_expect_true(gs.story_flags.has(OrrenArc.FLAG_WAITED), "waiting advances relationship")
	_expect_eq(OrrenArc.stage_id(gs), "attachment", "third meeting becomes ordinary time together")

	var love := OrrenArc.apply_choice(gs, run, "sit")
	_expect_true(gs.story_flags.has(OrrenArc.FLAG_EXPECTED), "sitting creates expectation")
	_expect_true(RecurrenceStory.is_leaf_restored(gs, "love"), "attachment restores Love")
	_expect_eq(str(love.get("story_event", {}).get("leaf_id", "")), "love", "Love returns as story event")
	_expect_eq(OrrenArc.stage_id(gs), "last_seen", "next meeting is deliberately ordinary")

	OrrenArc.apply_choice(gs, run, "promise")
	_expect_true(gs.story_flags.has(OrrenArc.FLAG_LAST_SEEN), "last ordinary meeting persists")
	_expect_eq(OrrenArc.stage_id(gs), "absence", "later wanderer node becomes empty stair")

	var grief := OrrenArc.apply_choice(gs, run, "take_case")
	_expect_true(gs.story_flags.has(OrrenArc.FLAG_ABSENT), "absence persists")
	_expect_true(RecurrenceStory.is_leaf_restored(gs, "grief"), "absence restores Grief")
	_expect_eq(str(grief.get("story_event", {}).get("leaf_id", "")), "grief", "Grief returns as story event")
	_expect_eq(RecurrenceStory.restored_leaf_count(gs), 2, "opening bifurcation restores exactly two Leaves")
	_expect_eq(OrrenArc.stage_id(gs), "after_grief", "future wanderer nodes acknowledge absence without replaying it")

	if _failures > 0:
		push_error("Orren arc test failed: %d failure(s), %d pass(es)" % [_failures, _passes])
		quit(1)
		return

	print("Orren Love/Grief arc: OK (%d assertions)" % _passes)
	quit(0)


func _expect_true(value: bool, label: String) -> void:
	if value:
		_passes += 1
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _expect_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		_passes += 1
		return
	_failures += 1
	push_error("FAIL: %s | expected=%s actual=%s" % [label, str(expected), str(actual)])
