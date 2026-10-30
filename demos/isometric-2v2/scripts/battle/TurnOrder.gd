class_name TurnOrder
extends Node

signal timeline_updated(ordered_units: Array)

var units: Array[Unit] = []


func initialize(p_units: Array[Unit]) -> void:
	for unit in units:
		_disconnect_status_updates(unit)
	units = p_units.filter(func(u): return u.hp > 0)
	for u in units:
		u.ct = 0
		u.status_applied.connect(_on_status_changed)
		u.status_removed.connect(_on_status_changed)


func tick_until_ready() -> Unit:
	var state := _snapshot()
	var index := _advance_to_ready(state)
	if index < 0:
		return null
	for entry in state:
		entry.unit.ct = entry.ct
	var chosen: Unit = state[index].unit
	timeline_updated.emit(get_projected_order())
	return chosen


func get_projected_order(count: int = 6) -> Array[Dictionary]:
	var projection: Array[Dictionary] = []
	var state := _snapshot()
	for i in range(maxi(count, 0)):
		var index := _advance_to_ready(state)
		if index < 0:
			break
		var unit: Unit = state[index].unit
		projection.append({
			"unit_id": unit.unit_id,
			"display_name": unit.display_name,
			"team": unit.team,
		})
	return projection


func _snapshot() -> Array[Dictionary]:
	var state: Array[Dictionary] = []
	for unit in units:
		if is_instance_valid(unit) and unit.hp > 0:
			state.append({"unit": unit, "ct": unit.ct, "speed": maxi(0, unit.get_effective_speed())})
	return state


## Mutates only snapshot CT. Both the live scheduler and forecast use integer ticks,
## consume already-ready units first, and break equal-speed ties by roster order.
static func _advance_to_ready(state: Array[Dictionary]) -> int:
	for tick in range(501):
		var chosen := -1
		var fastest := -1
		for i in range(state.size()):
			if int(state[i].ct) >= 100 and int(state[i].speed) > fastest:
				chosen = i
				fastest = int(state[i].speed)
		if chosen >= 0:
			state[chosen].ct -= 100
			return chosen
		if tick == 500:
			break
		var can_advance := false
		for entry in state:
			entry.ct += int(entry.speed)
			can_advance = can_advance or int(entry.speed) > 0
		if not can_advance:
			break
	return -1


func remove_unit(unit_id: String) -> void:
	for unit in units:
		if unit.unit_id == unit_id:
			_disconnect_status_updates(unit)
	units = units.filter(func(u): return u.unit_id != unit_id)
	timeline_updated.emit(get_projected_order())


func _on_status_changed(_unit_id: String, status_id: String) -> void:
	if status_id in ["haste", "slow"]:
		timeline_updated.emit(get_projected_order())


func _disconnect_status_updates(unit: Unit) -> void:
	if not is_instance_valid(unit):
		return
	if unit.status_applied.is_connected(_on_status_changed):
		unit.status_applied.disconnect(_on_status_changed)
	if unit.status_removed.is_connected(_on_status_changed):
		unit.status_removed.disconnect(_on_status_changed)
