class_name CombatResolver
extends Node

signal combat_resolved(result: Dictionary)


func resolve_attack(attacker: Unit, target: Unit, tile_attacker, tile_target) -> Dictionary:
	var raw_damage: float = attacker.unit_data.base_stats.physical * 1.2
	var att_height: int = tile_attacker.get("height", 0) if tile_attacker else 0
	var tar_height: int = tile_target.get("height", 0) if tile_target else 0
	var height_bonus: float = 1.15 if att_height > tar_height else (0.9 if att_height < tar_height else 1.0)
	var final_damage: int = int(round(raw_damage * height_bonus))
	var dmg_result := target.receive_damage(final_damage, "physical")
	var result := {
		"damage": final_damage,
		"hp_damage": dmg_result.get("hp_damage", 0),
		"temper_damage": dmg_result.get("temper_damage", 0),
		"ether_damage": dmg_result.get("ether_damage", 0),
		"height_bonus": height_bonus,
	}
	combat_resolved.emit(result)
	return result


func resolve_heal(caster: Unit, target: Unit, heal_amount: int) -> Dictionary:
	target.heal(heal_amount)
	var result := {"healed": heal_amount}
	combat_resolved.emit(result)
	return result
