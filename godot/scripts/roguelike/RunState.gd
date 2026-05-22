class_name RunState
extends RefCounted

const TOTAL_FLOORS := 10

var run_id:        String = ""
@warning_ignore("shadowed_global_identifier")
var seed:          int    = 0
var current_floor: int    = 1
var current_node:  int    = 0
var floor_plan:    Array  = []   # Array of node Dictionaries
var active_boons:  Array  = []
var active_curses: Array  = []   ## accepted curses this run
var banned_guardian: String = ""  ## set by Guardian's Absence curse
var active_wanderer_conditions: Array = []
var elite_kills:   int    = 0
var deaths:        int    = 0
var completed:     bool   = false
var started_at:    int    = 0
var heat_level:    int    = 0

## Slay-the-Spire-style route map: every floor can offer multiple choices.
## Choosing one node marks the other nodes on that floor as skipped, then the run
## advances to the next floor's available route options.
static func create(p_seed: int) -> RunState:
	var rs          := RunState.new()
	rs.run_id       = "run_%s" % str(p_seed)
	rs.seed         = p_seed
	rs.started_at   = int(Time.get_unix_time_from_system())

	for f in range(1, TOTAL_FLOORS + 1):
		var options := _route_options_for_floor(f, p_seed)
		for branch in range(options.size()):
			var ntype: String = options[branch]
			rs.floor_plan.append({
				"id": "f%d_b%d" % [f, branch],
				"floor": f,
				"branch": branch,
				"branch_count": options.size(),
				"type": ntype,
				"completed": false,
				"skipped": false,
				"revealed": ntype != "mystery",
				"risk": _risk_for_node(ntype, f),
				"reward_hint": _reward_for_node(ntype, f),
			})
	return rs

static func _route_options_for_floor(floor_num: int, run_seed: int) -> Array[String]:
	if floor_num == 1:
		return ["battle"]
	if floor_num >= TOTAL_FLOORS:
		return ["boss"]

	var patterns: Array[Array] = [
		["battle", "mystery"],
		["battle", "elite"],
		["battle", "boon_pick", "mystery"],
		["elite", "battle", "wanderer"],
		["battle", "mystery", "elite"],
	]
	var pick: int = int(abs((run_seed + floor_num * 37 + floor_num * floor_num * 11) % patterns.size()))
	var result: Array[String] = []
	for item in patterns[pick]:
		result.append(str(item))

	if floor_num in [3, 6, 9] and not result.has("boon_pick"):
		result[min(1, result.size() - 1)] = "boon_pick"
	if floor_num in [5, 8] and not result.has("wanderer"):
		result[result.size() - 1] = "wanderer"
	return result

static func _risk_for_node(ntype: String, _floor_num: int) -> String:
	match ntype:
		"boss": return "Final fight"
		"elite": return "High risk"
		"mystery": return "Unknown"
		"mystery_cache": return "Reward"
		"mystery_training": return "Reward"
		"mystery_shrine": return "Choice"
		"mystery_ambush": return "Danger"
		"boon_pick": return "Safe"
		"wanderer": return "Story"
		_: return "Standard"

static func _reward_for_node(ntype: String, _floor_num: int) -> String:
	match ntype:
		"boss": return "Run clear"
		"elite": return "+loot / +JP"
		"mystery": return "?"
		"mystery_cache": return "+gold"
		"mystery_training": return "+JP"
		"mystery_shrine": return "Boon offer"
		"mystery_ambush": return "+spoils"
		"boon_pick": return "Guardian boon"
		"wanderer": return "Secret help"
		_: return "+gold / +JP"

func get_current_node() -> Dictionary:
	if current_node >= floor_plan.size(): return {}
	return floor_plan[current_node]

func get_available_nodes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in floor_plan:
		if int(node.get("floor", 0)) == current_floor and node.get("completed", false) != true and node.get("skipped", false) != true:
			result.append(node)
	return result

func select_node(node_id: String) -> void:
	for i in range(floor_plan.size()):
		if str(floor_plan[i].get("id", "")) == node_id:
			current_node = i
			current_floor = int(floor_plan[i].get("floor", current_floor))
			return

func resolve_mystery_node(node_id: String) -> Dictionary:
	select_node(node_id)
	var node: Dictionary = get_current_node()
	if node.is_empty() or node.get("type", "") != "mystery":
		return node
	var options: Array[String] = ["mystery_cache", "mystery_training", "mystery_shrine", "mystery_ambush"]
	var roll: int = int(abs((seed * 97 + current_floor * 53 + current_node * 17) % options.size()))
	var resolved_type: String = options[roll]
	floor_plan[current_node]["type"] = resolved_type
	floor_plan[current_node]["revealed"] = true
	floor_plan[current_node]["risk"] = _risk_for_node(resolved_type, current_floor)
	floor_plan[current_node]["reward_hint"] = _reward_for_node(resolved_type, current_floor)
	return floor_plan[current_node]

func advance() -> void:
	for i in range(floor_plan.size()):
		var node: Dictionary = floor_plan[i]
		if node.get("completed", false) == true or node.get("skipped", false) == true:
			continue
		current_node = i
		current_floor = int(node.get("floor", current_floor))
		return
	completed = true

func complete_current_node() -> void:
	if current_node < floor_plan.size():
		var chosen_floor: int = int(floor_plan[current_node].get("floor", current_floor))
		floor_plan[current_node]["completed"] = true
		for i in range(floor_plan.size()):
			if i != current_node and int(floor_plan[i].get("floor", -1)) == chosen_floor:
				floor_plan[i]["skipped"] = true
	advance()

func to_dict() -> Dictionary:
	return {
		"run_id": run_id, "seed": seed, "floor": current_floor,
		"node": current_node, "floor_plan": floor_plan,
		"active_boons": active_boons, "active_curses": active_curses, "banned_guardian": banned_guardian, "elite_kills": elite_kills,
		"deaths": deaths, "completed": completed, "started_at": started_at, "heat_level": heat_level,
	}

static func from_dict(d: Dictionary) -> RunState:
	var rs := RunState.new()
	rs.run_id        = d.get("run_id", "")
	rs.seed          = d.get("seed", 0)
	rs.current_floor = d.get("floor", 1)
	rs.current_node  = d.get("node", 0)
	rs.floor_plan    = d.get("floor_plan", [])
	rs.active_boons   = d.get("active_boons", [])
	rs.active_curses  = d.get("active_curses", [])
	rs.banned_guardian = d.get("banned_guardian", "")
	rs.elite_kills   = d.get("elite_kills", 0)
	rs.deaths        = d.get("deaths", 0)
	rs.completed     = d.get("completed", false)
	rs.started_at    = d.get("started_at", 0)
	rs.heat_level    = d.get("heat_level", 0)
	return rs