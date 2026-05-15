class_name ElementalSystem
extends Node

signal reaction_triggered(reaction_id: String, tile_pos: Vector2i, affected_unit_ids: Array)

var surface_states: Dictionary = {}

const REACTIONS := {
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
	"cursed": {"holy": ["holy_purge", ""]},
	"blessed": {"dark": ["null_corrupt", ""]},
}


func apply_element(tile_pos: Vector2i, element: String, units_on_tile: Array) -> String:
	var current_state: String = surface_states.get(tile_pos, "")
	var reaction_table: Dictionary = REACTIONS.get(current_state, {})
	if reaction_table.has(element):
		var reaction_data: Array = reaction_table[element]
		surface_states[tile_pos] = reaction_data[1]
		reaction_triggered.emit(reaction_data[0], tile_pos, units_on_tile)
		return reaction_data[0]
	var fallthrough: Dictionary = REACTIONS.get("", {})
	if fallthrough.has(element):
		surface_states[tile_pos] = fallthrough[element][1]
	return ""


func get_surface_state(tile_pos: Vector2i) -> String:
	return surface_states.get(tile_pos, "")


func clear_surface(tile_pos: Vector2i) -> void:
	surface_states.erase(tile_pos)
