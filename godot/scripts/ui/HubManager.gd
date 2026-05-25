## HubManager.gd
## "The Last Hearth"  between-run upgrade hub.
## Currency spend, permanent upgrades, Guardian boon unlocks, heat, secret skills.

class_name HubManager
extends Control

const BG         := Color(0.04, 0.05, 0.08)
const FG         := Color(0.97, 0.94, 0.87)
const DIM        := Color(0.45, 0.42, 0.38)
const GOLD       := Color(0.79, 0.65, 0.34)
const ACCENT     := Color(0.48, 0.86, 1.0)
const RED        := Color(0.93, 0.27, 0.27)

const GUARDIAN_COLORS := {
	"ignareth":  Color(1.0, 0.57, 0.20),
	"nerevan":   Color(0.22, 0.74, 1.0),
	"torvahk":   Color(1.0, 0.92, 0.27),
	"luminarch":  Color(1.0, 0.96, 0.60),
	"vaelthorn": Color(0.66, 0.33, 0.97),
}

var _meta:    Node
var _run_mgr: Node
var _msg_lbl: Label
var _cur_row: HBoxContainer
var _root:    VBoxContainer


func _ready() -> void:
	_meta    = get_node_or_null("/root/MetaProgression")
	_run_mgr = get_node_or_null("/root/RunManager")
	_build_ui()


func _build_ui() -> void:
	for c in get_children(): c.queue_free()

	# Background
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Scroll container so content never clips
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	_root = VBoxContainer.new()
	_root.custom_minimum_size = Vector2(1180, 0)
	_root.add_theme_constant_override("separation", 0)
	_root.add_theme_constant_override("margin_top", 0)
	scroll.add_child(_root)

	#  Header
	var hdr := _panel_solid(Color(0.07, 0.08, 0.11), Vector2(0, 82))
	var hh  := HBoxContainer.new()
	hh.add_theme_constant_override("margin_left", 32)
	hh.add_theme_constant_override("margin_right", 24)
	hh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hh.alignment = BoxContainer.ALIGNMENT_CENTER
	hdr.add_child(hh)

	var title_col := VBoxContainer.new()
	hh.add_child(title_col)
	_lbl(title_col, "THE LAST HEARTH", 11, DIM)
	_lbl(title_col, "Eidolon Chronicles", 26, GOLD)

	var stretch := Control.new()
	stretch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(stretch)

	# Currency row in header
	_cur_row = HBoxContainer.new()
	_cur_row.add_theme_constant_override("separation", 6)
	hh.add_child(_cur_row)
	_rebuild_currencies()

	# Message bar
	var msg_bar := _panel_solid(Color(0.06, 0.07, 0.10), Vector2(0, 34))
	_msg_lbl = Label.new()
	_msg_lbl.add_theme_font_size_override("font_size", 12)
	_msg_lbl.add_theme_color_override("font_color", Color(0.55, 0.92, 0.72))
	_msg_lbl.add_theme_constant_override("margin_left", 32)
	_msg_lbl.set_anchors_and_offsets_preset(Control.PRESET_VCENTER_WIDE)
	msg_bar.add_child(_msg_lbl)

	_space(16)

	#  Main grid
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.add_theme_constant_override("margin_left", 28)
	grid.add_theme_constant_override("margin_right", 28)
	_root.add_child(grid)

	# Body Training
	grid.add_child(_upgrade_panel(
		"Body Training", "Permanent power applied to every run.",
		Color(0.53, 0.94, 0.67),
		[
			_stat_row("max_hp",   "Max HP",        "+15 HP to all units per tier.",    Currency.SOUL_SHARDS, 20),
			_stat_row("physical", "Physical Power", "+2 physical per tier.",            Currency.SOUL_SHARDS, 25),
			_stat_row("magic",    "Magic Power",    "+2 magic per tier.",               Currency.SOUL_SHARDS, 25),
		]
	))

	# Heat Altar
	grid.add_child(_upgrade_panel(
		"Heat Altar", "Optional difficulty  higher heat, better rewards.",
		Color(1.0, 0.57, 0.20),
		[
			_flag_row("guardian-heat-1", "Unlock Heat I",   "Enemies gain HP. +12% reward multiplier.",
				{Currency.SOUL_SHARDS:30}),
			_flag_row("guardian-heat-2", "Unlock Heat II",  "More elite spawns. +24% rewards.",
				{Currency.SOUL_SHARDS:55, Currency.BOSS_TOKENS:1}),
			_flag_row("guardian-heat-3", "Unlock Heat III", "Champion-tier enemies appear earlier.",
				{Currency.SOUL_SHARDS:90, Currency.BOSS_TOKENS:2, Currency.OBSIDIAN:15}),
		]
	))

	# Guardian Shrine  one upgrade per Guardian
	grid.add_child(_guardian_panel())

	# Job Reliquary
	grid.add_child(_upgrade_panel(
		"Job Reliquary", "Spend rare materials to open deeper job routes.",
		Color(0.66, 0.33, 0.97),
		[
			_flag_row("advanced-jobs-unlocked", "Advanced Jobs",
				"Specialist-tier jobs become available.",
				{Currency.OBSIDIAN:10, Currency.BOSS_TOKENS:1}),
			_flag_row("ascended-jobs-unlocked", "Ascended Jobs",
				"Master-tier ascension paths open.",
				{Currency.OBSIDIAN:25, Currency.BOSS_TOKENS:3}),
			_flag_row("secret-skill-slots",     "Secret Skill Slots",
				"Each character can learn one secret technique.",
				{Currency.OBSIDIAN:20, Currency.GLYPHS:10}),
		]
	))

	_space(20)

	#  Hub characters
	_root.add_child(_build_dialogue_panel())
	_space(16)

	#  Bottom nav
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 12)
	nav.add_theme_constant_override("margin_left", 28)
	_root.add_child(nav)

	var desc_btn := _nav_btn("  Begin Descent", GOLD, 200, 52)
	desc_btn.pressed.connect(_start_descent)
	nav.add_child(desc_btn)

	var jobs_btn := _nav_btn("Manage Jobs", ACCENT, 150, 52)
	jobs_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/CharacterScreen.tscn"))
	nav.add_child(jobs_btn)

	var inn_btn := _nav_btn("The Inn", Color(0.831, 0.686, 0.275), 130, 44)
	inn_btn.pressed.connect(_open_inn)
	nav.add_child(inn_btn)

	var inv_btn := _nav_btn("Inventory", Color(0.22, 0.74, 1.0), 130, 44)
	inv_btn.pressed.connect(_open_inventory)
	nav.add_child(inv_btn)

	var codex_btn := _nav_btn("Codex", Color(0.66, 0.33, 0.97), 110, 44)
	codex_btn.pressed.connect(_open_codex)
	nav.add_child(codex_btn)

	var stage_btn := _nav_btn("Run Map (Debug)", DIM, 150, 40)
	stage_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/StageSelect.tscn"))
	nav.add_child(stage_btn)

	_space(32)


#  Panel builders

func _upgrade_panel(title: String, desc: String, accent: Color,
		rows: Array[Dictionary]) -> PanelContainer:
	var pc   := PanelContainer.new()
	pc.custom_minimum_size = Vector2(560, 190)
	_border_style(pc, accent)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_theme_constant_override("margin_left", 18)
	box.add_theme_constant_override("margin_right", 18)
	box.add_theme_constant_override("margin_top", 16)
	box.add_theme_constant_override("margin_bottom", 16)
	pc.add_child(box)

	_lbl(box, title, 18, accent)
	_lbl(box, desc, 11, DIM)
	_space_in(box, 6)

	for row in rows:
		box.add_child(_purchase_row(row, accent))
	return pc


func _guardian_panel() -> PanelContainer:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(560, 190)
	_border_style(pc, GOLD)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_theme_constant_override("margin_left", 18)
	box.add_theme_constant_override("margin_right", 18)
	box.add_theme_constant_override("margin_top", 16)
	box.add_theme_constant_override("margin_bottom", 16)
	pc.add_child(box)

	_lbl(box, "Guardian Shrine", 18, GOLD)
	_lbl(box, "Unlock stronger boons for each Primal Guardian.", 11, DIM)
	_space_in(box, 6)

	var guardians := [
		{"id":"guardian-ignareth-rank-1", "name":"Ignareth's Deeper Flame",
		 "desc":"Adds Legendary fire boons to pool.", "guardian":"ignareth",
		 "cost":{Currency.GLYPHS:8, "phoenix-sigils":5}},
		{"id":"guardian-nerevan-rank-1",  "name":"Nerevan's Tide Memory",
		 "desc":"Adds Legendary water boons to pool.", "guardian":"nerevan",
		 "cost":{Currency.GLYPHS:8, "phoenix-sigils":5}},
		{"id":"guardian-torvahk-rank-1",  "name":"Torvahk's Storm Pattern",
		 "desc":"Adds Legendary thunder boons to pool.", "guardian":"torvahk",
		 "cost":{Currency.GLYPHS:8, "titan-sigils":5}},
		{"id":"guardian-luminarch-rank-1","name":"Luminarch's Sacred Memory",
		 "desc":"Adds Legendary holy boons to pool.", "guardian":"luminarch",
		 "cost":{Currency.GLYPHS:8, "titan-sigils":5}},
		{"id":"guardian-vaelthorn-rank-1","name":"Vaelthorn's Echo Fragment",
		 "desc":"Adds Legendary dark boons to pool.", "guardian":"vaelthorn",
		 "cost":{Currency.GLYPHS:10, Currency.BOSS_TOKENS:1}},
	]

	# 2-column mini-grid for Guardians
	var gg := GridContainer.new()
	gg.columns = 2
	gg.add_theme_constant_override("h_separation", 8)
	gg.add_theme_constant_override("v_separation", 5)
	box.add_child(gg)

	for g in guardians:
		var row_def := _flag_row(g["id"], g["name"], g["desc"], g["cost"])
		var col: Color = GUARDIAN_COLORS.get(g.get("guardian",""), GOLD)
		gg.add_child(_purchase_row(row_def, col))

	return pc


func _purchase_row(row: Dictionary, accent: Color) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size.y = 32
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 12)

	var already  := false
	var can_buy  := false
	var level    := 0

	if row.get("type","") == "stat":
		level   = _meta.get_upgrade(row["stat_id"]) if _meta else 0
		can_buy = _meta != null and _meta.can_spend(row["cost"])
		var cost_str := _fmt_cost(row["cost"])
		btn.text        = "%-28s  Lv%d    %s" % [row["label"], level, cost_str]
		btn.tooltip_text = row["desc"]
		btn.pressed.connect(func() -> void: _buy_stat(row["stat_id"], row["cost"]))
	else:
		already  = _meta != null and _meta.has_unlock(row["flag_id"])
		can_buy  = not already and _meta != null and _meta.can_spend(row["cost"])
		var cost_str := _fmt_cost(row["cost"])
		var prefix := "  " if already else "   "
		btn.text         = "%s%-28s    %s" % [prefix, row["label"], cost_str]
		btn.tooltip_text = row["desc"]
		btn.disabled     = already
		if not already:
			btn.pressed.connect(func() -> void: _buy_flag(row["flag_id"], row["cost"]))

	# Colour feedback
	var col := accent if can_buy and not already else (Color(0.35, 0.7, 0.35) if already else DIM.darkened(0.2))
	btn.add_theme_color_override("font_color", col)
	_simple_style(btn, Color(0.08, 0.09, 0.12))
	hbox.add_child(btn)
	return hbox


#  Row def helpers

func _stat_row(stat_id: String, label: String, desc: String,
		currency: String, base_cost: int) -> Dictionary:
	# Cost scales with current level
	var level: int = _meta.get_upgrade(stat_id) if _meta else 0
	var cost := int(base_cost * pow(1.6, level))
	return {"type":"stat", "stat_id":stat_id, "label":label, "desc":desc, "cost":{currency:cost}}

func _flag_row(flag_id: String, label: String, desc: String,
		cost: Dictionary) -> Dictionary:
	return {"type":"flag", "flag_id":flag_id, "label":label, "desc":desc, "cost":cost}


#  Actions

func _build_dialogue_panel() -> PanelContainer:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.06, 0.07, 0.10)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side,1)
	st.border_color = Color(1,1,1,0.07)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 12)
	pc.add_theme_stylebox_override("panel", st)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("margin_left", 16)
	hbox.add_theme_constant_override("margin_right", 16)
	hbox.add_theme_constant_override("margin_top", 12)
	hbox.add_theme_constant_override("margin_bottom", 12)
	hbox.add_theme_constant_override("separation", 16)
	pc.add_child(hbox)

	var gs: Node = get_node_or_null("/root/GameState")
	var lines := HubDialogue.get_all_lines(gs)

	for line_data: Dictionary in lines:
		var bubble := VBoxContainer.new()
		bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bubble.add_theme_constant_override("separation", 4)
		hbox.add_child(bubble)

		# Name + portrait
		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 6)
		bubble.add_child(name_row)
		var portrait := Label.new()
		portrait.text = line_data.get("portrait","?")
		portrait.add_theme_font_size_override("font_size", 18)
		name_row.add_child(portrait)
		var name_col := VBoxContainer.new()
		name_row.add_child(name_col)
		var nlbl := Label.new()
		nlbl.text = line_data.get("name","?")
		nlbl.add_theme_font_size_override("font_size", 12)
		nlbl.add_theme_color_override("font_color", line_data.get("color", GOLD))
		name_col.add_child(nlbl)
		var tlbl := Label.new()
		tlbl.text = line_data.get("title","")
		tlbl.add_theme_font_size_override("font_size", 9)
		tlbl.add_theme_color_override("font_color", DIM)
		name_col.add_child(tlbl)

		# Dialogue line
		var dlbl := RichTextLabel.new()
		dlbl.bbcode_enabled = false
		dlbl.text = line_data.get("line","...")
		dlbl.add_theme_font_size_override("normal_font_size", 12)
		dlbl.add_theme_color_override("default_color", Color(0.88,0.85,0.80))
		dlbl.custom_minimum_size = Vector2(0, 52)
		dlbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bubble.add_child(dlbl)

	# Fallback if no lines
	if lines.is_empty():
		var fl := Label.new()
		fl.text = "The Hearth is quiet."
		fl.add_theme_font_size_override("font_size", 13)
		fl.add_theme_color_override("font_color", DIM)
		hbox.add_child(fl)

	return pc


func _buy_stat(stat_id: String, cost: Dictionary) -> void:
	if not _meta or not _meta.spend(cost):
		_show_msg("Not enough currency.", RED); return
	_meta.add_upgrade(stat_id, 1); _meta.save()
	_show_msg("Upgraded: %s." % stat_id.replace("_"," ").capitalize())
	_rebuild_currencies()
	_build_ui()   # Rebuild to update scaling costs

func _buy_flag(flag_id: String, cost: Dictionary) -> void:
	if not _meta: return
	if _meta.has_unlock(flag_id): _show_msg("Already unlocked.", DIM); return
	if not _meta.spend(cost): _show_msg("Not enough currency.", RED); return
	_meta.add_unlock(flag_id)
	# Heat level unlocks update max heat
	if flag_id.begins_with("guardian-heat-"):
		var level := int(flag_id.trim_prefix("guardian-heat-"))
		if level > _meta.max_heat_unlocked:
			_meta.max_heat_unlocked = level
			_meta.selected_heat_level = level
	_meta.save()
	_show_msg("Unlocked: %s." % flag_id.replace("-"," ").capitalize())
	_rebuild_currencies()
	_build_ui()

func _start_descent() -> void:
	if _run_mgr:
		_run_mgr.start_new_run(_meta.selected_heat_level if _meta else 0)
	get_tree().change_scene_to_file("res://scenes/StageSelect.tscn")


func _open_inn() -> void:
	var inn := preload("res://scripts/ui/InnScreen.gd").new()
	inn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inn.back_pressed.connect(func() -> void: inn.queue_free())
	get_tree().current_scene.add_child(inn)


func _open_inventory() -> void:
	var inv := preload("res://scripts/ui/InventoryScreen.gd").new()
	inv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inv.back_pressed.connect(func() -> void: inv.queue_free())
	get_tree().current_scene.add_child(inv)


func _open_codex() -> void:
	var cdx := preload("res://scripts/ui/CodexScreen.gd").new()
	cdx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cdx.back_pressed.connect(func() -> void: cdx.queue_free())
	get_tree().current_scene.add_child(cdx)


#  Currency display

func _rebuild_currencies() -> void:
	for c in _cur_row.get_children(): c.queue_free()
	if not _meta: return
	var currencies := [Currency.SOUL_SHARDS, Currency.OBSIDIAN,
		Currency.GLYPHS, Currency.BOSS_TOKENS, "phoenix-sigils", "titan-sigils"]
	for cid in currencies:
		var amount: int = int(_meta.get_currency(cid))
		if amount == 0 and cid in ["phoenix-sigils","titan-sigils"]: continue
		var chip := _currency_chip(Currency.display_name(cid), amount)
		_cur_row.add_child(chip)
		var gap := Control.new(); gap.custom_minimum_size = Vector2(6, 0); _cur_row.add_child(gap)

func _currency_chip(currency_name: String, amount: int) -> PanelContainer:
	var pc  := PanelContainer.new()
	var st  := StyleBoxFlat.new()
	st.bg_color      = Color(0.12, 0.13, 0.17)
	st.border_color  = GOLD.lerp(Color.TRANSPARENT, 0.5)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 6)
	st.content_margin_left = 8; st.content_margin_right = 8
	st.content_margin_top  = 3; st.content_margin_bottom = 3
	pc.add_theme_stylebox_override("panel", st)
	var lbl := Label.new()
	lbl.text = "%s: %d" % [currency_name, amount]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", GOLD if amount > 0 else DIM)
	pc.add_child(lbl)
	return pc


#  Widget helpers

func _lbl(parent: Control, text: String, font_size: int, color: Color,
		centered: bool = false) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if centered: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l); return l

func _space(h: int = 8) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(0, h); _root.add_child(s)

func _space_in(parent: Control, h: int) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(0, h); parent.add_child(s)

func _panel_solid(color: Color, min_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var pc := PanelContainer.new()
	if min_size != Vector2.ZERO: pc.custom_minimum_size = min_size
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new(); st.bg_color = color
	pc.add_theme_stylebox_override("panel", st); _root.add_child(pc); return pc

func _border_style(pc: PanelContainer, accent: Color) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color    = Color(0.06, 0.07, 0.10)
	st.border_color = accent.lerp(Color.TRANSPARENT, 0.5)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 12)
	pc.add_theme_stylebox_override("panel", st)

func _simple_style(btn: Button, color: Color) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color = color
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 6)
	btn.add_theme_stylebox_override("normal", st)
	var hover := st.duplicate(); hover.bg_color = color.lightened(0.07)
	btn.add_theme_stylebox_override("hover", hover)

func _nav_btn(text: String, color: Color, min_w: int, min_h: int) -> Button:
	var btn := Button.new(); btn.text = text
	btn.custom_minimum_size = Vector2(min_w, min_h)
	var st := StyleBoxFlat.new()
	st.bg_color     = color.darkened(0.55)
	st.border_color = color.lerp(Color.TRANSPARENT, 0.3)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 10)
	btn.add_theme_stylebox_override("normal", st); btn.add_theme_stylebox_override("hover", st)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 14); return btn

func _fmt_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for cid: String in cost.keys():
		parts.append("%d %s" % [int(cost[cid]), Currency.display_name(cid)])
	return ", ".join(parts)

func _show_msg(text: String, color: Color = Color(0.55, 0.92, 0.72)) -> void:
	if _msg_lbl:
		_msg_lbl.text = text
		_msg_lbl.add_theme_color_override("font_color", color)
