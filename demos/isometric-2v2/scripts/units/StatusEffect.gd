class_name StatusEffect
extends Resource

@export var status_id: String = ""
@export var display_name: String = ""
@export var duration: int = 1
## For DoT statuses (poison, burn): fraction of target's MAX HP dealt per tick.
## e.g. 0.07 = 7 % max HP per turn.  0.0 means no tick damage.
@export var magnitude: float = 0.0
## Damage type used for tick damage VFX colouring ("fire", "dark", "pure").
@export var damage_type: String = "pure"
