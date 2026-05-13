class_name TurnOrder
extends Node

signal timeline_updated(ordered_units: Array)

var units: Array[Unit] = []


func initialize(p_units: Array[Unit]) -> void:
	units = p_units.filter(func(u): return u.hp > 0)
	for u in units:
		u.ct = 0


func tick_until_ready() -> Unit:
	var max_iterations := 500
	var iterations := 0
	while iterations < max_iterations:
		iterations += 1
		var ready_units: Array[Unit] = []
		for u in units:
			if u.hp <= 0:
				continue
			u.ct += u.get_effective_speed()
			if u.ct >= 100:
				ready_units.append(u)
		if ready_units.size() > 0:
			ready_units.sort_custom(func(a, b): return a.get_effective_speed() > b.get_effective_speed())
			var chosen: Unit = ready_units[0]
			chosen.ct -= 100
			timeline_updated.emit(get_projected_order())
			return chosen
		timeline_updated.emit(get_projected_order())
	return null


func get_projected_order(count: int = 6) -> Array[Dictionary]:
	var projection: Array[Dictionary] = []
	var ct_clone: Dictionary = {}
	for u in units:
		if u.hp > 0:
			ct_clone[u.unit_id] = float(u.ct)
	for i in range(count):
		var best_unit: Unit = null
		var ticks_to_ready: float = INF
		for u in units:
			if u.hp <= 0:
				continue
			var speed: float = float(u.get_effective_speed())
			if speed <= 0.0:
				continue
			var ticks: float = (100.0 - ct_clone.get(u.unit_id, 0.0)) / speed
			if ticks < ticks_to_ready:
				ticks_to_ready = ticks
				best_unit = u
		if not best_unit:
			break
		projection.append({
			"unit_id": best_unit.unit_id,
			"display_name": best_unit.display_name,
			"team": best_unit.team,
		})
		for u in units:
			if u.hp > 0 and ct_clone.has(u.unit_id):
				ct_clone[u.unit_id] += float(u.get_effective_speed()) * ticks_to_ready
		ct_clone[best_unit.unit_id] -= 100.0
	return projection


func remove_unit(unit_id: String) -> void:
	units = units.filter(func(u): return u.unit_id != unit_id)
	timeline_updated.emit(get_projected_order())
