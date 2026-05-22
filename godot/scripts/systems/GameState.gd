## GameState.gd  —  Autoload singleton.
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
const SAVE_PATH    := "user://save.json"
const SAVE_VERSION := 1

## Which map to load when transitioning into Battle.tscn  (0 = Ashvale, 1 = Crypt)
var selected_map_index: int = 0

## Gold accumulated across all battles
var gold: int = 0

## Stages the player has beaten at least once
var completed_stages: Array[String] = []

## Rewards from the most recent victory — read by ResultsScreen
var pending_rewards: Dictionary = {}

## Roguelike run state
var active_run:           RunState = null
var story_flags:          Array[String] = []
var pending_loot:         Array = []
var pending_boon_offers:  Array = []

## Last run death context — read by ResultsScreen + HubDialogue
var last_run_death: Dictionary = {}
## Run history — floors completed, used by hub dialogue
var runs_completed: int = 0
var best_floor_reached: int = 0

## Items accumulated during the current run
var run_inventory:        Array = []
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
	# Zane — Arcanist path → Resonant
	_reg("zane", "Zane",
		["fireball", "thunderstrike", "void_pulse"],
		["blizzard", "dark_breath", "elemental_convergence"])
	unit_registry["zane"]["current_job_id"] = "arcanist"
	unit_registry["zane"]["job_jp"]         = { "arcanist": 0 }

	# Mira — Arcanist → Luminary path
	_reg("mira", "Mira Vey",
		["fireball", "cure", "holy_strike"],
		["blizzard", "luminous_barrier", "mass_cure"])
	unit_registry["mira"]["current_job_id"] = "arcanist"
	unit_registry["mira"]["job_jp"]         = { "arcanist": 0 }

	# Kael — Squire → Warder → Void Knight path
	_reg("kael", "Kael",
		["slash", "mighty_strike", "defend"],
		["cover_ally", "iron_wall", "retribution"])
	unit_registry["kael"]["current_job_id"] = "squire"
	unit_registry["kael"]["job_jp"]         = { "squire": 0 }

	# Lyra — Scout → Shadow path
	_reg("lyra", "Lyra",
		["long_shot", "quickstep"],
		["rain_of_arrows", "smoke_screen", "shadow_step"])
	unit_registry["lyra"]["current_job_id"] = "scout"
	unit_registry["lyra"]["job_jp"]         = { "scout": 0 }


func _reg(uid: String, dname: String,
		base: Array[String], learnable: Array[String]) -> void:
	unit_registry[uid] = {
		"display_name":        dname,
		"jp":                  0,
		"base_abilities":      base,
		"learned_abilities":   [],
		"learnable_abilities": learnable,
	}


# ── Ability queries ───────────────────────────────────────────────────────────

## Full ability list for a unit: base + every JP-purchased ability.
func get_all_abilities(unit_id: String) -> Array[String]:
	if not unit_registry.has(unit_id):
		return []
	var reg: Dictionary = unit_registry[unit_id]
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


# ── Battle results ────────────────────────────────────────────────────────────

## Called by BattleScene on victory.  Awards JP to surviving player units.
func apply_victory(map_id: String, rewards: Dictionary,
		player_unit_ids: Array[String]) -> void:
	var gld: int = rewards.get("gold", 0)
	var jp_gain: int = rewards.get("jp", 0)
	gold += gld
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


# ── Persistence ───────────────────────────────────────────────────────────────

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Writes current state to disk.  Silent on failure.
func save() -> void:
	var unit_jp:      Dictionary = {}
	var unit_learned: Dictionary = {}
	for uid in unit_registry:
		var reg: Dictionary = unit_registry[uid]
		unit_jp[uid]      = reg.get("jp", 0)
		unit_learned[uid] = reg.get("learned_abilities", []).duplicate()

	var data: Dictionary = {
		"version":          SAVE_VERSION,
		"gold":             gold,
		"completed_stages": completed_stages.duplicate(),
		"story_flags":      story_flags.duplicate(),
		"unit_jp":          unit_jp,
		"unit_learned":     unit_learned,
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
		push_warning("GameState.load_save: version mismatch — starting fresh.")
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

	var saved_jp:      Dictionary = data.get("unit_jp", {})
	var saved_learned: Dictionary = data.get("unit_learned", {})

	for uid: String in unit_registry:
		if saved_jp.has(uid):
			unit_registry[uid]["jp"] = int(saved_jp[uid])
		if saved_learned.has(uid):
			var raw: Array = saved_learned[uid]
			var typed: Array[String] = []
			for ab: Variant in raw:
				typed.append(str(ab))
			unit_registry[uid]["learned_abilities"] = typed

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
	unit_registry.clear()
	_init_defaults()
