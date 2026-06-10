## ForecastCalculator.gd
## Pure RefCounted. Computes action forecasts with the same CombatFormula used by resolution.

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
	"fire":"F", "blizzard":"I", "thunder":"T", "holy":"H", "dark":"D",
	"water":"W", "wind":"A", "resonance":"R", "physical":"P", "heal":"+", "buff":"B",
}

const AOE_SHAPE_LABELS: Dictionary = {
	"fan": "FAN", "cross": "CROSS", "line": "LINE", "chain": "CHAIN", "radius": "BURST", "nova": "NOVA",
}

const AOE_SHAPE_ICONS: Dictionary = {
	"fan":"V", "cross":"+", "line":"-", "chain":"~", "radius":"O", "nova":"*",
}


static func attack(attacker: Unit, target: Unit,
		tile_att: Dictionary, tile_tar: Dictionary) -> Dictionary:
	var formula := CombatFormula.calculate_physical_attack(attacker, target, tile_att, tile_tar)
	var dmg: int = int(formula.get("hp_damage", formula.get("incoming_damage", 0)))
	var flank_m: float = float(formula.get("flank_mult", 1.0))
	var bonuses: Dictionary = RunBonuses.for_current_run()
	var jp: int = int(6 * bonuses.get("jp_multiplier", 1.0))

	return {
		"visible":       true,
		"mode":          "Attack",
		"element":       "physical",
		"element_icon":  ELEMENT_ICONS["physical"],
		"element_color": ELEMENT_COLORS["physical"],
		"damage":        dmg,
		"damage_min":    int(dmg * 0.85),
		"damage_max":    int(dmg * float(formula.get("crit_mult", 1.5))) if int(formula.get("crit_pct", 0)) > 0 else int(dmg * 1.10),
		"height_mult":   float(formula.get("height_mult", 1.0)),
		"height_delta":  int(formula.get("height_delta", 0)),
		"flank_mult":    flank_m,
		"incoming_damage": int(formula.get("incoming_damage", dmg)),
		"temper_damage": int(formula.get("temper_damage", 0)),
		"physical_resistance": int(formula.get("physical_resistance", 0)),
		"formula_explain": formula.get("explain", []),
		"modifier_breakdown": _compact_breakdown(formula),
		"hp_before":     target.hp,
		"hp_after":      max(target.hp - dmg, 0),
		"max_hp":        _max_hp(target),
		"affinity":      1.0,
		"affinity_label":"",
		"affinity_color": Color.WHITE,
		"boon_mult":     1.0,
		"hit_pct":       int(formula.get("hit_pct", 95)),
		"crit_pct":      int(formula.get("crit_pct", 0)),
		"crit_damage":   int(formula.get("crit_damage", dmg)),
		"status_preview":"",
		"jp_gain":       jp,
		"flank_label":   "Back attack" if flank_m >= 1.25 else ("Side hit" if flank_m > 1.0 else ""),
		"can_counter":   _can_counter(attacker, target),
		"is_heal":       false,
		"actor_name":    attacker.display_name,
		"target_name":   target.display_name,
		"ability_name":  "Attack",
	}


static func spell(caster: Unit, target: Unit, ability: Dictionary,
		tile_caster: Dictionary = {}, tile_target: Dictionary = {}) -> Dictionary:
	var spell_type: String = CombatFormula.normalize_element(str(ability.get("spell_type", "fire")))
	var base_power: int = int(ability.get("base_power", 50))
	var mp_cost: int = int(ability.get("mp_cost", 0))
	var is_heal: bool = spell_type in ["heal", "cure"] or ability.get("type", "") == "heal"
	var is_buff: bool = spell_type == "buff" or ability.get("type", "") == "buff"
	var bonuses := RunBonuses.for_current_run()
	var el_mult: float = float(bonuses["elemental_mult"].get(spell_type, 1.0))
	el_mult *= CombatFormula.item_elemental_multiplier(caster, spell_type)
	var boon_bonus: float = el_mult - 1.0

	var dmg := 0
	var heal := 0
	var formula: Dictionary = {}
	if is_heal:
		formula = CombatFormula.calculate_heal(caster, base_power, int(bonuses.get("heal_bonus", 0)))
		heal = int(formula.get("heal", 0))
	elif is_buff:
		dmg = 0
	elif spell_type == "physical":
		formula = CombatFormula.calculate_physical_attack(caster, target, tile_caster, tile_target)
		dmg = int(formula.get("hp_damage", formula.get("incoming_damage", 0)))
	else:
		formula = CombatFormula.calculate_magical_attack(caster, target, spell_type, base_power, {"power_mult": el_mult})
		dmg = int(formula.get("hp_damage", formula.get("incoming_damage", 0)))
		if bonuses.get("brand_bonus", 0.0) > 0.0 and target.has_status("burn"):
			dmg = int(round(float(dmg) * (1.0 + float(bonuses["brand_bonus"]))))

	var affinity: float = float(formula.get("affinity", 1.0))
	var aff_label := _affinity_label(affinity)
	var aff_color := _affinity_color(affinity)
	var status_text := _status_preview(ability)
	var jp: int = int(6 * bonuses.get("jp_multiplier", 1.0))
	if affinity > 1.0:
		jp += int(4 * bonuses.get("jp_multiplier", 1.0))
	var aoe_r: int = int(ability.get("aoe_radius", 0))

	return {
		"visible":        true,
		"mode":           "Spell",
		"element":        spell_type,
		"element_icon":   ELEMENT_ICONS.get(spell_type, "*"),
		"element_color":  ELEMENT_COLORS.get(spell_type, Color.WHITE),
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
		"hit_pct":        int(formula.get("hit_pct", 100)),
		"crit_pct":       int(formula.get("crit_pct", 0)),
		"formula_explain": formula.get("explain", []),
		"modifier_breakdown": _compact_breakdown(formula, _run_damage_notes(spell_type, bonuses)),
		"status_preview": status_text,
		"aoe_note":       ("%d-tile radius" % aoe_r) if aoe_r > 0 else "",
		"jp_gain":        jp,
		"mp_cost":        mp_cost,
		"ability_name":   ability.get("display_name", "?"),
		"actor_name":     caster.display_name,
		"target_name":    target.display_name,
		"flank_label":    "",
		"can_counter":    false,
	}


static func quick_spell(caster: Unit, ability: Dictionary) -> Dictionary:
	var spell_type: String = CombatFormula.normalize_element(str(ability.get("spell_type", "fire")))
	var bonuses := RunBonuses.for_current_run()
	var el_mult: float = float(bonuses["elemental_mult"].get(spell_type, 1.0))
	el_mult *= CombatFormula.item_elemental_multiplier(caster, spell_type)
	var base: float = float(caster.unit_data.base_stats.magic) * (float(ability.get("base_power", 50)) / 100.0)
	var boosted: int = int(round(base * el_mult))
	return {
		"element": spell_type,
		"element_icon": ELEMENT_ICONS.get(spell_type, "*"),
		"element_color": ELEMENT_COLORS.get(spell_type, Color.WHITE),
		"base_damage": int(round(base)),
		"boosted_damage": boosted,
		"boon_pct": int((el_mult - 1.0) * 100),
		"mp_cost": ability.get("mp_cost", 0),
		"range": ability.get("range", 0),
	}


static func _compact_breakdown(formula: Dictionary, extra_notes: Array[String] = []) -> Array[String]:
	var parts: Array[String] = []
	for item in formula.get("explain", []):
		var text: String = str(item)
		if not text.is_empty() and text not in parts:
			parts.append(text)
	for note in extra_notes:
		if not note.is_empty() and note not in parts:
			parts.append(note)
	return parts


static func _run_damage_notes(element: String, bonuses: Dictionary) -> Array[String]:
	var notes: Array[String] = []
	if bonuses.has("elemental_mult") and bonuses["elemental_mult"] is Dictionary:
		var element_mult: float = float(bonuses["elemental_mult"].get(element, 1.0))
		if element != "physical" and element_mult != 1.0:
			notes.append("Boon %s %s" % [element.capitalize(), _signed_percent(element_mult - 1.0)])
	if int(bonuses.get("heal_bonus", 0)) != 0 and element == "heal":
		notes.append("Boon Heal %+d" % int(bonuses.get("heal_bonus", 0)))
	return notes


static func _signed_percent(delta: float) -> String:
	return "%+d%%" % int(round(delta * 100.0))


static func _status_preview(ability: Dictionary) -> String:
	var se: Dictionary = ability.get("status_effect", {})
	if se.is_empty():
		return ""
	var sid: String = str(se.get("id", ""))
	var dur: int = int(se.get("duration", 1))
	if sid.is_empty() or dur >= 90:
		return ""
	return "Applies: %s (%dt)" % [sid.replace("_", " ").capitalize(), dur]


static func _affinity_label(affinity: float) -> String:
	if affinity == 0.0: return "IMMUNE"
	if affinity <= 0.3: return "ABSORBS"
	if affinity < 1.0: return "RESISTS"
	if affinity >= 2.0: return "WEAK x%.1f!" % affinity
	if affinity > 1.0: return "WEAK x%.1f" % affinity
	return ""


static func _affinity_color(affinity: float) -> Color:
	if affinity == 0.0: return Color(0.5, 0.5, 0.55)
	if affinity <= 0.3: return Color(0.4, 0.9, 0.4)
	if affinity < 1.0: return Color(0.4, 0.75, 1.0)
	if affinity > 1.0: return Color(1.0, 0.65, 0.2)
	return Color.WHITE


static func _max_hp(unit: Unit) -> int:
	return unit.unit_data.base_stats.hp if unit.unit_data else 100


static func _can_counter(attacker: Unit, target: Unit) -> bool:
	if target.team != "enemy": return false
	var dist: int = abs(attacker.grid_pos.x - target.grid_pos.x) + abs(attacker.grid_pos.y - target.grid_pos.y)
	return dist <= (target.unit_data.base_stats.attack_range_max if target.unit_data else 1)
