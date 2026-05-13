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
