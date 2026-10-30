class_name OrrenArc
extends RefCounted

const RecurrenceStory = preload("res://scripts/story/RecurrenceStory.gd")
const DATA_PATH := "res://data/story/orren_arc.json"

const FLAG_MET := "met_orren"
const FLAG_WAITED := "orrens_waited"
const FLAG_EXPECTED := "orrens_expected"
const FLAG_LAST_SEEN := "orrens_last_seen"
const FLAG_ABSENT := "orrens_absent"
const FLAG_DECLINED_WAIT := "orrens_declined_wait"

static var _data_cache: Dictionary = {}


static func data() -> Dictionary:
	if not _data_cache.is_empty():
		return _data_cache
	if not FileAccess.file_exists(DATA_PATH):
		push_error("OrrenArc: missing data at %s" % DATA_PATH)
		return {}
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("OrrenArc: could not open story data.")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_data_cache = (parsed as Dictionary).duplicate(true)
	else:
		push_error("OrrenArc: story data is not a Dictionary.")
	return _data_cache


static func has_flag(gs: Node, flag_id: String) -> bool:
	return RecurrenceStory.has_flag(gs, flag_id)


static func stage_id(gs: Node) -> String:
	if has_flag(gs, FLAG_ABSENT):
		return "after_grief"
	if has_flag(gs, FLAG_LAST_SEEN):
		return "absence"
	if has_flag(gs, FLAG_EXPECTED):
		return "last_seen"
	if has_flag(gs, FLAG_WAITED):
		return "attachment"
	if has_flag(gs, FLAG_MET):
		return "sacrifice"
	return "first"


static func get_stage(gs: Node, run: RunState = null) -> Dictionary:
	var wanted := "interlude" if run != null and run.orren_story_beat_consumed else stage_id(gs)
	for stage: Dictionary in data().get("stages", []):
		if str(stage.get("id", "")) == wanted:
			return stage
	return {}


static func get_choice(gs: Node, run: RunState, choice_id: String) -> Dictionary:
	var stage := get_stage(gs, run)
	for choice: Dictionary in stage.get("choices", []):
		if str(choice.get("id", "")) == choice_id:
			return choice
	return {}


static func gold_reward(run: RunState) -> int:
	return 70 + int(run.current_floor) * 30 if run != null else 100


static func jp_reward(run: RunState) -> int:
	return 18 + int(run.current_floor) * 5 if run != null else 24


static func apply_choice(gs: Node, run: RunState, choice_id: String) -> Dictionary:
	if gs == null or run == null:
		return {}
	var stage := get_stage(gs, run)
	var stage_name := str(stage.get("id", ""))
	var choice := get_choice(gs, run, choice_id)
	if choice.is_empty():
		return {}

	var result := {
		"choice_id": choice_id,
		"effect": str(choice.get("effect", "")),
		"reward_gold": 0,
		"reward_jp": 0,
		"story_event": {},
	}

	match str(choice.get("effect", "")):
		"interlude_gold":
			result["reward_gold"] = gold_reward(run)
		"interlude_jp":
			result["reward_jp"] = jp_reward(run)
		"gold":
			RecurrenceStory.add_flag(gs, FLAG_MET)
			result["reward_gold"] = gold_reward(run)
		"jp":
			RecurrenceStory.add_flag(gs, FLAG_MET)
			result["reward_jp"] = jp_reward(run)
		"gold_without_progress":
			RecurrenceStory.add_flag(gs, FLAG_MET)
			RecurrenceStory.add_flag(gs, FLAG_DECLINED_WAIT)
			result["reward_gold"] = gold_reward(run)
		"wait":
			RecurrenceStory.add_flag(gs, FLAG_MET)
			RecurrenceStory.add_flag(gs, FLAG_WAITED)
			run.story_move_penalty = mini(run.story_move_penalty, -1)
		"love":
			RecurrenceStory.add_flag(gs, FLAG_EXPECTED)
			result["story_event"] = RecurrenceStory.restore_leaf(gs, "love")
		"last_seen":
			RecurrenceStory.add_flag(gs, FLAG_LAST_SEEN)
		"grief":
			RecurrenceStory.add_flag(gs, FLAG_ABSENT)
			result["story_event"] = RecurrenceStory.restore_leaf(gs, "grief")

	if stage_name != "interlude":
		run.orren_story_beat_consumed = true

	if gs.has_method("save"):
		gs.save()
	return result


static func codex_entries() -> Array[Dictionary]:
	return [
		{
			"id": "orren_lower_stair",
			"category": "Characters",
			"flag": FLAG_MET,
			"title": "Orren of the Lower Stair",
			"summary": "A vault-runner with a green lantern and a silver map case. His maps are imprecise in ways that repeatedly turn out to be useful.",
			"gameplay_note": "Orren remembers how you treat him across descents.",
		},
		{
			"id": "orrens_burden",
			"category": "Characters",
			"flag": FLAG_WAITED,
			"title": "Someone Else's Weight",
			"summary": "You gave up distance to help Orren carry a wounded stranger through the lower stair.",
			"gameplay_note": "That descent carries a movement penalty. The relationship advances because the choice cost something.",
		},
		{
			"id": "empty_stair",
			"category": "Mysteries",
			"flag": FLAG_ABSENT,
			"title": "The Empty Stair",
			"summary": "Orren's map case was found where he had promised to return. No body, blood, or departure mark explained his absence.",
			"gameplay_note": "Absence is not proof of death. It is proof that expectation had formed.",
		},
	]


static func choice_label(choice: Dictionary, run: RunState) -> String:
	var label := str(choice.get("label", "Continue"))
	label = label.replace("{gold}", str(gold_reward(run)))
	label = label.replace("{jp}", str(jp_reward(run)))
	return label
