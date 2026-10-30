extends Unit
## Proof-only artwork adapter. Combat, movement and facing remain production code.
const FRONT := preload("res://prototypes/isometric/assets/zane-front.png")
const BACK := preload("res://prototypes/isometric/assets/zane-back.png")

func _character_direction_texture(direction: String) -> Texture2D:
	if unit_data != null and unit_data.id == "zane":
		return BACK if direction in ["N", "W"] else FRONT
	return super._character_direction_texture(direction)

func _draw_unit() -> void:
	super._draw_unit()
	_fit_illustrated_actor()

func _refresh_directional_sprite() -> void:
	super._refresh_directional_sprite()
	_fit_illustrated_actor()

func _fit_illustrated_actor() -> void:
	if unit_id != "zane" or not is_instance_valid(_sprite):
		return
	# Original images retain transparent margins. Anchor to visible boot soles,
	# not the image bounds; 86 world pixels keeps a small battlefield silhouette.
	var rear := facing in ["N", "W"]
	var anchor := Vector2(630, 1160) if rear else Vector2(650, 1150)
	_sprite.scale = Vector2.ONE * (86.0 / 1080.0)
	_sprite.position = Vector2.ZERO
	_sprite.offset = _sprite.texture.get_size() * 0.5 - anchor
	# Two authored poses, mirrored for interim west/south orientation.
	_sprite.flip_h = facing in ["W", "S"]
	if _sprite.flip_h:
		_sprite.offset.x = -_sprite.offset.x
