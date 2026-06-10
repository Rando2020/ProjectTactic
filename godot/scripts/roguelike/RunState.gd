class_name RunState
extends RefCounted

const TOTAL_FLOORS := 10
const TOWN_NODE_TYPES: Array[String] = ["town_1", "town_2", "town_3"]

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
var inventory:     Array  = []   ## LootSystem item Dictionaries collected this run
var run_deployment: Array = []   ## Persistent player formation for this run
var equipped_vow_id: String = VowSigilSystem.DEFAULT_VOW_ID
var equipped_vow_level: int = 1
var equipped_vow_xp: int = 0
var equipped_sigil_id: String = VowSigilSystem.DEFAULT_SIGIL_ID
var equipped_sigil_level: int = 1
var equipped_sigil_xp: int = 0

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
	if floor_num == 2:
		return ["wanderer", "battle"]
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
	if floor_num in [10, 20, 29]:
		var town_type: String = _town_type_for_floor(floor_num)
		if not result.has(town_type):
			if result.size() < 3:
				result.append(town_type)
			else:
				result[result.size() - 1] = town_type
	return result

static func _town_type_for_floor(floor_num: int) -> String:
	match floor_num:
		10: return TOWN_NODE_TYPES[0]
		20: return TOWN_NODE_TYPES[1]
		29: return TOWN_NODE_TYPES[2]
		_: return TOWN_NODE_TYPES[0]

static func _risk_for_node(ntype: String, _floor_num: int) -> String:
	match ntype:
		"boss": return "Final fight"
		"elite": return "High risk"
		"mystery": return "Unknown"
		"mystery_cache": return "Reward"
		"mystery_training": return "Reward"
		"mystery_shrine": return "Choice"
		"mystery_ambush": return "Danger"
		"mystery_treasure": return "Reward"
		"mystery_caravan": return "Shop"
		"mystery_trap": return "Danger"
		"mystery_curse_site": return "Choice"
		"mystery_mimic": return "Danger"
		"boon_pick": return "Safe"
		"wanderer": return "Story"
		"town_1", "town_2", "town_3": return "Town"
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
		"mystery_treasure": return "+vault gold"
		"mystery_caravan": return "Buy/sell"
		"mystery_trap": return "Gold+risk"
		"mystery_curse_site": return "+JP/curse"
		"mystery_mimic": return "Spoils"
		"boon_pick": return "Guardian boon"
		"wanderer": return "Secret help"
		"town_1": return "Rest"
		"town_2": return "Armory"
		"town_3": return "Scout"
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
	return reveal_mystery_node_at_index(current_node)

func reveal_mystery_node_at_index(index: int) -> Dictionary:
	if index < 0 or index >= floor_plan.size():
		return {}
	var node: Dictionary = floor_plan[index]
	if node.get("type", "") != "mystery":
		return node
	var options: Array[String] = [
		"mystery_cache", "mystery_training", "mystery_shrine", "mystery_ambush",
		"mystery_treasure", "mystery_caravan", "mystery_trap", "mystery_curse_site", "mystery_mimic",
	]
	var node_floor: int = int(node.get("floor", current_floor))
	var roll: int = int(abs((seed * 97 + node_floor * 53 + index * 17) % options.size()))
	var resolved_type: String = options[roll]
	floor_plan[index]["type"] = resolved_type
	floor_plan[index]["revealed"] = true
	floor_plan[index]["risk"] = _risk_for_node(resolved_type, node_floor)
	floor_plan[index]["reward_hint"] = _reward_for_node(resolved_type, node_floor)
	return floor_plan[index]

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

func get_loadout_bonus() -> Dictionary:
	return VowSigilSystem.loadout_bonus(equipped_vow_id, equipped_vow_level, equipped_sigil_id, equipped_sigil_level)

func grant_loadout_xp(amount: int) -> void:
	if amount <= 0:
		return
	equipped_vow_xp += amount
	equipped_sigil_xp += amount
	equipped_vow_level = VowSigilSystem.level_for_xp(equipped_vow_xp)
	equipped_sigil_level = VowSigilSystem.level_for_xp(equipped_sigil_xp)

func to_dict() -> Dictionary:
	return {
		"run_id": run_id, "seed": seed, "floor": current_floor,
		"node": current_node, "floor_plan": floor_plan,
		"active_boons": active_boons, "active_curses": active_curses, "banned_guardian": banned_guardian, "elite_kills": elite_kills,
		"deaths": deaths, "completed": completed, "started_at": started_at, "heat_level": heat_level,
		"equipped_vow_id": equipped_vow_id, "equipped_vow_level": equipped_vow_level, "equipped_vow_xp": equipped_vow_xp,
		"equipped_sigil_id": equipped_sigil_id, "equipped_sigil_level": equipped_sigil_level, "equipped_sigil_xp": equipped_sigil_xp,
		"inventory": inventory,
		"run_deployment": run_deployment,
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
	rs.equipped_vow_id = d.get("equipped_vow_id", VowSigilSystem.DEFAULT_VOW_ID)
	rs.equipped_vow_level = int(d.get("equipped_vow_level", 1))
	rs.equipped_vow_xp = int(d.get("equipped_vow_xp", 0))
	rs.equipped_sigil_id = d.get("equipped_sigil_id", VowSigilSystem.DEFAULT_SIGIL_ID)
	rs.equipped_sigil_level = int(d.get("equipped_sigil_level", 1))
	rs.equipped_sigil_xp = int(d.get("equipped_sigil_xp", 0))
	rs.inventory = d.get("inventory", [])
	rs.run_deployment = d.get("run_deployment", [])
	return rs
