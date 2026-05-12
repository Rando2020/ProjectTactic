## BattleManager.gd
## Scene-local Node that owns the entire battle loop.
## Connects TacticalGrid signals to game logic.
## Drives the CT turn order and phase machine.
## Tells UI what to display. Never touches UI directly — emits signals.
##
## AI AGENT: Implement all TODO sections.
## The phase machine is the heart of the battle. Get it right.

class_name BattleManager
extends Node

# ── Signals ──────────────────────────────────────────────────────────────────

signal phase_changed(new_phase: String)
signal turn_started(unit_id: String, team: String)
signal turn_ended(unit_id: String)
signal unit_defeated(unit_id: String)
signal battle_won(rewards: Dictionary)
signal battle_lost()
signal move_range_ready(positions: Array)
signal attack_range_ready(positions: Array)
signal log_message(text: String)

# ── Phase constants ────────────────────────────────────────────────────────────

enum Phase {
	INACTIVE,
	TICK,
	PLAYER_TURN,
	ENEMY_TURN,
	RESOLVE,
	CHECK_OBJECTIVE,
	VICTORY,
	DEFEAT,
}

# ── References ────────────────────────────────────────────────────────────────

@onready var tactical_grid: TacticalGrid = $TacticalGrid
@onready var turn_order: TurnOrder = $TurnOrder
@onready var combat_resolver: CombatResolver = $CombatResolver
@onready var objective_tracker: ObjectiveTracker = $ObjectiveTracker

# ── State ─────────────────────────────────────────────────────────────────────

var map_data: MapData
var units: Dictionary = {}         # unit_id -> Unit node
var current_phase: Phase = Phase.INACTIVE
var active_unit_id: String = ""
var selected_unit_id: String = ""
var active_command: String = ""    # "move", "attack", "ability", "item", "wait"


func _ready() -> void:
	tactical_grid.tile_clicked.connect(_on_tile_clicked)
	tactical_grid.unit_clicked.connect(_on_unit_clicked)


## Called by BattleScene after map_data and units are set up
func start_battle(p_map_data: MapData, p_units: Array[Unit]) -> void:
	map_data = p_map_data
	for unit in p_units:
		units[unit.unit_id] = unit
		unit.unit_defeated.connect(_on_unit_defeated)
	turn_order.initialize(p_units)
	objective_tracker.initialize(map_data, p_units)
	_set_phase(Phase.TICK)
	log_message.emit("Battle started: %s" % map_data.display_name)


func _set_phase(new_phase: Phase) -> void:
	current_phase = new_phase
	phase_changed.emit(Phase.keys()[new_phase])
	match new_phase:
		Phase.TICK:
			_run_tick()
		Phase.PLAYER_TURN:
			_begin_player_turn()
		Phase.ENEMY_TURN:
			_begin_enemy_turn()
		Phase.CHECK_OBJECTIVE:
			_check_objective()
		Phase.VICTORY:
			_handle_victory()
		Phase.DEFEAT:
			battle_lost.emit()


func _run_tick() -> void:
    # Use the TurnOrder to determine which unit acts next based on CT
    var ready_unit: Unit = turn_order.tick_until_ready()
    if not ready_unit:
        return
    active_unit_id = ready_unit.unit_id
    # Decide phase based on team/faction. We treat "party" as player.
    var faction: String = ready_unit.team
    if faction == "enemy":
        _set_phase(Phase.ENEMY_TURN)
    else:
        _set_phase(Phase.PLAYER_TURN)


func _begin_player_turn() -> void:
	# TODO: Call unit.begin_turn(), emit turn_started signal
	# Wait for player input (tile_clicked / unit_clicked signals drive this)
	active_unit_id = turn_order.get_active_unit_id()
	var unit: Unit = units.get(active_unit_id)
	if unit:
		unit.begin_turn()
	turn_started.emit(active_unit_id, "player")
	log_message.emit("%s's turn." % units[active_unit_id].display_name)


func _begin_enemy_turn() -> void:
    # Very simple AI: enemy immediately ends their turn without acting. A
    # more complete implementation would compute move/attack decisions using
    # GridSystem and CombatResolver. For now, log a message and proceed.
    active_unit_id = turn_order.get_active_unit_id()
    var unit: Unit = units.get(active_unit_id)
    if unit:
        unit.begin_turn()
        log_message.emit("Enemy %s acts." % unit.display_name)
        # Here you could implement AI behaviour such as moving toward the
        # nearest player unit or attacking if in range.
        unit.end_turn()
        turn_ended.emit(active_unit_id)
    _set_phase(Phase.RESOLVE)


func _check_objective() -> void:
	if objective_tracker.is_victory():
		_set_phase(Phase.VICTORY)
	elif objective_tracker.is_defeat():
		_set_phase(Phase.DEFEAT)
	else:
		_set_phase(Phase.TICK)


func _handle_victory() -> void:
	var rewards := {
		"gold": map_data.reward_gold,
		"jp": map_data.reward_jp,
		"items": map_data.reward_items,
		"flags": map_data.reward_flags,
	}
	battle_won.emit(rewards)


# ── Player command handling ────────────────────────────────────────────────────

func select_command(command: String) -> void:
	active_command = command
	var unit: Unit = units.get(active_unit_id)
	if not unit:
		return
	match command:
		"move":
            # Compute reachable tiles using the GridSystem and emit for UI
            var move_range := GridSystem.get_move_range(unit.grid_pos, unit.unit_data.base_stats.move, tactical_grid.tiles, tactical_grid.unit_positions)
            move_range_ready.emit(move_range)
            tactical_grid.show_move_range(move_range)
		"attack":
            # Basic attack range uses the unit's weapon; here we default to
            # Manhattan distance of 1 (adjacent tiles). Use GridSystem for
            # consistency.
            var attack_range := GridSystem.get_attack_range(unit.grid_pos, 1, tactical_grid.tiles)
            attack_range_ready.emit(attack_range)
            tactical_grid.show_attack_range(attack_range)
		"wait":
			_end_player_turn()


func _on_tile_clicked(grid_pos: Vector2i) -> void:
	var unit: Unit = units.get(active_unit_id)
	if not unit or current_phase != Phase.PLAYER_TURN:
		return
	match active_command:
		"move":
            # Move the active unit if the clicked tile is within the computed
            # movement range. After moving, end the player's turn and
            # transition to the resolve phase.
            if grid_pos in tactical_grid.move_tiles:
                var old_pos: Vector2i = unit.grid_pos
                unit.move_to(grid_pos)
                # Update the grid's unit position registry and animate sprite
                tactical_grid.move_unit_visual(active_unit_id, old_pos, grid_pos)
                active_command = ""
                tactical_grid.clear_highlights()
                # End turn and proceed to resolution
                unit.end_turn()
                turn_ended.emit(active_unit_id)
                _set_phase(Phase.RESOLVE)
		"ability":
			# TODO: Handle ability targeting
			pass


func _on_unit_clicked(unit_id: String) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	match active_command:
		"attack":
            # If the selected enemy is within attack range, resolve a basic
            # physical attack using the CombatResolver. Afterwards, clear
            # highlights and transition to resolve phase.
            var attacker: Unit = units.get(active_unit_id)
            var target: Unit = units.get(unit_id)
            if not attacker or not target:
                return
            var target_pos: Vector2i = target.grid_pos
            if target_pos in tactical_grid.attack_tiles:
                # Compute tile refs for height bonuses
                var tile_att := tactical_grid.get_tile(attacker.grid_pos)
                var tile_tar := tactical_grid.get_tile(target_pos)
                var result := combat_resolver.resolve_attack(attacker, target, tile_att, tile_tar)
                combat_resolver.apply_result(target, result)
                active_command = ""
                tactical_grid.clear_highlights()
                attacker.end_turn()
                turn_ended.emit(active_unit_id)
                _set_phase(Phase.RESOLVE)
		_:
			# Select a different unit or inspect
			selected_unit_id = unit_id


func _end_player_turn() -> void:
	var unit: Unit = units.get(active_unit_id)
	if unit:
		unit.end_turn()
	turn_ended.emit(active_unit_id)
	active_command = ""
	tactical_grid.clear_highlights()
	_set_phase(Phase.CHECK_OBJECTIVE)


func _on_unit_defeated(unit_id: String) -> void:
	unit_defeated.emit(unit_id)
	log_message.emit("%s was defeated." % units[unit_id].display_name)
	objective_tracker.on_unit_defeated(unit_id)
