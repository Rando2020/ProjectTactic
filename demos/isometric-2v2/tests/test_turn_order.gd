extends Node

var checks := 0
var failures := 0

func _ready() -> void:
	for fixture in [
		[[7, 0], [9, 0], [5, 0], [12, 0], [8, 0], [6, 0], [10, 0]],
		[[10, 100], [8, 115], [10, 100], [20, 0]],
		[[0, 0], [0, 105]],
		[[0, 0], [0, 0]],
		[[200, 0], [6, 0], [8, 0]],
	]:
		var scheduler := TurnOrder.new()
		for i in range(fixture.size()):
			var unit := Unit.new()
			unit.unit_id = "u%d" % i
			unit.unit_data = UnitData.new()
			unit.unit_data.base_stats = UnitStats.new()
			unit.unit_data.base_stats.speed = fixture[i][0]
			unit.hp = 100
			unit.ct = fixture[i][1]
			scheduler.units.append(unit)
		_verify_projection(scheduler, "fixture %s" % str(fixture))
		for unit in scheduler.units:
			unit.free()
		scheduler.free()
	var scheduler := TurnOrder.new()
	for i in range(3):
		var unit := Unit.new()
		unit.unit_id = str(i)
		unit.unit_data = UnitData.new()
		unit.unit_data.base_stats = UnitStats.new()
		unit.unit_data.base_stats.speed = 8
		unit.hp = 100 if i < 2 else 0
		var status := StatusEffect.new()
		status.status_id = "haste" if i == 0 else "slow"
		unit.statuses.append(status)
		scheduler.units.append(unit)
	_verify_projection(scheduler, "haste slow dead")
	for unit in scheduler.units:
		unit.free()
	scheduler.free()
	print("Turn order: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL " + message)

func _verify_projection(scheduler: TurnOrder, label: String) -> void:
	var before: Array = scheduler.units.map(func(u): return u.ct)
	var forecast := scheduler.get_projected_order(30)
	check(before == scheduler.units.map(func(u): return u.ct), label + " forecast is pure")
	for entry in forecast:
		var actual := scheduler.tick_until_ready()
		check(actual != null and actual.unit_id == entry.unit_id, label + " next activation agrees: " + entry.unit_id)
	if forecast.is_empty():
		check(scheduler.tick_until_ready() == null, label + " no activation possible")
	# An already-ready unit must not give free CT to others.
	if label.begins_with("fixture") and before == [100, 115, 100, 0]:
		# Separate assertion on the initial fixture, restored after long comparison.
		for i in range(scheduler.units.size()):
			scheduler.units[i].ct = before[i]
		check(scheduler.tick_until_ready() == scheduler.units[0], "ready ties preserve input order")
		check(scheduler.units[3].ct == 0, "ready backlog is consumed before advancing time")
