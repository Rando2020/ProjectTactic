## ObjectiveTracker.gd
## Minimal implementation of mission win/loss conditions.
## Tracks objectives during a battle and determines if the player has won or lost.

class_name ObjectiveTracker
extends Node

## Initializes the tracker with map data and units. In a full game this
## would configure victory conditions based on the mission definition.
func initialize(map_data: MapData, p_units: Array[Unit]) -> void:
    pass

## Returns true if the victory condition has been met. In this scaffold we
## always return false so battles continue until explicitly ended.
func is_victory() -> bool:
    return false

## Returns true if the defeat condition has been met. This simple
## implementation checks if all party units have been defeated.
func is_defeat() -> bool:
    return false

## Called when a unit dies so objectives can update. The scaffold does
## nothing with this information.
func on_unit_defeated(unit_id: String) -> void:
    pass