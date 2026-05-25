extends SceneTree

const CombatFormula := preload("res://scripts/battle/CombatFormula.gd")

var _pass := 0
var _fail := 0

func _init() -> void:
	_run_tests()
	print("Combat formula tests: %d pass, %d fail" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _run_tests() -> void:
	var attacker := _unit("attacker", 50, 50, 0, 0, 80, 80, Vector2i(2, 2), "S")
	var target := _unit("target", 20, 30, 10, 6, 80, 80, Vector2i(2, 3), "N")
	var even := {"height": 0}
	var high := {"height": 2}
	var low := {"height": 0}
	var front := CombatFormula.calculate_physical_attack(attacker, target, even, even)
	_eq(int(front.get("incoming_damage", 0)), 50, "physical subtracts resistance before multipliers")
	_eq(int(front.get("hp_damage", 0)), 46, "temper projects expected hp damage")
	_eq(int(front.get("hit_pct", 0)), 88, "front hit uses base accuracy")
	target.facing = "S"
	var back := CombatFormula.calculate_physical_attack(attacker, target, high, low)
	_true(float(back.get("flank_mult", 1.0)) > 1.25, "back attack multiplier applies")
	_true(float(back.get("height_mult", 1.0)) > 1.0, "high ground multiplier applies")
	_true(int(back.get("crit_pct", 0)) > int(front.get("crit_pct", 0)), "back/high ground improves crit")
	target.unit_data.elemental_affinities = {"fire": 1.5, "dark": 0.5, "thunder": 0.0}
	var fire := CombatFormula.calculate_magical_attack(attacker, target, "fire", 100)
	_eq(int(fire.get("incoming_damage", 0)), 66, "magic uses magic resistance then affinity")
	_eq(str(fire.get("affinity_label", "")), "Weak", "weakness label")
	var dark := CombatFormula.calculate_magical_attack(attacker, target, "dark", 100)
	_true(int(dark.get("incoming_damage", 0)) < int(fire.get("incoming_damage", 0)), "resisted element lowers damage")
	var thunder := CombatFormula.calculate_magical_attack(attacker, target, "thunder", 100)
	_eq(int(thunder.get("incoming_damage", -1)), 0, "immune element deals zero incoming damage")
	attacker.free()
	target.free()

func _unit(id: String, physical: int, magic: int, pres: int, mres: int, temper_value: int, ether_value: int, pos: Vector2i, facing_value: String) -> Unit:
	var stats := UnitStats.new()
	stats.hp = 300
	stats.mp = 60
	stats.physical = physical
	stats.magic = magic
	stats.physical_resistance = pres
	stats.magic_resistance = mres
	stats.max_temper = temper_value
	stats.max_ether = ether_value
	var data := UnitData.new()
	data.id = id
	data.display_name = id.capitalize()
	data.base_stats = stats
	var unit := Unit.new()
	unit.unit_data = data
	unit.unit_id = id
	unit.display_name = data.display_name
	unit.grid_pos = pos
	unit.facing = facing_value
	unit.hp = stats.hp
	unit.mp = stats.mp
	unit.temper = temper_value
	unit.ether = ether_value
	return unit

func _eq(got, exp, label: String) -> void:
	if got == exp:
		print("PASS %s" % label)
		_pass += 1
	else:
		print("FAIL %s (got=%s exp=%s)" % [label, str(got), str(exp)])
		_fail += 1

func _true(value: bool, label: String) -> void:
	if value:
		print("PASS %s" % label)
		_pass += 1
	else:
		print("FAIL %s" % label)
		_fail += 1
