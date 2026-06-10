class_name VowSigilSystem
extends RefCounted

const DEFAULT_VOW_ID := "vow_ignareth"
const DEFAULT_SIGIL_ID := "sigil_vanguard"
const MAX_LEVEL := 4

const VOWS: Array[Dictionary] = [
	{"id":"vow_ignareth", "name":"Vow of Ignareth", "short_name":"Ignareth", "guardian":"ignareth", "element":"fire", "theme":"Flame, pressure, decisive physical bursts.", "weights":{"guardian":{"ignareth":1.85}, "element":{"fire":1.65}, "tag":{"burn":1.35, "physical":1.18, "damage":1.12}}},
	{"id":"vow_nerevan", "name":"Vow of Nerevan", "short_name":"Nerevan", "guardian":"nerevan", "element":"water", "theme":"Tides, recovery, wet terrain, longer fights.", "weights":{"guardian":{"nerevan":1.85}, "element":{"water":1.65}, "tag":{"heal":1.35, "regen":1.30, "survive":1.12}}},
	{"id":"vow_torvahk", "name":"Vow of Torvahk", "short_name":"Torvahk", "guardian":"torvahk", "element":"thunder", "theme":"Storm rhythm, Surge timing, stun, speed.", "weights":{"guardian":{"torvahk":1.85}, "element":{"thunder":1.65}, "tag":{"surge":1.45, "stun":1.30, "speed":1.15}}},
	{"id":"vow_luminarch", "name":"Vow of Luminarch", "short_name":"Luminarch", "guardian":"luminarch", "element":"holy", "theme":"Light, protection, healing, last stands.", "weights":{"guardian":{"luminarch":1.85}, "element":{"holy":1.65}, "tag":{"heal":1.35, "guard":1.30, "survive":1.25}}},
	{"id":"vow_vaelthorn", "name":"Vow of Vaelthorn", "short_name":"Vaelthorn", "guardian":"vaelthorn", "element":"dark", "theme":"Shadow, curses, Ether drain, risky power.", "weights":{"guardian":{"vaelthorn":1.85}, "element":{"dark":1.65}, "tag":{"curse":1.40, "ether":1.30, "damage":1.15}}},
]

const SIGILS: Array[Dictionary] = [
	{"id":"sigil_vanguard", "name":"Vanguard Sigil", "short_name":"Vanguard", "theme":"Physical jobs, armor, counterplay, direct trades.", "weights":{"tag":{"physical":1.35, "guard":1.25, "temper":1.25, "counter":1.20}}},
	{"id":"sigil_arcanist", "name":"Arcanist Sigil", "short_name":"Arcanist", "theme":"Magical scaling, MP/Ether pressure, elemental chains.", "weights":{"tag":{"magic":1.35, "ether":1.30, "elemental":1.25, "damage":1.10}}},
	{"id":"sigil_duelist", "name":"Duelist Sigil", "short_name":"Duelist", "theme":"Flanks, mobility, burst windows, finishing blows.", "weights":{"tag":{"flank":1.35, "speed":1.25, "execute":1.25, "physical":1.12}}},
	{"id":"sigil_ranger", "name":"Ranger Sigil", "short_name":"Ranger", "theme":"Range, mark pressure, line attacks, safer spacing.", "weights":{"tag":{"range":1.35, "line":1.30, "accuracy":1.25, "speed":1.10}}},
	{"id":"sigil_cantor", "name":"Cantor Sigil", "short_name":"Cantor", "theme":"Support jobs, healing cadence, blessed protection.", "weights":{"tag":{"heal":1.35, "support":1.30, "guard":1.20, "survive":1.15}}},
	{"id":"sigil_marauder", "name":"Marauder Sigil", "short_name":"Marauder", "theme":"Momentum, knockback, cleaves, kill rewards.", "weights":{"tag":{"knockback":1.35, "cleave":1.30, "kill":1.25, "physical":1.15}}},
]

static func get_vow(vow_id: String) -> Dictionary:
	return _find_by_id(VOWS, vow_id, DEFAULT_VOW_ID)

static func get_sigil(sigil_id: String) -> Dictionary:
	return _find_by_id(SIGILS, sigil_id, DEFAULT_SIGIL_ID)

static func default_loadout() -> Dictionary:
	return loadout_bonus(DEFAULT_VOW_ID, 1, DEFAULT_SIGIL_ID, 1)

static func loadout_bonus(vow_id: String, vow_level: int, sigil_id: String, sigil_level: int) -> Dictionary:
	var vow := get_vow(vow_id)
	var sigil := get_sigil(sigil_id)
	var v_level := clampi(vow_level, 1, MAX_LEVEL)
	var s_level := clampi(sigil_level, 1, MAX_LEVEL)
	return {
		"vow_id": vow.get("id", DEFAULT_VOW_ID),
		"vow_name": vow.get("name", "Vow"),
		"vow_level": v_level,
		"sigil_id": sigil.get("id", DEFAULT_SIGIL_ID),
		"sigil_name": sigil.get("name", "Sigil"),
		"sigil_level": s_level,
		"guardian_weights": _scaled_weights(vow.get("weights", {}).get("guardian", {}), v_level),
		"element_weights": _scaled_weights(vow.get("weights", {}).get("element", {}), v_level),
		"tag_weights": _merge_weights(
			_scaled_weights(vow.get("weights", {}).get("tag", {}), v_level),
			_scaled_weights(sigil.get("weights", {}).get("tag", {}), s_level)
		),
		"rarity_weights": _rarity_weights(v_level, s_level),
	}

static func xp_for_floor_clear(floor_num: int, node_type: String = "battle") -> int:
	var base := 8 + maxi(1, floor_num) * 2
	match node_type:
		"elite": return base + 10
		"boss": return base + 18
		"boon_pick", "mystery_shrine": return base + 4
		"town_1", "town_2", "town_3": return base + 2
		_: return base

static func xp_for_run_end(floor_reached: int, victory: bool, heat_level: int = 0) -> int:
	var amount := maxi(1, floor_reached) * 3 + maxi(0, heat_level) * 2
	if victory:
		amount += 30
	return amount

static func level_for_xp(xp: int) -> int:
	if xp >= 160:
		return 4
	if xp >= 80:
		return 3
	if xp >= 30:
		return 2
	return 1

static func xp_for_next_level(level: int) -> int:
	match level:
		1: return 30
		2: return 80
		3: return 160
		_: return -1

static func xp_progress_text(xp: int) -> String:
	var level := level_for_xp(xp)
	var next := xp_for_next_level(level)
	if next < 0:
		return "Max level"
	return "%d / %d XP" % [xp, next]

static func level_bonus_text(level: int, is_vow: bool) -> String:
	var prefix := "Guardian" if is_vow else "Sigil"
	match clampi(level, 1, MAX_LEVEL):
		1: return "%s attunement active" % prefix
		2: return "+stronger offer weighting"
		3: return "+rare/legendary offer bias"
		_: return "Max attunement"

static func next_unlock_text(level: int, _is_vow: bool) -> String:
	match clampi(level, 1, MAX_LEVEL):
		1: return "Next: stronger weighting"
		2: return "Next: rare/legendary bias"
		3: return "Next: max attunement"
		_: return "All unlocks active"

static func _find_by_id(items: Array[Dictionary], item_id: String, fallback_id: String) -> Dictionary:
	var fallback: Dictionary = {}
	for item in items:
		if item.get("id", "") == fallback_id:
			fallback = item
		if item.get("id", "") == item_id:
			return item
	return fallback

static func _scaled_weights(weights: Dictionary, level: int) -> Dictionary:
	var result: Dictionary = {}
	var bonus_scale := 1.0 + float(clampi(level, 1, MAX_LEVEL) - 1) * 0.25
	for key in weights.keys():
		var base := float(weights[key])
		result[key] = 1.0 + (base - 1.0) * bonus_scale
	return result

static func _rarity_weights(vow_level: int, sigil_level: int) -> Dictionary:
	var attunement := maxi(vow_level, sigil_level)
	if attunement < 3:
		return {}
	var bonus := 1.0 + float(attunement - 2) * 0.10
	return {
		"rare": bonus,
		"legendary": bonus,
		"unique": 1.0 + float(attunement - 2) * 0.06,
	}

static func _merge_weights(a: Dictionary, b: Dictionary) -> Dictionary:
	var result := a.duplicate()
	for key in b.keys():
		result[key] = maxf(float(result.get(key, 1.0)), float(b[key]))
	return result
