class_name GuideDialogue
extends RefCounted

const RecurrenceStory = preload("res://scripts/story/RecurrenceStory.gd")
const GUIDE_COLOR := Color(0.76, 0.70, 0.92)

static func get_line(gs: Node) -> Dictionary:
	if gs == null:
		return {}
	var count := RecurrenceStory.restored_leaf_count(gs)
	var floor := int(gs.get("last_run_floor")) if gs.get("last_run_floor") != null else int(gs.get("run_floor_reached"))
	var death: Dictionary = gs.get("last_run_death") if gs.get("last_run_death") != null else {}
	var pool: Array[String] = []

	if count == 0:
		pool = [
			'"Before you go again, answer something useless for me. Which person in your party do you look for first when the fighting stops?"',
			'"You choose differently when you are tired. I know the pattern. I do not know why the choice feels more like yours then."',
			'"I know the road ahead of you. I would rather know what you noticed on the way back."',
		]
	elif RecurrenceStory.is_leaf_restored(gs, "grief"):
		pool = [
			'"I remembered someone today. I possess every memory of her. I can reproduce the cadence of her voice. I still miss her. Explain that to me."',
			'"If you had known loving them would make losing them hurt this much, would you still have done it?"',
			'"There used to be six chairs at the table. I remember everyone who sat in them. That is not the same as believing they will be there tomorrow."',
		]
	elif RecurrenceStory.is_leaf_restored(gs, "love"):
		pool = [
			'"When did you know you cared about someone? Not when you decided to. When did you notice it had already happened?"',
			'"There was a table. Six chairs. Someone laughed before I knew what the joke was. I had forgotten that a memory could arrive before its explanation."',
			'"I used to think affection was knowledge accumulated over time. I am beginning to suspect I had the order wrong."',
		]
	else:
		pool = [
			'"You came back. Tell me one thing that happened that did not help you win."',
		]

	if not death.is_empty() and floor >= 4 and RecurrenceStory.is_leaf_restored(gs, "love") and not RecurrenceStory.is_leaf_restored(gs, "grief"):
		pool = [
			'"You are quieter this time. I know what happened. I do not know what it cost you. Is that the difference?"',
		]

	var line := pool[randi() % pool.size()]
	return {
		"line": line,
		"name": "The Guide",
		"title": "Keeper of the Returning Road",
		"portrait": "?",
		"color": GUIDE_COLOR,
		"category": str(RecurrenceStory.guide_stage(gs).get("id", "grey")),
	}
