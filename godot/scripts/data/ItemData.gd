## ItemData.gd
## Resource class defining consumable and equipment items. Items are
## referenced by their `id` in mission rewards, shops, and inventory
## management. See docs/DATA_SCHEMAS.md for field descriptions.

class_name ItemData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var item_type: String = "consumable"  # "consumable", "equipment", "key"
@export var effect_type: String = ""	# "heal_hp", "restore_temper", "restore_ether", "revive"
@export var effect_value: int = 0
@export var target: String = "self"   # "self", "ally", "any"
@export var stackable: bool = true
@export var icon: Texture2D
