extends "res://prototypes/blooming/BloomingBattle.gd"
## Opt-in fixture only: add existing Haste without changing saved skill ownership.
func _spawn_player_units() -> Array[Unit]:
 var party := super._spawn_player_units()
 for unit in party:
  if unit.unit_id == "zane" and "haste" not in unit.unit_data.abilities:
   unit.unit_data.abilities.append("haste")
 return party
