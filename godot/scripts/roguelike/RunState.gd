## RunState.gd — RefCounted, tracks active roguelike run.
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

## Flat 10-battle node plan with boon picks every ~3 floors
static func create(p_seed: int) -> RunState:
	var rs          := RunState.new()
	rs.run_id       = "run_%s" % str(p_seed)
	rs.seed         = p_seed
	rs.started_at   = int(Time.get_unix_time_from_system())

	# Build 10-floor node sequence
	for f in range(1, TOTAL_FLOORS + 1):
		var is_boss := f == TOTAL_FLOORS
		rs.floor_plan.append({
			"floor":     f,
			"type":      "boss" if is_boss else "battle",
			"completed": false,
		})
		# Insert boon pick after floors 3, 6, 9
		if f in [3, 6, 9]:
			rs.floor_plan.append({
				"floor":     f,
				"type":      "boon_pick",
				"completed": false,
			})
		# Insert wanderer after floors 5, 8
		if f in [5, 8]:
			rs.floor_plan.append({
				"floor":     f,
				"type":      "wanderer",
				"completed": false,
			})
	return rs

func get_current_node() -> Dictionary:
	if current_node >= floor_plan.size(): return {}
	return floor_plan[current_node]

func advance() -> void:
	if current_node < floor_plan.size() - 1:
		current_node += 1
		# Sync current_floor to the floor of the next battle node
		var node := get_current_node()
		if node.get("type", "") in ["battle", "boss"]:
			current_floor = node.get("floor", current_floor)
	else:
		completed = true

func complete_current_node() -> void:
	if current_node < floor_plan.size():
		floor_plan[current_node]["completed"] = true
	advance()

func to_dict() -> Dictionary:
	return {
		"run_id": run_id, "seed": seed, "floor": current_floor,
		"node": current_node, "floor_plan": floor_plan,
		"active_boons": active_boons, "active_curses": active_curses, "banned_guardian": banned_guardian, "elite_kills": elite_kills,
		"deaths": deaths, "completed": completed, "started_at": started_at,
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
