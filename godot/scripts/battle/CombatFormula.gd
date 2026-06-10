## CombatFormula.gd
## Official side-effect-free combat math contract.
## Forecasts and real resolution should call this instead of duplicating formulas.

class_name CombatFormula
extends RefCounted

const FACING_OPPOSITE: Dictionary = {"N":"S", "S":"N", "E":"W", "W":"E"}

const DAMAGE_KIND_PHYSICAL := "physical"
const DAMAGE_KIND_MAGICAL := "magical"
const DAMAGE_KIND_TRUE := "true"

const PHYSICAL_ATTACK_SCALE := 1.10
const SPELL_POWER_SCALE := 0.95

const HIGH_GROUND_STEP_BONUS := 0.10
const LOW_GROUND_STEP_PENALTY := 0.08
const MAX_HEIGHT_BONUS := 0.30
const MAX_HEIGHT_PENALTY := 0.24

const FRONT_MULT := 1.00
const SIDE_MULT := 1.10
const BACK_MULT := 1.25

const BASE_ATTACK_HIT := 88
const BASE_SPELL_HIT := 100
const SIDE_HIT_BONUS := 5
const BACK_HIT_BONUS := 12
const LOW_GROUND_HIT_PENALTY := 5
const HIGH_GROUND_HIT_BONUS := 3
const BLIND_HIT_PENALTY := 35
const HIT_FLOOR := 20
const HIT_CEILING := 100

const BASE_CRIT_CHANCE := 5
const BACK_CRIT_BONUS := 10
const SIDE_CRIT_BONUS := 4
const HIGH_GROUND_CRIT_BONUS := 3
const CRIT_DAMAGE_MULT := 1.50

const PHYSICAL_TEMPER_ABSORB_RATIO := 0.35
const MAGICAL_ETHER_ABSORB_RATIO := 0.35
const ARMOR_TO_HP_REDUCTION_RATIO := 0.45
const PROTECT_DAMAGE_MULT := 0.70

const ELEMENT_LABELS: Dictionary = {
	"physical":"Physical", "fire":"Fire", "water":"Water", "blizzard":"Ice", "ice":"Ice",
	"thunder":"Thunder", "wind":"Wind", "holy":"Holy", "dark":"Dark", "resonance":"Resonance",
}


static func item_elemental_multiplier(unit: Unit, element: String) -> float:
	if not unit or not unit.has_meta("item_elemental_mult"):
		return 1.0
	var multipliers: Dictionary = unit.get_meta("item_elemental_mult", {})
	return float(multipliers.get(normalize_element(element), 1.0))


static func calculate_physical_attack(attacker: Unit, target: Unit,
		tile_attacker: Dictionary, tile_target: Dictionary,
		mods: Dictionary = {}) -> Dictionary:
	var context := _context(attacker, target, tile_attacker, tile_target)
	var base_physical := float(_stat_value(attacker, "physical", 0))
	var raw := base_physical * PHYSICAL_ATTACK_SCALE * float(mods.get("power_mult", 1.0))
	if mods.has("base_power"):
		raw = base_physical * (float(mods.get("base_power", 100)) / 100.0)

	var attack_mult := _attacker_damage_multiplier(attacker) * float(mods.get("damage_mult", 1.0))
	var after_attack_mult := raw * attack_mult
	var resistance := maxf(0.0, float(_stat_value(target, "physical_resistance", 0)) + float(mods.get("resistance_delta", 0.0)))
	var resisted := maxf(after_attack_mult - resistance, 0.0)
	var damage_before_armor := maxi(0, int(round(resisted * float(context.get("height_mult", 1.0)) * float(context.get("facing_mult", 1.0)))))
	var armor := project_physical_armor_result(target, damage_before_armor)
	var accuracy := calculate_accuracy(DAMAGE_KIND_PHYSICAL, attacker, target, context, mods)
	var crit := calculate_crit(attacker, target, context, mods)

	return {
		"kind": DAMAGE_KIND_PHYSICAL,
		"element": "physical",
		"raw": int(round(raw)),
		"attack_mult": attack_mult,
		"resistance": int(round(resistance)),
		"physical_resistance": int(round(resistance)),
		"resisted": int(round(resisted)),
		"height_mult": context.get("height_mult", 1.0),
		"height_delta": context.get("height_delta", 0),
		"height_label": context.get("height_label", "Even ground"),
		"flank_mult": context.get("facing_mult", 1.0),
		"facing_mult": context.get("facing_mult", 1.0),
		"flank": context.get("facing_label", "front"),
		"facing_label": context.get("facing_label", "front"),
		"incoming_damage": damage_before_armor,
		"hp_damage": int(armor.get("hp_damage", 0)),
		"temper_damage": int(armor.get("temper_damage", 0)),
		"ether_damage": 0,
		"effective_damage": int(armor.get("effective_damage", damage_before_armor)),
		"hit_pct": accuracy.get("hit_pct", BASE_ATTACK_HIT),
		"crit_pct": crit.get("crit_pct", BASE_CRIT_CHANCE),
		"crit_mult": crit.get("crit_mult", CRIT_DAMAGE_MULT),
		"crit_damage": int(round(float(armor.get("hp_damage", 0)) * float(crit.get("crit_mult", CRIT_DAMAGE_MULT)))),
		"affinity": 1.0,
		"affinity_label": "",
		"explain": _damage_explain("Physical", raw, attack_mult, resistance, context, 1.0, armor, accuracy, crit),
	}


static func calculate_magical_attack(caster: Unit, target: Unit,
		spell_type: String, base_power: int,
		mods: Dictionary = {}) -> Dictionary:
	var element := normalize_element(spell_type)
	var raw := float(_stat_value(caster, "magic", 0)) * (float(base_power) / 100.0) * SPELL_POWER_SCALE
	var power_mult := float(mods.get("power_mult", 1.0)) * float(mods.get("damage_mult", 1.0))
	var after_power := raw * power_mult
	var resistance := maxf(0.0, float(_stat_value(target, "magic_resistance", 0)) + float(mods.get("resistance_delta", 0.0)))
	var resisted := maxf(after_power - resistance, 0.0)
	var affinity := elemental_affinity(target, element, mods)
	var damage_before_armor := maxi(0, int(round(resisted * affinity)))
	var armor := project_magical_armor_result(target, damage_before_armor)
	var context := _context(caster, target, {}, {})
	var accuracy := calculate_accuracy(DAMAGE_KIND_MAGICAL, caster, target, context, mods)
	var crit := calculate_crit(caster, target, context, {"base_crit": mods.get("base_crit", 0), "crit_bonus": mods.get("crit_bonus", 0)})

	return {
		"kind": DAMAGE_KIND_MAGICAL,
		"element": element,
		"raw": int(round(raw)),
		"attack_mult": power_mult,
		"resistance": int(round(resistance)),
		"magic_resistance": int(round(resistance)),
		"resisted": int(round(resisted)),
		"affinity": affinity,
		"affinity_label": affinity_label(affinity),
		"incoming_damage": damage_before_armor,
		"hp_damage": int(armor.get("hp_damage", 0)),
		"temper_damage": 0,
		"ether_damage": int(armor.get("ether_damage", 0)),
		"effective_damage": int(armor.get("effective_damage", damage_before_armor)),
		"hit_pct": accuracy.get("hit_pct", BASE_SPELL_HIT),
		"crit_pct": crit.get("crit_pct", 0),
		"crit_mult": crit.get("crit_mult", CRIT_DAMAGE_MULT),
		"crit_damage": int(round(float(armor.get("hp_damage", 0)) * float(crit.get("crit_mult", CRIT_DAMAGE_MULT)))),
		"height_mult": 1.0,
		"height_delta": 0,
		"flank_mult": 1.0,
		"facing_mult": 1.0,
		"flank": "front",
		"facing_label": "front",
		"explain": _damage_explain(element_label(element), raw, power_mult, resistance, context, affinity, armor, accuracy, crit),
	}


static func calculate_heal(caster: Unit, base_power: int, flat_bonus: int = 0) -> Dictionary:
	var raw := float(_stat_value(caster, "magic", 0)) * (float(base_power) / 100.0)
	var amount := maxi(0, int(round(raw)) + flat_bonus)
	return {"kind":"heal", "raw":int(round(raw)), "heal":amount, "explain":["Magic %d" % int(round(raw)), "Flat +%d" % flat_bonus]}


static func project_physical_armor_result(target: Unit, incoming_damage: int) -> Dictionary:
	var effective := maxi(0, incoming_damage)
	if target and target.has_status("protect"):
		effective = int(round(float(effective) * PROTECT_DAMAGE_MULT))
	if target and target.has_status("defending"):
		effective = int(round(float(effective) * 0.5))
	var temper := int(target.temper if target else 0)
	var absorbed := mini(temper, int(round(float(effective) * PHYSICAL_TEMPER_ABSORB_RATIO)))
	var hp_damage := 0
	if effective > 0:
		hp_damage = maxi(1, effective - int(round(float(absorbed) * ARMOR_TO_HP_REDUCTION_RATIO)))
	return {
		"effective_damage": effective,
		"hp_damage": hp_damage,
		"temper_damage": absorbed,
		"temper_before": temper,
		"temper_after": maxi(temper - absorbed, 0),
	}


static func project_magical_armor_result(target: Unit, incoming_damage: int) -> Dictionary:
	var effective := maxi(0, incoming_damage)
	if target and target.has_status("protect"):
		effective = int(round(float(effective) * PROTECT_DAMAGE_MULT))
	var ether := int(target.ether if target else 0)
	var absorbed := mini(ether, int(round(float(effective) * MAGICAL_ETHER_ABSORB_RATIO)))
	var hp_damage := 0
	if effective > 0:
		hp_damage = maxi(1, effective - int(round(float(absorbed) * ARMOR_TO_HP_REDUCTION_RATIO)))
	return {
		"effective_damage": effective,
		"hp_damage": hp_damage,
		"ether_damage": absorbed,
		"ether_before": ether,
		"ether_after": maxi(ether - absorbed, 0),
	}


static func calculate_accuracy(kind: String, attacker: Unit, target: Unit, context: Dictionary = {}, mods: Dictionary = {}) -> Dictionary:
	var hit := int(mods.get("base_hit", BASE_SPELL_HIT if kind == DAMAGE_KIND_MAGICAL else BASE_ATTACK_HIT))
	var facing_label := str(context.get("facing_label", "front"))
	if kind == DAMAGE_KIND_PHYSICAL:
		if facing_label == "back": hit += BACK_HIT_BONUS
		elif facing_label == "side": hit += SIDE_HIT_BONUS
		var height_delta := int(context.get("height_delta", 0))
		if height_delta > 0: hit += HIGH_GROUND_HIT_BONUS
		elif height_delta < 0: hit -= LOW_GROUND_HIT_PENALTY
	if attacker and attacker.has_status("blind"):
		hit -= BLIND_HIT_PENALTY
	if target and target.has_status("invisible"):
		hit -= 25
	if target and target.has_meta("dodge_chance"):
		hit -= int(round(float(target.get_meta("dodge_chance", 0.0)) * 100.0))
	hit += int(mods.get("hit_bonus", 0))
	return {"hit_pct": clampi(hit, HIT_FLOOR, HIT_CEILING)}


static func calculate_crit(_attacker: Unit, _target: Unit, context: Dictionary = {}, mods: Dictionary = {}) -> Dictionary:
	var crit := int(mods.get("base_crit", BASE_CRIT_CHANCE))
	var facing_label := str(context.get("facing_label", "front"))
	if facing_label == "back": crit += BACK_CRIT_BONUS
	elif facing_label == "side": crit += SIDE_CRIT_BONUS
	if int(context.get("height_delta", 0)) > 0:
		crit += HIGH_GROUND_CRIT_BONUS
	crit += int(mods.get("crit_bonus", 0))
	return {"crit_pct": clampi(crit, 0, 100), "crit_mult": float(mods.get("crit_mult", CRIT_DAMAGE_MULT))}


static func height_multiplier(tile_attacker: Dictionary, tile_target: Dictionary) -> float:
	var delta := int(tile_attacker.get("height", 0)) - int(tile_target.get("height", 0))
	if delta > 0:
		return 1.0 + minf(MAX_HEIGHT_BONUS, float(delta) * HIGH_GROUND_STEP_BONUS)
	if delta < 0:
		return 1.0 - minf(MAX_HEIGHT_PENALTY, float(abs(delta)) * LOW_GROUND_STEP_PENALTY)
	return 1.0


static func flank_multiplier(attacker: Unit, target: Unit) -> float:
	return float(_context(attacker, target, {}, {}).get("facing_mult", 1.0))


static func attack_direction(attacker_pos: Vector2i, target_pos: Vector2i) -> String:
	var delta := attacker_pos - target_pos
	if abs(delta.x) >= abs(delta.y):
		return "E" if delta.x > 0 else "W"
	return "S" if delta.y > 0 else "N"


static func flank_label_from_multiplier(multiplier: float) -> String:
	if multiplier >= BACK_MULT - 0.01:
		return "back"
	if multiplier > FRONT_MULT:
		return "side"
	return "front"


static func elemental_affinity(target: Unit, element: String, mods: Dictionary = {}) -> float:
	var normalized := normalize_element(element)
	var affinity := 1.0
	if target and target.unit_data and not target.unit_data.elemental_affinities.is_empty():
		affinity = float(target.unit_data.elemental_affinities.get(normalized, target.unit_data.elemental_affinities.get(element, 1.0)))
	if target and target.has_meta("immune") and normalized in target.get_meta("immune", []):
		affinity = 0.0
	if mods.has("affinity_override"):
		affinity = float(mods.get("affinity_override", affinity))
	return maxf(0.0, affinity)


static func affinity_label(affinity: float) -> String:
	if affinity == 0.0: return "Immune"
	if affinity < 0.5: return "Absorbs"
	if affinity < 1.0: return "Resists"
	if affinity >= 2.0: return "Very weak"
	if affinity > 1.0: return "Weak"
	return ""


static func normalize_element(element: String) -> String:
	if element == "ice": return "blizzard"
	if element == "cure": return "heal"
	return element


static func element_label(element: String) -> String:
	return str(ELEMENT_LABELS.get(normalize_element(element), element.capitalize()))


static func _context(attacker: Unit, target: Unit, tile_attacker: Dictionary, tile_target: Dictionary) -> Dictionary:
	var height_delta := int(tile_attacker.get("height", 0)) - int(tile_target.get("height", 0))
	var height_mult := height_multiplier(tile_attacker, tile_target)
	var facing_mult := FRONT_MULT
	var facing_label := "front"
	if attacker and target:
		var attack_from := attack_direction(attacker.grid_pos, target.grid_pos)
		if attack_from == target.facing:
			facing_mult = FRONT_MULT
		elif attack_from == FACING_OPPOSITE.get(target.facing, ""):
			facing_mult = BACK_MULT
		else:
			facing_mult = SIDE_MULT
		facing_label = flank_label_from_multiplier(facing_mult)
	return {
		"height_delta": height_delta,
		"height_mult": height_mult,
		"height_label": "Height %+d" % height_delta if height_delta != 0 else "Even ground",
		"facing_mult": facing_mult,
		"facing_label": facing_label,
	}


static func _attacker_damage_multiplier(attacker: Unit) -> float:
	var mult := 1.0
	if not attacker:
		return mult
	if attacker.has_meta("dmg_mult"):
		mult *= float(attacker.get_meta("dmg_mult", 1.0))
	if attacker.has_meta("prefixes") and attacker.unit_data:
		for pfx: Dictionary in attacker.get_meta("prefixes", []):
			if pfx.get("id", "") == "berserker" and attacker.hp < attacker.unit_data.base_stats.hp * 0.5:
				mult *= float(pfx.get("conditional", {}).get("dmg", 1.25))
	return mult


static func _stat_value(unit: Unit, stat_name: String, fallback: int) -> int:
	if not unit or not unit.unit_data or not unit.unit_data.base_stats:
		return fallback
	var value: Variant = unit.unit_data.base_stats.get(stat_name)
	return fallback if value == null else int(value)


static func _damage_explain(label: String, raw: float, attack_mult: float, resistance: float,
		context: Dictionary, affinity: float, armor: Dictionary, accuracy: Dictionary, crit: Dictionary) -> Array[String]:
	var rows: Array[String] = ["%s %d" % [label, int(round(raw))]]
	if attack_mult != 1.0:
		rows.append("Power %s" % _signed_percent(attack_mult - 1.0))
	if resistance > 0.0:
		rows.append("Resist -%d" % int(round(resistance)))
	var height_delta := int(context.get("height_delta", 0))
	var height_mult := float(context.get("height_mult", 1.0))
	if height_delta != 0 or height_mult != 1.0:
		var height_name := "High Ground" if height_delta > 0 else "Low Ground"
		rows.append("%s %s" % [height_name, _signed_percent(height_mult - 1.0)])
	var facing_mult := float(context.get("facing_mult", 1.0))
	if facing_mult != 1.0:
		rows.append("%s %s" % [str(context.get("facing_label", "front")).capitalize(), _signed_percent(facing_mult - 1.0)])
	if affinity != 1.0:
		rows.append("%s %s" % [affinity_label(affinity), _signed_percent(affinity - 1.0)])
	var temper_damage := int(armor.get("temper_damage", 0))
	var ether_damage := int(armor.get("ether_damage", 0))
	if temper_damage > 0:
		rows.append("Temper -%d" % temper_damage)
	if ether_damage > 0:
		rows.append("Ether -%d" % ether_damage)
	var hp_damage := int(armor.get("hp_damage", 0))
	if hp_damage > 0:
		rows.append("HP %d" % hp_damage)
	rows.append("Hit %d%%" % int(accuracy.get("hit_pct", 100)))
	var crit_pct := int(crit.get("crit_pct", 0))
	if crit_pct > 0:
		rows.append("Crit %d%%" % crit_pct)
	return rows


static func _signed_percent(delta: float) -> String:
	return "%+d%%" % int(round(delta * 100.0))
