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


func _draw_unit() -> void:
	var is_player := team == "player"

	# ── Isometric ground shadow (ellipse at feet level = y 0) ───────────────
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

	# ── Sprite or coloured-square fallback ──────────────────────────────────
	# IMPORTANT: the unit's world origin represents the character's FEET.
	# All sprites and rects are offset upward so their bottom sits at y = 0.
	if unit_data and unit_data.sprite_sheet:
		_sprite = Sprite2D.new()
		_sprite.texture = unit_data.sprite_sheet
		var tex_size := unit_data.sprite_sheet.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var target_size: float = 62.0 if is_player else 70.0
			var sprite_scale: float = target_size / max(tex_size.x, tex_size.y)
			_sprite.scale = Vector2(sprite_scale, sprite_scale)
		# Sprite2D origin is at texture centre; shift up so bottom (feet) = y 0.
		_sprite.position = Vector2(0, -tex_size.y * _sprite.scale.y * 0.5)
		_sprite.z_index = 10
		add_child(_sprite)
	else:
		# Plain coloured pillar used when no sprite texture is assigned
		_body_rect = ColorRect.new()
		_body_rect.size = Vector2(28, 42)
		_body_rect.position = Vector2(-14, -42)   # bottom at y = 0
		_body_rect.color = Color(0.18, 0.38, 0.85) if is_player else Color(0.82, 0.18, 0.18)
		_body_rect.z_index = 10
		add_child(_body_rect)

		var stripe := ColorRect.new()
		stripe.size = Vector2(28, 5)
		stripe.position = Vector2(-14, -14)   # near the base
		stripe.color = Color(0.7, 0.9, 1.0) if is_player else Color(1.0, 0.8, 0.3)
		stripe.z_index = 11
		add_child(stripe)

	# ── Team-colour dot (top-right, above sprite head) ────────────────────
	var dot := ColorRect.new()
	dot.size = Vector2(7, 7)
	dot.position = Vector2(12, -60)
	dot.color = Color(0.3, 0.7, 1.0) if is_player else Color(1.0, 0.35, 0.35)
	dot.z_index = 14
	add_child(dot)

	# ── HP bar (floats just above the sprite head) ────────────────────────
	var hp_bg := ColorRect.new()
	hp_bg.size = Vector2(40, 4)
	hp_bg.position = Vector2(-20, -62)
	hp_bg.color = Color(0.08, 0.08, 0.08)
	hp_bg.z_index = 14
	add_child(hp_bg)

	_hp_bar = ColorRect.new()
	_hp_bar.size = Vector2(40, 4)
	_hp_bar.position = Vector2(-20, -62)
	_hp_bar.color = Color(0.2, 0.85, 0.3)
	_hp_bar.z_index = 15
	add_child(_hp_bar)

	# ── Name label (above HP bar) ─────────────────────────────────────────
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
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.06)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)


## Flash white and drift upward slightly on death.
func animate_death() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5)
	tween.tween_property(self, "position:y", position.y - 12.0, 0.5)
	tween.chain()
	tween.tween_callback(queue_free)


# ── Combat ────────────────────────────────────────────────────────────────────

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


# ── Status effects ────────────────────────────────────────────────────────────

func apply_status(status: StatusEffect) -> void:
	statuses.append(status)
	status_applied.emit(unit_id, status.status_id)


func remove_status(status_id: String) -> void:
	statuses = statuses.filter(func(s): return s.status_id != status_id)
	status_removed.emit(unit_id, status_id)


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


# ── Movement ──────────────────────────────────────────────────────────────────

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
	facing = new_facing


# ── Turn lifecycle ────────────────────────────────────────────────────────────

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
