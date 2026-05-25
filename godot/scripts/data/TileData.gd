## TileData.gd
## Resource class defining the properties of a single terrain tile.
## These values are used by GridSystem and combat logic to determine
## movement costs, height penalties, defense bonuses, and elemental
## interactions. See docs/DATA_SCHEMAS.md for field descriptions.

class_name ProjectTileData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var move_cost: int = 1
@export var height_cost: int = 1
@export var defense_bonus: int = 0
@export var ether_defense_bonus: int = 0
@export var blocks_movement: bool = false
@export var blocks_line_of_sight: bool = false
@export var tags: Array[String] = []
var elemental_reactions: Dictionary = {}
@export var surge_profile: String = ""
