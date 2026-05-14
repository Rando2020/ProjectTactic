extends RefCounted
class_name PTBattleMath


const READY_CT := 100


static func charge_gain(speed: int) -> int:
	return max(4, int(round(float(speed) * 0.75)))


static func damage(caster: Dictionary, target: Dictionary, ability: Dictionary, caster_tile: Dictionary, target_tile: Dictionary) -> int:
	var power: int = int(ability.get("power", 0))
	var attack: int = int(caster.get("attack", caster.get("level", 5) + 12))
	var defense: int = int(target.get("defense", target.get("level", 5) + 8))
	var raw := power + attack - int(round(float(defense) * 0.45))
	var height_bonus := height_damage_bonus(int(caster_tile.get("height", 0)), int(target_tile.get("height", 0)))
	var guard_multiplier := 0.70 if has_status(target, "guarded") else 1.0
	return max(1, int(round(float(raw) * height_bonus * guard_multiplier)))


static func healing(caster: Dictionary, ability: Dictionary, caster_tile: Dictionary, target_tile: Dictionary) -> int:
	var power: int = int(ability.get("power", 0))
	var spirit: int = int(caster.get("spirit", caster.get("level", 5) + 10))
	var height_bonus := 1.0
	if int(caster_tile.get("height", 0)) >= int(target_tile.get("height", 0)):
		height_bonus = 1.08
	return max(1, int(round(float(power + spirit) * height_bonus)))


static func height_damage_bonus(attacker_height: int, defender_height: int) -> float:
	return clamp(1.0 + float(attacker_height - defender_height) * 0.08, 0.84, 1.24)


static func has_status(unit: Dictionary, status_id: String) -> bool:
	for status in unit.get("statuses", []):
		if String(status.get("id", "")) == status_id:
			return true
	return false


static func is_hostile_category(category: String) -> bool:
	return ["Melee", "Ranged", "Magic", "Control", "Debuff"].has(category)


static func is_ally_category(category: String) -> bool:
	return ["Heal", "Support", "Guard", "Mobility"].has(category)
