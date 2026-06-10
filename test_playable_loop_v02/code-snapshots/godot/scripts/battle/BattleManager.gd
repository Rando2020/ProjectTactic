class_name BattleManager
extends Node

signal phase_changed(new_phase: String)
signal turn_started(unit_id: String, team: String)
signal turn_ended(unit_id: String)
signal unit_moved(unit_id: String, from: Vector2i, to: Vector2i)
signal unit_defeated(unit_id: String)
signal battle_won(rewards: Dictionary)
signal battle_lost()
signal move_range_ready(positions: Array)
signal attack_range_ready(positions: Array)
signal log_message(text: String)
signal ability_mode_started(usable_ids: Array)
signal tile_info_changed(text: String)
signal battle_started(display_name: String, objective: String)
signal command_hint_changed(text: String)
signal action_preview_changed(preview: Dictionary)
signal action_state_changed(can_move: bool, can_act: bool, has_pending: bool)
signal enemy_intent_changed(intent: Dictionary)

const RunBonusesUtil := preload("res://scripts/roguelike/RunBonuses.gd")
const FACING_OPPOSITE: Dictionary = {"N":"S","S":"N","E":"W","W":"E"}
const DEMO_PACE := 0.45
const MIN_WAIT := 0.03
const AUTO_BATTLE_TEST_MODE := true
const AUTO_BATTLE_TEST_SPEED := 2.0

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
## Most recent attack/ability name  read by BattleScene for death-context recording.
var last_ability_used: String = ""
var is_resolving_action: bool = false
var active_unit_has_moved: bool = false
var active_unit_has_acted: bool = false
var auto_battle_enabled: bool = AUTO_BATTLE_TEST_MODE
var battle_speed_multiplier: float = AUTO_BATTLE_TEST_SPEED
var _last_enemy_intents: Dictionary = {}

##  Tactical boon runtime state
var _ruinous_hit_counter:    int  = 0   ## counts hits toward Ruinous Field interval
var _wrath_crescendo_stacks: int  = 0   ## kill counter for Wrath Crescendo (resets each battle)
var _tiles_moved_this_turn:  int  = 0   ## Manhattan distance moved this player turn
var _iron_momentum_primed:   bool = false  ## true when Iron Momentum threshold was met
var _reaping_step_pending:   bool = false  ## true when a kill grants a free move

func _living_unit(uid: String) -> Unit:
	var candidate: Variant = units.get(uid)
	if candidate == null or not is_instance_valid(candidate):
		units.erase(uid)
		return null
	var unit := candidate as Unit
	if not unit or unit.hp <= 0:
		return null
	return unit


func _timer(seconds: float) -> SceneTreeTimer:
	return get_tree().create_timer(maxf(seconds * DEMO_PACE, MIN_WAIT))


func _exit_tree() -> void:
	if auto_battle_enabled:
		Engine.time_scale = 1.0


func _ready() -> void:
	tactical_grid.tile_clicked.connect(_on_tile_clicked)
	tactical_grid.unit_clicked.connect(_on_unit_clicked)
	tactical_grid.tile_hovered.connect(_on_tile_hovered)
	unit_moved.connect(_on_unit_moved_internal)


func start_battle(p_map_data: MapData, p_units: Array[Unit]) -> void:
	map_data = p_map_data
	_ruinous_hit_counter    = 0
	_wrath_crescendo_stacks = 0
	_tiles_moved_this_turn  = 0
	_iron_momentum_primed   = false
	_reaping_step_pending   = false
	if auto_battle_enabled:
		Engine.time_scale = battle_speed_multiplier
	else:
		Engine.time_scale = 1.0
	for unit in p_units:
		units[unit.unit_id] = unit
		unit.unit_defeated.connect(_on_unit_defeated)
		unit.status_tick.connect(_on_status_tick)
		#  Initialize boon tracking metadata
		unit.set_meta("kill_count", 0)
		unit.set_meta("moved_this_turn", false)
		unit.set_meta("tiles_moved_this_turn", 0)
	turn_order.initialize(p_units)
	objective_tracker.initialize(map_data, p_units)
	battle_started.emit(map_data.display_name, map_data.objective_label)
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
		Phase.DEFEAT:          _handle_defeat()


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
	var unit: Unit = _living_unit(active_unit_id)
	active_unit_has_moved = false
	active_unit_has_acted = false
	_tiles_moved_this_turn = 0
	_iron_momentum_primed  = false
	_reaping_step_pending  = false
	if unit:
		unit.begin_turn()
		tactical_grid.show_active_unit(unit.grid_pos, "player")
		#  Reset boon tracking for this turn
		unit.set_meta("moved_this_turn", false)
		unit.set_meta("tiles_moved_this_turn", 0)
		unit.set_meta("turn_start_pos", unit.grid_pos)
	turn_started.emit(active_unit_id, "player")
	_emit_enemy_intent_board()
	var unit_name := unit.display_name if unit else active_unit_id
	log_message.emit("%s's turn." % unit_name)
	command_hint_changed.emit("Choose Move, Attack, Ability, or Wait.")
	_emit_action_state()
	if auto_battle_enabled:
		command_hint_changed.emit("AUTO-BATTLE x%.1f: planning %s's turn..." % [battle_speed_multiplier, unit_name])
		_run_auto_player_turn.call_deferred(active_unit_id)


func _begin_enemy_turn() -> void:
	var unit: Unit = _living_unit(active_unit_id)
	if not unit:
		_set_phase(Phase.RESOLVE)
		return
	unit.begin_turn()
	active_unit_has_moved = false
	active_unit_has_acted = false
	tactical_grid.show_active_unit(unit.grid_pos, "enemy")
	turn_started.emit(active_unit_id, "enemy")

	#  Void Anchor: special behaviour
	if unit.unit_data and unit.unit_data.get("is_anchor") == true:
		log_message.emit("The Anchor pulses with void energy!")
		command_hint_changed.emit("VOID PULSE - take cover!")
		await _timer(0.6).timeout
		await _anchor_pulse(unit)
		unit.end_turn()
		turn_ended.emit(active_unit_id)
		_set_phase(Phase.RESOLVE)
		return

	log_message.emit("Enemy: %s acts." % unit.display_name)
	var intent: Dictionary = _evaluate_enemy_intent(unit)
	_last_enemy_intents[unit.unit_id] = intent
	enemy_intent_changed.emit(intent)
	command_hint_changed.emit(str(intent.get("summary", "Enemy is acting...")))
	await _timer(0.50).timeout
	await _execute_enemy_intent(unit, intent)
	unit.end_turn()
	_process_terrain_hazards(unit)
	turn_ended.emit(active_unit_id)
	_set_phase(Phase.RESOLVE)


## Void Anchor pulse  30 dark damage to all units within 2 tiles.
## Holy resistance boon (Luminarch's Covenant) halves this.
func _anchor_pulse(anchor: Unit) -> void:
	var pulse_damage := 30
	var vfx_n := get_node_or_null("/root/VFX")

	for uid in units:
		var u: Unit = _living_unit(str(uid))
		if not u:
			continue
		if u.hp <= 0: continue
		var dist: int = GridSystem.manhattan(anchor.grid_pos, u.grid_pos)
		if dist > 2: continue

		# Reduce damage for player units with min_hp_guard (Luminarch's Covenant)
		var bonuses := RunBonuses.for_current_run()
		var dmg := pulse_damage
		if u.team == "player" and bonuses.get("min_hp_guard", false):
			dmg = int(float(dmg) * 0.5)

		u.receive_damage(dmg, "magical")
		if vfx_n:
			(vfx_n as VFXManager).play_dark(u.grid_pos)
			await _timer(0.08).timeout
			(vfx_n as VFXManager).play_damage_number(u.grid_pos, dmg, Color(0.6, 0.2, 0.9))

		# Phase 2: Anchor enrages below 50% HP  pulses twice
		if anchor.hp < anchor.unit_data.base_stats.hp * 0.5 and dist <= 1:
			await _timer(0.4).timeout
			u.receive_damage(int(dmg * 0.6), "magical")
			if vfx_n:
				(vfx_n as VFXManager).play_damage_number(u.grid_pos, int(dmg * 0.6), Color(0.8, 0.1, 1.0))

	await _timer(0.3).timeout


func _run_enemy_ai(unit: Unit) -> void:
	var closest_player: Unit = null
	var closest_dist: int = 9999
	for uid in units:
		var u: Unit = _living_unit(str(uid))
		if not u:
			continue
		if u.team == "player" and u.hp > 0:
			var dist := GridSystem.manhattan(unit.grid_pos, u.grid_pos)
			if dist < closest_dist:
				closest_dist = dist
				closest_player = u
	if not closest_player:
		return
	if closest_dist <= unit.unit_data.base_stats.attack_range_max:
		var tile_att := tactical_grid.get_tile(unit.grid_pos)
		var tile_tar := tactical_grid.get_tile(closest_player.grid_pos)
		var result := combat_resolver.resolve_attack(unit, closest_player, tile_att, tile_tar)
		if result.get("missed", false):
			log_message.emit("%s attacks but misses! (blind)" % unit.display_name)
		else:
			var ftag := " [BACK ATTACK!]" if result.get("flank","") == "back" \
				else (" [flank]" if result.get("flank","") == "side" else "")
			log_message.emit("%s hits %s for %d dmg!%s" % [unit.display_name, closest_player.display_name, result.get("hp_damage", 0), ftag])
		# Counter-attack
		if result.get("counter", false):
			_timer(0.6).timeout.connect(
				func() -> void: _execute_counter_attack(closest_player, unit))
	else:
		var occupied: Array = []
		for uid in units:
			var u: Unit = _living_unit(str(uid))
			if not u:
				continue
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
			unit.move_to(best_tile)
			log_message.emit("%s advances." % unit.display_name)
			unit_moved.emit(unit.unit_id, old_pos, best_tile)
			await tactical_grid.move_unit_visual(unit.unit_id, old_pos, best_tile)
			await _timer(0.20).timeout
			active_unit_has_moved = true
			closest_dist = GridSystem.manhattan(unit.grid_pos, closest_player.grid_pos)
			if closest_dist <= unit.unit_data.base_stats.attack_range_max:
				_face_toward(unit, closest_player.grid_pos)
				var tile_att2 := tactical_grid.get_tile(unit.grid_pos)
				var tile_tar2 := tactical_grid.get_tile(closest_player.grid_pos)
				var result2 := combat_resolver.resolve_attack(unit, closest_player, tile_att2, tile_tar2)
				active_unit_has_acted = true
				if result2.get("missed", false):
					log_message.emit("%s attacks after moving but misses!" % unit.display_name)
				else:
					log_message.emit("%s moves in and hits %s for %d dmg!" % [unit.display_name, closest_player.display_name, result2.get("hp_damage", 0)])
				if result2.get("counter", false):
					_timer(0.6).timeout.connect(
						func() -> void: _execute_counter_attack(closest_player, unit))
		else:
			log_message.emit("%s holds." % unit.display_name)

func _evaluate_enemy_intent(unit: Unit) -> Dictionary:
	var hp_ratio := float(unit.hp) / float(max(unit.unit_data.base_stats.hp, 1))
	var nearest := _nearest_player(unit)
	if not nearest:
		return _enemy_intent(unit, "hold", null, "Hold", "No targets remain.")
	var heal_ability := _find_enemy_ability(unit, "cure", "ally")
	if hp_ratio <= 0.35 and not heal_ability.is_empty() and unit.mp >= int(heal_ability.get("mp_cost", 0)):
		return _enemy_intent(unit, "heal", unit, heal_ability.get("display_name", "Heal"), "Low HP - healing self.", heal_ability)
	if hp_ratio <= 0.28:
		var retreat_tile := _best_retreat_tile(unit, nearest)
		if retreat_tile != unit.grid_pos:
			return _enemy_intent(unit, "retreat", null, "Retreat", "Low HP - falling back from %s." % nearest.display_name, {}, retreat_tile)
	var kill_spell := _find_kill_spell(unit)
	if not kill_spell.is_empty():
		return kill_spell
	var kill_target := _find_kill_attack(unit)
	if kill_target:
		return _enemy_intent(unit, "attack", kill_target, "Finish", "Can defeat %s." % kill_target.display_name)
	var spell_intent := _find_best_spell_intent(unit)
	if not spell_intent.is_empty():
		return spell_intent
	if GridSystem.manhattan(unit.grid_pos, nearest.grid_pos) <= unit.unit_data.base_stats.attack_range_max:
		return _enemy_intent(unit, "attack", nearest, "Attack", "Basic attack on %s." % nearest.display_name)
	var advance_tile := _best_advance_tile(unit, nearest)
	if advance_tile != unit.grid_pos:
		var can_attack_after_advance := GridSystem.manhattan(advance_tile, nearest.grid_pos) <= unit.unit_data.base_stats.attack_range_max
		var advance_action := "Advance + Attack" if can_attack_after_advance else "Advance"
		var advance_note := "Will move then attack %s." % nearest.display_name if can_attack_after_advance else "Moving toward %s." % nearest.display_name
		return _enemy_intent(unit, "advance", nearest, advance_action, advance_note, {}, advance_tile)
	return _enemy_intent(unit, "hold", nearest, "Hold", "No useful action.")


func _enemy_intent(unit: Unit, kind: String, target: Unit, action_name: String, note: String,
		ability: Dictionary = {}, move_to: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var target_name := target.display_name if target else "-"
	var summary := "%s intends to %s" % [unit.display_name, action_name.to_lower()]
	if target:
		summary += " -> %s" % target.display_name
	var details := _enemy_intent_details(unit, kind, target, ability, move_to)

	# Determine element for display purposes
	var element := "physical"
	var element_icon := "P"
	if kind == "spell" and not ability.is_empty():
		element = CombatFormula.normalize_element(str(ability.get("spell_type", "fire")))
		element_icon = ForecastCalculator.ELEMENT_ICONS.get(element, "?")
	elif kind == "heal":
		element = "heal"
		element_icon = ForecastCalculator.ELEMENT_ICONS.get("heal", "+")

	return {
		"actor": unit.display_name,
		"actor_id": unit.unit_id,
		"kind": kind,
		"target_id": target.unit_id if target else "",
		"target": target_name,
		"action": action_name,
		"note": note,
		"details": details,
		"summary": summary,
		"ability": ability,
		"move_to": move_to,
		"danger": _enemy_intent_danger(kind, target, details),
		"element": element,
		"element_icon": element_icon,
		"damage": details.get("damage", 0),
	}


func _enemy_intent_details(unit: Unit, kind: String, target: Unit, ability: Dictionary = {},
		move_to: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var details := {
		"damage": 0,
		"hit_pct": 100,
		"crit_pct": 0,
		"range": 0,
		"target_hp_after": -1,
		"can_ko": false,
		"move_label": "",
		"element": "physical",
		"affinity_label": "",
	}
	if not unit or not target:
		if move_to.x >= 0:
			details["move_label"] = "Move to %d,%d" % [move_to.x, move_to.y]
		return details
	var origin := unit.grid_pos
	var attack_pos := origin
	if move_to.x >= 0:
		attack_pos = move_to
		details["move_label"] = "Move to %d,%d" % [move_to.x, move_to.y]
	details["range"] = GridSystem.manhattan(attack_pos, target.grid_pos)
	if kind == "advance" and int(details["range"]) > unit.unit_data.base_stats.attack_range_max:
		return details
	if kind == "attack" or kind == "advance":
		var tile_att := tactical_grid.get_tile(attack_pos)
		var tile_tar := tactical_grid.get_tile(target.grid_pos)
		var formula := CombatFormula.calculate_physical_attack(unit, target, tile_att, tile_tar)
		details["damage"] = int(formula.get("hp_damage", formula.get("incoming_damage", 0)))
		details["hit_pct"] = int(formula.get("hit_pct", 88))
		details["crit_pct"] = int(formula.get("crit_pct", 0))
		details["target_hp_after"] = max(target.hp - int(details["damage"]), 0)
		details["can_ko"] = int(details["damage"]) >= target.hp
		details["affinity_label"] = str(formula.get("facing_label", "front")).capitalize()
		details["modifier_breakdown"] = _intent_formula_breakdown(formula, "physical")
	elif kind == "spell" and not ability.is_empty():
		var spell_type: String = CombatFormula.normalize_element(str(ability.get("spell_type", "fire")))
		var formula := {}
		if spell_type == "physical":
			formula = CombatFormula.calculate_physical_attack(unit, target, tactical_grid.get_tile(unit.grid_pos), tactical_grid.get_tile(target.grid_pos))
		else:
			var base_power: int = int(ability.get("base_power", 100))
			var bonuses: Dictionary = RunBonusesUtil.for_current_run()
			var el_mult: float = float(bonuses["elemental_mult"].get(spell_type, 1.0))
			el_mult *= CombatFormula.item_elemental_multiplier(unit, spell_type)
			formula = CombatFormula.calculate_magical_attack(unit, target, spell_type, base_power, {"power_mult": el_mult})
		details["element"] = spell_type
		if _ability_has_area_effect(ability):
			details["area_label"] = _ability_area_label(ability)
		details["damage"] = int(formula.get("hp_damage", formula.get("incoming_damage", 0)))
		details["hit_pct"] = int(formula.get("hit_pct", 100))
		details["crit_pct"] = int(formula.get("crit_pct", 0))
		details["target_hp_after"] = max(target.hp - int(details["damage"]), 0)
		details["can_ko"] = int(details["damage"]) >= target.hp
		details["affinity_label"] = str(formula.get("affinity_label", ""))
		details["modifier_breakdown"] = _intent_formula_breakdown(formula, spell_type)
	elif kind == "heal":
		var heal_formula := CombatFormula.calculate_heal(unit, int(ability.get("base_power", 100)), 0)
		details["damage"] = -int(heal_formula.get("heal", 0))
		details["target_hp_after"] = min(target.hp + int(heal_formula.get("heal", 0)), target.unit_data.base_stats.hp)
	return details


func _enemy_intent_danger(kind: String, target: Unit, details: Dictionary) -> String:
	if kind in ["hold", "retreat"]:
		return "low"
	if bool(details.get("can_ko", false)):
		return "lethal"
	if target and int(details.get("damage", 0)) >= int(ceil(float(max(target.hp, 1)) * 0.50)):
		return "high"
	if kind == "advance":
		return "medium"
	return "normal"


func _ability_has_area_effect(ability: Dictionary) -> bool:
	return not str(ability.get("aoe_type", "")).is_empty() or int(ability.get("aoe_radius", 0)) > 0


func _ability_area_label(ability: Dictionary) -> String:
	var aoe_type: String = str(ability.get("aoe_type", ""))
	if aoe_type == "chain":
		return "Chain"
	if not aoe_type.is_empty():
		return aoe_type.capitalize()
	if int(ability.get("aoe_radius", 0)) > 0:
		return "Area"
	return ""


func _ability_target_in_range(unit: Unit, target: Unit, ability: Dictionary) -> bool:
	if not unit or not target:
		return false
	var distance := GridSystem.manhattan(unit.grid_pos, target.grid_pos)
	var max_range := int(ability.get("range", ability.get("attack_range_max", 1)))
	var min_range := int(ability.get("min_range", ability.get("attack_range_min", 0)))
	return distance >= min_range and distance <= max_range


func _intent_formula_breakdown(formula: Dictionary, element: String) -> Array[String]:
	var parts: Array[String] = []
	for item in formula.get("explain", []):
		var text: String = str(item)
		if not text.is_empty() and text not in parts:
			parts.append(text)
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	if element != "physical" and bonuses.has("elemental_mult") and bonuses["elemental_mult"] is Dictionary:
		var element_mult: float = float(bonuses["elemental_mult"].get(element, 1.0))
		if element_mult != 1.0:
			var boon_label := "Boon %s %+d%%" % [element.capitalize(), int(round((element_mult - 1.0) * 100.0))]
			if boon_label not in parts:
				parts.append(boon_label)
	return parts


func _emit_enemy_intent_board() -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	var rows: Array[Dictionary] = []
	for uid in units:
		var enemy := _living_unit(str(uid))
		if not enemy or enemy.team != "enemy":
			continue
		var intent: Dictionary = _evaluate_enemy_intent(enemy)
		_last_enemy_intents[enemy.unit_id] = intent
		rows.append(intent)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _intent_sort_score(a) > _intent_sort_score(b))
	enemy_intent_changed.emit({
		"kind": "board",
		"actor": "Enemy Plans",
		"rows": rows,
		"summary": "Enemy plans visible",
	})


func _intent_sort_score(intent: Dictionary) -> int:
	var danger := str(intent.get("danger", "normal"))
	var score: int = int({"lethal": 400, "high": 300, "normal": 200, "medium": 150, "low": 50}.get(danger, 100))
	var details: Dictionary = intent.get("details", {})
	score += int(details.get("damage", 0))
	if str(intent.get("kind", "")) == "spell":
		score += 20
	return score


func _execute_enemy_intent(unit: Unit, intent: Dictionary) -> void:
	if not unit or unit.hp <= 0:
		return
	intent = _validated_enemy_intent(unit, intent)
	_last_enemy_intents[unit.unit_id] = intent
	enemy_intent_changed.emit(intent)
	command_hint_changed.emit(str(intent.get("summary", "Enemy is acting...")))
	match str(intent.get("kind", "hold")):
		"heal":
			var heal_ability: Dictionary = intent.get("ability", {})
			if not heal_ability.is_empty():
				_execute_ability(unit, unit, heal_ability)
				active_unit_has_acted = true
		"retreat":
			await _enemy_move_to(unit, _intent_move_to(intent, unit.grid_pos), "%s retreats to recover." % unit.display_name)
		"spell":
			var target: Unit = units.get(str(intent.get("target_id", "")))
			var ability: Dictionary = intent.get("ability", {})
			if target and target.hp > 0 and not ability.is_empty():
				last_ability_used = ability.get("display_name", "an ability")
				if _ability_has_area_effect(ability):
					_execute_aoe_ability(unit, target.grid_pos, ability)
				else:
					_execute_ability(unit, target, ability)
				active_unit_has_acted = true
		"attack":
			var attack_target: Unit = units.get(str(intent.get("target_id", "")))
			if attack_target and attack_target.hp > 0:
				_enemy_attack(unit, attack_target)
		"advance":
			var chase_target: Unit = units.get(str(intent.get("target_id", "")))
			var moved: bool = await _enemy_move_to(unit, _intent_move_to(intent, unit.grid_pos), "%s advances." % unit.display_name)
			if chase_target and chase_target.hp > 0 and GridSystem.manhattan(unit.grid_pos, chase_target.grid_pos) <= unit.unit_data.base_stats.attack_range_max:
				_enemy_attack(unit, chase_target, true)
			elif moved:
				log_message.emit("%s cannot reach an attack after advancing." % unit.display_name)
		_:
			log_message.emit("%s holds." % unit.display_name)


func _validated_enemy_intent(unit: Unit, intent: Dictionary) -> Dictionary:
	if _enemy_intent_is_valid(unit, intent):
		intent["validated"] = true
		return intent
	var replanned: Dictionary = _evaluate_enemy_intent(unit)
	if not _enemy_intent_is_valid(unit, replanned):
		replanned = _enemy_intent(unit, "hold", null, "Hold", "No valid action after reassessing.")
	replanned["replanned"] = true
	replanned["previous_kind"] = str(intent.get("kind", ""))
	log_message.emit("%s reassesses the battlefield." % unit.display_name)
	return replanned


func _enemy_intent_is_valid(unit: Unit, intent: Dictionary) -> bool:
	if not unit or unit.hp <= 0:
		return false
	var kind: String = str(intent.get("kind", "hold"))
	match kind:
		"hold":
			return true
		"heal":
			var heal_ability: Dictionary = intent.get("ability", {})
			var max_hp: int = unit.unit_data.base_stats.hp if unit.unit_data else unit.hp
			return not heal_ability.is_empty() and unit.mp >= int(heal_ability.get("mp_cost", 0)) and unit.hp > 0 and unit.hp < max_hp
		"retreat":
			var retreat_pos: Vector2i = _intent_move_to(intent, unit.grid_pos)
			var retreat_max_hp: int = unit.unit_data.base_stats.hp if unit.unit_data else unit.hp
			var hp_ratio: float = float(unit.hp) / float(max(retreat_max_hp, 1))
			return hp_ratio <= 0.28 and _enemy_move_tile_is_valid(unit, retreat_pos)
		"attack":
			var attack_target: Unit = units.get(str(intent.get("target_id", "")))
			return attack_target != null and attack_target.hp > 0 and attack_target.team == "player" \
				and GridSystem.manhattan(unit.grid_pos, attack_target.grid_pos) <= unit.unit_data.base_stats.attack_range_max
		"advance":
			var chase_target: Unit = units.get(str(intent.get("target_id", "")))
			var advance_pos: Vector2i = _intent_move_to(intent, unit.grid_pos)
			var details: Dictionary = intent.get("details", {})
			if chase_target and int(details.get("damage", 0)) > 0 \
					and GridSystem.manhattan(advance_pos, chase_target.grid_pos) > unit.unit_data.base_stats.attack_range_max:
				return false
			return chase_target != null and chase_target.hp > 0 and chase_target.team == "player" \
				and _enemy_move_tile_is_valid(unit, advance_pos)
		"spell":
			var spell_target: Unit = units.get(str(intent.get("target_id", "")))
			var ability: Dictionary = intent.get("ability", {})
			if not spell_target or spell_target.hp <= 0 or spell_target.team != "player" or ability.is_empty():
				return false
			if str(ability.get("target_type", "enemy")) != "enemy":
				return false
			if unit.mp < int(ability.get("mp_cost", 0)):
				return false
			return _ability_target_in_range(unit, spell_target, ability)
	return false


func _intent_move_to(intent: Dictionary, fallback: Vector2i) -> Vector2i:
	var raw: Variant = intent.get("move_to", fallback)
	if raw is Vector2i:
		return raw
	return fallback


func _enemy_move_tile_is_valid(unit: Unit, pos: Vector2i) -> bool:
	if pos == unit.grid_pos:
		return true
	if not tactical_grid.tiles.has(pos):
		return false
	var tile: Dictionary = tactical_grid.get_tile(pos)
	if bool(tile.get("blocks_movement", false)):
		return false
	for uid in units:
		var other: Unit = _living_unit(str(uid))
		if other and other.unit_id != unit.unit_id and other.hp > 0 and other.grid_pos == pos:
			return false
	return true


func _enemy_attack(unit: Unit, target: Unit, after_move: bool = false) -> void:
	_face_toward(unit, target.grid_pos)
	var tile_att := tactical_grid.get_tile(unit.grid_pos)
	var tile_tar := tactical_grid.get_tile(target.grid_pos)
	last_ability_used = "a basic attack"
	var result := combat_resolver.resolve_attack(unit, target, tile_att, tile_tar)
	active_unit_has_acted = true
	if result.get("missed", false):
		log_message.emit("%s attacks but misses!" % unit.display_name)
	else:
		var verb := "moves in and hits" if after_move else "hits"
		log_message.emit("%s %s %s for %d dmg!" % [unit.display_name, verb, target.display_name, result.get("hp_damage", 0)])
	if result.get("counter", false):
		_timer(0.6).timeout.connect(func() -> void: _execute_counter_attack(target, unit))


func _enemy_move_to(unit: Unit, pos: Vector2i, message: String) -> bool:
	if pos == unit.grid_pos or not tactical_grid.tiles.has(pos):
		return false
	if not _enemy_move_tile_is_valid(unit, pos):
		log_message.emit("%s cannot move to the planned tile." % unit.display_name)
		return false
	var old_pos := unit.grid_pos
	unit.move_to(pos)
	log_message.emit(message)
	unit_moved.emit(unit.unit_id, old_pos, pos)
	await tactical_grid.move_unit_visual(unit.unit_id, old_pos, pos)
	await _timer(0.20).timeout
	active_unit_has_moved = true
	return true


func _nearest_player(unit: Unit) -> Unit:
	var best: Unit = null
	var best_dist := 9999
	for uid: String in units.keys():
		var candidate := _living_unit(uid)
		if not candidate or candidate.team != "player":
			continue
		var dist := GridSystem.manhattan(unit.grid_pos, candidate.grid_pos)
		if dist < best_dist:
			best_dist = dist
			best = candidate
	return best


func _find_enemy_ability(unit: Unit, spell_type: String, target_type: String = "") -> Dictionary:
	for ab_id: String in unit.unit_data.abilities:
		var ability := AbilityDB.get_ability(ab_id)
		if ability.get("spell_type", "") != spell_type:
			continue
		if target_type != "" and ability.get("target_type", "enemy") != target_type:
			continue
		return ability
	return {}


func _find_kill_attack(unit: Unit) -> Unit:
	for uid in units:
		var target: Unit = _living_unit(str(uid))
		if not target:
			continue
		if target.team != "player" or target.hp <= 0:
			continue
		if GridSystem.manhattan(unit.grid_pos, target.grid_pos) > unit.unit_data.base_stats.attack_range_max:
			continue
		var amount := _predict_attack_damage(unit, target, tactical_grid.get_tile(unit.grid_pos), tactical_grid.get_tile(target.grid_pos))
		if amount >= target.hp:
			return target
	return null


func _find_kill_spell(unit: Unit) -> Dictionary:
	for uid in units:
		var target: Unit = _living_unit(str(uid))
		if not target:
			continue
		if target.team != "player" or target.hp <= 0:
			continue
		for ab_id: String in unit.unit_data.abilities:
			var ability := AbilityDB.get_ability(ab_id)
			if ability.get("target_type", "enemy") != "enemy" or ability.get("spell_type", "") == "cure":
				continue
			if unit.mp < int(ability.get("mp_cost", 0)):
				continue
			if not _ability_target_in_range(unit, target, ability):
				continue
			var amount := _predict_spell_damage(unit, target, ability)
			if amount >= target.hp:
				return _enemy_intent(unit, "spell", target, ability.get("display_name", ab_id), "Can defeat %s." % target.display_name, ability)
	return {}


func _find_best_spell_intent(unit: Unit) -> Dictionary:
	var best_target: Unit = null
	var best_ability: Dictionary = {}
	var best_score := -1
	for uid in units:
		var target: Unit = _living_unit(str(uid))
		if not target:
			continue
		if target.team != "player" or target.hp <= 0:
			continue
		for ab_id: String in unit.unit_data.abilities:
			var ability := AbilityDB.get_ability(ab_id)
			if ability.get("target_type", "enemy") != "enemy" or ability.get("spell_type", "") == "cure":
				continue
			if unit.mp < int(ability.get("mp_cost", 0)):
				continue
			if not _ability_target_in_range(unit, target, ability):
				continue
			var score := _predict_spell_damage(unit, target, ability) + (target.unit_data.base_stats.hp - target.hp)
			if score > best_score:
				best_score = score
				best_target = target
				best_ability = ability
	if best_target and not best_ability.is_empty():
		return _enemy_intent(unit, "spell", best_target, best_ability.get("display_name", "Spell"), "Best spell target.", best_ability)
	return {}


func _best_advance_tile(unit: Unit, target: Unit) -> Vector2i:
	return _best_reachable_tile(unit, target, false)


func _best_retreat_tile(unit: Unit, target: Unit) -> Vector2i:
	return _best_reachable_tile(unit, target, true)


func _best_reachable_tile(unit: Unit, target: Unit, maximize_distance: bool) -> Vector2i:
	var occupied: Array = []
	for uid in units:
		var other: Unit = _living_unit(str(uid))
		if not other:
			continue
		if other.unit_id != unit.unit_id and other.hp > 0:
			occupied.append(other.grid_pos)
	var reachable := GridSystem.get_move_range(unit.grid_pos, unit.unit_data.base_stats.move, tactical_grid.tiles, occupied, map_data.map_width, map_data.map_height, unit.unit_data.base_stats.jump)
	var best_tile := unit.grid_pos
	var best_dist := GridSystem.manhattan(unit.grid_pos, target.grid_pos)
	for tile_pos in reachable:
		var dist := GridSystem.manhattan(tile_pos, target.grid_pos)
		if maximize_distance and dist > best_dist:
			best_dist = dist
			best_tile = tile_pos
		elif not maximize_distance and dist < best_dist:
			best_dist = dist
			best_tile = tile_pos
	return best_tile


func _run_auto_player_turn(unit_id: String) -> void:
	await _timer(0.18).timeout
	if not auto_battle_enabled or current_phase != Phase.PLAYER_TURN or active_unit_id != unit_id:
		return
	var unit := _living_unit(unit_id)
	if not unit:
		return
	log_message.emit("AUTO: %s takes the fastest useful action." % unit.display_name)
	if await _auto_try_attack(unit):
		return
	var target := _nearest_enemy(unit)
	if target and not active_unit_has_moved:
		var move_to := _best_auto_move_tile(unit, target)
		if move_to != unit.grid_pos:
			select_command("move")
			await _timer(0.10).timeout
			if current_phase != Phase.PLAYER_TURN or active_unit_id != unit_id:
				return
			await _on_tile_clicked(move_to)
			await _timer(0.14).timeout
			unit = _living_unit(unit_id)
			if not unit or current_phase != Phase.PLAYER_TURN or active_unit_id != unit_id:
				return
	if await _auto_try_attack(unit):
		return
	select_command("wait")


func _auto_try_attack(unit: Unit) -> bool:
	if not unit or active_unit_has_acted:
		return false
	select_command("attack")
	await _timer(0.08).timeout
	if current_phase != Phase.PLAYER_TURN or active_unit_id != unit.unit_id:
		return true
	var target := _best_auto_attack_target(unit)
	if not target:
		active_command = ""
		tactical_grid.clear_highlights()
		return false
	action_preview_changed.emit(_attack_preview_for_tile(target.grid_pos))
	await _timer(0.10).timeout
	_on_unit_clicked(target.unit_id)
	return true


func _best_auto_attack_target(unit: Unit) -> Unit:
	var best: Unit = null
	var best_score := -999999.0
	for uid: String in units.keys():
		var target := _living_unit(uid)
		if not target or target.team == unit.team:
			continue
		var dist := GridSystem.manhattan(unit.grid_pos, target.grid_pos)
		if dist < unit.unit_data.base_stats.attack_range_min or dist > unit.unit_data.base_stats.attack_range_max:
			continue
		var damage := _predict_attack_damage(unit, target, tactical_grid.get_tile(unit.grid_pos), tactical_grid.get_tile(target.grid_pos))
		var score := float(damage) + float(target.unit_data.base_stats.hp - target.hp) * 0.15
		if damage >= target.hp:
			score += 1000.0
		score -= float(dist) * 2.0
		if score > best_score:
			best_score = score
			best = target
	return best


func _nearest_enemy(unit: Unit) -> Unit:
	var best: Unit = null
	var best_dist := 999999
	for uid: String in units.keys():
		var target := _living_unit(uid)
		if not target or target.team == unit.team:
			continue
		var dist := GridSystem.manhattan(unit.grid_pos, target.grid_pos)
		if dist < best_dist:
			best_dist = dist
			best = target
	return best


func _best_auto_move_tile(unit: Unit, _target: Unit) -> Vector2i:
	var occupied: Array = []
	for uid: String in units.keys():
		var other := _living_unit(uid)
		if other and other.unit_id != unit.unit_id:
			occupied.append(other.grid_pos)
	var reachable := GridSystem.get_move_range(
		unit.grid_pos, unit.unit_data.base_stats.move,
		tactical_grid.tiles, occupied, map_data.map_width, map_data.map_height,
		unit.unit_data.base_stats.jump
	)
	var best_tile := unit.grid_pos
	var best_score := -999999.0
	for tile_pos: Vector2i in reachable:
		var nearest_after := _nearest_enemy_from_tile(unit, tile_pos)
		if not nearest_after:
			continue
		var dist := GridSystem.manhattan(tile_pos, nearest_after.grid_pos)
		var in_range := dist >= unit.unit_data.base_stats.attack_range_min and dist <= unit.unit_data.base_stats.attack_range_max
		var score := -float(dist) * 10.0
		if in_range:
			score += 500.0
			score += float(_predict_attack_damage(unit, nearest_after, tactical_grid.get_tile(tile_pos), tactical_grid.get_tile(nearest_after.grid_pos)))
		var tile: Dictionary = tactical_grid.get_tile(tile_pos)
		score += float(tile.get("height", 0)) * 2.0
		if score > best_score:
			best_score = score
			best_tile = tile_pos
	return best_tile


func _nearest_enemy_from_tile(unit: Unit, tile_pos: Vector2i) -> Unit:
	var best: Unit = null
	var best_dist := 999999
	for uid: String in units.keys():
		var target := _living_unit(uid)
		if not target or target.team == unit.team:
			continue
		var dist := GridSystem.manhattan(tile_pos, target.grid_pos)
		if dist < best_dist:
			best_dist = dist
			best = target
	return best

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
	_play_sfx("victory", -2.0)
	log_message.emit("VICTORY! +%dg +%dJP" % [map_data.reward_gold, map_data.reward_jp])
	battle_won.emit(rewards)


#  Player commands

func _handle_defeat() -> void:
	_play_sfx("defeat", -2.0)
	battle_lost.emit()


func _play_sfx(sfx_id: String, volume_db: float = 0.0) -> void:
	var audio := get_node_or_null("/root/AudioSettings")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(sfx_id, volume_db)


func _emit_action_state() -> void:
	action_state_changed.emit(
		current_phase == Phase.PLAYER_TURN and not active_unit_has_moved,
		current_phase == Phase.PLAYER_TURN and not active_unit_has_acted,
		false
	)


func confirm_pending_action() -> void:
	_emit_action_state()


func cancel_pending_action() -> void:
	action_preview_changed.emit({})
	tactical_grid.clear_target_lock()
	command_hint_changed.emit("Cancelled. Choose Move, Attack, Ability, or Wait.")
	_emit_action_state()

func select_command(command: String) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	var unit: Unit = _living_unit(active_unit_id)
	if not unit:
		return
	if command == "move" and active_unit_has_moved:
		log_message.emit("%s has already moved." % unit.display_name)
		command_hint_changed.emit("Choose Attack, Ability, or Wait.")
		return
	if command in ["attack", "ability"] and active_unit_has_acted:
		log_message.emit("%s has already acted." % unit.display_name)
		command_hint_changed.emit("Choose Move or Wait.")
		return
	active_command = command
	tactical_grid.clear_target_lock()
	match command:
		"move":
			command_hint_changed.emit("Move: click a blue GO tile.")
			var occupied: Array = []
			for uid in units:
				var u: Unit = _living_unit(str(uid))
				if not u:
					continue
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
			if active_unit_has_acted:
				return
			command_hint_changed.emit("Attack: click an orange enemy tile.")
			var atk_min: int = unit.unit_data.base_stats.attack_range_min
			var atk_max: int = unit.unit_data.base_stats.attack_range_max
			var atk_range := GridSystem.get_attack_range(
				unit.grid_pos, atk_min, atk_max, map_data.map_width, map_data.map_height
			)
			attack_range_ready.emit(atk_range)
			tactical_grid.show_attack_range(atk_range)
		"wait":
			command_hint_changed.emit("Waiting...")
			_end_player_turn()
		"ability":
			if active_unit_has_acted:
				return
			command_hint_changed.emit("Ability: choose a spell, then click a purple CAST tile or target.")
			var ab_unit: Unit = _living_unit(active_unit_id)
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
	var unit: Unit = _living_unit(active_unit_id)
	if not unit:
		return
	if active_unit_has_acted:
		log_message.emit("%s has already acted." % unit.display_name)
		return
	var ability: Dictionary = AbilityDB.get_ability(ability_id)
	if unit.mp < ability.get("mp_cost", 0):
		log_message.emit("Not enough MP!")
		return
	selected_ability_id = ability_id
	active_command = "ability_target"
	command_hint_changed.emit("%s: click a purple CAST tile or target." % ability.get("display_name", ability_id))
	var range_val: int = ability.get("range", 1)
	var target_type: String = ability.get("target_type", "enemy")
	# Self-cast or range-0  resolve immediately on the caster's tile
	if target_type == "self" or range_val == 0:
		if ability.has("aoe_type"):
			_execute_aoe_ability(unit, unit.grid_pos, ability)
		else:
			_execute_ability(unit, unit, ability)
		active_unit_has_acted = true
		_end_player_turn()
		return
	var ab_range := GridSystem.get_attack_range(
		unit.grid_pos, ability.get("min_range", 1), range_val, map_data.map_width, map_data.map_height
	)
	tactical_grid.show_ability_range(ab_range)


#  Ability execution

## Execute ability against a single target.
## skip_setup=true skips MP deduction, UI cleanup, and per-target log spam (used by AoE wrapper).
func _execute_ability(caster: Unit, target: Unit, ability: Dictionary,
		skip_setup: bool = false) -> void:
	if target and target.grid_pos != caster.grid_pos:
		_face_toward(caster, target.grid_pos)
	if not skip_setup:
		caster.mp = max(caster.mp - ability.get("mp_cost", 0), 0)
		tactical_grid.clear_highlights()
		active_command = ""
		selected_ability_id = ""

	var spell_type: String = ability.get("spell_type", "fire")
	var base_power:  int   = ability.get("base_power", 100)
	var ab_name:     String = ability.get("display_name", "?")

	#  Buff abilities (Haste, Protect, )
	if spell_type == "buff":
		var se_data: Dictionary = ability.get("status_effect", {})
		var vfx_node := get_node_or_null("/root/VFX")
		if vfx_node and not se_data.is_empty():
			var vfx := vfx_node as VFXManager
			match se_data.get("id", ""):
				"haste":   vfx.play_haste(target.grid_pos)
				"protect": vfx.play_protect(target.grid_pos)
				_:         vfx.play_aura(target.grid_pos, Color(0.6, 0.8, 1.0))
		if not se_data.is_empty():
			_timer(0.25).timeout.connect(
				func() -> void: _try_apply_status(target, se_data))
		if not skip_setup:
			log_message.emit("%s casts %s on %s!" % [caster.display_name, ab_name, target.display_name])
		return

	#  Heal
	if spell_type == "cure":
		combat_resolver.resolve_heal(caster, target, base_power)
		if not skip_setup:
			log_message.emit("%s uses %s on %s!" % [caster.display_name, ab_name, target.display_name])
		return

	#  Physical
	if spell_type == "physical":
		var tile_c := tactical_grid.get_tile(caster.grid_pos)
		var tile_t := tactical_grid.get_tile(target.grid_pos)
		var ab_vfx: String = ability.get("vfx_mode", "slash")
		var result := combat_resolver.resolve_attack(caster, target, tile_c, tile_t, ab_vfx)
		if not skip_setup:
			if result.get("missed", false):
				log_message.emit("%s swings but misses! (blind)" % caster.display_name)
			else:
				log_message.emit("%s uses %s!" % [caster.display_name, ab_name])
		if result.get("counter", false):
			_timer(0.6).timeout.connect(
				func() -> void: _execute_counter_attack(target, caster))
		# Status after hit
		var se_data: Dictionary = ability.get("status_effect", {})
		if not se_data.is_empty():
			_timer(0.3).timeout.connect(
				func() -> void: _try_apply_status(target, se_data))
		# JP award for physical ability
		if not skip_setup:
			_award_jp(caster, "action_used")
		# Volatile explosion on kill
		if target.hp <= 0:
			_check_volatile_explosion(target)
			_check_boon_on_kill(caster, target)
		return

	#  Spell (elemental / dark / etc.)
	combat_resolver.resolve_spell(caster, target, spell_type, base_power)
	# Terrain ignite regardless of skip_setup
	if spell_type == "fire":
		var tgt_terrain: String = tactical_grid.get_tile(target.grid_pos).get("terrain", "")
		if tgt_terrain in ["grass", "road"]:
			tactical_grid.ignite_tile(target.grid_pos)
			if not skip_setup:
				log_message.emit("The ground catches fire!")
		# JP award for spell + weakness bonus
		if not skip_setup:
			_award_jp(caster, "action_used")
		# On kill checks
		if target.hp <= 0:
			_check_volatile_explosion(target)
			_check_boon_on_kill(caster, target)
			if not skip_setup: _award_jp(caster, "boss_clear" if target.has_meta("is_boss") else "battle_clear")

	if not skip_setup:
		var affinity: float = 1.0
		if target.unit_data:
			affinity = target.unit_data.elemental_affinities.get(spell_type, 1.0)
		var affinity_tag := ""
		if affinity == 0.0:   affinity_tag = " [IMMUNE]"
		elif affinity >= 1.5: affinity_tag = " [WEAK!]"
		elif affinity > 1.0:  affinity_tag = " [weak]"
		elif affinity < 1.0:  affinity_tag = " [resist]"
		log_message.emit("%s casts %s on %s!%s" % [caster.display_name, ab_name, target.display_name, affinity_tag])
	# Status
	var se_data2: Dictionary = ability.get("status_effect", {})
	if not se_data2.is_empty():
		_timer(0.3).timeout.connect(
			func() -> void: _try_apply_status(target, se_data2))


## Execute an AoE ability centred on a grid tile.
## Deducts MP once, logs once, then hits every valid unit in the pattern.
func _execute_aoe_ability(caster: Unit, center: Vector2i, ability: Dictionary) -> void:
	if center != caster.grid_pos:
		_face_toward(caster, center)
	caster.mp = max(caster.mp - ability.get("mp_cost", 0), 0)
	tactical_grid.clear_highlights()
	active_command = ""
	selected_ability_id = ""
	var ab_name: String   = ability.get("display_name", "?")
	var aoe_type: String  = ability.get("aoe_type", "")
	log_message.emit("%s uses %s!" % [caster.display_name, ab_name])

	#  Chain: ordered hops with damage falloff
	if aoe_type == "chain":
		var chain_targets := _chain_targets(center, ability, caster)
		if chain_targets.is_empty():
			log_message.emit("(no target to chain from)")
			return
		var falloff: float = ability.get("chain_falloff", 0.40)
		var power_mult     := 1.0
		for i: int in range(chain_targets.size()):
			var tgt: Unit = chain_targets[i]
			var chain_ab  := ability.duplicate()
			chain_ab["base_power"] = int(float(ability.get("base_power", 100)) * power_mult)
			_execute_ability(caster, tgt, chain_ab, i > 0)  # skip_setup on hops
			if i == 0:
				log_message.emit("%s - %d dmg" % [tgt.display_name, chain_ab["base_power"]])
			else:
				log_message.emit("arcs to %s - %d dmg" % [tgt.display_name, chain_ab["base_power"]])
			power_mult *= (1.0 - falloff)
		return

	#  All other shapes
	var aoe_targets := _get_aoe_targets(center, ability, caster)
	if aoe_targets.is_empty():
		log_message.emit("(no targets in burst)")
		return
	for tgt: Unit in aoe_targets:
		_execute_ability(caster, tgt, ability, true)


## Returns the unit step in the dominant axis from `from` toward `to`.
func _forward_dir(from: Vector2i, to: Vector2i) -> Vector2i:
	var dx := to.x - from.x
	var dy := to.y - from.y
	if dx == 0 and dy == 0:
		return Vector2i(1, 0)
	if abs(dx) >= abs(dy):
		return Vector2i(sign(dx), 0)
	return Vector2i(0, sign(dy))


## Returns the perpendicular unit step to the cast direction.
func _perp_dir(from: Vector2i, to: Vector2i) -> Vector2i:
	var fwd := _forward_dir(from, to)
	return Vector2i(-fwd.y, fwd.x)


## Returns the set of tiles affected by an AOE pattern.
## Used by both _get_aoe_targets (for unit lookup) and the hover preview.
func _aoe_tiles(center: Vector2i, ability: Dictionary, caster: Unit) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	match ability.get("aoe_type", ""):

		"radius":
			var radius: int = ability.get("aoe_radius", 1)
			for dx: int in range(-radius, radius + 1):
				for dy: int in range(-radius, radius + 1):
					var c := center + Vector2i(dx, dy)
					if GridSystem.manhattan(c, center) <= radius and tactical_grid.get_tile(c) != {}:
						result.append(c)

		"fan":
			# Primary tile + N tiles to each side perpendicular to cast direction.
			# fan_width controls how many tiles out each side; fan_depth adds rows forward.
			result.append(center)
			var perp  := _perp_dir(caster.grid_pos, center)
			var width: int = ability.get("fan_width", 1)
			for i in range(1, width + 1):
				var t1 := center + perp * i
				var t2 := center - perp * i
				if tactical_grid.get_tile(t1) != {}: result.append(t1)
				if tactical_grid.get_tile(t2) != {}: result.append(t2)
			var depth: int = ability.get("fan_depth", 0)
			if depth > 0:
				var fwd := _forward_dir(caster.grid_pos, center)
				for d in range(1, depth + 1):
					var dc := center + fwd * d
					if tactical_grid.get_tile(dc) == {}: break
					result.append(dc)
					for i in range(1, width + 1):
						var t1 := dc + perp * i
						var t2 := dc - perp * i
						if tactical_grid.get_tile(t1) != {}: result.append(t1)
						if tactical_grid.get_tile(t2) != {}: result.append(t2)

		"cross":
			# Center + N tiles in each cardinal direction (cross_arm controls length).
			result.append(center)
			var arm: int = ability.get("cross_arm", 1)
			for off in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				for i in range(1, arm + 1):
					var c: Vector2i = center + off * i
					if tactical_grid.get_tile(c) == {}: break
					result.append(c)

		"line":
			# Pierce from center outward in the cast direction until map edge.
			var fwd   := _forward_dir(caster.grid_pos, center)
			var check := center
			var limit: int = ability.get("line_length", 12)
			for _i in range(limit):
				if tactical_grid.get_tile(check) == {}: break
				result.append(check)
				check += fwd

		"nova":
			# Erupts from the CASTER, not from center  dark/resonance self-detonation.
			var radius: int = ability.get("aoe_radius", 2)
			for dx: int in range(-radius, radius + 1):
				for dy: int in range(-radius, radius + 1):
					var c := caster.grid_pos + Vector2i(dx, dy)
					if GridSystem.manhattan(c, caster.grid_pos) <= radius and tactical_grid.get_tile(c) != {}:
						result.append(c)

		"chain":
			# Preview only: show primary tile + chain-reach ring around it.
			result.append(center)
			var chain_range: int = ability.get("chain_range", 2)
			for dx: int in range(-chain_range, chain_range + 1):
				for dy: int in range(-chain_range, chain_range + 1):
					var c := center + Vector2i(dx, dy)
					if GridSystem.manhattan(c, center) <= chain_range \
							and tactical_grid.get_tile(c) != {} \
							and not c in result:
						result.append(c)

	return result


## Returns ordered chain targets starting from `center` (primary must be a unit).
func _chain_targets(center: Vector2i, ability: Dictionary, caster: Unit) -> Array[Unit]:
	var result:      Array[Unit] = []
	var chain_range: int         = ability.get("chain_range", 2)
	var chain_count: int         = ability.get("chain_count", 1)
	var target_type: String      = ability.get("target_type", "enemy")
	# Primary target must be a living unit at center.
	var primary := _unit_at_pos(center)
	if not primary or primary.hp <= 0:
		return result
	var is_valid_target := (target_type == "enemy" and primary.team != caster.team) \
						or (target_type == "ally"  and primary.team == caster.team)
	if not is_valid_target:
		return result
	result.append(primary)
	var current_pos := primary.grid_pos
	# Chain hops.
	for _hop in range(chain_count):
		var best:      Unit = null
		var best_dist: int  = 9999
		for uid: String in units:
			var u: Unit = _living_unit(str(uid))
			if not u or u.hp <= 0 or u in result:
				continue
			var valid := (target_type == "enemy" and u.team != caster.team) \
					  or (target_type == "ally"  and u.team == caster.team)
			if not valid:
				continue
			var d := GridSystem.manhattan(u.grid_pos, current_pos)
			if d <= chain_range and d < best_dist:
				best      = u
				best_dist = d
		if best:
			result.append(best)
			current_pos = best.grid_pos
		else:
			break
	return result


## Returns every living unit that falls inside the AoE pattern centred on `center`.
func _get_aoe_targets(center: Vector2i, ability: Dictionary, caster: Unit) -> Array[Unit]:
	var result:      Array[Unit]    = []
	var target_type: String         = ability.get("target_type", "enemy")
	# Chain uses hop logic instead of tile-set lookup.
	if ability.get("aoe_type", "") == "chain":
		return _chain_targets(center, ability, caster)
	var tiles := _aoe_tiles(center, ability, caster)
	if tiles.is_empty():
		return result
	for uid: String in units:
		var u: Unit = _living_unit(str(uid))
		if not u or u.hp <= 0:
			continue
		if u.grid_pos not in tiles:
			continue
		var valid := (target_type == "enemy" and u.team != caster.team) \
				  or (target_type == "ally"  and u.team == caster.team)
		if valid:
			result.append(u)
	return result


## Melee counter-attack  never triggers a second counter (is_counter=true).
## Award JP to a unit via JobSystem. Multiplied by run boon JP bonus.
func _award_jp(unit: Unit, event_type: String) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if not gs: return
	var uid: String = unit.name
	if unit.unit_data:
		uid = unit.unit_data.id
	if not gs.unit_registry.has(uid): return
	var js := JobSystem.new()
	var base_jp: int = js.get_jp_award(event_type)
	if base_jp <= 0: return
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	var total_jp: int = int(ceil(float(base_jp) * bonuses["jp_multiplier"]))
	var char_data: Dictionary = gs.unit_registry[uid]
	var job_id: String = char_data.get("current_job_id", "")
	if job_id.is_empty(): return
	var result := js.apply_jp(char_data, job_id, total_jp)
	if result["leveled_up"]:
		log_message.emit("%s: %s reached %s!" % [unit.display_name, job_id.capitalize(), result["title"]])
		var vfx_n := get_node_or_null("/root/VFX")
		if vfx_n: (vfx_n as VFXManager).play_aura(unit.grid_pos, Color(0.9, 0.8, 0.2, 0.8))


## Handle Volatile prefix explosion on unit death.
func _check_volatile_explosion(dead_unit: Unit) -> void:
	if not dead_unit.has_meta("prefixes"): return
	var prefixes: Array = dead_unit.get_meta("prefixes", [])
	for pfx: Dictionary in prefixes:
		var od: Dictionary = pfx.get("on_death", {})
		if od.get("type","") != "explosion": continue
		var dmg: int = od.get("damage", 45)
		log_message.emit("%s EXPLODES! %d fire dmg to adjacent!" % [dead_unit.display_name, dmg])
		var dirs := [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),
					 Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]
		for d in dirs:
			var nb: Vector2i = dead_unit.grid_pos + d
			for uid: String in units.keys():
				var u: Unit = _living_unit(uid)
				if not u:
					continue
				if u.grid_pos == nb and u.hp > 0 and u != dead_unit:
					var _damage_result := u.receive_damage(dmg, "magical")
					var vfx_n := get_node_or_null("/root/VFX")
					if vfx_n:
						(vfx_n as VFXManager).play_fire(nb)
						(vfx_n as VFXManager).play_damage_number(nb, dmg, Color(1.0,0.35,0.1))


## Handle boon on-kill effects (Champion's Grit, Vaelthorn kills, Reaping Step).
func _check_boon_on_kill(killer: Unit, dead_unit: Unit) -> void:
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	var is_elite: bool = dead_unit.has_meta("elite_tier") and dead_unit.get_meta("elite_tier","") != ""
	if is_elite:
		# Champion's Grit: heal killer
		var hp_r: int   = bonuses["on_elite_kill_hp"]
		var tmpr_r: int = bonuses["on_elite_kill_tmpr"]
		if hp_r > 0 or tmpr_r > 0:
			if hp_r > 0:   killer.heal(hp_r)
			if tmpr_r > 0: killer.temper = mini(killer.unit_data.base_stats.max_temper, killer.temper + tmpr_r)
			log_message.emit("Champion's Grit: +%d HP, +%d Temper!" % [hp_r, tmpr_r])
	# Vaelthorn Unchained on-kill
	var ve_hp:    int = bonuses["vaelthorn_kill_hp"]
	var ve_ether: int = bonuses["vaelthorn_kill_ether"]
	if ve_hp > 0 or ve_ether > 0:
		if ve_hp > 0:    killer.heal(ve_hp)
		if ve_ether > 0: killer.ether = mini(killer.unit_data.base_stats.max_ether, killer.ether + ve_ether)
	var item_kill_hp: int = int(killer.get_meta("item_kill_hp", 0)) if killer.has_meta("item_kill_hp") else 0
	if item_kill_hp > 0 and killer.team == "player":
		killer.heal(item_kill_hp)
		log_message.emit("Item effect: %s recovers %d HP on kill." % [killer.display_name, item_kill_hp])
	# Reaping Step: grant free move on player kills
	if killer.team == "player" and bonuses.get("reaping_step_range", 0) > 0:
		_reaping_step_pending = true


func _execute_counter_attack(counter_unit: Unit, original_attacker: Unit) -> void:
	if not is_instance_valid(counter_unit) or counter_unit.hp <= 0:
		return
	if not is_instance_valid(original_attacker) or original_attacker.hp <= 0:
		return
	_face_toward(counter_unit, original_attacker.grid_pos)
	var tile_c := tactical_grid.get_tile(counter_unit.grid_pos)
	var tile_t := tactical_grid.get_tile(original_attacker.grid_pos)
	var result := combat_resolver.resolve_attack(
		counter_unit, original_attacker, tile_c, tile_t, "slash", true)
	if result.get("missed", false):
		log_message.emit("%s counters but misses!" % counter_unit.display_name)
	else:
		log_message.emit("%s counters! %d dmg" % [
			counter_unit.display_name, result.get("hp_damage", 0)])


func _try_enemy_spell(unit: Unit) -> bool:
	if unit.unit_data.abilities.is_empty():
		return false
	var ab_list: Array = unit.unit_data.abilities.duplicate()
	ab_list.shuffle()
	for ab_id: String in ab_list:
		var ab: Dictionary = AbilityDB.get_ability(ab_id)
		if unit.mp < ab.get("mp_cost", 0):
			continue
		var spell_range: int = ab.get("range", 1)
		# Self-cast AoE (range == 0)  cast on self immediately
		if spell_range == 0 and ab.has("aoe_type"):
			_execute_aoe_ability(unit, unit.grid_pos, ab)
			return true
		var target_type: String = ab.get("target_type", "enemy")
		for uid: String in units:
			var target: Unit = _living_unit(str(uid))
			if not target:
				continue
			if target.hp <= 0:
				continue
			var is_valid := (target_type == "enemy" and target.team == "player") or \
							(target_type == "ally" and target.team == unit.team and target != unit)
			if not is_valid:
				continue
			if GridSystem.manhattan(unit.grid_pos, target.grid_pos) <= spell_range:
				if ab.has("aoe_type"):
					_execute_aoe_ability(unit, target.grid_pos, ab)
				else:
					_execute_ability(unit, target, ab)
				return true
	return false


#  Input handlers

## Called every time the mouse crosses into a new grid tile.
## If an AoE ability is selected, paints the burst zone in red so the
## player can see exactly which tiles will be hit before committing.
func _on_tile_hovered(grid_pos: Vector2i) -> void:
	var tile: Dictionary = tactical_grid.get_tile(grid_pos)
	if not tile.is_empty():
		var occupant := _unit_at_pos(grid_pos)
		var occupant_text := ""
		if occupant:
			occupant_text = "  %s %d/%d HP" % [
				occupant.display_name,
				occupant.hp,
				occupant.unit_data.base_stats.hp if occupant.unit_data else occupant.hp,
			]
		var height_delta_text := ""
		var active := _living_unit(active_unit_id)
		if active and active.grid_pos != grid_pos:
			var active_tile := tactical_grid.get_tile(active.grid_pos)
			var height_delta: int = int(tile.get("height", 0)) - int(active_tile.get("height", 0))
			if height_delta != 0:
				height_delta_text = "  %+dH" % height_delta
		var hazard_text := _terrain_hazard_label(str(tile.get("terrain", "")))
		tile_info_changed.emit("%s  %d,%d  H:%d  Move:%d%s%s%s" % [
			str(tile.get("terrain", "unknown")).replace("_", " ").capitalize(),
			grid_pos.x,
			grid_pos.y,
			int(tile.get("height", 0)),
			int(tile.get("move_cost", 1)),
			height_delta_text,
			hazard_text,
			occupant_text,
		])
	if active_command == "move":
		action_preview_changed.emit(_move_preview(grid_pos))
		var mover: Unit = _living_unit(active_unit_id)
		if mover and grid_pos in tactical_grid.move_tiles:
			var occupied: Array = []
			for uid in units:
				var u: Unit = _living_unit(str(uid))
				if not u:
					continue
				if u.unit_id != mover.unit_id and u.hp > 0:
					occupied.append(u.grid_pos)
			var path := GridSystem.find_path(
				mover.grid_pos, grid_pos, tactical_grid.tiles, occupied,
				map_data.map_width, map_data.map_height
			)
			if path.size() > 1:
				path.pop_front()
			tactical_grid.show_path_preview(path)
		else:
			tactical_grid.clear_path_preview()
		return
	if active_command == "attack":
		var attack_preview := _attack_preview_for_tile(grid_pos)
		action_preview_changed.emit(attack_preview)
		if attack_preview.is_empty():
			tactical_grid.clear_target_lock()
		else:
			tactical_grid.show_target_lock(grid_pos)
		return
	if active_command != "ability_target" or selected_ability_id == "":
		action_preview_changed.emit({})
		tactical_grid.clear_target_lock()
		tactical_grid.clear_path_preview()
		tactical_grid.clear_aoe_preview()
		return
	var ability: Dictionary = AbilityDB.get_ability(selected_ability_id)
	var ability_preview := _ability_preview_for_tile(grid_pos, ability)
	action_preview_changed.emit(ability_preview)
	if ability_preview.is_empty():
		tactical_grid.clear_target_lock()
	else:
		tactical_grid.show_target_lock(grid_pos)
	if not ability.has("aoe_type"):
		tactical_grid.clear_aoe_preview()
		return
	# Only show preview when the cursor is inside ability range
	if grid_pos not in tactical_grid.ability_tiles:
		tactical_grid.clear_aoe_preview()
		return
	# Compute tiles inside the shape and highlight them.
	var caster: Unit = _living_unit(active_unit_id)
	if not caster:
		tactical_grid.clear_aoe_preview()
		return
	var preview: Array[Vector2i] = _aoe_tiles(grid_pos, ability, caster)
	tactical_grid.show_aoe_preview(preview)


func _on_tile_clicked(grid_pos: Vector2i) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	if is_resolving_action:
		return
	var unit: Unit = _living_unit(active_unit_id)
	if not unit:
		return
	if active_command in ["attack", "ability_target"]:
		var clicked_unit := _unit_at_pos(grid_pos)
		if clicked_unit:
			_on_unit_clicked(clicked_unit.unit_id)
			return
	if active_command == "move" and grid_pos in tactical_grid.move_tiles:
		is_resolving_action = true
		var old_pos := unit.grid_pos
		unit.move_to(grid_pos)
		tactical_grid.clear_highlights()
		active_command = ""
		log_message.emit("%s moved to %d,%d." % [unit.display_name, grid_pos.x, grid_pos.y])
		unit_moved.emit(unit.unit_id, old_pos, grid_pos)
		await tactical_grid.move_unit_visual(unit.unit_id, old_pos, grid_pos)
		await _timer(0.20).timeout
		active_unit_has_moved = true
		_tiles_moved_this_turn = GridSystem.manhattan(old_pos, grid_pos)
		var _im_b := RunBonusesUtil.for_current_run()
		if _im_b.get("iron_momentum_min_move", 0) > 0 \
				and _tiles_moved_this_turn >= _im_b.get("iron_momentum_min_move", 0):
			_iron_momentum_primed = true
		is_resolving_action = false
		if _iron_momentum_primed:
			command_hint_changed.emit(" Iron Momentum! +30%% bonus damage on next attack. Choose Attack, Ability, or Wait.")
		else:
			command_hint_changed.emit("Move complete. Choose Attack, Ability, or Wait.")
		_emit_enemy_intent_board()
	elif active_command == "ability_target" and selected_ability_id != "":
		# AoE abilities can be targeted on empty tiles
		var ability: Dictionary = AbilityDB.get_ability(selected_ability_id)
		if not ability.has("aoe_type"):
			return   # single-target abilities require clicking a unit
		if grid_pos not in tactical_grid.ability_tiles:
			return
		_execute_aoe_ability(unit, grid_pos, ability)
		active_unit_has_acted = true
		_end_player_turn()


func _on_unit_clicked(unit_id: String) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	if is_resolving_action:
		return
	if active_command == "attack":
		var attacker: Unit = _living_unit(active_unit_id)
		var target:   Unit = _living_unit(unit_id)
		if not attacker or not target or target.team == attacker.team or target.hp <= 0:
			return
		if target.grid_pos not in tactical_grid.attack_tiles:
			var distance := GridSystem.manhattan(attacker.grid_pos, target.grid_pos)
			log_message.emit("%s is out of range." % target.display_name)
			command_hint_changed.emit("Target is %d tiles away. Attack range is %d-%d. Choose another target, Move, Ability, or Wait." % [
				distance,
				attacker.unit_data.base_stats.attack_range_min,
				attacker.unit_data.base_stats.attack_range_max,
			])
			action_preview_changed.emit({})
			return
		_face_toward(attacker, target.grid_pos)
		var tile_att := tactical_grid.get_tile(attacker.grid_pos)
		var tile_tar := tactical_grid.get_tile(target.grid_pos)
		var atk_vfx: String = "arrow" if attacker.unit_data.base_stats.attack_range_max > 1 else "slash"
		last_ability_used = "a basic attack"
		var result := combat_resolver.resolve_attack(attacker, target, tile_att, tile_tar, atk_vfx)
		tactical_grid.clear_highlights()
		active_command = ""
		if result.get("missed", false):
			log_message.emit("%s swings but misses! (blind)" % attacker.display_name)
		else:
			var ftag := " [BACK ATTACK!]" if result.get("flank","") == "back" \
				else (" [flank]" if result.get("flank","") == "side" else "")
			log_message.emit("%s hits %s for %d dmg!%s" % [attacker.display_name, target.display_name, result.get("hp_damage", 0), ftag])
		if result.get("counter", false):
			_timer(0.6).timeout.connect(
				func() -> void: _execute_counter_attack(target, attacker))
		active_unit_has_acted = true

		#  Tactical boon follow-ups (player attacks only)
		var tb_bonuses := RunBonusesUtil.for_current_run()
		if not result.get("missed", false):
			var dmg_dealt: int = result.get("hp_damage", 0) + result.get("temper_damage", 0)
			_apply_tactical_boons(attacker, target, tb_bonuses, dmg_dealt)
			# Kill checks for basic attacks (volatile + boon on-kill effects)
			if target.hp <= 0:
				_check_volatile_explosion(target)
				_check_boon_on_kill(attacker, target)
				if tb_bonuses.get("wrath_crescendo_per_kill", 0.0) > 0.0:
					_wrath_crescendo_stacks = mini(_wrath_crescendo_stacks + 1, 10)
					log_message.emit("Wrath Crescendo: %d kills! (+%d%% dmg)" % [
						_wrath_crescendo_stacks,
						int(tb_bonuses["wrath_crescendo_per_kill"] * 100.0 * _wrath_crescendo_stacks)])

		# Reaping Step: grant free move if a kill was scored
		if _reaping_step_pending:
			_reaping_step_pending = false
			active_unit_has_moved = false
			var rs_tiles: int = tb_bonuses.get("reaping_step_range", 3)
			command_hint_changed.emit(" Reaping Step! Move up to %d tiles, then your turn ends." % rs_tiles)
			if auto_battle_enabled:
				_run_reaping_step_auto.call_deferred(attacker)
			return   # don't end turn yet  player may still move

		_end_player_turn()
	elif active_command == "ability_target" and selected_ability_id != "":
		var target: Unit = units.get(unit_id)
		if not target or target.hp <= 0:
			return
		var ability: Dictionary = AbilityDB.get_ability(selected_ability_id)
		var target_type: String = ability.get("target_type", "enemy")
		var caster: Unit = _living_unit(active_unit_id)
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
			command_hint_changed.emit("%s is outside %s range." % [target.display_name, ability.get("display_name", selected_ability_id)])
			action_preview_changed.emit({})
			return
		last_ability_used = ability.get("display_name", selected_ability_id)
		if ability.has("aoe_type"):
			_execute_aoe_ability(caster, target.grid_pos, ability)
		else:
			_execute_ability(caster, target, ability)
		active_unit_has_acted = true
		_end_player_turn()


func _end_player_turn() -> void:
	var unit: Unit = _living_unit(active_unit_id)
	if unit:
		unit.end_turn()
		_process_terrain_hazards(unit)
	turn_ended.emit(active_unit_id)
	active_command = ""
	selected_ability_id = ""
	active_unit_has_moved = false
	active_unit_has_acted = false
	action_preview_changed.emit({})
	tactical_grid.clear_highlights()
	command_hint_changed.emit("Resolving turn...")
	_set_phase(Phase.RESOLVE)


func _unit_at_pos(grid_pos: Vector2i) -> Unit:
	for uid: String in units.keys():
		var unit := _living_unit(uid)
		if unit and unit.grid_pos == grid_pos:
			return unit
	return null


func _move_preview(grid_pos: Vector2i) -> Dictionary:
	var unit: Unit = _living_unit(active_unit_id)
	if not unit or grid_pos not in tactical_grid.move_tiles:
		return {}
	var start_tile := tactical_grid.get_tile(unit.grid_pos)
	var dest_tile := tactical_grid.get_tile(grid_pos)
	var path := _preview_path(unit, grid_pos)
	var path_cost := _movement_path_cost(path)
	var height_delta: int = int(dest_tile.get("height", 0)) - int(start_tile.get("height", 0))
	var terrain_name := str(dest_tile.get("terrain", "unknown")).replace("_", " ").capitalize()
	var note := "%s tile. Turn continues after moving." % terrain_name
	var hazard_note := _path_hazard_note(unit, path)
	if not hazard_note.is_empty():
		note = "%s %s" % [hazard_note, note]
	if height_delta > 0:
		note = "Climb +%d height. %s" % [height_delta, note]
	elif height_delta < 0:
		note = "Drop %d height. %s" % [abs(height_delta), note]
	return {
		"visible": true,
		"mode": "Move",
		"actor": unit.display_name,
		"actor_portrait": _portrait_path(unit),
		"target": "%d,%d" % [grid_pos.x, grid_pos.y],
		"target_portrait": "",
		"action": "Reposition",
		"ability_name": "Move",
		"element_color": Color(0.25, 0.95, 1.0),
		"amount_label": "No damage",
		"hit_pct": 100,
		"jp_gain": 0,
		"range_label": "%d steps" % max(path.size() - 1, 0),
		"height_label": "Height %d -> %d" % [int(start_tile.get("height", 0)), int(dest_tile.get("height", 0))],
		"status_preview": "Move cost %d / %d" % [path_cost, unit.unit_data.base_stats.move],
		"note": note,
	}


func _path_hazard_note(unit: Unit, path: Array[Vector2i]) -> String:
	if not unit or path.size() <= 2:
		return ""
	var burns := 0
	var shocks := 0
	var voids := 0
	var ice := 0
	for i in range(1, path.size() - 1):
		var tile := tactical_grid.get_tile(path[i])
		match str(tile.get("terrain", "")):
			"burning":
				burns += 1
			"electrified", "electrified_water":
				shocks += 1
			"void_corruption", "void_anchor":
				voids += 1
			"ice", "frozen_water":
				ice += 1
	var parts: Array[String] = []
	if burns > 0:
		parts.append("%d burning" % burns)
	if shocks > 0:
		parts.append("%d electrified" % shocks)
	if voids > 0:
		parts.append("%d corrupted" % voids)
	if ice > 0:
		parts.append("%d icy" % ice)
	if parts.is_empty():
		return ""
	return "Path crosses %s hazard tile%s." % [", ".join(parts), "" if parts.size() == 1 and (burns + shocks + voids + ice) == 1 else "s"]


func _terrain_hazard_label(terrain: String) -> String:
	match terrain:
		"burning":
			return "  Hazard: burn"
		"electrified", "electrified_water":
			return "  Hazard: shock/Ether drain"
		"ice", "frozen_water":
			return "  Hazard: slippery/slow"
		"void_corruption", "void_anchor":
			return "  Hazard: void/Ether drain"
		_:
			return ""


func _attack_preview_for_tile(grid_pos: Vector2i) -> Dictionary:
	var attacker: Unit = _living_unit(active_unit_id)
	var target := _unit_at_pos(grid_pos)
	if not attacker or not target or target.team == attacker.team or grid_pos not in tactical_grid.attack_tiles:
		return {}
	var tile_att := tactical_grid.get_tile(attacker.grid_pos)
	var tile_tar := tactical_grid.get_tile(target.grid_pos)
	var fc := ForecastCalculator.attack(attacker, target, tile_att, tile_tar)
	fc["actor_portrait"] = _portrait_path(attacker)
	fc["target_portrait"] = _portrait_path(target)
	return _with_run_bonus_context(_with_position_context(fc, attacker, target), attacker, target)


func _ability_preview_for_tile(grid_pos: Vector2i, ability: Dictionary) -> Dictionary:
	var caster: Unit = _living_unit(active_unit_id)
	if not caster or grid_pos not in tactical_grid.ability_tiles:
		return {}
	var target := _unit_at_pos(grid_pos)
	if not target:
		# AoE with no unit under cursor  show basic info
		var area_fc := ForecastCalculator.quick_spell(caster, ability)
		return {
			"visible": true, "mode": "Ability",
			"actor": caster.display_name, "actor_portrait": _portrait_path(caster),
			"target": "Area (%d tiles)" % ability.get("aoe_radius",1),
			"target_portrait": "",
			"ability_name": ability.get("display_name","?"),
			"element": area_fc["element"], "element_icon": area_fc["element_icon"],
			"element_color": area_fc["element_color"],
			"damage": area_fc["boosted_damage"], "damage_min": int(area_fc["boosted_damage"]*0.9),
			"damage_max": int(area_fc["boosted_damage"]*1.1),
			"affinity_label": "", "boon_bonus_pct": area_fc["boon_pct"],
			"hp_before": 0, "hp_after": 0, "max_hp": 1,
			"status_preview": "", "jp_gain": 6, "is_heal": false, "is_buff": false,
		}
	var target_type: String = ability.get("target_type", "enemy")
	var valid := (target_type == "enemy" and target.team != caster.team) or 		(target_type != "enemy" and target.team == caster.team)
	if not valid: return {}
	var spell_fc := ForecastCalculator.spell(caster, target, ability, tactical_grid.get_tile(caster.grid_pos), tactical_grid.get_tile(target.grid_pos))
	spell_fc["actor_portrait"] = _portrait_path(caster)
	spell_fc["target_portrait"] = _portrait_path(target)
	return _with_run_bonus_context(_with_position_context(spell_fc, caster, target), caster, target)


func _with_position_context(preview: Dictionary, actor: Unit, target: Unit) -> Dictionary:
	var actor_tile := tactical_grid.get_tile(actor.grid_pos)
	var target_tile := tactical_grid.get_tile(target.grid_pos)
	var actor_height: int = int(actor_tile.get("height", 0))
	var target_height: int = int(target_tile.get("height", 0))
	var height_delta: int = actor_height - target_height
	preview["range_label"] = "Range %d" % GridSystem.manhattan(actor.grid_pos, target.grid_pos)
	preview["height_label"] = "Height %d -> %d" % [actor_height, target_height]
	var height_mult: float = float(preview.get("height_mult", 1.0))
	if height_delta > 0:
		preview["height_label"] += "  high ground"
		preview["height_rule_label"] = "Height %+d  x%.2f damage" % [height_delta, height_mult]
	elif height_delta < 0:
		preview["height_label"] += "  uphill"
		preview["height_rule_label"] = "Height %+d  x%.2f damage" % [height_delta, height_mult]
	elif preview.has("height_mult"):
		preview["height_rule_label"] = "Even height  x%.2f damage" % height_mult
	var flank_text := _flank_label(actor, target)
	var flank_mult: float = float(preview.get("flank_mult", 1.0))
	preview["facing_label"] = "%s side, target faces %s" % [flank_text, target.facing]
	if preview.has("flank_mult"):
		preview["facing_rule_label"] = "%s  x%.2f damage" % [flank_text, flank_mult]
	return preview


func _with_run_bonus_context(preview: Dictionary, actor: Unit, target: Unit) -> Dictionary:
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	var notes: Array[String] = []
	var element := str(preview.get("element", "physical"))
	var element_mult: float = 1.0
	if bonuses.has("elemental_mult") and bonuses["elemental_mult"] is Dictionary:
		element_mult = float(bonuses["elemental_mult"].get(element, 1.0))
	if element != "physical" and element_mult != 1.0:
		notes.append("Boon: %s %+d%% damage" % [element.capitalize(), int(round((element_mult - 1.0) * 100.0))])
	var item_mult: float = CombatFormula.item_elemental_multiplier(actor, element)
	if element != "physical" and item_mult != 1.0:
		notes.append("Item: %s %+d%% damage" % [element.capitalize(), int(round((item_mult - 1.0) * 100.0))])
	if bool(preview.get("is_heal", false)) and int(bonuses.get("heal_bonus", 0)) != 0:
		notes.append("Boon: healing %+d" % int(bonuses.get("heal_bonus", 0)))
	if element == "physical":
		if float(bonuses.get("battle_fury_bonus", 0.0)) > 0.0 and bool(actor.get_meta("moved_this_turn", false)):
			notes.append("Boon: Battle Fury %+d%% after moving" % int(round(float(bonuses["battle_fury_bonus"]) * 100.0)))
		if int(bonuses.get("iron_momentum_min_move", 0)) > 0:
			var moved_tiles: int = int(actor.get_meta("tiles_moved_this_turn", 0))
			var min_move: int = int(bonuses["iron_momentum_min_move"])
			if moved_tiles >= min_move:
				notes.append("Boon: Iron Momentum primed")
		if float(bonuses.get("coup_de_grace_bonus", 0.0)) > 0.0 and target.unit_data:
			var threshold: float = float(bonuses.get("coup_de_grace_threshold", 0.0))
			var target_ratio: float = float(target.hp) / float(maxi(target.unit_data.base_stats.hp, 1))
			if threshold > 0.0 and target_ratio <= threshold:
				notes.append("Boon: Coup de Grace %+d%% vs low HP" % int(round(float(bonuses["coup_de_grace_bonus"]) * 100.0)))
		if bool(bonuses.get("cleave", false)):
			notes.append("Boon: Cleave also checks flanking tiles")
		if bool(bonuses.get("piercing_line", false)):
			notes.append("Boon: Piercing line can hit behind target")
	if float(bonuses.get("jp_multiplier", 1.0)) != 1.0:
		notes.append("Boon: JP x%.1f" % float(bonuses["jp_multiplier"]))
	preview["run_bonus_notes"] = notes
	var breakdown: Array = preview.get("modifier_breakdown", preview.get("formula_explain", [])) as Array
	for note in notes:
		var compact_note: String = str(note).replace("Boon: ", "Boon ")
		if compact_note not in breakdown:
			breakdown.append(compact_note)
	preview["modifier_breakdown"] = breakdown
	return preview


func _preview_path(unit: Unit, grid_pos: Vector2i) -> Array[Vector2i]:
	var occupied: Array = []
	for uid in units:
		var other: Unit = _living_unit(str(uid))
		if not other:
			continue
		if other.unit_id != unit.unit_id and other.hp > 0:
			occupied.append(other.grid_pos)
	return GridSystem.find_path(unit.grid_pos, grid_pos, tactical_grid.tiles, occupied, map_data.map_width, map_data.map_height)


func _movement_path_cost(path: Array[Vector2i]) -> int:
	if path.size() <= 1:
		return 0
	var total := 0
	for i in range(1, path.size()):
		var prev_tile: Dictionary = tactical_grid.get_tile(path[i - 1])
		var next_tile: Dictionary = tactical_grid.get_tile(path[i])
		total += int(next_tile.get("move_cost", 1))
		total += abs(int(next_tile.get("height", 0)) - int(prev_tile.get("height", 0)))
	return total


func _face_toward(unit: Unit, target_pos: Vector2i) -> void:
	if not unit or unit.grid_pos == target_pos:
		return
	unit.set_facing(GridSystem.facing_from_delta(unit.grid_pos, target_pos))


func _predict_attack_damage(attacker: Unit, target: Unit, tile_attacker: Dictionary, tile_target: Dictionary) -> int:
	var formula := CombatFormula.calculate_physical_attack(attacker, target, tile_attacker, tile_target)
	return int(formula.get("hp_damage", formula.get("incoming_damage", 0)))


func _predict_spell_damage(caster: Unit, target: Unit, ability: Dictionary) -> int:
	var spell_type: String = CombatFormula.normalize_element(str(ability.get("spell_type", "fire")))
	if spell_type == "physical":
		return _predict_attack_damage(caster, target, tactical_grid.get_tile(caster.grid_pos), tactical_grid.get_tile(target.grid_pos))
	var base_power: int = int(ability.get("base_power", 100))
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	var el_mult: float = float(bonuses["elemental_mult"].get(spell_type, 1.0))
	el_mult *= CombatFormula.item_elemental_multiplier(caster, spell_type)
	var formula := CombatFormula.calculate_magical_attack(caster, target, spell_type, base_power, {"power_mult": el_mult})
	return int(formula.get("hp_damage", formula.get("incoming_damage", 0)))


func _get_flank_multiplier(attacker: Unit, target: Unit) -> float:
	var delta: Vector2i = attacker.grid_pos - target.grid_pos
	var attack_from: String
	if abs(delta.x) >= abs(delta.y):
		attack_from = "E" if delta.x > 0 else "W"
	else:
		attack_from = "S" if delta.y > 0 else "N"
	if attack_from == target.facing:
		return 1.0
	if attack_from == FACING_OPPOSITE.get(target.facing, ""):
		return 1.3
	return 1.15


func _flank_label(attacker: Unit, target: Unit) -> String:
	var mult := _get_flank_multiplier(attacker, target)
	if mult >= 1.25:
		return "Back attack"
	if mult > 1.0:
		return "Flank"
	return "Front"


func _target_can_counter(attacker: Unit, target: Unit) -> bool:
	var distance := GridSystem.manhattan(attacker.grid_pos, target.grid_pos)
	return distance <= target.unit_data.base_stats.attack_range_max


func _affinity_label(target: Unit, spell_type: String) -> String:
	var affinity := 1.0
	if target.unit_data and not target.unit_data.elemental_affinities.is_empty():
		affinity = target.unit_data.elemental_affinities.get(spell_type, 1.0)
	if affinity == 0.0:
		return "Immune"
	if affinity >= 1.5:
		return "Weak"
	if affinity > 1.0:
		return "Soft"
	if affinity < 1.0:
		return "Resist"
	return "Normal"


func _portrait_path(unit: Unit) -> String:
	if not unit or not unit.unit_data:
		return ""
	if unit.unit_data.portrait:
		return unit.unit_data.portrait.resource_path
	if unit.unit_data.sprite_sheet:
		return unit.unit_data.sprite_sheet.resource_path
	return ""


func _on_unit_defeated(unit_id: String) -> void:
	if _apply_defeat_boon_effects(unit_id):
		return
	unit_defeated.emit(unit_id)
	if units.has(unit_id):
		log_message.emit("%s was defeated!" % units[unit_id].display_name)
	objective_tracker.on_unit_defeated(unit_id)
	turn_order.remove_unit(unit_id)
	# A unit dying mid-tick could end the battle  check objectives
	if current_phase == Phase.TICK or current_phase == Phase.RESOLVE:
		_set_phase(Phase.CHECK_OBJECTIVE)


func _process_terrain_hazards(unit: Unit) -> void:
	if unit.hp <= 0:
		return
	var tile: Dictionary = tactical_grid.get_tile(unit.grid_pos)
	_apply_terrain_hazard(unit, unit.grid_pos, str(tile.get("terrain", "")), "standing")


func _process_terrain_path_hazards(unit: Unit, path: Array[Vector2i]) -> void:
	if unit.hp <= 0 or path.size() <= 2:
		return
	for i in range(1, path.size() - 1):
		var pos: Vector2i = path[i]
		var tile: Dictionary = tactical_grid.get_tile(pos)
		if tile.is_empty():
			continue
		_apply_terrain_hazard(unit, pos, str(tile.get("terrain", "")), "movement")
		if unit.hp <= 0:
			return


func _apply_terrain_hazard(unit: Unit, pos: Vector2i, terrain: String, trigger: String) -> void:
	match terrain:
		"burning":
			var dmg: int = max(1, int(unit.unit_data.base_stats.hp * 0.05))
			var result := unit.receive_damage(dmg, "magical")
			var dealt: int = result.get("hp_damage", 0)
			var source := "crossing burning ground" if trigger == "movement" else "burning ground"
			log_message.emit("%s takes %d fire damage from %s!" % [unit.display_name, dealt, source])
			var vfx_node := get_node_or_null("/root/VFX")
			if vfx_node:
				(vfx_node as VFXManager).play_damage_number(pos, dealt, Color(1.0, 0.45, 0.1))
				(vfx_node as VFXManager).play_fire(pos)
		"electrified", "electrified_water":
			var dmg: int = max(1, int(unit.unit_data.base_stats.hp * 0.04))
			var result := unit.receive_damage(dmg, "magical")
			var dealt: int = result.get("hp_damage", 0)
			unit.ether = max(0, unit.ether - 8)
			log_message.emit("%s takes %d lightning damage and loses 8 Ether from electrified ground!" % [unit.display_name, dealt])
			var vfx_node := get_node_or_null("/root/VFX")
			if vfx_node:
				(vfx_node as VFXManager).play_damage_number(pos, dealt, Color(0.5, 0.85, 1.0))
		"ice", "frozen_water":
			if not unit.has_status("slow"):
				_try_apply_status(unit, {"id": "slow", "duration": 1, "magnitude": 0.0, "damage_type": "ice"})
			log_message.emit("%s loses footing on icy ground!" % unit.display_name)
		"void_corruption", "void_anchor":
			var dmg: int = max(1, int(unit.unit_data.base_stats.hp * 0.03))
			var result := unit.receive_damage(dmg, "magical")
			var dealt: int = result.get("hp_damage", 0)
			unit.ether = max(0, unit.ether - 5)
			log_message.emit("%s takes %d void damage and loses 5 Ether from corrupted ground!" % [unit.display_name, dealt])
			var vfx_node := get_node_or_null("/root/VFX")
			if vfx_node:
				(vfx_node as VFXManager).play_damage_number(pos, dealt, Color(0.72, 0.32, 1.0))


func _try_apply_status(target: Unit, se_data: Dictionary) -> void:
	if not is_instance_valid(target) or target.hp <= 0:
		return
	var sid: String = se_data.get("id", "")
	if sid == "" or target.has_status(sid):
		return
	var se := StatusEffect.new()
	se.status_id    = sid
	se.display_name = sid.capitalize()
	se.duration     = se_data.get("duration", 2)
	se.magnitude    = se_data.get("magnitude", 0.0)
	se.damage_type  = se_data.get("damage_type", "pure")
	target.apply_status(se)
	log_message.emit("%s is now %s!" % [target.display_name, sid.to_upper()])


func _on_status_tick(unit_id: String, status_id: String, damage: int) -> void:
	var unit: Unit = units.get(unit_id)
	var uname: String = unit.display_name if unit else unit_id
	log_message.emit("%s: %s tick -%d HP" % [uname, status_id.capitalize(), damage])
	var vfx_node := get_node_or_null("/root/VFX")
	if vfx_node and unit:
		var color: Color = Color(0.2, 0.9, 0.2) if status_id == "poison" \
			else Color(1.0, 0.5, 0.1)   # green for poison, orange for burn
		(vfx_node as VFXManager).play_damage_number(unit.grid_pos, damage, color)


#  Tactical Boon Execution

## Apply all tactical boon follow-up effects after a player attack resolves.
## Called only for player-side attacks; `damage_dealt` = hp_damage + temper_damage.
func _apply_tactical_boons(attacker: Unit, primary_target: Unit,
		bonuses: Dictionary, damage_dealt: int) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(primary_target):
		return
	var vfx := get_node_or_null("/root/VFX") as VFXManager
	var wc_pct: float = bonuses.get("wrath_crescendo_per_kill", 0.0)

	#  Coup de Grace
	var cdg_thresh: float = bonuses.get("coup_de_grace_threshold", 0.0)
	var cdg_bonus:  float = bonuses.get("coup_de_grace_bonus", 0.0)
	if cdg_thresh > 0.0 and cdg_bonus > 0.0 and primary_target.hp > 0:
		var hp_pct := float(primary_target.hp) / float(maxi(primary_target.unit_data.base_stats.hp, 1))
		if hp_pct <= cdg_thresh:
			var bonus_dmg := int(round(float(damage_dealt) * cdg_bonus))
			if bonus_dmg > 0:
				primary_target.receive_damage(bonus_dmg, "physical")
				log_message.emit("Coup de Grace! +%d finishing blow!" % bonus_dmg)
				if vfx and primary_target.hp > 0:
					vfx.play_damage_number(primary_target.grid_pos, bonus_dmg, Color(0.95, 0.1, 0.1))

	#  Battle Fury
	var fury: float = bonuses.get("battle_fury_bonus", 0.0)
	if fury > 0.0 and active_unit_has_moved and primary_target.hp > 0:
		var fury_dmg := int(round(float(damage_dealt) * fury))
		if fury_dmg > 0:
			primary_target.receive_damage(fury_dmg, "physical")
			log_message.emit("Battle Fury! +%d (moved first)!" % fury_dmg)
			if vfx and primary_target.hp > 0:
				vfx.play_damage_number(primary_target.grid_pos, fury_dmg, Color(1.0, 0.5, 0.1))

	#  Iron Momentum
	if _iron_momentum_primed and bonuses.get("iron_momentum_min_move", 0) > 0 \
			and primary_target.hp > 0:
		var im_dmg := int(round(float(damage_dealt) * 0.30))
		if im_dmg > 0:
			primary_target.receive_damage(im_dmg, "physical")
			log_message.emit("Iron Momentum! +%d bonus damage!" % im_dmg)
			if vfx and primary_target.hp > 0:
				vfx.play_damage_number(primary_target.grid_pos, im_dmg, Color(0.70, 0.70, 0.95))
		_iron_momentum_primed = false

	#  Wrath Crescendo
	if wc_pct > 0.0 and _wrath_crescendo_stacks > 0 and primary_target.hp > 0:
		var wc_dmg := int(round(float(damage_dealt) * wc_pct * float(_wrath_crescendo_stacks)))
		if wc_dmg > 0:
			primary_target.receive_damage(wc_dmg, "physical")
			log_message.emit("Wrath Crescendo %d! +%d damage!" % [_wrath_crescendo_stacks, wc_dmg])
			if vfx and primary_target.hp > 0:
				vfx.play_damage_number(primary_target.grid_pos, wc_dmg, Color(0.9, 0.3, 0.9))

	#  Bloodthirst
	var bt: float = bonuses.get("bloodthirst_pct", 0.0)
	if bt > 0.0 and damage_dealt > 0:
		var heal_amt := int(round(float(damage_dealt) * bt))
		if heal_amt > 0:
			attacker.heal(heal_amt)
			log_message.emit("Bloodthirst: +%d HP" % heal_amt)
			if vfx:
				vfx.play_aura(attacker.grid_pos, Color(0.8, 0.1, 0.1, 0.6))

	#  Sundering Blow
	var sunder: int = bonuses.get("sundering_amount", 0)
	if sunder > 0 and is_instance_valid(primary_target) and primary_target.hp > 0 \
			and primary_target.unit_data:
		primary_target.unit_data.base_stats.max_temper = \
			maxi(0, primary_target.unit_data.base_stats.max_temper - sunder)
		primary_target.temper = mini(
			primary_target.temper, primary_target.unit_data.base_stats.max_temper)
		log_message.emit("Sundering Blow! %s max Temper %d!" % [primary_target.display_name, sunder])

	#  Ruinous Field
	var rf_int: int = bonuses.get("ruinous_field_interval", 0)
	if rf_int > 0 and is_instance_valid(primary_target) and primary_target.hp > 0:
		_ruinous_hit_counter += 1
		if _ruinous_hit_counter >= rf_int:
			_ruinous_hit_counter = 0
			if tactical_grid.has_method("ignite_tile"):
				tactical_grid.ignite_tile(primary_target.grid_pos)
			log_message.emit("Ruinous Field! Ground ignites under %s!" % primary_target.display_name)
			if vfx:
				vfx.play_fire(primary_target.grid_pos)

	#  Knockback
	var kb: float = bonuses.get("knockback_chance", 0.0)
	if kb > 0.0 and is_instance_valid(primary_target) and primary_target.hp > 0:
		if randf() < kb:
			_apply_knockback(attacker.grid_pos, primary_target)

	#  Cleave
	if bonuses.get("cleave", false) and is_instance_valid(primary_target):
		for cpos: Vector2i in _get_cleave_tiles(attacker.grid_pos, primary_target.grid_pos):
			var ctgt := _unit_at_pos(cpos)
			if not ctgt or ctgt.team == attacker.team or ctgt.hp <= 0:
				continue
			var cr := combat_resolver.resolve_attack(
				attacker, ctgt,
				tactical_grid.get_tile(attacker.grid_pos),
				tactical_grid.get_tile(cpos), "slash", true)
			if not cr.get("missed", false):
				log_message.emit("Cleave hits %s for %d!" % [ctgt.display_name, cr.get("hp_damage", 0)])
				if ctgt.hp <= 0:
					_check_volatile_explosion(ctgt)
					_check_boon_on_kill(attacker, ctgt)
					if wc_pct > 0.0:
						_wrath_crescendo_stacks = mini(_wrath_crescendo_stacks + 1, 10)

	#  Piercing Line
	if bonuses.get("piercing_line", false) and is_instance_valid(primary_target):
		var ppos := _get_pierce_tile(attacker.grid_pos, primary_target.grid_pos)
		var ptgt := _unit_at_pos(ppos)
		if ptgt and ptgt.team != attacker.team and ptgt.hp > 0:
			var pr := combat_resolver.resolve_attack(
				attacker, ptgt,
				tactical_grid.get_tile(attacker.grid_pos),
				tactical_grid.get_tile(ppos), "slash", true)
			if not pr.get("missed", false):
				log_message.emit("Pierce! Hits %s for %d!" % [ptgt.display_name, pr.get("hp_damage", 0)])
				if ptgt.hp <= 0:
					_check_volatile_explosion(ptgt)
					_check_boon_on_kill(attacker, ptgt)
					if wc_pct > 0.0:
						_wrath_crescendo_stacks = mini(_wrath_crescendo_stacks + 1, 10)

	#  Echo Strike
	var echo: float = bonuses.get("echo_strike_chance", 0.0)
	if echo > 0.0 and is_instance_valid(primary_target) and primary_target.hp > 0:
		if randf() < echo:
			var er := combat_resolver.resolve_attack(
				attacker, primary_target,
				tactical_grid.get_tile(attacker.grid_pos),
				tactical_grid.get_tile(primary_target.grid_pos), "slash", true)
			if not er.get("missed", false):
				log_message.emit("Echo Strike! Second hit: %d damage!" % er.get("hp_damage", 0))
				if primary_target.hp <= 0:
					_check_volatile_explosion(primary_target)
					_check_boon_on_kill(attacker, primary_target)
					if wc_pct > 0.0:
						_wrath_crescendo_stacks = mini(_wrath_crescendo_stacks + 1, 10)


## Returns the two tiles flanking the target (perpendicular to the attack direction).
func _get_cleave_tiles(attacker_pos: Vector2i, target_pos: Vector2i) -> Array[Vector2i]:
	var dx := target_pos.x - attacker_pos.x
	var dy := target_pos.y - attacker_pos.y
	var result: Array[Vector2i] = []
	if abs(dx) >= abs(dy):   # horizontal attack  cleave above/below target
		result.append(target_pos + Vector2i(0, -1))
		result.append(target_pos + Vector2i(0,  1))
	else:                     # vertical attack  cleave left/right of target
		result.append(target_pos + Vector2i(-1, 0))
		result.append(target_pos + Vector2i( 1, 0))
	return result


## Returns the tile directly behind the target (away from the attacker).
func _get_pierce_tile(attacker_pos: Vector2i, target_pos: Vector2i) -> Vector2i:
	var dx := target_pos.x - attacker_pos.x
	var dy := target_pos.y - attacker_pos.y
	var step: Vector2i
	if abs(dx) >= abs(dy):
		step = Vector2i(sign(dx), 0)
	else:
		step = Vector2i(0, sign(dy))
	return target_pos + step


## Push the target 1 tile directly away from the attacker.
## Silently cancels if the destination tile is occupied or off-map.
func _apply_knockback(attacker_pos: Vector2i, target: Unit) -> void:
	var dx := target.grid_pos.x - attacker_pos.x
	var dy := target.grid_pos.y - attacker_pos.y
	var step: Vector2i
	if abs(dx) >= abs(dy):
		step = Vector2i(sign(dx), 0)
	else:
		step = Vector2i(0, sign(dy))
	if step == Vector2i.ZERO:
		return   # attacker and target share the same tile (shouldn't happen)
	var new_pos := target.grid_pos + step
	if tactical_grid.get_tile(new_pos).is_empty():
		return   # off-map or no tile data
	if _unit_at_pos(new_pos):
		return   # destination occupied
	var old_pos := target.grid_pos
	target.move_to(new_pos)
	unit_moved.emit(target.unit_id, old_pos, new_pos)
	tactical_grid.move_unit_visual(target.unit_id, old_pos, new_pos)  # fire-and-forget
	log_message.emit("Knocked back! %s pushed to %d,%d" % [
		target.display_name, new_pos.x, new_pos.y])


## Reaping Step: automatically move toward the nearest remaining enemy after a kill.
## In manual mode the player sees the move-range UI and makes the choice.
func _run_reaping_step_auto(unit: Unit) -> void:
	await _timer(0.25).timeout
	if not is_instance_valid(unit) or unit.hp <= 0:
		_end_player_turn()
		return
	var tgt := _nearest_enemy(unit)
	if tgt:
		var bonuses   := RunBonusesUtil.for_current_run()
		var rs_range: int = bonuses.get("reaping_step_range", 3)
		# Temporarily raise move budget to reaping range for tile search
		var orig_move: int = unit.unit_data.base_stats.move
		unit.unit_data.base_stats.move = rs_range
		var best := _best_auto_move_tile(unit, tgt)
		unit.unit_data.base_stats.move = orig_move
		if best != unit.grid_pos:
			var old_pos := unit.grid_pos
			unit.move_to(best)
			unit_moved.emit(unit.unit_id, old_pos, best)
			await tactical_grid.move_unit_visual(unit.unit_id, old_pos, best)
			log_message.emit("Reaping Step! %s dashes to %d,%d!" % [
				unit.display_name, best.x, best.y])
			await _timer(0.15).timeout
	_end_player_turn()


#  Boon Handler: Movement tracking
func _on_unit_moved_internal(unit_id: String, from: Vector2i, to: Vector2i) -> void:
	var unit := _living_unit(unit_id)
	if not unit:
		return
	var path := _path_between_for_hazards(unit, from, to)
	_process_terrain_path_hazards(unit, path)
	if unit.hp <= 0 or unit.team != "player":
		return
	if unit_id != active_unit_id:
		return  # Only track active unit

	# Track movement for Iron Momentum and Battle Fury
	unit.set_meta("moved_this_turn", true)
	var distance: int = GridSystem.manhattan(from, to)
	var current: int = unit.get_meta("tiles_moved_this_turn", 0) as int
	unit.set_meta("tiles_moved_this_turn", current + distance)
	active_unit_has_moved = true


func _path_between_for_hazards(unit: Unit, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var occupied: Array = []
	for uid in units:
		var other: Unit = _living_unit(str(uid))
		if not other or other.unit_id == unit.unit_id:
			continue
		occupied.append(other.grid_pos)
	var path := GridSystem.find_path(from, to, tactical_grid.tiles, occupied, map_data.map_width, map_data.map_height)
	if path.is_empty() and from != to:
		path = [from, to]
	return path


#  Boon Handler: Kill effects and survival mechanics
func _apply_defeat_boon_effects(unit_id: String) -> bool:
	var unit: Unit = units.get(unit_id) as Unit
	if not unit:
		return false

	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	var vfx_n := get_node_or_null("/root/VFX")

	#  Phoenix Vitality: survive at 1 HP once per battle
	if bonuses.get("phoenix_vitality", false) and unit.team == "player" and not unit.has_meta("phoenix_used"):
		if vfx_n: (vfx_n as VFXManager).play_heal_number(unit.grid_pos, unit.unit_data.base_stats.hp if unit.unit_data else 1)
		unit.hp = 1
		unit.set_meta("phoenix_used", true)
		log_message.emit("Phoenix Vitality! %s cheats death!" % unit.display_name)
		return true

	#  Death Flare: damage adjacent units when unit dies
	if bonuses.get("death_flare_damage", 0) > 0:
		var flare_dmg: int = bonuses["death_flare_damage"]
		for other_id: String in units:
			var other: Unit = _living_unit(str(other_id))
			if not other or other == unit:
				continue
			var dist: int = GridSystem.manhattan(unit.grid_pos, other.grid_pos)
			if dist <= 1 and other.hp > 0:
				other.receive_damage(flare_dmg, "magical")
				if vfx_n: (vfx_n as VFXManager).play_damage_number(other.grid_pos, flare_dmg, Color(0.95, 0.35, 0.15))

	# Track kill for killer's boon effects
	if unit.team == "player":
		# Find who killed this unit (tracked in last_ability_used or last combat)
		# For now, mark it in objective tracker
		pass
	else:
		# Enemy unit defeated - track as player kill for wrath crescendo
		var active: Unit = _living_unit(active_unit_id)
		if active:
			var kills: int = active.get_meta("kill_count", 0) as int
			active.set_meta("kill_count", kills + 1)
	return false


#  Boon Handler: Secondary combat effects
func _on_boon_effect(signal_name: String, data: Dictionary) -> void:
	var vfx_n := get_node_or_null("/root/VFX")
	match signal_name:
		"knockback":
			var target: Unit = data.get("target")
			var new_pos: Vector2i = data.get("new_pos")
			if target and tactical_grid.is_walkable(new_pos):
				var old_pos := target.grid_pos
				target.move_to(new_pos)
				unit_moved.emit(target.unit_id, old_pos, new_pos)
				if vfx_n: (vfx_n as VFXManager).play_damage_number(new_pos, 0, Color(0.8, 0.5, 1.0))
				log_message.emit("Knockback! %s pushed to %d,%d!" % [target.display_name, new_pos.x, new_pos.y])

		"apply_double_strike":
			# Handled in attack resolution loop
			pass

		"apply_echo_strike":
			# Handled separately - second hit will be triggered
			pass
