## CombatResolver.gd
## Resolves combat by applying the shared CombatFormula contract.

class_name CombatResolver
extends Node

signal combat_resolved(result: Dictionary)
## Presentation-only recipe for the hit that is about to resolve. Kept off the
## result dictionary so mechanical outcomes stay identical across feedback owners.
signal impact_presented(impact: Dictionary)

const RunBonusesUtil := preload("res://scripts/roguelike/RunBonuses.gd")
const UISettings := preload("res://scripts/ui/UISettings.gd")
# Synchronous feedback policy during receive_damage; never changes damage authority.
var damage_feedback_owner: StringName = &""
func resolve_attack(attacker: Unit, target: Unit,
		tile_attacker: Dictionary, tile_target: Dictionary,
		vfx_mode: String = "slash", is_counter: bool = false, mods: Dictionary = {}, feedback_owner: StringName = &"") -> Dictionary:
	var formula := CombatFormula.calculate_physical_attack(attacker, target, tile_attacker, tile_target, mods)
	var hit_pct := int(formula.get("hit_pct", 100))
	if randi_range(1, 100) > hit_pct:
		var miss_result := {
			"damage": 0, "hp_damage": 0, "applied_hp_damage": 0, "temper_damage": 0, "ether_damage": 0,
			"missed": true, "hit_pct": hit_pct, "formula_explain": formula.get("explain", []),
		}
		if feedback_owner.is_empty(): _show_miss(target)
		else: miss_result["feedback_owner"] = feedback_owner
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
	var dmg_result := _receive_damage_with_feedback(target, incoming_damage, "physical", feedback_owner)
	var actual_hp_damage := int(dmg_result.get("hp_damage", 0))
	var impact := _impact_profile(attacker, target, actual_hp_damage, did_crit, "arrow" if vfx_mode == "arrow" else "melee", "")
	if vfx_n and feedback_owner.is_empty():
		var vfx := vfx_n as VFXManager
		vfx.play_punchy_attack(attacker.grid_pos, target.grid_pos, preview_hp_damage, dmg_color, impact, "arrow" if vfx_mode == "arrow" else "melee")
		if did_crit:
			vfx.play_tactical_tag(target.grid_pos, "CRIT", Color(1.0, 0.22, 0.10))
		elif flank_m >= 1.25:
			vfx.play_tactical_tag(target.grid_pos, "BACK", Color(1.0, 0.48, 0.10))
		elif flank_m > 1.0:
			vfx.play_tactical_tag(target.grid_pos, "SIDE", Color(1.0, 0.78, 0.20))

	if feedback_owner.is_empty(): BattleJuiceEffects.punch(target, impact)

	if target.hp <= 0:
		if vfx_n and feedback_owner.is_empty():
			var death_pos := target.grid_pos
			get_tree().create_timer(0.22).timeout.connect(func() -> void: (vfx_n as VFXManager).play_ko(death_pos))
			get_tree().create_timer(0.38).timeout.connect(func() -> void: (vfx_n as VFXManager).play_death(death_pos))
	elif feedback_owner.is_empty() and target.has_method("animate_hit"):
		target.animate_hit(float(impact.flash_sec))

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
		"applied_hp_damage": dmg_result["applied_hp_damage"],
		"temper_damage": dmg_result.get("temper_damage", 0),
		"ether_damage": dmg_result.get("ether_damage", 0),
		"height_bonus": formula.get("height_mult", 1.0),
		"flank": formula.get("flank", "front"),
		"hit_pct": hit_pct,
		"crit_pct": crit_pct,
		"critical": did_crit,
		"counter": should_counter,
	}
	if not feedback_owner.is_empty():
		result["feedback_owner"] = feedback_owner
		result["defeated"] = bool(dmg_result.get("defeated",false))
	else:
		impact_presented.emit(_impact_summary(impact))
	combat_resolved.emit(result)
	return result


func resolve_spell(caster: Unit, target: Unit,
		spell_type: String, base_power: int, feedback_owner: StringName = &"") -> Dictionary:
	if feedback_owner.is_empty(): _play_sfx("spell_cast", -2.5)
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	var element := CombatFormula.normalize_element(spell_type)
	var el_mult: float = float(bonuses["elemental_mult"].get(element, 1.0))
	var formula := CombatFormula.calculate_magical_attack(caster, target, element, base_power, {"power_mult": el_mult})
	var hit_pct := int(formula.get("hit_pct", 100))
	if randi_range(1, 100) > hit_pct:
		var miss_result := {"damage":0, "hp_damage":0, "applied_hp_damage":0, "temper_damage":0, "ether_damage":0, "missed":true, "spell_type":element, "hit_pct":hit_pct}
		if feedback_owner.is_empty(): _show_miss(target)
		else: miss_result["feedback_owner"] = feedback_owner
		combat_resolved.emit(miss_result)
		return miss_result

	var final_damage: int = int(formula.get("incoming_damage", 0))
	if bonuses.get("brand_bonus", 0.0) > 0.0 and target.has_status("burn") and element == "physical":
		final_damage = int(round(float(final_damage) * (1.0 + float(bonuses["brand_bonus"]))))

	var affinity := float(formula.get("affinity", 1.0))
	var num_color := _element_damage_color(affinity, el_mult)
	var vfx_n := get_node_or_null("/root/VFX")
	var dmg_result := _receive_damage_with_feedback(target, final_damage, "magical", feedback_owner)
	var actual_hp_damage := int(dmg_result.get("hp_damage", 0))
	var impact := _impact_profile(caster, target, actual_hp_damage, false, "spell", element)
	if vfx_n and feedback_owner.is_empty():
		var vfx := vfx_n as VFXManager
		if ImpactJuice.has_staged_spell(element):
			vfx.play_spell_finale(caster.grid_pos, target.grid_pos, element, impact, caster.get_instance_id() ^ target.get_instance_id(), target.visual as CanvasItem)
		vfx.play_damage_number(target.grid_pos, int(formula.get("hp_damage", final_damage)), num_color)

	if feedback_owner.is_empty(): BattleJuiceEffects.punch(target, impact)

	if target.hp <= 0 and vfx_n and feedback_owner.is_empty():
		var death_pos := target.grid_pos
		get_tree().create_timer(0.22).timeout.connect(func() -> void: (vfx_n as VFXManager).play_ko(death_pos))
		get_tree().create_timer(0.42).timeout.connect(func() -> void: (vfx_n as VFXManager).play_death(death_pos))
	elif feedback_owner.is_empty() and target.has_method("animate_hit"):
		target.animate_hit(float(impact.flash_sec))

	_apply_elite_on_hit(caster, target, actual_hp_damage)
	_apply_spell_curses(caster, target, element, actual_hp_damage, bonuses)

	var result := {
		"damage": actual_hp_damage,
		"incoming_damage": final_damage,
		"formula_explain": formula.get("explain", []),
		"hp_damage": actual_hp_damage,
		"applied_hp_damage": dmg_result["applied_hp_damage"],
		"ether_damage": dmg_result.get("ether_damage", 0),
		"spell_type": element,
		"affinity": affinity,
		"el_boon_mult": el_mult,
		"hit_pct": hit_pct,
		"is_weakness": affinity > 1.0,
	}
	if not feedback_owner.is_empty():
		result["feedback_owner"] = feedback_owner
		result["defeated"] = bool(dmg_result.get("defeated",false))
	else:
		impact_presented.emit(_impact_summary(impact))
	combat_resolved.emit(result)
	return result


func resolve_heal(_caster: Unit, target: Unit, heal_amount: int) -> Dictionary:
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	var formula := CombatFormula.calculate_heal(target, heal_amount, int(bonuses.get("heal_bonus", 0)))
	var before_hp := target.hp
	target.heal(int(formula["heal"]))
	heal_amount = target.hp - before_hp
	_play_sfx("spell_cast", -4.0)
	var vfx_n := get_node_or_null("/root/VFX")
	if vfx_n:
		var vfx := vfx_n as VFXManager
		vfx.play_cure(target.grid_pos)
		vfx.play_heal_number(target.grid_pos, heal_amount)
	var result := {"healed": heal_amount}
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


## Presentation recipe from the AUTHORITATIVE applied outcome (never predicted).
func _impact_profile(source: Unit, target: Unit, hp_damage: int, critical: bool, kind: String, element: String) -> Dictionary:
	var vfx := get_node_or_null("/root/VFX") as VFXManager
	var from := vfx.gp(source.grid_pos) if vfx else Vector2(source.grid_pos)
	var to := vfx.gp(target.grid_pos) if vfx else Vector2(target.grid_pos)
	var max_hp := 1
	if target.unit_data and target.unit_data.base_stats:
		max_hp = int(target.unit_data.base_stats.hp)
	var reduced: bool = UISettings.shared().reduced_motion
	var gs := get_node_or_null("/root/GameState")
	if gs and "practice_session" in gs:
		reduced = reduced or bool(gs.practice_session.get("reduced_zane_motion", false))
	return ImpactJuice.hit_profile({
		"hp_damage": hp_damage, "max_hp": max_hp, "critical": critical,
		"defeated": target.hp <= 0, "kind": kind, "element": element,
		"from": from, "to": to, "reduced_motion": reduced,
	})


## The slice of the recipe BattleScene needs for camera shake / kick.
static func _impact_summary(impact: Dictionary) -> Dictionary:
	return {"tier": impact.tier, "shake_px": impact.shake_px, "shake_sec": impact.shake_sec, "direction": impact.direction}


func _play_sfx(sfx_id: String, volume_db: float = 0.0) -> void:
	var audio := get_node_or_null("/root/AudioSettings")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(sfx_id, volume_db)

func _receive_damage_with_feedback(target: Unit, amount: int, kind: String, owner: StringName) -> Dictionary:
	var previous := damage_feedback_owner
	damage_feedback_owner = owner
	var result := target.receive_damage(amount,kind)
	damage_feedback_owner = previous
	return result
