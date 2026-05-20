class_name FloorGenerator
extends RefCounted

const FLOOR_MAPS := {
	1: ["ashvale_road_01"],
	2: ["mirefen_marsh_01", "ashvale_road_01"],
	3: ["thornspire_vault_01", "mirefen_marsh_01", "crypt_of_echoes_01"],
	4: ["crypt_of_echoes_01"],
}

static func generate_run(seed: int, floors: int = 4) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var plan: Array[Dictionary] = []
	for floor_number in range(1, floors + 1):
		var nodes: Array[Dictionary] = []
		if floor_number == floors:
			nodes.append(_battle_node(floor_number, rng, false, true))
		elif floor_number == 1:
			nodes.append(_battle_node(floor_number, rng))
			nodes.append(_boon_node(floor_number, rng))
		elif floor_number == 2:
			nodes.append(_battle_node(floor_number, rng))
			nodes.append(_wanderer_node(floor_number, rng))
			nodes.append(_battle_node(floor_number, rng))
			nodes.append(_boon_node(floor_number, rng))
		else:
			nodes.append(_battle_node(floor_number, rng))
			nodes.append(_wanderer_node(floor_number, rng))
			nodes.append(_battle_node(floor_number, rng, true))
			nodes.append(_boon_node(floor_number, rng))
		plan.append({"floor": floor_number, "nodes": nodes, "completed": false})
	return {
		"run_id": "run_%s" % str(seed),
		"seed": seed,
		"total_floors": floors,
		"current_floor": 1,
		"current_node_index": 0,
		"plan": plan,
		"active_boons": [],
		"elites_slain": 0,
		"run_aether": 0,
		"deaths": 0,
	}

static func get_current_node(run_state: Dictionary) -> Dictionary:
	var floor_index := int(run_state.get("current_floor", 1)) - 1
	var node_index := int(run_state.get("current_node_index", 0))
	var plan: Array = run_state.get("plan", [])
	if floor_index < 0 or floor_index >= plan.size():
		return {}
	var floor: Dictionary = plan[floor_index]
	var nodes: Array = floor.get("nodes", [])
	if node_index < 0 or node_index >= nodes.size():
		return {}
	return nodes[node_index]

static func complete_current_node(run_state: Dictionary) -> Dictionary:
	var next := run_state.duplicate(true)
	var floor_index := int(next.get("current_floor", 1)) - 1
	var node_index := int(next.get("current_node_index", 0))
	var plan: Array = next.get("plan", [])
	if floor_index >= 0 and floor_index < plan.size():
		var floor: Dictionary = plan[floor_index]
		var nodes: Array = floor.get("nodes", [])
		if node_index >= 0 and node_index < nodes.size():
			var node: Dictionary = nodes[node_index]
			node["completed"] = true
			nodes[node_index] = node
			floor["nodes"] = nodes
			plan[floor_index] = floor
	next["plan"] = plan
	return advance_run(next)

static func advance_run(run_state: Dictionary) -> Dictionary:
	var next := run_state.duplicate(true)
	var floor_index := int(next.get("current_floor", 1)) - 1
	var node_index := int(next.get("current_node_index", 0))
	var plan: Array = next.get("plan", [])
	if floor_index < 0 or floor_index >= plan.size():
		next["completed"] = true
		return next
	var floor: Dictionary = plan[floor_index]
	var nodes: Array = floor.get("nodes", [])
	if node_index < nodes.size() - 1:
		next["current_node_index"] = node_index + 1
	elif int(next.get("current_floor", 1)) < int(next.get("total_floors", 1)):
		next["current_floor"] = int(next.get("current_floor", 1)) + 1
		next["current_node_index"] = 0
	else:
		next["completed"] = true
	return next

static func _battle_node(floor_number: int, rng: RandomNumberGenerator, is_elite: bool = false, is_boss: bool = false) -> Dictionary:
	var maps: Array = FLOOR_MAPS.get(floor_number, FLOOR_MAPS[1])
	var map_id: String = maps[rng.randi_range(0, maps.size() - 1)]
	return {
		"type": "boss" if is_boss else "elite-battle" if is_elite else "battle",
		"map_id": map_id,
		"floor": floor_number,
		"is_elite": is_elite,
		"is_boss": is_boss,
		"elite_rate_bonus": 1.0 if is_boss else 0.5 if is_elite else 0.0,
		"completed": false,
	}

static func _boon_node(floor_number: int, rng: RandomNumberGenerator) -> Dictionary:
	return {"type": "boon-pick", "floor": floor_number, "options": BoonDB.generate_boon_options(rng, floor_number), "completed": false}

static func _wanderer_node(floor_number: int, rng: RandomNumberGenerator) -> Dictionary:
	return {"type": "wanderer", "floor": floor_number, "wanderer": WandererDB.pick_for_floor(floor_number, rng), "completed": false}
