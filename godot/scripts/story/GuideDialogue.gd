class_name GuideDialogue
extends RefCounted

const RecurrenceStory = preload("res://scripts/story/RecurrenceStory.gd")
const GUIDE_COLOR := Color(0.76, 0.70, 0.92)

static func get_line(gs: Node) -> Dictionary:
	if gs == null:
		return {}
	var first_meeting := RecurrenceStory.add_flag(gs, RecurrenceStory.GUIDE_MET_FLAG)
	if first_meeting and gs.has_method("save"):
		gs.save()
	var count := RecurrenceStory.restored_leaf_count(gs)
	var floor := int(gs.get("last_run_floor")) if gs.get("last_run_floor") != null else int(gs.get("run_floor_reached"))
	var death: Dictionary = gs.get("last_run_death") if gs.get("last_run_death") != null else {}
	var story_flags: Array = gs.story_flags if gs.get("story_flags") != null else []
	var waited_for_orren := story_flags.has("orrens_waited")
	var expected_orren := story_flags.has("orrens_expected")
	var orren_absent := story_flags.has("orrens_absent")
	var pool: Array[String] = []

	if RecurrenceStory.is_leaf_restored(gs, "grief") and orren_absent:
		pool = [
			'"I remember every time Orren stood at that stair. I remember the angle of the lantern, the map case, the coastlines he drew where none were needed. Why did the empty place feel larger than he did?"',
			'"I possess every conversation you had with him. None of it tells me where he is now. I dislike that sentence."',
			'"You expected the lantern. Expectation points toward a future. I had forgotten that memory could do that."',
		]
	elif RecurrenceStory.is_leaf_restored(gs, "love") and expected_orren:
		pool = [
			'"You look for the green lantern before you read the route now. When did that begin?"',
			'"Orren says next time as though next time is a place. You believed him. I think that belief matters."',
			'"There was a table in the Leaf. There is a stair in yours. Different memory. Same strange certainty that someone will be there."',
		]
	elif count == 0 and waited_for_orren:
		pool = [
			'"You surrendered distance for a man you barely knew and a stranger whose name you never learned. Was that inefficient?"',
			'"You carried someone else more slowly than you could have left them. I know what it cost. I do not yet understand why the cost changed the choice."',
		]
	elif count == 0:
		pool = [
			'"Before you go again, answer something useless for me. Which person in your party do you look for first when the fighting stops?"',
			'"You choose differently when you are tired. I know the pattern. I do not know why the choice feels more like yours then."',
			'"I know the road ahead of you. I would rather know what you noticed on the way back."',
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
		"portrait": "res://assets/ui/portraits/guide-portrait-v01.png",
		"color": GUIDE_COLOR,
		"category": str(RecurrenceStory.guide_stage(gs).get("id", "grey")),
	}
