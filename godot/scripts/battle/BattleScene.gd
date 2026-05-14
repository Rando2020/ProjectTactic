class_name BattleScene
extends Node2D

@onready var battle_manager: BattleManager = $BattleManager
@onready var tactical_grid: TacticalGrid = $BattleManager/TacticalGrid
@onready var battle_ui: BattleUI = $BattleUI

var unit_scene: PackedScene = preload("res://scenes/Unit.tscn")

## Set via GameState.selected_map_index before loading this scene.
## Kept as @export so you can still override in the editor during dev.
@export var map_index: int = 0

var _map_data: MapData

const SPRITE_PATHS := {
	"zane":         "res://assets/sprites/units/zane.svg",
	"mira":         "res://assets/sprites/units/mira.svg",
	"kael":         "res://assets/sprites/units/kael.svg",
	"lyra":         "res://assets/sprites/units/lyra.svg",
	"null_drake":   "res://assets/sprites/units/null_drake.svg",
	"storm_imp":    "res://assets/sprites/units/storm_imp.svg",
	"void_cultist": "res://assets/sprites/units/void_cultist.svg",
}


func _ready() -> void:
	# Prefer GameState's selection; @export override still works in editor
	if Engine.has_singleton("GameState") or is_instance_valid(get_node_or_null("/root/GameState")):
		map_index = (get_node("/root/GameState") as GameState).selected_map_index

	_map_data = _create_ashvale_map() if map_index == 0 else _create_crypt_map()
	tactical_grid.initialize_from_map(_map_data)

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


func _on_battle_won(rewards: Dictionary) -> void:
	# Collect surviving player unit IDs for JP award
	var player_ids: Array[String] = []
	for uid in battle_manager.units:
		var u: Unit = battle_manager.units[uid]
		if u.team == "player":
			player_ids.append(uid)
	var gs: GameState = get_node_or_null("/root/GameState")
	if gs:
		gs.apply_victory(_map_data.id, rewards, player_ids)
	await get_tree().create_timer(2.2).timeout
	get_tree().change_scene_to_file("res://scenes/ResultsScreen.tscn")


func _on_battle_lost() -> void:
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
		{"x": 7, "y": 0, "terrain": "stone", "height": 2},
		{"x": 8, "y": 0, "terrain": "stone", "height": 2},
		{"x": 7, "y": 1, "terrain": "stone", "height": 1},
		{"x": 8, "y": 1, "terrain": "stone", "height": 1},
		{"x": 9, "y": 5, "terrain": "shrine", "height": 0},
		{"x": 2, "y": 7, "terrain": "road", "height": 0},
		{"x": 3, "y": 7, "terrain": "road", "height": 0},
		{"x": 4, "y": 7, "terrain": "road", "height": 0},
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
	var gs: GameState = get_node_or_null("/root/GameState")
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
