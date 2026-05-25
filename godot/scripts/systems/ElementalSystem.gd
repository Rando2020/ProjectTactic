## ElementalSystem.gd  Reactions + chain electrify + burning spread.
class_name ElementalSystem
extends Node

signal reaction_triggered(reaction_id: String, tile_pos: Vector2i, affected_unit_ids: Array)
signal chain_reaction(reaction_id: String, positions: Array)

var surface_states: Dictionary = {}

const REACTIONS: Dictionary = {
	"": {
		"water": ["apply_wet",     "wet"],
		"ice":   ["apply_wet",     "wet"],
		"fire":  ["apply_burning", "burning"],
	},
	"wet": {
		"ice":     ["freeze",           "frozen"],
		"thunder": ["electrify_chain",  "electrified"],
		"fire":    ["steam_cloud",      ""],
		"earth":   ["muddy",            "mud"],
	},
	"frozen": {
		"thunder": ["shatter",  ""],
		"fire":    ["melt",     "wet"],
		"earth":   ["shatter",  ""],
	},
	"burning": {
		"water": ["extinguish", "wet"],
		"ice":   ["cryo_douse", "frozen"],
	},
	"electrified": {
		"water": ["electrify_chain", "electrified"],
	},
	"cursed":  {"holy":  ["holy_purge",   ""]},
	"blessed": {"dark":  ["null_corrupt", ""]},
	"mud":     {"thunder": ["electrify_chain", "electrified"]},
}

## Reaction damage values
const REACTION_DAMAGE: Dictionary = {
	"shatter":         52,
	"electrify_chain": 32,
	"holy_purge":      38,
	"null_corrupt":    28,
}

const MAX_CHAIN_TILES := 6  # max tiles electrify can jump to


func apply_element(tile_pos: Vector2i, element: String, units_on_tile: Array) -> String:
	var current: String = surface_states.get(tile_pos, "")
	var table:   Dictionary = REACTIONS.get(current, {})

	if table.has(element):
		var rd: Array = table[element]
		var reaction_id: String = rd[0]
		var new_state:   String = rd[1]

		surface_states[tile_pos] = new_state

		# Handle chain electrify  spreads to all connected wet/electrified tiles
		if reaction_id == "electrify_chain":
			var chain_positions := _find_chain_tiles(tile_pos)
			for pos in chain_positions:
				surface_states[pos] = "electrified"
			chain_reaction.emit(reaction_id, chain_positions)
			reaction_triggered.emit(reaction_id, tile_pos, units_on_tile)
			return reaction_id

		# Handle burning spread (30% chance to adjacent flammable tiles)
		if reaction_id == "apply_burning":
			_spread_burning(tile_pos)

		reaction_triggered.emit(reaction_id, tile_pos, units_on_tile)
		return reaction_id

	# Fallthrough: apply base element state
	var fallthrough: Dictionary = REACTIONS.get("", {})
	if fallthrough.has(element):
		surface_states[tile_pos] = fallthrough[element][1]

	return ""


func get_surface_state(tile_pos: Vector2i) -> String:
	return surface_states.get(tile_pos, "")


func clear_surface(tile_pos: Vector2i) -> void:
	surface_states.erase(tile_pos)


func get_reaction_damage(reaction_id: String) -> int:
	return REACTION_DAMAGE.get(reaction_id, 0)


## BFS to find all connected wet/electrified tiles for chain reaction
func _find_chain_tiles(origin: Vector2i) -> Array[Vector2i]:
	var visited: Dictionary = {origin: true}
	var queue: Array[Vector2i] = [origin]
	var result: Array[Vector2i] = [origin]
	var dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

	while not queue.is_empty() and result.size() < MAX_CHAIN_TILES:
		var cur: Vector2i = queue.pop_front()
		for d in dirs:
			var nb: Vector2i = cur + d
			if visited.has(nb): continue
			visited[nb] = true
			var state: String = surface_states.get(nb, "")
			if state in ["wet", "electrified", "mud"]:
				result.append(nb)
				queue.append(nb)
	return result


## Burning spreads to 1-2 adjacent tiles with 35% chance each
func _spread_burning(origin: Vector2i) -> void:
	var dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	dirs.shuffle()
	var spread_count := 0
	for d in dirs:
		if spread_count >= 2: break
		if randf() > 0.35: continue
		var nb: Vector2i = origin + d
		var state: String = surface_states.get(nb, "")
		# Only spread to natural terrain (not water, stone floors, etc.)
		if state in ["", "wet"]: continue
		surface_states[nb] = "burning"
		reaction_triggered.emit("apply_burning", nb, [])
		spread_count += 1
