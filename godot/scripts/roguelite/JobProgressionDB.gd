class_name JobProgressionDB
extends RefCounted

const JOB_LEVEL_TABLE := [
	{"level": 0, "jp": 0, "title": "Untrained"},
	{"level": 1, "jp": 30, "title": "Initiate"},
	{"level": 2, "jp": 90, "title": "Apprentice"},
	{"level": 3, "jp": 180, "title": "Adept"},
	{"level": 4, "jp": 320, "title": "Specialist"},
	{"level": 5, "jp": 520, "title": "Veteran"},
	{"level": 6, "jp": 800, "title": "Master"},
	{"level": 7, "jp": 1200, "title": "Transcendent"},
	{"level": 8, "jp": 1700, "title": "Mythic"},
]

const JOBS := {
	"warder": {"id": "warder", "name": "Warder", "tier": "base", "unlock": {"character_level": 1, "job_levels": {}, "flags": []}},
	"arcanist": {"id": "arcanist", "name": "Arcanist", "tier": "base", "unlock": {"character_level": 1, "job_levels": {}, "flags": []}},
	"resonant": {"id": "resonant", "name": "Resonant", "tier": "base", "unlock": {"character_level": 1, "job_levels": {}, "flags": []}},
	"luminary": {"id": "luminary", "name": "Luminary", "tier": "base", "unlock": {"character_level": 1, "job_levels": {}, "flags": []}},
	"skywarden": {"id": "skywarden", "name": "Skywarden", "tier": "advanced", "unlock": {"character_level": 4, "job_levels": {"warder": 2}, "flags": ["advanced-jobs-unlocked"]}},
	"chronist": {"id": "chronist", "name": "Chronist", "tier": "advanced", "unlock": {"character_level": 4, "job_levels": {"arcanist": 2}, "flags": ["advanced-jobs-unlocked"]}},
	"oathbound": {"id": "oathbound", "name": "Oathbound", "tier": "advanced", "unlock": {"character_level": 6, "job_levels": {"warder": 2, "luminary": 2}, "flags": ["advanced-jobs-unlocked"]}},
	"voidcaller": {"id": "voidcaller", "name": "Voidcaller", "tier": "advanced", "unlock": {"character_level": 6, "job_levels": {"arcanist": 3, "resonant": 1}, "flags": ["advanced-jobs-unlocked"]}},
	"breaker": {"id": "breaker", "name": "Null Breaker", "tier": "ascended", "unlock": {"character_level": 12, "job_levels": {"warder": 5, "skywarden": 2, "oathbound": 2}, "flags": ["ascended-jobs-unlocked"]}},
	"etherweaver": {"id": "etherweaver", "name": "Etherweaver", "tier": "ascended", "unlock": {"character_level": 12, "job_levels": {"arcanist": 5, "chronist": 3, "voidcaller": 2}, "flags": ["ascended-jobs-unlocked"]}},
}

static func get_job(job_id: String) -> Dictionary:
	return JOBS.get(job_id, {}).duplicate(true)

static func get_job_level_from_jp(jp: int) -> int:
	var level := 0
	for row: Dictionary in JOB_LEVEL_TABLE:
		if jp >= int(row.jp):
			level = int(row.level)
	return level

static func get_jp_for_next_level(jp: int) -> int:
	var current := get_job_level_from_jp(jp)
	for row: Dictionary in JOB_LEVEL_TABLE:
		if int(row.level) == current + 1:
			return max(0, int(row.jp) - jp)
	return 0

static func can_unlock_job(character_level: int, job_levels: Dictionary, unlock_flags: Array[String], job_id: String) -> bool:
	var job := get_job(job_id)
	if job.is_empty():
		return false
	var unlock: Dictionary = job.get("unlock", {})
	if character_level < int(unlock.get("character_level", 1)):
		return false
	for required_job_id: String in unlock.get("job_levels", {}).keys():
		if int(job_levels.get(required_job_id, 0)) < int(unlock["job_levels"][required_job_id]):
			return false
	for flag: String in unlock.get("flags", []):
		if flag not in unlock_flags:
			return false
	return true

static func get_unlocked_jobs(character_level: int, job_levels: Dictionary, unlock_flags: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for job_id: String in JOBS.keys():
		if can_unlock_job(character_level, job_levels, unlock_flags, job_id):
			result.append(job_id)
	return result
