## VFXManager.gd
## Autoload singleton.  All battle visual effects spawn here.
## Call from anywhere: VFXManager.play_attack(attacker_grid, target_grid)
##
## Coordinate system: grid positions are converted to screen pixels using
## the same isometric projection as TacticalGrid.

class_name VFXManager
extends Node2D

const TILE_SIZE := Vector2(96.0, 48.0)
const HEIGHT_STEP := 14.0
const MAP_ORIGIN := Vector2(320.0, 64.0)

func _ready() -> void:
	z_index = 3000
	z_as_relative = false


#  Coordinate helper

func gp(grid_pos: Vector2i) -> Vector2:
	var height := _height_for(grid_pos)
	return MAP_ORIGIN + Vector2(
		(grid_pos.x - grid_pos.y) * TILE_SIZE.x * 0.5,
		(grid_pos.x + grid_pos.y) * TILE_SIZE.y * 0.5 - float(height) * HEIGHT_STEP
	)


func _height_for(grid_pos: Vector2i) -> int:
	var grid := get_node_or_null("/root/BattleScene/BattleManager/TacticalGrid")
	if grid and grid.has_method("get_tile"):
		return int(grid.get_tile(grid_pos).get("height", 0))
	return 0


#  Physical attack

func play_attack(from_grid: Vector2i, to_grid: Vector2i, damage: int,
		dmg_color: Color = Color(1.0, 0.95, 0.4)) -> void:
	var fw := gp(from_grid)
	var tw := gp(to_grid)
	play_target_ping(to_grid, Color(1.0, 0.76, 0.20, 0.9))
	_play_slash(fw, tw)
	# Slight delay so slash arrives before impact
	await get_tree().create_timer(0.12).timeout
	_play_impact_sparks(tw)
	play_damage_number(to_grid, damage, dmg_color)


func _play_slash(from_w: Vector2, to_w: Vector2) -> void:
	var dir  := (to_w - from_w).normalized()
	var perp := Vector2(-dir.y, dir.x)
	# Three overlapping arcs for a sword-slash look
	for i in range(3):
		var offset := perp * (float(i - 1) * 8.0)
		var line   := Line2D.new()
		line.width = 4.0 - float(i)
		line.default_color = Color(1.0, 1.0, 0.85, 1.0)
		line.joint_mode    = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode   = Line2D.LINE_CAP_ROUND
		# Build arc with 6 points
		for t in range(7):
			var pct := float(t) / 6.0
			var arc_bow := sin(pct * PI) * 18.0
			line.add_point(from_w + offset + dir * (pct * 48.0) + perp * arc_bow)
		_spawn(line)
		var tw2 := create_tween()
		tw2.tween_property(line, "modulate:a", 0.0, 0.22)
		tw2.tween_callback(line.queue_free)


func play_arrow(from_grid: Vector2i, to_grid: Vector2i, damage: int,
		dmg_color: Color = Color(1.0, 0.95, 0.4)) -> void:
	var fw := gp(from_grid)
	var tw := gp(to_grid)
	play_target_ping(to_grid, Color(1.0, 0.76, 0.20, 0.9))
	_play_arrow_shaft(fw, tw)
	await get_tree().create_timer(0.18).timeout
	_play_impact_sparks(tw)
	play_damage_number(to_grid, damage, dmg_color)


func _play_arrow_shaft(from_w: Vector2, to_w: Vector2) -> void:
	var dir  := (to_w - from_w).normalized()
	var angle := dir.angle()
	# Shaft line grows from source toward target
	var shaft := Line2D.new()
	shaft.width = 3.0
	shaft.default_color = Color(0.72, 0.52, 0.28)
	shaft.add_point(from_w)
	shaft.add_point(from_w)   # tip starts at origin; animated below
	_spawn(shaft)
	var shaft_tw := create_tween()
	shaft_tw.tween_method(
		func(t: float) -> void: shaft.set_point_position(1, from_w.lerp(to_w, t)),
		0.0, 1.0, 0.18)
	shaft_tw.tween_property(shaft, "modulate:a", 0.0, 0.22)
	shaft_tw.tween_callback(shaft.queue_free)
	# Arrowhead triangle that travels with the tip
	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(0.0, -6.0),
		Vector2(4.0,  4.0),
		Vector2(-4.0, 4.0),
	])
	head.color    = Color(0.85, 0.75, 0.35)
	head.rotation = angle + deg_to_rad(90.0)
	head.position = from_w
	_spawn(head)
	var head_tw := create_tween()
	head_tw.tween_property(head, "position", to_w, 0.18)
	head_tw.tween_property(head, "modulate:a", 0.0, 0.22)
	head_tw.tween_callback(head.queue_free)


func _play_impact_sparks(world_pos: Vector2) -> void:
	# Eight radial spark lines
	for i in range(8):
		var angle := deg_to_rad(float(i) * 45.0 + randf_range(-10.0, 10.0))
		var spark := Line2D.new()
		spark.width = 2.5
		spark.default_color = Color(1.0, 0.9, 0.3)
		spark.add_point(world_pos + Vector2(cos(angle), sin(angle)) * 4.0)
		spark.add_point(world_pos + Vector2(cos(angle), sin(angle)) * randf_range(14.0, 22.0))
		_spawn(spark)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "modulate:a", 0.0, 0.28)
		tw.tween_property(spark, "position",
			Vector2(cos(angle), sin(angle)) * 6.0, 0.28)
		tw.chain().tween_callback(spark.queue_free)
	# Central flash
	_screen_flash(world_pos, Color(1.0, 0.9, 0.6, 0.55), 0.14)


#  Floating damage / heal numbers

func play_damage_number(grid_pos: Vector2i, amount: int,
		color: Color = Color.WHITE) -> void:
	var world := gp(grid_pos) + Vector2(randf_range(-8.0, 8.0), -20.0)
	var lbl   := Label.new()
	lbl.text  = str(amount)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.position = world
	_spawn(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", world.y - 52.0, 0.75)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.75).set_delay(0.3)
	tw.chain().tween_callback(lbl.queue_free)


func play_heal_number(grid_pos: Vector2i, amount: int) -> void:
	play_damage_number(grid_pos, amount, Color(0.35, 1.0, 0.55))


func play_combat_text(grid_pos: Vector2i, text: String, color: Color,
		font_size: int = 18, rise: float = 42.0) -> void:
	var world := gp(grid_pos) + Vector2(-30.0, -54.0)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.03))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.position = world
	lbl.size = Vector2(96.0, 26.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spawn(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", world.y - rise, 0.68).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.18, 1.18), 0.14)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.68).set_delay(0.26)
	tw.chain().tween_callback(lbl.queue_free)


func play_miss(grid_pos: Vector2i) -> void:
	play_combat_text(grid_pos, "MISS", Color(0.72, 0.78, 0.86), 18, 34.0)


func play_ko(grid_pos: Vector2i) -> void:
	play_combat_text(grid_pos, "KO", Color(1.0, 0.18, 0.10), 28, 56.0)
	_screen_flash(gp(grid_pos), Color(1.0, 0.12, 0.06, 0.45), 0.18)


func play_tactical_tag(grid_pos: Vector2i, text: String, color: Color) -> void:
	play_combat_text(grid_pos, text, color, 14, 30.0)


func play_target_ping(grid_pos: Vector2i, color: Color) -> void:
	var world := gp(grid_pos)
	for i in range(2):
		var ring := Line2D.new()
		var radius_scale := 0.68 + float(i) * 0.18
		var half_w := TILE_SIZE.x * 0.5 * radius_scale
		var half_h := TILE_SIZE.y * 0.5 * radius_scale
		ring.points = PackedVector2Array([
			Vector2(0.0, -half_h),
			Vector2(half_w, 0.0),
			Vector2(0.0, half_h),
			Vector2(-half_w, 0.0),
			Vector2(0.0, -half_h),
		])
		ring.width = 2.5
		ring.default_color = Color(color.r, color.g, color.b, color.a - float(i) * 0.24)
		ring.position = world
		_spawn(ring)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_interval(float(i) * 0.04)
		tw.tween_property(ring, "scale", Vector2(1.22, 1.22), 0.28)
		tw.tween_property(ring, "modulate:a", 0.0, 0.28)
		tw.chain().tween_callback(ring.queue_free)


#  Spell VFX

## Fire / Fira / Firaga
func play_fire(grid_pos: Vector2i) -> void:
	var world := gp(grid_pos)
	_screen_flash(world, Color(1.0, 0.55, 0.05, 0.65), 0.18)
	var particles := CPUParticles2D.new()
	particles.position        = world
	particles.emitting        = true
	particles.one_shot        = true
	particles.explosiveness   = 0.85
	particles.amount          = 40
	particles.lifetime        = 0.7
	particles.direction       = Vector2(0.0, -1.0)
	particles.spread          = 160.0
	particles.gravity         = Vector2(0.0, -60.0)
	particles.initial_velocity_min = 55.0
	particles.initial_velocity_max = 130.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 9.0
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.95, 0.3, 1.0))
	grad.set_color(1, Color(0.85, 0.1, 0.0, 0.0))
	particles.color_ramp = grad
	_spawn(particles)
	# Ember smoke rings
	for i in range(5):
		var ring := ColorRect.new()
		ring.size     = Vector2(12.0, 12.0)
		ring.color    = Color(0.6, 0.25, 0.05, 0.6)
		ring.position = world + Vector2(randf_range(-20.0, 20.0), randf_range(-10.0, 10.0))
		_spawn(ring)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(ring, "position:y", ring.position.y - randf_range(28.0, 48.0), 0.6)
		tw.tween_property(ring, "modulate:a", 0.0, 0.6).set_delay(0.1)
		tw.chain().tween_callback(ring.queue_free)
	get_tree().create_timer(1.2).timeout.connect(particles.queue_free)


## Blizzard / Blizzara / Blizzaga
func play_blizzard(grid_pos: Vector2i) -> void:
	var world := gp(grid_pos)
	_screen_flash(world, Color(0.5, 0.85, 1.0, 0.5), 0.12)
	# Ice shards flying outward
	for i in range(16):
		var angle := deg_to_rad(float(i) * 22.5 + randf_range(-8.0, 8.0))
		var shard := ColorRect.new()
		shard.size     = Vector2(5.0, 13.0)
		shard.rotation = angle
		shard.color    = Color(0.55, 0.88, 1.0, 0.95)
		shard.position = world
		_spawn(shard)
		var travel := randf_range(22.0, 42.0)
		var dir    := Vector2(cos(angle), sin(angle))
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "position", world + dir * travel, 0.35)
		tw.tween_property(shard, "modulate:a", 0.0, 0.40)
		tw.chain().tween_callback(shard.queue_free)
	# Crystal impact lines
	for i in range(4):
		var angle := deg_to_rad(float(i) * 90.0 + 45.0)
		var bar   := ColorRect.new()
		bar.size     = Vector2(3.0, 24.0)
		bar.rotation = angle
		bar.color    = Color(0.8, 0.95, 1.0, 0.9)
		bar.position = world
		_spawn(bar)
		var tw := create_tween()
		tw.tween_property(bar, "modulate:a", 0.0, 0.3)
		tw.tween_callback(bar.queue_free)


## Thunder / Thundara / Thundaga
func play_thunder(grid_pos: Vector2i) -> void:
	var world := gp(grid_pos)
	# Pre-flash
	_screen_flash(world, Color(0.85, 0.9, 1.0, 0.7), 0.08)
	for bolt_i in range(4):
		var bolt := Line2D.new()
		bolt.width         = 2.5
		bolt.default_color = Color(0.92, 0.95, 1.0, 1.0)
		bolt.joint_mode    = Line2D.LINE_JOINT_SHARP
		var ox := randf_range(-18.0, 18.0)
		var cur := Vector2(world.x + ox, world.y - 72.0)
		bolt.add_point(cur)
		for seg in range(6):
			cur += Vector2(randf_range(-14.0, 14.0), 12.0 + randf_range(0.0, 4.0))
			bolt.add_point(cur)
		bolt.add_point(world)
		_spawn(bolt)
		# Yellow glow copy
		var glow := bolt.duplicate() as Line2D
		glow.width         = 6.0
		glow.default_color = Color(0.95, 1.0, 0.4, 0.45)
		_spawn(glow)
		var tw := create_tween()
		tw.tween_interval(float(bolt_i) * 0.055)
		tw.tween_property(bolt, "modulate:a", 0.0, 0.22)
		tw.tween_callback(bolt.queue_free)
		var tw2 := create_tween()
		tw2.tween_interval(float(bolt_i) * 0.055)
		tw2.tween_property(glow, "modulate:a", 0.0, 0.18)
		tw2.tween_callback(glow.queue_free)
	# Ground shockwave circle
	_screen_flash(world, Color(0.8, 0.9, 1.0, 0.6), 0.15)


## Cure / Cura / Curaga
func play_cure(grid_pos: Vector2i) -> void:
	var world := gp(grid_pos)
	_screen_flash(world, Color(0.3, 1.0, 0.55, 0.45), 0.15)
	# Rising green crosses
	for i in range(10):
		var cross := Label.new()
		cross.text = ""
		cross.add_theme_font_size_override("font_size", 16)
		cross.add_theme_color_override("font_color",
			Color(0.3 + randf_range(0.0, 0.2), 1.0, 0.45 + randf_range(0.0, 0.3)))
		var ox := randf_range(-28.0, 28.0)
		var oy := randf_range(-16.0, 16.0)
		cross.position = world + Vector2(ox, oy)
		_spawn(cross)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_interval(float(i) * 0.055)
		tw.tween_property(cross, "position:y", cross.position.y - randf_range(36.0, 52.0), 0.75)
		tw.tween_property(cross, "modulate:a", 0.0, 0.75).set_delay(0.25)
		tw.chain().tween_callback(cross.queue_free)
	# White upward beam
	var beam := ColorRect.new()
	beam.size     = Vector2(8.0, 60.0)
	beam.color    = Color(0.8, 1.0, 0.85, 0.6)
	beam.position = world + Vector2(-4.0, -60.0)
	_spawn(beam)
	var beam_tw := create_tween()
	beam_tw.tween_property(beam, "modulate:a", 0.0, 0.4)
	beam_tw.tween_callback(beam.queue_free)


## Wind / Aero
func play_wind(grid_pos: Vector2i) -> void:
	var world := gp(grid_pos)
	for i in range(6):
		var arc := Line2D.new()
		arc.width         = 3.0
		arc.default_color = Color(0.65, 1.0, 0.55, 0.85)
		arc.joint_mode    = Line2D.LINE_JOINT_ROUND
		var oy := randf_range(-22.0, 22.0)
		for t in range(10):
			var pct := float(t) / 9.0
			arc.add_point(world + Vector2(-44.0 + pct * 88.0,
				oy + sin(pct * PI) * 14.0))
		_spawn(arc)
		var tw := create_tween()
		tw.tween_interval(float(i) * 0.045)
		tw.tween_property(arc, "modulate:a", 0.0, 0.38)
		tw.tween_callback(arc.queue_free)


## Holy / Faith beam
func play_holy(grid_pos: Vector2i) -> void:
	var world := gp(grid_pos)
	_screen_flash(world, Color(1.0, 1.0, 0.9, 0.8), 0.2)
	# Descending rays of light
	for i in range(8):
		var angle := deg_to_rad(float(i) * 45.0)
		var ray   := Line2D.new()
		ray.width         = 4.0
		ray.default_color = Color(1.0, 0.98, 0.8, 0.9)
		ray.add_point(world + Vector2(cos(angle), sin(angle)) * 8.0)
		ray.add_point(world + Vector2(cos(angle), sin(angle)) * 38.0)
		_spawn(ray)
		var tw := create_tween()
		tw.tween_property(ray, "modulate:a", 0.0, 0.45)
		tw.tween_callback(ray.queue_free)
	# Gold sparkle particles
	for i in range(20):
		var dot := ColorRect.new()
		dot.size     = Vector2(4.0, 4.0)
		dot.color    = Color(1.0, 0.95, 0.5, 1.0)
		var angle   := randf_range(0.0, TAU)
		var radius  := randf_range(8.0, 36.0)
		dot.position = world + Vector2(cos(angle), sin(angle)) * radius
		_spawn(dot)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(dot, "position:y", dot.position.y - randf_range(20.0, 40.0), 0.6)
		tw.tween_property(dot, "modulate:a", 0.0, 0.6).set_delay(0.1)
		tw.chain().tween_callback(dot.queue_free)


## Dark / Darkness
func play_dark(grid_pos: Vector2i) -> void:
	var world := gp(grid_pos)
	_screen_flash(world, Color(0.2, 0.0, 0.3, 0.65), 0.18)
	for i in range(12):
		var angle  := deg_to_rad(float(i) * 30.0 + randf_range(-15.0, 15.0))
		var shard  := ColorRect.new()
		shard.size     = Vector2(4.0, 16.0)
		shard.rotation = angle
		shard.color    = Color(0.35, 0.0, 0.5, 0.9)
		shard.position = world
		_spawn(shard)
		var dir := Vector2(cos(angle), sin(angle))
		var tw  := create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "position", world + dir * randf_range(18.0, 38.0), 0.3)
		tw.tween_property(shard, "modulate:a", 0.0, 0.38)
		tw.chain().tween_callback(shard.queue_free)


#  Death VFX

func play_death(grid_pos: Vector2i) -> void:
	var world := gp(grid_pos)
	# Soul rising  white/grey particles drifting upward
	var particles := CPUParticles2D.new()
	particles.position          = world
	particles.emitting          = true
	particles.one_shot          = true
	particles.explosiveness     = 0.3
	particles.amount            = 18
	particles.lifetime          = 1.4
	particles.direction         = Vector2(0.0, -1.0)
	particles.spread            = 30.0
	particles.gravity           = Vector2(0.0, -20.0)
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 45.0
	particles.scale_amount_min  = 3.0
	particles.scale_amount_max  = 7.0
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.9))
	grad.set_color(1, Color(0.6, 0.7, 1.0, 0.0))
	particles.color_ramp = grad
	_spawn(particles)
	get_tree().create_timer(2.0).timeout.connect(particles.queue_free)


#  Move trail

func play_step(grid_pos: Vector2i) -> void:
	var world := gp(grid_pos)
	var dot   := ColorRect.new()
	dot.size     = Vector2(10.0, 10.0)
	dot.color    = Color(0.4, 0.75, 1.0, 0.55)
	dot.position = world - Vector2(5.0, 5.0)
	_spawn(dot)
	var tw := create_tween()
	tw.tween_property(dot, "modulate:a", 0.0, 0.45)
	tw.tween_callback(dot.queue_free)


#  Aura / Dark Breath

## Expanding aura ring  used for War Cry, buffs, etc.
func play_aura(grid_pos: Vector2i, color: Color) -> void:
	var world := gp(grid_pos)
	for i in range(3):
		var ring := ColorRect.new()
		ring.size = Vector2(16.0 + float(i) * 10.0, 16.0 + float(i) * 10.0)
		var half := ring.size * 0.5
		ring.position = world - half
		ring.color = Color(color.r, color.g, color.b, 0.55 - float(i) * 0.15)
		_spawn(ring)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_interval(float(i) * 0.08)
		tw.tween_property(ring, "scale", Vector2(2.2, 2.2), 0.45)
		tw.tween_property(ring, "modulate:a", 0.0, 0.45)
		tw.chain().tween_callback(ring.queue_free)


## Haste  golden speed streaks shooting upward
func play_haste(grid_pos: Vector2i) -> void:
	var world := gp(grid_pos)
	_screen_flash(world, Color(1.0, 0.88, 0.1, 0.4), 0.14)
	for i in range(8):
		var ox := randf_range(-18.0, 18.0)
		var line := Line2D.new()
		line.width = 2.5
		line.default_color = Color(1.0, 0.85, 0.1, 0.9)
		line.add_point(world + Vector2(ox, randf_range(-4.0, 8.0)))
		line.add_point(world + Vector2(ox, -randf_range(26.0, 46.0)))
		_spawn(line)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_interval(float(i) * 0.035)
		tw.tween_property(line, "position:y", line.position.y - 22.0, 0.32)
		tw.tween_property(line, "modulate:a", 0.0, 0.32)
		tw.chain().tween_callback(line.queue_free)


## Protect  blue-silver shield rings expanding outward
func play_protect(grid_pos: Vector2i) -> void:
	var world := gp(grid_pos)
	_screen_flash(world, Color(0.3, 0.55, 1.0, 0.45), 0.18)
	# Expanding rings
	for i in range(3):
		var sz := 20.0 + float(i) * 12.0
		var ring := ColorRect.new()
		ring.size = Vector2(sz, sz)
		ring.position = world - ring.size * 0.5
		ring.color = Color(0.45, 0.65, 1.0, 0.7 - float(i) * 0.2)
		_spawn(ring)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_interval(float(i) * 0.09)
		tw.tween_property(ring, "scale", Vector2(2.5, 2.5), 0.5)
		tw.tween_property(ring, "modulate:a", 0.0, 0.5)
		tw.chain().tween_callback(ring.queue_free)
	# Silver sparkles rising
	for i in range(10):
		var dot := ColorRect.new()
		dot.size = Vector2(4.0, 4.0)
		dot.color = Color(0.7, 0.85, 1.0, 1.0)
		var angle := randf_range(0.0, TAU)
		var radius := randf_range(8.0, 28.0)
		dot.position = world + Vector2(cos(angle), sin(angle)) * radius - dot.size * 0.5
		_spawn(dot)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(dot, "position:y", dot.position.y - randf_range(18.0, 36.0), 0.55)
		tw.tween_property(dot, "modulate:a", 0.0, 0.55).set_delay(0.1)
		tw.chain().tween_callback(dot.queue_free)


## Dark breath  sweeping cone of void energy
func play_dark_breath(from_grid: Vector2i, to_grid: Vector2i) -> void:
	var fw := gp(from_grid)
	var tw_world := gp(to_grid)
	var dir := (tw_world - fw).normalized()
	var perp := Vector2(-dir.y, dir.x)
	_screen_flash(tw_world, Color(0.3, 0.0, 0.4, 0.6), 0.2)
	for i in range(12):
		var spread := perp * randf_range(-24.0, 24.0)
		var line := Line2D.new()
		line.width = 3.5
		line.default_color = Color(0.5 + randf() * 0.2, 0.0, 0.6 + randf() * 0.2, 0.85)
		line.add_point(fw + dir * 12.0)
		var mid := fw + dir * randf_range(20.0, 50.0) + spread * 0.5
		line.add_point(mid)
		line.add_point(tw_world + spread)
		_spawn(line)
		var tw2 := create_tween()
		tw2.tween_interval(float(i) * 0.025)
		tw2.tween_property(line, "modulate:a", 0.0, 0.35)
		tw2.tween_callback(line.queue_free)


#  Utility

## Adds a VFX node as a child and ensures it renders above everything.
func _spawn(node: CanvasItem) -> void:
	node.z_index = 200
	node.z_as_relative = false
	add_child(node)


func _screen_flash(world_pos: Vector2, color: Color, duration: float) -> void:
	var flash    := ColorRect.new()
	flash.size   = Vector2(72.0, 72.0)
	flash.color  = color
	flash.position = world_pos - Vector2(36.0, 36.0)
	_spawn(flash)
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, duration)
	tw.tween_callback(flash.queue_free)
