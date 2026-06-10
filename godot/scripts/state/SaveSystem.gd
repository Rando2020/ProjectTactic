## SaveSystem.gd  Autoload. 3 save slots, schema v2, run state included.
extends Node

const SCHEMA := 2
const PATH   := "user://save_%d.json"
const SLOTS  := 3

func save(slot: int = 1) -> bool:
	if slot < 1 or slot > SLOTS: return false
	var gs := _gs(); if not gs: return false
	var file := FileAccess.open(PATH % slot, FileAccess.WRITE)
	if not file: return false
	file.store_string(JSON.stringify(_serialize(gs), "\t"))
	file.close(); return true

func load_slot(slot: int = 1) -> bool:
	if not has_save(slot): return false
	var file := FileAccess.open(PATH % slot, FileAccess.READ)
	if not file: return false
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary: return false
	if int(data.get("schema", 1)) < SCHEMA: data = _migrate(data)
	_deserialize(data); return true

func has_save(slot: int = 1) -> bool:
	return FileAccess.file_exists(PATH % slot)

func delete_slot(slot: int = 1) -> void:
	if has_save(slot): DirAccess.remove_absolute(PATH % slot)

func get_summary(slot: int = 1) -> Dictionary:
	if not has_save(slot): return {"exists":false}
	var file := FileAccess.open(PATH % slot, FileAccess.READ)
	if not file: return {"exists":false}
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary: return {"exists":false}
	return {
		"exists":    true,
		"gold":      data.get("gold",    0),
		"floor":     data.get("floor",   0),
		"boons":     data.get("boons",   0),
		"saved_at":  data.get("saved_at",""),
	}

func _serialize(gs: Node) -> Dictionary:
	var units: Dictionary = {}
	for uid in gs.unit_registry:
		var r: Dictionary = gs.unit_registry[uid]
		units[uid] = {
			"jp":r.get("jp",0), "learned_abilities":r.get("learned_abilities",[]),
			"current_job_id":r.get("current_job_id",""), "job_jp":r.get("job_jp",{}),
			"unlocked_jobs":r.get("unlocked_jobs",[]),
		}
	var run_dict: Dictionary = {}
	if gs.get("active_run") and gs.active_run:
		run_dict = gs.active_run.to_dict()
	return {
		"schema":SCHEMA, "saved_at":Time.get_datetime_string_from_system(),
		"gold":gs.gold, "completed_stages":gs.completed_stages,
		"story_flags":gs.get("story_flags") or [],
		"unit_registry":units, "active_run":run_dict,
		# Top-level summary fields read by get_summary() without parsing nested run.
		"floor": gs.active_run.current_floor if gs.active_run else 0,
		"boons": gs.active_run.active_boons.size() if gs.active_run else 0,
	}

func _deserialize(data: Dictionary) -> void:
	var gs := _gs(); if not gs: return
	gs.gold             = data.get("gold", 0)
	gs.completed_stages = data.get("completed_stages", [])
	if gs.get("story_flags") != null: gs.story_flags = data.get("story_flags", [])
	var rd: Dictionary = data.get("active_run", {})
	if not rd.is_empty():
		gs.active_run = RunState.from_dict(rd)
	for uid in data.get("unit_registry", {}):
		if not gs.unit_registry.has(uid): continue
		gs.unit_registry[uid].merge(data["unit_registry"][uid], true)

func _migrate(data: Dictionary) -> Dictionary:
	var r := data.duplicate(true)
	r["story_flags"] = r.get("story_flags", [])
	r["active_run"]  = r.get("active_run", {})
	r["schema"] = SCHEMA; return r

func _gs() -> Node: return get_node_or_null("/root/GameState")
