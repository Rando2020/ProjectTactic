class_name Unit
extends Node2D

signal hp_changed(unit_id: String, new_hp: int, max_hp: int)
signal temper_changed(unit_id: String, new_temper: int, max_temper: int)
signal ether_changed(unit_id: String, new_ether: int, max_ether: int)
signal status_applied(unit_id: String, status_id: String)
signal status_removed(unit_id: String, status_id: String)
signal status_tick(unit_id: String, status_id: String, damage: int)
signal unit_defeated(unit_id: String)
signal turn_started(unit_id: String)
signal turn_ended(unit_id: String)
signal moved(unit_id: String, from: Vector2i, to: Vector2i)

@export var unit_data: UnitData

var unit_id: String
var display_name: String
var team: String = "player"
var grid_pos: Vector2i
var facing: String = "S"

var hp: int
var mp: int
var temper: int
var ether: int
var ct: int = 0

var has_acted: bool = false
var has_moved: bool = false
var is_defeated: bool = false

var statuses: Array[StatusEffect] = []
var current_job_id: String

var _hp_bar: ColorRect
var _body_rect: ColorRect
var _sprite: Sprite2D
var _facing_arrow: Polygon2D
var _facing_arrow_shadow: Polygon2D
var _selection_ring: Line2D
var _selection_glow: Polygon2D
var _status_icons_container: Node2D

## Returns the main visual element for effects (sprite if available, else body_rect)
var visual: Node:
	get:
		if _sprite and is_instance_valid(_sprite):
			return _sprite
		if _body_rect and is_instance_valid(_body_rect):
			return _body_rect
		return self


func _ready() -> void:
	if unit_data and unit_id.is_empty():
		_initialize_from_data(unit_data)


func _initialize_from_data(data: UnitData) -> void:
	unit_id = data.id
	display_name = data.display_name
	team = data.faction
	current_job_id = data.base_job_id
	hp = data.base_stats.hp
	mp = data.base_stats.mp
	temper = data.base_stats.max_temper
	ether = data.base_stats.max_ether
	ct = 0
	_draw_unit()
	_apply_unit_scale()


func _draw_unit() -> void:
	var is_player := team == "player"

	#  Isometric ground shadow (ellipse at feet level = y 0)
	# This flat oval sells the "standing on the tile" look.
	var shadow := Polygon2D.new()
	var shadow_pts: PackedVector2Array = []
	for i in range(14):
		var a := TAU * float(i) / 14.0
		shadow_pts.append(Vector2(cos(a) * 17.0, sin(a) * 5.5))
	shadow.polygon = shadow_pts
	shadow.color = Color(0.0, 0.0, 0.0, 0.30)
	shadow.position = Vector2(0.0, -3.0)   # just below feet
	shadow.z_index = 8
	add_child(shadow)

	#  Sprite or coloured-square fallback
	# IMPORTANT: the unit's world origin represents the character's FEET.
	# All sprites and rects are offset upward so their bottom sits at y = 0.
	var initial_tex := _get_texture_for_facing(facing)
	if initial_tex:
		_sprite = Sprite2D.new()
		_sprite.texture = initial_tex
		var tex_size := initial_tex.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var target_size: float = 80.0 if is_player else 95.0
			var sprite_scale: float = target_size / max(tex_size.x, tex_size.y)
			_sprite.scale = Vector2(sprite_scale, sprite_scale)
		# Sprite2D origin is at texture centre; shift up so bottom (feet) = y 0.
		_sprite.position = Vector2(0, -tex_size.y * _sprite.scale.y * 0.5)
		_sprite.z_index = 10
		add_child(_sprite)
	else:
		# Plain coloured pillar used when no sprite texture is assigned
		_body_rect = ColorRect.new()
		_body_rect.size = Vector2(36, 56)
		_body_rect.position = Vector2(-18, -56)   # bottom at y = 0
		_body_rect.color = Color(0.18, 0.38, 0.85) if is_player else Color(0.82, 0.18, 0.18)
		_body_rect.z_index = 10
		add_child(_body_rect)

		var stripe := ColorRect.new()
		stripe.size = Vector2(36, 7)
		stripe.position = Vector2(-18, -18)   # near the base
		stripe.color = Color(0.7, 0.9, 1.0) if is_player else Color(1.0, 0.8, 0.3)
		stripe.z_index = 11
		add_child(stripe)

	#  Team-colour indicator (larger, more visible)
	var dot := ColorRect.new()
	dot.size = Vector2(10, 10)
	dot.position = Vector2(14, -63)
	dot.color = Color(0.3, 0.7, 1.0) if is_player else Color(1.0, 0.35, 0.35)
	dot.z_index = 14
	add_child(dot)
	# Add bright outline for contrast
	var dot_outline := ColorRect.new()
	dot_outline.size = Vector2(12, 12)
	dot_outline.position = Vector2(13, -64)
	dot_outline.color = Color(0.0, 0.0, 0.0, 0.6)
	dot_outline.z_index = 13
	add_child(dot_outline)

	#  HP bar (floats just above the sprite head) - enlarged and more visible
	var hp_bg := ColorRect.new()
	hp_bg.size = Vector2(50, 6)
	hp_bg.position = Vector2(-25, -66)
	hp_bg.color = Color(0.04, 0.04, 0.04)
	hp_bg.z_index = 14
	add_child(hp_bg)

	# HP bar background outline for better visibility
	var hp_border := ColorRect.new()
	hp_border.size = Vector2(52, 8)
	hp_border.position = Vector2(-26, -67)
	hp_border.color = Color(0.0, 0.0, 0.0, 0.5)
	hp_border.z_index = 13
	add_child(hp_border)

	_hp_bar = ColorRect.new()
	_hp_bar.size = Vector2(50, 6)
	_hp_bar.position = Vector2(-25, -66)
	_hp_bar.color = Color(0.2, 0.85, 0.3)
	_hp_bar.z_index = 15
	add_child(_hp_bar)

	#  Name label (above HP bar)
	var lbl := Label.new()
	lbl.text = display_name.left(6)
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.position = Vector2(-20, -72)
	lbl.size = Vector2(40, 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.z_index = 15
	add_child(lbl)

	_draw_facing_arrow()
	_create_selection_outline()
	_create_status_icons_container()


func _apply_unit_scale() -> void:
	"""
	Scale units based on their max HP relative to baseline.
	Baseline is 50 HP. Units scale from 0.75x to 1.35x.
	Visually creates hierarchy: weaker units look smaller, stronger units look larger.
	"""
	if not unit_data:
		return

	var max_hp := float(unit_data.base_stats.hp)
	var baseline_hp := 50.0
	var power_ratio := max_hp / baseline_hp

	# Logarithmic scale: subtle changes for similar units, more dramatic for extremes
	# Formula: 0.75 + 0.6 * log2(power_ratio + 0.5), clamped to [0.75, 1.35]
	var scale_mult := 0.75 + 0.6 * log(power_ratio + 0.5) / log(2.0)
	scale_mult = clamp(scale_mult, 0.75, 1.35)

	# Apply scale to all children (sprite, body_rect, etc)
	scale = Vector2(scale_mult, scale_mult)


func _create_selection_outline() -> void:
	# Glow ring (behind the line for depth)
	_selection_glow = Polygon2D.new()
	var glow_poly: PackedVector2Array = []
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		var radius := 55.0
		glow_poly.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	_selection_glow.polygon = glow_poly
	_selection_glow.color = Color(0.3, 0.8, 1.0, 0.0) if team == "player" else Color(1.0, 0.4, 0.2, 0.0)
	_selection_glow.z_index = 9
	_selection_glow.visible = false
	add_child(_selection_glow)

	# Selection ring (bright outline)
	_selection_ring = Line2D.new()
	var ring_poly: PackedVector2Array = []
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		var radius := 52.0
		ring_poly.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	ring_poly.append(ring_poly[0])  # Close the loop
	_selection_ring.points = ring_poly
	_selection_ring.width = 3.5
	_selection_ring.default_color = Color(0.2, 1.0, 1.0, 0.0) if team == "player" else Color(1.0, 0.5, 0.2, 0.0)
	_selection_ring.z_index = 12
	_selection_ring.visible = false
	add_child(_selection_ring)


func _create_status_icons_container() -> void:
	_status_icons_container = Node2D.new()
	_status_icons_container.z_index = 20
	add_child(_status_icons_container)


func _update_hp_bar() -> void:
	if not _hp_bar or not unit_data:
		return
	var ratio := float(hp) / float(unit_data.base_stats.hp)
	_hp_bar.size.x = 40.0 * ratio
	if ratio < 0.3:
		_hp_bar.color = Color(0.85, 0.2, 0.2)
	elif ratio < 0.6:
		_hp_bar.color = Color(0.9, 0.75, 0.1)
	else:
		_hp_bar.color = Color(0.2, 0.85, 0.3)


## Flash red on hit, restore normal colour.
func animate_hit() -> void:
	var start_pos := position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(1.0, 0.34, 0.30, 1.0), 0.06)
	tween.tween_property(self, "position", start_pos + Vector2(5.0, -3.0), 0.05)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(self, "position", start_pos + Vector2(-3.0, 2.0), 0.06)
	tween.tween_property(self, "modulate", Color(1.0, 0.78, 0.68, 1.0), 0.08)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(self, "position", start_pos, 0.12)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.16)


## Flash white and drift upward slightly on death.
func animate_death() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.65).set_delay(0.18)
	tween.tween_property(self, "position:y", position.y - 14.0, 0.65).set_delay(0.18)
	tween.chain()
	tween.tween_callback(queue_free)


#  Combat

func receive_damage(amount: int, damage_type: String) -> Dictionary:
	var result := {"hp_damage": 0, "temper_damage": 0, "ether_damage": 0, "defeated": false}
	match damage_type:
		"physical":
			var effective: int = int(amount * 0.7) if has_status("protect") else amount
			var absorbed: int = min(temper, int(effective * 0.35))
			temper = max(temper - absorbed, 0)
			var hp_dmg: int = max(1, effective - int(absorbed * 0.25))
			hp = max(hp - hp_dmg, 0)
			result["hp_damage"] = hp_dmg
			result["temper_damage"] = absorbed
		"magical":
			var absorbed: int = min(ether, int(amount * 0.35))
			ether = max(ether - absorbed, 0)
			var hp_dmg: int = max(1, amount - int(absorbed * 0.25))
			hp = max(hp - hp_dmg, 0)
			result["hp_damage"] = hp_dmg
			result["ether_damage"] = absorbed
		_:
			hp = max(hp - amount, 0)
			result["hp_damage"] = amount
	hp_changed.emit(unit_id, hp, unit_data.base_stats.hp)
	temper_changed.emit(unit_id, temper, unit_data.base_stats.max_temper)
	_update_hp_bar()
	if hp <= 0 and not is_defeated:
		is_defeated = true
		result["defeated"] = true
		unit_defeated.emit(unit_id)
		animate_death()
	return result


func heal(amount: int) -> void:
	hp = min(hp + amount, unit_data.base_stats.hp)
	hp_changed.emit(unit_id, hp, unit_data.base_stats.hp)
	_update_hp_bar()


func restore_temper(amount: int) -> void:
	temper = min(temper + amount, unit_data.base_stats.max_temper)
	temper_changed.emit(unit_id, temper, unit_data.base_stats.max_temper)


func restore_ether(amount: int) -> void:
	ether = min(ether + amount, unit_data.base_stats.max_ether)
	ether_changed.emit(unit_id, ether, unit_data.base_stats.max_ether)


#  Status effects

func apply_status(status: StatusEffect) -> void:
	statuses.append(status)
	status_applied.emit(unit_id, status.status_id)
	_update_status_icons()


func remove_status(status_id: String) -> void:
	statuses = statuses.filter(func(s): return s.status_id != status_id)
	status_removed.emit(unit_id, status_id)
	_update_status_icons()


func has_status(status_id: String) -> bool:
	return statuses.any(func(s): return s.status_id == status_id)


func tick_statuses() -> void:
	var to_remove: Array[String] = []
	for s in statuses:
		# Damage-over-time (poison, burn)
		if s.magnitude > 0.0 and hp > 0:
			var dmg: int = max(1, int(unit_data.base_stats.hp * s.magnitude))
			hp = max(hp - dmg, 0)
			hp_changed.emit(unit_id, hp, unit_data.base_stats.hp)
			_update_hp_bar()
			status_tick.emit(unit_id, s.status_id, dmg)
			if hp <= 0 and not is_defeated:
				is_defeated = true
				unit_defeated.emit(unit_id)
				animate_death()
		s.duration -= 1
		if s.duration <= 0:
			to_remove.append(s.status_id)
	for sid in to_remove:
		remove_status(sid)


#  Movement

func move_to(new_pos: Vector2i) -> void:
	var old_pos := grid_pos
	grid_pos = new_pos
	var delta := new_pos - old_pos
	if delta != Vector2i.ZERO:
		if abs(delta.x) >= abs(delta.y):
			set_facing("E" if delta.x > 0 else "W")
		else:
			set_facing("S" if delta.y > 0 else "N")
	moved.emit(unit_id, old_pos, new_pos)
	has_moved = true


func set_facing(new_facing: String) -> void:
	if new_facing not in ["N", "E", "S", "W"]:
		return
	facing = new_facing
	_update_directional_sprite()
	_update_facing_arrow()


func _get_texture_for_facing(dir: String) -> Texture2D:
	if not unit_data:
		return null
	match dir:
		"N": return unit_data.sprite_back_right if unit_data.sprite_back_right else unit_data.sprite_sheet
		"E": return unit_data.sprite_front_right if unit_data.sprite_front_right else unit_data.sprite_sheet
		"W": return unit_data.sprite_back_left if unit_data.sprite_back_left else unit_data.sprite_sheet
		_:   return unit_data.sprite_front_left if unit_data.sprite_front_left else unit_data.sprite_sheet


func _update_directional_sprite() -> void:
	if not _sprite or not unit_data:
		return
	var tex := _get_texture_for_facing(facing)
	if not tex or tex == _sprite.texture:
		return
	_sprite.texture = tex
	var tex_size := tex.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var target_size: float = 80.0 if team == "player" else 95.0
		var sprite_scale: float = target_size / max(tex_size.x, tex_size.y)
		_sprite.scale = Vector2(sprite_scale, sprite_scale)
		_sprite.position = Vector2(0, -tex_size.y * _sprite.scale.y * 0.5)


func _draw_facing_arrow() -> void:
	# Glow ring behind arrow (larger, transparent)
	var glow_points := PackedVector2Array([
		Vector2(0.0, -14.0),
		Vector2(12.0, 10.0),
		Vector2(0.0, 5.0),
		Vector2(-12.0, 10.0),
	])
	var glow := Polygon2D.new()
	glow.polygon = glow_points
	glow.color = Color(0.42, 0.82, 1.0, 0.25) if team == "player" else Color(1.0, 0.42, 0.30, 0.25)
	glow.z_index = 15
	add_child(glow)

	# Shadow
	var shadow_points := PackedVector2Array([
		Vector2(0.0, -12.0),
		Vector2(10.0, 10.0),
		Vector2(0.0, 5.0),
		Vector2(-10.0, 10.0),
	])
	_facing_arrow_shadow = Polygon2D.new()
	_facing_arrow_shadow.polygon = shadow_points
	_facing_arrow_shadow.color = Color(0.0, 0.0, 0.0, 0.70)
	_facing_arrow_shadow.z_index = 16
	add_child(_facing_arrow_shadow)

	# Main arrow (larger and more visible)
	_facing_arrow = Polygon2D.new()
	_facing_arrow.polygon = PackedVector2Array([
		Vector2(0.0, -10.0),
		Vector2(8.0, 8.0),
		Vector2(0.0, 3.0),
		Vector2(-8.0, 8.0),
	])
	_facing_arrow.color = Color(0.42, 0.82, 1.0, 1.0) if team == "player" else Color(1.0, 0.42, 0.30, 1.0)
	_facing_arrow.z_index = 17
	add_child(_facing_arrow)
	_update_facing_arrow()


func _update_facing_arrow() -> void:
	if not _facing_arrow or not _facing_arrow_shadow:
		return
	var dir := _facing_screen_direction(facing)
	var marker_pos := dir * 22.0 + Vector2(0.0, -8.0)
	var marker_rotation := dir.angle() + PI * 0.5
	_facing_arrow.position = marker_pos
	_facing_arrow.rotation = marker_rotation
	_facing_arrow_shadow.position = marker_pos + Vector2(1.0, 2.0)
	_facing_arrow_shadow.rotation = marker_rotation


func _facing_screen_direction(value: String) -> Vector2:
	match value:
		"N":
			return Vector2(0.9, -0.45).normalized()
		"E":
			return Vector2(0.9, 0.45).normalized()
		"W":
			return Vector2(-0.9, -0.45).normalized()
		_:
			return Vector2(-0.9, 0.45).normalized()

## Highlight this unit as the active/selected unit
func set_active(is_active: bool) -> void:
	if is_active:
		# Slight unit brightening
		modulate = Color(1.15, 1.15, 1.15, 1.0)
		# Show and animate selection ring
		if _selection_ring and _selection_glow:
			_selection_ring.visible = true
			_selection_glow.visible = true
			var player_color := Color(0.2, 1.0, 1.0, 1.0)
			var enemy_color := Color(1.0, 0.5, 0.2, 1.0)
			var ring_color := player_color if team == "player" else enemy_color
			var glow_color := Color(ring_color.r, ring_color.g, ring_color.b, 0.45)
			_selection_glow.color = glow_color

			var tween := create_tween()
			tween.set_loops()
			tween.tween_property(_selection_ring, "default_color", ring_color, 0.6)
			tween.tween_property(_selection_ring, "default_color", Color(ring_color.r, ring_color.g, ring_color.b, 0.4), 0.6)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		# Hide selection ring
		if _selection_ring and _selection_glow:
			_selection_ring.visible = false
			_selection_glow.visible = false
			# Kill any active tweens on the ring
			_selection_ring.modulate = Color.WHITE


#  Turn lifecycle

func begin_turn() -> void:
	has_acted = false
	has_moved = false
	if _body_rect:
		_body_rect.color = Color(0.35, 0.65, 1.0) if team == "player" else Color(1.0, 0.38, 0.38)
	turn_started.emit(unit_id)


func end_turn() -> void:
	tick_statuses()
	if _body_rect:
		_body_rect.color = Color(0.18, 0.38, 0.85) if team == "player" else Color(0.82, 0.18, 0.18)
	turn_ended.emit(unit_id)


func get_effective_speed() -> int:
	var base_speed: int = unit_data.base_stats.speed if unit_data else 6
	if has_status("haste"): return int(base_speed * 1.5)
	if has_status("slow"): return int(base_speed * 0.5)
	return base_speed


func can_act() -> bool:
	return not has_acted and hp > 0 and not has_status("stun") and not has_status("petrify")


func can_move() -> bool:
	return not has_moved and hp > 0 and not has_status("immobilize") and not has_status("petrify")


func _update_status_icons() -> void:
	if not _status_icons_container:
		return
	# Clear old icons
	for child in _status_icons_container.get_children():
		child.queue_free()

	# Status effect icons and colors
	var status_displays := {
		"haste": {"icon": "H", "color": Color(0.9, 0.8, 0.2, 1.0)},
		"slow": {"icon": "S", "color": Color(0.3, 0.8, 1.0, 1.0)},
		"protect": {"icon": "P", "color": Color(0.4, 0.9, 0.7, 1.0)},
		"stun": {"icon": "!", "color": Color(1.0, 0.9, 0.1, 1.0)},
		"petrify": {"icon": "R", "color": Color(0.7, 0.7, 0.7, 1.0)},
		"immobilize": {"icon": "I", "color": Color(0.8, 0.5, 0.8, 1.0)},
		"blessed": {"icon": "+", "color": Color(1.0, 0.85, 0.3, 1.0)},
		"cursed": {"icon": "X", "color": Color(0.6, 0.2, 0.6, 1.0)},
	}

	var icon_idx := 0
	for status in statuses:
		var display: Dictionary = status_displays.get(status.status_id, {
			"icon": "*",
			"color": Color(0.8, 0.8, 0.8, 1.0)
		}) as Dictionary
		var icon := Label.new()
		icon.text = str(display["icon"])
		icon.add_theme_font_size_override("font_size", 14)
		icon.add_theme_color_override("font_color", display["color"] as Color)
		icon.position = Vector2(icon_idx * 16 - 16, -82)  # Row of icons above HP bar
		icon.z_index = 20
		_status_icons_container.add_child(icon)
		icon_idx += 1
