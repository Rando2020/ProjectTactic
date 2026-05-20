class_name BattleScene
extends Node2D

@onready var battle_manager: BattleManager = $BattleManager
@onready var tactical_grid: TacticalGrid = $BattleManager/TacticalGrid
@onready var battle_ui: BattleUI = $BattleUI

var unit_scene: PackedScene = preload("res://scenes/Unit.tscn")
var _battle_camera: Camera2D
var _camera_base_position: Vector2 = Vector2(320.0, 245.0)
var _camera_zoom_value: float = 0.92

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

const DEFAULT_BATTLE_MUSIC: AudioStream = preload("res://assets/music/steel-march-echo-battle.wav")

var _battle_music_player: AudioStreamPlayer


func _ready() -> void:
	_setup_camera()
	_start_battle_music()

	var gs: Node = get_node_or_null("/root/GameState")

	# Use procedurally generated map when inside a roguelike run
	if gs and gs.active_run and not gs.active_run.completed:
		var mg := MapGenerator.new()
		var run: RunState = gs.active_run
		_map_data = mg.generate_floor(run.current_floor, run.seed)
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

	var all_units: Array[Unit] = []
	all_units.append_array(player_units)
	all_units.append_array(enemy_units)

	battle_ui.setup(battle_manager)
	battle_manager.start_battle(_map_data, all_units)

	battle_manager.battle_won.connect(_on_battle_won)
	battle_manager.battle_lost.connect(_on_battle_lost)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.unit_defeated.connect(_on_unit_defeated)


func _start_battle_music() -> void:
	_battle_music_player = AudioStreamPlayer.new()
	_battle_music_player.stream = DEFAULT_BATTLE_MUSIC
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
		_battle_music_player.stop()


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
	var play_area := Vector2(620.0, 700.0)
	var zoom_x: float = play_area.x / max(bounds.size.x, 1.0)
	var zoom_y: float = play_area.y / max(bounds.size.y, 1.0)
	_camera_zoom_value = clamp(min(zoom_x, zoom_y), 0.72, 1.15)
	_camera_base_position = bounds.get_center()
	_camera_base_position.x += 26.0
	_battle_camera.position = _camera_base_position
	_battle_camera.zoom = Vector2(_camera_zoom_value, _camera_zoom_value)


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


func _on_unit_defeated(unit_id: String) -> void:
	var u: Unit = battle_manager.units.get(unit_id)
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
		# Award stage rewards (Soul Shards, Aether, Obsidian)
		var rm: Node = get_node_or_null("/root/RunManager")
		if rm and rm.is_run_active:
			var floor_num := gs.active_run.current_floor if gs.active_run else 1
			var is_boss   := floor_num >= 10
			var has_elite := _defeated_enemies.any(func(e: Dictionary) -> bool: return e.get("elite_tier","") != "")
			rm.award_stage_reward(floor_num, has_elite, is_boss)
			if is_boss:
				rm.end_run(true)
				await get_tree().create_timer(1.8).timeout
				get_tree().change_scene_to_file("res://scenes/HubScene.tscn")
				return

		if gs.active_run:
			# Generate loot, advance run, route to StageSelect
			var ls    := LootSystem.new()
			var loot  := ls.generate_battle_loot(_defeated_enemies, gs.active_run.seed, gs.active_run.current_floor)
			gs.pending_loot = loot
			var elite_n := _defeated_enemies.filter(func(e: Dictionary) -> bool: return e.get("elite_tier","") != "").size()
			gs.active_run.elite_kills += elite_n
			gs.active_run.complete_current_node()
			# If next node is boon_pick, generate offers
			var next_nd := gs.active_run.get_current_node()
			if next_nd.get("type","") == "boon_pick":
				var bs := BoonSystem.new()
				var owned := gs.active_run.active_boons.map(func(b: Dictionary) -> String: return b.get("id",""))
				gs.pending_boon_offers = bs.generate_offers(gs.active_run.seed * 17 + gs.active_run.current_floor * 3, gs.active_run.current_floor, owned)
			await get_tree().create_timer(1.5).timeout
			get_tree().change_scene_to_file("res://scenes/StageSelect.tscn")
			return
	await get_tree().create_timer(2.2).timeout
	get_tree().change_scene_to_file("res://scenes/ResultsScreen.tscn")
func _on_battle_lost() -> void:
	_fade_battle_music()
	await get_tree().create_timer(2.0).timeout
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
	return result


func _spawn_enemy_units() -> Array[Unit]:
	var result: Array[Unit] = []
	result.append(_make_unit("null_drake", "Null Drake", "enemy", Vector2i(7, 2),
		120, 35, 3, 1, 6, 38, 30, 80, 60, ["dark_breath"],
		{"fire": 0.5, "blizzard": 1.5, "holy": 1.5, "dark": 0.5}))
	result.append(_make_unit("storm_imp", "Storm Imp", "enemy", Vector2i(8, 3),
		90,  50, 4, 2, 8, 25, 45, 50, 90, ["thunderstrike", "void_pulse"],
		{"thunder": 0.0, "blizzard": 1.75, "holy": 1.25, "wind": 0.5}))
	result.append(_make_unit("void_cultist", "Void Cultist", "enemy", Vector2i(6, 1),
		80,  80, 3, 1, 7, 20, 55, 40, 100, ["void_pulse", "dark_breath"],
		{"holy": 2.0, "dark": 0.0, "fire": 0.75, "blizzard": 1.25}))
	# Apply elite rolls when in a roguelike run
	var gs2: Node = get_node_or_null("/root/GameState")
	if gs2 and gs2.active_run and _elite_system:
		var floor := gs2.active_run.current_floor
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
		var rolled := _elite_system.apply_to_floor(spawns_as_dicts, gs2.active_run.seed, floor, heat)
		for i in result.size():
			var r: Dictionary = rolled[i]
			if r.get("elite_tier","") != "" and result[i].unit_data:
				result[i].unit_data.display_name         = r["name"]
				result[i].unit_data.base_stats.hp        = r["hp"]
				result[i].unit_data.base_stats.max_temper = r["max_temper"]
				result[i].unit_data.base_stats.max_ether  = r["max_ether"]
				result[i].set_meta("elite_tier",  r["elite_tier"])
				result[i].set_meta("elite_color", r["elite_color"])
				result[i].set_meta("jp_mult",     r.get("jp_mult", 1.0))
				result[i].set_meta("prefixes",    r.get("prefixes", []))
				result[i].set_meta("suffixes",    r.get("suffixes", []))
	return result


func _make_unit(id: String, uname: String, faction: String, pos: Vector2i,
				hp: int, mp: int, move: int, jump: int, speed: int,
				physical: int, magic: int, max_temper: int, max_ether: int,
				abilities: Array[String] = [],
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
	data.abilities = abilities
	data.elemental_affinities = affinities

	if SPRITE_PATHS.has(id):
		var tex = load(SPRITE_PATHS[id])
		if tex is Texture2D:
			data.sprite_sheet = tex

	var unit: Unit = unit_scene.instantiate()
	unit.unit_data = data
	unit.grid_pos = pos
	unit.team = faction
	return unit
