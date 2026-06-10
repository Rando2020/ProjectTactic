## CombatResolver.gd
## Resolves combat by applying the shared CombatFormula contract.

class_name CombatResolver
extends Node

signal combat_resolved(result: Dictionary)

const RunBonusesUtil := preload("res://scripts/roguelike/RunBonuses.gd")
func resolve_attack(attacker: Unit, target: Unit,
		tile_attacker: Dictionary, tile_target: Dictionary,
		vfx_mode: String = "slash", is_counter: bool = false) -> Dictionary:
	var formula := CombatFormula.calculate_physical_attack(attacker, target, tile_attacker, tile_target)
	var hit_pct := int(formula.get("hit_pct", 100))
	if randi_range(1, 100) > hit_pct:
		var miss_result := {
			"damage": 0, "hp_damage": 0, "temper_damage": 0, "ether_damage": 0,
			"missed": true, "hit_pct": hit_pct, "formula_explain": formula.get("explain", []),
			"actor_id": attacker.unit_id if attacker else "",
			"actor_team": attacker.team if attacker else "",
			"target_id": target.unit_id if target else "",
			"target_team": target.team if target else "",
		}
		_show_miss(target)
		combat_resolved.emit(miss_result)
		return miss_result

	var incoming_damage: int = int(formula.get("incoming_damage", 0))
	var crit_pct := int(formula.get("crit_pct", 0))
	var did_crit := randi_range(1, 100) <= crit_pct
	if did_crit:
		incoming_damage = int(round(float(incoming_damage) * float(formula.get("crit_mult", 1.5))))

	var armor := CombatFormula.project_physical_armor_result(target, incoming_damage)
	var preview_hp_damage := int(armor.get("hp_damage", incoming_damage))
	var flank_m := float(formula.get("flank_mult", 1.0))
	var dmg_color := Color(1.0, 0.95, 0.4)
	if did_crit:
		dmg_color = Color(1.0, 0.25, 0.1)
	elif flank_m >= 1.25:
		dmg_color = Color(1.0, 0.45, 0.1)
	elif flank_m > 1.0:
		dmg_color = Color(1.0, 0.78, 0.2)

	var vfx_n := get_node_or_null("/root/VFX")
	if vfx_n:
		var vfx := vfx_n as VFXManager
		if vfx_mode == "arrow":
			vfx.play_arrow(attacker.grid_pos, target.grid_pos, preview_hp_damage, dmg_color)
		else:
			vfx.play_attack(attacker.grid_pos, target.grid_pos, preview_hp_damage, dmg_color)
		if did_crit:
			vfx.play_tactical_tag(target.grid_pos, "CRIT", Color(1.0, 0.22, 0.10))
		elif flank_m >= 1.25:
			vfx.play_tactical_tag(target.grid_pos, "BACK", Color(1.0, 0.48, 0.10))
		elif flank_m > 1.0:
			vfx.play_tactical_tag(target.grid_pos, "SIDE", Color(1.0, 0.78, 0.20))

	_play_sfx("attack_impact", -3.0)
	var dmg_result := target.receive_damage(incoming_damage, "physical")
	var actual_hp_damage := int(dmg_result.get("hp_damage", 0))

	# Trigger hit effects based on damage intensity
	var hit_intensity := "normal"
	if actual_hp_damage > 150:
		hit_intensity = "critical"
	elif actual_hp_damage > 100:
		hit_intensity = "heavy"
	elif actual_hp_damage > 50:
		hit_intensity = "normal"
	else:
		hit_intensity = "light"
	BattleJuiceEffects.trigger_hit([target.unit_id], hit_intensity, 80, 300, 150)

	if target.hp <= 0:
		if vfx_n:
			get_tree().create_timer(0.22).timeout.connect(func() -> void: (vfx_n as VFXManager).play_ko(target.grid_pos))
			get_tree().create_timer(0.38).timeout.connect(func() -> void: (vfx_n as VFXManager).play_death(target.grid_pos))
	elif target.has_method("animate_hit"):
		target.animate_hit()

	_apply_elite_on_hit(attacker, target, actual_hp_damage)

	var should_counter := false
	if not is_counter and vfx_mode != "arrow" and target.hp > 0:
		var dist: int = abs(attacker.grid_pos.x - target.grid_pos.x) + abs(attacker.grid_pos.y - target.grid_pos.y)
		if dist <= target.unit_data.base_stats.attack_range_max and randf() < 0.25:
			should_counter = true

	var result := {
		"damage": actual_hp_damage,
		"incoming_damage": incoming_damage,
		"formula_explain": formula.get("explain", []),
		"hp_damage": actual_hp_damage,
		"temper_damage": dmg_result.get("temper_damage", 0),
		"ether_damage": dmg_result.get("ether_damage", 0),
		"height_bonus": formula.get("height_mult", 1.0),
		"flank": formula.get("flank", "front"),
		"hit_pct": hit_pct,
		"crit_pct": crit_pct,
		"critical": did_crit,
		"counter": should_counter,
		"actor_id": attacker.unit_id if attacker else "",
		"actor_team": attacker.team if attacker else "",
		"target_id": target.unit_id if target else "",
		"target_team": target.team if target else "",
	}
	combat_resolved.emit(result)
	return result


func resolve_spell(caster: Unit, target: Unit,
		spell_type: String, base_power: int) -> Dictionary:
	_play_sfx("spell_cast", -2.5)
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	var element := CombatFormula.normalize_element(spell_type)
	var el_mult: float = float(bonuses["elemental_mult"].get(element, 1.0))
	el_mult *= CombatFormula.item_elemental_multiplier(caster, element)
	var formula := CombatFormula.calculate_magical_attack(caster, target, element, base_power, {"power_mult": el_mult})
	var hit_pct := int(formula.get("hit_pct", 100))
	if randi_range(1, 100) > hit_pct:
		var miss_result := {"damage":0, "hp_damage":0, "missed":true, "spell_type":element, "hit_pct":hit_pct}
		miss_result["actor_id"] = caster.unit_id if caster else ""
		miss_result["actor_team"] = caster.team if caster else ""
		miss_result["target_id"] = target.unit_id if target else ""
		miss_result["target_team"] = target.team if target else ""
		_show_miss(target)
		combat_resolved.emit(miss_result)
		return miss_result

	var final_damage: int = int(formula.get("incoming_damage", 0))
	if bonuses.get("brand_bonus", 0.0) > 0.0 and target.has_status("burn") and element == "physical":
		final_damage = int(round(float(final_damage) * (1.0 + float(bonuses["brand_bonus"]))))

	var affinity := float(formula.get("affinity", 1.0))
	var num_color := _element_damage_color(affinity, el_mult)
	var vfx_n := get_node_or_null("/root/VFX")
	if vfx_n:
		var vfx := vfx_n as VFXManager
		match element:
			"fire": vfx.play_fire(target.grid_pos)
			"blizzard": vfx.play_blizzard(target.grid_pos)
			"thunder": vfx.play_thunder(target.grid_pos)
			"wind": vfx.play_wind(target.grid_pos)
			"holy": vfx.play_holy(target.grid_pos)
			"dark": vfx.play_dark(target.grid_pos)
		await get_tree().create_timer(0.18).timeout
		vfx.play_damage_number(target.grid_pos, int(formula.get("hp_damage", final_damage)), num_color)

	var dmg_result := target.receive_damage(final_damage, "magical")
	var actual_hp_damage := int(dmg_result.get("hp_damage", 0))

	# Trigger hit effects for spell damage
	var spell_intensity := "normal"
	if actual_hp_damage > 150:
		spell_intensity = "critical"
	elif actual_hp_damage > 100:
		spell_intensity = "heavy"
	elif actual_hp_damage > 50:
		spell_intensity = "normal"
	else:
		spell_intensity = "light"
	BattleJuiceEffects.trigger_hit([target.unit_id], spell_intensity, 60, 250, 120)

	if target.hp <= 0 and vfx_n:
		get_tree().create_timer(0.22).timeout.connect(func() -> void: (vfx_n as VFXManager).play_ko(target.grid_pos))
		get_tree().create_timer(0.42).timeout.connect(func() -> void: (vfx_n as VFXManager).play_death(target.grid_pos))
	elif target.has_method("animate_hit"):
		target.animate_hit()

	_apply_elite_on_hit(caster, target, actual_hp_damage)
	_apply_spell_curses(caster, target, element, actual_hp_damage, bonuses)

	var result := {
		"damage": actual_hp_damage,
		"incoming_damage": final_damage,
		"formula_explain": formula.get("explain", []),
		"hp_damage": actual_hp_damage,
		"ether_damage": dmg_result.get("ether_damage", 0),
		"spell_type": element,
		"affinity": affinity,
		"el_boon_mult": el_mult,
		"hit_pct": hit_pct,
		"is_weakness": affinity > 1.0,
		"actor_id": caster.unit_id if caster else "",
		"actor_team": caster.team if caster else "",
		"target_id": target.unit_id if target else "",
		"target_team": target.team if target else "",
	}
	combat_resolved.emit(result)
	return result


func resolve_heal(caster: Unit, target: Unit, heal_amount: int) -> Dictionary:
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	heal_amount += int(bonuses.get("heal_bonus", 0))
	target.heal(heal_amount)
	_play_sfx("spell_cast", -4.0)
	var vfx_n := get_node_or_null("/root/VFX")
	if vfx_n:
		var vfx := vfx_n as VFXManager
		vfx.play_cure(target.grid_pos)
		vfx.play_heal_number(target.grid_pos, heal_amount)
	var result := {
		"healed": heal_amount,
		"actor_id": caster.unit_id if caster else "",
		"actor_team": caster.team if caster else "",
		"target_id": target.unit_id if target else "",
		"target_team": target.team if target else "",
	}
	combat_resolved.emit(result)
	return result


func _apply_spell_curses(caster: Unit, target: Unit, element: String, final_damage: int, bonuses: Dictionary) -> void:
	if bonuses.get("curse_ether_drain_on_hit", 0) > 0 and target.team == "enemy":
		for player_unit: Unit in get_tree().get_nodes_in_group("player_units"):
			if player_unit.hp > 0:
				player_unit.ether = max(0, player_unit.ether - int(bonuses["curse_ether_drain_on_hit"]))
	if element == "fire" and bonuses.get("curse_self_fire_pct", 0.0) > 0.0:
		var self_dmg: int = int(float(final_damage) * float(bonuses["curse_self_fire_pct"]))
		if self_dmg > 0 and caster.team == "player":
			caster.receive_damage(self_dmg, "magical")
			var vfx2 := get_node_or_null("/root/VFX")
			if vfx2:
				(vfx2 as VFXManager).play_damage_number(caster.grid_pos, self_dmg, Color(1.0, 0.35, 0.1))


func _apply_elite_on_hit(attacker: Unit, target: Unit, damage_dealt: int) -> void:
	if not attacker.has_meta("prefixes"):
		return
	var prefixes: Array = attacker.get_meta("prefixes", [])
	var vfx_n := get_node_or_null("/root/VFX")
	for pfx: Dictionary in prefixes:
		var oh: Dictionary = pfx.get("on_hit", {})
		if oh.is_empty():
			continue
		match oh.get("type", ""):
			"mp_drain":
				var amount: int = oh.get("amount", 20)
				if target.mp > 0:
					target.mp = max(0, target.mp - amount)
					if vfx_n:
						(vfx_n as VFXManager).play_damage_number(target.grid_pos, amount, Color(0.65, 0.35, 1.0))
			"lifesteal":
				var pct: float = oh.get("pct", 0.3)
				var heal: int = int(float(damage_dealt) * pct)
				if heal > 0:
					attacker.heal(heal)
					if vfx_n:
						(vfx_n as VFXManager).play_heal_number(attacker.grid_pos, heal)
			"status":
				var chance: float = oh.get("chance", 0.35)
				if randf() < chance:
					var sid: String = oh.get("status", "burn")
					var turns: int = oh.get("turns", 2)
					var immune: bool = target.get_meta("status_immune", false) if target.has_meta("status_immune") else false
					if not immune and not target.has_status(sid):
						var status := StatusEffect.new()
						status.status_id = sid
						status.display_name = sid.capitalize()
						status.duration = turns
						status.magnitude = 0.0
						target.apply_status(status)
						if vfx_n:
							(vfx_n as VFXManager).play_damage_number(target.grid_pos, 0, Color(0.9, 0.4, 0.1))


func _element_damage_color(affinity: float, el_mult: float) -> Color:
	var num_color: Color
	if affinity == 0.0: num_color = Color(0.55, 0.55, 0.55)
	elif affinity >= 1.5: num_color = Color(1.0, 0.22, 0.08)
	elif affinity > 1.0: num_color = Color(1.0, 0.58, 0.15)
	elif affinity < 1.0: num_color = Color(0.38, 0.62, 1.0)
	else: num_color = Color(0.8, 0.7, 1.0)
	if el_mult > 1.0:
		num_color = num_color.lightened(0.15)
	return num_color


func _show_zero(target: Unit, color: Color) -> void:
	var vfx_n := get_node_or_null("/root/VFX")
	if vfx_n:
		(vfx_n as VFXManager).play_damage_number(target.grid_pos, 0, color)


func _show_miss(target: Unit) -> void:
	var vfx_n := get_node_or_null("/root/VFX")
	if vfx_n:
		var vfx := vfx_n as VFXManager
		vfx.play_target_ping(target.grid_pos, Color(0.65, 0.72, 0.82, 0.75))
		vfx.play_miss(target.grid_pos)


func _play_sfx(sfx_id: String, volume_db: float = 0.0) -> void:
	var audio := get_node_or_null("/root/AudioSettings")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(sfx_id, volume_db)
