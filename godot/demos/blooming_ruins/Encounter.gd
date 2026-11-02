extends RefCounted
## Self-contained demo state; shares production damage/heal and CT rules.
const WIDTH := 12
const DEPTH := 11
const GATE := Vector2i(9, 0)
var tiles: Dictionary = {}
var units: Array[Unit] = []
var order := TurnOrder.new()
var active: Unit
var moved := false
var acted := false
var result := ""
var rng := RandomNumberGenerator.new()

func _init(seed_value: int = 1789) -> void:
	rng.seed = seed_value
	for z in DEPTH:
		for x in WIDTH:
			var height := 3 if z <= 2 else 0
			if x in [2, 9] and z in [3, 4]: height = 5 - z
			var blocked := (z == 6 and x in [3, 4, 7, 8]) or (z == 1 and x in [4, 5])
			tiles[Vector2i(x, z)] = {"height": height, "blocked": blocked}
	add_unit("Zane", "player", Vector2i(2, 9), 130, 44, 26, 12, 1, 0)
	add_unit("Mira", "player", Vector2i(1, 8), 105, 24, 48, 10, 3, 1)
	add_unit("Lyra", "player", Vector2i(4, 9), 110, 35, 25, 11, 4, 2)
	add_unit("Sentinel", "enemy", Vector2i(5, 5), 85, 29, 20, 8, 1, 3)
	add_unit("Warden", "enemy", Vector2i(10, 5), 90, 32, 20, 8, 1, 3)
	add_unit("Gatekeeper", "enemy", Vector2i(9, 1), 120, 38, 20, 7, 1, 3)
	order.initialize(units)
	next_turn()

func add_unit(title: String, team: String, cell: Vector2i, hp: int, physical: int, magic: int, speed: int, reach: int, sprite: int) -> void:
	var unit := Unit.new()
	unit.unit_data = UnitData.new()
	unit.unit_data.base_stats = UnitStats.new()
	var stats := unit.unit_data.base_stats
	stats.hp = hp
	stats.mp = 40
	stats.physical = physical
	stats.magic = magic
	stats.speed = speed
	stats.physical_resistance = 6
	stats.magic_resistance = 4
	stats.attack_range_max = reach
	unit.unit_id = title.to_lower()
	unit.display_name = title
	unit.team = team
	unit.hp = hp
	unit.mp = 40
	unit.temper = 20
	unit.ether = 15
	unit.grid_pos = cell
	unit.facing = "N" if team == "player" else "S"
	unit.set_meta("sprite", sprite)
	units.append(unit)

func dispose() -> void:
	order.free()
	for unit in units: unit.free()

func occupant(cell: Vector2i) -> Unit:
	for unit in units:
		if unit.hp > 0 and unit.grid_pos == cell: return unit
	return null

func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var next: Vector2i = cell + step
		if not tiles.has(next) or tiles[next].blocked: continue
		var difference := absi(int(tiles[cell].height) - int(tiles[next].height))
		if difference > 1: continue
		if difference > 0 and (cell.x != next.x or cell.x not in [2, 9]): continue
		found.append(next)
	return found

func reachable(unit: Unit, budget: int = 4) -> Dictionary:
	var paths := {unit.grid_pos: []}
	var queue: Array[Vector2i] = [unit.grid_pos]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if paths[cell].size() >= budget: continue
		for next in neighbors(cell):
			if paths.has(next) or occupant(next) != null: continue
			var path: Array = paths[cell].duplicate()
			path.append(next)
			paths[next] = path
			queue.append(next)
	return paths

func can_attack(actor: Unit, target: Unit) -> bool:
	if not actor or not target or actor.hp <= 0 or target.hp <= 0 or actor.team == target.team: return false
	var delta := target.grid_pos - actor.grid_pos
	var distance := absi(delta.x) + absi(delta.y)
	if distance > actor.unit_data.base_stats.attack_range_max: return false
	if actor.unit_data.base_stats.attack_range_max == 1 and absi(int(tiles[actor.grid_pos].height) - int(tiles[target.grid_pos].height)) > 1: return false
	var steps := maxi(absi(delta.x), absi(delta.y))
	for i in range(1, steps):
		var cell := Vector2i(Vector2(actor.grid_pos).lerp(Vector2(target.grid_pos), float(i) / steps).round())
		if tiles[cell].blocked: return false
	return actor.unit_id != "mira" or actor.mp >= 6

func forecast(actor: Unit, target: Unit) -> Dictionary:
	if actor.unit_id == "mira":
		return CombatFormula.calculate_magical_attack(actor, target, "holy", 110)
	return CombatFormula.calculate_physical_attack(actor, target, tiles[actor.grid_pos], tiles[target.grid_pos])

func move_active(cell: Vector2i) -> Array:
	if moved or not result.is_empty(): return []
	var paths := reachable(active)
	if not paths.has(cell) or cell == active.grid_pos: return []
	var path: Array = paths[cell]
	active.facing = GridSystem.facing_from_delta(active.grid_pos, cell)
	active.grid_pos = cell
	moved = true
	check_result()
	return path

func attack_active(target: Unit) -> Dictionary:
	if acted or not result.is_empty() or not can_attack(active, target): return {}
	var formula := forecast(active, target)
	acted = true
	if active.unit_id == "mira": active.mp -= 6
	if rng.randi_range(1, 100) > int(formula.hit_pct): return {"message": "%s misses %s" % [active.display_name, target.display_name], "damage": 0}
	var critical := rng.randi_range(1, 100) <= int(formula.crit_pct)
	var incoming := int(formula.incoming_damage)
	if critical: incoming = int(round(incoming * float(formula.crit_mult)))
	var projection: Dictionary = CombatFormula.project_magical_armor_result(target, incoming) if active.unit_id == "mira" else CombatFormula.project_physical_armor_result(target, incoming)
	var damage := mini(target.hp, int(projection.hp_damage))
	target.hp = maxi(0, target.hp - damage)
	target.temper -= int(projection.get("temper_damage", 0))
	target.ether -= int(projection.get("ether_damage", 0))
	check_result()
	return {"damage": damage, "message": "%s → %s: %d HP%s" % [active.display_name, target.display_name, damage, " · CRITICAL" if critical else ""]}

func heal_active(target: Unit) -> bool:
	if acted or active.unit_id != "mira" or active.mp < 8 or not target or target.team != "player" or target.hp <= 0: return false
	var delta := target.grid_pos - active.grid_pos
	if absi(delta.x) + absi(delta.y) > 3: return false
	var heal := CombatFormula.calculate_heal(target, 45)
	target.hp = int(heal.hp_after)
	active.mp -= 8
	acted = true
	return true

func next_turn() -> void:
	check_result()
	if not result.is_empty(): return
	active = order.tick_until_ready()
	moved = false
	acted = false

func check_result() -> void:
	var allies := units.filter(func(u: Unit): return u.team == "player" and u.hp > 0)
	var foes := units.filter(func(u: Unit): return u.team == "enemy" and u.hp > 0)
	if allies.is_empty(): result = "DEFEAT"
	elif foes.is_empty() and occupant(GATE) != null and occupant(GATE).team == "player": result = "VICTORY"
