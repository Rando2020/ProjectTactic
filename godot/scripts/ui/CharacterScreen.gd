class_name CharacterScreen
extends Control

const DISPLAY_FONT := preload("res://assets/fonts/TrajanPro-Regular.ttf")
const CINZEL_FONT  := preload("res://assets/fonts/Cinzel-Regular.ttf")

const UNIT_IDS: Array[String] = ["zane", "mira", "kael", "lyra"]
const TABS: Array[String]     = ["Status", "Jobs", "Abilities", "Equipment"]

# Attribute display names (map BASE_STATS keys to UI labels)
const ATTR_NAMES := {
	"physical": "Strength",
	"magic": "Magic",
	"bravery": "Vitality",
	"faith": "Spirit",
	"speed": "Agility",
	"move": "Move",
}

const PORTRAITS := {
	"zane": "res://assets/sprites/units/zane-idle-isometric.png",
	"mira": "res://assets/sprites/units/mira-idle-isometric.png",
	"kael": "res://assets/sprites/units/kael-idle-isometric.png",
	"lyra": "res://assets/sprites/units/lyra-idle-isometric.png",
}

const BASE_STATS := {
	"zane": {"level":11,"hp":320,"mp":90,"max_temper":80,"max_ether":110,"move":4,"jump":2,"speed":8,"physical":42,"magic":48,"bravery":80,"faith":70},
	"mira": {"level":10,"hp":280,"mp":120,"max_temper":65,"max_ether":130,"move":4,"jump":2,"speed":7,"physical":28,"magic":54,"bravery":65,"faith":84},
	"kael": {"level":12,"hp":380,"mp":55,"max_temper":110,"max_ether":70,"move":4,"jump":2,"speed":6,"physical":55,"magic":32,"bravery":92,"faith":54},
	"lyra": {"level":10,"hp":240,"mp":70,"max_temper":55,"max_ether":65,"move":4,"jump":2,"speed":9,"physical":52,"magic":18,"bravery":72,"faith":60},
}

const SLOT_LABELS := {
	"main_hand": "WEAPON", "off_hand": "OFF-HAND",
	"head": "HEAD", "body": "ARMOR", "accessory": "ACCESSORY",
}

const ABILITY_ICONS := {
	"physical":  "res://assets/ui/insignias/soldier.svg",
	"fire":      "res://assets/ui/insignias/mage.svg",
	"blizzard":  "res://assets/ui/insignias/mage.svg",
	"thunder":   "res://assets/ui/insignias/mage.svg",
	"wind":      "res://assets/ui/insignias/archer.svg",
	"holy":      "res://assets/ui/insignias/cleric.svg",
	"dark":      "res://assets/ui/insignias/templar.svg",
	"buff":      "res://assets/ui/insignias/templar.svg",
	"cure":      "res://assets/ui/insignias/cleric.svg",
	"heal":      "res://assets/ui/insignias/cleric.svg",
	"resonance": "res://assets/ui/insignias/mage.svg",
}

# Maps job id → insignia SVG (best visual match)
const JOB_INSIGNIAS := {
	"squire":    "res://assets/ui/insignias/soldier.svg",
	"arcanist":  "res://assets/ui/insignias/mage.svg",
	"scout":     "res://assets/ui/insignias/archer.svg",
	"knight":    "res://assets/ui/insignias/knight.svg",
	"warmage":   "res://assets/ui/insignias/mage.svg",
	"priest":    "res://assets/ui/insignias/cleric.svg",
	"ranger":    "res://assets/ui/insignias/archer.svg",
	"paladin":   "res://assets/ui/insignias/templar.svg",
	"archmage":  "res://assets/ui/insignias/mage.svg",
	"hierophant":"res://assets/ui/insignias/cleric.svg",
	"assassin":  "res://assets/ui/insignias/vagrant.svg",
	"dark_knight":"res://assets/ui/insignias/templar.svg",
}

# ── Palette ──────────────────────────────────────────────────────────────────
const C_BG         := Color(0.016, 0.014, 0.020)
const C_PANEL      := Color(0.044, 0.040, 0.054, 0.96)
const C_PANEL_DEEP := Color(0.026, 0.022, 0.032, 0.98)
const C_PANEL_MID  := Color(0.060, 0.054, 0.070, 0.95)
const C_GOLD       := Color(0.88, 0.72, 0.26)
const C_GOLD_BRIGHT:= Color(1.00, 0.90, 0.50)
const C_GOLD_DIM   := Color(0.52, 0.42, 0.16)
const C_TEXT       := Color(0.93, 0.89, 0.76)
const C_SUBTEXT    := Color(0.60, 0.57, 0.50)
const C_HP         := Color(0.76, 0.15, 0.18)
const C_TEMPER     := Color(0.88, 0.54, 0.10)
const C_ETHER      := Color(0.50, 0.26, 0.82)
const C_CT         := Color(0.26, 0.60, 0.92)
const C_LEARNED    := Color(0.40, 0.82, 0.48)

var _gs: Node
var _selected_uid: String   = "zane"
var _active_tab: String     = "Status"
var _selected_ability: String = ""
var _root: VBoxContainer
var _hint_label: Label


func _ready() -> void:
	_gs = get_node_or_null("/root/GameState")
	if _gs and not _gs.unit_registry.has(_selected_uid) and not _gs.unit_registry.is_empty():
		_selected_uid = str(_gs.unit_registry.keys()[0])
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_Q:
			_select_adjacent_unit(-1)
			get_viewport().set_input_as_handled()
		KEY_E:
			_select_adjacent_unit(1)
			get_viewport().set_input_as_handled()
		KEY_1: _set_tab("Status")
		KEY_2: _set_tab("Jobs")
		KEY_3: _set_tab("Abilities")
		KEY_4: _set_tab("Equipment")
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/HubScene.tscn")


# ── Top-level build ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_add_stone_floor(bg)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.48)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left","margin_right"]:
		margin.add_theme_constant_override(side, 52)
	for side in ["margin_top","margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	add_child(margin)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 14)
	margin.add_child(_root)

	_build_breadcrumb()
	_build_tab_bar()
	_build_main_content()
	_build_roster_strip()
	_build_footer()


func _build_breadcrumb() -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 40
	_root.add_child(row)

	var crumb := _label("Units  ›  %s  ›  %s" % [_get_reg(_selected_uid).get("display_name", _selected_uid.capitalize()), _active_tab], 28, C_GOLD, true)
	crumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(crumb)

	var gold_col := VBoxContainer.new()
	gold_col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(gold_col)
	gold_col.add_child(_label("GOLD", 16, C_SUBTEXT, true, HORIZONTAL_ALIGNMENT_RIGHT))
	gold_col.add_child(_label("%d" % (_gs.gold if _gs else 0), 28, C_GOLD_BRIGHT, true, HORIZONTAL_ALIGNMENT_RIGHT))


func _build_main_content() -> void:
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 16)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(main)

	# Left panel: portrait + stats
	main.add_child(_build_left_panel(_selected_uid))

	# Center: tab content (scrollable)
	var center := ScrollContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(center)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	center.add_child(content)

	var reg := _get_reg(_selected_uid)
	match _active_tab:
		"Jobs":       _build_jobs_tab(content, reg)
		"Abilities":  _build_abilities_tab(content, reg)
		"Equipment":  _build_equipment_tab(content, reg)
		_:            _build_status_tab(content, reg)

	# Right panel: context-aware sidebar
	main.add_child(_build_right_sidebar(_active_tab, reg))


func _build_left_panel(uid: String) -> Control:
	var panel := _panel_box(C_PANEL_DEEP, C_GOLD, 1, 12)
	panel.custom_minimum_size = Vector2(280, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(_padded(inner, 16, 16))

	var stats := _stats_for(uid)
	var reg   := _get_reg(uid)

	# Portrait in circular frame
	var port_outer := _panel_box(C_PANEL, C_GOLD, 2, 100)
	port_outer.custom_minimum_size = Vector2(248, 220)
	inner.add_child(port_outer)
	var portrait := TextureRect.new()
	portrait.texture = _unit_texture(uid)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(200, 200)
	port_outer.add_child(_padded(portrait, 12, 10))

	# Name and level
	var unit_name := _label(reg.get("display_name", uid.capitalize()), 32, C_GOLD_BRIGHT, true, HORIZONTAL_ALIGNMENT_CENTER)
	inner.add_child(unit_name)

	var lv_str := "Lv. %d" % int(stats.get("level", 1))
	inner.add_child(_label(lv_str, 20, C_SUBTEXT, false, HORIZONTAL_ALIGNMENT_CENTER))

	# Current job
	var job_id: String = reg.get("current_job_id", "squire")
	var job_def := JobTreeData.get_job(job_id)
	var job_jp_dict: Dictionary = reg.get("job_jp", {})
	var job_level := JobTreeData._jp_to_level(int(job_jp_dict.get(job_id, 0)))
	var job_chip := _panel_box(C_GOLD_DIM.darkened(0.6), C_GOLD_DIM, 1, 6)
	job_chip.custom_minimum_size.y = 36
	var job_text := _label("%s (Lv.%d)" % [job_def.get("name", "Squire"), job_level], 18, C_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
	job_chip.add_child(_padded(job_text, 8, 4))
	inner.add_child(job_chip)

	inner.add_child(_gold_separator())

	# Stat bars
	inner.add_child(_bar_line("HP",     int(stats.get("hp", 1)),          int(stats.get("hp", 1)),          C_HP))
	inner.add_child(_bar_line("TEMPER", int(stats.get("max_temper", 80)), int(stats.get("max_temper", 80)), C_TEMPER))
	inner.add_child(_bar_line("ETHER",  int(stats.get("max_ether", 100)), int(stats.get("max_ether", 100)), C_ETHER))
	inner.add_child(_bar_line("CT",     100, 100, C_CT))

	# Stat chips
	var chips := VBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	inner.add_child(chips)
	chips.add_child(_mini_chip("BRAVERY %d" % int(stats.get("bravery", 70)), C_CT))
	chips.add_child(_mini_chip("FAITH %d"   % int(stats.get("faith", 70)),   C_ETHER))
	chips.add_child(_mini_chip("JP %d"      % int(reg.get("jp", 0)),         C_GOLD_DIM))

	# Spacer to push content up
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(spacer)

	return panel


func _build_right_sidebar(tab: String, reg: Dictionary) -> Control:
	var panel := _panel_box(C_PANEL, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 1, 12)
	panel.custom_minimum_size = Vector2(280, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(_padded(inner, 16, 16))

	var stats := _stats_for(_selected_uid)
	var job_id: String = reg.get("current_job_id", "squire")
	var job_def := JobTreeData.get_job(job_id)

	match tab:
		"Status":
			_build_sidebar_status(inner, stats, job_def, reg)
		"Jobs":
			_build_sidebar_jobs(inner, job_def)
		"Abilities":
			_build_sidebar_abilities(inner, reg)
		"Equipment":
			_build_sidebar_equipment(inner, reg)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(spacer)

	return panel


func _build_sidebar_status(parent: VBoxContainer, stats: Dictionary, job_def: Dictionary, _reg: Dictionary) -> void:
	parent.add_child(_section_lbl("CALLING"))
	parent.add_child(_label(job_def.get("name", ""), 24, C_GOLD_BRIGHT, true))
	parent.add_child(_wrapped(job_def.get("description", ""), 16, C_SUBTEXT))

	parent.add_child(_gold_separator())
	parent.add_child(_section_lbl("ATTRIBUTES"))

	# Display attributes in 2 columns
	var attr_order: Array[String] = ["physical", "magic", "bravery", "faith", "speed", "move"]
	for i in range(0, attr_order.size(), 2):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		parent.add_child(row)
		for j in range(2):
			if i + j < attr_order.size():
				var key: String = attr_order[i + j]
				var display_name: String = ATTR_NAMES.get(key, key.capitalize()) as String
				var value := int(stats.get(key, 0))
				var col := VBoxContainer.new()
				col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				col.add_theme_constant_override("separation", 2)
				row.add_child(col)
				col.add_child(_label(display_name, 14, C_SUBTEXT, false))
				col.add_child(_label(str(value), 20, C_TEXT, false, HORIZONTAL_ALIGNMENT_RIGHT))


func _build_sidebar_jobs(parent: VBoxContainer, job_def: Dictionary) -> void:
	parent.add_child(_section_lbl("JOB DETAILS"))
	parent.add_child(_label(job_def.get("name", ""), 24, C_GOLD_BRIGHT, true))
	parent.add_child(_wrapped(job_def.get("description", ""), 16, C_SUBTEXT))

	if job_def.get("flavour", "") != "":
		parent.add_child(_gold_separator())
		parent.add_child(_wrapped(job_def.get("flavour", ""), 14, Color(0.54, 0.52, 0.46)))


func _build_sidebar_abilities(parent: VBoxContainer, _reg: Dictionary) -> void:
	parent.add_child(_section_lbl("ABILITY INFO"))
	if _selected_ability == "":
		parent.add_child(_wrapped("Select an ability to view details.", 18, C_SUBTEXT))
	else:
		var ab := AbilityDB.get_ability(_selected_ability)
		parent.add_child(_label(ab.get("display_name", _selected_ability), 24, C_GOLD_BRIGHT, true))
		parent.add_child(_wrapped(ab.get("description", ""), 16, C_SUBTEXT))

		var costs := HBoxContainer.new()
		costs.add_theme_constant_override("separation", 8)
		parent.add_child(_gold_separator())
		parent.add_child(_label("COSTS", 16, C_SUBTEXT, false))
		parent.add_child(costs)

		var jp_cost := int(ab.get("jp_cost", 0))
		costs.add_child(_mini_chip("JP %d" % jp_cost, C_GOLD_DIM))

		var mp_cost := int(ab.get("mp_cost", 0))
		if mp_cost > 0:
			costs.add_child(_mini_chip("MP %d" % mp_cost, C_TEMPER))

		var rng := int(ab.get("range", 0))
		costs.add_child(_mini_chip("%s%d" % ["Range " if rng > 0 else "Self", rng], C_CT))


func _build_sidebar_equipment(parent: VBoxContainer, _reg: Dictionary) -> void:
	parent.add_child(_section_lbl("EQUIPMENT"))
	parent.add_child(_wrapped("Item stats will be available once loot is integrated.", 16, C_SUBTEXT))


func _build_tab_bar() -> void:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size.y = 48
	bar.add_theme_constant_override("separation", 24)
	_root.add_child(bar)

	for tab in TABS:
		var active := tab == _active_tab
		var btn := Button.new()
		btn.text = tab.to_upper()
		btn.custom_minimum_size.y = 48
		btn.add_theme_font_override("font", DISPLAY_FONT)
		btn.add_theme_font_size_override("font_size", 22)
		var col := C_GOLD_BRIGHT if active else C_SUBTEXT
		btn.add_theme_color_override("font_color", col)

		# Simple background-less style with bottom border for active
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0, 0, 0, 0)
		st.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			st.set_border_width(s, 0)
		if active:
			st.border_color = C_GOLD_BRIGHT
			st.set_border_width(SIDE_BOTTOM, 3)
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", st)
		btn.add_theme_stylebox_override("pressed", st)

		btn.pressed.connect(_set_tab.bind(tab))
		bar.add_child(btn)

	# Spacer fills the rest
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(sp)


# ── Tab content ───────────────────────────────────────────────────────────────

func _build_status_tab(parent: VBoxContainer, reg: Dictionary) -> void:
	var job_id: String  = reg.get("current_job_id", "squire")
	var job_def := JobTreeData.get_job(job_id)
	parent.add_child(_section_lbl("CURRENT CALLING"))

	var calling_row := HBoxContainer.new()
	calling_row.add_theme_constant_override("separation", 18)
	parent.add_child(calling_row)
	_add_insignia(calling_row, job_id, Vector2(64, 64))
	var calling_info := VBoxContainer.new()
	calling_info.add_theme_constant_override("separation", 4)
	calling_row.add_child(calling_info)
	calling_info.add_child(_label(job_def.get("name", job_id.capitalize()), 32, C_GOLD_BRIGHT, true))
	calling_info.add_child(_wrapped(job_def.get("description", ""), 22, C_SUBTEXT))
	if job_def.get("flavour", "") != "":
		var flav := _wrapped(job_def.get("flavour", ""), 20, Color(0.54, 0.52, 0.46))
		flav.add_theme_color_override("font_color", Color(0.54, 0.52, 0.46))
		calling_info.add_child(flav)

	parent.add_child(_gold_separator())
	parent.add_child(_section_lbl("EQUIPPED ABILITIES"))
	var eq: Array = reg.get("equipped_abilities", [])
	if eq.is_empty():
		parent.add_child(_wrapped("No ability set selected — battle will use all known abilities.", 24, C_SUBTEXT))
	else:
		var table := _ability_table_header()
		parent.add_child(table)
		for i in range(eq.size()):
			var ab_id := str(eq[i])
			var ab := AbilityDB.get_ability(ab_id)
			parent.add_child(_ability_table_row(i + 1, ab_id, ab, false, false))

	parent.add_child(_gold_separator())
	parent.add_child(_section_lbl("MASTERY BONUS"))
	var mastery: Dictionary = job_def.get("mastery_bonus", {})
	parent.add_child(_wrapped(mastery.get("description", "Master this job to unlock a permanent bonus."), 24, Color(0.82, 0.78, 0.58)))


func _build_jobs_tab(parent: VBoxContainer, reg: Dictionary) -> void:
	var job_jp: Dictionary = reg.get("job_jp", {})
	var current_job: String = reg.get("current_job_id", "squire")

	parent.add_child(_wrapped("Choose a calling to change this unit's command pool. Advance by earning JP in battle.", 26, C_SUBTEXT))

	for tier in [1, 2, 3]:
		var tier_label: String = str(["BASIC CALLINGS", "ADVANCED CALLINGS", "ASCENDED CALLINGS"][tier - 1])
		parent.add_child(_gold_separator())
		parent.add_child(_section_lbl(tier_label))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		parent.add_child(grid)
		for job_id in JobTreeData.get_jobs_by_tier(tier):
			grid.add_child(_job_card(job_id, current_job, job_jp))


func _build_abilities_tab(parent: VBoxContainer, reg: Dictionary) -> void:
	# Equipped strip
	parent.add_child(_section_lbl("EQUIPPED"))
	var eq: Array = reg.get("equipped_abilities", [])
	var eq_row := HBoxContainer.new()
	eq_row.add_theme_constant_override("separation", 12)
	parent.add_child(eq_row)
	for i in range(4):
		var ab_name := "Empty"
		if i < eq.size():
			var ab := AbilityDB.get_ability(str(eq[i]))
			ab_name = ab.get("display_name", str(eq[i]))
		var chip_col := C_GOLD_DIM if i < eq.size() else Color(0.30, 0.28, 0.26)
		eq_row.add_child(_mini_chip("%d. %s" % [i + 1, ab_name], chip_col))

	parent.add_child(_gold_separator())
	parent.add_child(_section_lbl("KNOWN ABILITIES"))
	parent.add_child(_ability_table_header())

	var known := _known_abilities(reg)
	var idx   := 0
	for ab_id in known:
		idx += 1
		var ab         := AbilityDB.get_ability(ab_id)
		var is_equipped := ab_id in eq
		parent.add_child(_ability_table_row(idx, ab_id, ab, is_equipped, true))

	parent.add_child(_gold_separator())
	parent.add_child(_section_lbl("LEARNABLE"))
	var any_learnable := false
	for ab_id: String in reg.get("learnable_abilities", []):
		if _gs and _gs.knows_ability(_selected_uid, ab_id):
			continue
		any_learnable = true
		idx += 1
		var ab := AbilityDB.get_ability(ab_id)
		parent.add_child(_ability_table_row(idx, ab_id, ab, false, false, true))
	if not any_learnable:
		parent.add_child(_wrapped("No unlearned abilities in this job pool.", 24, C_SUBTEXT))


func _build_equipment_tab(parent: VBoxContainer, reg: Dictionary) -> void:
	var equipment: Dictionary = reg.get("equipment", {})

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	parent.add_child(columns)

	# Equipment slots column
	var eq_col := VBoxContainer.new()
	eq_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq_col.add_theme_constant_override("separation", 10)
	columns.add_child(eq_col)
	eq_col.add_child(_section_lbl("EQUIPMENT"))
	for slot in ["main_hand", "off_hand", "head", "body", "accessory"]:
		eq_col.add_child(_equip_slot_row(SLOT_LABELS.get(slot, slot), equipment.get(slot, "Empty")))

	# Ability slots column
	var ab_col := VBoxContainer.new()
	ab_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ab_col.add_theme_constant_override("separation", 10)
	columns.add_child(ab_col)
	ab_col.add_child(_section_lbl("ABILITY SET"))
	var eq_ab: Array = reg.get("equipped_abilities", [])
	var ab_slots := ["COMMAND", "REACTION", "SUPPORT", "MOVEMENT"]
	for i in range(4):
		var ab_name := "Empty"
		if i < eq_ab.size():
			var ab := AbilityDB.get_ability(str(eq_ab[i]))
			ab_name = ab.get("display_name", str(eq_ab[i]))
		ab_col.add_child(_equip_slot_row(ab_slots[i], ab_name))

	parent.add_child(_gold_separator())
	parent.add_child(_wrapped("Equipment slots are staged for the demo — item stats from loot drops will populate these in the full build.", 24, C_SUBTEXT))


# ── Roster strip ──────────────────────────────────────────────────────────────

func _build_roster_strip() -> void:
	var strip := HBoxContainer.new()
	strip.custom_minimum_size.y = 132
	strip.add_theme_constant_override("separation", 16)
	_root.add_child(strip)
	for uid in UNIT_IDS:
		strip.add_child(_roster_card(uid))


func _roster_card(uid: String) -> Button:
	var reg   := _get_reg(uid)
	var stats: Dictionary = BASE_STATS.get(uid, {})
	var active := uid == _selected_uid

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 120)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = ""
	btn.pressed.connect(_select_unit.bind(uid))

	var st := StyleBoxFlat.new()
	st.bg_color    = C_PANEL if active else C_PANEL_DEEP
	st.border_color = C_GOLD_BRIGHT if active else Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.24)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(s, 2 if active else 1)
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 10)
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover",  st)
	btn.add_theme_stylebox_override("pressed",st)

	var inner := HBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 12)
	btn.add_child(_padded(inner, 14, 10))

	var img := TextureRect.new()
	img.texture = _unit_texture(uid)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.custom_minimum_size = Vector2(72, 90)
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(img)

	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_constant_override("separation", 4)
	inner.add_child(info)
	info.add_child(_label("Lv.%d  %s" % [int(stats.get("level", 1)), reg.get("display_name", uid.capitalize())], 26, C_GOLD_BRIGHT if active else C_TEXT, true))
	var job_def := JobTreeData.get_job(reg.get("current_job_id", "squire"))
	info.add_child(_label(job_def.get("name", "Squire"), 20, C_SUBTEXT, false))

	# HP/Temper mini bars
	for entry: Array in [["HP", C_HP], ["TEMPER", C_TEMPER]]:
		var brow := HBoxContainer.new()
		brow.add_theme_constant_override("separation", 6)
		brow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lbl := _label(str(entry[0]), 14, C_SUBTEXT, false)
		lbl.custom_minimum_size.x = 52
		brow.add_child(lbl)
		var bar := ProgressBar.new()
		bar.max_value = 100
		bar.value = 100
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(100, 8)
		var fill := StyleBoxFlat.new()
		fill.bg_color = entry[1] as Color
		fill.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("fill", fill)
		brow.add_child(bar)
		info.add_child(brow)
	return btn


# ── Footer ────────────────────────────────────────────────────────────────────

func _build_footer() -> void:
	var foot := HBoxContainer.new()
	foot.custom_minimum_size.y = 60
	foot.add_theme_constant_override("separation", 20)
	_root.add_child(foot)

	_hint_label = _label("Q / E  cycle unit     1–4  switch tab     Esc  back to hub", 24, C_SUBTEXT, false)
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_hint_label)

	var back := _action_button("Back to Hub", C_SUBTEXT)
	back.custom_minimum_size = Vector2(240, 54)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/HubScene.tscn"))
	foot.add_child(back)

	var next := _action_button("Select Stage", C_GOLD)
	next.custom_minimum_size = Vector2(260, 54)
	next.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/StageSelect.tscn"))
	foot.add_child(next)


# ── Widget builders ───────────────────────────────────────────────────────────

func _job_card(job_id: String, current_job: String, job_jp: Dictionary) -> Control:
	var job_def   := JobTreeData.get_job(job_id)
	var jp        := int(job_jp.get(job_id, 0))
	var level     := JobTreeData._jp_to_level(jp)
	var can_change:= JobTreeData.meets_prerequisites(job_id, job_jp)
	var is_current := job_id == current_job

	var card := _panel_box(
		C_PANEL if can_change else C_PANEL_DEEP,
		C_GOLD_BRIGHT if is_current else (C_GOLD_DIM if can_change else Color(0.3, 0.28, 0.32, 0.5)),
		2 if is_current else 1,
		10
	)
	card.custom_minimum_size = Vector2(0, 200)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	card.add_child(_padded(inner, 16, 14))

	# Insignia + name row
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	inner.add_child(top_row)
	_add_insignia(top_row, job_id, Vector2(44, 44))
	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.add_theme_constant_override("separation", 2)
	top_row.add_child(name_col)
	name_col.add_child(_label(job_def.get("name", job_id.capitalize()), 26, C_GOLD_BRIGHT if (is_current or can_change) else C_SUBTEXT, true))
	var jp_label := _label("Lv.%d   %d JP" % [level, jp], 18, C_CT if can_change else C_SUBTEXT, false)
	name_col.add_child(jp_label)

	inner.add_child(_wrapped(job_def.get("description", ""), 18, C_SUBTEXT if can_change else Color(0.40, 0.38, 0.36)))

	var btn_text := "Current" if is_current else ("Change" if can_change else "Locked")
	var btn_col  := C_GOLD if is_current else (C_GOLD_BRIGHT if can_change else C_SUBTEXT)
	var btn := _action_button(btn_text, btn_col)
	btn.disabled = is_current or not can_change
	btn.pressed.connect(_on_change_job.bind(job_id))
	inner.add_child(btn)
	return card


func _ability_table_header() -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 36
	row.add_theme_constant_override("separation", 0)

	# Ability column: leave 58px gap on left for icon
	var ability_lbl := _label("ABILITY", 15, C_SUBTEXT, true)
	ability_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_padded(ability_lbl, 58, 4))

	var temper_lbl := _label("TEMPER", 15, C_TEMPER, true, HORIZONTAL_ALIGNMENT_CENTER)
	temper_lbl.custom_minimum_size.x = 100
	row.add_child(_padded(temper_lbl, 4, 4))

	var ether_lbl := _label("ETHER", 15, C_ETHER, true, HORIZONTAL_ALIGNMENT_CENTER)
	ether_lbl.custom_minimum_size.x = 100
	row.add_child(_padded(ether_lbl, 4, 4))

	var range_lbl := _label("RANGE", 15, C_SUBTEXT, true, HORIZONTAL_ALIGNMENT_CENTER)
	range_lbl.custom_minimum_size.x = 80
	row.add_child(_padded(range_lbl, 4, 4))

	var jp_lbl := _label("JP", 15, C_SUBTEXT, true, HORIZONTAL_ALIGNMENT_CENTER)
	jp_lbl.custom_minimum_size.x = 120
	row.add_child(_padded(jp_lbl, 4, 4))

	var state_space := Control.new()
	state_space.custom_minimum_size.x = 52
	row.add_child(state_space)

	return row


func _ability_table_row(_idx: int, ab_id: String, ab: Dictionary, is_equipped: bool, with_equip: bool, learnable: bool = false) -> Control:
	var spell_type := str(ab.get("spell_type", "physical"))
	var mp_cost    := int(ab.get("mp_cost", 0))
	var rng        := int(ab.get("range", 0))
	var jp_cost    := int(ab.get("jp_cost", 0))

	# Physical abilities consume Temper; everything else consumes Ether
	var is_physical  := spell_type == "physical"
	var temper_cost  := mp_cost if is_physical else 0
	var ether_cost   := 0 if is_physical else mp_cost

	# Three visual states from the mockup
	var is_locked   := learnable
	var is_selected := is_equipped and with_equip
	var dim         := 0.40 if is_locked else 1.0

	# Row panel
	var row := PanelContainer.new()
	row.custom_minimum_size.y = 62

	var bg := StyleBoxFlat.new()
	if is_selected:
		bg.bg_color    = Color(0.10, 0.08, 0.04, 0.98)
		bg.border_color = C_GOLD_BRIGHT
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			bg.set_border_width(s, 2)
	elif is_locked:
		bg.bg_color    = C_PANEL_DEEP
		bg.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08)
		bg.set_border_width(SIDE_BOTTOM, 1)
	else:
		bg.bg_color    = Color(C_PANEL.r, C_PANEL.g, C_PANEL.b, 0.70)
		bg.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.14)
		bg.set_border_width(SIDE_BOTTOM, 1)
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		bg.set_corner_radius(c, 6)
	row.add_theme_stylebox_override("panel", bg)

	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 0)
	inner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_padded(inner, 8, 8))

	# ── Ability icon ──────────────────────────────────────────────────────────
	var icon_path: String = ABILITY_ICONS.get(spell_type, "res://assets/ui/insignias/soldier.svg")
	var icon_border := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25 if is_locked else 0.65)
	var icon_frame := _panel_box(C_PANEL_DEEP, icon_border, 1, 6)
	icon_frame.custom_minimum_size = Vector2(46, 46)
	var icon_tex := TextureRect.new()
	icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_tex.custom_minimum_size = Vector2(30, 30)
	if ResourceLoader.exists(icon_path):
		icon_tex.texture = load(icon_path)
	icon_tex.modulate = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40 if is_locked else 0.88)
	icon_frame.add_child(_padded(icon_tex, 7, 7))
	inner.add_child(icon_frame)

	# ── Ability name ──────────────────────────────────────────────────────────
	var name_color := C_SUBTEXT if is_locked else (C_GOLD_BRIGHT if is_selected else C_TEXT)
	var name_lbl   := _label(ab.get("display_name", ab_id), 21, name_color, false)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(_padded(name_lbl, 10, 0))

	# ── Temper ────────────────────────────────────────────────────────────────
	var t_str := str(temper_cost) if temper_cost > 0 else "—"
	var t_col := Color(C_TEMPER.r, C_TEMPER.g, C_TEMPER.b, dim if temper_cost > 0 else 0.25)
	var t_lbl := _label(t_str, 20, t_col, false, HORIZONTAL_ALIGNMENT_CENTER)
	t_lbl.custom_minimum_size.x = 100
	inner.add_child(t_lbl)

	# ── Ether ─────────────────────────────────────────────────────────────────
	var e_str := str(ether_cost) if ether_cost > 0 else "—"
	var e_col := Color(C_ETHER.r, C_ETHER.g, C_ETHER.b, dim if ether_cost > 0 else 0.25)
	var e_lbl := _label(e_str, 20, e_col, false, HORIZONTAL_ALIGNMENT_CENTER)
	e_lbl.custom_minimum_size.x = 100
	inner.add_child(e_lbl)

	# ── Range ─────────────────────────────────────────────────────────────────
	var rng_str := str(rng) if rng > 0 else "Self"
	var rng_lbl := _label(rng_str, 20, Color(C_TEXT.r, C_TEXT.g, C_TEXT.b, dim), false, HORIZONTAL_ALIGNMENT_CENTER)
	rng_lbl.custom_minimum_size.x = 80
	inner.add_child(rng_lbl)

	# ── JP column / action button ─────────────────────────────────────────────
	if learnable:
		var reg      := _get_reg(_selected_uid)
		var have_jp  := int(reg.get("jp", 0))
		var can_learn := have_jp >= jp_cost
		var btn := _action_button("Learn  %d JP" % jp_cost, C_GOLD if can_learn else C_SUBTEXT)
		btn.disabled = not can_learn
		btn.custom_minimum_size.x = 120
		btn.pressed.connect(_on_learn.bind(ab_id))
		inner.add_child(_padded(btn, 4, 0))
	elif with_equip:
		var btn_text := "Remove" if is_equipped else "Equip"
		var btn := _action_button(btn_text, C_HP if is_equipped else C_LEARNED)
		btn.custom_minimum_size.x = 120
		btn.pressed.connect(_toggle_equipped.bind(ab_id))
		inner.add_child(_padded(btn, 4, 0))
	else:
		var jp_display := _label(str(jp_cost) if jp_cost > 0 else "—", 20, Color(C_ETHER.r, C_ETHER.g, C_ETHER.b, dim * 0.8), false, HORIZONTAL_ALIGNMENT_CENTER)
		jp_display.custom_minimum_size.x = 120
		inner.add_child(jp_display)

	# ── State indicator ───────────────────────────────────────────────────────
	var state_lbl := _label("", 20, C_SUBTEXT, false, HORIZONTAL_ALIGNMENT_CENTER)
	state_lbl.custom_minimum_size.x = 52
	if is_locked:
		state_lbl.text = "🔒"  # 🔒 lock
		state_lbl.add_theme_color_override("font_color", C_SUBTEXT.darkened(0.2))
	else:
		state_lbl.text = "✓"  # ✓ checkmark
		var check_col := C_GOLD_BRIGHT if is_selected else C_LEARNED
		state_lbl.add_theme_color_override("font_color", check_col)
	inner.add_child(state_lbl)

	return row


func _equip_slot_row(slot_type: String, item_name: String) -> Control:
	var row := _panel_box(C_PANEL_DEEP, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20), 1, 8)
	row.custom_minimum_size.y = 64
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 16)
	row.add_child(_padded(inner, 16, 10))

	var type_lbl := _label(slot_type, 18, C_SUBTEXT, true)
	type_lbl.custom_minimum_size.x = 140
	inner.add_child(type_lbl)

	var sep := VSeparator.new()
	sep.add_theme_color_override("color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22))
	inner.add_child(sep)

	var empty := item_name == "Empty"
	var item_lbl := _label(item_name, 24, C_TEXT if not empty else C_SUBTEXT, false)
	item_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(item_lbl)

	return row


func _add_insignia(parent: Control, job_id: String, sz: Vector2) -> void:
	var path: String = JOB_INSIGNIAS.get(job_id, "")
	var img := TextureRect.new()
	img.custom_minimum_size = sz
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if path != "" and ResourceLoader.exists(path):
		img.texture = load(path)
	img.modulate = C_GOLD
	parent.add_child(img)


func _bar_line(lbl_text: String, value: int, maximum: int, color: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl := _label(lbl_text, 22, C_SUBTEXT, true)
	lbl.custom_minimum_size.x = 80
	row.add_child(lbl)
	var bar := ProgressBar.new()
	bar.max_value  = maximum
	bar.value      = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 22)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.1, 0.08, 0.12, 0.9)
	track.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", track)
	row.add_child(bar)
	row.add_child(_label("%d/%d" % [value, maximum], 22, Color(0.88, 0.86, 0.80), false, HORIZONTAL_ALIGNMENT_RIGHT))
	return row


func _cstat_row(label: String, value: int) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 34
	var l := _label(label, 18, C_SUBTEXT, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(_label(str(value), 22, C_TEXT, false, HORIZONTAL_ALIGNMENT_RIGHT))
	return row


func _mini_chip(text: String, color: Color) -> Control:
	var p := _panel_box(color.darkened(0.78), color, 1, 6)
	p.custom_minimum_size.y = 30
	p.add_child(_padded(_label(text, 18, color.lightened(0.18), false, HORIZONTAL_ALIGNMENT_CENTER), 10, 4))
	return p


func _gold_separator() -> Control:
	var sep := HSeparator.new()
	sep.custom_minimum_size.y = 4
	sep.add_theme_color_override("color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28))
	return sep


func _section_lbl(text: String) -> Label:
	var l := _label(text, 22, C_GOLD_DIM, true)
	l.add_theme_constant_override("outline_size", 1)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	return l


# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_change_job(job_id: String) -> void:
	if not _gs:
		return
	if _gs.has_method("set_current_job"):
		_gs.set_current_job(_selected_uid, job_id)
	else:
		_gs.unit_registry[_selected_uid]["current_job_id"] = job_id
	_refresh_all()


func _on_learn(ab_id: String) -> void:
	if _gs and _gs.learn_ability(_selected_uid, ab_id):
		var reg: Dictionary = _gs.unit_registry[_selected_uid]
		var equipped: Array = reg.get("equipped_abilities", [])
		if equipped.size() < 4:
			equipped.append(ab_id)
			reg["equipped_abilities"] = equipped
		_gs.save()
		_refresh_all()


func _toggle_equipped(ab_id: String) -> void:
	if not _gs:
		return
	var reg: Dictionary = _gs.unit_registry[_selected_uid]
	var equipped: Array = reg.get("equipped_abilities", []).duplicate()
	if ab_id in equipped:
		equipped.erase(ab_id)
	elif equipped.size() < 4:
		equipped.append(ab_id)
	else:
		equipped[3] = ab_id
	if _gs.has_method("set_equipped_abilities"):
		_gs.set_equipped_abilities(_selected_uid, equipped)
	else:
		reg["equipped_abilities"] = equipped
	_refresh_all()


func _select_unit(uid: String) -> void:
	_selected_uid = uid
	_refresh_all()


func _select_adjacent_unit(delta: int) -> void:
	var idx := UNIT_IDS.find(_selected_uid)
	if idx < 0:
		idx = 0
	_select_unit(UNIT_IDS[wrapi(idx + delta, 0, UNIT_IDS.size())])


func _set_tab(tab: String) -> void:
	_active_tab = tab
	_refresh_all()


func _refresh_all() -> void:
	_build_ui()


# ── Data helpers ──────────────────────────────────────────────────────────────

func _known_abilities(reg: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for ab: Variant in reg.get("base_abilities", []):
		if str(ab) not in result: result.append(str(ab))
	for ab: Variant in reg.get("learned_abilities", []):
		if str(ab) not in result: result.append(str(ab))
	return result


func _stats_for(uid: String) -> Dictionary:
	var base: Dictionary = BASE_STATS.get(uid, {}).duplicate()
	var reg  := _get_reg(uid)
	var bonuses := JobTreeData.compute_stat_bonuses(reg.get("job_jp", {}))
	base["hp"]       = int(base.get("hp", 1))       + int(bonuses.get("max_hp", 0))
	base["mp"]       = int(base.get("mp", 1))        + int(bonuses.get("max_ether", 0))
	base["max_temper"]= int(base.get("max_temper", 80))+ int(bonuses.get("max_temper", 0))
	base["max_ether"] = int(base.get("max_ether", 100))+ int(bonuses.get("max_ether", 0))
	base["physical"] = int(base.get("physical", 0)) + int(bonuses.get("physical", 0))
	base["magic"]    = int(base.get("magic", 0))    + int(bonuses.get("magic", 0))
	base["speed"]    = int(base.get("speed", 0))    + int(bonuses.get("speed", 0))
	return base


func _get_reg(uid: String) -> Dictionary:
	if _gs and _gs.unit_registry.has(uid):
		return _gs.unit_registry[uid]
	return {
		"display_name": uid.capitalize(), "jp": 0,
		"base_abilities": [], "learned_abilities": [], "equipped_abilities": [],
		"current_job_id": "squire", "job_jp": {"squire": 0}, "equipment": {},
		"learnable_abilities": [],
	}


func _unit_texture(uid: String) -> Texture2D:
	var path: String = PORTRAITS.get(uid, "")
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null


# ── Primitive helpers ─────────────────────────────────────────────────────────

func _label(text: String, font_px: int, color: Color, display_font: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_px)
	l.add_theme_color_override("font_color", color)
	if display_font:
		l.add_theme_font_override("font", DISPLAY_FONT)
	return l


func _wrapped(text: String, font_px: int, color: Color) -> Label:
	var l := _label(text, font_px, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _action_button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", DISPLAY_FONT)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", color)
	var st := StyleBoxFlat.new()
	st.bg_color    = Color(color.r * 0.12, color.g * 0.10, color.b * 0.08, 0.96)
	st.border_color = color.darkened(0.05)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(s, 1)
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]: st.set_corner_radius(c, 6)
	st.content_margin_left  = 14
	st.content_margin_right = 14
	st.content_margin_top   = 6
	st.content_margin_bottom= 6
	var hover := st.duplicate() as StyleBoxFlat
	hover.bg_color = Color(color.r * 0.20, color.g * 0.17, color.b * 0.13, 0.98)
	hover.border_color = color.lightened(0.08)
	b.add_theme_stylebox_override("normal",  st)
	b.add_theme_stylebox_override("hover",   hover)
	b.add_theme_stylebox_override("pressed", hover)
	return b


func _panel_box(bg: Color, border: Color, border_w: int, radius: int) -> PanelContainer:
	var p  := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color    = bg
	st.border_color = border
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(s, border_w)
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]: st.set_corner_radius(c, radius)
	p.add_theme_stylebox_override("panel", st)
	return p


func _padded(node: Control, x: int, y: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",   x)
	m.add_theme_constant_override("margin_right",  x)
	m.add_theme_constant_override("margin_top",    y)
	m.add_theme_constant_override("margin_bottom", y)
	m.add_child(node)
	return m


func _add_stone_floor(parent: Control) -> void:
	var tex: Texture2D = load("res://assets/ui/tiles/stone.png")
	if not tex:
		return
	var grid := Control.new()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(grid)
	for y in range(0, 2160, 96):
		for x in range(0, 3840, 96):
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.position = Vector2(x, y)
			s.modulate = Color(0.45, 0.45, 0.45, 0.40)
			grid.add_child(s)
