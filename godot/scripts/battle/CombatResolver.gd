## CombatResolver.gd
## Resolves all combat: attacks, spells, heals.
## Reads RunBonuses for boon effects + elite prefix on-hit hooks.

class_name CombatResolver
extends Node

signal combat_resolved(result: Dictionary)

const FACING_OPPOSITE: Dictionary = {"N":"S","S":"N","E":"W","W":"E"}
const RunBonusesUtil := preload("res://scripts/roguelike/RunBonuses.gd")


func resolve_attack(attacker: Unit, target: Unit,
		tile_attacker: Dictionary, tile_target: Dictionary,
		vfx_mode: String = "slash", is_counter: bool = false) -> Dictionary:
	# Blind miss
	if attacker.has_status("blind") and randf() < 0.35:
		var blind_vfx_node := get_node_or_null("/root/VFX")
		if blind_vfx_node: (blind_vfx_node as VFXManager).play_damage_number(target.grid_pos, 0, Color(0.65,0.65,0.65))
		var blind_result := {"damage":0,"hp_damage":0,"missed":true}
		combat_resolved.emit(blind_result); return blind_result

	# Dodge from elite suffix
	if target.has_meta("elite_tier") and target.get_meta("dodge_chance", 0.0) > 0:
		if randf() < target.get_meta("dodge_chance", 0.0):
			var dodge_vfx_node := get_node_or_null("/root/VFX")
			if dodge_vfx_node: (dodge_vfx_node as VFXManager).play_damage_number(target.grid_pos, 0, Color(0.6,0.6,0.9))
			var dodge_result := {"damage":0,"hp_damage":0,"missed":true,"dodged":true}
			combat_resolved.emit(dodge_result); return dodge_result

	var raw: float = attacker.unit_data.base_stats.physical * 1.2

	# Elite empowered prefix
	if attacker.has_meta("dmg_mult"):
		raw *= attacker.get_meta("dmg_mult", 1.0)

	# Berserking conditional (below 50% HP)
	if attacker.has_meta("prefixes"):
		for pfx: Dictionary in attacker.get_meta("prefixes", []):
			if pfx.get("id","") == "berserker" and attacker.hp < attacker.unit_data.base_stats.hp * 0.5:
				raw *= pfx.get("conditional",{}).get("dmg", 1.25)

	var att_h: int = tile_attacker.get("height",0)
	var tar_h: int = tile_target.get("height",0)
	var height_m: float = 1.15 if att_h > tar_h else (0.9 if att_h < tar_h else 1.0)
	var flank_m: float  = _get_flank_multiplier(attacker, target)
	var final_damage: int = int(round(raw * height_m * flank_m))

	var dmg_color := Color(1.0,0.95,0.4)
	if flank_m >= 1.25: dmg_color = Color(1.0,0.45,0.1)
	elif flank_m > 1.0: dmg_color = Color(1.0,0.78,0.2)

	var vfx_n := get_node_or_null("/root/VFX")
	if vfx_n:
		var vfx := vfx_n as VFXManager
		if vfx_mode == "arrow": vfx.play_arrow(attacker.grid_pos, target.grid_pos, final_damage, dmg_color)
		else:                   vfx.play_attack(attacker.grid_pos, target.grid_pos, final_damage, dmg_color)

	_play_sfx("attack_impact", -3.0)
	var dmg_result := target.receive_damage(final_damage, "physical")

	if target.hp <= 0:
		if vfx_n: get_tree().create_timer(0.3).timeout.connect(func()->void: (vfx_n as VFXManager).play_death(target.grid_pos))
	elif target.has_method("animate_hit"):
		target.animate_hit()

	# ── Elite on-hit effects ────────────────────────────────────────────
	_apply_elite_on_hit(attacker, target, final_damage)

	var flank_str := "back" if flank_m >= 1.25 else ("side" if flank_m > 1.0 else "front")
	var should_counter := false
	if not is_counter and vfx_mode != "arrow" and target.hp > 0:
		var dist: int = abs(attacker.grid_pos.x - target.grid_pos.x) + abs(attacker.grid_pos.y - target.grid_pos.y)
		if dist <= target.unit_data.base_stats.attack_range_max and randf() < 0.25:
			should_counter = true

	var result := {
		"damage":        final_damage,
		"hp_damage":     dmg_result.get("hp_damage",0),
		"temper_damage": dmg_result.get("temper_damage",0),
		"ether_damage":  dmg_result.get("ether_damage",0),
		"height_bonus":  height_m,
		"flank":         flank_str,
		"counter":       should_counter,
	}
	combat_resolved.emit(result)
	return result


func resolve_spell(caster: Unit, target: Unit,
		spell_type: String, base_power: int) -> Dictionary:
	_play_sfx("spell_cast", -2.5)

	var raw: float = caster.unit_data.base_stats.magic * (base_power / 100.0)

	# ── Boon elemental bonus ────────────────────────────────────────────
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	var el_mult: float = bonuses["elemental_mult"].get(spell_type, 1.0)
	raw *= el_mult

	# ── Elemental affinity ───────────────────────────────────────────────
	var affinity: float = 1.0
	if target.unit_data and not target.unit_data.elemental_affinities.is_empty():
		affinity = target.unit_data.elemental_affinities.get(spell_type, 1.0)

	# Immune from elite suffix
	if target.has_meta("elite_tier"):
		var immune: Array = target.get_meta("immune", [])
		if spell_type in immune: affinity = 0.0

	var final_damage: int = int(round(raw * affinity))

	# ── Brand boon: burning enemies take bonus physical damage ──────────
	if bonuses["brand_bonus"] > 0.0 and target.has_status("burn"):
		final_damage = int(round(float(final_damage) * (1.0 + bonuses["brand_bonus"])))

	var num_color: Color
	if affinity == 0.0:      num_color = Color(0.55,0.55,0.55)
	elif affinity >= 1.5:    num_color = Color(1.0,0.22,0.08)
	elif affinity > 1.0:     num_color = Color(1.0,0.58,0.15)
	elif affinity < 1.0:     num_color = Color(0.38,0.62,1.0)
	else:                    num_color = Color(0.8,0.7,1.0)

	# Boost colour saturation if boon gave a bonus
	if el_mult > 1.0: num_color = num_color.lightened(0.15)

	var vfx_n := get_node_or_null("/root/VFX")
	if vfx_n:
		var vfx := vfx_n as VFXManager
		match spell_type:
			"fire":     vfx.play_fire(target.grid_pos)
			"blizzard": vfx.play_blizzard(target.grid_pos)
			"thunder":  vfx.play_thunder(target.grid_pos)
			"wind":     vfx.play_wind(target.grid_pos)
			"holy":     vfx.play_holy(target.grid_pos)
			"dark":     vfx.play_dark(target.grid_pos)
		await get_tree().create_timer(0.18).timeout
		vfx.play_damage_number(target.grid_pos, final_damage, num_color)

	var dmg_result := target.receive_damage(final_damage, "magical")
	if target.hp <= 0 and vfx_n:
		get_tree().create_timer(0.35).timeout.connect(func()->void: (vfx_n as VFXManager).play_death(target.grid_pos))
	elif target.has_method("animate_hit"):
		target.animate_hit()

	# ── Elite on-hit effects (spell) ─────────────────────────────────────
	_apply_elite_on_hit(caster, target, final_damage)

	var result := {
		"damage":      final_damage,
		"hp_damage":   dmg_result.get("hp_damage",0),
		"ether_damage":dmg_result.get("ether_damage",0),
		"spell_type":  spell_type,
		"affinity":    affinity,
		"el_boon_mult":el_mult,
		"is_weakness": affinity > 1.0,
	}
	combat_resolved.emit(result)
	return result


func resolve_heal(_caster: Unit, target: Unit, heal_amount: int) -> Dictionary:
	# Heal bonus from boons
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	heal_amount += bonuses["heal_bonus"]

	target.heal(heal_amount)
	_play_sfx("spell_cast", -4.0)
	var vfx_n := get_node_or_null("/root/VFX")
	if vfx_n:
		var vfx := vfx_n as VFXManager
		vfx.play_cure(target.grid_pos)
		vfx.play_heal_number(target.grid_pos, heal_amount)
	var result := {"healed": heal_amount}
	combat_resolved.emit(result)
	return result


# ── Elite prefix on-hit effects ───────────────────────────────────────────────

func _apply_elite_on_hit(attacker: Unit, target: Unit, damage_dealt: int) -> void:
	if not attacker.has_meta("prefixes"): return
	var prefixes: Array = attacker.get_meta("prefixes", [])
	var vfx_n := get_node_or_null("/root/VFX")

	for pfx: Dictionary in prefixes:
		var oh: Dictionary = pfx.get("on_hit", {})
		if oh.is_empty(): continue

		match oh.get("type",""):

			"mp_drain":
				var amount: int = oh.get("amount", 20)
				if target.mp > 0:
					target.mp = max(0, target.mp - amount)
					if vfx_n: (vfx_n as VFXManager).play_damage_number(
						target.grid_pos, amount, Color(0.65, 0.35, 1.0))

			"lifesteal":
				var pct: float = oh.get("pct", 0.3)
				var heal: int  = int(float(damage_dealt) * pct)
				if heal > 0:
					attacker.heal(heal)
					if vfx_n: (vfx_n as VFXManager).play_heal_number(attacker.grid_pos, heal)

			"status":
				var chance: float = oh.get("chance", 0.35)
				if randf() < chance:
					var sid: String   = oh.get("status","burn")
					var turns: int    = oh.get("turns", 2)
					var immune: bool  = target.get_meta("status_immune", false) if target.has_meta("status_immune") else false
					if not immune and not target.has_status(sid):
						var status := StatusEffect.new()
						status.status_id = sid
						status.display_name = sid.capitalize()
						status.duration = turns
						status.magnitude = 0.0
						target.apply_status(status)
						if vfx_n: (vfx_n as VFXManager).play_damage_number(
							target.grid_pos, 0, Color(0.9,0.4,0.1))


# ── Helpers ───────────────────────────────────────────────────────────────────

func _play_sfx(sfx_id: String, volume_db: float = 0.0) -> void:
	var audio := get_node_or_null("/root/AudioSettings")
	if audio and audio.has_method("play_sfx"): audio.play_sfx(sfx_id, volume_db)

func _get_flank_multiplier(attacker: Unit, target: Unit) -> float:
	var delta: Vector2i = attacker.grid_pos - target.grid_pos
	var attack_from: String
	if abs(delta.x) >= abs(delta.y): attack_from = "E" if delta.x > 0 else "W"
	else:                            attack_from = "S" if delta.y > 0 else "N"
	if attack_from == target.facing:                    return 1.0
	if attack_from == FACING_OPPOSITE.get(target.facing,""): return 1.3
	return 1.15
