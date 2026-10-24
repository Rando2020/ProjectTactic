extends Node

const CombatFormula := preload("res://scripts/battle/CombatFormula.gd")

var _pass := 0
var _fail := 0

func _ready() -> void:
	_run_tests()
	print("Combat formula tests: %d pass, %d fail" % [_pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)

func _run_tests() -> void:
	var attacker := _unit("attacker", 50, 50, 0, 0, 80, 80, Vector2i(2, 2), "S")
	var target := _unit("target", 20, 30, 10, 6, 80, 80, Vector2i(2, 3), "N")
	var even := {"height": 0}
	var high := {"height": 2}
	var low := {"height": 0}
	var front := CombatFormula.calculate_physical_attack(attacker, target, even, even)
	_eq(int(front.get("incoming_damage", 0)), 50, "physical subtracts resistance before multipliers")
	_eq(int(front.get("hp_damage", 0)), 45, "temper projects expected hp damage")
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
	_damage_contract_tests(attacker, target)
	attacker.free()
	target.free()

func _damage_contract_tests(attacker: Unit, target: Unit) -> void:
	for kind in ["physical", "magical"]:
		for status_ids in [[], ["protect"], ["defending"], ["protect", "defending"]]:
			for incoming in [0, 1, 66]:
				for armor_value in [0, 65]:
					target.statuses.clear()
					for sid in status_ids:
						var status := StatusEffect.new()
						status.status_id = sid
						target.statuses.append(status)
					target.hp = 300
					target.temper = armor_value
					target.ether = armor_value
					var forecast: Dictionary = CombatFormula.project_physical_armor_result(target, incoming) if kind == "physical" else CombatFormula.project_magical_armor_result(target, incoming)
					var actual := target.receive_damage(incoming, kind)
					var label := "%s %s incoming=%d armor=%d" % [kind, str(status_ids), incoming, armor_value]
					_eq(actual.hp_damage, forecast.hp_damage, "application HP matches projection " + label)
					_eq(300 - target.hp, forecast.hp_damage, "actual HP loss matches projection " + label)
					_eq(actual.get("temper_damage", 0), forecast.get("temper_damage", 0), "temper matches projection " + label)
					_eq(actual.get("ether_damage", 0), forecast.get("ether_damage", 0), "ether matches projection " + label)
	target.statuses.clear()
	target.temper = 65
	target.ether = 65
	var protect := StatusEffect.new()
	protect.status_id = "protect"
	target.statuses.append(protect)
	_eq(CombatFormula.project_magical_armor_result(target, 66).hp_damage, 60, "Protect only reduces physical damage")
	target.statuses.clear()
	protect.status_id = "defending"
	target.statuses.append(protect)
	_eq(CombatFormula.project_magical_armor_result(target, 66).hp_damage, 30, "Defend reduces magical direct damage")
	target.statuses.clear()
	attacker.unit_data.base_stats.physical = 10
	target.unit_data.base_stats.physical_resistance = 0
	target.facing = "N"
	var physical := CombatFormula.calculate_physical_attack(attacker, target, {}, {})
	var crit_incoming := int(round(float(physical.incoming_damage) * physical.crit_mult))
	_eq(physical.crit_damage, CombatFormula.project_physical_armor_result(target, crit_incoming).hp_damage, "critical forecast projects critical incoming through armor")
	for facing_value in ["N", "S", "E", "W"]:
		target.facing = facing_value
		_eq(CombatFormula.calculate_magical_attack(attacker, target, "fire", 100).crit_pct, 0, "spells never gain unimplemented positional crit " + facing_value)

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
