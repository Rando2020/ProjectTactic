class_name CombatResolver
extends Node

signal combat_resolved(result: Dictionary)

const FACING_OPPOSITE: Dictionary = {"N": "S", "S": "N", "E": "W", "W": "E"}


func resolve_attack(attacker: Unit, target: Unit,
		tile_attacker: Dictionary, tile_target: Dictionary,
		vfx_mode: String = "slash", is_counter: bool = false) -> Dictionary:
	# ── Blind miss check (35 % miss when blind) ───────────────────────────
	if attacker.has_status("blind") and randf() < 0.35:
		var vfx_node := get_node_or_null("/root/VFX")
		if vfx_node:
			(vfx_node as VFXManager).play_damage_number(
				target.grid_pos, 0, Color(0.65, 0.65, 0.65))
		var miss_result := {"damage": 0, "hp_damage": 0, "missed": true}
		combat_resolved.emit(miss_result)
		return miss_result

	var raw_damage: float = attacker.unit_data.base_stats.physical * 1.2
	var att_height: int = tile_attacker.get("height", 0)
	var tar_height: int = tile_target.get("height", 0)
	var height_bonus: float = 1.15 if att_height > tar_height \
		else (0.9 if att_height < tar_height else 1.0)
	var flank_mult: float = _get_flank_multiplier(attacker, target)
	var final_damage: int = int(round(raw_damage * height_bonus * flank_mult))

	# Colour the damage number by flank angle
	var dmg_color := Color(1.0, 0.95, 0.4)          # front — yellow
	if flank_mult >= 1.25:
		dmg_color = Color(1.0, 0.45, 0.1)           # back  — orange
	elif flank_mult > 1.0:
		dmg_color = Color(1.0, 0.78, 0.2)           # side  — warm yellow

	# ── VFX: arrow or slash → impact → damage number ─────────────────────
	if Engine.has_singleton("VFX") or is_instance_valid(get_node_or_null("/root/VFX")):
		var vfx: VFXManager = get_node("/root/VFX")
		if vfx_mode == "arrow":
			vfx.play_arrow(attacker.grid_pos, target.grid_pos, final_damage, dmg_color)
		else:
			vfx.play_attack(attacker.grid_pos, target.grid_pos, final_damage, dmg_color)

	var dmg_result := target.receive_damage(final_damage, "physical")
	if target.hp <= 0:
		# Death VFX fires after a short delay (unit fade starts simultaneously)
		var vfx_node := get_node_or_null("/root/VFX")
		if vfx_node:
			get_tree().create_timer(0.3).timeout.connect(
				func() -> void: (vfx_node as VFXManager).play_death(target.grid_pos))
	elif target.has_method("animate_hit"):
		target.animate_hit()

	var flank_str := "back" if flank_mult >= 1.25 else ("side" if flank_mult > 1.0 else "front")
	# Counter-attack: 25 % chance when hit in melee by a non-counter, non-arrow strike
	var should_counter := false
	if not is_counter and vfx_mode != "arrow" and target.hp > 0:
		var dist: int = abs(attacker.grid_pos.x - target.grid_pos.x) \
				  + abs(attacker.grid_pos.y - target.grid_pos.y)
		if dist <= target.unit_data.base_stats.attack_range_max and randf() < 0.25:
			should_counter = true
	var result := {
		"damage":        final_damage,
		"hp_damage":     dmg_result.get("hp_damage", 0),
		"temper_damage": dmg_result.get("temper_damage", 0),
		"ether_damage":  dmg_result.get("ether_damage", 0),
		"height_bonus":  height_bonus,
		"flank":         flank_str,
		"counter":       should_counter,
	}
	combat_resolved.emit(result)
	return result


func _get_flank_multiplier(attacker: Unit, target: Unit) -> float:
	var delta: Vector2i = attacker.grid_pos - target.grid_pos
	var attack_from: String
	if abs(delta.x) >= abs(delta.y):
		attack_from = "E" if delta.x > 0 else "W"
	else:
		attack_from = "S" if delta.y > 0 else "N"
	if attack_from == target.facing:
		return 1.0   # frontal — no bonus
	if attack_from == FACING_OPPOSITE.get(target.facing, ""):
		return 1.3   # back attack — +30 %
	return 1.15      # side attack — +15 %


func resolve_heal(_caster: Unit, target: Unit, heal_amount: int) -> Dictionary:
	target.heal(heal_amount)
	# ── VFX: cure sparkles + green number ────────────────────────────────
	var vfx_node := get_node_or_null("/root/VFX")
	if vfx_node:
		var vfx := vfx_node as VFXManager
		vfx.play_cure(target.grid_pos)
		vfx.play_heal_number(target.grid_pos, heal_amount)
	var result := {"healed": heal_amount}
	combat_resolved.emit(result)
	return result


## Called by BattleManager / ability system when a spell is cast.
## spell_type: "fire" | "blizzard" | "thunder" | "wind" | "holy" | "dark"
func resolve_spell(caster: Unit, target: Unit, spell_type: String,
		base_power: int) -> Dictionary:
	var raw_damage: float = caster.unit_data.base_stats.magic * (base_power / 100.0)

	# ── Elemental affinity multiplier ─────────────────────────────────────
	var affinity: float = 1.0
	if target.unit_data and not target.unit_data.elemental_affinities.is_empty():
		affinity = target.unit_data.elemental_affinities.get(spell_type, 1.0)
	var final_damage: int = int(round(raw_damage * affinity))

	# Colour damage number by affinity
	var num_color: Color
	if affinity == 0.0:
		num_color = Color(0.55, 0.55, 0.55)   # immune   — grey
	elif affinity >= 1.5:
		num_color = Color(1.0, 0.22, 0.08)    # very weak — red
	elif affinity > 1.0:
		num_color = Color(1.0, 0.58, 0.15)    # weak     — orange
	elif affinity < 1.0:
		num_color = Color(0.38, 0.62, 1.0)    # resist   — blue
	else:
		num_color = Color(0.8, 0.7, 1.0)      # neutral  — purple

	# ── VFX ──────────────────────────────────────────────────────────────
	var vfx_node := get_node_or_null("/root/VFX")
	if vfx_node:
		var vfx := vfx_node as VFXManager
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
	if target.hp <= 0 and vfx_node:
		get_tree().create_timer(0.35).timeout.connect(
			func() -> void: (vfx_node as VFXManager).play_death(target.grid_pos))
	elif target.has_method("animate_hit"):
		target.animate_hit()

	var result := {
		"damage":       final_damage,
		"hp_damage":    dmg_result.get("hp_damage", 0),
		"ether_damage": dmg_result.get("ether_damage", 0),
		"spell_type":   spell_type,
		"affinity":     affinity,
	}
	combat_resolved.emit(result)
	return result
