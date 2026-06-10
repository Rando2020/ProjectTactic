## DeploymentScreen.gd
## Pre-battle unit placement. Shown between StageSelect node selection and
## BattleScene launch. Reads a MapData resource; player drags units onto
## highlighted deployment zones, rotates facing, then hits "Begin Battle".
##
## Signals:

class_name DeploymentScreen
extends Control

signal battle_started(deployment: Array)
signal cancelled

const _FONT_DISPLAY := preload("res://assets/fonts/TrajanPro-Regular.ttf")
const _FONT_HEADER  := preload("res://assets/fonts/Cinzel-Bold.ttf")
const _FONT_BODY    := preload("res://assets/fonts/IMFellEnglish-Regular.ttf")
const _FONT_UI      := preload("res://assets/fonts/CormorantGaramond-Regular.ttf")

const _BG       := Color(0.031, 0.035, 0.051)
const _SURFACE  := Color(0.067, 0.063, 0.047)
const _SURFACE2 := Color(0.102, 0.086, 0.063)
const _FG       := Color(0.941, 0.910, 0.816)
const _FG2      := Color(0.784, 0.722, 0.604)
const _DIM      := Color(0.353, 0.322, 0.278)
const _GOLD     := Color(0.831, 0.686, 0.275)
const _PLACED   := Color(0.22, 0.74, 1.0)
const _ZONE     := Color(0.22, 0.74, 0.55, 0.40)
const _ZONE_EDGE := Color(0.35, 1.0, 0.70, 0.92)
const _SAVED    := Color(0.56, 0.78, 1.0)
const _DANGER   := Color(0.93, 0.27, 0.27)

const _TERRAIN := {
	"grass":         Color(0.13, 0.28, 0.20),
	"road":          Color(0.37, 0.30, 0.21),
	"stone":         Color(0.36, 0.39, 0.43),
	"shrine":        Color(0.25, 0.19, 0.37),
	"shallow_water": Color(0.07, 0.42, 0.54),
	"deep_water":    Color(0.04, 0.20, 0.31),
	"ice":           Color(0.62, 0.86, 1.00),
	"burning":       Color(0.62, 0.21, 0.11),
	"wall":          Color(0.12, 0.13, 0.19),
	"high_ground":   Color(0.43, 0.42, 0.34),
}
const _TILE_PX := 56

## Validate a deployment formation against a MapData without instantiating a screen.
## Returns an empty Array if valid, or a list of human-readable error strings.
## Pass known_roster to enforce that only those unit IDs are valid.
static func validate_formation(formation: Array, map: MapData, known_roster: Array = []) -> Array:
	if formation.is_empty():
		return ["No saved formation."]

	# Build the zone set the same way _zones() does at runtime
	var zone_set: Dictionary = {}
	var zones: Array = []
	if map and map.deployment_zones.size() > 0:
		zones = map.deployment_zones
	else:
		var w: int = map.map_width  if map else 10
		var h: int = map.map_height if map else 8
		for row in range(h - 2, h):
			for col in range(0, mini(4, w)):
				zones.append({"x": col, "y": row})
	for z in zones:
		zone_set[Vector2i(int(z.get("x", 0)), int(z.get("y", 0)))] = true

	var errs: Array = []
	var used_tiles: Dictionary = {}
	var used_units: Dictionary = {}
	var party_cap: int = map.max_party_size if map else 4

	for slot: Dictionary in formation:
		var uid := str(slot.get("unit_id", ""))
		var pos := Vector2i(int(slot.get("x", 0)), int(slot.get("y", 0)))
		if uid.is_empty() or (not known_roster.is_empty() and not (uid in known_roster)):
			errs.append("Unknown unit in formation: %s" % uid)
			continue
		if used_units.has(uid):
			errs.append("Duplicate unit in formation: %s" % uid)
			continue
		if not zone_set.has(pos):
			errs.append("%s placed outside deployment zone (%d,%d)." % [uid, pos.x, pos.y])
			continue
		if used_tiles.has(pos):
			errs.append("Two units share the same tile (%d,%d)." % [pos.x, pos.y])
			continue
		used_tiles[pos] = true
		used_units[uid] = true

	if used_units.is_empty():
		errs.append("Formation contains no valid units.")

	if used_units.size() > party_cap:
		errs.append("Formation exceeds the map's party limit of %d." % party_cap)

	if map:
		for uid: String in map.required_unit_ids:
			if not used_units.has(uid):
				errs.append("Required unit '%s' is missing from the formation." % uid)

	return errs

## Returns {"name": ..., "job": ...} pulled live from the Characters autoload.
## Falls back gracefully if the autoload doesn't know the id.
func _unit_def(uid: String) -> Dictionary:
	var char_data: Dictionary = Characters.get_character(uid)
	if char_data.is_empty():
		return {"name": uid.capitalize(), "job": ""}
	var job_raw: String = char_data.get("starting_job", "")
	return {
		"name": char_data.get("human_name", uid.capitalize()),
		"job":  job_raw.capitalize(),
	}

var map_data: MapData = null
var saved_formation: Array = []
var saved_formation_loaded: bool = false
var _roster: Array        = []
var _deployment: Array    = []   # [{unit_id, x, y, facing}]
var _selected_id: String  = ""
var _editing_saved_formation: bool = false

var _roster_box:  VBoxContainer
var _grid_cont:   GridContainer
var _start_btn:   Button
var _status_lbl:  Label


func _ready() -> void:
	# Populate roster from the Characters autoload — single source of truth.
	_roster = Characters.PARTY_ORDER.duplicate()
	_setup_deployment()
	_editing_saved_formation = not saved_formation_loaded
	_build_ui()


func _fallback_map_data() -> MapData:
	var map := MapData.new()
	map.id = "deployment_preview"
	map.display_name = "Formation Ground"
	map.map_width = 10
	map.map_height = 8
	map.default_terrain = "grass"
	map.max_party_size = 4
	map.deployment_briefing = "Choose your starting formation. This formation will be reused for the run."
	var zones: Array[Dictionary] = []
	for y in range(map.map_height - 2, map.map_height):
		for x in range(0, 4):
			zones.append({"x": x, "y": y})
	map.deployment_zones = zones
	return map

func _setup_deployment() -> void:
	_deployment.clear()
	if map_data == null:
		map_data = _fallback_map_data()
	if saved_formation_loaded and not saved_formation.is_empty():
		_deployment = _sanitize_saved_formation(saved_formation)
		if not _deployment.is_empty():
			_selected_id = str(_deployment[0].get("unit_id", _roster[0] if _roster.size() > 0 else ""))
			return
	if map_data.player_spawns.size() > 0:
		for sp in map_data.player_spawns:
			_deployment.append({
				"unit_id": str(sp.get("unit_id", "aeryn")),
				"x":       int(sp.get("x", 0)),
				"y":       int(sp.get("y", 0)),
				"facing":  str(sp.get("facing", "S")),
			})
	else:
		var zones := _zones()
		for i in mini(_roster.size(), zones.size()):
			_deployment.append({
				"unit_id": _roster[i],
				"x": int(zones[i].get("x", i)),
				"y": int(zones[i].get("y", 0)),
				"facing": "S",
			})
	_selected_id = _roster[0] if _roster.size() > 0 else ""


func _sanitize_saved_formation(formation: Array) -> Array:
	var zone_positions: Array = []
	var zone_set: Dictionary = {}
	for z in _zones():
		var zone_pos := Vector2i(int(z.get("x", 0)), int(z.get("y", 0)))
		zone_positions.append(zone_pos)
		zone_set[zone_pos] = true

	var used: Dictionary = {}
	var result: Array = []
	var party_cap: int = map_data.max_party_size if map_data else 4
	for raw_slot in formation:
		if result.size() >= party_cap:
			break
		var saved_slot: Dictionary = raw_slot
		var uid := str(saved_slot.get("unit_id", ""))
		if uid.is_empty() or not (uid in _roster):
			continue
		var desired := Vector2i(int(saved_slot.get("x", 0)), int(saved_slot.get("y", 0)))
		var chosen_pos := desired
		if not zone_set.has(chosen_pos) or used.has(chosen_pos):
			chosen_pos = _first_open_zone(zone_positions, used)
		if chosen_pos.x < 0:
			continue
		used[chosen_pos] = true
		result.append({
			"unit_id": uid,
			"x": chosen_pos.x,
			"y": chosen_pos.y,
			"facing": _valid_facing(str(saved_slot.get("facing", "S"))),
		})

	for uid in _roster:
		if result.size() >= party_cap:
			break
		var already_placed := false
		for placed_slot in result:
			if str(placed_slot.get("unit_id", "")) == uid:
				already_placed = true
				break
		if already_placed:
			continue
		var fill_pos := _first_open_zone(zone_positions, used)
		if fill_pos.x < 0:
			break
		used[fill_pos] = true
		result.append({"unit_id": uid, "x": fill_pos.x, "y": fill_pos.y, "facing": "S"})
	return result


func _first_open_zone(zone_positions: Array, used: Dictionary) -> Vector2i:
	for pos in zone_positions:
		if not used.has(pos):
			return pos
	return Vector2i(-1, -1)


func _valid_facing(facing: String) -> String:
	return facing if facing in ["N", "E", "S", "W"] else "S"


func _zones() -> Array:
	if map_data and map_data.deployment_zones.size() > 0:
		return map_data.deployment_zones
	# Fallback: bottom-left corner
	var zones: Array = []
	var w: int = map_data.map_width  if map_data else 10
	var h: int = map_data.map_height if map_data else 8
	for row in range(h - 2, h):
		for col in range(0, mini(4, w)):
			zones.append({"x": col, "y": row})
	return zones


#  UI BUILD

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var bg := ColorRect.new()
	bg.color = _BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(1200, 0)
	root.add_theme_constant_override("separation", 0)
	scroll.add_child(root)

	_build_header(root)
	_build_brief_bar(root)
	_space(root, 12)
	_build_main_layout(root)
	_space(root, 24)
	_refresh_start_btn()


func _build_header(root: VBoxContainer) -> void:
	var hdr := _solid_panel(root, _SURFACE2, Vector2(0, 80))
	var hh  := HBoxContainer.new()
	hh.add_theme_constant_override("margin_left", 32)
	hh.add_theme_constant_override("margin_right", 32)
	hh.alignment = BoxContainer.ALIGNMENT_CENTER
	hh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hdr.add_child(hh)

	var col := VBoxContainer.new()
	hh.add_child(col)
	_eyebrow(col, "SAVED FORMATION" if saved_formation_loaded else "PRE-BATTLE DEPLOYMENT")
	_heading(col, map_data.display_name if map_data else "Unknown Map", 26)

	var stretch := Control.new()
	stretch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(stretch)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	hh.add_child(btns)

	var back := _iron_btn("Back")
	back.pressed.connect(func() -> void: cancelled.emit())
	btns.add_child(back)

	if saved_formation_loaded:
		var edit := _iron_btn("Edit Formation")
		edit.pressed.connect(_on_edit_saved_formation)
		btns.add_child(edit)

	_start_btn = _gold_btn("Use Saved" if saved_formation_loaded and not _editing_saved_formation else "Begin Battle")
	_start_btn.pressed.connect(_on_start)
	btns.add_child(_start_btn)


func _build_brief_bar(root: VBoxContainer) -> void:
	var bar := _solid_panel(root, Color(0.05, 0.05, 0.07), Vector2(0, 36))
	_status_lbl = Label.new()
	_status_lbl.add_theme_font_override("font", _FONT_BODY)
	_status_lbl.add_theme_font_size_override("font_size", 13)
	_status_lbl.add_theme_color_override("font_color", _FG2)
	_status_lbl.add_theme_constant_override("margin_left", 32)
	_status_lbl.set_anchors_and_offsets_preset(Control.PRESET_VCENTER_WIDE)
	if map_data and map_data.deployment_briefing != "":
		_status_lbl.text = map_data.deployment_briefing
	else:
		_status_lbl.text = "Place your units on the highlighted deployment zones, then begin the battle."
	if saved_formation_loaded:
		_status_lbl.text = "Editing saved formation. Begin Battle will save these positions for the run." if _editing_saved_formation else "Saved formation loaded. Use Saved to begin immediately, or Edit Formation to adjust."
	bar.add_child(_status_lbl)


func _build_main_layout(root: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("margin_left", 24)
	hbox.add_theme_constant_override("margin_right", 24)
	hbox.add_theme_constant_override("separation", 20)
	root.add_child(hbox)

	_build_roster_panel(hbox)
	_build_grid_panel(hbox)


func _build_roster_panel(parent: HBoxContainer) -> void:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(260, 0)
	_iron_panel_style(pc)
	parent.add_child(pc)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_theme_constant_override("margin_left", 16)
	box.add_theme_constant_override("margin_right", 16)
	box.add_theme_constant_override("margin_top", 16)
	box.add_theme_constant_override("margin_bottom", 16)
	pc.add_child(box)

	_heading_sm(box, "ROSTER")

	var cap := Label.new()
	cap.add_theme_font_override("font", _FONT_BODY)
	cap.add_theme_font_size_override("font_size", 12)
	cap.add_theme_color_override("font_color", _DIM)
	var zone_count := _zones().size()
	cap.text = "Max party: %d  |  Zones: %d" % [(map_data.max_party_size if map_data else 4), zone_count]
	box.add_child(cap)

	if saved_formation_loaded:
		var saved := Label.new()
		saved.add_theme_font_override("font", _FONT_BODY)
		saved.add_theme_font_size_override("font_size", 12)
		saved.add_theme_color_override("font_color", _SAVED)
		saved.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		saved.text = "Saved: %s" % _formation_summary()
		box.add_child(saved)
		var mode := Label.new()
		mode.add_theme_font_override("font", _FONT_BODY)
		mode.add_theme_font_size_override("font_size", 11)
		mode.add_theme_color_override("font_color", _GOLD if _editing_saved_formation else _DIM)
		mode.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mode.text = "Editing enabled" if _editing_saved_formation else "Locked preview. Press Edit Formation to move units."
		box.add_child(mode)

	_sep(box)

	_roster_box = VBoxContainer.new()
	_roster_box.add_theme_constant_override("separation", 6)
	box.add_child(_roster_box)

	_refresh_roster()
	_sep(box)

	# Rotate / Remove buttons
	var ctrl := HBoxContainer.new()
	ctrl.add_theme_constant_override("separation", 8)
	box.add_child(ctrl)

	var rot_btn := _iron_btn("Rotate")
	rot_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rot_btn.pressed.connect(_on_rotate)
	ctrl.add_child(rot_btn)

	var rem_btn := _iron_btn("Remove")
	rem_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rem_btn.pressed.connect(_on_remove)
	ctrl.add_child(rem_btn)

	_space(box, 8)

	# Facing legend
	var legend := Label.new()
	legend.add_theme_font_override("font", _FONT_BODY)
	legend.add_theme_font_size_override("font_size", 11)
	legend.add_theme_color_override("font_color", _DIM)
	legend.text = "Facing: N / E / S / W\nClick a DEPLOY zone to place selected unit."
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(legend)


func _refresh_roster() -> void:
	for c in _roster_box.get_children():
		c.queue_free()

	var placed: Dictionary = {}
	for slot in _deployment:
		placed[slot["unit_id"]] = slot
	var required: Array = map_data.required_unit_ids if map_data else []

	for uid in _roster:
		var udef: Dictionary = _unit_def(uid)
		var is_sel: bool = _selected_id == uid
		var is_placed: bool = placed.has(uid)
		var is_req: bool = uid in required

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 46)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_override("font", _FONT_DISPLAY)
		btn.add_theme_font_size_override("font_size", 12)

		var border: Color = _GOLD if is_sel else (_PLACED if is_placed else Color(1, 1, 1, 0.12))
		var st := StyleBoxFlat.new()
		st.bg_color     = Color(0.11, 0.10, 0.08) if is_sel else _SURFACE
		st.border_color = border
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			st.set_border_width(side, 2 if is_sel else 1)
		st.content_margin_left = 10; st.content_margin_right = 10
		st.content_margin_top  = 8;  st.content_margin_bottom = 8
		btn.add_theme_stylebox_override("normal",  st)
		btn.add_theme_stylebox_override("hover",   st)
		btn.add_theme_stylebox_override("pressed", st)

		var facing_str := ""
		if is_placed:
			facing_str = "  %s" % _arrow(placed[uid]["facing"])
		var status := "[REQ]" if is_req else ("[PLACED]" if is_placed else "Reserve")
		btn.text = "%s%s\n%s - %s" % [udef["name"], facing_str, udef.get("job", ""), status]

		var fc := _GOLD if is_sel else (_PLACED if is_placed else (_DANGER if is_req else _FG2))
		btn.add_theme_color_override("font_color",       fc)
		btn.add_theme_color_override("font_hover_color", fc)
		btn.pressed.connect(func() -> void: _select(uid))
		_roster_box.add_child(btn)


func _build_grid_panel(parent: HBoxContainer) -> void:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_iron_panel_style(pc)
	parent.add_child(pc)

	var grid_wrap := VBoxContainer.new()
	grid_wrap.add_theme_constant_override("separation", 10)
	grid_wrap.add_theme_constant_override("margin_left", 16)
	grid_wrap.add_theme_constant_override("margin_right", 16)
	grid_wrap.add_theme_constant_override("margin_top", 16)
	grid_wrap.add_theme_constant_override("margin_bottom", 16)
	pc.add_child(grid_wrap)

	var map_meta := Label.new()
	map_meta.add_theme_font_override("font", _FONT_BODY)
	map_meta.add_theme_font_size_override("font_size", 12)
	map_meta.add_theme_color_override("font_color", _FG2)
	map_meta.text = "Map %dx%d  |  Deployment zones: %d" % [
		map_data.map_width if map_data else 10,
		map_data.map_height if map_data else 8,
		_zones().size(),
	]
	grid_wrap.add_child(map_meta)

	var inner_scroll := ScrollContainer.new()
	inner_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	inner_scroll.custom_minimum_size    = Vector2(0, 520)
	grid_wrap.add_child(inner_scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner_scroll.add_child(center)

	_grid_cont = GridContainer.new()
	_grid_cont.columns = map_data.map_width if map_data else 10
	_grid_cont.add_theme_constant_override("h_separation", 4)
	_grid_cont.add_theme_constant_override("v_separation", 4)
	center.add_child(_grid_cont)

	_refresh_grid()


func _refresh_grid() -> void:
	for c in _grid_cont.get_children():
		c.queue_free()
	if map_data == null:
		return

	var w: int = map_data.map_width
	var h: int = map_data.map_height
	_grid_cont.columns = w

	# Build terrain map
	var terrain_map: Dictionary = {}
	for row in range(h):
		for col in range(w):
			terrain_map[Vector2i(col, row)] = map_data.default_terrain
	for ov in map_data.tile_overrides:
		terrain_map[Vector2i(int(ov.get("x", 0)), int(ov.get("y", 0)))] = str(ov.get("terrain", map_data.default_terrain))

	# Zone set
	var zone_set: Dictionary = {}
	for z in _zones():
		zone_set[Vector2i(int(z.get("x", 0)), int(z.get("y", 0)))] = true

	# Placed unit lookup
	var placed_map: Dictionary = {}
	for slot in _deployment:
		placed_map[Vector2i(slot["x"], slot["y"])] = slot

	for row in range(h):
		for col in range(w):
			var pos      := Vector2i(col, row)
			var terrain  := str(terrain_map.get(pos, "grass"))
			var is_zone  := zone_set.has(pos)
			var slot: Variant = placed_map.get(pos, null)

			var base_col: Color = _TERRAIN.get(terrain, _TERRAIN["grass"])

			var btn := Button.new()
			btn.custom_minimum_size = Vector2(_TILE_PX, _TILE_PX)
			btn.focus_mode = Control.FOCUS_NONE

			var st := StyleBoxFlat.new()
			st.bg_color     = base_col.lerp(_ZONE, 0.6) if is_zone else base_col
			st.border_color = _ZONE_EDGE if is_zone else Color(1, 1, 1, 0.06)
			for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
				st.set_border_width(side, 2 if is_zone else 1)
			btn.add_theme_stylebox_override("normal", st)

			var hv := st.duplicate() as StyleBoxFlat
			hv.bg_color     = base_col.lightened(0.15).lerp(_ZONE, 0.5) if is_zone else base_col.lightened(0.15)
			hv.border_color = _GOLD if is_zone else Color(1, 1, 1, 0.2)
			for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
				hv.set_border_width(side, 2 if is_zone else 1)
			btn.add_theme_stylebox_override("hover", hv)

			# If a unit is placed here
			if slot != null:
				var uid: String    = str(slot["unit_id"])
				var udef: Dictionary = _unit_def(uid)
				var is_sel         := _selected_id == uid
				var tok_lbl        := Label.new()
				tok_lbl.text       = "%s\n%s" % [udef["name"].left(3).to_upper(), _arrow(str(slot["facing"]))]
				tok_lbl.add_theme_font_override("font", _FONT_DISPLAY)
				tok_lbl.add_theme_font_size_override("font_size", 10)
				tok_lbl.add_theme_color_override("font_color", _GOLD if is_sel else _PLACED)
				tok_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				tok_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
				tok_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				btn.add_child(tok_lbl)
				if is_sel:
					var sel_st := st.duplicate() as StyleBoxFlat
					sel_st.border_color = _GOLD
					for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
						sel_st.set_border_width(side, 2)
					btn.add_theme_stylebox_override("normal", sel_st)
			elif is_zone:
				var marker := Label.new()
				marker.text = "DEPLOY"
				marker.add_theme_font_override("font", _FONT_UI)
				marker.add_theme_font_size_override("font_size", 9)
				marker.add_theme_color_override("font_color", _ZONE_EDGE)
				marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				marker.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
				marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				btn.add_child(marker)

			# Coordinate label
			if is_zone or slot != null:
				var coord := Label.new()
				coord.text = "%d,%d" % [col, row]
				coord.add_theme_font_size_override("font_size", 8)
				coord.add_theme_color_override("font_color", Color(1, 1, 1, 0.24))
				coord.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
				coord.position = Vector2(3, 2)
				btn.add_child(coord)

			btn.pressed.connect(_on_tile.bind(col, row, is_zone))
			_grid_cont.add_child(btn)


#  INTERACTIONS

func _select(uid: String) -> void:
	_selected_id = uid
	_refresh_roster()
	_refresh_grid()


func _on_tile(x: int, y: int, is_zone: bool) -> void:
	if saved_formation_loaded and not _editing_saved_formation:
		_status_lbl.text = "Saved formation is locked. Press Edit Formation to adjust positions."
		_status_lbl.add_theme_color_override("font_color", _SAVED)
		return
	if not is_zone or _selected_id.is_empty():
		return
	# Clear any unit already at this tile
	_deployment = _deployment.filter(func(s: Dictionary) -> bool:
		return not (s["x"] == x and s["y"] == y))
	# Remove the selected unit from its previous tile
	_deployment = _deployment.filter(func(s: Dictionary) -> bool:
		return s["unit_id"] != _selected_id)
	_deployment.append({"unit_id": _selected_id, "x": x, "y": y, "facing": "S"})
	_status_lbl.text = "%s positioned at %d,%d. Rotate to set facing." % [_unit_name(_selected_id), x, y]
	_status_lbl.add_theme_color_override("font_color", _FG2)
	_refresh_roster()
	_refresh_grid()
	_refresh_start_btn()


func _on_rotate() -> void:
	if saved_formation_loaded and not _editing_saved_formation:
		_status_lbl.text = "Saved formation is locked. Press Edit Formation to rotate units."
		_status_lbl.add_theme_color_override("font_color", _SAVED)
		return
	if _selected_id.is_empty():
		return
	const CYCLE := ["N", "E", "S", "W"]
	for slot in _deployment:
		if slot["unit_id"] == _selected_id:
			var idx: int = CYCLE.find(str(slot["facing"]))
			slot["facing"] = CYCLE[(idx + 1) % CYCLE.size()]
			_status_lbl.text = "%s now faces %s." % [_unit_name(_selected_id), _arrow(str(slot["facing"]))]
			_status_lbl.add_theme_color_override("font_color", _FG2)
	_refresh_roster()
	_refresh_grid()


func _on_remove() -> void:
	if saved_formation_loaded and not _editing_saved_formation:
		_status_lbl.text = "Saved formation is locked. Press Edit Formation to remove units."
		_status_lbl.add_theme_color_override("font_color", _SAVED)
		return
	if _selected_id.is_empty():
		return
	var required: Array = map_data.required_unit_ids if map_data else []
	if _selected_id in required:
		_status_lbl.text = "%s is required and cannot be removed." % _selected_id.capitalize()
		_status_lbl.add_theme_color_override("font_color", _DANGER)
		return
	_deployment = _deployment.filter(func(s: Dictionary) -> bool:
		return s["unit_id"] != _selected_id)
	_status_lbl.text = "%s returned to reserve." % _unit_name(_selected_id)
	_status_lbl.add_theme_color_override("font_color", _FG2)
	_refresh_roster()
	_refresh_grid()
	_refresh_start_btn()


func _on_start() -> void:
	var errs := _validate()
	if errs.size() > 0:
		_status_lbl.text = errs[0]
		_status_lbl.add_theme_color_override("font_color", _DANGER)
		return
	battle_started.emit(_deployment.duplicate(true))


func _on_edit_saved_formation() -> void:
	_editing_saved_formation = true
	_build_ui()


func _validate() -> Array:
	var errs: Array = []
	if map_data == null:
		errs.append("No map data loaded.")
		return errs
	if _deployment.is_empty():
		errs.append("Place at least one unit before starting.")
	for uid in map_data.required_unit_ids:
		var found := false
		for slot in _deployment:
			if slot["unit_id"] == uid:
				found = true; break
		if not found:
			errs.append("%s is required and has not been placed." % _unit_def(uid).get("name", uid))
	return errs


func _refresh_start_btn() -> void:
	_start_btn.disabled = _validate().size() > 0


#  WIDGET HELPERS

func _unit_name(uid: String) -> String:
	return _unit_def(uid).get("name", uid.capitalize())


func _formation_summary() -> String:
	var parts: Array = []
	for slot in _deployment:
		parts.append("%s %d,%d %s" % [
			_unit_name(str(slot.get("unit_id", ""))),
			int(slot.get("x", 0)),
			int(slot.get("y", 0)),
			_arrow(str(slot.get("facing", "S"))),
		])
	return " | ".join(parts)

func _arrow(facing: String) -> String:
	match facing:
		"N": return "N"
		"E": return "E"
		"S": return "S"
		"W": return "W"
		_:   return "S"


func _eyebrow(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _FONT_UI)
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", _DIM)
	l.add_theme_constant_override("character_spacing", 4)
	parent.add_child(l)
	return l


func _heading(parent: Control, text: String, sz: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _FONT_DISPLAY)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", _FG)
	parent.add_child(l)
	return l


func _heading_sm(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _FONT_HEADER)
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", _GOLD)
	l.add_theme_constant_override("character_spacing", 2)
	parent.add_child(l)
	return l


func _solid_panel(parent: Control, color: Color, min_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var pc := PanelContainer.new()
	if min_size != Vector2.ZERO:
		pc.custom_minimum_size = min_size
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color = color
	pc.add_theme_stylebox_override("panel", st)
	parent.add_child(pc)
	return pc


func _iron_panel_style(pc: PanelContainer) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color     = _SURFACE
	st.border_color = Color(0.239, 0.208, 0.188, 0.45)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	pc.add_theme_stylebox_override("panel", st)


func _iron_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_override("font", _FONT_DISPLAY)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", _FG2)
	var st := StyleBoxFlat.new()
	st.bg_color     = _SURFACE
	st.border_color = Color(0.239, 0.208, 0.188, 0.6)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	st.content_margin_left = 14; st.content_margin_right  = 14
	st.content_margin_top  = 8;  st.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", st)
	var hv := st.duplicate() as StyleBoxFlat
	hv.border_color = _GOLD
	btn.add_theme_stylebox_override("hover", hv)
	return btn


func _gold_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_override("font", _FONT_DISPLAY)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.08, 0.06, 0.03))
	var st := StyleBoxFlat.new()
	st.bg_color      = _GOLD
	st.border_color  = _GOLD.darkened(0.3)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	st.content_margin_left = 22; st.content_margin_right  = 22
	st.content_margin_top  = 10; st.content_margin_bottom = 10
	st.shadow_color = Color(_GOLD.r, _GOLD.g, _GOLD.b, 0.3)
	st.shadow_size  = 16
	btn.add_theme_stylebox_override("normal", st)
	var hv := st.duplicate() as StyleBoxFlat
	hv.bg_color    = _GOLD.lightened(0.15)
	hv.shadow_size = 24
	btn.add_theme_stylebox_override("hover", hv)
	# Disabled style
	var dis := StyleBoxFlat.new()
	dis.bg_color     = Color(0.12, 0.11, 0.09)
	dis.border_color = Color(0.20, 0.18, 0.14)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		dis.set_border_width(side, 1)
	dis.content_margin_left = 22; dis.content_margin_right  = 22
	dis.content_margin_top  = 10; dis.content_margin_bottom = 10
	btn.add_theme_stylebox_override("disabled", dis)
	btn.add_theme_color_override("font_disabled_color", _DIM)
	return btn


func _sep(parent: Control) -> void:
	var s := HSeparator.new()
	s.add_theme_color_override("color", Color(1, 1, 1, 0.07))
	parent.add_child(s)


func _space(parent: Control, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)
