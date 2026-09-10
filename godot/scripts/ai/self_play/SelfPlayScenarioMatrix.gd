class_name SelfPlayScenarioMatrix
extends RefCounted

## Development-only scenario descriptors used to ask whether a policy's behavior
## generalizes beyond one Ashvale setup. Every scenario selects an existing real
## BattleScene path: one of the shipped debug maps or MapGenerator through RunState.
## No campaign/map source data is mutated.

const SCENARIO_IDS: Array[String] = [
	"ashvale-control",
	"crypt-control",
	"generated-floor-4",
]


static func ids() -> Array[String]:
	return SCENARIO_IDS.duplicate()


static func get_scenario(scenario_id: String) -> Dictionary:
	match scenario_id:
		"ashvale-control":
			return {
				"id": scenario_id,
				"label": "Ashvale control",
				"source": "debug_map",
				"map_index": 0,
				"design_axes": ["control"],
			}
		"crypt-control":
			return {
				"id": scenario_id,
				"label": "Crypt terrain control",
				"source": "debug_map",
				"map_index": 1,
				"design_axes": ["terrain", "elevation", "hazards", "starting_distance"],
			}
		"generated-floor-4":
			return {
				"id": scenario_id,
				"label": "Generated floor 4",
				"source": "generated_run_floor",
				"run_seed": 4242,
				"floor": 4,
				"heat": 0,
				"design_axes": ["terrain", "starting_distance", "enemy_composition", "procedural_variation"],
			}
		_:
			return {}
