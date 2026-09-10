class_name SelfPlayScenarioMatrix
extends RefCounted

## Development-only scenario definitions used to ask whether a policy's behavior
## generalizes beyond one Ashvale setup. These dictionaries are applied in-memory
## before BattleManager.start_battle() and never modify campaign/map source data.

const SCENARIO_IDS: Array[String] = [
	"ashvale-control",
	"ashvale-close-pressure",
	"crypt-elevation-crossfire",
]


static func ids() -> Array[String]:
	return SCENARIO_IDS.duplicate()


static func get_scenario(scenario_id: String) -> Dictionary:
	match scenario_id:
		"ashvale-control":
			return {
				"id": scenario_id,
				"label": "Ashvale control",
				"map_index": 0,
				"design_axis": "control",
			}
		"ashvale-close-pressure":
			return {
				"id": scenario_id,
				"label": "Ashvale close pressure",
				"map_index": 0,
				"design_axis": "starting_distance_and_composition",
				"enemy_spawns": [
					_enemy("null_drake", "Null Drake A", 5, 4, 120, 35, 3, 1, 6, 38, 30, ["dark_breath"], {"fire":0.5,"blizzard":1.5,"holy":1.5,"dark":0.5}),
					_enemy("null_drake", "Null Drake B", 6, 3, 120, 35, 3, 1, 6, 38, 30, ["dark_breath"], {"fire":0.5,"blizzard":1.5,"holy":1.5,"dark":0.5}),
					_enemy("void_cultist", "Void Cultist", 5, 2, 80, 80, 3, 1, 7, 20, 55, ["void_pulse", "dark_breath", "shadow_mend"], {"holy":2.0,"dark":0.0,"fire":0.75,"blizzard":1.25}),
				],
			}
		"crypt-elevation-crossfire":
			return {
				"id": scenario_id,
				"label": "Crypt elevation crossfire",
				"map_index": 1,
				"design_axis": "terrain_elevation_and_ranged_pressure",
				"enemy_spawns": [
					_enemy("storm_imp", "Storm Imp A", 4, 3, 90, 50, 4, 2, 8, 25, 45, ["thunderstrike", "void_pulse"], {"thunder":0.0,"blizzard":1.75,"holy":1.25,"wind":0.5}),
					_enemy("storm_imp", "Storm Imp B", 5, 4, 90, 50, 4, 2, 8, 25, 45, ["thunderstrike", "void_pulse"], {"thunder":0.0,"blizzard":1.75,"holy":1.25,"wind":0.5}),
					_enemy("void_cultist", "Void Cultist", 6, 3, 80, 80, 3, 1, 7, 20, 55, ["void_pulse", "dark_breath", "shadow_mend"], {"holy":2.0,"dark":0.0,"fire":0.75,"blizzard":1.25}),
				],
			}
		_:
			return {}


static func _enemy(
	unit_id: String,
	name: String,
	x: int,
	y: int,
	hp: int,
	mp: int,
	move: int,
	jump: int,
	speed: int,
	physical: int,
	magic: int,
	abilities: Array,
	affinities: Dictionary
) -> Dictionary:
	return {
		"unit_id": unit_id,
		"name": name,
		"x": x,
		"y": y,
		"hp": hp,
		"mp": mp,
		"move": move,
		"jump": jump,
		"speed": speed,
		"physical": physical,
		"magic": magic,
		"max_temper": 80,
		"max_ether": 90,
		"abilities": abilities,
		"affinities": affinities,
	}
