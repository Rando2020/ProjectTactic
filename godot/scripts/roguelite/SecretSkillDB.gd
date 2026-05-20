class_name SecretSkillDB
extends RefCounted

const SECRET_SKILLS := {
	"resonance-fracture": {"id": "resonance-fracture", "name": "Resonance Fracture", "element": "resonance", "target": "all-enemies", "range": 5, "power": 90, "mp_cost": 60, "teacher_required": "the-wandering-null", "description": "Deals resonance damage to all enemies and strips one status."},
	"null-break": {"id": "null-break", "name": "Null-Break", "element": "resonance", "target": "enemy", "range": 2, "power": 45, "mp_cost": 35, "teacher_required": "void-scholar-thresh", "description": "Disrupts a target elite prefix for the rest of the run."},
	"leyline-burst": {"id": "leyline-burst", "name": "Leyline Burst", "element": "holy", "target": "area", "range": 3, "power": 55, "mp_cost": 40, "teacher_required": "archive-mage-volant", "description": "Deals holy and fire damage in an area and ignites terrain."},
	"last-rites": {"id": "last-rites", "name": "Last Rites", "element": "holy", "target": "ally", "range": 4, "power": 0, "mp_cost": 30, "teacher_required": "chaplain-aldis", "description": "When a party member would fall, they get one final free action.", "is_passive": true},
	"blaze-counter": {"id": "blaze-counter", "name": "Blaze Counter", "element": "fire", "target": "auto", "range": 0, "power": 50, "mp_cost": 0, "teacher_required": "ember-knight-solara", "description": "Once per battle, counter with a fire-wreathed blow when struck.", "is_passive": true, "trigger": "on-hit"},
	"sunder-armor": {"id": "sunder-armor", "name": "Sunder Armor", "element": "none", "target": "enemy", "range": 1, "power": 30, "mp_cost": 20, "teacher_required": "iron-duelist-garek", "description": "Deals damage and reduces target physical defense for the run."},
	"arc-counter": {"id": "arc-counter", "name": "Arc Counter", "element": "thunder", "target": "auto", "range": 0, "power": 40, "mp_cost": 0, "teacher_required": "storm-duelist-kira", "description": "Once per battle, auto-counter with thunder when struck.", "is_passive": true, "trigger": "on-hit"},
	"dark-echo": {"id": "dark-echo", "name": "Dark Echo", "element": "dark", "target": "enemy", "range": 3, "power": 60, "mp_cost": 25, "teacher_required": "shadow-of-vaelthorn", "description": "Mirrors the last enemy ability as dark-typed damage."},
}

const UNIT_SPECIFIC := {
	"zane": ["resonance-fracture", "null-break"],
	"mira": ["leyline-burst", "last-rites"],
	"kael": ["blaze-counter", "sunder-armor"],
}

const NEUTRAL_SKILLS := ["arc-counter", "dark-echo"]

static func get_secret_skill(skill_id: String) -> Dictionary:
	return SECRET_SKILLS.get(skill_id, {}).duplicate(true)

static func get_secret_skills_for_unit(unit_id: String) -> Array[Dictionary]:
	var ids: Array = UNIT_SPECIFIC.get(unit_id, []).duplicate()
	ids.append_array(NEUTRAL_SKILLS)
	var result: Array[Dictionary] = []
	for skill_id: String in ids:
		if SECRET_SKILLS.has(skill_id):
			result.append(SECRET_SKILLS[skill_id].duplicate(true))
	return result
