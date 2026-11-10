class_name AbilityCommands
extends RefCounted
## Read-only battle-loadout projection. A hero can have any number of schools.
## Labels/assignments are provisional content metadata, not job or damage rules.
const SCHOOLS := {
	"black": "Black Magic",
	"white": "White Magic",
	"time": "Time Magic",
	"arcane": "Arcane Magic",
	"other": "Other Magic",
}

static func school_label(id: String) -> String:
	return str(SCHOOLS.get(id, id.capitalize() + " Magic"))

static func catalog(ids: Array) -> Dictionary:
	var result := {"skills": [], "schools": []}
	var grouped: Dictionary = {}
	for id in AbilityDB.canonical_ids(ids):
		var ability := AbilityDB.get_ability(id)
		if ability.is_empty(): continue
		if str(ability.get("command_category", "skills")) != "magic":
			result.skills.append(id)
			continue
		var school := str(ability.get("magic_school", "other"))
		if school.is_empty(): school = "other"
		if not grouped.has(school): grouped[school] = []
		grouped[school].append(id)
	# Stable catalog order, with future schools following their learned order.
	var order: Array = SCHOOLS.keys()
	for school in grouped:
		if school not in order: order.append(school)
	for school in order:
		if grouped.has(school):
			result.schools.append({"id": school, "label": school_label(school), "abilities": grouped[school]})
	return result
