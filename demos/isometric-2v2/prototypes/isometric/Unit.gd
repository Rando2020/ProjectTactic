extends Unit
## Proof-only artwork adapter. Combat, movement and facing remain production code.
var view_quarter := 0
var _compact_textures: Dictionary = {}

func uses_compact_skin() -> bool:
	return bool(GameState.practice_session.get("compact_skins", true)) and unit_data != null and unit_data.id in ["zane", "kael"]

func set_melee_pose(pose: String) -> bool:
	# Compact sheets contain idle directions only. Keep the same class identity
	# during attacks and let VFXManager use its procedural anticipation fallback.
	if uses_compact_skin():
		if pose == "idle":
			reset_melee_pose()
			return true
		return false
	return super.set_melee_pose(pose)

func _compact_texture(direction: String) -> Texture2D:
	var role := "mage" if unit_data.id == "zane" else "swordsman"
	var path := "res://prototypes/isometric/assets/character-sets/compact/frames/%s/%s.png" % [role, _view_facing(direction)]
	if not _compact_textures.has(path): _compact_textures[path] = load(path)
	return _compact_textures[path]


func set_view_quarter(value: int) -> void:
	view_quarter = posmod(value,4)
	_refresh_directional_sprite()
	_update_facing_arrow()

func _view_facing(value: String) -> String:
	var dirs := ["N","E","S","W"]
	return dirs[posmod(dirs.find(value)+view_quarter,4)]

func _facing_screen_direction(value: String) -> Vector2:
	return super._facing_screen_direction(_view_facing(value))

const FRONT := preload("res://prototypes/isometric/assets/zane-front.png")
const BACK := preload("res://prototypes/isometric/assets/zane-back.png")

func _character_direction_texture(direction: String) -> Texture2D:
	if uses_compact_skin(): return _compact_texture(direction)
	if unit_data != null and unit_data.id == "zane":
		return BACK if _view_facing(direction) in ["N", "W"] else FRONT
	return super._character_direction_texture(direction)

func _draw_unit() -> void:
	super._draw_unit()
	# Replaced by readable, non-interactive screen-space labels in the demo HUD.
	for child in get_children():
		if child is Label and child.text == display_name.left(6): child.hide()
	_fit_illustrated_actor()

func _refresh_directional_sprite() -> void:
	if is_instance_valid(_sprite) and uses_compact_skin():
		_sprite.texture = _compact_texture(facing)
	else:
		super._refresh_directional_sprite()
		if is_instance_valid(_sprite) and unit_data != null and unit_data.id == "kael":
			_sprite.texture = unit_data.sprite_sheet
			var dimensions := _sprite.texture.get_size()
			_sprite.scale = Vector2.ONE * (80.0 / maxf(dimensions.x, dimensions.y))
			_sprite.position = Vector2(0, -dimensions.y * _sprite.scale.y * 0.5)
			_sprite.offset = Vector2.ZERO
			_sprite.flip_h = false
	_fit_illustrated_actor()

func _fit_illustrated_actor() -> void:
	if uses_compact_skin() and is_instance_valid(_sprite):
		# Frames are normalized by the deterministic extraction script.
		_sprite.scale = Vector2.ONE * (86.0 / 600.0)
		_sprite.position = Vector2.ZERO
		_sprite.offset = _sprite.texture.get_size() * 0.5 - Vector2(400, 740)
		_sprite.flip_h = false
		return
	if unit_id != "zane" or not is_instance_valid(_sprite):
		return
	# Original images retain transparent margins. Anchor to visible boot soles,
	# not the image bounds; 86 world pixels keeps a small battlefield silhouette.
	var rear := _view_facing(facing) in ["N", "W"]
	var anchor := Vector2(630, 1160) if rear else Vector2(650, 1150)
	_sprite.scale = Vector2.ONE * (86.0 / 1080.0)
	_sprite.position = Vector2.ZERO
	_sprite.offset = _sprite.texture.get_size() * 0.5 - anchor
	# Two authored poses, mirrored for interim west/south orientation.
	_sprite.flip_h = _view_facing(facing) in ["W", "S"]
	if _sprite.flip_h:
		_sprite.offset.x = -_sprite.offset.x
