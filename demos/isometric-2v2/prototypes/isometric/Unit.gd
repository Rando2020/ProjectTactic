extends Unit
## Proof-only artwork adapter. Combat, movement and facing remain production code.
var view_quarter := 0
var _compact_textures: Dictionary = {}
var _cast_rest: Transform2D
var _cast_motion: Tween
var _cast_active := false
var _cast_weight := 0.0
var _cast_side := 1.0

func face_action(destination: Vector2i) -> void:
	super.face_action(destination)
	var direction := facing if destination == grid_pos else CombatFormula.attack_direction(destination, grid_pos)
	_cast_side = signf(_facing_screen_direction(direction).x)

func set_cast_pose(pose: String) -> bool:
	if is_instance_valid(_rig3d): return super.set_cast_pose(pose)
	if unit_data == null or unit_data.id not in ["zane", "kael"] or not is_instance_valid(_sprite): return false
	if pose not in ["anticipation", "release"]: return false
	if bool(GameState.practice_session.get("reduced_zane_motion", false)):
		_reset_cast_motion()
		return true
	if not _cast_active:
		_cast_rest = _sprite.transform
		_cast_active = true
		_cast_weight = 0.0
	_tween_cast_weight(-1.0 if pose == "anticipation" else 1.0, 0.18 if pose == "anticipation" else 0.12)
	return true

func _tween_cast_weight(target: float, seconds: float) -> void:
	if _cast_motion != null and _cast_motion.is_valid(): _cast_motion.kill()
	_cast_motion = create_tween()
	_cast_motion.tween_method(_apply_cast_weight, _cast_weight, target, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_cast_weight(weight: float) -> void:
	if not _cast_active or not is_instance_valid(_sprite): return
	_cast_weight = weight
	# Transform the unchanged painted sprite around the actor's ground origin.
	# This is restrained procedural motion, not newly painted limb/pose frames.
	var brace := unit_data.id == "kael"
	var height := 1.0 + weight * (0.012 if brace else 0.025)
	var lean := weight * _cast_side * (0.025 if brace else 0.045)
	_sprite.transform = Transform2D(0.0, Vector2(1.0, height), lean, Vector2.ZERO) * _cast_rest

func _reset_cast_motion() -> void:
	if _cast_motion != null and _cast_motion.is_valid(): _cast_motion.kill()
	_cast_motion = null
	if _cast_active and is_instance_valid(_sprite): _sprite.transform = _cast_rest
	_cast_active = false
	_cast_weight = 0.0

func recover_melee_pose() -> void:
	if _cast_active: _tween_cast_weight(0.0, 0.18)
	else: super.recover_melee_pose()

func reset_melee_pose() -> void:
	_reset_cast_motion()
	super.reset_melee_pose()

func uses_compact_skin() -> bool:
	return bool(GameState.practice_session.get("compact_skins", true)) and unit_data != null and unit_data.id in ["zane", "kael"]

func set_melee_pose(pose: String) -> bool:
	_reset_cast_motion()
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
