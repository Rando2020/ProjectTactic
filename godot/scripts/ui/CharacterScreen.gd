class_name CharacterScreen
extends Control

const DISPLAY_FONT := preload("res://assets/fonts/TrajanPro-Regular.ttf")
const UNIT_IDS: Array[String] = ["zane", "mira", "kael", "lyra"]
const TABS: Array[String] = ["Status", "Jobs", "Abilities", "Equipment"]
const PORTRAITS := {
	"zane": ["res://assets/sprites/units/zane-idle-isometric.png"],
	"mira": ["res://assets/sprites/units/mira-idle-isometric.png"],
	"kael": ["res://assets/sprites/units/kael-idle-isometric.png"],
	"lyra": ["res://assets/sprites/units/lyra-idle-isometric.png"],
}
const BASE_STATS := {
	"zane": {"level": 11, "hp": 320, "mp": 90, "move": 4, "jump": 2, "speed": 8, "physical": 42, "magic": 48, "bravery": 80, "faith": 70},
	"mira": {"level": 10, "hp": 280, "mp": 120, "move": 4, "jump": 2, "speed": 7, "physical": 28, "magic": 54, "bravery": 65, "faith": 84},
	"kael": {"level": 12, "hp": 380, "mp": 55, "move": 4, "jump": 2, "speed": 6, "physical": 55, "magic": 32, "bravery": 92, "faith": 54},
	"lyra": {"level": 10, "hp": 240, "mp": 70, "move": 4, "jump": 2, "speed": 9, "physical": 52, "magic": 18, "bravery": 72, "faith": 60},
}
const SLOT_LABELS := {
	"main_hand": "Main Hand",
	"off_hand": "Off Hand",
	"head": "Head",
	"body": "Body",
	"accessory": "Accessory",
}

var _gs: Node
var _selected_uid: String = "zane"
var _active_tab: String = "Status"
var _root: Control
var _roster_grid: GridContainer
var _detail_panel: VBoxContainer
var _tab_row: HBoxContainer
var _hint_label: Label


func _ready() -> void:
	_gs = get_node_or_null("/root/GameState")
	if _gs and not _gs.unit_registry.has(_selected_uid) and not _gs.unit_registry.is_empty():
		_selected_uid = str(_gs.unit_registry.keys()[0])
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q:
				_select_adjacent_unit(-1)
				get_viewport().set_input_as_handled()
			KEY_E:
				_select_adjacent_unit(1)
				get_viewport().set_input_as_handled()
			KEY_1:
				_set_tab("Status")
			KEY_2:
				_set_tab("Jobs")
			KEY_3:
				_set_tab("Abilities")
			KEY_4:
				_set_tab("Equipment")
			KEY_ESCAPE:
				get_tree().change_scene_to_file("res://scenes/HubScene.tscn")


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0.025, 0.026, 0.030)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_add_stone_floor(bg)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.34)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 76)
	margin.add_theme_constant_override("margin_right", 76)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 46)
	add_child(margin)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 24)
	margin.add_child(_root)

	_build_top_bar()

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 34)
	_root.add_child(content)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(1840, 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 18)
	content.add_child(left)

	var right_panel := _panel(Color(0.05, 0.055, 0.07, 0.92), Color(0.72, 0.62, 0.42, 0.45), 18)
	right_panel.custom_minimum_size = Vector2(1320, 0)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(right_panel)
	_detail_panel = VBoxContainer.new()
	_detail_panel.add_theme_constant_override("separation", 16)
	right_panel.add_child(_padded(_detail_panel, 28, 24))

	_build_roster(left)
	_build_footer()
	_refresh_details()


func _build_top_bar() -> void:
	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 88
	_root.add_child(top)

	var crumb := _label("Units > Status > %s" % _active_tab, 42, Color(0.91, 0.84, 0.66), true)
	crumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(crumb)

	var meta := VBoxContainer.new()
	meta.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(meta)
	meta.add_child(_label("Gold", 22, Color(0.60, 0.56, 0.48), true, HORIZONTAL_ALIGNMENT_RIGHT))
	meta.add_child(_label("%d" % (_gs.gold if _gs else 0), 38, Color(1.0, 0.86, 0.34), true, HORIZONTAL_ALIGNMENT_RIGHT))


func _build_roster(parent: VBoxContainer) -> void:
	var selected := _get_reg(_selected_uid)
	var hero := HBoxContainer.new()
	hero.custom_minimum_size.y = 390
	hero.add_theme_constant_override("separation", 30)
	parent.add_child(hero)

	var portrait_panel := _panel(Color(0.06, 0.065, 0.08, 0.95), Color(0.95, 0.83, 0.48, 0.62), 12)
	portrait_panel.custom_minimum_size = Vector2(310, 330)
	hero.add_child(portrait_panel)
	var portrait := TextureRect.new()
	portrait.texture = _unit_texture(_selected_uid)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(280, 305)
	portrait_panel.add_child(portrait)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 12)
	hero.add_child(info)
	var name_row := HBoxContainer.new()
	info.add_child(name_row)
	var unit_name := _label(selected.get("display_name", _selected_uid), 64, Color(1.0, 0.96, 0.82), true)
	unit_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(unit_name)
	var stats := _stats_for(_selected_uid)
	name_row.add_child(_label("Lv.%d   EXP 0" % int(stats.get("level", 1)), 34, Color(0.86, 0.88, 0.93), true, HORIZONTAL_ALIGNMENT_RIGHT))
	info.add_child(_job_line(_selected_uid))
	info.add_child(_bar_line("HP", int(stats.get("hp", 1)), int(stats.get("hp", 1)), Color(0.48, 0.92, 0.16)))
	info.add_child(_bar_line("MP", int(stats.get("mp", 1)), int(stats.get("mp", 1)), Color(0.92, 0.50, 0.38)))
	info.add_child(_bar_line("CT", 100, 100, Color(0.95, 0.72, 0.12)))
	var brave_faith := HBoxContainer.new()
	brave_faith.add_theme_constant_override("separation", 28)
	brave_faith.add_child(_chip("Bravery %d" % int(stats.get("bravery", 70)), Color(0.72, 0.82, 0.92)))
	brave_faith.add_child(_chip("Faith %d" % int(stats.get("faith", 70)), Color(0.72, 0.82, 0.92)))
	brave_faith.add_child(_chip("JP %d" % int(selected.get("jp", 0)), Color(0.55, 0.92, 1.0)))
	info.add_child(brave_faith)

	var unit_stat_row := HBoxContainer.new()
	unit_stat_row.add_theme_constant_override("separation", 20)
	info.add_child(unit_stat_row)
	for key in ["move", "jump", "speed", "physical", "magic"]:
		unit_stat_row.add_child(_small_stat(key.capitalize(), int(stats.get(key, 0))))

	var roster_panel := _panel(Color(0.035, 0.038, 0.045, 0.75), Color(0.2, 0.2, 0.22, 0.35), 12)
	roster_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(roster_panel)
	var roster_box := VBoxContainer.new()
	roster_box.add_theme_constant_override("separation", 16)
	roster_panel.add_child(_padded(roster_box, 18, 16))
	roster_box.add_child(_section("ROSTER"))
	_roster_grid = GridContainer.new()
	_roster_grid.columns = 4
	_roster_grid.add_theme_constant_override("h_separation", 26)
	_roster_grid.add_theme_constant_override("v_separation", 28)
	_roster_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roster_box.add_child(_roster_grid)
	for uid in UNIT_IDS:
		_roster_grid.add_child(_unit_roster_button(uid))


func _build_footer() -> void:
	var foot := HBoxContainer.new()
	foot.custom_minimum_size.y = 70
	foot.add_theme_constant_override("separation", 24)
	_root.add_child(foot)
	_hint_label = _label("Q/E change unit    1-4 switch panel    Enter confirms buttons    Esc returns", 28, Color(0.76, 0.73, 0.66), false)
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_hint_label)
	var back := _button("Back to Hub", Color(0.78, 0.74, 0.68))
	back.custom_minimum_size = Vector2(260, 58)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/HubScene.tscn"))
	foot.add_child(back)
	var next := _button("Select Stage", Color(1.0, 0.82, 0.36))
	next.custom_minimum_size = Vector2(280, 58)
	next.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/StageSelect.tscn"))
	foot.add_child(next)


func _refresh_details() -> void:
	for child in _detail_panel.get_children():
		child.queue_free()
	var reg := _get_reg(_selected_uid)
	_build_tabs()
	_detail_panel.add_child(_label(reg.get("display_name", _selected_uid), 52, Color(1.0, 0.96, 0.82), true))
	match _active_tab:
		"Jobs": _build_jobs_tab(reg)
		"Abilities": _build_abilities_tab(reg)
		"Equipment": _build_equipment_tab(reg)
		_: _build_status_tab(reg)


func _build_tabs() -> void:
	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 8)
	_detail_panel.add_child(_tab_row)
	for tab in TABS:
		var b := _button(tab, Color(0.90, 0.84, 0.68) if tab == _active_tab else Color(0.58, 0.57, 0.54))
		b.toggle_mode = true
		b.button_pressed = tab == _active_tab
		b.custom_minimum_size = Vector2(230, 54)
		b.pressed.connect(_set_tab.bind(tab))
		_tab_row.add_child(b)


func _build_status_tab(reg: Dictionary) -> void:
	var job_id: String = reg.get("current_job_id", "squire")
	var job := JobTreeData.get_job(job_id)
	_detail_panel.add_child(_section("STATUS"))
	_detail_panel.add_child(_rich_line("Current Job", job.get("name", job_id.capitalize()), Color(1.0, 0.85, 0.38)))
	_detail_panel.add_child(_wrapped(job.get("description", "No job description."), 30, Color(0.82, 0.80, 0.74)))
	var stats := _stats_for(_selected_uid)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	_detail_panel.add_child(grid)
	for entry in [["HP", "hp"], ["MP", "mp"], ["Move", "move"], ["Jump", "jump"], ["Speed", "speed"], ["Physical", "physical"], ["Magic", "magic"], ["JP", "jp"]]:
		var label := str(entry[0])
		var key := str(entry[1])
		var value := int(reg.get("jp", 0)) if key == "jp" else int(stats.get(key, 0))
		grid.add_child(_stat_tile(label, value))
	_detail_panel.add_child(_section("EQUIPPED COMBAT SET"))
	var eq: Array = reg.get("equipped_abilities", [])
	if eq.is_empty():
		_detail_panel.add_child(_wrapped("No abilities equipped. The battle will use all known abilities until a set is chosen.", 26, Color(0.74, 0.73, 0.70)))
	else:
		for ab_id: String in eq:
			var ab := AbilityDB.get_ability(ab_id)
			_detail_panel.add_child(_ability_summary(ab_id, ab, false))


func _build_jobs_tab(reg: Dictionary) -> void:
	_detail_panel.add_child(_section("JOBS"))
	_detail_panel.add_child(_wrapped("Choose a job to change this unit's command pool. Advanced jobs unlock as job levels rise.", 28, Color(0.78, 0.76, 0.70)))
	var job_jp: Dictionary = reg.get("job_jp", {})
	var current_job: String = reg.get("current_job_id", "squire")
	for tier in [1, 2, 3]:
		_detail_panel.add_child(_section(["BASIC", "ADVANCED", "ASCENDED"][tier - 1]))
		var row := GridContainer.new()
		row.columns = 3
		row.add_theme_constant_override("h_separation", 14)
		row.add_theme_constant_override("v_separation", 14)
		_detail_panel.add_child(row)
		for job_id in JobTreeData.get_jobs_by_tier(tier):
			row.add_child(_job_card(job_id, current_job, job_jp))


func _build_abilities_tab(reg: Dictionary) -> void:
	_detail_panel.add_child(_section("ABILITIES"))
	_detail_panel.add_child(_wrapped("Learn with JP, then equip up to four abilities for battle.", 28, Color(0.78, 0.76, 0.70)))
	_detail_panel.add_child(_section("EQUIPPED"))
	var equipped: Array = reg.get("equipped_abilities", [])
	var equipped_row := HBoxContainer.new()
	equipped_row.add_theme_constant_override("separation", 10)
	_detail_panel.add_child(equipped_row)
	for i in range(4):
		var text := "Empty"
		if i < equipped.size():
			var ab := AbilityDB.get_ability(str(equipped[i]))
			text = ab.get("display_name", str(equipped[i]))
		equipped_row.add_child(_chip("%d. %s" % [i + 1, text], Color(0.58, 0.84, 1.0)))
	_detail_panel.add_child(_section("KNOWN"))
	var known := _known_abilities(reg)
	for ab_id in known:
		var ab := AbilityDB.get_ability(ab_id)
		_detail_panel.add_child(_ability_summary(ab_id, ab, true))
	_detail_panel.add_child(_section("LEARNABLE"))
	var any_learnable := false
	for ab_id: String in reg.get("learnable_abilities", []):
		if _gs and _gs.knows_ability(_selected_uid, ab_id):
			continue
		any_learnable = true
		var ab := AbilityDB.get_ability(ab_id)
		_detail_panel.add_child(_learn_row(ab_id, ab))
	if not any_learnable:
		_detail_panel.add_child(_wrapped("No unlearned abilities in this job pool.", 28, Color(0.68, 0.66, 0.62)))


func _build_equipment_tab(reg: Dictionary) -> void:
	_detail_panel.add_child(_section("EQUIPMENT"))
	_detail_panel.add_child(_wrapped("Equipment is staged for the demo: the screen saves a loadout shape now, and item stats can plug into these slots next.", 28, Color(0.78, 0.76, 0.70)))
	var equipment: Dictionary = reg.get("equipment", {})
	for slot in ["main_hand", "off_hand", "head", "body", "accessory"]:
		_detail_panel.add_child(_rich_line(SLOT_LABELS.get(slot, slot), equipment.get(slot, "Empty"), Color(0.94, 0.90, 0.76)))
	_detail_panel.add_child(_section("NEXT HOOK"))
	_detail_panel.add_child(_wrapped("Loot from runs should populate inventory, then this panel can assign weapon and armor bonuses to the battle stats.", 28, Color(0.74, 0.72, 0.66)))


func _unit_roster_button(uid: String) -> Button:
	var reg := _get_reg(uid)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(410, 310)
	btn.text = ""
	btn.pressed.connect(_select_unit.bind(uid))
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.055, 0.060, 0.070, 0.88)
	st.border_color = Color(1.0, 0.83, 0.34, 0.85) if uid == _selected_uid else Color(0.58, 0.52, 0.42, 0.35)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 2 if uid == _selected_uid else 1)
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]: st.set_corner_radius(c, 10)
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", st)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	btn.add_child(_padded(box, 10, 10))
	var image := TextureRect.new()
	image.texture = _unit_texture(uid)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(210, 170)
	box.add_child(image)
	box.add_child(_label("Lv.%d  %s" % [int(BASE_STATS.get(uid, {}).get("level", 1)), reg.get("display_name", uid)], 28, Color(1.0, 0.94, 0.78), true, HORIZONTAL_ALIGNMENT_CENTER))
	var job := JobTreeData.get_job(reg.get("current_job_id", "squire"))
	box.add_child(_label(job.get("name", "Squire"), 22, Color(0.74, 0.80, 0.90), true, HORIZONTAL_ALIGNMENT_CENTER))
	return btn


func _job_card(job_id: String, current_job: String, job_jp: Dictionary) -> Control:
	var job := JobTreeData.get_job(job_id)
	var can_change := JobTreeData.meets_prerequisites(job_id, job_jp)
	var is_current := job_id == current_job
	var jp := int(job_jp.get(job_id, 0))
	var level := JobTreeData._jp_to_level(jp)
	var card := _panel(Color(0.07, 0.075, 0.090, 0.95), Color(1.0, 0.82, 0.34, 0.75) if is_current else Color(0.5, 0.5, 0.5, 0.25), 8)
	card.custom_minimum_size = Vector2(390, 210)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(_padded(box, 16, 12))
	box.add_child(_label(("* " if is_current else "") + job.get("name", job_id.capitalize()), 30, Color(1.0, 0.92, 0.62) if can_change else Color(0.42, 0.40, 0.38), true))
	box.add_child(_label("Lv.%d   JP %d" % [level, jp], 22, Color(0.58, 0.84, 1.0) if can_change else Color(0.42, 0.42, 0.42), false))
	box.add_child(_wrapped(job.get("description", ""), 20, Color(0.76, 0.74, 0.68) if can_change else Color(0.42, 0.40, 0.38)))
	var b := _button("Current" if is_current else ("Change" if can_change else "Locked"), Color(1.0, 0.82, 0.34) if can_change else Color(0.40, 0.38, 0.34))
	b.disabled = is_current or not can_change
	b.pressed.connect(_on_change_job.bind(job_id))
	box.add_child(b)
	return card


func _ability_summary(ab_id: String, ab: Dictionary, with_equip_button: bool) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 74
	row.add_theme_constant_override("separation", 14)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(_label(ab.get("display_name", ab_id), 27, Color(0.92, 0.90, 0.82), true))
	info.add_child(_label("MP %d   Range %d   %s" % [int(ab.get("mp_cost", 0)), int(ab.get("range", 0)), str(ab.get("spell_type", "physical")).capitalize()], 20, Color(0.58, 0.64, 0.72), false))
	if with_equip_button:
		var equipped: Array = _get_reg(_selected_uid).get("equipped_abilities", [])
		var btn_text := "Remove" if ab_id in equipped else "Equip"
		var btn := _button(btn_text, Color(0.58, 0.84, 1.0))
		btn.custom_minimum_size = Vector2(150, 48)
		btn.pressed.connect(_toggle_equipped.bind(ab_id))
		row.add_child(btn)
	return row


func _learn_row(ab_id: String, ab: Dictionary) -> Control:
	var row := _ability_summary(ab_id, ab, false)
	var cost := int(ab.get("jp_cost", 999))
	var jp := int(_get_reg(_selected_uid).get("jp", 0))
	var btn := _button("Learn %d JP" % cost, Color(0.88, 0.80, 0.48) if jp >= cost else Color(0.40, 0.38, 0.34))
	btn.custom_minimum_size = Vector2(190, 48)
	btn.disabled = jp < cost
	btn.pressed.connect(_on_learn.bind(ab_id))	
	row.add_child(btn)
	return row


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
	idx = wrapi(idx + delta, 0, UNIT_IDS.size())
	_select_unit(UNIT_IDS[idx])


func _set_tab(tab: String) -> void:
	_active_tab = tab
	_refresh_all()


func _refresh_all() -> void:
	_build_ui()


func _known_abilities(reg: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for ab: Variant in reg.get("base_abilities", []):
		if str(ab) not in result:
			result.append(str(ab))
	for ab: Variant in reg.get("learned_abilities", []):
		if str(ab) not in result:
			result.append(str(ab))
	return result


func _stats_for(uid: String) -> Dictionary:
	var base: Dictionary = BASE_STATS.get(uid, {}).duplicate()
	var reg := _get_reg(uid)
	var bonuses := JobTreeData.compute_stat_bonuses(reg.get("job_jp", {}))
	base["hp"] = int(base.get("hp", 1)) + int(bonuses.get("max_hp", 0))
	base["mp"] = int(base.get("mp", 1)) + int(bonuses.get("max_ether", 0))
	base["physical"] = int(base.get("physical", 0)) + int(bonuses.get("physical", 0))
	base["magic"] = int(base.get("magic", 0)) + int(bonuses.get("magic", 0))
	base["speed"] = int(base.get("speed", 0)) + int(bonuses.get("speed", 0))
	return base


func _get_reg(uid: String) -> Dictionary:
	if _gs and _gs.unit_registry.has(uid):
		return _gs.unit_registry[uid]
	return {"display_name": uid.capitalize(), "jp": 0, "base_abilities": [], "learned_abilities": [], "equipped_abilities": [], "current_job_id": "squire", "job_jp": {"squire": 0}, "equipment": {}}


func _unit_texture(uid: String) -> Texture2D:
	var paths: Array = PORTRAITS.get(uid, [])
	for path: Variant in paths:
		var pth := str(path)
		if ResourceLoader.exists(pth):
			return load(pth)
	return null


func _job_line(uid: String) -> Control:
	var reg := _get_reg(uid)
	var job := JobTreeData.get_job(reg.get("current_job_id", "squire"))
	return _rich_line("Job", job.get("name", "Squire"), Color(1.0, 0.82, 0.36))


func _bar_line(label: String, value: int, maximum: int, color: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(_label(label, 30, Color(0.92, 0.90, 0.82), true))
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(560, 34)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	row.add_child(_label("%d/%d" % [value, maximum], 30, Color(1, 1, 1), true, HORIZONTAL_ALIGNMENT_RIGHT))
	return row


func _small_stat(label: String, value: int) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(150, 80)
	box.add_child(_label(label, 18, Color(0.58, 0.60, 0.66), true, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label(str(value), 34, Color(0.94, 0.92, 0.86), true, HORIZONTAL_ALIGNMENT_CENTER))
	return box


func _stat_tile(label: String, value: int) -> Control:
	var p := _panel(Color(0.07, 0.075, 0.09, 0.90), Color(0.45, 0.45, 0.48, 0.25), 8)
	p.custom_minimum_size = Vector2(390, 110)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	p.add_child(_padded(box, 16, 14))
	var l := _label(label, 26, Color(0.67, 0.66, 0.62), true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(l)
	box.add_child(_label(str(value), 34, Color(0.96, 0.92, 0.78), true, HORIZONTAL_ALIGNMENT_RIGHT))
	return p


func _rich_line(left: String, right: String, color: Color) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 52
	var l := _label(left, 26, Color(0.62, 0.62, 0.60), true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(_label(right, 30, color, true, HORIZONTAL_ALIGNMENT_RIGHT))
	return row


func _section(text: String) -> Label:
	var l := _label(text, 24, Color(0.68, 0.62, 0.48), true)
	l.add_theme_constant_override("outline_size", 1)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	return l


func _wrapped(text: String, size: int, color: Color) -> Label:
	var l := _label(text, size, color, false)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _chip(text: String, color: Color) -> Control:
	var p := _panel(color.darkened(0.72), color, 8)
	p.custom_minimum_size = Vector2(180, 46)
	var l := _label(text, 22, color.lightened(0.12), true, HORIZONTAL_ALIGNMENT_CENTER)
	p.add_child(_padded(l, 12, 6))
	return p


func _label(text: String, size: int, color: Color, display: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if display:
		l.add_theme_font_override("font", DISPLAY_FONT)
	return l


func _button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", DISPLAY_FONT)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", color)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.09, 0.085, 0.075, 0.92)
	st.border_color = color.darkened(0.1)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]: st.set_corner_radius(c, 8)
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", st)
	b.add_theme_stylebox_override("pressed", st)
	return b


func _panel(bg: Color, border: Color, radius: int) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]: st.set_corner_radius(c, radius)
	p.add_theme_stylebox_override("panel", st)
	return p


func _padded(node: Control, x: int, y: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", x)
	m.add_theme_constant_override("margin_right", x)
	m.add_theme_constant_override("margin_top", y)
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
			s.modulate = Color(0.55, 0.55, 0.55, 0.52)
			grid.add_child(s)