class_name BattleManager
extends Node

signal phase_changed(new_phase: String)
signal turn_started(unit_id: String, team: String)
signal turn_ended(unit_id: String)
signal unit_defeated(unit_id: String)
signal battle_won(rewards: Dictionary)
signal battle_lost()
signal move_range_ready(positions: Array)
signal attack_range_ready(positions: Array)
signal log_message(text: String)

enum Phase { INACTIVE, TICK, PLAYER_TURN, ENEMY_TURN, RESOLVE, CHECK_OBJECTIVE, VICTORY, DEFEAT }

@onready var tactical_grid: TacticalGrid = $TacticalGrid
@onready var turn_order: TurnOrder = $TurnOrder
@onready var combat_resolver: CombatResolver = $CombatResolver
@onready var objective_tracker: ObjectiveTracker = $ObjectiveTracker

var map_data: MapData
var units: Dictionary = {}
var current_phase: Phase = Phase.INACTIVE
var active_unit_id: String = ""
var active_command: String = ""


func _ready() -> void:
	tactical_grid.tile_clicked.connect(_on_tile_clicked)
	tactical_grid.unit_clicked.connect(_on_unit_clicked)


func start_battle(p_map_data: MapData, p_units: Array[Unit]) -> void:
	map_data = p_map_data
	for unit in p_units:
		units[unit.unit_id] = unit
		unit.unit_defeated.connect(_on_unit_defeated)
	turn_order.initialize(p_units)
	objective_tracker.initialize(map_data, p_units)
	log_message.emit("Battle started: %s" % map_data.display_name)
	log_message.emit("Objective: %s" % map_data.objective_label)
	_set_phase(Phase.TICK)


func _set_phase(new_phase: Phase) -> void:
	current_phase = new_phase
	phase_changed.emit(Phase.keys()[new_phase])
	match new_phase:
		Phase.TICK:            _run_tick()
		Phase.PLAYER_TURN:     _begin_player_turn()
		Phase.ENEMY_TURN:      _begin_enemy_turn()
		Phase.RESOLVE:         _resolve_turn()
		Phase.CHECK_OBJECTIVE: _check_objective()
		Phase.VICTORY:         _handle_victory()
		Phase.DEFEAT:          battle_lost.emit()


func _run_tick() -> void:
	var ready_unit: Unit = turn_order.tick_until_ready()
	if not ready_unit:
		return
	active_unit_id = ready_unit.unit_id
	if ready_unit.team == "enemy":
		_set_phase(Phase.ENEMY_TURN)
	else:
		_set_phase(Phase.PLAYER_TURN)


func _begin_player_turn() -> void:
	var unit: Unit = units.get(active_unit_id)
	if unit:
		unit.begin_turn()
	turn_started.emit(active_unit_id, "player")
	var name := unit.display_name if unit else active_unit_id
	log_message.emit("%s's turn." % name)


func _begin_enemy_turn() -> void:
	var unit: Unit = units.get(active_unit_id)
	if not unit:
		_set_phase(Phase.RESOLVE)
		return
	unit.begin_turn()
	log_message.emit("Enemy: %s acts." % unit.display_name)
	_run_enemy_ai(unit)
	unit.end_turn()
	turn_ended.emit(active_unit_id)
	_set_phase(Phase.RESOLVE)


func _run_enemy_ai(unit: Unit) -> void:
	var closest_player: Unit = null
	var closest_dist: int = 9999
	for uid in units:
		var u: Unit = units[uid]
		if u.team == "player" and u.hp > 0:
			var dist := GridSystem.manhattan(unit.grid_pos, u.grid_pos)
			if dist < closest_dist:
				closest_dist = dist
				closest_player = u
	if not closest_player:
		return
	if closest_dist <= 1:
		var tile_att := tactical_grid.get_tile(unit.grid_pos)
		var tile_tar := tactical_grid.get_tile(closest_player.grid_pos)
		var result := combat_resolver.resolve_attack(unit, closest_player, tile_att, tile_tar)
		log_message.emit("%s hits %s for %d dmg!" % [unit.display_name, closest_player.display_name, result.get("hp_damage", 0)])
	else:
		var occupied: Array = []
		for uid in units:
			var u: Unit = units[uid]
			if u.unit_id != unit.unit_id and u.hp > 0:
				occupied.append(u.grid_pos)
		var reachable := GridSystem.get_move_range(
			unit.grid_pos, unit.unit_data.base_stats.move,
			tactical_grid.tiles, occupied, map_data.map_width, map_data.map_height
		)
		var best_tile := unit.grid_pos
		var best_dist := closest_dist
		for tile_pos in reachable:
			var d := GridSystem.manhattan(tile_pos, closest_player.grid_pos)
			if d < best_dist:
				best_dist = d
				best_tile = tile_pos
		if best_tile != unit.grid_pos:
			var old_pos := unit.grid_pos
			unit.grid_pos = best_tile
			tactical_grid.move_unit_visual(unit.unit_id, old_pos, best_tile)
			log_message.emit("%s advances." % unit.display_name)
		else:
			log_message.emit("%s holds." % unit.display_name)


func _resolve_turn() -> void:
	_set_phase(Phase.CHECK_OBJECTIVE)


func _check_objective() -> void:
	if objective_tracker.is_victory():
		_set_phase(Phase.VICTORY)
	elif objective_tracker.is_defeat():
		_set_phase(Phase.DEFEAT)
	else:
		_set_phase(Phase.TICK)


func _handle_victory() -> void:
	var rewards := {"gold": map_data.reward_gold, "jp": map_data.reward_jp,
					"items": map_data.reward_items, "flags": map_data.reward_flags}
	log_message.emit("VICTORY! +%dg +%dJP" % [map_data.reward_gold, map_data.reward_jp])
	battle_won.emit(rewards)


# ── Player commands ───────────────────────────────────────────────────────────

func select_command(command: String) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	active_command = command
	var unit: Unit = units.get(active_unit_id)
	if not unit:
		return
	match command:
		"move":
			var occupied: Array = []
			for uid in units:
				var u: Unit = units[uid]
				if u.unit_id != unit.unit_id and u.hp > 0:
					occupied.append(u.grid_pos)
			var move_range := GridSystem.get_move_range(
				unit.grid_pos, unit.unit_data.base_stats.move,
				tactical_grid.tiles, occupied, map_data.map_width, map_data.map_height
			)
			move_range_ready.emit(move_range)
			tactical_grid.show_move_range(move_range)
		"attack":
			var atk_range := GridSystem.get_attack_range(
				unit.grid_pos, 1, 1, map_data.map_width, map_data.map_height
			)
			attack_range_ready.emit(atk_range)
			tactical_grid.show_attack_range(atk_range)
		"wait":
			_end_player_turn()


func _on_tile_clicked(grid_pos: Vector2i) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	var unit: Unit = units.get(active_unit_id)
	if not unit:
		return
	if active_command == "move" and grid_pos in tactical_grid.move_tiles:
		var old_pos := unit.grid_pos
		unit.move_to(grid_pos)
		tactical_grid.move_unit_visual(unit.unit_id, old_pos, grid_pos)
		tactical_grid.clear_highlights()
		active_command = ""
		log_message.emit("%s moved to %d,%d." % [unit.display_name, grid_pos.x, grid_pos.y])
		_end_player_turn()


func _on_unit_clicked(unit_id: String) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	if active_command == "attack":
		var attacker: Unit = units.get(active_unit_id)
		var target: Unit = units.get(unit_id)
		if not attacker or not target or target.team == attacker.team or target.hp <= 0:
			return
		if target.grid_pos in tactical_grid.attack_tiles:
			var tile_att := tactical_grid.get_tile(attacker.grid_pos)
			var tile_tar := tactical_grid.get_tile(target.grid_pos)
			var result := combat_resolver.resolve_attack(attacker, target, tile_att, tile_tar)
			tactical_grid.clear_highlights()
			active_command = ""
			log_message.emit("%s hits %s for %d dmg!" % [attacker.display_name, target.display_name, result.get("hp_damage", 0)])
			_end_player_turn()


func _end_player_turn() -> void:
	var unit: Unit = units.get(active_unit_id)
	if unit:
		unit.end_turn()
	turn_ended.emit(active_unit_id)
	active_command = ""
	tactical_grid.clear_highlights()
	_set_phase(Phase.RESOLVE)


func _on_unit_defeated(unit_id: String) -> void:
	unit_defeated.emit(unit_id)
	if units.has(unit_id):
		log_message.emit("%s was defeated!" % units[unit_id].display_name)
	objective_tracker.on_unit_defeated(unit_id)
	turn_order.remove_unit(unit_id)
