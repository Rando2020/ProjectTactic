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
signal ability_mode_started(usable_ids: Array)

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
var selected_ability_id: String = ""


func _ready() -> void:
	tactical_grid.tile_clicked.connect(_on_tile_clicked)
	tactical_grid.unit_clicked.connect(_on_unit_clicked)


func start_battle(p_map_data: MapData, p_units: Array[Unit]) -> void:
	map_data = p_map_data
	for unit in p_units:
		units[unit.unit_id] = unit
		unit.unit_defeated.connect(_on_unit_defeated)
		unit.status_tick.connect(_on_status_tick)
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
	var unit_name := unit.display_name if unit else active_unit_id
	log_message.emit("%s's turn." % unit_name)


func _begin_enemy_turn() -> void:
	var unit: Unit = units.get(active_unit_id)
	if not unit:
		_set_phase(Phase.RESOLVE)
		return
	unit.begin_turn()
	log_message.emit("Enemy: %s acts." % unit.display_name)
	var cast_spell := randf() < 0.45
	if cast_spell and _try_enemy_spell(unit):
		pass  # spell was cast
	else:
		_run_enemy_ai(unit)
	unit.end_turn()
	_process_terrain_hazards(unit)
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
		if result.get("missed", false):
			log_message.emit("%s attacks but misses! (blind)" % unit.display_name)
		else:
			log_message.emit("%s hits %s for %d dmg!" % [unit.display_name, closest_player.display_name, result.get("hp_damage", 0)])
	else:
		var occupied: Array = []
		for uid in units:
			var u: Unit = units[uid]
			if u.unit_id != unit.unit_id and u.hp > 0:
				occupied.append(u.grid_pos)
		var reachable := GridSystem.get_move_range(
			unit.grid_pos, unit.unit_data.base_stats.move,
			tactical_grid.tiles, occupied, map_data.map_width, map_data.map_height,
			unit.unit_data.base_stats.jump
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
				tactical_grid.tiles, occupied, map_data.map_width, map_data.map_height,
				unit.unit_data.base_stats.jump
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
		"ability":
			var ab_unit: Unit = units.get(active_unit_id)
			if not ab_unit:
				return
			if ab_unit.has_status("silence"):
				log_message.emit("%s is silenced!" % ab_unit.display_name)
				return
			var usable: Array = []
			for ab_id in ab_unit.unit_data.abilities:
				var ab: Dictionary = AbilityDB.get_ability(ab_id)
				if ab_unit.mp >= ab.get("mp_cost", 0):
					usable.append(ab_id)
			ability_mode_started.emit(usable)


func select_ability(ability_id: String) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	var unit: Unit = units.get(active_unit_id)
	if not unit:
		return
	var ability: Dictionary = AbilityDB.get_ability(ability_id)
	if unit.mp < ability.get("mp_cost", 0):
		log_message.emit("Not enough MP!")
		return
	selected_ability_id = ability_id
	active_command = "ability_target"
	var range_val: int = ability.get("range", 1)
	var target_type: String = ability.get("target_type", "enemy")
	if target_type == "self" or range_val == 0:
		_execute_ability(unit, unit, ability)
		return
	var ab_range := GridSystem.get_attack_range(
		unit.grid_pos, 1, range_val, map_data.map_width, map_data.map_height
	)
	tactical_grid.show_ability_range(ab_range)


func _execute_ability(caster: Unit, target: Unit, ability: Dictionary) -> void:
	var mp_cost: int = ability.get("mp_cost", 0)
	caster.mp = max(caster.mp - mp_cost, 0)
	tactical_grid.clear_highlights()
	active_command = ""
	selected_ability_id = ""
	var spell_type: String = ability.get("spell_type", "fire")
	var base_power: int = ability.get("base_power", 100)
	var ab_name: String = ability.get("display_name", "?")
	if spell_type == "cure":
		combat_resolver.resolve_heal(caster, target, base_power)
		log_message.emit("%s uses %s on %s!" % [caster.display_name, ab_name, target.display_name])
	elif spell_type == "physical":
		var tile_c := tactical_grid.get_tile(caster.grid_pos)
		var tile_t := tactical_grid.get_tile(target.grid_pos)
		var result := combat_resolver.resolve_attack(caster, target, tile_c, tile_t)
		if result.get("missed", false):
			log_message.emit("%s swings but misses! (blind)" % caster.display_name)
		else:
			log_message.emit("%s uses %s!" % [caster.display_name, ab_name])
	else:
		combat_resolver.resolve_spell(caster, target, spell_type, base_power)
		log_message.emit("%s casts %s on %s!" % [caster.display_name, ab_name, target.display_name])
		# Fire spells can ignite flammable terrain
		if spell_type == "fire":
			var tgt_terrain: String = tactical_grid.get_tile(target.grid_pos).get("terrain", "")
			if tgt_terrain in ["grass", "road"]:
				tactical_grid.ignite_tile(target.grid_pos)
				log_message.emit("The ground catches fire!")
	# Apply any status effect after a short delay (spells deal damage after 0.18 s)
	var se_data: Dictionary = ability.get("status_effect", {})
	if not se_data.is_empty() and spell_type != "cure":
		get_tree().create_timer(0.3).timeout.connect(
			func() -> void: _try_apply_status(target, se_data))


func _try_enemy_spell(unit: Unit) -> bool:
	if unit.unit_data.abilities.is_empty():
		return false
	# Shuffle abilities so enemies vary their choices
	var ab_list: Array = unit.unit_data.abilities.duplicate()
	ab_list.shuffle()
	for ab_id in ab_list:
		var ab: Dictionary = AbilityDB.get_ability(ab_id)
		if unit.mp < ab.get("mp_cost", 0):
			continue
		var spell_range: int = ab.get("range", 1)
		var target_type: String = ab.get("target_type", "enemy")
		for uid in units:
			var target: Unit = units[uid]
			if target.hp <= 0:
				continue
			var is_valid := (target_type == "enemy" and target.team == "player") or \
							(target_type == "ally" and target.team == unit.team and target != unit)
			if not is_valid:
				continue
			if GridSystem.manhattan(unit.grid_pos, target.grid_pos) <= spell_range:
				_execute_ability(unit, target, ab)
				return true
	return false


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
	elif active_command == "ability_target" and selected_ability_id != "":
		var target: Unit = units.get(unit_id)
		if not target or target.hp <= 0:
			return
		var ability: Dictionary = AbilityDB.get_ability(selected_ability_id)
		var target_type: String = ability.get("target_type", "enemy")
		var caster: Unit = units.get(active_unit_id)
		if not caster:
			return
		var valid_target := false
		if target_type == "enemy" and target.team != caster.team:
			valid_target = true
		elif target_type == "ally" and target.team == caster.team:
			valid_target = true
		if not valid_target:
			return
		if target.grid_pos not in tactical_grid.ability_tiles:
			return
		_execute_ability(caster, target, ability)
		_end_player_turn()


func _end_player_turn() -> void:
	var unit: Unit = units.get(active_unit_id)
	if unit:
		unit.end_turn()
		_process_terrain_hazards(unit)
	turn_ended.emit(active_unit_id)
	active_command = ""
	selected_ability_id = ""
	tactical_grid.clear_highlights()
	_set_phase(Phase.RESOLVE)


func _on_unit_defeated(unit_id: String) -> void:
	unit_defeated.emit(unit_id)
	if units.has(unit_id):
		log_message.emit("%s was defeated!" % units[unit_id].display_name)
	objective_tracker.on_unit_defeated(unit_id)
	turn_order.remove_unit(unit_id)
	# A unit dying mid-tick could end the battle — check objectives
	if current_phase == Phase.TICK or current_phase == Phase.RESOLVE:
		_set_phase(Phase.CHECK_OBJECTIVE)


func _process_terrain_hazards(unit: Unit) -> void:
	if unit.hp <= 0:
		return
	var tile: Dictionary = tactical_grid.get_tile(unit.grid_pos)
	match tile.get("terrain", ""):
		"burning":
			var dmg: int = max(1, int(unit.unit_data.base_stats.hp * 0.05))
			var result := unit.receive_damage(dmg, "magical")
			var dealt: int = result.get("hp_damage", 0)
			log_message.emit("%s takes %d fire damage from burning ground!" % [unit.display_name, dealt])
			var vfx_node := get_node_or_null("/root/VFX")
			if vfx_node:
				(vfx_node as VFXManager).play_damage_number(unit.grid_pos, dealt, Color(1.0, 0.45, 0.1))
				(vfx_node as VFXManager).play_fire(unit.grid_pos)


func _try_apply_status(target: Unit, se_data: Dictionary) -> void:
	if not is_instance_valid(target) or target.hp <= 0:
		return
	var sid: String = se_data.get("id", "")
	if sid == "" or target.has_status(sid):
		return
	var se := StatusEffect.new()
	se.status_id   = sid
	se.display_name = sid.capitalize()
	se.duration    = se_data.get("duration", 2)
	se.magnitude   = se_data.get("magnitude", 0.0)
	se.damage_type = se_data.get("damage_type", "pure")
	target.apply_status(se)
	log_message.emit("%s is now %s!" % [target.display_name, sid.to_upper()])


func _on_status_tick(unit_id: String, status_id: String, damage: int) -> void:
	var unit: Unit = units.get(unit_id)
	var uname: String = unit.display_name if unit else unit_id
	log_message.emit("%s: %s tick -%d HP" % [uname, status_id.capitalize(), damage])
	# Show a coloured damage number on the unit's tile
	var vfx_node := get_node_or_null("/root/VFX")
	if vfx_node and unit:
		var color: Color = Color(0.2, 0.9, 0.2) if status_id == "poison" \
			else Color(1.0, 0.5, 0.1)   # green for poison, orange for burn
		(vfx_node as VFXManager).play_damage_number(unit.grid_pos, damage, color)
