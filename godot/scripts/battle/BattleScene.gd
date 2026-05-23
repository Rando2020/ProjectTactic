class_name BattleScene
extends Node2D

@onready var battle_manager: BattleManager = $BattleManager
@onready var tactical_grid: TacticalGrid = $BattleManager/TacticalGrid
@onready var battle_ui: BattleUI = $BattleUI

var unit_scene: PackedScene = preload("res://scenes/Unit.tscn")
var _battle_camera: Camera2D
var _camera_base_position: Vector2 = Vector2(320.0, 245.0)
var _camera_zoom_value: float = 0.92
var _camera_bounds: Rect2 = Rect2()
var _camera_dragging: bool = false
var _camera_drag_last: Vector2 = Vector2.ZERO
var _camera_shake_strength: float = 0.0
var _camera_shake_timer: float = 0.0

const CAMERA_PAN_SPEED := 560.0
const CAMERA_MIN_ZOOM := 0.55
const CAMERA_MAX_ZOOM := 1.40
const CAMERA_ZOOM_STEP := 0.08

## Set via GameState.selected_map_index before loading this scene.
## Kept as @export so you can still override in the editor during dev.
@export var map_index: int = 0

var _map_data: MapData
var _defeated_enemies: Array[Dictionary] = []
var _elite_system:     EliteSystem = null

const SPRITE_PATHS := {
	"zane":         "res://assets/sprites/units/zane.png",
	"mira":         "res://assets/sprites/units/mira.png",
	"kael":         "res://assets/sprites/units/kael.png",
	"lyra":         "res://assets/sprites/units/lyra.png",
	"null_drake":   "res://assets/sprites/units/null_drake.png",
	"storm_imp":    "res://assets/sprites/units/storm_imp.png",
	"void_cultist": "res://assets/sprites/units/void_cultist.png",
}

const DEFAULT_BATTLE_MUSIC_PATH := "res://assets/music/steel-march-echo-battle.wav"
const RunBonusesUtil := preload("res://scripts/roguelike/RunBonuses.gd")

var _battle_music_player: AudioStreamPlayer


func _ready() -> void:
	_setup_camera()
	_start_battle_music()

	var gs: Node = get_node_or_null("/root/GameState")

	# Use procedurally generated map when inside a roguelike run
	if gs and gs.active_run and not gs.active_run.completed:
		var mg := MapGenerator.new()
		var run: RunState = gs.active_run
		var current_node: Dictionary = run.get_current_node()
		_map_data = mg.generate_floor(run.current_floor, run.seed)
		if current_node.get("type", "") == "elite":
			_map_data.display_name += " - Elite Route"
			_map_data.objective_label = "Defeat the elite patrol"
			_map_data.reward_gold = int(float(_map_data.reward_gold) * 1.55)
			_map_data.reward_jp = int(float(_map_data.reward_jp) * 1.45)
		elif current_node.get("type", "") == "mystery_ambush":
			_map_data.display_name += " - Ambush"
			_map_data.objective_label = "Survive the ambush"
			_map_data.reward_gold = int(float(_map_data.reward_gold) * 1.35)
			_map_data.reward_jp = int(float(_map_data.reward_jp) * 1.25)
		_elite_system = EliteSystem.new()
	else:
		# Hardcoded maps for editor / debug
		if gs: map_index = gs.selected_map_index
		_map_data = _create_ashvale_map() if map_index == 0 else _create_crypt_map()

	tactical_grid.initialize_from_map(_map_data)

	_frame_battlefield_camera()

	var player_units := _spawn_player_units()
	var enemy_units  := _spawn_enemy_units()

	for unit in player_units:
		tactical_grid.place_unit(unit, unit.grid_pos)
	for unit in enemy_units:
		tactical_grid.place_unit(unit, unit.grid_pos)
	tactical_grid.unit_visual_position_changed.connect(_on_unit_visual_position_changed)

	var all_units: Array[Unit] = []
	all_units.append_array(player_units)
	all_units.append_array(enemy_units)

	battle_ui.setup(battle_manager)
	if gs and gs.active_run:
		_apply_boon_battle_start_effects(gs, all_units)
		gs.run_floor_reached = max(gs.run_floor_reached, gs.active_run.current_floor)
	battle_manager.start_battle(_map_data, all_units)

	battle_manager.battle_won.connect(_on_battle_won)
	battle_manager.battle_lost.connect(_on_battle_lost)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.unit_defeated.connect(_on_unit_defeated)
	battle_manager.unit_moved.connect(_on_unit_moved)
	battle_manager.combat_resolver.combat_resolved.connect(_on_combat_resolved)


func _start_battle_music() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_battle_music_player = AudioStreamPlayer.new()
	_battle_music_player.stream = load(DEFAULT_BATTLE_MUSIC_PATH)
	_battle_music_player.bus = "Music"
	_battle_music_player.volume_db = -8.0
	_battle_music_player.finished.connect(_on_battle_music_finished)
	add_child(_battle_music_player)
	_battle_music_player.play()


func _on_battle_music_finished() -> void:
	if _battle_music_player:
		_battle_music_player.play()


func _fade_battle_music(target_db: float = -30.0, duration: float = 1.1) -> void:
	if not _battle_music_player or not _battle_music_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_battle_music_player, "volume_db", target_db, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _exit_tree() -> void:
	if _battle_music_player:
		if _battle_music_player.finished.is_connected(_on_battle_music_finished):
			_battle_music_player.finished.disconnect(_on_battle_music_finished)
		_battle_music_player.stop()
		_battle_music_player.stream = null
		_battle_music_player.queue_free()
		_battle_music_player = null


func _setup_camera() -> void:
	_battle_camera = Camera2D.new()
	_battle_camera.enabled = true
	_battle_camera.position = _camera_base_position
	_battle_camera.zoom = Vector2(_camera_zoom_value, _camera_zoom_value)
	add_child(_battle_camera)


func _frame_battlefield_camera() -> void:
	if not _battle_camera:
		return
	var bounds := tactical_grid.get_board_bounds().grow(72.0)
	_camera_bounds = bounds.grow(260.0)
	var play_area := Vector2(620.0, 700.0)
	var zoom_x: float = play_area.x / max(bounds.size.x, 1.0)
	var zoom_y: float = play_area.y / max(bounds.size.y, 1.0)
	_camera_zoom_value = clamp(min(zoom_x, zoom_y), 0.72, 1.15)
	_camera_base_position = bounds.get_center()
	_camera_base_position.x += 26.0
	_battle_camera.position = _camera_base_position
	_battle_camera.zoom = Vector2(_camera_zoom_value, _camera_zoom_value)
	_clamp_camera_to_board()


func _process(delta: float) -> void:
	if not _battle_camera:
		return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction != Vector2.ZERO:
		_battle_camera.position += direction.normalized() * CAMERA_PAN_SPEED * delta / max(_camera_zoom_value, 0.1)
		_clamp_camera_to_board()
	_update_camera_shake(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not _battle_camera:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_set_camera_zoom(_camera_zoom_value + CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_set_camera_zoom(_camera_zoom_value - CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			_camera_dragging = event.pressed
			_camera_drag_last = event.position
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _camera_dragging:
		var drag_delta: Vector2 = event.position - _camera_drag_last
		_camera_drag_last = event.position
		_battle_camera.position -= drag_delta / max(_camera_zoom_value, 0.1)
		_clamp_camera_to_board()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_reset_camera()
			get_viewport().set_input_as_handled()


func _set_camera_zoom(value: float) -> void:
	_camera_zoom_value = clamp(value, CAMERA_MIN_ZOOM, CAMERA_MAX_ZOOM)
	_battle_camera.zoom = Vector2(_camera_zoom_value, _camera_zoom_value)
	_clamp_camera_to_board()


func _reset_camera() -> void:
	if not _battle_camera:
		return
	var tween := create_tween()
	tween.tween_property(_battle_camera, "position", _camera_base_position, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_set_camera_zoom(clamp(_camera_zoom_value, CAMERA_MIN_ZOOM, CAMERA_MAX_ZOOM))


func _clamp_camera_to_board() -> void:
	if not _battle_camera or _camera_bounds.size == Vector2.ZERO:
		return
	_battle_camera.position.x = clamp(_battle_camera.position.x, _camera_bounds.position.x, _camera_bounds.end.x)
	_battle_camera.position.y = clamp(_battle_camera.position.y, _camera_bounds.position.y, _camera_bounds.end.y)


func _on_turn_started(unit_id: String, _team: String) -> void:
	var unit: Unit = battle_manager.units.get(unit_id)
	if not unit or not _battle_camera:
		return
	var focus := tactical_grid.get_unit_focus_position(unit.grid_pos)
	var target := _camera_base_position
	var margin := Vector2(155.0 / _camera_zoom_value, 120.0 / _camera_zoom_value)
	var delta := focus - _camera_base_position
	if abs(delta.x) > margin.x:
		target.x += sign(delta.x) * min(abs(delta.x) - margin.x, 110.0)
	if abs(delta.y) > margin.y:
		target.y += sign(delta.y) * min(abs(delta.y) - margin.y, 80.0)
	var tween := create_tween()
	tween.tween_property(_battle_camera, "position", target, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_unit_moved(_unit_id: String, _from: Vector2i, to: Vector2i) -> void:
	if not _battle_camera:
		return
	var target := tactical_grid.get_unit_focus_position(to)
	var tween := create_tween()
	tween.tween_property(_battle_camera, "position", target, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_unit_visual_position_changed(_unit_id: String, world_pos: Vector2) -> void:
	if not _battle_camera:
		return
	_battle_camera.global_position = world_pos
	_clamp_camera_to_board()


func _on_combat_resolved(result: Dictionary) -> void:
	if result.get("missed", false) == true:
		_camera_shake(2.0, 0.10)
		return
	var amount := int(result.get("hp_damage", result.get("damage", 0)))
	if amount <= 0:
		return
	_camera_shake(clamp(float(amount) * 0.10, 2.5, 8.0), 0.16)


func _camera_shake(strength: float, duration: float) -> void:
	_camera_shake_strength = max(_camera_shake_strength, strength)
	_camera_shake_timer = max(_camera_shake_timer, duration)


func _update_camera_shake(delta: float) -> void:
	if _camera_shake_timer <= 0.0 or not _battle_camera:
		return
	_camera_shake_timer = max(_camera_shake_timer - delta, 0.0)
	var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _camera_shake_strength
	_battle_camera.offset = offset
	_camera_shake_strength = lerpf(_camera_shake_strength, 0.0, min(delta * 12.0, 1.0))
	if _camera_shake_timer <= 0.0:
		_battle_camera.offset = Vector2.ZERO


func _on_unit_defeated(unit_id: String) -> void:
	var u: Unit = battle_manager.units.get(unit_id)
	if u:
		_camera_shake(7.0, 0.20)
	if u and u.team == "enemy":
		_defeated_enemies.append({
			"id":         unit_id,
			"name":       u.unit_data.display_name if u.unit_data else unit_id,
			"elite_tier": u.get_meta("elite_tier","") if u.has_meta("elite_tier") else "",
			"jp_mult":    float(u.get_meta("jp_mult", 1.0)) if u.has_meta("jp_mult") else 1.0,
		})


func _on_battle_won(rewards: Dictionary) -> void:
	var player_ids: Array[String] = []
	for uid in battle_manager.units:
		var u: Unit = battle_manager.units[uid]
		if u.team == "player": player_ids.append(uid)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs:
		gs.apply_victory(_map_data.id, rewards, player_ids)

		if gs.active_run:
			# Generate loot, show spoils, then route to the next run node.
			var ls    := LootSystem.new()
			var loot  := ls.generate_battle_loot(_defeated_enemies, gs.active_run.seed, gs.active_run.current_floor)
			gs.pending_loot.clear()
			for item in loot: gs.run_inventory.append(item)
			var elite_n := _defeated_enemies.filter(func(e: Dictionary) -> bool: return e.get("elite_tier","") != "").size()
			gs.active_run.elite_kills += elite_n

			var rm: Node = get_node_or_null("/root/RunManager")
			var floor_num: int = int(gs.active_run.current_floor)
			var is_boss: bool = floor_num >= 10
			var has_elite := _defeated_enemies.any(func(e: Dictionary) -> bool: return e.get("elite_tier","") != "")
			if rm and rm.is_run_active:
				rm.award_stage_reward(floor_num, has_elite, is_boss)

			battle_ui.show_spoils(rewards, loot)
			await battle_ui.spoils_continue_requested

			if is_boss:
				if rm and rm.is_run_active:
					rm.end_run(true)
				get_tree().change_scene_to_file("res://scenes/ResultsScreen.tscn")
				return

			gs.active_run.complete_current_node()
			var next_nd: Dictionary = gs.active_run.get_current_node()
			if next_nd.get("type","") == "boon_pick":
				var bs := BoonSystem.new()
				var owned: Array = gs.active_run.active_boons.map(func(b: Dictionary) -> String: return b.get("id",""))
				gs.pending_boon_offers = bs.generate_offers(gs.active_run.seed * 17 + gs.active_run.current_floor * 3, gs.active_run.current_floor, owned)
			get_tree().change_scene_to_file("res://scenes/StageSelect.tscn")
			return
	battle_ui.show_spoils(rewards, [])
	await battle_ui.spoils_continue_requested
	get_tree().change_scene_to_file("res://scenes/ResultsScreen.tscn")
func _on_battle_lost() -> void:
	_fade_battle_music()
	await get_tree().create_timer(0.85).timeout
	get_tree().change_scene_to_file("res://scenes/StageSelect.tscn")


# ── Map data ──────────────────────────────────────────────────────────────────

func _create_ashvale_map() -> MapData:
	var map := MapData.new()
	map.id = "ashvale_road_01"
	map.display_name = "Ashvale Road"
	map.map_width = 10
	map.map_height = 8
	map.default_terrain = "grass"
	map.objective_type = "defeat_all"
	map.objective_label = "Defeat all enemies"
	map.reward_gold = 150
	map.reward_jp = 40
	map.tile_overrides = [
		{"x": 3, "y": 3, "terrain": "road", "height": 0},
		{"x": 4, "y": 3, "terrain": "road", "height": 0},
		{"x": 5, "y": 3, "terrain": "road", "height": 0},
		{"x": 3, "y": 4, "terrain": "road", "height": 0},
		{"x": 4, "y": 4, "terrain": "road", "height": 0},
		{"x": 5, "y": 4, "terrain": "road", "height": 0},
		{"x": 0, "y": 2, "terrain": "shallow_water", "height": 0},
		{"x": 1, "y": 2, "terrain": "shallow_water", "height": 0},
		{"x": 0, "y": 3, "terrain": "shallow_water", "height": 0},
		{"x": 1, "y": 1, "terrain": "grass_flowers", "height": 0},
		{"x": 2, "y": 1, "terrain": "brush", "height": 0},
		{"x": 6, "y": 5, "terrain": "grass_flowers", "height": 0},
		{"x": 8, "y": 4, "terrain": "brush", "height": 0},
		{"x": 7, "y": 0, "terrain": "stone", "height": 2},
		{"x": 8, "y": 0, "terrain": "stone", "height": 2},
		{"x": 7, "y": 1, "terrain": "high_ground", "height": 1},
		{"x": 8, "y": 1, "terrain": "high_ground", "height": 1},
		{"x": 9, "y": 5, "terrain": "shrine", "height": 0},
		{"x": 2, "y": 7, "terrain": "road", "height": 0},
		{"x": 3, "y": 7, "terrain": "road", "height": 0},
		{"x": 4, "y": 7, "terrain": "road", "height": 0},
	]
	map.prop_overrides = [
		{"x": 2, "y": 1, "prop": "leafy_bush", "offset_y": -10},
		{"x": 6, "y": 0, "prop": "ruin_block", "offset_y": -8},
		{"x": 6, "y": 5, "prop": "tree_stump", "offset_y": -8},
		{"x": 9, "y": 4, "prop": "mossy_rock", "offset_y": -6},
	]
	return map


func _create_crypt_map() -> MapData:
	var map := MapData.new()
	map.id           = "crypt_of_echoes_01"
	map.display_name = "Crypt of Echoes"
	map.map_width    = 10
	map.map_height   = 8
	map.default_terrain = "stone"
	map.objective_type  = "defeat_all"
	map.objective_label = "Defeat all enemies"
	map.reward_gold  = 220
	map.reward_jp    = 60
	map.tile_overrides = [
		{"x": 0, "y": 0, "terrain": "wall", "height": 0},
		{"x": 1, "y": 0, "terrain": "wall", "height": 0},
		{"x": 8, "y": 0, "terrain": "wall", "height": 0},
		{"x": 9, "y": 0, "terrain": "wall", "height": 0},
		{"x": 0, "y": 1, "terrain": "wall", "height": 0},
		{"x": 0, "y": 2, "terrain": "wall", "height": 0},
		{"x": 0, "y": 5, "terrain": "wall", "height": 0},
		{"x": 0, "y": 6, "terrain": "wall", "height": 0},
		{"x": 9, "y": 1, "terrain": "wall", "height": 0},
		{"x": 9, "y": 2, "terrain": "wall", "height": 0},
		{"x": 9, "y": 5, "terrain": "wall", "height": 0},
		{"x": 9, "y": 6, "terrain": "wall", "height": 0},
		{"x": 2, "y": 2, "terrain": "wall", "height": 0},
		{"x": 7, "y": 2, "terrain": "wall", "height": 0},
		{"x": 2, "y": 5, "terrain": "wall", "height": 0},
		{"x": 7, "y": 5, "terrain": "wall", "height": 0},
		{"x": 4, "y": 3, "terrain": "high_ground", "height": 2},
		{"x": 5, "y": 3, "terrain": "high_ground", "height": 2},
		{"x": 4, "y": 4, "terrain": "high_ground", "height": 2},
		{"x": 5, "y": 4, "terrain": "high_ground", "height": 2},
		{"x": 1, "y": 3, "terrain": "shallow_water", "height": 0},
		{"x": 1, "y": 4, "terrain": "shallow_water", "height": 0},
		{"x": 8, "y": 3, "terrain": "shallow_water", "height": 0},
		{"x": 8, "y": 4, "terrain": "shallow_water", "height": 0},
		{"x": 4, "y": 0, "terrain": "shrine", "height": 0},
		{"x": 5, "y": 0, "terrain": "shrine", "height": 0},
		{"x": 3, "y": 2, "terrain": "burning", "height": 0},
		{"x": 6, "y": 2, "terrain": "burning", "height": 0},
		{"x": 3, "y": 5, "terrain": "burning", "height": 0},
		{"x": 6, "y": 5, "terrain": "burning", "height": 0},
		{"x": 3, "y": 6, "terrain": "road", "height": 0},
		{"x": 4, "y": 6, "terrain": "road", "height": 0},
		{"x": 5, "y": 6, "terrain": "road", "height": 0},
		{"x": 6, "y": 6, "terrain": "road", "height": 0},
		{"x": 3, "y": 7, "terrain": "road", "height": 0},
		{"x": 4, "y": 7, "terrain": "road", "height": 0},
		{"x": 5, "y": 7, "terrain": "road", "height": 0},
		{"x": 6, "y": 7, "terrain": "road", "height": 0},
	]
	return map


# ── Unit spawning ─────────────────────────────────────────────────────────────

func _apply_boon_battle_start_effects(_gs: Node, all_units: Array[Unit]) -> void:
	var bonuses: Dictionary = RunBonusesUtil.for_current_run()
	var move_bonus: int = int(bonuses.get("move_bonus", 0))
	var temper_bonus: int = int(bonuses.get("max_temper_bonus", 0))
	var damage_mult: float = float(bonuses.get("battle_damage_mult", 1.0))
	for unit in all_units:
		if unit.team != "player" or not unit.unit_data:
			continue
		if move_bonus != 0:
			unit.unit_data.base_stats.move = max(1, unit.unit_data.base_stats.move + move_bonus)
		if temper_bonus != 0:
			unit.unit_data.base_stats.max_temper += temper_bonus
			unit.temper = min(unit.unit_data.base_stats.max_temper, unit.temper + temper_bonus)
		if damage_mult > 1.0:
			unit.set_meta("dmg_mult", damage_mult)
	var effects: Array = bonuses.get("battle_start_effects", [])
	for fx: Dictionary in effects:
		match fx.get("trigger",""):

			"ignite_all_terrain", "ignite_all":
				# Ignareth Unchained — all natural terrain becomes burning
				for pos in tactical_grid.tiles.keys():
					var t: String = tactical_grid.tiles[pos].get("terrain","")
					if t in ["grass","road","brush"]:
						tactical_grid.tiles[pos]["terrain"] = "burning"
				tactical_grid.redraw_base_tiles()
				battle_manager.log_message.emit("Ignareth Unchained: all terrain ignites!")

			"vaelthorn_curse_all", "curse_all":
				# Vaelthorn Unchained — all enemies start Cursed (2t)
				for unit in all_units:
					if unit.team == "enemy" and unit.hp > 0:
						unit.apply_status(_make_status("burn", "Burn", 2, 0.0, "fire"))
				battle_manager.log_message.emit("Vaelthorn Unchained: all enemies are cursed!")

			"summon_tide":
				# Nerevan's Veil — 3x3 water at centre
				var cx: int = floori(float(tactical_grid.map_data.map_width) / 2.0)
				var cy: int = floori(float(tactical_grid.map_data.map_height) / 2.0)
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var p := Vector2i(cx+dx, cy+dy)
						if tactical_grid.tiles.has(p):
							tactical_grid.tiles[p]["terrain"] = "shallow_water"
				tactical_grid.redraw_base_tiles()
				battle_manager.log_message.emit("Nerevan's Veil: a tide rises!")

			"vaelthorn_bargain":
				# Vaelthorn's Bargain — sacrifice HP for damage bonus
				var cost: float = fx.get("hp_cost", 0.2)
				for unit in all_units:
					if unit.team == "player":
						var sacrifice: int = int(float(unit.unit_data.base_stats.hp) * cost)
						unit.hp = max(1, unit.hp - sacrifice)
						unit._update_hp_bar()
				battle_manager.log_message.emit("Vaelthorn's Bargain: HP sacrificed for power!")


func _make_status(status_id: String, display_name: String, turns: int, magnitude: float, damage_type: String = "pure") -> StatusEffect:
	var status := StatusEffect.new()
	status.status_id = status_id
	status.display_name = display_name
	status.duration = turns
	status.magnitude = magnitude
	status.damage_type = damage_type
	return status


func _spawn_player_units() -> Array[Unit]:
	var gs: Node = get_node_or_null("/root/GameState")
	var result: Array[Unit] = []
	result.append(_make_unit("zane", "Zane", "player", Vector2i(1, 6),
		320, 90,  4, 2, 8, 42, 48, 80,  110,
		gs.get_all_abilities("zane") if gs else ["mighty_strike", "wind_slash"]))
	result.append(_make_unit("mira", "Mira Vey", "player", Vector2i(2, 6),
		280, 120, 4, 2, 7, 28, 54, 65,  130,
		gs.get_all_abilities("mira") if gs else ["fire", "thunder", "blizzard", "cure", "holy"]))
	result.append(_make_unit("kael", "Kael", "player", Vector2i(1, 7),
		380, 55,  4, 2, 6, 55, 32, 110, 70,
		gs.get_all_abilities("kael") if gs else ["mighty_strike"]))
	result.append(_make_unit("lyra", "Lyra", "player", Vector2i(0, 7),
		240, 70, 4, 2, 9, 52, 18, 55, 65,
		gs.get_all_abilities("lyra") if gs else ["pin_shot"],
		{}, 2, 4))
	# Apply curse move penalty
	var bonuses := RunBonuses.for_current_run()
	var move_pen: int = bonuses.get("curse_move_penalty", 0)

	# Apply MetaProgression permanent stat bonuses
	var meta: Node = get_node_or_null("/root/MetaProgression")
	if meta:
		var hp_bonus:   int = meta.get_stat_bonus("max_hp")
		var phys_bonus: int = meta.get_stat_bonus("physical")
		var mag_bonus:  int = meta.get_stat_bonus("magic")
		for unit in result:
			if unit.unit_data and unit.unit_data.base_stats:
				unit.unit_data.base_stats.hp       += hp_bonus
				unit.unit_data.base_stats.physical += phys_bonus
				unit.unit_data.base_stats.magic    += mag_bonus
			if move_pen != 0:
				unit.unit_data.base_stats.movement = max(1, unit.unit_data.base_stats.movement + move_pen)
	return result


func _spawn_enemy_units() -> Array[Unit]:
	var result: Array[Unit] = []

	# ── Procedural spawns from MapGenerator ─────────────────────────────────
	if _map_data and _map_data.enemy_spawns.size() > 0:
		for spawn in _map_data.enemy_spawns:
			var unit := _make_unit(
				spawn.get("unit_id", "null_drake"),
				spawn.get("name",    "Enemy"),
				"enemy",
				Vector2i(spawn.get("x", 5), spawn.get("y", 2)),
				spawn.get("hp",          120),
				spawn.get("mp",           35),
				spawn.get("move",          3),
				spawn.get("jump",          1),
				spawn.get("speed",         6),
				spawn.get("physical",     38),
				spawn.get("magic",        30),
				spawn.get("max_temper",   80),
				spawn.get("max_ether",    60),
				spawn.get("abilities",    []),
				spawn.get("affinities",   {}),
			)
			result.append(unit)
	else:
		# ── Hardcoded fallback for editor / debug ────────────────────────────
		result.append(_make_unit("null_drake", "Null Drake", "enemy", Vector2i(7, 2),
			120, 35, 3, 1, 6, 38, 30, 80, 60, ["dark_breath"],
			{"fire": 0.5, "blizzard": 1.5, "holy": 1.5, "dark": 0.5}))
		result.append(_make_unit("storm_imp", "Storm Imp", "enemy", Vector2i(8, 3),
			90,  50, 4, 2, 8, 25, 45, 50, 90, ["thunderstrike", "void_pulse"],
			{"thunder": 0.0, "blizzard": 1.75, "holy": 1.25, "wind": 0.5}))
		result.append(_make_unit("void_cultist", "Void Cultist", "enemy", Vector2i(6, 1),
			80,  80, 3, 1, 7, 20, 55, 40, 100, ["void_pulse", "dark_breath", "shadow_mend"],
			{"holy": 2.0, "dark": 0.0, "fire": 0.75, "blizzard": 1.25}))

	# Apply elite rolls when in a roguelike run
	var gs2: Node = get_node_or_null("/root/GameState")
	if gs2 and gs2.active_run and _elite_system:
		var floor_num: int = int(gs2.active_run.current_floor)
		var spawns_as_dicts: Array = []
		for unit in result:
			spawns_as_dicts.append({
				"name": unit.unit_data.display_name if unit.unit_data else "Enemy",
				"hp":   unit.unit_data.base_stats.hp if unit.unit_data else 100,
				"max_temper": unit.unit_data.base_stats.max_temper if unit.unit_data else 50,
				"max_ether":  unit.unit_data.base_stats.max_ether  if unit.unit_data else 50,
			})
		var heat: int = 0
		var rm: Node = get_node_or_null("/root/RunManager")
		if rm: heat = rm.get_heat_level()
		var current_node: Dictionary = gs2.active_run.get_current_node()
		if current_node.get("type", "") == "elite":
			heat += 5
		elif current_node.get("type", "") == "mystery_ambush":
			heat += 3
		var rolled := _elite_system.apply_to_floor(spawns_as_dicts, gs2.active_run.seed, floor_num, heat)
		for i in result.size():
			var rolled_spawn: Dictionary = rolled[i]
			if rolled_spawn.get("elite_tier","") != "" and result[i].unit_data:
				result[i].unit_data.display_name         = rolled_spawn["name"]
				result[i].unit_data.base_stats.hp        = rolled_spawn["hp"]
				result[i].unit_data.base_stats.max_temper = rolled_spawn["max_temper"]
				result[i].unit_data.base_stats.max_ether  = rolled_spawn["max_ether"]
				result[i].set_meta("elite_tier",  rolled_spawn["elite_tier"])
				result[i].set_meta("elite_color", rolled_spawn["elite_color"])
				result[i].set_meta("jp_mult",     rolled_spawn.get("jp_mult", 1.0))
				result[i].set_meta("prefixes",    rolled_spawn.get("prefixes", []))
				result[i].set_meta("suffixes",    rolled_spawn.get("suffixes", []))
	return result


func _make_unit(id: String, uname: String, faction: String, pos: Vector2i,
				hp: int, mp: int, move: int, jump: int, speed: int,
				physical: int, magic: int, max_temper: int, max_ether: int,
				abilities: Array = [],
				affinities: Dictionary = {},
				atk_range_min: int = 1, atk_range_max: int = 1) -> Unit:
	var stats := UnitStats.new()
	stats.hp = hp;  stats.mp = mp;  stats.move = move;  stats.jump = jump
	stats.speed = speed;  stats.physical = physical;  stats.magic = magic
	stats.max_temper = max_temper;  stats.max_ether = max_ether
	stats.attack_range_min = atk_range_min
	stats.attack_range_max = atk_range_max

	var data := UnitData.new()
	data.id = id;  data.display_name = uname;  data.faction = faction
	data.base_stats = stats
	data.abilities = _to_string_array(abilities)
	data.elemental_affinities = affinities

	if SPRITE_PATHS.has(id):
		var tex := _texture_from_source(SPRITE_PATHS[id])
		if tex:
			data.sprite_sheet = tex

	var unit: Unit = unit_scene.instantiate()
	unit.unit_data = data
	unit.grid_pos = pos
	unit.team = faction
	unit._initialize_from_data(data)
	return unit


func _texture_from_source(path: String) -> Texture2D:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var bytes := file.get_buffer(file.get_length())
	if bytes.size() >= 7 and bytes.slice(0, 7).get_string_from_ascii() == "version":
		return null
	var image := Image.new()
	var err := image.load_png_from_buffer(bytes)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)

func _to_string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result
