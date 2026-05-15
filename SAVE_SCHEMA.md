class_name ObjectiveTracker
extends Node

var map_data: MapData
var units: Array[Unit] = []


func initialize(p_map_data: MapData, p_units: Array[Unit]) -> void:
	map_data = p_map_data
	units = p_units


func is_victory() -> bool:
	return units.all(func(u): return u.team != "enemy" or u.hp <= 0)


func is_defeat() -> bool:
	return units.all(func(u): return u.team != "player" or u.hp <= 0)


func on_unit_defeated(_unit_id: String) -> void:
	pass
