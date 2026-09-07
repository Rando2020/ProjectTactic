## Sole disk owner. Slot 1 is the autosave; each slot is a complete snapshot.
extends Node

const SCHEMA := 3
const PATH := "user://save_%d.json"
const SLOTS := 3
var _transaction_depth: int = 0
var last_error: String = ""

func _ready() -> void:
	if FileAccess.file_exists(PATH % 1):
		load_slot()
	else:
		_import_legacy()

func begin_transaction() -> void:
	_transaction_depth += 1

func commit_transaction() -> bool:
	_transaction_depth = maxi(0, _transaction_depth - 1)
	return save() if _transaction_depth == 0 else true

func save(slot: int = 1) -> bool:
	if slot < 1 or slot > SLOTS:
		return false
	if _transaction_depth > 0:
		return true
	var data := _serialize()
	var target := PATH % slot
	var temp := target + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return _fail("Could not open checkpoint for writing.")
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return _fail("Could not write checkpoint.")
	if DirAccess.rename_absolute(temp, target) != OK:
		return _fail("Could not replace checkpoint; previous save retained.")
	last_error = ""
	return true

func load_slot(slot: int = 1) -> bool:
	if _transaction_depth > 0 or slot < 1 or slot > SLOTS:
		return false
	var data := _read(PATH % slot)
	if int(data.get("schema", 0)) in [1, 2]:
		data = _migrate_slot(data)
	if not _valid(data):
		return _fail("Save is missing, damaged, or from an unsupported version.")
	_deserialize(data)
	last_error = ""
	return true

func has_save(slot: int = 1) -> bool:
	if slot < 1 or slot > SLOTS:
		return false
	var data := _read(PATH % slot)
	if int(data.get("schema", 0)) in [1, 2]:
		data = _migrate_slot(data)
	return _valid(data)

func delete_slot(slot: int = 1) -> void:
	if slot >= 1 and slot <= SLOTS:
		DirAccess.remove_absolute(PATH % slot)

func get_summary(slot: int = 1) -> Dictionary:
	if not has_save(slot):
		return {"exists": false}
	var data := _read(PATH % slot)
	if int(data.get("schema", 0)) in [1, 2]:
		data = _migrate_slot(data)
	var run: Dictionary = data.get("active_run", {})
	return {"exists": true, "gold": data["progress"].get("gold", 0),
		"floor": run.get("floor", 1), "saved_at": data.get("saved_at", "")}

func continue_scene() -> String:
	var gs := get_node("/root/GameState")
	return "res://scenes/StageSelect.tscn" if gs.active_run != null and not gs.active_run.completed else "res://scenes/HubScene.tscn"

func _serialize() -> Dictionary:
	var gs := get_node("/root/GameState")
	var rm := get_node("/root/RunManager")
	var run: Dictionary = {}
	if gs.active_run:
		rm.current_stage = gs.active_run.current_floor
		rm.active_boons.assign(gs.active_run.active_boons)
		gs.active_run.run_aether = rm.run_aether
		gs.active_run.rng_state = str(rm.rng.state)
		gs.active_run.inventory = gs.run_inventory.duplicate(true)
		run = gs.active_run.to_dict()
	var transient := {}
	for key in ["pending_rewards", "pending_loot", "pending_boon_offers", "last_run_death", "run_inventory", "run_floor_reached", "run_jp_earned", "runs_completed", "best_floor_reached", "selected_map_index"]:
		transient[key] = gs.get(key)
	return {"schema": SCHEMA, "saved_at": Time.get_datetime_string_from_system(),
		"progress": gs.to_dict(), "unit_registry": gs.unit_registry,
		"active_run": run, "transient": transient,
		"meta": get_node("/root/MetaProgression").to_dict()}

func _deserialize(data: Dictionary) -> void:
	var gs := get_node("/root/GameState")
	gs.restore_progress(data["progress"])
	for uid: String in data.get("unit_registry", {}):
		if not gs.unit_registry.has(uid):
			gs.unit_registry[uid] = {}
		gs.unit_registry[uid].merge(data["unit_registry"][uid], true)
	var rd: Dictionary = data["active_run"]
	gs.active_run = null if rd.is_empty() else RunState.from_dict(rd)
	var transient: Dictionary = data.get("transient", {})
	for key in ["pending_rewards", "last_run_death"]:
		gs.set(key, transient.get(key, {}).duplicate(true))
	for key in ["pending_loot", "pending_boon_offers", "run_inventory"]:
		gs.set(key, transient.get(key, []).duplicate(true))
	for key in ["run_floor_reached", "run_jp_earned", "runs_completed", "best_floor_reached", "selected_map_index"]:
		gs.set(key, int(transient.get(key, 0)))
	if gs.active_run:
		gs.run_inventory = gs.active_run.inventory.duplicate(true)
	get_node("/root/MetaProgression").restore_progress(data["meta"])
	get_node("/root/RunManager").restore_from_run()

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	return json.data if error == OK and json.data is Dictionary else {}

func _valid(data: Dictionary) -> bool:
	if data.get("schema", 0) != SCHEMA:
		return false
	for key in ["progress", "unit_registry", "active_run", "transient", "meta"]:
		if not data.get(key) is Dictionary:
			return false
	for value: Variant in data["unit_registry"].values():
		if not value is Dictionary:
			return false
	var run: Dictionary = data["active_run"]
	if not run.is_empty():
		if not run.get("floor_plan") is Array or run["floor_plan"].is_empty():
			return false
		if int(run.get("node", -1)) < 0 or int(run.get("node", -1)) >= run["floor_plan"].size():
			return false
		for node: Variant in run["floor_plan"]:
			if not node is Dictionary:
				return false
		for key in ["active_boons", "active_curses", "run_deployment", "inventory", "active_wanderer_conditions"]:
			if not run.get(key, []) is Array:
				return false
		if not run.get("claimed_rewards", {}) is Dictionary:
			return false
	for key in ["completed_stages", "story_flags"]:
		if not data["progress"].get(key, []) is Array:
			return false
	for key in ["unit_jp", "unit_learned", "unit_jobs", "unit_job_jp", "unit_equipped", "unit_equipment", "vow_progress", "sigil_progress"]:
		if not data["progress"].get(key, {}) is Dictionary:
			return false
	for key in ["unit_learned", "unit_equipped"]:
		for value: Variant in data["progress"].get(key, {}).values():
			if not value is Array:
				return false
	for key in ["pending_rewards", "last_run_death"]:
		if not data["transient"].get(key, {}) is Dictionary:
			return false
	for key in ["pending_loot", "pending_boon_offers", "run_inventory"]:
		if not data["transient"].get(key, []) is Array:
			return false
	for key in ["currencies", "permanent_upgrades"]:
		if not data["meta"].get(key, {}) is Dictionary:
			return false
	return data["meta"].get("unlocked_flags", []) is Array

func _migrate_slot(old: Dictionary) -> Dictionary:
	# Old slots omitted meta balances and equipment; retain legacy campaign defaults.
	var progress := _read("user://save.json")
	progress["gold"] = old.get("gold", 0)
	progress["completed_stages"] = old.get("completed_stages", [])
	var flags: Variant = old.get("story_flags", [])
	progress["story_flags"] = flags if flags is Array else []
	return {"schema": SCHEMA, "progress": progress, "unit_registry": old.get("unit_registry", {}),
		"active_run": old.get("active_run", {}), "transient": {},
		"meta": _read("user://meta-progression.json")}

func _import_legacy() -> void:
	var progress := _read("user://save.json")
	var meta := _read("user://meta-progression.json")
	if progress.is_empty() and meta.is_empty():
		return
	if not progress.is_empty() and progress.get("version", 0) != 1:
		return
	var data := {"schema": SCHEMA, "progress": progress, "unit_registry": {},
		"active_run": {}, "transient": {}, "meta": meta}
	if _valid(data):
		_deserialize(data)
		save()

func _fail(message: String) -> bool:
	last_error = message
	push_warning(message)
	return false
