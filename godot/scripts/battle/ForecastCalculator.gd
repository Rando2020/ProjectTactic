## ForecastCalculator.gd
## Pure RefCounted. Computes the full FF Tactics-style action forecast.
## No side effects — call before the action, display the result.

class_name ForecastCalculator
extends RefCounted

const ELEMENT_COLORS: Dictionary = {
	"fire":      Color(1.00, 0.42, 0.10),
	"blizzard":  Color(0.42, 0.82, 1.00),
	"thunder":   Color(1.00, 0.95, 0.20),
	"holy":      Color(1.00, 0.98, 0.65),
	"dark":      Color(0.72, 0.30, 1.00),
	"water":     Color(0.22, 0.72, 1.00),
	"wind":      Color(0.70, 0.95, 0.55),
	"resonance": Color(0.52, 0.92, 1.00),
	"physical":  Color(0.90, 0.82, 0.70),
	"heal":      Color(0.45, 0.95, 0.55),
	"buff":      Color(0.55, 0.75, 1.00),
}

const ELEMENT_ICONS: Dictionary = {
	"fire":"🔥", "blizzard":"❄", "thunder":"⚡", "holy":"✨",
	"dark":"💀", "water":"🌊", "wind":"💨", "resonance":"💠",
	"physical":"⚔", "heal":"💚", "buff":"🛡",
}


## Full attack forecast (physical).
static func attack(attacker: Unit, target: Unit,
		tile_att: Dictionary, tile_tar: Dictionary) -> Dictionary:
	var raw: float = attacker.unit_data.base_stats.physical * 1.2
	if attacker.has_meta("dmg_mult"):
		raw *= attacker.get_meta("dmg_mult", 1.0)

	var h_att: int = tile_att.get("height", 0)
	var h_tar: int = tile_tar.get("height", 0)
	var height_m: float = 1.15 if h_att > h_tar else (0.9 if h_att < h_tar else 1.0)
	var flank_m:  float = _flank(attacker, target)
	var dmg:      int   = int(raw * height_m * flank_m)

	var bonuses: Dictionary = RunBonuses.for_current_run()
	var jp: int = int(6 * bonuses.get("jp_multiplier", 1.0))

	return {
		"visible":       true,
		"mode":          "Attack",
		"element":       "physical",
		"element_icon":  "⚔",
		"element_color": ELEMENT_COLORS["physical"],
		"damage":        dmg,
		"damage_min":    int(dmg * 0.85),
		"damage_max":    int(dmg * 1.30) if flank_m >= 1.25 else int(dmg * 1.10),
		"hp_before":     target.hp,
		"hp_after":      max(target.hp - dmg, 0),
		"max_hp":        _max_hp(target),
		"affinity":      1.0,
		"affinity_label":"",
		"affinity_color": Color.WHITE,
		"boon_mult":     1.0,
		"hit_pct":       95 if flank_m >= 1.0 else 85,
		"status_preview":"",
		"jp_gain":       jp,
		"flank_label":   "Back attack!" if flank_m >= 1.25 else ("Side hit" if flank_m > 1.0 else ""),
		"can_counter":   _can_counter(attacker, target),
		"is_heal":       false,
		"actor_name":    attacker.display_name,
		"target_name":   target.display_name,
		"ability_name":  "Attack",
	}


## Full spell forecast.
static func spell(caster: Unit, target: Unit, ability: Dictionary) -> Dictionary:
	var spell_type: String = ability.get("spell_type", "fire")
	var base_power: int    = ability.get("base_power", 50)
	var mp_cost: int       = ability.get("mp_cost", 0)
	var is_heal: bool      = spell_type in ["heal", "cure"] or ability.get("type","") == "heal"
	var is_buff: bool      = spell_type == "buff" or ability.get("type","") == "buff"

	# Elemental visuals
	var el_color: Color = ELEMENT_COLORS.get(spell_type, Color.WHITE)
	var el_icon:  String = ELEMENT_ICONS.get(spell_type, "✦")

	# Boon elemental bonus
	var bonuses  := RunBonuses.for_current_run()
	var el_mult: float = bonuses["elemental_mult"].get(spell_type, 1.0)
	var boon_bonus: float = el_mult - 1.0

	# Affinity
	var affinity: float = 1.0
	if target.unit_data and not target.unit_data.elemental_affinities.is_empty():
		affinity = target.unit_data.elemental_affinities.get(spell_type, 1.0)
	if target.has_meta("immune") and spell_type in target.get_meta("immune",[]):
		affinity = 0.0

	var aff_label: String
	var aff_color: Color
	if affinity == 0.0:          aff_label = "IMMUNE";  aff_color = Color(0.5,0.5,0.55)
	elif affinity <= 0.3:        aff_label = "ABSORBS"; aff_color = Color(0.4,0.9,0.4)
	elif affinity < 1.0:         aff_label = "RESISTS"; aff_color = Color(0.4,0.75,1.0)
	elif affinity >= 2.0:        aff_label = "WEAK ×%.1f!" % affinity; aff_color = Color(1.0,0.38,0.12)
	elif affinity > 1.0:         aff_label = "WEAK ×%.1f" % affinity;  aff_color = Color(1.0,0.65,0.2)
	else:                        aff_label = ""; aff_color = Color.WHITE

	# Damage
	var dmg: int = 0
	var heal: int = 0
	if is_heal:
		heal = int(float(caster.unit_data.base_stats.magic) * (float(base_power)/100.0))
		heal += bonuses.get("heal_bonus", 0)
	elif is_buff:
		dmg = 0
	else:
		var raw: float = float(caster.unit_data.base_stats.magic) * (float(base_power)/100.0)
		raw *= el_mult
		dmg = int(raw * affinity)
		# Brand boon: burning targets take bonus physical damage
		if bonuses.get("brand_bonus",0.0) > 0.0 and target.has_status("burn"):
			dmg = int(float(dmg) * (1.0 + bonuses["brand_bonus"]))

	# Status effect preview
	var se: Dictionary = ability.get("status_effect", {})
	var status_text: String = ""
	if not se.is_empty():
		var sid: String = se.get("id", "")
		var dur: int    = se.get("duration", 1)
		if not sid.is_empty() and dur < 90:
			status_text = "Applies: %s (%dt)" % [sid.replace("_"," ").capitalize(), dur]

	# JP
	var jp: int = int(6 * bonuses.get("jp_multiplier", 1.0))
	if affinity > 1.0: jp += int(4 * bonuses.get("jp_multiplier", 1.0))

	# AoE note
	var aoe_r: int = ability.get("aoe_radius", 0)
	var aoe_note: String = ("%d-tile radius" % aoe_r) if aoe_r > 0 else ""

	return {
		"visible":        true,
		"mode":           "Spell",
		"element":        spell_type,
		"element_icon":   el_icon,
		"element_color":  el_color,
		"damage":         dmg,
		"damage_min":     int(dmg * 0.9),
		"damage_max":     int(dmg * 1.1),
		"hp_before":      target.hp,
		"hp_after":       max(target.hp - dmg, 0) if not is_heal else min(target.hp + heal, _max_hp(target)),
		"max_hp":         _max_hp(target),
		"heal":           heal,
		"is_heal":        is_heal,
		"is_buff":        is_buff,
		"affinity":       affinity,
		"affinity_label": aff_label,
		"affinity_color": aff_color,
		"boon_mult":      el_mult,
		"boon_bonus_pct": int(boon_bonus * 100),
		"hit_pct":        100,
		"status_preview": status_text,
		"aoe_note":       aoe_note,
		"jp_gain":        jp,
		"mp_cost":        mp_cost,
		"ability_name":   ability.get("display_name", "?"),
		"actor_name":     caster.display_name,
		"target_name":    target.display_name,
		"flank_label":    "",
		"can_counter":    false,
	}


## Compact forecast used in the ability list (hover tooltip).
static func quick_spell(caster: Unit, ability: Dictionary) -> Dictionary:
	var spell_type: String = ability.get("spell_type", "fire")
	var el_color: Color = ELEMENT_COLORS.get(spell_type, Color.WHITE)
	var el_icon: String = ELEMENT_ICONS.get(spell_type, "✦")
	var bonuses   := RunBonuses.for_current_run()
	var el_mult: float = float(bonuses["elemental_mult"].get(spell_type, 1.0))
	var base: float = float(caster.unit_data.base_stats.magic) * (float(ability.get("base_power",50))/100.0)
	var boosted: int = int(base * el_mult)
	return {
		"element": spell_type, "element_icon": el_icon, "element_color": el_color,
		"base_damage": int(base), "boosted_damage": boosted,
		"boon_pct": int((el_mult-1.0)*100),
		"mp_cost": ability.get("mp_cost",0),
		"range": ability.get("range",0),
	}


# ── Helpers ───────────────────────────────────────────────────────────────────

static func _flank(attacker: Unit, target: Unit) -> float:
	var delta: Vector2i = attacker.grid_pos - target.grid_pos
	var from: String
	if abs(delta.x) >= abs(delta.y): from = "E" if delta.x > 0 else "W"
	else:                            from = "S" if delta.y > 0 else "N"
	var opp: Dictionary = {"N":"S","S":"N","E":"W","W":"E"}
	if from == target.facing:                  return 1.0
	if from == opp.get(target.facing,""):      return 1.30
	return 1.15

static func _max_hp(unit: Unit) -> int:
	return unit.unit_data.base_stats.hp if unit.unit_data else 100

static func _can_counter(attacker: Unit, target: Unit) -> bool:
	if target.team != "enemy": return false
	var dist: int = abs(attacker.grid_pos.x - target.grid_pos.x) + abs(attacker.grid_pos.y - target.grid_pos.y)
	return dist <= (target.unit_data.base_stats.attack_range_max if target.unit_data else 1)
