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

const RunBonusesUtil := preload("res://scripts/roguelike/RunBonuses.gd")
const FACING_OPPOSITE: Dictionary = {"N":"S","S":"N","E":"W","W":"E"}

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
var is_resolving_action: bool = false
var active_unit_has_moved: bool = false
var active_unit_has_acted: bool = false
var pending_action: Dictionary = {}


func _ready() -> void:
	tactical_grid.tile_clicked.connect(_on_tile_clicked)
	tactical_grid.unit_clicked.connect(_on_unit_clicked)
	tactical_grid.tile_hovered.connect(_on_tile_hovered)


func start_battle(p_map_data: MapData, p_units: Array[Unit]) -> void:
	map_data = p_map_data
	for unit in p_units:
		units[unit.unit_id] = unit
		unit.unit_defeated.connect(_on_unit_defeated)
		unit.status_tick.connect(_on_status_tick)
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
	var unit: Unit = units.get(active_unit_id)
	active_unit_has_moved = false
	active_unit_has_acted = false
	pending_action.clear()
	if unit:
		unit.begin_turn()
		tactical_grid.show_active_unit(unit.grid_pos, "player")
	turn_started.emit(active_unit_id, "player")
	var unit_name := unit.display_name if unit else active_unit_id
	log_message.emit("%s's turn." % unit_name)
	command_hint_changed.emit("Choose Move, Attack, Ability, or Wait.")
	_emit_action_state()


func _begin_enemy_turn() -> void:
	var unit: Unit = units.get(active_unit_id)
	if not unit:
		_set_phase(Phase.RESOLVE)
		return
	unit.begin_turn()
	active_unit_has_moved = false
	active_unit_has_acted = false
	pending_action.clear()
	tactical_grid.show_active_unit(unit.grid_pos, "enemy")
	turn_started.emit(active_unit_id, "enemy")
	log_message.emit("Enemy: %s acts." % unit.display_name)
	command_hint_changed.emit("Enemy is acting...")
	_emit_action_state()
	await get_tree().create_timer(0.50).timeout
	var cast_spell := randf() < 0.45
	if cast_spell and _try_enemy_spell(unit):
		active_unit_has_acted = true
	else:
		await _run_enemy_ai(unit)
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
			get_tree().create_timer(0.6).timeout.connect(
				func() -> void: _execute_counter_attack(closest_player, unit))
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
			log_message.emit("%s advances." % unit.display_name)
			unit_moved.emit(unit.unit_id, old_pos, best_tile)
			await tactical_grid.move_unit_visual(unit.unit_id, old_pos, best_tile)
			await get_tree().create_timer(0.20).timeout
			active_unit_has_moved = true
			closest_dist = GridSystem.manhattan(unit.grid_pos, closest_player.grid_pos)
			if closest_dist <= unit.unit_data.base_stats.attack_range_max:
				var tile_att2 := tactical_grid.get_tile(unit.grid_pos)
				var tile_tar2 := tactical_grid.get_tile(closest_player.grid_pos)
				var result2 := combat_resolver.resolve_attack(unit, closest_player, tile_att2, tile_tar2)
				active_unit_has_acted = true
				if result2.get("missed", false):
					log_message.emit("%s attacks after moving but misses!" % unit.display_name)
				else:
					log_message.emit("%s moves in and hits %s for %d dmg!" % [unit.display_name, closest_player.display_name, result2.get("hp_damage", 0)])
				if result2.get("counter", false):
					get_tree().create_timer(0.6).timeout.connect(
						func() -> void: _execute_counter_attack(closest_player, unit))
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
	_play_sfx("victory", -2.0)
	log_message.emit("VICTORY! +%dg +%dJP" % [map_data.reward_gold, map_data.reward_jp])
	battle_won.emit(rewards)


# ── Player commands ───────────────────────────────────────────────────────────

func _handle_defeat() -> void:
	_play_sfx("defeat", -2.0)
	battle_lost.emit()


func _play_sfx(sfx_id: String, volume_db: float = 0.0) -> void:
	var audio := get_node_or_null("/root/AudioSettings")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(sfx_id, volume_db)


func _emit_action_state() -> void:
	var is_player_turn := current_phase == Phase.PLAYER_TURN
	action_state_changed.emit(
		is_player_turn and not active_unit_has_moved,
		is_player_turn and not active_unit_has_acted,
		is_player_turn and not pending_action.is_empty()
	)


func select_command(command: String) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	var unit: Unit = units.get(active_unit_id)
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
	if not pending_action.is_empty():
		pending_action.clear()
		tactical_grid.clear_target_lock()
		action_preview_changed.emit({})
	active_command = command
	match command:
		"move":
			command_hint_changed.emit("Move: click a blue GO tile.")
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
	# Self-cast or range-0 → resolve immediately on the caster's tile
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


# ── Ability execution ─────────────────────────────────────────────────────────

## Execute ability against a single target.
## skip_setup=true skips MP deduction, UI cleanup, and per-target log spam (used by AoE wrapper).
func _execute_ability(caster: Unit, target: Unit, ability: Dictionary,
		skip_setup: bool = false) -> void:
	if not skip_setup:
		caster.mp = max(caster.mp - ability.get("mp_cost", 0), 0)
		tactical_grid.clear_highlights()
		active_command = ""
		selected_ability_id = ""

	var spell_type: String = ability.get("spell_type", "fire")
	var base_power:  int   = ability.get("base_power", 100)
	var ab_name:     String = ability.get("display_name", "?")

	# ── Buff abilities (Haste, Protect, …) ────────────────────────────────
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
			get_tree().create_timer(0.25).timeout.connect(
				func() -> void: _try_apply_status(target, se_data))
		if not skip_setup:
			log_message.emit("%s casts %s on %s!" % [caster.display_name, ab_name, target.display_name])
		return

	# ── Heal ──────────────────────────────────────────────────────────────
	if spell_type == "cure":
		combat_resolver.resolve_heal(caster, target, base_power)
		if not skip_setup:
			log_message.emit("%s uses %s on %s!" % [caster.display_name, ab_name, target.display_name])
		return

	# ── Physical ──────────────────────────────────────────────────────────
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
			get_tree().create_timer(0.6).timeout.connect(
				func() -> void: _execute_counter_attack(target, caster))
		# Status after hit
		var se_data: Dictionary = ability.get("status_effect", {})
		if not se_data.is_empty():
			get_tree().create_timer(0.3).timeout.connect(
				func() -> void: _try_apply_status(target, se_data))
		# JP award for physical ability
		if not skip_setup:
			_award_jp(caster, "action_used")
		# Volatile explosion on kill
		if target.hp <= 0:
			_check_volatile_explosion(target)
			_check_boon_on_kill(caster, target)
		return

	# ── Spell (elemental / dark / etc.) ───────────────────────────────────
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
		get_tree().create_timer(0.3).timeout.connect(
			func() -> void: _try_apply_status(target, se_data2))


## Execute an AoE ability centred on a grid tile.
## Deducts MP once, logs once, then hits every valid unit in the radius.
func _execute_aoe_ability(caster: Unit, center: Vector2i, ability: Dictionary) -> void:
	caster.mp = max(caster.mp - ability.get("mp_cost", 0), 0)
	tactical_grid.clear_highlights()
	active_command = ""
	selected_ability_id = ""
	var ab_name: String = ability.get("display_name", "?")
	log_message.emit("%s uses %s!" % [caster.display_name, ab_name])
	var targets := _get_aoe_targets(center, ability, caster)
	if targets.is_empty():
		log_message.emit("(no targets in burst)")
		return
	for tgt: Unit in targets:
		_execute_ability(caster, tgt, ability, true)


## Returns every living unit that falls inside the AoE pattern centred on `center`.
func _get_aoe_targets(center: Vector2i, ability: Dictionary, caster: Unit) -> Array[Unit]:
	var result: Array[Unit] = []
	var aoe_type:    String = ability.get("aoe_type", "")
	var target_type: String = ability.get("target_type", "enemy")
	if aoe_type == "radius":
		var radius: int = ability.get("aoe_radius", 1)
		for uid: String in units:
			var u: Unit = units[uid]
			if u.hp <= 0:
				continue
			var dist := GridSystem.manhattan(u.grid_pos, center)
			if dist > radius:
				continue
			var valid := false
			if target_type == "enemy" and u.team != caster.team:
				valid = true
			elif target_type == "ally" and u.team == caster.team:
				valid = true
			if valid:
				result.append(u)
	return result


## Melee counter-attack — never triggers a second counter (is_counter=true).
## Award JP to a unit via JobSystem. Multiplied by run boon JP bonus.
func _award_jp(unit: Unit, event_type: String) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if not gs: return
	var uid: String = unit.unit_data.id if unit.unit_data else unit.name
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
		log_message.emit("★ %s: %s reached %s!" % [unit.display_name, job_id.capitalize(), result["title"]])
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
		log_message.emit("💥 %s EXPLODES! %d fire dmg to adjacent!" % [dead_unit.display_name, dmg])
		var dirs := [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),
					 Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]
		for d in dirs:
			var nb: Vector2i = dead_unit.grid_pos + d
			for u: Unit in units:
				if u.grid_pos == nb and u.hp > 0 and u != dead_unit:
					var _damage_result := u.receive_damage(dmg, "magical")
					var vfx_n := get_node_or_null("/root/VFX")
					if vfx_n:
						(vfx_n as VFXManager).play_fire(nb)
						(vfx_n as VFXManager).play_damage_number(nb, dmg, Color(1.0,0.35,0.1))


## Handle boon on-kill effects (Champion's Grit, Vaelthorn kills).
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
			log_message.emit("💪 Champion's Grit: +%d HP, +%d Temper!" % [hp_r, tmpr_r])
	# Vaelthorn Unchained on-kill
	var ve_hp:    int = bonuses["vaelthorn_kill_hp"]
	var ve_ether: int = bonuses["vaelthorn_kill_ether"]
	if ve_hp > 0 or ve_ether > 0:
		if ve_hp > 0:    killer.heal(ve_hp)
		if ve_ether > 0: killer.ether = mini(killer.unit_data.base_stats.max_ether, killer.ether + ve_ether)


func _execute_counter_attack(counter_unit: Unit, original_attacker: Unit) -> void:
	if not is_instance_valid(counter_unit) or counter_unit.hp <= 0:
		return
	if not is_instance_valid(original_attacker) or original_attacker.hp <= 0:
		return
	var tile_c := tactical_grid.get_tile(counter_unit.grid_pos)
	var tile_t := tactical_grid.get_tile(original_attacker.grid_pos)
	var result := combat_resolver.resolve_attack(
		counter_unit, original_attacker, tile_c, tile_t, "slash", true)
	if result.get("missed", false):
		log_message.emit("%s counters but misses!" % counter_unit.display_name)
	else:
		log_message.emit("%s counters! → %d dmg" % [
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
		# Self-cast AoE (range == 0) → cast on self immediately
		if spell_range == 0 and ab.has("aoe_type"):
			_execute_aoe_ability(unit, unit.grid_pos, ab)
			return true
		var target_type: String = ab.get("target_type", "enemy")
		for uid: String in units:
			var target: Unit = units[uid]
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


# ── Input handlers ────────────────────────────────────────────────────────────

## Called every time the mouse crosses into a new grid tile.
## If an AoE ability is selected, paints the burst zone in red so the
## player can see exactly which tiles will be hit before committing.
func _on_tile_hovered(grid_pos: Vector2i) -> void:
	var tile: Dictionary = tactical_grid.get_tile(grid_pos)
	if not tile.is_empty():
		tile_info_changed.emit("%s  H:%d  Move:%d" % [
			str(tile.get("terrain", "unknown")).replace("_", " ").capitalize(),
			int(tile.get("height", 0)),
			int(tile.get("move_cost", 1)),
		])
	if active_command == "move":
		action_preview_changed.emit(_move_preview(grid_pos))
		var mover: Unit = units.get(active_unit_id)
		if mover and grid_pos in tactical_grid.move_tiles:
			var occupied: Array = []
			for uid in units:
				var u: Unit = units[uid]
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
		action_preview_changed.emit(_attack_preview_for_tile(grid_pos))
		return
	if active_command != "ability_target" or selected_ability_id == "":
		action_preview_changed.emit({})
		tactical_grid.clear_path_preview()
		tactical_grid.clear_aoe_preview()
		return
	var ability: Dictionary = AbilityDB.get_ability(selected_ability_id)
	action_preview_changed.emit(_ability_preview_for_tile(grid_pos, ability))
	if not ability.has("aoe_type"):
		tactical_grid.clear_aoe_preview()
		return
	# Only show preview when the cursor is inside ability range
	if grid_pos not in tactical_grid.ability_tiles:
		tactical_grid.clear_aoe_preview()
		return
	# Compute all tiles inside the burst
	var preview: Array[Vector2i] = []
	if ability.get("aoe_type", "") == "radius":
		var radius: int = ability.get("aoe_radius", 1)
		for dx: int in range(-radius, radius + 1):
			for dy: int in range(-radius, radius + 1):
				var check := grid_pos + Vector2i(dx, dy)
				if GridSystem.manhattan(check, grid_pos) <= radius \
						and tactical_grid.get_tile(check) != {}:
					preview.append(check)
	tactical_grid.show_aoe_preview(preview)


func _on_tile_clicked(grid_pos: Vector2i) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	if is_resolving_action:
		return
	var unit: Unit = units.get(active_unit_id)
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
		await get_tree().create_timer(0.20).timeout
		active_unit_has_moved = true
		is_resolving_action = false
		command_hint_changed.emit("Move complete. Choose Attack, Ability, or Wait.")
		_emit_action_state()
	elif active_command == "ability_target" and selected_ability_id != "":
		# AoE abilities can be targeted on empty tiles
		var ability: Dictionary = AbilityDB.get_ability(selected_ability_id)
		if not ability.has("aoe_type"):
			return   # single-target abilities require clicking a unit
		if grid_pos not in tactical_grid.ability_tiles:
			return
		_queue_aoe(unit, grid_pos, ability)


func _on_unit_clicked(unit_id: String) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	if is_resolving_action:
		return
	if active_command == "attack":
		var attacker: Unit = units.get(active_unit_id)
		var target:   Unit = units.get(unit_id)
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
			tactical_grid.clear_target_lock()
			return
		_queue_attack(attacker, target)
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
			command_hint_changed.emit("%s is outside %s range." % [target.display_name, ability.get("display_name", selected_ability_id)])
			action_preview_changed.emit({})
			tactical_grid.clear_target_lock()
			return
		if ability.has("aoe_type"):
			_queue_aoe(caster, target.grid_pos, ability)
		else:
			_queue_ability(caster, target, ability)


func confirm_pending_action() -> void:
	if current_phase != Phase.PLAYER_TURN or is_resolving_action or pending_action.is_empty():
		return
	var kind := str(pending_action.get("kind", ""))
	match kind:
		"attack":
			_resolve_pending_attack()
		"ability":
			_resolve_pending_ability()
		"aoe":
			_resolve_pending_aoe()


func cancel_pending_action() -> void:
	if pending_action.is_empty():
		return
	pending_action.clear()
	tactical_grid.clear_target_lock()
	action_preview_changed.emit({})
	command_hint_changed.emit("Cancelled. Choose a target or another command.")
	_emit_action_state()


func _queue_attack(attacker: Unit, target: Unit) -> void:
	pending_action = {
		"kind": "attack",
		"attacker_id": attacker.unit_id,
		"target_id": target.unit_id,
	}
	tactical_grid.show_target_lock(target.grid_pos)
	action_preview_changed.emit(_attack_preview_for_tile(target.grid_pos))
	command_hint_changed.emit("Confirm attack or cancel.")
	_emit_action_state()


func _queue_ability(caster: Unit, target: Unit, ability: Dictionary) -> void:
	pending_action = {
		"kind": "ability",
		"caster_id": caster.unit_id,
		"target_id": target.unit_id,
		"ability_id": selected_ability_id,
	}
	tactical_grid.show_target_lock(target.grid_pos)
	action_preview_changed.emit(_ability_preview_for_tile(target.grid_pos, ability))
	command_hint_changed.emit("Confirm %s or cancel." % ability.get("display_name", selected_ability_id))
	_emit_action_state()


func _queue_aoe(caster: Unit, center: Vector2i, ability: Dictionary) -> void:
	pending_action = {
		"kind": "aoe",
		"caster_id": caster.unit_id,
		"center": center,
		"ability_id": selected_ability_id,
	}
	tactical_grid.show_target_lock(center)
	action_preview_changed.emit(_ability_preview_for_tile(center, ability))
	command_hint_changed.emit("Confirm %s or cancel." % ability.get("display_name", selected_ability_id))
	_emit_action_state()


func _resolve_pending_attack() -> void:
	var attacker: Unit = units.get(str(pending_action.get("attacker_id", "")))
	var target: Unit = units.get(str(pending_action.get("target_id", "")))
	if not attacker or not target or target.hp <= 0:
		cancel_pending_action()
		return
	is_resolving_action = true
	var tile_att := tactical_grid.get_tile(attacker.grid_pos)
	var tile_tar := tactical_grid.get_tile(target.grid_pos)
	var atk_vfx: String = "arrow" if attacker.unit_data.base_stats.attack_range_max > 1 else "slash"
	var result := combat_resolver.resolve_attack(attacker, target, tile_att, tile_tar, atk_vfx)
	pending_action.clear()
	tactical_grid.clear_target_lock()
	tactical_grid.clear_highlights()
	active_command = ""
	if result.get("missed", false):
		log_message.emit("%s swings but misses! (blind)" % attacker.display_name)
	else:
		var ftag := " [BACK ATTACK!]" if result.get("flank", "") == "back" \
			else (" [flank]" if result.get("flank", "") == "side" else "")
		log_message.emit("%s hits %s for %d dmg!%s" % [attacker.display_name, target.display_name, result.get("hp_damage", 0), ftag])
	if result.get("counter", false):
		get_tree().create_timer(0.6).timeout.connect(
			func() -> void: _execute_counter_attack(target, attacker))
	active_unit_has_acted = true
	is_resolving_action = false
	_end_player_turn()


func _resolve_pending_ability() -> void:
	var caster: Unit = units.get(str(pending_action.get("caster_id", "")))
	var target: Unit = units.get(str(pending_action.get("target_id", "")))
	var ability_id := str(pending_action.get("ability_id", ""))
	var ability: Dictionary = AbilityDB.get_ability(ability_id)
	if not caster or not target or target.hp <= 0 or ability.is_empty():
		cancel_pending_action()
		return
	is_resolving_action = true
	pending_action.clear()
	tactical_grid.clear_target_lock()
	_execute_ability(caster, target, ability)
	active_unit_has_acted = true
	is_resolving_action = false
	_end_player_turn()


func _resolve_pending_aoe() -> void:
	var caster: Unit = units.get(str(pending_action.get("caster_id", "")))
	var center: Vector2i = pending_action.get("center", Vector2i(-1, -1))
	var ability_id := str(pending_action.get("ability_id", ""))
	var ability: Dictionary = AbilityDB.get_ability(ability_id)
	if not caster or ability.is_empty():
		cancel_pending_action()
		return
	is_resolving_action = true
	pending_action.clear()
	tactical_grid.clear_target_lock()
	_execute_aoe_ability(caster, center, ability)
	active_unit_has_acted = true
	is_resolving_action = false
	_end_player_turn()


func _end_player_turn() -> void:
	var unit: Unit = units.get(active_unit_id)
	if unit:
		unit.end_turn()
		_process_terrain_hazards(unit)
	turn_ended.emit(active_unit_id)
	active_command = ""
	selected_ability_id = ""
	pending_action.clear()
	active_unit_has_moved = false
	active_unit_has_acted = false
	action_preview_changed.emit({})
	tactical_grid.clear_highlights()
	command_hint_changed.emit("Resolving turn...")
	_emit_action_state()
	_set_phase(Phase.RESOLVE)


func _unit_at_pos(grid_pos: Vector2i) -> Unit:
	for uid in units:
		var unit: Unit = units[uid]
		if unit.grid_pos == grid_pos and unit.hp > 0:
			return unit
	return null


func _move_preview(grid_pos: Vector2i) -> Dictionary:
	var unit: Unit = units.get(active_unit_id)
	if not unit or grid_pos not in tactical_grid.move_tiles:
		return {}
	return {
		"visible": true,
		"mode": "Move",
		"actor": unit.display_name,
		"actor_portrait": _portrait_path(unit),
		"target": "%d,%d" % [grid_pos.x, grid_pos.y],
		"target_portrait": "",
		"action": "Reposition",
		"amount_label": "No damage",
		"hit": "100%",
		"crit": "--",
		"note": "Turn continues after moving.",
	}


func _attack_preview_for_tile(grid_pos: Vector2i) -> Dictionary:
	var attacker: Unit = units.get(active_unit_id)
	var target := _unit_at_pos(grid_pos)
	if not attacker or not target or target.team == attacker.team or grid_pos not in tactical_grid.attack_tiles:
		return {}
	var tile_att := tactical_grid.get_tile(attacker.grid_pos)
	var tile_tar := tactical_grid.get_tile(target.grid_pos)
	var amount := _predict_attack_damage(attacker, target, tile_att, tile_tar)
	var flank := _flank_label(attacker, target)
	var counter := "Counter possible" if _target_can_counter(attacker, target) else "No counter"
	return {
		"visible": true,
		"mode": "Attack",
		"actor": attacker.display_name,
		"actor_portrait": _portrait_path(attacker),
		"target": target.display_name,
		"target_portrait": _portrait_path(target),
		"action": "Basic attack",
		"amount_label": "%d damage" % amount,
		"hit": "95%",
		"crit": "10%",
		"note": "%s | %s | HP %d -> %d" % [flank, counter, target.hp, max(target.hp - amount, 0)],
	}


func _ability_preview_for_tile(grid_pos: Vector2i, ability: Dictionary) -> Dictionary:
	var caster: Unit = units.get(active_unit_id)
	if not caster or grid_pos not in tactical_grid.ability_tiles:
		return {}
	var target := _unit_at_pos(grid_pos)
	var target_name := "Area"
	var amount_label := "Preview"
	var note := "Targets tiles in the highlighted area."
	var target_type: String = ability.get("target_type", "enemy")
	if target:
		var valid_target := (target_type == "enemy" and target.team != caster.team) or \
			(target_type == "ally" and target.team == caster.team)
		if not valid_target:
			return {}
		target_name = target.display_name
		var spell_type: String = ability.get("spell_type", "fire")
		if spell_type == "cure":
			var heal_amount: int = int(ability.get("base_power", 100))
			amount_label = "%d heal" % heal_amount
			note = "HP %d -> %d" % [target.hp, min(target.hp + heal_amount, target.unit_data.base_stats.hp)]
		elif spell_type == "buff":
			amount_label = "Status"
			note = "Applies %s" % str(ability.get("status_effect", {}).get("id", "buff")).capitalize()
		elif spell_type == "physical":
			var amount := _predict_attack_damage(caster, target, tactical_grid.get_tile(caster.grid_pos), tactical_grid.get_tile(target.grid_pos))
			amount_label = "%d damage" % amount
			note = "HP %d -> %d" % [target.hp, max(target.hp - amount, 0)]
		else:
			var amount := _predict_spell_damage(caster, target, ability)
			amount_label = "%d damage" % amount
			note = "%s affinity | HP %d -> %d" % [_affinity_label(target, spell_type), target.hp, max(target.hp - amount, 0)]
	return {
		"visible": true,
		"mode": "Ability",
		"actor": caster.display_name,
		"actor_portrait": _portrait_path(caster),
		"target": target_name,
		"target_portrait": _portrait_path(target) if target else "",
		"action": ability.get("display_name", selected_ability_id),
		"amount_label": amount_label,
		"hit": "100%",
		"crit": "--",
		"note": note,
	}


func _predict_attack_damage(attacker: Unit, target: Unit, tile_attacker: Dictionary, tile_target: Dictionary) -> int:
	var raw: float = attacker.unit_data.base_stats.physical * 1.2
	if attacker.has_meta("dmg_mult"):
		raw *= attacker.get_meta("dmg_mult", 1.0)
	if attacker.has_meta("prefixes"):
		for pfx: Dictionary in attacker.get_meta("prefixes", []):
			if pfx.get("id","") == "berserker" and attacker.hp < attacker.unit_data.base_stats.hp * 0.5:
				raw *= pfx.get("conditional",{}).get("dmg", 1.25)
	var att_h: int = tile_attacker.get("height", 0)
	var tar_h: int = tile_target.get("height", 0)
	var height_m: float = 1.0
	if att_h > tar_h:
		height_m = 1.15
	elif att_h < tar_h:
		height_m = 0.9
	return max(0, int(round(raw * height_m * _get_flank_multiplier(attacker, target))))


func _predict_spell_damage(caster: Unit, target: Unit, ability: Dictionary) -> int:
	var spell_type: String = ability.get("spell_type", "fire")
	var base_power: int = ability.get("base_power", 100)
	var raw: float = caster.unit_data.base_stats.magic * (float(base_power) / 100.0)
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	raw *= bonuses["elemental_mult"].get(spell_type, 1.0)
	var affinity: float = 1.0
	if target.unit_data and not target.unit_data.elemental_affinities.is_empty():
		affinity = target.unit_data.elemental_affinities.get(spell_type, 1.0)
	if target.has_meta("elite_tier"):
		var immune: Array = target.get_meta("immune", [])
		if spell_type in immune:
			affinity = 0.0
	var damage := int(round(raw * affinity))
	if bonuses["brand_bonus"] > 0.0 and target.has_status("burn"):
		damage = int(round(float(damage) * (1.0 + bonuses["brand_bonus"])))
	return max(0, damage)


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
	var defeated_unit: Unit = units.get(unit_id)
	if defeated_unit:
		tactical_grid.remove_unit_visual(unit_id, defeated_unit.grid_pos)
	unit_defeated.emit(unit_id)
	if defeated_unit:
		log_message.emit("%s was defeated!" % defeated_unit.display_name)
	objective_tracker.on_unit_defeated(unit_id)
	turn_order.remove_unit(unit_id)
	call_deferred("_check_objective_after_defeat")


func _check_objective_after_defeat() -> void:
	if current_phase in [Phase.VICTORY, Phase.DEFEAT, Phase.CHECK_OBJECTIVE]:
		return
	if is_resolving_action:
		return
	if objective_tracker.is_victory() or objective_tracker.is_defeat():
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
