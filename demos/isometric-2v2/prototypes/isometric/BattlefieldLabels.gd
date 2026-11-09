extends Node2D
## Screen-space presentation only. Names never inherit actor/camera scaling.
var ui: CanvasLayer
var manager: BattleManager
var rows: Dictionary = {}
var anchors: Dictionary = {}

func setup(p_ui: CanvasLayer, p_manager: BattleManager) -> void:
	ui = p_ui
	manager = p_manager
	z_index = -1 # Menus and forecasts remain above the non-interactive labels.

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if not is_instance_valid(manager): return
	var living: Array[Unit] = []
	for unit in manager.units.values():
		if is_instance_valid(unit) and not unit.is_queued_for_deletion() and unit.hp > 0:
			living.append(unit)
	living.sort_custom(func(a: Unit,b: Unit):
		var ay := a.get_global_transform_with_canvas().origin.y
		var by := b.get_global_transform_with_canvas().origin.y
		return a.unit_id < b.unit_id if is_equal_approx(ay,by) else ay > by)
	var used: Array[Rect2] = []
	var alive: Dictionary = {}
	var viewport := get_viewport().get_visible_rect().size
	var right := viewport.x - 12.0
	if is_instance_valid(ui._right_panel_bg): right = minf(right, ui._right_panel_bg.position.x - 12.0)
	var safe := Rect2(12, minf(155, viewport.y * 0.22), maxf(80,right - 12), maxf(60,viewport.y - minf(155, viewport.y * 0.22) - 12))
	anchors.clear()
	for unit: Unit in living:
		alive[unit.unit_id] = true
		var label: Label = rows.get(unit.unit_id)
		if not is_instance_valid(label):
			label = Label.new()
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size",22)
			label.add_theme_color_override("font_color",Color("fff5df"))
			var style := StyleBoxFlat.new()
			style.bg_color = Color("111923")
			style.set_content_margin_all(5)
			style.set_corner_radius_all(4)
			style.border_width_left = 4
			style.border_color = Color("71c9e9") if unit.team == "player" else Color("ee9c8b")
			label.add_theme_stylebox_override("normal",style)
			add_child(label)
			rows[unit.unit_id] = label
		label.text = unit.display_name
		label.tooltip_text = "%s · %s · HP %d/%d" % [unit.display_name,"ALLY" if unit.team == "player" else "ENEMY",unit.hp,unit.unit_data.base_stats.hp]
		label.size = label.get_combined_minimum_size()
		var anchor := unit.get_global_transform_with_canvas() * Vector2(0, unit._hud_bar_y - 5)
		var position_value := Vector2(anchor.x-label.size.x*0.5, anchor.y-label.size.y)
		position_value.x = clampf(position_value.x,safe.position.x,maxf(safe.position.x,safe.end.x-label.size.x))
		position_value.y = clampf(position_value.y,safe.position.y,maxf(safe.position.y,safe.end.y-label.size.y))
		# Place lower actors first, then lift colliding labels above their own heads.
		var origin_y := position_value.y
		for lane in 12:
			var rect := Rect2(position_value,label.size).grow(3)
			var overlaps := false
			for occupied in used:
				if rect.intersects(occupied): overlaps = true
			if not overlaps: break
			var offset := float(lane + 1) * (label.size.y+8)
			position_value.y = clampf(origin_y - offset,safe.position.y,maxf(safe.position.y,safe.end.y-label.size.y))
		# At short viewport heights, prefer a sideways lane over hiding another name.
		if _overlaps(Rect2(position_value,label.size).grow(3),used):
			var found := false
			for lane_y in range(0, int(safe.size.y / (label.size.y + 8)) + 1):
				for step in range(0, int(safe.size.x / 16) + 1):
					for sign_value in [-1,1]:
						var candidate := Vector2(clampf(position_value.x + step * 16 * sign_value,safe.position.x,maxf(safe.position.x,safe.end.x-label.size.x)),clampf(position_value.y + lane_y*(label.size.y+8),safe.position.y,maxf(safe.position.y,safe.end.y-label.size.y)))
						if not _overlaps(Rect2(candidate,label.size).grow(3),used):
							position_value = candidate
							found = true
							break
					if found: break
				if found: break
		label.position = position_value
		label.visible = unit.visible
		used.append(Rect2(position_value,label.size).grow(3))
		anchors[unit.unit_id] = anchor
	for id in rows.keys():
		if not alive.has(id):
			rows[id].queue_free()
			rows.erase(id)
	queue_redraw()

func _draw() -> void:
	for id in anchors:
		var label: Label = rows.get(id)
		if not is_instance_valid(label) or not label.visible: continue
		var start := label.position + Vector2(label.size.x*0.5,label.size.y)
		var end: Vector2 = anchors[id]
		if start.distance_to(end) > 12:
			draw_line(start,end,Color(0.85,0.85,0.75,0.6),1.5,true)

func _overlaps(rect: Rect2, used: Array[Rect2]) -> bool:
	for other in used:
		if rect.intersects(other): return true
	return false
