extends "res://prototypes/isometric/Battle.gd"
## Same painted floor and combat engine; two existing allies vs two existing foes.

func _spawn_player_units() -> Array[Unit]:
	_map_data.display_name = "The Painted Chapel · 2 vs 2"
	_map_data.objective_label = "Defeat both enemies"
	var party := super._spawn_player_units()
	party.append(_make_unit("kael", "Kael", "player", Vector2i(1,4),
		380,55,4,2,6,55,32,110,70,GameState.get_all_abilities("kael")))
	return party

func _spawn_enemy_units() -> Array[Unit]:
	var foes := super._spawn_enemy_units()
	# Reuse the production Void Cultist definition, not a new class/AI.
	foes.append(_make_unit("void_cultist", "Void Cultist", "enemy", Vector2i(3,1),
		80,80,3,1,7,20,55,40,100,["void_pulse","dark_breath","shadow_mend"],
		{"holy":2.0,"dark":0.0,"fire":0.75,"blizzard":1.25}))
	return foes
