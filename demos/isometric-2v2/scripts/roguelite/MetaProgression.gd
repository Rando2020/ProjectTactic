extends Node

const SAVE_PATH := "user://meta-progression.json"
const SAVE_VERSION := 1

var currencies: Dictionary = {}
var permanent_upgrades: Dictionary = {}
var unlocked_flags: Array[String] = []
var selected_heat_level: int = 0
var max_heat_unlocked: int = 0

func _ready() -> void:
	if not load_save():
		_init_defaults()

func _init_defaults() -> void:
	for currency_id in [Currency.SOUL_SHARDS, Currency.OBSIDIAN, Currency.GLYPHS, Currency.BOSS_TOKENS, "phoenix-sigils", "titan-sigils"]:
		if not currencies.has(currency_id):
			currencies[currency_id] = 0
	for upgrade_id in ["max_hp", "physical", "magic"]:
		if not permanent_upgrades.has(upgrade_id):
			permanent_upgrades[upgrade_id] = 0

func get_currency(currency_id: String) -> int:
	return int(currencies.get(currency_id, 0))

func add_currency(currency_id: String, amount: int) -> void:
	currencies[currency_id] = max(0, get_currency(currency_id) + amount)

func can_spend(cost: Dictionary) -> bool:
	for currency_id: String in cost.keys():
		if get_currency(currency_id) < int(cost[currency_id]):
			return false
	return true

func spend(cost: Dictionary) -> bool:
	if not can_spend(cost):
		return false
	for currency_id: String in cost.keys():
		add_currency(currency_id, -int(cost[currency_id]))
	save()
	return true

func add_upgrade(upgrade_id: String, amount: int = 1) -> void:
	permanent_upgrades[upgrade_id] = int(permanent_upgrades.get(upgrade_id, 0)) + amount

func get_upgrade(upgrade_id: String) -> int:
	return int(permanent_upgrades.get(upgrade_id, 0))

func get_stat_bonus(stat_id: String) -> int:
	match stat_id:
		"max_hp": return get_upgrade("max_hp") * 15
		"physical": return get_upgrade("physical") * 2
		"magic": return get_upgrade("magic") * 2
		_: return 0

func add_unlock(flag_id: String) -> void:
	if flag_id not in unlocked_flags:
		unlocked_flags.append(flag_id)

func has_unlock(flag_id: String) -> bool:
	return flag_id in unlocked_flags

func award_stage_rewards(map_id: String) -> Dictionary:
	var is_boss: bool = map_id == "crypt_of_echoes_01"
	var heat_bonus: int = maxi(selected_heat_level, 0)
	var rewards: Dictionary = {
		Currency.SOUL_SHARDS: 6 + heat_bonus,
		Currency.GLYPHS: 1,
	}
	if is_boss:
		rewards[Currency.OBSIDIAN] = 5 + heat_bonus
		rewards[Currency.BOSS_TOKENS] = 1 + floori(float(heat_bonus) / 3.0)
		rewards["titan-sigils"] = 2 + floori(float(heat_bonus) / 2.0)
	else:
		rewards[Currency.OBSIDIAN] = 1 + floori(float(heat_bonus) / 2.0)
		rewards["phoenix-sigils"] = 2 + floori(float(heat_bonus) / 2.0)
	for currency_id: String in rewards.keys():
		add_currency(currency_id, int(rewards[currency_id]))
	save()
	return rewards

func save() -> void:
	var data := {
		"version": SAVE_VERSION,
		"currencies": currencies,
		"permanent_upgrades": permanent_upgrades,
		"unlocked_flags": unlocked_flags,
		"selected_heat_level": selected_heat_level,
		"max_heat_unlocked": max_heat_unlocked,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_warning("MetaProgression.save: could not open save path")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return false
	var data: Dictionary = parsed
	currencies = data.get("currencies", {}).duplicate()
	permanent_upgrades = data.get("permanent_upgrades", {}).duplicate()
	unlocked_flags.clear()
	for flag: Variant in data.get("unlocked_flags", []):
		unlocked_flags.append(str(flag))
	selected_heat_level = int(data.get("selected_heat_level", 0))
	max_heat_unlocked = int(data.get("max_heat_unlocked", 0))
	_init_defaults()
	return true
