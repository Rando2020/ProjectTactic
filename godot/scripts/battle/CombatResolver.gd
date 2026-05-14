class_name CombatResolver
extends Node

signal combat_resolved(result: Dictionary)


func resolve_attack(attacker: Unit, target: Unit,
		tile_attacker: Dictionary, tile_target: Dictionary) -> Dictionary:
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
	var final_damage: int = int(round(raw_damage * height_bonus))

	# ── VFX: slash → impact → damage number ──────────────────────────────
	if Engine.has_singleton("VFX") or is_instance_valid(get_node_or_null("/root/VFX")):
		var vfx: VFXManager = get_node("/root/VFX")
		vfx.play_attack(attacker.grid_pos, target.grid_pos, final_damage)

	var dmg_result := target.receive_damage(final_damage, "physical")
	if target.hp <= 0:
		# Death VFX fires after a short delay (unit fade starts simultaneously)
		var vfx_node := get_node_or_null("/root/VFX")
		if vfx_node:
			get_tree().create_timer(0.3).timeout.connect(
				func() -> void: (vfx_node as VFXManager).play_death(target.grid_pos))
	elif target.has_method("animate_hit"):
		target.animate_hit()

	var result := {
		"damage":        final_damage,
		"hp_damage":     dmg_result.get("hp_damage", 0),
		"temper_damage": dmg_result.get("temper_damage", 0),
		"ether_damage":  dmg_result.get("ether_damage", 0),
		"height_bonus":  height_bonus,
	}
	combat_resolved.emit(result)
	return result


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
	var final_damage: int = int(round(raw_damage))

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
		vfx.play_damage_number(target.grid_pos, final_damage, Color(0.8, 0.7, 1.0))

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
	}
	combat_resolved.emit(result)
	return result
