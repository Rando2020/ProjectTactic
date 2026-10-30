class_name UnitStats
extends Resource

@export var hp: int = 300
@export var mp: int = 60
@export var move: int = 4
@export var jump: int = 2
@export var speed: int = 7
@export var physical: int = 40
@export var magic: int = 40
@export var physical_resistance: int = 0
@export var magic_resistance: int = 0
@export var max_temper: int = 80
@export var max_ether: int = 80
## Minimum tiles away for a basic Attack (1 = melee, 2 = bow can't hit adjacent)
@export var attack_range_min: int = 1
## Maximum tiles away for a basic Attack (1 = melee, 3-5 = ranged)
@export var attack_range_max: int = 1
