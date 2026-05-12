## CombatResolver.gd
## Resolves combat actions: damage, healing, status effects.
## Does NOT move units or change turn order — only resolves one action at a time.
## Returns a CombatResult dictionary for BattleManager to apply.
##
## AI AGENT: Implement TODO sections. See SYSTEMS.md section 3 for formulas.

class_name CombatResolver
extends Node

signal combat_resolved(result: Dictionary)

var elemental_system: ElementalSystem


func _ready() -> void:
	elemental_system = get_node("../ElementalSystem")


## Resolve a basic attack from attacker onto target
## Returns result dict: { damage, hp_damage, temper_damage, ether_damage,
##                        hit, critical, status_applied, height_bonus }
func resolve_attack(attacker: Unit, target: Unit, tile_attacker: RefCounted, tile_target: RefCounted) -> Dictionary:
    var result := {}
    # Step 1: calculate base physical damage for a basic attack
    var raw_damage: float = attacker.unit_data.base_stats.physical * 1.2
    # Step 2: determine height bonus: attacker attacking downhill gets +15%,
    # uphill gets -10%, otherwise 0. Tiles may be null if not provided.
    var att_height: int = tile_attacker.get("height", 0) if tile_attacker else 0
    var tar_height: int = tile_target.get("height", 0) if tile_target else 0
    var height_bonus: float = 1.0
    if att_height > tar_height:
        height_bonus = 1.15
    elif att_height < tar_height:
        height_bonus = 0.9
    var final_damage: int = int(round(raw_damage * height_bonus))
    # Step 3 & 4: apply Temper absorption via the unit's receive_damage
    var dmg_result := target.receive_damage(final_damage, "physical")
    result["damage"] = final_damage
    result["hp_damage"] = dmg_result.get("hp_damage", 0)
    result["temper_damage"] = dmg_result.get("temper_damage", 0)
    result["ether_damage"] = dmg_result.get("ether_damage", 0)
    result["height_bonus"] = height_bonus
    # Step 5: trigger surface reaction on the target tile (if defined)
    # We assume elemental attacks apply an element; since this is a basic
    # physical attack, no element is applied.
    combat_resolved.emit(result)
    return result


## Resolve a healing ability
func resolve_heal(caster: Unit, target: Unit, heal_amount: int) -> Dictionary:
    var result := { "healed": heal_amount }
    target.heal(heal_amount)
    combat_resolved.emit(result)
    return result


## Apply a resolved combat result to the target unit
func apply_result(target: Unit, result: Dictionary) -> void:
    # For now we rely on resolve_attack/resolve_heal to have already called
    # receive_damage or heal. This function could apply status effects or
    # elemental reactions based on the result. Placeholder implementation.
    pass


## ─────────────────────────────────────────────────────────────────────────────


## ElementalSystem.gd
## Tracks surface states on tiles and resolves elemental reactions.
## See SYSTEMS.md section 4 for the full reaction table.
##
## AI AGENT: Implement TODO sections.

class_name ElementalSystem
extends Node

signal reaction_triggered(reaction_id: String, tile_pos: Vector2i, affected_unit_ids: Array)

## tile_pos -> surface_state String
var surface_states: Dictionary = {}

const REACTIONS := {
	# { from_state: { element: [reaction_id, new_state] } }
	"": {
		"water": ["apply_wet", "wet"],
		"ice": ["apply_wet", "wet"],
		"fire": ["apply_burning", "burning"],
	},
	"wet": {
		"ice": ["freeze", "frozen"],
		"thunder": ["electrify_chain", "electrified"],
		"earth": ["muddy", "mud"],
	},
	"frozen": {
		"thunder": ["shatter", ""],
		"fire": ["melt", "wet"],
	},
	"burning": {
		"water": ["extinguish", "wet"],
		"ice": ["extinguish", "wet"],
	},
	"cursed": {
		"holy": ["holy_purge", ""],
	},
	"blessed": {
		"dark": ["null_corrupt", ""],
	},
}


## Apply an element to a tile, check for reaction, update surface state
## Returns the reaction_id if a reaction occurred, else ""
func apply_element(tile_pos: Vector2i, element: String, units_on_tile: Array) -> String:
	var current_state: String = surface_states.get(tile_pos, "")
	var reaction_table: Dictionary = REACTIONS.get(current_state, {})

	if reaction_table.has(element):
		var reaction_data: Array = reaction_table[element]
		var reaction_id: String = reaction_data[0]
		var new_state: String = reaction_data[1]
		surface_states[tile_pos] = new_state
		reaction_triggered.emit(reaction_id, tile_pos, units_on_tile)
		# TODO: Handle chain reactions (electrify spreads to adjacent wet tiles)
		return reaction_id
	else:
		# No reaction, just update state if applicable
		var fallthrough: Dictionary = REACTIONS.get("", {})
		if fallthrough.has(element):
			surface_states[tile_pos] = fallthrough[element][1]
	return ""


func get_surface_state(tile_pos: Vector2i) -> String:
	return surface_states.get(tile_pos, "")


func clear_surface(tile_pos: Vector2i) -> void:
	surface_states.erase(tile_pos)
