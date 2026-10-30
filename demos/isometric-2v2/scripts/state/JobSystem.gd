## JobSystem.gd  Pure RefCounted. JP thresholds and level calculations.
class_name JobSystem
extends RefCounted

const JP_THRESHOLDS: Array[int] = [0, 30, 90, 180, 320, 520, 800]
const TITLES: Array[String] = ["Untrained","Initiate","Apprentice","Adept","Specialist","Veteran","Master"]
const JP_AWARDS: Dictionary = {
	"action_used":6, "weakness_hit":4, "status_applied":4,
	"armor_broken":6, "reaction_chain":8, "battle_clear":18, "boss_clear":35,
}

func get_level(jp: int) -> int:
	var lv := 0
	for i in JP_THRESHOLDS.size():
		if jp >= JP_THRESHOLDS[i]: lv = i
		else: break
	return lv

func get_next_threshold(jp: int) -> int:
	var lv := get_level(jp)
	return 0 if lv >= 6 else JP_THRESHOLDS[lv + 1]

func get_title(jp: int) -> String: return TITLES[get_level(jp)]

func get_progress(jp: int) -> float:
	var lv := get_level(jp)
	if lv >= 6: return 1.0
	return float(jp - JP_THRESHOLDS[lv]) / float(JP_THRESHOLDS[lv + 1] - JP_THRESHOLDS[lv])

func apply_jp(char_data: Dictionary, job_id: String, amount: int) -> Dictionary:
	if not char_data.has("job_jp"): char_data["job_jp"] = {}
	var old_jp: int = char_data["job_jp"].get(job_id, 0)
	var new_jp: int = old_jp + amount
	char_data["job_jp"][job_id] = new_jp
	return {
		"old_jp":old_jp, "new_jp":new_jp,
		"leveled_up":get_level(new_jp) > get_level(old_jp),
		"new_level":get_level(new_jp), "title":get_title(new_jp),
	}

func get_jp_award(event: String) -> int: return JP_AWARDS.get(event, 0)
