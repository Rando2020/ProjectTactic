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

	# Run 1: Orren is useful first.
	var run1 := RunState.create(4241)
	_expect_eq(OrrenArc.stage_id(gs), "first", "starts at first meeting")
	var first := OrrenArc.apply_choice(gs, run1, "map")
	_expect_true(first.get("reward_gold", 0) > 0, "first meeting grants selected practical reward")
	_expect_true(gs.story_flags.has(OrrenArc.FLAG_MET), "first meeting persists")
	_expect_true(run1.orren_story_beat_consumed, "first authored beat consumes this descent")
	_expect_eq(str(OrrenArc.get_stage(gs, run1).get("id", "")), "interlude", "same-run Orren node becomes non-advancing interlude")
	var interlude := OrrenArc.apply_choice(gs, run1, "interlude_training")
	_expect_true(interlude.get("reward_jp", 0) > 0, "same-run interlude can still reward the player")
	_expect_eq(OrrenArc.stage_id(gs), "sacrifice", "interlude does not advance relationship")
	var roundtrip := RunState.from_dict(run1.to_dict())
	_expect_true(roundtrip.orren_story_beat_consumed, "same-run pacing lock survives save roundtrip")

	# Run 2: the player must knowingly pay a tactical cost.
	var run2 := RunState.create(4242)
	_expect_true(not run2.orren_story_beat_consumed, "new descent resets Orren pacing lock")
	_expect_eq(str(OrrenArc.get_stage(gs, run2).get("id", "")), "sacrifice", "next descent resumes relationship")
	var wait := OrrenArc.apply_choice(gs, run2, "wait")
	_expect_eq(int(wait.get("reward_gold", 0)), 0, "waiting gives no gold")
	_expect_eq(run2.story_move_penalty, -1, "waiting applies real movement burden")
	_expect_true(gs.story_flags.has(OrrenArc.FLAG_WAITED), "waiting advances relationship")
	_expect_true(run2.orren_story_beat_consumed, "sacrifice is the only authored Orren beat this descent")

	# Run 3: ordinary time restores Love.
	var run3 := RunState.create(4243)
	_expect_eq(OrrenArc.stage_id(gs), "attachment", "third descent reaches ordinary attachment scene")
	var love := OrrenArc.apply_choice(gs, run3, "sit")
	_expect_true(gs.story_flags.has(OrrenArc.FLAG_EXPECTED), "sitting creates expectation")
	_expect_true(RecurrenceStory.is_leaf_restored(gs, "love"), "attachment restores Love")
	_expect_eq(str(love.get("story_event", {}).get("leaf_id", "")), "love", "Love returns as story event")
	_expect_true(run3.orren_story_beat_consumed, "Love cannot immediately roll into the next authored beat")

	# Run 4: establish a future before taking it away.
	var run4 := RunState.create(4244)
	_expect_eq(OrrenArc.stage_id(gs), "last_seen", "fourth descent is deliberately ordinary")
	OrrenArc.apply_choice(gs, run4, "promise")
	_expect_true(gs.story_flags.has(OrrenArc.FLAG_LAST_SEEN), "last ordinary meeting persists")
	_expect_true(run4.orren_story_beat_consumed, "promise consumes this descent's authored beat")

	# Run 5: absence restores Grief.
	var run5 := RunState.create(4245)
	_expect_eq(OrrenArc.stage_id(gs), "absence", "later descent becomes the empty stair")
	var grief := OrrenArc.apply_choice(gs, run5, "take_case")
	_expect_true(gs.story_flags.has(OrrenArc.FLAG_ABSENT), "absence persists")
	_expect_true(RecurrenceStory.is_leaf_restored(gs, "grief"), "absence restores Grief")
	_expect_eq(str(grief.get("story_event", {}).get("leaf_id", "")), "grief", "Grief returns as story event")
	_expect_eq(RecurrenceStory.restored_leaf_count(gs), 2, "opening bifurcation restores exactly two Leaves")
	_expect_eq(OrrenArc.stage_id(gs), "after_grief", "future descents acknowledge absence without replaying it")

	# Declining the sacrifice should postpone, not fail, the relationship.
	var gs_decline := FakeState.new()
	var decline_run1 := RunState.create(5001)
	OrrenArc.apply_choice(gs_decline, decline_run1, "map")
	var decline_run2 := RunState.create(5002)
	OrrenArc.apply_choice(gs_decline, decline_run2, "take_route")
	_expect_eq(OrrenArc.stage_id(gs_decline), "sacrifice", "declining the sacrifice does not permanently lock the arc")
	_expect_true(decline_run2.orren_story_beat_consumed, "declining still prevents a second authored beat in the same descent")
	var decline_run3 := RunState.create(5003)
	_expect_eq(str(OrrenArc.get_stage(gs_decline, decline_run3).get("id", "")), "sacrifice", "sacrifice can be reconsidered on a later descent")

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
