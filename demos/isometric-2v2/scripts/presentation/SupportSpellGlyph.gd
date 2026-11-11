## Original procedural support glyphs, not imported or bespoke painted animation.
## Draw coordinates are relative to the ground contact, just like authored sheets.
extends Sprite2D
var stage := "casting"
var ability_id := "haste"
var progress := 0.0
var reduced_motion := false

func configure(ability: String, phase: String) -> void:
	ability_id = ability
	stage = phase
	show_progress(0.0)

func available() -> bool:
	return true

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	queue_redraw()

func show_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	modulate.a = 1.0 - smoothstep(0.15, 1.0, progress) if stage == "dissipation" else 1.0
	queue_redraw()

func _draw() -> void:
	var haste := ability_id == "haste"
	var gold := Color(1.0, 0.82, 0.34, 0.95)
	var light := Color(1.0, 0.98, 0.78, 1.0)
	var center := Vector2(0, -42)
	var radius := 19.0 if stage == "casting" else 25.0
	var reveal := 1.0 if reduced_motion else lerpf(0.65, 1.0, smoothstep(0, 0.55, progress))
	radius *= reveal
	# Ground footprint remains anchored while the suspended emblem resolves.
	var floor_points := PackedVector2Array()
	for i in 49:
		var a := TAU * float(i) / 48.0
		floor_points.append(Vector2(cos(a)*34, sin(a)*11))
	draw_polyline(floor_points, Color(0.1,0.07,0.03,0.75), 5, true)
	draw_polyline(floor_points, gold, 2.0, true)
	if haste:
		# A clock face and forward chevrons read as speed rather than an explosion.
		draw_circle(center, radius+3, Color(0.09,0.08,0.05,0.68))
		draw_arc(center, radius, 0, TAU, 64, gold, 2.5, true)
		draw_arc(center, radius-4, -PI*0.85, PI*0.6, 40, Color(1,0.93,0.58,0.45), 1, true)
		for i in 12:
			var direction := Vector2.from_angle(TAU*float(i)/12.0)
			draw_line(center+direction*(radius-5), center+direction*(radius-1), light, 1.5, true)
		var hand_angle := -PI/2 + (0.0 if reduced_motion else progress*PI*1.5)
		draw_line(center, center+Vector2.from_angle(hand_angle)*(radius-7), light, 2.5, true)
		draw_line(center, center+Vector2(8,-3), gold, 3, true)
		draw_circle(center, 2.5, light)
		for side in [-1,1]:
			for i in 2:
				var x := float(side)*(radius+8+i*7)
				var points := PackedVector2Array([center+Vector2(x-4,-5),center+Vector2(x,0),center+Vector2(x-4,5)])
				draw_polyline(points,gold,2.5,true)
	else:
		# A broad shield, not an impact flash. Shoulder braces frame the actor.
		var shield := PackedVector2Array([center+Vector2(-radius,-13),center+Vector2(0,-19),center+Vector2(radius,-13),center+Vector2(radius*0.8,10),center+Vector2(0,26),center+Vector2(-radius*0.8,10)])
		draw_colored_polygon(shield,Color(0.13,0.13,0.12,0.60))
		shield.append(shield[0])
		draw_polyline(shield,gold,3,true)
		draw_line(center+Vector2(0,-12),center+Vector2(0,16),light,3,true)
		draw_line(center+Vector2(-11,-2),center+Vector2(11,-2),light,3,true)
		for side in [-1,1]:
			var brace := PackedVector2Array([Vector2(side*40,-50),Vector2(side*33,-43),Vector2(side*33,-20),Vector2(side*40,-13)])
			draw_polyline(brace,gold,3,true)
