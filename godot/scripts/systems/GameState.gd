## GameState.gd  —  Autoload singleton.
## Persists player progress (JP, gold, learned abilities, completed stages)
## across scene transitions.  Never freed between battles.
extends Node

const AbilityDBScript := preload("res://scripts/data/AbilityDB.gd")

## Which map to load when transitioning into Battle.tscn  (0 = Ashvale, 1 = Crypt)
var selected_map_index: int = 0

## Gold accumulated across all battles
var gold: int = 0

## Stages the player has beaten at least once
var completed_stages: Array[String] = []

## Rewards from the most recent victory — read by ResultsScreen
var pending_rewards: Dictionary = {}

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
	if unit_registry.is_empty():
		_init_defaults()


func _init_defaults() -> void:
	_reg("zane", "Zane",
		["mighty_strike", "wind_slash"],
		["dark_blade", "aero", "tremor"])
	_reg("mira", "Mira Vey",
		["fire", "thunder", "blizzard", "cure", "holy"],
		["fira", "blizzara", "cura"])
	_reg("kael", "Kael",
		["mighty_strike"],
		["wind_slash", "tremor", "dark_blade"])


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
