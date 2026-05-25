## GameState.gd    Autoload singleton.
## Persists player progress (JP, gold, learned abilities, completed stages)
## across scene transitions.  Never freed between battles.
##
## Save format (user://save.json):
##   version          : int   (must == SAVE_VERSION)
##   gold             : int
##   completed_stages : Array[String]
##   unit_jp          : { uid -> int }
##   unit_learned     : { uid -> Array[String] }
extends Node

const AbilityDBScript := preload("res://scripts/data/AbilityDB.gd")
const VowSigilDefs := preload("res://scripts/roguelike/VowSigilSystem.gd")
const SAVE_PATH    := "user://save.json"
const SAVE_VERSION := 1

## Which map to load when transitioning into Battle.tscn  (0 = Ashvale, 1 = Crypt)
var selected_map_index: int = 0

## Gold accumulated across all battles
var gold: int = 0

## Stages the player has beaten at least once
var completed_stages: Array[String] = []

## Rewards from the most recent victory  read by ResultsScreen
var pending_rewards: Dictionary = {}

## Roguelike run state
var active_run:           RunState = null
var story_flags:          Array[String] = []
var pending_loot:         Array = []
var pending_boon_offers:  Array = []

## Last run death context  read by ResultsScreen + HubDialogue
var last_run_death: Dictionary = {}
## Run history  floors completed, used by hub dialogue
var runs_completed: int = 0
var best_floor_reached: int = 0

## Items accumulated during the current run (mirrors active_run.inventory)
var run_inventory:        Array = []
var vow_progress:         Dictionary = {}
var sigil_progress:       Dictionary = {}

## Retrieve and clear the pending deployment array written by DeploymentScreen.
## Call from BattleScene._ready() to get the player's chosen unit positions.
func pop_pending_deployment() -> Array:
	if active_run == null or not active_run.has_meta("pending_deployment"):
		return []
	var dep: Array = active_run.get_meta("pending_deployment", [])
	active_run.remove_meta("pending_deployment")
	return dep
## Highest floor reached this run (for ResultsScreen)
var run_floor_reached:    int   = 0
## Total JP earned this run (for ResultsScreen)
var run_jp_earned:        int   = 0

## Per-unit persistent data.
## unit_id -> {
##   display_name      : String,
##   jp                : int,
##   base_abilities    : Array[String],   (always available, cannot be spent)
##   learned_abilities : Array[String],   (JP-purchased)
##   learnable_abilities: Array[String],  (purchaseable pool)
## }
var unit_registry: Dictionary = {}


func _ready() -> void:
	if not load_save():
		_init_defaults()


func _init_defaults() -> void:
	# Zane  Arcanist path  Resonant
	_reg("zane", "Zane",
		["fireball", "thunderstrike", "void_pulse"],
		["blizzard", "dark_breath", "elemental_convergence"])
	unit_registry["zane"]["current_job_id"] = "arcanist"
	unit_registry["zane"]["job_jp"]         = { "arcanist": 0 }

	# Mira  Arcanist  Luminary path
	_reg("mira", "Mira Vey",
		["fireball", "cure", "holy_strike"],
		["blizzard", "luminous_barrier", "mass_cure"])
	unit_registry["mira"]["current_job_id"] = "arcanist"
	unit_registry["mira"]["job_jp"]         = { "arcanist": 0 }

	# Kael  Squire  Warder  Void Knight path
	_reg("kael", "Kael",
		["slash", "mighty_strike", "defend"],
		["cover_ally", "iron_wall", "retribution"])
	unit_registry["kael"]["current_job_id"] = "squire"
	unit_registry["kael"]["job_jp"]         = { "squire": 0 }

	# Lyra  Scout  Shadow path
	_reg("lyra", "Lyra",
		["long_shot", "quickstep"],
		["rain_of_arrows", "smoke_screen", "shadow_step"])
	unit_registry["lyra"]["current_job_id"] = "scout"
	unit_registry["lyra"]["job_jp"]         = { "scout": 0 }
	_init_loadout_progress_defaults()


func _init_loadout_progress_defaults() -> void:
	for vow: Dictionary in VowSigilDefs.VOWS:
		var vow_id := str(vow.get("id", ""))
		if not vow_id.is_empty() and not vow_progress.has(vow_id):
			vow_progress[vow_id] = 0
	for sigil: Dictionary in VowSigilDefs.SIGILS:
		var sigil_id := str(sigil.get("id", ""))
		if not sigil_id.is_empty() and not sigil_progress.has(sigil_id):
			sigil_progress[sigil_id] = 0


func get_vow_xp(vow_id: String) -> int:
	return int(vow_progress.get(vow_id, 0))


func get_sigil_xp(sigil_id: String) -> int:
	return int(sigil_progress.get(sigil_id, 0))


func seed_run_loadout(run: RunState) -> void:
	if not run:
		return
	_init_loadout_progress_defaults()
	run.equipped_vow_xp = get_vow_xp(run.equipped_vow_id)
	run.equipped_vow_level = VowSigilDefs.level_for_xp(run.equipped_vow_xp)
	run.equipped_sigil_xp = get_sigil_xp(run.equipped_sigil_id)
	run.equipped_sigil_level = VowSigilDefs.level_for_xp(run.equipped_sigil_xp)


func apply_loadout_xp(amount: int, reason: String = "") -> Dictionary:
	if amount <= 0 or active_run == null:
		return {}
	_init_loadout_progress_defaults()
	var vow_id := active_run.equipped_vow_id
	var sigil_id := active_run.equipped_sigil_id
	var before_vow_level := VowSigilDefs.level_for_xp(get_vow_xp(vow_id))
	var before_sigil_level := VowSigilDefs.level_for_xp(get_sigil_xp(sigil_id))
	vow_progress[vow_id] = get_vow_xp(vow_id) + amount
	sigil_progress[sigil_id] = get_sigil_xp(sigil_id) + amount
	seed_run_loadout(active_run)
	var result := {
		"amount": amount,
		"reason": reason,
		"vow_id": vow_id,
		"vow_level_before": before_vow_level,
		"vow_level_after": active_run.equipped_vow_level,
		"vow_leveled": active_run.equipped_vow_level > before_vow_level,
		"sigil_id": sigil_id,
		"sigil_level_before": before_sigil_level,
		"sigil_level_after": active_run.equipped_sigil_level,
		"sigil_leveled": active_run.equipped_sigil_level > before_sigil_level,
	}
	pending_rewards["loadout_xp"] = int(pending_rewards.get("loadout_xp", 0)) + amount
	pending_rewards["loadout_xp_reason"] = reason
	pending_rewards["loadout_progress"] = result
	save()
	return result


func _reg(uid: String, dname: String,
		base: Array[String], learnable: Array[String]) -> void:
	unit_registry[uid] = {
		"display_name":        dname,
		"jp":                  0,
		"base_abilities":      base,
		"learned_abilities":   [],
		"learnable_abilities": learnable,
		"equipped_abilities":  base.slice(0, min(base.size(), 4)),
		"equipment": {
			"main_hand": "Training Blade",
			"off_hand": "Buckler",
			"head": "Cloth Cap",
			"body": "Traveling Garb",
			"accessory": "Copper Ring",
		},
	}


#  Ability queries

## Full ability list for a unit: base + every JP-purchased ability.
func get_all_abilities(unit_id: String) -> Array[String]:
	if not unit_registry.has(unit_id):
		return []
	var reg: Dictionary = unit_registry[unit_id]
	var equipped: Array = reg.get("equipped_abilities", [])
	if not equipped.is_empty():
		var chosen: Array[String] = []
		for ab: Variant in equipped:
			if knows_ability(unit_id, str(ab)) and str(ab) not in chosen:
				chosen.append(str(ab))
		if not chosen.is_empty():
			return chosen
	var result: Array[String] = []
	result.append_array(reg.get("base_abilities", []))
	for ab: String in reg.get("learned_abilities", []):
		if ab not in result:
			result.append(ab)
	return result


## Returns true if unit already knows the ability (base or learned).
func knows_ability(unit_id: String, ability_id: String) -> bool:
	if not unit_registry.has(unit_id):
		return false
	var reg: Dictionary = unit_registry[unit_id]
	return ability_id in reg.get("base_abilities", []) \
		or ability_id in reg.get("learned_abilities", [])


## Spends JP to learn an ability.  Returns true on success.
func learn_ability(unit_id: String, ability_id: String) -> bool:
	if not unit_registry.has(unit_id):
		return false
	var reg: Dictionary = unit_registry[unit_id]
	if knows_ability(unit_id, ability_id):
		return false
	var ab: Dictionary = AbilityDBScript.get_ability(ability_id)
	var cost: int = ab.get("jp_cost", 9999)
	if reg.get("jp", 0) < cost:
		return false
	reg["jp"] = reg.get("jp", 0) - cost
	reg["learned_abilities"].append(ability_id)
	return true


func get_jp(unit_id: String) -> int:
	if not unit_registry.has(unit_id):
		return 0
	return unit_registry[unit_id].get("jp", 0)


func set_current_job(unit_id: String, job_id: String) -> void:
	if not unit_registry.has(unit_id):
		return
	var reg: Dictionary = unit_registry[unit_id]
	reg["current_job_id"] = job_id
	if not reg.has("job_jp"):
		reg["job_jp"] = {}
	if not reg["job_jp"].has(job_id):
		reg["job_jp"][job_id] = 0
	var job := JobTreeData.get_job(job_id)
	if not job.is_empty():
		reg["learnable_abilities"] = job.get("abilities", [])
	save()


func set_equipped_abilities(unit_id: String, ability_ids: Array) -> void:
	if not unit_registry.has(unit_id):
		return
	var equipped: Array[String] = []
	for ab: Variant in ability_ids:
		var ab_id := str(ab)
		if knows_ability(unit_id, ab_id) and ab_id not in equipped:
			equipped.append(ab_id)
		if equipped.size() >= 4:
			break
	unit_registry[unit_id]["equipped_abilities"] = equipped
	save()


#  Battle results

## Called by BattleScene on victory.  Awards JP to surviving player units.
func apply_victory(map_id: String, rewards: Dictionary,
		player_unit_ids: Array[String]) -> void:
	var gld: int = rewards.get("gold", 0)
	var jp_gain: int = rewards.get("jp", 0)
	gold += gld
	run_jp_earned += jp_gain
	for uid in player_unit_ids:
		if unit_registry.has(uid):
			unit_registry[uid]["jp"] = unit_registry[uid].get("jp", 0) + jp_gain
	if map_id not in completed_stages:
		completed_stages.append(map_id)
	pending_rewards = {
		"gold":    gld,
		"jp":      jp_gain,
		"map_id":  map_id,
		"units":   player_unit_ids.duplicate(),
	}
	save()   # auto-save on every victory


#  Persistence

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Writes current state to disk.  Silent on failure.
func save() -> void:
	var unit_jp:        Dictionary = {}
	var unit_learned:   Dictionary = {}
	var unit_jobs:      Dictionary = {}
	var unit_job_jp:    Dictionary = {}
	var unit_equipped:  Dictionary = {}
	var unit_equipment: Dictionary = {}
	for uid in unit_registry:
		var reg: Dictionary = unit_registry[uid]
		unit_jp[uid]        = reg.get("jp", 0)
		unit_learned[uid]   = reg.get("learned_abilities", []).duplicate()
		unit_jobs[uid]      = reg.get("current_job_id", "")
		unit_job_jp[uid]    = reg.get("job_jp", {}).duplicate()
		unit_equipped[uid]  = reg.get("equipped_abilities", []).duplicate()
		unit_equipment[uid] = reg.get("equipment", {}).duplicate()

	var data: Dictionary = {
		"version":          SAVE_VERSION,
		"gold":             gold,
		"completed_stages": completed_stages.duplicate(),
		"story_flags":      story_flags.duplicate(),
		"unit_jp":          unit_jp,
		"unit_learned":     unit_learned,
		"unit_jobs":        unit_jobs,
		"unit_job_jp":      unit_job_jp,
		"unit_equipped":    unit_equipped,
		"unit_equipment":   unit_equipment,
		"vow_progress":     vow_progress.duplicate(),
		"sigil_progress":   sigil_progress.duplicate(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_warning("GameState.save: could not open %s for writing." % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## Loads save file.  Returns false if no file or format mismatch.
## On success populates gold, completed_stages, and per-unit JP/learned.
func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_warning("GameState.load_save: JSON parse failed or not a dict.")
		return false

	var data: Dictionary = parsed as Dictionary
	if data.get("version", 0) != SAVE_VERSION:
		push_warning("GameState.load_save: version mismatch  starting fresh.")
		return false

	# Populate registry with defaults first so learnable/base lists are intact
	_init_defaults()

	gold = int(data.get("gold", 0))

	completed_stages.clear()
	for s: Variant in data.get("completed_stages", []):
		completed_stages.append(str(s))

	story_flags.clear()
	for flag: Variant in data.get("story_flags", []):
		story_flags.append(str(flag))

	var saved_jp:        Dictionary = data.get("unit_jp", {})
	var saved_learned:   Dictionary = data.get("unit_learned", {})
	var saved_jobs:      Dictionary = data.get("unit_jobs", {})
	var saved_job_jp:    Dictionary = data.get("unit_job_jp", {})
	var saved_equipped:  Dictionary = data.get("unit_equipped", {})
	var saved_equipment: Dictionary = data.get("unit_equipment", {})
	var saved_vow_progress: Variant = data.get("vow_progress", {})
	var saved_sigil_progress: Variant = data.get("sigil_progress", {})
	vow_progress = {}
	if saved_vow_progress is Dictionary:
		vow_progress = (saved_vow_progress as Dictionary).duplicate()
	sigil_progress = {}
	if saved_sigil_progress is Dictionary:
		sigil_progress = (saved_sigil_progress as Dictionary).duplicate()
	_init_loadout_progress_defaults()

	for uid: String in unit_registry:
		if saved_jp.has(uid):
			unit_registry[uid]["jp"] = int(saved_jp[uid])
		if saved_learned.has(uid):
			var raw: Array = saved_learned[uid]
			var typed: Array[String] = []
			for ab: Variant in raw:
				typed.append(str(ab))
			unit_registry[uid]["learned_abilities"] = typed
		if saved_jobs.has(uid):
			unit_registry[uid]["current_job_id"] = str(saved_jobs[uid])
		if saved_job_jp.has(uid) and saved_job_jp[uid] is Dictionary:
			unit_registry[uid]["job_jp"] = (saved_job_jp[uid] as Dictionary).duplicate()
		if saved_equipped.has(uid) and saved_equipped[uid] is Array:
			var eq: Array[String] = []
			for ab: Variant in saved_equipped[uid]:
				eq.append(str(ab))
			unit_registry[uid]["equipped_abilities"] = eq
		if saved_equipment.has(uid) and saved_equipment[uid] is Dictionary:
			unit_registry[uid]["equipment"] = (saved_equipment[uid] as Dictionary).duplicate()

	return true


## Wipes the save file and resets in-memory state to defaults.
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			dir.remove("save.json")
	gold = 0
	completed_stages.clear()
	story_flags.clear()
	pending_rewards.clear()
	vow_progress.clear()
	sigil_progress.clear()
	unit_registry.clear()
	_init_defaults()
