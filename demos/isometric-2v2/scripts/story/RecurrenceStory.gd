class_name RecurrenceStory
extends RefCounted

const MANIFEST_PATH := "res://data/story/recurrence_manifest.json"
const LEAF_FLAG_PREFIX := "recurrence_leaf_"
const GUIDE_MET_FLAG := "recurrence_guide_met"
const GIGAS_DISCOVERED_FLAG := "recurrence_gigas_discovered"
const CONTINUANCE_REVEALED_FLAG := "continuance_revealed"

static var _manifest_cache: Dictionary = {}

static func manifest() -> Dictionary:
	if not _manifest_cache.is_empty():
		return _manifest_cache
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_error("RecurrenceStory: missing manifest at %s" % MANIFEST_PATH)
		return {}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("RecurrenceStory: could not open manifest.")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_manifest_cache = (parsed as Dictionary).duplicate(true)
	else:
		push_error("RecurrenceStory: manifest is not a Dictionary.")
	return _manifest_cache

static func leaf_flag(leaf_id: String) -> String:
	return LEAF_FLAG_PREFIX + leaf_id

static func has_flag(gs: Node, flag_id: String) -> bool:
	if gs == null or gs.get("story_flags") == null:
		return false
	return flag_id in gs.story_flags

static func add_flag(gs: Node, flag_id: String) -> bool:
	if gs == null or gs.get("story_flags") == null:
		return false
	if flag_id in gs.story_flags:
		return false
	gs.story_flags.append(flag_id)
	return true

static func is_leaf_restored(gs: Node, leaf_id: String) -> bool:
	return has_flag(gs, leaf_flag(leaf_id))

static func restored_leaf_ids(gs: Node) -> Array[String]:
	var restored: Array[String] = []
	for leaf: Dictionary in manifest().get("leaves", []):
		var leaf_id := str(leaf.get("id", ""))
		if not leaf_id.is_empty() and is_leaf_restored(gs, leaf_id):
			restored.append(leaf_id)
	return restored

static func restored_leaf_count(gs: Node) -> int:
	return restored_leaf_ids(gs).size()

static func get_leaf(leaf_id: String) -> Dictionary:
	for leaf: Dictionary in manifest().get("leaves", []):
		if str(leaf.get("id", "")) == leaf_id:
			return leaf
	return {}

static func restore_leaf(gs: Node, leaf_id: String) -> Dictionary:
	var leaf := get_leaf(leaf_id)
	if leaf.is_empty():
		return {}
	if is_leaf_restored(gs, leaf_id):
		return {}
	add_flag(gs, leaf_flag(leaf_id))
	add_flag(gs, GIGAS_DISCOVERED_FLAG)
	add_flag(gs, "recurrence_fragment_restored")
	if gs.has_method("save"):
		gs.save()
	return {
		"type": "leaf_restored",
		"leaf_id": leaf_id,
		"title": str(leaf.get("title", "A Sealed Leaf")),
		"text": str(leaf.get("restoration_event", leaf.get("player_summary", ""))),
		"guide_change": str(leaf.get("guide_change", "")),
	}

static func guide_stage(gs: Node) -> Dictionary:
	var count := restored_leaf_count(gs)
	var selected: Dictionary = {}
	var guide_data: Dictionary = manifest().get("guide", {})
	for stage: Dictionary in guide_data.get("stages", []):
		if count >= int(stage.get("min_leaves", 0)):
			selected = stage
	return selected

static func record_run_outcome(gs: Node, _victory: bool, _floor_reached: int, _was_defeat: bool) -> Dictionary:
	if gs == null:
		return {}
	add_flag(gs, GUIDE_MET_FLAG)
	if gs.has_method("save"):
		gs.save()
	return {}

static func codex_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = [
		{
			"id": "the_guide",
			"category": "Characters",
			"flag": GUIDE_MET_FLAG,
			"title": "The Guide",
			"summary": "The voice at the Last Hearth remembers routes no living cartographer drew. It is gentle with the Appointed and strangely interested in answers that have no tactical value.",
			"gameplay_note": "The Guide's dialogue changes as sealed Leaves are restored.",
		},
		{
			"id": "the_gigas_codex",
			"category": "Mysteries",
			"flag": GIGAS_DISCOVERED_FLAG,
			"title": "The Gigas Codex",
			"summary": "An impossible chronicle survives in fragments. Ten Leaves were deliberately removed. The text before the absence argues, contradicts itself, and speaks as many people. The surviving hand after the gap grows unnervingly singular.",
			"gameplay_note": "Restored Leaves are permanent across runs.",
		},
		{
			"id": "the_sealed_leaves",
			"category": "Mysteries",
			"flag": "recurrence_fragment_restored",
			"title": "The Sealed Leaves",
			"summary": "The missing Leaves do not behave like ordinary records. Restoring one changes the Guide before it explains anything about the past.",
			"gameplay_note": "Ten Leaves form five paired human experiences.",
		},
	]
	for leaf: Dictionary in manifest().get("leaves", []):
		var leaf_id := str(leaf.get("id", ""))
		entries.append({
			"id": "leaf_" + leaf_id,
			"category": "Mysteries",
			"flag": leaf_flag(leaf_id),
			"title": str(leaf.get("title", leaf_id.capitalize())),
			"summary": str(leaf.get("player_summary", "")),
			"gameplay_note": str(leaf.get("guide_change", "")),
		})
	return entries

static func all_leaf_ids() -> Array[String]:
	var ids: Array[String] = []
	for leaf: Dictionary in manifest().get("leaves", []):
		ids.append(str(leaf.get("id", "")))
	return ids

static func can_sever(gs: Node) -> bool:
	for leaf_id: String in all_leaf_ids():
		if not is_leaf_restored(gs, leaf_id):
			return false
	return has_flag(gs, CONTINUANCE_REVEALED_FLAG)

static func available_endings(gs: Node) -> Array[String]:
	var endings: Array[String] = ["recurrence", "return"]
	if can_sever(gs):
		endings.append("severance")
	if can_sever(gs) and has_flag(gs, "guide_accepts_otherness"):
		endings.append("release")
	return endings
