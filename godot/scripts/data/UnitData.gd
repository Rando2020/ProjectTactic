class_name UnitData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var faction: String = "player"  # "player", "enemy"
@export var base_job_id: String = ""
@export var level: int = 1
@export var base_stats: UnitStats
@export var abilities: Array[String] = []
@export var portrait: Texture2D
@export var sprite_sheet: Texture2D

# Directional sprites for isometric view.
# S direction = front-left, E = front-right, W = back-left, N = back-right.
# When set, Unit will swap textures automatically as facing changes.
@export var sprite_front_left: Texture2D   # used when facing S
@export var sprite_front_right: Texture2D  # used when facing E
@export var sprite_back_left: Texture2D    # used when facing W
@export var sprite_back_right: Texture2D   # used when facing N

## Elemental affinity multipliers applied to incoming spell damage.
## Keys: "fire" "blizzard" "thunder" "wind" "holy" "dark"
## Values: 2.0=very weak  1.5=weak  1.0=neutral  0.5=resist  0.0=immune
## Not @exported  bare Dictionary @export is a parse error in Godot 4.6.
var elemental_affinities: Dictionary = {}
