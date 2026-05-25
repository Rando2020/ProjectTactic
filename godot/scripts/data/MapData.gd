## MapData.gd
class_name MapData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var region: String = ""
@export var objective_type: String = "defeat_all"
@export var objective_label: String = "Defeat all enemies"
@export var map_width: int = 10
@export var map_height: int = 8
@export var default_terrain: String = "grass"
@export var max_party_size: int = 4
@export var required_unit_ids: Array[String] = []
@export var recommended_unit_ids: Array[String] = []
@export var tile_overrides: Array[Dictionary] = []  # [{x, y, terrain, height}]
@export var prop_overrides: Array[Dictionary] = []  # [{x, y, prop, offset_x, offset_y}]
@export var player_spawns: Array[Dictionary] = []   # [{unit_id, x, y, facing}]
@export var enemy_spawns: Array[Dictionary] = []    # [{unit_id, x, y, facing}]
@export var deployment_zones: Array[Dictionary] = []
@export var deployment_briefing: String = ""
@export var reward_gold: int = 100
@export var reward_jp: int = 30
@export var reward_items: Array[String] = []
@export var reward_flags: Array[String] = []

# Path to the .tscn scene used for visually rendering the tilemap. This
# allows level designers to author maps in a 2D editor and connect them
# to gameplay data via this resource. The path should be relative to
# the project root (e.g. "res://scenes/maps/ashvale_road_01.tscn").
@export var tilemap_scene: String = ""
