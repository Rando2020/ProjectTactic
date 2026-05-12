## TurnOrder.gd
## Manages CT accumulation and the turn timeline.
## Pure logic — no rendering. Emits signals for UI to display timeline.
##
## AI AGENT: Implement TODO sections. See SYSTEMS.md section 2 for CT rules.

class_name TurnOrder
extends Node

signal timeline_updated(ordered_units: Array)

var units: Array[Unit] = []


func initialize(p_units: Array[Unit]) -> void:
	units = p_units.filter(func(u): return u.hp > 0)
    # Reset CT for all units on initialization
    for u in units:
        u.ct = 0


## Advance CT until one unit reaches 100. Returns that unit.
func tick_until_ready() -> Unit:
    # Continuously accumulate CT until a unit reaches the threshold. CT
    # accumulation is based on each unit's effective speed. Units that reach
    # 100 CT become ready to act; their CT is reduced by 100. If multiple
    # units reach 100 on the same tick, the one with the highest speed acts
    # first. After CT changes, emit an updated projected timeline.
    while true:
        var ready_units: Array[Unit] = []
        # Accumulate CT
        for u in units:
            if u.hp <= 0:
                continue
            u.ct += u.get_effective_speed()
            if u.ct >= 100:
                ready_units.append(u)
        # If any unit is ready, determine which acts first
        if ready_units.size() > 0:
            # Sort ready units by effective speed descending
            ready_units.sort_custom(func(a, b): return a.get_effective_speed() > b.get_effective_speed())
            var chosen: Unit = ready_units[0]
            chosen.ct -= 100
            # Emit timeline update before returning so UI can reflect new CT
            timeline_updated.emit(get_projected_order())
            return chosen
        # No unit ready this tick — update timeline preview
        timeline_updated.emit(get_projected_order())


func get_active_unit_id() -> String:
    # The active unit is the one whose CT most recently crossed the threshold
    # and thus acted in the last call to tick_until_ready. This method
    # anticipates that BattleManager will have stored or requested the
    # returned Unit from tick_until_ready; however, as a convenience we
    # approximate by selecting the unit with the highest CT value (closest
    # to 100). This does not modify CT.
    var best_unit: Unit = null
    var best_ct: int = -1
    for u in units:
        if u.hp <= 0:
            continue
        if u.ct > best_ct:
            best_ct = u.ct
            best_unit = u
    return best_unit.unit_id if best_unit else ""


## Returns an ordered preview of upcoming turns (for timeline UI)
## Projects forward N ticks to show who acts next
func get_projected_order(count: int = 8) -> Array[Dictionary]:
    # Simulate future CT accumulation to provide a timeline preview. Clone
    # current CT values and repeatedly advance until `count` units have been
    # scheduled to act. This does not mutate the real unit state.
    var projection: Array[Dictionary] = []
    # Clone CT values
    var ct_clone: Dictionary = {}
    for u in units:
        ct_clone[u.unit_id] = u.ct
    # Determine number of steps
    for i in range(count):
        var best_unit: Unit = null
        var ticks_to_ready: float = INF
        # Compute ticks required for each unit to reach 100 CT
        for u in units:
            if u.hp <= 0:
                continue
            var current_ct: float = ct_clone[u.unit_id]
            var speed: float = u.get_effective_speed()
            if speed <= 0:
                continue
            var ticks: float = (100.0 - current_ct) / speed
            if ticks < ticks_to_ready:
                ticks_to_ready = ticks
                best_unit = u
        if not best_unit:
            break
        # Record the projected turn
        projection.append({
            "unit_id": best_unit.unit_id,
            "display_name": best_unit.display_name,
            "portrait": best_unit.unit_data.portrait,
            "ct_to_turn": ticks_to_ready
        })
        # Advance CT for all units by ticks_to_ready * speed
        for u in units:
            if u.hp <= 0:
                continue
            ct_clone[u.unit_id] += u.get_effective_speed() * ticks_to_ready
        # Reduce CT for the chosen unit
        ct_clone[best_unit.unit_id] -= 100.0
    return projection


func remove_unit(unit_id: String) -> void:
	units = units.filter(func(u): return u.unit_id != unit_id)
	timeline_updated.emit(get_projected_order())
