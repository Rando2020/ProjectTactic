## StageSelect.gd
## 30-floor Act 1 run map. Start Run -> choose routes -> fight through procedurally generated floors.

class_name StageSelect
extends Control

const BG   := Color(0.04, 0.05, 0.08)
const FG   := Color(0.97, 0.94, 0.87)
const DIM  := Color(0.45, 0.42, 0.38)
const GOLD := Color(0.79, 0.65, 0.34)
const TEAL := Color(0.25, 0.82, 0.72)

const SELL_VALUES: Dictionary = {
	"common":   15,
	"uncommon": 35,
	"rare":     80,
	"resonant": 200,
}

# Design-system fonts
const _FONT_DISPLAY := preload("res://assets/fonts/TrajanPro-Regular.ttf")
const _FONT_HEADER  := preload("res://assets/fonts/Cinzel-Bold.ttf")
const _FONT_BODY    := preload("res://assets/fonts/IMFellEnglish-Regular.ttf")
const _FONT_UI      := preload("res://assets/fonts/CormorantGaramond-Regular.ttf")

const PARTY_SCENE := preload("res://scenes/PartyScreen.tscn")

const NODE_META: Dictionary = {
	"battle":      {"icon":"B", "color":Color(0.48,0.86,1.0),  "label":"Battle"},
	"elite":       {"icon":"E", "color":Color(1.0,0.50,0.18),  "label":"Elite"},
	"mystery":     {"icon":"?", "color":Color(0.72,0.58,1.0),  "label":"?"},
	"mystery_cache": {"icon":"$", "color":Color(0.96,0.78,0.28),  "label":"Cache"},
	"mystery_training": {"icon":"JP", "color":Color(0.48,0.86,1.0),  "label":"Training"},
	"mystery_shrine": {"icon":"+", "color":Color(0.79,0.65,0.34),  "label":"Shrine"},
	"mystery_ambush": {"icon":"!", "color":Color(0.93,0.27,0.27),  "label":"Ambush"},
	"boss":        {"icon":"!", "color":Color(0.93,0.27,0.27), "label":"Boss"},
	"boon_pick":   {"icon":"+", "color":Color(0.79,0.65,0.34), "label":"Boon"},
	"wanderer":    {"icon":"?", "color":Color(0.53,0.94,0.67), "label":"Wanderer"},
	"town_1":      {"icon":"T1", "color":Color(0.53,0.94,0.67), "label":"Town 1"},
	"town_2":      {"icon":"T2", "color":Color(0.96,0.78,0.28), "label":"Town 2"},
	"town_3":      {"icon":"T3", "color":Color(0.72,0.58,1.0), "label":"Town 3"},
}

var _gs:  Node
var _bs:  BoonSystem
var _cs:  CurseSystem

var _boon_overlay:  Control = null
var _loot_overlay:  Control = null
var _selected_vow_id: String = VowSigilSystem.DEFAULT_VOW_ID
var _selected_sigil_id: String = VowSigilSystem.DEFAULT_SIGIL_ID


func _ready() -> void:
	_gs = get_node_or_null("/root/GameState")
	_bs = BoonSystem.new()
	_cs = CurseSystem.new()

	if _gs and _gs.pending_boon_offers.size() > 0:
		_build_ui(); _show_boon_pick(_gs.pending_boon_offers); return
	if _gs and _gs.pending_loot.size() > 0:
		_build_ui(); _show_loot(_gs.pending_loot); return
	_build_ui()


func _clean_ui_text(value: Variant, fallback: String = "") -> String:
	var text: String = str(value)
	for i in text.length():
		if text.unicode_at(i) > 127:
			return fallback
	return text

func _build_ui() -> void:
	for c in get_children(): c.queue_free()

	_bg(self)

	if not _gs or not _gs.active_run or _gs.active_run.completed:
		_build_start_screen()
	else:
		_build_run_screen(_gs.active_run)


#  Start screen

func _build_start_screen() -> void:
	var vbox := _vbox(self, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(460, 0)

	_lbl(vbox, "VAELTHAR / EIDOLON CHRONICLES", 12, DIM, true)
	_space(vbox, 8)
	_lbl(vbox, "The Roguelike Run", 34, FG, true)
	_space(vbox, 6)
	_lbl(vbox, "%d floors. Town checkpoints. Five Guardians." % RunState.TOTAL_FLOORS, 14, DIM, true)
	_space(vbox, 28)

	# Heat level selector
	var meta: Node = get_node_or_null("/root/MetaProgression")
	var heat := 0
	if meta: heat = meta.selected_heat_level
	var max_heat := 0
	if meta: max_heat = meta.max_heat_unlocked

	if max_heat > 0:
		var heat_row := HBoxContainer.new()
		heat_row.alignment = BoxContainer.ALIGNMENT_CENTER
		heat_row.add_theme_constant_override("separation", 10)
		vbox.add_child(heat_row)
		_lbl(heat_row, "Heat Level:", 13, DIM)
		var heat_lbl := _lbl(heat_row, str(heat), 16, Color(1.0,0.5,0.2))
		var less := _btn("-", DIM); less.custom_minimum_size = Vector2(36,36)
		less.pressed.connect(func() -> void:
			if meta: meta.selected_heat_level = maxi(0, meta.selected_heat_level - 1)
			heat_lbl.text = str(meta.selected_heat_level if meta else 0))
		var more := _btn("+", Color(1.0,0.5,0.2)); more.custom_minimum_size = Vector2(36,36)
		more.pressed.connect(func() -> void:
			if meta: meta.selected_heat_level = mini(meta.max_heat_unlocked, meta.selected_heat_level + 1)
			heat_lbl.text = str(meta.selected_heat_level if meta else 0))
		heat_row.add_child(less); heat_row.add_child(more)
		_space(vbox, 8)

	_build_loadout_picker(vbox)
	_space(vbox, 18)

	var btn := _btn(">  Start New Run", GOLD)
	btn.custom_minimum_size = Vector2(300, 52)
	btn.pressed.connect(func() -> void: _show_party_select(meta.selected_heat_level if meta else 0))
	vbox.add_child(btn)
	_space(vbox, 12)

	if _gs:
		_lbl(vbox, "Gold: %dg" % _gs.gold, 14, GOLD, true)

	# Show meta currencies
	if meta:
		_lbl(vbox, "Soul Shards: %d / Obsidian: %d" % [meta.get_currency(Currency.SOUL_SHARDS), meta.get_currency(Currency.OBSIDIAN)], 12, DIM, true)


#  Run screen

func _build_run_screen(run: RunState) -> void:
	var root := _vbox(self)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)

	# Header
	var hdr := _panel(root, Color(0.07,0.08,0.12), Vector2(0, 68))
	var hh  := _hbox(hdr)
	hh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hh.add_theme_constant_override("margin_left", 24)
	hh.add_theme_constant_override("margin_right", 16)
	_lbl(hh, "Floor %d / %d" % [run.current_floor, RunState.TOTAL_FLOORS], 22, FG)
	_stretch(hh)
	_lbl(hh, "Gold: %dg" % (_gs.gold if _gs else 0), 14, GOLD)
	_lbl(hh, "  Elites: %d" % run.elite_kills, 12, DIM)
	_lbl(hh, "  Boons: %d" % run.active_boons.size(), 12, DIM)
	_gap(hh, 12)
	# "Edit Formation" shortcut — always accessible so player isn't forced
	# to enter a battle node just to adjust positions.
	var formation_btn := _btn("⚔ Formation", Color(0.48, 0.72, 1.0))
	formation_btn.custom_minimum_size.x = 120
	formation_btn.pressed.connect(_on_edit_formation_from_run.bind(run))
	hh.add_child(formation_btn)
	_gap(hh, 8)

	var gear_btn := _btn("Gear", TEAL)
	gear_btn.custom_minimum_size.x = 90
	gear_btn.pressed.connect(_show_gear_panel)
	hh.add_child(gear_btn)
	_gap(hh, 8)

	var ab_btn := _btn("Abandon", Color(0.93,0.27,0.27))
	ab_btn.custom_minimum_size.x = 90
	ab_btn.pressed.connect(_on_abandon)
	hh.add_child(ab_btn)
	_gap(hh, 8)

	# Active boons row
	if run.active_boons.size() > 0:
		var bar := _panel(root, Color(0.05, 0.06, 0.09), Vector2(0, 50))
		var br  := _hbox(bar)
		br.add_theme_constant_override("margin_left", 24)
		br.add_theme_constant_override("margin_right", 16)
		br.set_anchors_and_offsets_preset(Control.PRESET_VCENTER_WIDE)
		br.add_theme_constant_override("separation", 6)
		var boons_title := Label.new()
		boons_title.text = "BLESSINGS"
		boons_title.add_theme_font_override("font", _FONT_HEADER)
		boons_title.add_theme_font_size_override("font_size", 9)
		boons_title.add_theme_color_override("font_color", GOLD.darkened(0.25))
		br.add_child(boons_title)
		_gap(br, 8)
		for boon in run.active_boons:
			var rd: Dictionary = BoonSystem.RARITIES.get(boon.get("rarity","common"), {})
			var bc: Color = rd.get("color", GOLD)
			_pill(br, "%s %s" % [str(boon.get("icon","+")), str(boon.get("name","?"))], bc)
		_stretch(br)
		var count_lbl := Label.new()
		count_lbl.text = "%d / ?" % run.active_boons.size()
		count_lbl.add_theme_font_size_override("font_size", 10)
		count_lbl.add_theme_color_override("font_color", DIM)
		br.add_child(count_lbl)

	_build_run_build_panel(root, run)
	_space(root, 18)

	# Group floor_plan by floor number, then render one column per floor.
	# Each column shows 1-3 branch cards stacked vertically.
	var map_wrapper := PanelContainer.new()
	map_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var map_bg_st := StyleBoxFlat.new()
	map_bg_st.bg_color = Color(0.03, 0.035, 0.055, 0.85)
	map_bg_st.border_color = Color(1.0, 1.0, 1.0, 0.05)
	map_bg_st.set_border_width_all(1)
	map_bg_st.content_margin_left = 0
	map_bg_st.content_margin_right = 0
	map_bg_st.content_margin_top = 8
	map_bg_st.content_margin_bottom = 8
	map_wrapper.add_theme_stylebox_override("panel", map_bg_st)
	root.add_child(map_wrapper)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 320
	map_wrapper.add_child(scroll)

	var hmap := HBoxContainer.new()
	hmap.add_theme_constant_override("margin_left",  20)
	hmap.add_theme_constant_override("margin_right", 20)
	hmap.add_theme_constant_override("separation",    8)
	scroll.add_child(hmap)

	var by_floor: Dictionary = {}
	for node in run.floor_plan:
		var f: int = int(node.get("floor", 1))
		if not by_floor.has(f):
			by_floor[f] = []
		by_floor[f].append(node)

	var available_nodes := run.get_available_nodes()

	for f in range(1, RunState.TOTAL_FLOORS + 1):
		var branches: Array = by_floor.get(f, [])
		if branches.is_empty():
			continue

		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		hmap.add_child(col)

		var is_past:    bool = f < run.current_floor
		var is_current: bool = f == run.current_floor
		var is_future:  bool = f > run.current_floor

		# Floor number label
		var floor_lbl := Label.new()
		floor_lbl.text = "F%d" % f
		floor_lbl.add_theme_font_override("font", _FONT_HEADER)
		floor_lbl.add_theme_font_size_override("font_size", 9)
		floor_lbl.add_theme_color_override("font_color",
			GOLD if is_current else (Color(0.4, 0.65, 0.4) if is_past else DIM.darkened(0.2)))
		floor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(floor_lbl)

		# "CHOOSE" badge above current floor
		if is_current and branches.size() > 1:
			var choose_pc := PanelContainer.new()
			var choose_st := StyleBoxFlat.new()
			choose_st.bg_color = GOLD.darkened(0.7)
			choose_st.border_color = GOLD
			choose_st.set_border_width_all(1)
			choose_st.set_corner_radius_all(4)
			choose_st.content_margin_left = 6
			choose_st.content_margin_right = 6
			choose_st.content_margin_top = 2
			choose_st.content_margin_bottom = 2
			choose_pc.add_theme_stylebox_override("panel", choose_st)
			var choose_lbl := Label.new()
			choose_lbl.text = "CHOOSE"
			choose_lbl.add_theme_font_override("font", _FONT_HEADER)
			choose_lbl.add_theme_font_size_override("font_size", 8)
			choose_lbl.add_theme_color_override("font_color", GOLD)
			choose_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			choose_pc.add_child(choose_lbl)
			col.add_child(choose_pc)

		# Branch cards
		for node in branches:
			var is_done:    bool = node.get("completed", false) == true
			var is_skipped: bool = node.get("skipped",   false) == true
			var is_live:    bool = is_current and not is_done and not is_skipped
			var ntype:      String = str(node.get("type", "battle"))
			var meta:       Dictionary = NODE_META.get(ntype, NODE_META["battle"])

			var card := _node_card(meta, is_live, is_done, is_future, is_skipped, node)

			# Modulate future floors down
			if is_future:
				card.modulate.a = 0.38
			elif is_past and not is_done:
				card.modulate.a = 0.25  # skipped branch on a past floor

			if is_live:
				card.pressed.connect(_on_enter_node.bind(node))

			col.add_child(card)

		if f < RunState.TOTAL_FLOORS:
			var connector := _build_floor_connector(is_current, is_past)
			hmap.add_child(connector)

	_space(root, 12)

	# Route hint when a choice is available
	_space(root, 6)
	if available_nodes.size() > 1:
		var hint_pc := PanelContainer.new()
		hint_pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hint_bg := StyleBoxFlat.new()
		hint_bg.bg_color = GOLD.darkened(0.82)
		hint_bg.border_color = GOLD.darkened(0.4)
		hint_bg.set_border_width_all(1)
		hint_bg.set_corner_radius_all(4)
		hint_bg.content_margin_top = 6
		hint_bg.content_margin_bottom = 6
		hint_pc.add_theme_stylebox_override("panel", hint_bg)
		root.add_child(hint_pc)
		var hint_lbl := Label.new()
		hint_lbl.text = "▲  Select your path — unchosen routes will close forever."
		hint_lbl.add_theme_font_override("font", _FONT_UI)
		hint_lbl.add_theme_font_size_override("font_size", 12)
		hint_lbl.add_theme_color_override("font_color", GOLD.lightened(0.1))
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_pc.add_child(hint_lbl)
	elif available_nodes.size() == 1:
		var single := available_nodes[0]
		var nm: Dictionary = NODE_META.get(single.get("type","battle"), NODE_META["battle"])
		var reward_text := _clean_ui_text(single.get("reward_hint", ""), "")
		var hint_lbl := Label.new()
		hint_lbl.text = "▶  %s%s" % [nm["label"], ("  —  " + reward_text if not reward_text.is_empty() else "")]
		hint_lbl.add_theme_font_override("font", _FONT_UI)
		hint_lbl.add_theme_font_size_override("font_size", 12)
		hint_lbl.add_theme_color_override("font_color", nm["color"])
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(hint_lbl)


func _build_run_build_panel(parent: Control, run: RunState) -> void:
	var panel := _panel(parent, Color(0.050, 0.058, 0.082), Vector2(0, 74))
	# Thin gold top border on panel
	var panel_border := ColorRect.new()
	panel_border.color = GOLD.darkened(0.55)
	panel_border.custom_minimum_size = Vector2(0, 1)
	panel_border.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.add_child(panel_border)
	var row := _hbox(panel)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("margin_left", 24)
	row.add_theme_constant_override("margin_right", 18)
	row.add_theme_constant_override("margin_top", 10)
	row.add_theme_constant_override("margin_bottom", 10)
	row.add_theme_constant_override("separation", 14)

	var vow: Dictionary = VowSigilSystem.get_vow(run.equipped_vow_id)
	var sigil: Dictionary = VowSigilSystem.get_sigil(run.equipped_sigil_id)
	_build_loadout_status(row, "VOW", str(vow.get("short_name", vow.get("name", "Vow"))), run.equipped_vow_level, run.equipped_vow_xp, GOLD)
	_build_loadout_status(row, "SIGIL", str(sigil.get("short_name", sigil.get("name", "Sigil"))), run.equipped_sigil_level, run.equipped_sigil_xp, Color(0.48, 0.86, 1.0))
	_stretch(row)
	_build_lane_status(row, run)

func _build_loadout_status(parent: Control, label: String, loadout_name: String, level: int, xp: int, color: Color) -> void:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(210, 0)
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)
	_lbl(box, label, 9, DIM)
	_lbl(box, "%s  Lv.%d" % [loadout_name, level], 15, color)
	_lbl(box, VowSigilSystem.xp_progress_text(xp), 10, DIM)
	_lbl(box, VowSigilSystem.level_bonus_text(level, label == "VOW"), 10, color)

func _build_lane_status(parent: Control, run: RunState) -> void:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(230, 0)
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)
	_lbl(box, "BOON LANES", 9, DIM)
	var has_lane: bool = false
	for lane_key in BoonSystem.BOON_LANE_LIMITS.keys():
		var lane_name: String = str(lane_key)
		var count: int = BoonSystem.boons_in_lane(run.active_boons, lane_name).size()
		var limit: int = BoonSystem.boon_lane_limit(lane_name)
		var lane_color: Color = Color(1.0, 0.52, 0.34) if count >= limit else GOLD
		_lbl(box, "%s  %d/%d" % [lane_name.capitalize(), count, limit], 13, lane_color)
		has_lane = true
	if not has_lane:
		_lbl(box, "No limited lanes", 12, DIM)
#  Node entry

func _build_loadout_picker(parent: Control) -> void:
	var box := _panel(parent, Color(0.07, 0.08, 0.12), Vector2(460, 0))
	var inner := _vbox(box)
	inner.add_theme_constant_override("separation", 6)
	_lbl(inner, "Run Alignment", 13, GOLD, true)
	_add_loadout_row(inner, "Vow", VowSigilSystem.VOWS, true)
	_add_loadout_row(inner, "Sigil", VowSigilSystem.SIGILS, false)

func _add_loadout_row(parent: Control, label: String, items: Array[Dictionary], is_vow: bool) -> void:
	var row := _hbox(parent)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var current := VowSigilSystem.get_vow(_selected_vow_id) if is_vow else VowSigilSystem.get_sigil(_selected_sigil_id)
	var current_xp := _loadout_xp(str(current.get("id", "")), is_vow)
	var current_level := VowSigilSystem.level_for_xp(current_xp)
	var name_lbl := _lbl(row, "%s: %s  Lv.%d" % [label, current.get("short_name", current.get("name", "?")), current_level], 14, FG)
	name_lbl.custom_minimum_size.x = 190
	var theme_lbl := _lbl(parent, _loadout_picker_detail(current, is_vow), 11, DIM, true)
	var prev := _btn("<", DIM)
	prev.custom_minimum_size = Vector2(34, 30)
	var next := _btn(">", GOLD)
	next.custom_minimum_size = Vector2(34, 30)
	prev.pressed.connect(func() -> void: _cycle_loadout(items, is_vow, -1); _refresh_loadout_row(name_lbl, theme_lbl, label, is_vow))
	next.pressed.connect(func() -> void: _cycle_loadout(items, is_vow, 1); _refresh_loadout_row(name_lbl, theme_lbl, label, is_vow))
	row.add_child(prev)
	row.add_child(next)

func _cycle_loadout(items: Array[Dictionary], is_vow: bool, delta: int) -> void:
	var current_id := _selected_vow_id if is_vow else _selected_sigil_id
	var idx := 0
	for i in range(items.size()):
		if str(items[i].get("id", "")) == current_id:
			idx = i
			break
	idx = posmod(idx + delta, items.size())
	if is_vow:
		_selected_vow_id = str(items[idx].get("id", VowSigilSystem.DEFAULT_VOW_ID))
	else:
		_selected_sigil_id = str(items[idx].get("id", VowSigilSystem.DEFAULT_SIGIL_ID))

func _refresh_loadout_row(name_lbl: Label, theme_lbl: Label, label: String, is_vow: bool) -> void:
	var current := VowSigilSystem.get_vow(_selected_vow_id) if is_vow else VowSigilSystem.get_sigil(_selected_sigil_id)
	var current_xp := _loadout_xp(str(current.get("id", "")), is_vow)
	var current_level := VowSigilSystem.level_for_xp(current_xp)
	name_lbl.text = "%s: %s  Lv.%d" % [label, current.get("short_name", current.get("name", "?")), current_level]
	theme_lbl.text = _loadout_picker_detail(current, is_vow)


func _loadout_xp(item_id: String, is_vow: bool) -> int:
	if not _gs:
		return 0
	if is_vow and _gs.has_method("get_vow_xp"):
		return _gs.get_vow_xp(item_id)
	if not is_vow and _gs.has_method("get_sigil_xp"):
		return _gs.get_sigil_xp(item_id)
	return 0


func _loadout_picker_detail(item: Dictionary, is_vow: bool) -> String:
	var item_id := str(item.get("id", ""))
	var xp := _loadout_xp(item_id, is_vow)
	var level := VowSigilSystem.level_for_xp(xp)
	return "%s  |  %s  |  %s" % [
		str(item.get("theme", "")),
		VowSigilSystem.xp_progress_text(xp),
		VowSigilSystem.next_unlock_text(level, is_vow),
	]
## Opens the PartyScreen overlay.  Called by "Start New Run" instead of going
## directly to _on_start_run() so the player picks their 4-unit roster first.
func _show_party_select(heat: int) -> void:
	var screen := PARTY_SCENE.instantiate() as PartyScreen
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.party_confirmed.connect(func(ids: Array) -> void:
		screen.queue_free()
		_on_start_run_with_party(heat, ids))
	screen.cancelled.connect(screen.queue_free)
	add_child(screen)


## Called after the player confirms their party choice.
## Creates the run then stamps run_deployment with the 4 selected units at
## default deployment-zone positions so DeploymentScreen has a starting formation.
func _on_start_run_with_party(heat: int, party_ids: Array) -> void:
	_on_start_run(heat)        # creates active_run and rebuilds UI
	if _gs and _gs.active_run and not party_ids.is_empty():
		_gs.active_run.run_deployment = _party_ids_to_deployment(party_ids)


## Converts an ordered list of unit IDs into a run_deployment Array.
## Positions are in the default deployment zone (bottom-2 rows, cols 0-3).
## DeploymentScreen will let the player rearrange before the first battle.
func _party_ids_to_deployment(ids: Array) -> Array:
	var positions: Array[Dictionary] = [
		{"x": 0, "y": 6}, {"x": 1, "y": 6},
		{"x": 2, "y": 6}, {"x": 3, "y": 6},
	]
	var result: Array = []
	for i: int in mini(ids.size(), positions.size()):
		result.append({
			"unit_id": str(ids[i]),
			"x":       int(positions[i]["x"]),
			"y":       int(positions[i]["y"]),
			"facing":  "N",
		})
	return result


func _on_start_run(heat: int = 0) -> void:
	if not _gs: return
	var rm: Node = get_node_or_null("/root/RunManager")
	if rm:
		rm.start_new_run(heat, -1, _selected_vow_id, _selected_sigil_id)
	else:
		# Fallback: create RunState directly if RunManager not registered yet
		var run_seed: int = int(Time.get_unix_time_from_system()) & 0xffffff
		_gs.active_run = RunState.create(run_seed)
		_gs.active_run.equipped_vow_id = _selected_vow_id
		_gs.active_run.equipped_sigil_id = _selected_sigil_id
		if _gs.has_method("seed_run_loadout"):
			_gs.seed_run_loadout(_gs.active_run)
	_build_ui()

func _on_enter_node(node: Dictionary) -> void:
	if not _gs or not _gs.active_run: return
	var node_id := str(node.get("id", ""))
	if not node_id.is_empty():
		_gs.active_run.select_node(node_id)
	if node.get("type", "") == "mystery":
		node = _gs.active_run.resolve_mystery_node(node_id)
		_resolve_revealed_mystery(node)
		return
	match node.get("type","battle"):
		"battle", "elite", "boss", "mystery_ambush":
			_open_deployment(node)
		"mystery_cache", "mystery_training":
			_show_mystery_event(node)
		"mystery_shrine":
			_show_mystery_shrine(node)
		"boon_pick":
			var owned: Array = _gs.active_run.active_boons.map(func(b: Dictionary) -> String: return b.get("id",""))
			var floor_num: int = int(_gs.active_run.current_floor)
			var offers := _bs.generate_offers(_gs.active_run.seed * 17 + floor_num * 3 + _gs.active_run.current_node, floor_num, owned, _gs.active_run.get_loadout_bonus())
			_show_boon_pick(offers)
		"wanderer":
			_show_wanderer_encounter(_gs.active_run)
		"town_1", "town_2", "town_3":
			_show_town_node(node)


## Resolve MapData for a run node — same logic used by both _open_deployment
## and the "Edit Formation" shortcut.
func _resolve_map_data(node: Dictionary) -> MapData:
	var map_id: String = str(node.get("map_id", ""))
	if not map_id.is_empty():
		var path := "res://data/maps/%s.tres" % map_id
		if ResourceLoader.exists(path):
			return load(path)
	var mg := MapGenerator.new()
	return mg.generate_floor(
		_gs.active_run.current_floor,
		_gs.active_run.seed,
		_gs.active_run.heat_level,
	)


func _open_deployment(node: Dictionary) -> void:
	if not _gs or not _gs.active_run:
		return
	_gs.active_run.set_meta("pending_node", node)
	var saved_deployment: Array = _gs.active_run.run_deployment.duplicate(true)
	var map_data: MapData = _resolve_map_data(node)

	# Skip deployment screen when the saved formation is still valid for this map.
	if not saved_deployment.is_empty():
		var errs := DeploymentScreen.validate_formation(saved_deployment, map_data)
		if errs.is_empty():
			_on_deployment_confirmed(saved_deployment)
			return

	_show_deployment_screen(saved_deployment, map_data)


func _show_deployment_screen(saved_deployment: Array, map_data: MapData) -> void:
	var ds := preload("res://scripts/ui/DeploymentScreen.gd").new()
	ds.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ds.saved_formation = saved_deployment
	ds.saved_formation_loaded = not saved_deployment.is_empty()
	ds.map_data = map_data
	ds.battle_started.connect(_on_deployment_confirmed)
	ds.cancelled.connect(func() -> void: ds.queue_free(); _build_ui())
	get_tree().current_scene.add_child(ds)


func _on_deployment_confirmed(deployment: Array) -> void:
	# Save the player's formation for this run and use it for the incoming battle.
	if _gs and _gs.active_run:
		_gs.active_run.run_deployment = deployment.duplicate(true)
		_gs.active_run.set_meta("pending_deployment", deployment.duplicate(true))
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")


func _resolve_revealed_mystery(node: Dictionary) -> void:
	match node.get("type", ""):
		"mystery_ambush":
			_open_deployment(node)
		"mystery_shrine":
			_show_mystery_shrine(node)
		"mystery_cache", "mystery_training":
			_show_mystery_event(node)
		"mystery_treasure":
			_show_mystery_treasure(node)
		"mystery_caravan":
			_show_mystery_caravan(node)
		"mystery_trap":
			_show_mystery_trap(node)
		"mystery_curse_site":
			_show_mystery_curse_site(node)
		"mystery_mimic":
			_show_mystery_mimic(node)
		_:
			_build_ui()


func _show_mystery_shrine(_node: Dictionary) -> void:
	if not _gs or not _gs.active_run:
		return
	var owned: Array = _gs.active_run.active_boons.map(func(b: Dictionary) -> String: return b.get("id", ""))
	var floor_num: int = int(_gs.active_run.current_floor)
	var offers := _bs.generate_offers(_gs.active_run.seed * 29 + floor_num * 11 + _gs.active_run.current_node, floor_num, owned, _gs.active_run.get_loadout_bonus())
	_show_boon_pick(offers)


func _show_mystery_event(node: Dictionary) -> void:
	if _boon_overlay:
		_boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)
	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(620, 0)
	var event_type: String = str(node.get("type", ""))
	var is_cache := event_type == "mystery_cache"
	var title := "Hidden Cache" if is_cache else "Training Shrine"
	var body := "You find sealed coin and supplies tucked beneath old stone." if is_cache else "The party studies an old tactical mural. Everyone gains JP."
	var reward := "+%dg" % _mystery_gold_reward() if is_cache else "+%d JP to each unit" % _mystery_jp_reward()
	_lbl(vbox, "MYSTERY", 11, DIM, true)
	_space(vbox, 8)
	_lbl(vbox, title, 30, FG, true)
	_space(vbox, 8)
	_lbl(vbox, body, 13, DIM, true)
	_space(vbox, 8)
	_lbl(vbox, reward, 18, GOLD if is_cache else Color(0.48,0.86,1.0), true)
	_space(vbox, 22)
	var cont := _btn("Claim", GOLD)
	cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cont.pressed.connect(func() -> void:
		_apply_mystery_event(event_type)
		if _boon_overlay:
			_boon_overlay.queue_free()
			_boon_overlay = null
		_build_ui())
	vbox.add_child(cont)


func _show_mystery_treasure(_node: Dictionary) -> void:
	if _boon_overlay:
		_boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)
	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(620, 0)
	var gold_reward: int = _mystery_treasure_reward()
	_lbl(vbox, "MYSTERY", 11, DIM, true)
	_space(vbox, 8)
	_lbl(vbox, "Ancient Vault", 30, FG, true)
	_space(vbox, 8)
	_lbl(vbox, "A sealed chamber, untouched since the last age. Coin and relics spill out as the lock breaks.", 13, DIM, true)
	_space(vbox, 8)
	_lbl(vbox, "+%dg" % gold_reward, 22, GOLD, true)
	_space(vbox, 22)
	var cont2 := _btn("Claim the Vault", GOLD)
	cont2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cont2.pressed.connect(func() -> void:
		_apply_mystery_event("mystery_treasure")
		if _boon_overlay:
			_boon_overlay.queue_free()
			_boon_overlay = null
		_build_ui())
	vbox.add_child(cont2)


func _show_mystery_caravan(_node: Dictionary) -> void:
	if _boon_overlay:
		_boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)
	var floor_num: int = int(_gs.active_run.current_floor) if _gs and _gs.active_run else 1
	var gold: int = int(_gs.gold) if _gs else 0
	var heal_amount: int = floor_num * 12 + 40
	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(720, 0)
	_lbl(vbox, "MYSTERY", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "Traveling Caravan", 28, FG, true)
	_space(vbox, 6)
	_lbl(vbox, "A merchant convoy halts at your approach. They trade quickly — routes don't wait.", 13, DIM, true)
	_space(vbox, 4)
	_lbl(vbox, "Gold: %dg" % gold, 15, GOLD, true)
	_space(vbox, 16)
	var cards_row := _hbox(vbox)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 16)
	var btn_ca := _town_service_card(cards_row,
		"Healing Provisions",
		"Restore %d HP to each party member.\nCaravan physician-grade salves." % heal_amount,
		"60g",
		Color(0.30, 0.86, 0.50) if gold >= 60 else DIM)
	btn_ca.text = "Buy"
	btn_ca.disabled = gold < 60
	btn_ca.pressed.connect(func() -> void:
		if not _gs or int(_gs.gold) < 60:
			return
		_gs.gold -= 60
		_apply_partial_hp_heal(heal_amount)
		btn_ca.text = "Purchased"
		btn_ca.disabled = true)
	var btn_cb := _town_service_card(cards_row,
		"Trainer's Contract",
		"All units gain +22 JP.\nA retired soldier shares hard-won technique.",
		"80g",
		Color(0.96, 0.78, 0.28) if gold >= 80 else DIM)
	btn_cb.text = "Buy"
	btn_cb.disabled = gold < 80
	btn_cb.pressed.connect(func() -> void:
		if not _gs or int(_gs.gold) < 80:
			return
		_gs.gold -= 80
		_grant_party_jp(22)
		btn_cb.text = "Contracted"
		btn_cb.disabled = true)
	_space(vbox, 22)
	var depart_car := _btn("Move On  ->", GOLD)
	depart_car.custom_minimum_size = Vector2(200, 46)
	depart_car.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	depart_car.pressed.connect(func() -> void:
		_complete_current_node_with_loadout_xp("mystery_caravan")
		if _gs:
			_gs.save()
		if _boon_overlay:
			_boon_overlay.queue_free()
			_boon_overlay = null
		_build_ui())
	vbox.add_child(depart_car)


func _show_mystery_trap(_node: Dictionary) -> void:
	if _boon_overlay:
		_boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)
	var floor_num: int = int(_gs.active_run.current_floor) if _gs and _gs.active_run else 1
	var damage: int        = floor_num * 5 + 10
	var gold_brave: int    = floor_num * 30 + 60
	var gold_cautious: int = floor_num * 10 + 20
	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(680, 0)
	_lbl(vbox, "MYSTERY", 11, DIM, true)
	_space(vbox, 8)
	_lbl(vbox, "Pressure Plate Trap", 30, FG, true)
	_space(vbox, 8)
	_lbl(vbox, "The path is rigged. A cache sits just beyond the trigger — if you can reach it.", 13, DIM, true)
	_space(vbox, 20)
	var trap_row := _hbox(vbox)
	trap_row.alignment = BoxContainer.ALIGNMENT_CENTER
	trap_row.add_theme_constant_override("separation", 16)
	var btn_ta := _town_service_card(trap_row,
		"Brave the Trigger",
		"Sprint through and grab the full cache.\nAll units take -%d HP." % damage,
		"-%d HP per unit" % damage,
		Color(0.96, 0.40, 0.30))
	btn_ta.text = "Push Through  (+%dg)" % gold_brave
	btn_ta.pressed.connect(func() -> void:
		if _gs:
			for uid in _gs.unit_registry:
				var reg: Dictionary = _gs.unit_registry[uid]
				reg["current_hp"] = maxi(1, int(reg.get("current_hp", 0)) - damage)
			_gs.gold += gold_brave
		_complete_current_node_with_loadout_xp("mystery_trap")
		if _gs: _gs.save()
		if _boon_overlay: _boon_overlay.queue_free(); _boon_overlay = null
		_build_ui())
	var btn_tb := _town_service_card(trap_row,
		"Careful Retreat",
		"Probe safely and snag what you can reach.\nNo injuries, but a smaller haul.",
		"No risk",
		Color(0.48, 0.86, 1.0))
	btn_tb.text = "Back Away  (+%dg)" % gold_cautious
	btn_tb.pressed.connect(func() -> void:
		if _gs:
			_gs.gold += gold_cautious
		_complete_current_node_with_loadout_xp("mystery_trap")
		if _gs: _gs.save()
		if _boon_overlay: _boon_overlay.queue_free(); _boon_overlay = null
		_build_ui())


func _show_mystery_curse_site(_node: Dictionary) -> void:
	if _boon_overlay:
		_boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)
	var floor_num: int = int(_gs.active_run.current_floor) if _gs and _gs.active_run else 1
	var meta: Node = get_node_or_null("/root/MetaProgression")
	var shards: int = meta.get_currency(Currency.SOUL_SHARDS) if meta else 0
	var jp_absorb: int = floor_num * 25 + 60
	var jp_purge: int  = floor_num * 12 + 25
	var owned_curse_ids: Array = []
	if _gs and _gs.active_run:
		owned_curse_ids = _gs.active_run.active_curses.map(
			func(c: Dictionary) -> String: return c.get("id", ""))
	var cs_seed: int = (_gs.active_run.seed * 61 + floor_num * 13 + _gs.active_run.current_node + 777) if _gs and _gs.active_run else 777
	var curse_offer: Dictionary = _cs.generate_curse_offer(cs_seed, floor_num, owned_curse_ids)
	var curse_name: String = str(curse_offer.get("name", "an unknown curse")) if not curse_offer.is_empty() else ""
	var can_absorb := not curse_offer.is_empty()
	var can_purge  := shards >= 30
	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(780, 0)
	_lbl(vbox, "MYSTERY", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "Blackened Altar", 28, FG, true)
	_space(vbox, 6)
	_lbl(vbox, "A site of old dark power. The taint is still active. What do you do with it?", 13, DIM, true)
	_space(vbox, 18)
	var cs_row := _hbox(vbox)
	cs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cs_row.add_theme_constant_override("separation", 12)
	var absorb_body: String
	if can_absorb:
		absorb_body = "Accept [%s] into the run.\n+%d JP to every unit as dark power courses through." % [curse_name, jp_absorb]
	else:
		absorb_body = "All curses for this depth are already active."
	var btn_cs_a := _town_service_card(cs_row,
		"Absorb the Darkness",
		absorb_body,
		"1 curse added to run",
		Color(0.72, 0.30, 0.86) if can_absorb else DIM)
	btn_cs_a.text = "Accept"
	btn_cs_a.disabled = not can_absorb
	btn_cs_a.pressed.connect(func() -> void:
		if _gs and _gs.active_run and not curse_offer.is_empty():
			_gs.active_run.active_curses.append(curse_offer)
			_grant_party_jp(jp_absorb)
		_complete_current_node_with_loadout_xp("mystery_curse_site")
		if _gs: _gs.save()
		if _boon_overlay: _boon_overlay.queue_free(); _boon_overlay = null
		_build_ui())
	var btn_cs_b := _town_service_card(cs_row,
		"Purge the Sigil",
		"Spend Soul Shards to cleanse the altar.\n+%d JP from residual energy. No curse." % jp_purge,
		"30 Soul Shards",
		Color(0.55, 0.92, 0.72) if can_purge else DIM)
	btn_cs_b.text = "Purge"
	btn_cs_b.disabled = not can_purge
	btn_cs_b.pressed.connect(func() -> void:
		if not meta or not meta.spend({Currency.SOUL_SHARDS: 30}):
			return
		_grant_party_jp(jp_purge)
		_complete_current_node_with_loadout_xp("mystery_curse_site")
		if _gs: _gs.save()
		if _boon_overlay: _boon_overlay.queue_free(); _boon_overlay = null
		_build_ui())
	_space(vbox, 22)
	var skip_cs := _btn("Walk Past", DIM)
	skip_cs.custom_minimum_size = Vector2(160, 40)
	skip_cs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip_cs.pressed.connect(func() -> void:
		_complete_current_node_with_loadout_xp("mystery_curse_site")
		if _gs: _gs.save()
		if _boon_overlay: _boon_overlay.queue_free(); _boon_overlay = null
		_build_ui())
	vbox.add_child(skip_cs)


func _show_mystery_mimic(node: Dictionary) -> void:
	if _boon_overlay:
		_boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)
	var floor_num: int = int(_gs.active_run.current_floor) if _gs and _gs.active_run else 1
	var flee_damage: int = floor_num * 8 + 15
	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(640, 0)
	_lbl(vbox, "MYSTERY", 11, DIM, true)
	_space(vbox, 8)
	_lbl(vbox, "!! MIMIC !!", 32, Color(0.96, 0.30, 0.20), true)
	_space(vbox, 8)
	_lbl(vbox, "The chest lunges. Eyes and teeth emerge from the lock. It was never treasure at all.", 13, DIM, true)
	_space(vbox, 20)
	var mimic_row := _hbox(vbox)
	mimic_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mimic_row.add_theme_constant_override("separation", 16)
	var fight := _btn("Fight!  ->", Color(0.96, 0.40, 0.30))
	fight.custom_minimum_size = Vector2(200, 56)
	fight.pressed.connect(func() -> void:
		if _boon_overlay:
			_boon_overlay.queue_free()
			_boon_overlay = null
		_open_deployment(node))
	mimic_row.add_child(fight)
	var flee := _btn("Flee!  (-%d HP each)" % flee_damage, DIM)
	flee.custom_minimum_size = Vector2(250, 56)
	flee.pressed.connect(func() -> void:
		if _gs:
			for uid in _gs.unit_registry:
				var reg: Dictionary = _gs.unit_registry[uid]
				reg["current_hp"] = maxi(1, int(reg.get("current_hp", 0)) - flee_damage)
		_complete_current_node_with_loadout_xp("mystery_mimic")
		if _gs: _gs.save()
		if _boon_overlay: _boon_overlay.queue_free(); _boon_overlay = null
		_build_ui())
	mimic_row.add_child(flee)


func _show_town_node(node: Dictionary) -> void:
	_show_town_hub(str(node.get("type", "town_1")))


func _close_town_overlay(town_type: String) -> void:
	_complete_current_node_with_loadout_xp(town_type)
	if _gs:
		_gs.save()
	if _boon_overlay:
		_boon_overlay.queue_free()
		_boon_overlay = null
	_build_ui()


func _town_service_card(parent: Control, title: String, body: String,
		cost: String, accent: Color) -> Button:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(320, 210)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color     = Color(accent.r * 0.08, accent.g * 0.08, accent.b * 0.08, 0.92)
	st.border_color = accent.lerp(Color.TRANSPARENT, 0.35)
	st.set_border_width_all(1)
	st.content_margin_left = 22; st.content_margin_right  = 22
	st.content_margin_top  = 18; st.content_margin_bottom = 18
	pc.add_theme_stylebox_override("panel", st)
	parent.add_child(pc)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	pc.add_child(inner)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", accent)
	inner.add_child(title_lbl)

	var body_lbl := Label.new()
	body_lbl.text = body
	body_lbl.add_theme_font_size_override("font_size", 13)
	body_lbl.add_theme_color_override("font_color", Color(0.78, 0.75, 0.70))
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(body_lbl)

	inner.add_child(HSeparator.new())

	var cost_lbl := Label.new()
	cost_lbl.text = "Cost: %s" % cost
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", accent)
	inner.add_child(cost_lbl)

	var btn := _btn("Use", accent)
	btn.custom_minimum_size = Vector2(0, 40)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(btn)
	return btn


func _apply_partial_hp_heal(amount: int) -> void:
	if not _gs:
		return
	var total_healed := 0
	for uid in _gs.unit_registry:
		var reg: Dictionary = _gs.unit_registry[uid]
		var current: int = int(reg.get("current_hp", reg.get("base_hp", reg.get("max_hp", 200))))
		var max_hp: int  = int(reg.get("base_hp", reg.get("max_hp", 200)))
		var next_hp: int = mini(max_hp, current + amount)
		total_healed += maxi(0, next_hp - current)
		reg["current_hp"] = next_hp
	_record_healing_applied("partial_hp", total_healed)


func _show_sanctum(town_type: String) -> void:
	if _boon_overlay:
		_boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)

	var floor_num: int = int(_gs.active_run.current_floor) if _gs and _gs.active_run else 1
	var partial_hp: int = floor_num * 15 + 30
	var meta: Node = get_node_or_null("/root/MetaProgression")
	var shards: int = meta.get_currency(Currency.SOUL_SHARDS) if meta else 0
	var jp_bonus: int = 6 + floor_num * 2

	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(720, 0)

	_lbl(vbox, "TOWN NODE", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "Sanctum of the Last Hearth", 28, FG, true)
	_space(vbox, 6)
	_lbl(vbox, "Holy ground. Choose your services before continuing.", 13, DIM, true)
	_space(vbox, 18)

	var cards_row := _hbox(vbox)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 16)

	var btn_a := _town_service_card(cards_row,
		"Tend the Wounded",
		"Restore %d HP to each party member.\nWill not exceed max HP." % partial_hp,
		"Free", Color(0.30, 0.86, 0.50))
	btn_a.pressed.connect(func() -> void:
		_apply_partial_hp_heal(partial_hp)
		btn_a.text = "Mended"
		btn_a.disabled = true)

	var can_rite := shards >= 50
	var btn_b := _town_service_card(cards_row,
		"Full Consecration",
		"Restore ALL HP to full.\n+%d JP to every unit." % jp_bonus,
		"50 Soul Shards",
		GOLD if can_rite else DIM)
	btn_b.disabled = not can_rite
	btn_b.pressed.connect(func() -> void:
		if not meta or not meta.spend({Currency.SOUL_SHARDS: 50}):
			return
		_restore_party_hp()
		_grant_party_jp(jp_bonus)
		btn_b.text = "Consecrated"
		btn_b.disabled = true)

	_space(vbox, 22)
	var back_sanc := _btn("← Town Square", DIM)
	back_sanc.custom_minimum_size = Vector2(200, 46)
	back_sanc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_sanc.pressed.connect(func() -> void: _show_town_hub(town_type))
	vbox.add_child(back_sanc)


func _show_armory(town_type: String) -> void:
	if _boon_overlay:
		_boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)

	var floor_num: int = int(_gs.active_run.current_floor) if _gs and _gs.active_run else 1
	var gold: int = int(_gs.gold) if _gs else 0
	var heal_b: int = floor_num * 10 + 25

	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(720, 0)

	_lbl(vbox, "TOWN NODE", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "Field Armory", 28, FG, true)
	_space(vbox, 6)
	_lbl(vbox, "Spend gold to strengthen the party. Services can be used once each.", 13, DIM, true)
	_space(vbox, 4)
	_lbl(vbox, "Gold: %dg" % gold, 15, GOLD, true)
	_space(vbox, 16)

	var cards_row := _hbox(vbox)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 16)

	var btn_a := _town_service_card(cards_row,
		"Basic Resupply",
		"All units gain +15 JP.\nSharpen skills for the fights ahead.",
		"50g",
		Color(0.96, 0.78, 0.28) if gold >= 50 else DIM)
	btn_a.disabled = gold < 50
	btn_a.pressed.connect(func() -> void:
		if not _gs or int(_gs.gold) < 50:
			return
		_gs.gold -= 50
		_grant_party_jp(15)
		btn_a.text = "Supplied"
		btn_a.disabled = true)

	var btn_b := _town_service_card(cards_row,
		"Full War Drill",
		"All units gain +30 JP.\nRestore %d HP to each unit." % heal_b,
		"100g",
		Color(1.0, 0.55, 0.20) if gold >= 100 else DIM)
	btn_b.disabled = gold < 100
	btn_b.pressed.connect(func() -> void:
		if not _gs or int(_gs.gold) < 100:
			return
		_gs.gold -= 100
		_grant_party_jp(30)
		_apply_partial_hp_heal(heal_b)
		btn_b.text = "Drilled"
		btn_b.disabled = true)

	_space(vbox, 22)
	var back_arm := _btn("← Town Square", DIM)
	back_arm.custom_minimum_size = Vector2(200, 46)
	back_arm.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_arm.pressed.connect(func() -> void: _show_town_hub(town_type))
	vbox.add_child(back_arm)


func _show_oracle(town_type: String) -> void:
	if _boon_overlay:
		_boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)

	var floor_num: int = int(_gs.active_run.current_floor) if _gs and _gs.active_run else 1
	var meta: Node = get_node_or_null("/root/MetaProgression")
	var shards: int = meta.get_currency(Currency.SOUL_SHARDS) if meta else 0
	var can_boon := shards >= 40 and _gs != null and _gs.active_run != null

	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(760, 0)

	_lbl(vbox, "TOWN NODE", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "The Oracle's Post", 28, FG, true)
	_space(vbox, 6)
	_lbl(vbox, "A seer reads the paths ahead. Knowledge and power, for a price.", 13, DIM, true)
	_space(vbox, 18)

	var cards_row := _hbox(vbox)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 16)

	var btn_a := _town_service_card(cards_row,
		"Scout Ahead",
		"Reveal mystery nodes on the next 2 floors.\nFree intelligence on what lies ahead.",
		"Free", Color(0.72, 0.58, 1.0))
	btn_a.pressed.connect(func() -> void:
		var revealed: int = _reveal_upcoming_mysteries(2)
		btn_a.text = "%d Node%s Revealed" % [revealed, "s" if revealed != 1 else ""]
		btn_a.disabled = true)

	var btn_b := _town_service_card(cards_row,
		"Commune with the Weave",
		"Draw 3 Guardian boons. Choose one to add to your run.\nLane limits apply.",
		"40 Soul Shards",
		Color(0.55, 0.92, 0.72) if can_boon else DIM)
	btn_b.disabled = not can_boon
	btn_b.pressed.connect(func() -> void:
		if not meta or not meta.spend({Currency.SOUL_SHARDS: 40}):
			return
		btn_b.text = "Communing..."
		btn_b.disabled = true
		_show_oracle_boon_pick(vbox, floor_num))

	_space(vbox, 22)
	var back_orc := _btn("← Town Square", DIM)
	back_orc.custom_minimum_size = Vector2(200, 46)
	back_orc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_orc.pressed.connect(func() -> void: _show_town_hub(town_type))
	vbox.add_child(back_orc)


func _show_oracle_boon_pick(parent: Control, floor_num: int) -> void:
	if not _gs or not _gs.active_run:
		return
	var owned: Array = _gs.active_run.active_boons.map(
		func(b: Dictionary) -> String: return b.get("id", ""))
	var offers := _bs.generate_offers(
		_gs.active_run.seed * 37 + floor_num * 7 + _gs.active_run.current_node + 999,
		floor_num, owned, _gs.active_run.get_loadout_bonus())

	_space(parent, 14)
	_lbl(parent, "CHOOSE A VISION", 11, Color(0.55, 0.92, 0.72), true)
	_space(parent, 8)

	var row := _hbox(parent)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)

	var offer_btns: Array[Button] = []
	for boon: Dictionary in offers:
		var rd: Dictionary = BoonSystem.RARITIES.get(boon.get("rarity", "common"), {})
		var bc: Color = rd.get("color", GOLD)
		var boon_copy := boon
		var offer_btn := Button.new()
		offer_btn.custom_minimum_size = Vector2(220, 80)
		offer_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var st := StyleBoxFlat.new()
		st.bg_color     = Color(bc.r * 0.10, bc.g * 0.10, bc.b * 0.10, 0.92)
		st.border_color = bc.lerp(Color.TRANSPARENT, 0.30)
		st.set_border_width_all(1)
		st.content_margin_left = 14; st.content_margin_right  = 14
		st.content_margin_top  = 10; st.content_margin_bottom = 10
		offer_btn.add_theme_stylebox_override("normal", st)
		offer_btn.add_theme_stylebox_override("hover",  st)
		offer_btn.add_theme_color_override("font_color", bc)
		offer_btn.add_theme_font_size_override("font_size", 13)
		offer_btn.text = "%s %s  [%s]" % [
			str(boon_copy.get("icon", "+")),
			str(boon_copy.get("name", "?")),
			str(boon_copy.get("rarity", "common")).capitalize()
		]
		offer_btn.pressed.connect(func() -> void:
			_oracle_accept_boon(boon_copy)
			for b: Button in offer_btns:
				b.disabled = true)
		offer_btns.append(offer_btn)
		row.add_child(offer_btn)


func _oracle_accept_boon(boon: Dictionary) -> void:
	if not _gs or not _gs.active_run:
		return
	if BoonSystem.needs_lane_replacement(_gs.active_run.active_boons, boon):
		var lane: String = BoonSystem.boon_lane(boon)
		var in_lane: Array = BoonSystem.boons_in_lane(_gs.active_run.active_boons, lane)
		if not in_lane.is_empty():
			var lane_id: String = str(in_lane[0].get("id", ""))
			for i: int in range(_gs.active_run.active_boons.size() - 1, -1, -1):
				if str(_gs.active_run.active_boons[i].get("id", "")) == lane_id:
					_gs.active_run.active_boons.remove_at(i)
					break
	_gs.active_run.active_boons.append(boon)


#  Town hub — 5-district entry screen  ——————————————————————————————————————

## Hub shown for all town node types.  Lets the player visit each district
## freely before the single "Depart" button completes the node.
func _show_town_hub(town_type: String) -> void:
	if _boon_overlay: _boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)

	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(920, 0)

	_lbl(vbox, "TOWN NODE", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "Town Square", 30, FG, true)
	_space(vbox, 8)
	_lbl(vbox, "Choose a district.  You may visit each one before departing.", 13, DIM, true)
	_space(vbox, 22)

	# District definitions — Callable stored as Variant in an untyped Array.
	var districts: Array = [
		{
			"title": "Sanctum",  "icon": "+",
			"desc":  "Rest the wounded.\nBlessings for the worthy.",
			"accent": Color(0.30, 0.86, 0.50),
			"fn": func() -> void: _show_sanctum(town_type),
		},
		{
			"title": "Armory",   "icon": "@",
			"desc":  "Spend gold on training\nand war supplies.",
			"accent": Color(0.96, 0.78, 0.28),
			"fn": func() -> void: _show_armory(town_type),
		},
		{
			"title": "Tavern",   "icon": "T",
			"desc":  "Reassign your deployed\nparty roster.",
			"accent": Color(0.48, 0.78, 1.00),
			"fn": func() -> void: _show_tavern(town_type),
		},
		{
			"title": "Vault",    "icon": "$",
			"desc":  "Convert gold into\nmeta-currencies.",
			"accent": Color(0.72, 0.58, 1.00),
			"fn": func() -> void: _show_vault(town_type),
		},
		{
			"title": "Oracle",   "icon": "?",
			"desc":  "Scout ahead and\ncommunne with the Weave.",
			"accent": Color(0.55, 0.92, 0.72),
			"fn": func() -> void: _show_oracle(town_type),
		},
	]

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	for d: Dictionary in districts:
		var acc: Color = d["accent"]

		var pc := PanelContainer.new()
		pc.custom_minimum_size = Vector2(162, 220)
		pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var card_st := StyleBoxFlat.new()
		card_st.bg_color     = Color(acc.r * 0.08, acc.g * 0.08, acc.b * 0.08, 0.92)
		card_st.border_color = acc.lerp(Color.TRANSPARENT, 0.40)
		card_st.set_border_width_all(1)
		card_st.set_corner_radius_all(8)
		card_st.content_margin_left = 14; card_st.content_margin_right  = 14
		card_st.content_margin_top  = 14; card_st.content_margin_bottom = 14
		pc.add_theme_stylebox_override("panel", card_st)
		row.add_child(pc)

		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 8)
		pc.add_child(inner)

		_lbl(inner, str(d["icon"]), 26, acc, true)
		var title_lbl := Label.new()
		title_lbl.text = str(d["title"])
		title_lbl.add_theme_font_size_override("font_size", 16)
		title_lbl.add_theme_color_override("font_color", acc)
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(title_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = str(d["desc"])
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.70, 0.65))
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(desc_lbl)

		var fill := Control.new()
		fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
		inner.add_child(fill)

		var enter_btn := _btn("Enter", acc)
		enter_btn.custom_minimum_size = Vector2(0, 36)
		enter_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var fn: Callable = d["fn"]
		enter_btn.pressed.connect(fn)
		inner.add_child(enter_btn)

	_space(vbox, 26)
	var depart_hub := _btn("Depart from Town  ->", GOLD)
	depart_hub.custom_minimum_size = Vector2(240, 48)
	depart_hub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	depart_hub.pressed.connect(func() -> void: _close_town_overlay(town_type))
	vbox.add_child(depart_hub)


#  Tavern — roster management  ——————————————————————————————————————————————

## Lets the player bench deployed units and call up reserve units.
## Changes write directly to run_deployment; max 4 deployed, min 1.
func _show_tavern(town_type: String) -> void:
	if _boon_overlay: _boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)

	if not _gs or not _gs.active_run:
		_show_town_hub(town_type)
		return

	var run: RunState = _gs.active_run
	var chars_node := get_node_or_null("/root/Characters")

	# Deployed: units present in run_deployment (preserving order).
	var deployed_ids: Array[String] = []
	for slot: Dictionary in run.run_deployment:
		var uid: String = str(slot.get("unit_id", ""))
		if uid != "" and uid not in deployed_ids:
			deployed_ids.append(uid)

	# Reserve: all unit_registry keys not currently deployed.
	var reserve_ids: Array[String] = []
	for uid: String in _gs.unit_registry.keys():
		if uid not in deployed_ids:
			reserve_ids.append(uid)

	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(780, 0)

	_lbl(vbox, "TOWN NODE", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "Tavern — Roster", 28, FG, true)
	_space(vbox, 6)
	_lbl(vbox, "Reassign your party before the next battle.  Changes take effect immediately.", 13, DIM, true)
	_space(vbox, 18)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	vbox.add_child(cols)

	# Left column: deployed.
	var dep_col := VBoxContainer.new()
	dep_col.add_theme_constant_override("separation", 8)
	dep_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(dep_col)
	_lbl(dep_col, "DEPLOYED  (%d / 4)" % deployed_ids.size(), 11, TEAL)
	_space(dep_col, 4)
	for uid: String in deployed_ids:
		dep_col.add_child(_tavern_unit_row(uid, true, town_type, deployed_ids, chars_node))

	# Right column: reserve.
	var res_col := VBoxContainer.new()
	res_col.add_theme_constant_override("separation", 8)
	res_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(res_col)
	_lbl(res_col, "RESERVE  (%d)" % reserve_ids.size(), 11, DIM)
	_space(res_col, 4)
	if reserve_ids.is_empty():
		_lbl(res_col, "All units are deployed.", 13, DIM)
	else:
		for uid: String in reserve_ids:
			res_col.add_child(_tavern_unit_row(uid, false, town_type, deployed_ids, chars_node))

	_space(vbox, 22)
	var back_tav := _btn("← Town Square", DIM)
	back_tav.custom_minimum_size = Vector2(200, 46)
	back_tav.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_tav.pressed.connect(func() -> void: _show_town_hub(town_type))
	vbox.add_child(back_tav)


## Builds one unit row for the Tavern — name/stats + Bench or Deploy button.
func _tavern_unit_row(uid: String, is_deployed: bool, town_type: String,
		deployed_ids: Array[String], chars_node: Node) -> PanelContainer:
	var reg: Dictionary = _gs.unit_registry.get(uid, {}) if _gs else {}
	var hp_cur: int = int(reg.get("current_hp", reg.get("base_hp", 200)))
	var hp_max: int = int(reg.get("base_hp",    reg.get("max_hp",  200)))
	var jp_val: int = int(reg.get("jp", 0))

	var display_name: String = uid
	if chars_node and chars_node.CHARACTERS.has(uid):
		display_name = str(chars_node.CHARACTERS[uid].get("human_name", uid))

	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_st := StyleBoxFlat.new()
	card_st.bg_color     = Color(0.07, 0.08, 0.11) if is_deployed else Color(0.05, 0.055, 0.075)
	card_st.border_color = TEAL.lerp(Color.TRANSPARENT, 0.50) if is_deployed else Color(1.0, 1.0, 1.0, 0.07)
	card_st.set_border_width_all(1)
	card_st.set_corner_radius_all(6)
	card_st.content_margin_left = 14; card_st.content_margin_right  = 14
	card_st.content_margin_top  = 10; card_st.content_margin_bottom = 10
	pc.add_theme_stylebox_override("panel", card_st)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	pc.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	_lbl(info, display_name, 14, FG if is_deployed else DIM)
	_lbl(info, "HP %d/%d  ·  %d JP" % [hp_cur, hp_max, jp_val], 11, DIM)

	var cap_uid := uid
	if is_deployed:
		var bench_btn := _btn("Bench", DIM)
		bench_btn.custom_minimum_size = Vector2(72, 28)
		bench_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Prevent benching the last deployed unit.
		bench_btn.disabled = deployed_ids.size() <= 1
		bench_btn.pressed.connect(func() -> void:
			if not _gs or not _gs.active_run: return
			for i: int in range(_gs.active_run.run_deployment.size() - 1, -1, -1):
				if str(_gs.active_run.run_deployment[i].get("unit_id", "")) == cap_uid:
					_gs.active_run.run_deployment.remove_at(i)
					break
			_show_tavern(town_type))
		row.add_child(bench_btn)
	else:
		var deploy_btn := _btn("Deploy", TEAL)
		deploy_btn.custom_minimum_size = Vector2(72, 28)
		deploy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Prevent deploying a fifth unit.
		deploy_btn.disabled = deployed_ids.size() >= 4
		deploy_btn.pressed.connect(func() -> void:
			if not _gs or not _gs.active_run: return
			var pos: int = _gs.active_run.run_deployment.size()
			_gs.active_run.run_deployment.append({
				"unit_id": cap_uid,
				"x":       mini(pos, 3),
				"y":       6,
				"facing":  "N",
			})
			_show_tavern(town_type))
		row.add_child(deploy_btn)

	return pc


#  Vault — gold banking  ————————————————————————————————————————————————————

## Converts run gold into persistent meta-currencies (Soul Shards and Obsidian).
func _show_vault(town_type: String) -> void:
	if _boon_overlay: _boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)

	var meta: Node    = get_node_or_null("/root/MetaProgression")
	var gold: int     = int(_gs.gold) if _gs else 0
	var shards: int   = meta.get_currency(Currency.SOUL_SHARDS) if meta else 0
	var obsidian: int = meta.get_currency(Currency.OBSIDIAN)     if meta else 0

	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(720, 0)

	_lbl(vbox, "TOWN NODE", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "The Vault", 28, FG, true)
	_space(vbox, 6)
	_lbl(vbox, "Convert run gold into persistent currencies that carry over between runs.", 13, DIM, true)
	_space(vbox, 12)

	# Current holdings summary.
	var res_row := HBoxContainer.new()
	res_row.alignment = BoxContainer.ALIGNMENT_CENTER
	res_row.add_theme_constant_override("separation", 28)
	vbox.add_child(res_row)
	_lbl(res_row, "Gold:  %dg" % gold, 16, GOLD)
	_lbl(res_row, "Soul Shards:  %d" % shards, 15, Color(0.55, 0.92, 0.72))
	_lbl(res_row, "Obsidian:  %d" % obsidian, 15, Color(0.72, 0.58, 1.00))
	_space(vbox, 18)

	var cards_row := _hbox(vbox)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 16)

	# Conversion A: 50g → 10 Soul Shards.
	var btn_v1 := _town_service_card(cards_row,
		"Tithe to the Shards",
		"Convert 50g into 10 Soul Shards.\nShards fund Sanctum rites and Oracle visions.",
		"50g",
		Color(0.55, 0.92, 0.72) if gold >= 50 else DIM)
	btn_v1.disabled = gold < 50 or not meta
	btn_v1.pressed.connect(func() -> void:
		if not _gs or int(_gs.gold) < 50 or not meta: return
		_gs.gold -= 50
		meta.add_currency(Currency.SOUL_SHARDS, 10)
		btn_v1.text    = "+10 Shards"
		btn_v1.disabled = true)

	# Conversion B: 100g → 5 Obsidian.
	var btn_v2 := _town_service_card(cards_row,
		"Temper the Obsidian",
		"Convert 100g into 5 Obsidian.\nObsidian fuels permanent upgrades between runs.",
		"100g",
		Color(0.72, 0.58, 1.00) if gold >= 100 else DIM)
	btn_v2.disabled = gold < 100 or not meta
	btn_v2.pressed.connect(func() -> void:
		if not _gs or int(_gs.gold) < 100 or not meta: return
		_gs.gold -= 100
		meta.add_currency(Currency.OBSIDIAN, 5)
		btn_v2.text    = "+5 Obsidian"
		btn_v2.disabled = true)

	_space(vbox, 22)
	var back_vlt := _btn("← Town Square", DIM)
	back_vlt.custom_minimum_size = Vector2(200, 46)
	back_vlt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_vlt.pressed.connect(func() -> void: _show_town_hub(town_type))
	vbox.add_child(back_vlt)


func _restore_party_hp() -> void:
	if not _gs:
		return
	var total_healed := 0
	for uid in _gs.unit_registry:
		var reg: Dictionary = _gs.unit_registry[uid]
		var max_hp: int = int(reg.get("base_hp", reg.get("max_hp", 200)))
		var current: int = int(reg.get("current_hp", max_hp))
		total_healed += maxi(0, max_hp - current)
		reg["current_hp"] = max_hp
	_record_healing_applied("full_restore", total_healed)


func _reveal_upcoming_mysteries(floors_ahead: int) -> int:
	if not _gs or not _gs.active_run:
		return 0
	var run: RunState = _gs.active_run
	var revealed := 0
	var start_floor: int = int(run.current_floor)
	for i in range(run.floor_plan.size()):
		var route_node: Dictionary = run.floor_plan[i]
		var node_floor: int = int(route_node.get("floor", 0))
		if node_floor <= start_floor or node_floor > start_floor + floors_ahead:
			continue
		if route_node.get("type", "") == "mystery":
			run.reveal_mystery_node_at_index(i)
			revealed += 1
	return revealed


func _apply_mystery_event(event_type: String) -> void:
	if not _gs or not _gs.active_run:
		return
	match event_type:
		"mystery_cache":
			_gs.gold += _mystery_gold_reward()
		"mystery_training":
			_grant_party_jp(_mystery_jp_reward())
		"mystery_treasure":
			_gs.gold += _mystery_treasure_reward()
	_complete_current_node_with_loadout_xp(event_type)
	_gs.save()


func _mystery_treasure_reward() -> int:
	return 120 + int(_gs.active_run.current_floor) * 40 if _gs and _gs.active_run else 120


func _complete_current_node_with_loadout_xp(node_type_override: String = "") -> Dictionary:
	if not _gs or not _gs.active_run:
		return {}
	var node: Dictionary = _gs.active_run.get_current_node()
	var node_type := node_type_override if not node_type_override.is_empty() else str(node.get("type", "battle"))
	var amount := VowSigilSystem.xp_for_floor_clear(int(_gs.active_run.current_floor), node_type)
	var progress: Dictionary = {}
	if _gs.has_method("apply_loadout_xp"):
		progress = _gs.apply_loadout_xp(amount, node_type)
	else:
		_gs.active_run.grant_loadout_xp(amount)
		progress = {"amount": amount, "reason": node_type}
	_gs.active_run.complete_current_node()
	return progress


func _mystery_gold_reward() -> int:
	return 80 + int(_gs.active_run.current_floor) * 24 if _gs and _gs.active_run else 80


func _mystery_jp_reward() -> int:
	return 12 + int(_gs.active_run.current_floor) * 4 if _gs and _gs.active_run else 12


func _grant_party_jp(amount: int) -> void:
	if not _gs:
		return
	for uid in _gs.unit_registry:
		var reg: Dictionary = _gs.unit_registry[uid]
		reg["jp"] = int(reg.get("jp", 0)) + amount
	_gs.run_jp_earned += amount

func _on_edit_formation_from_run(run: RunState) -> void:
	"""Open the deployment editor without committing to a battle node."""
	if not _gs or not run:
		return
	# Use the next available node's map data if possible, otherwise a generic floor.
	var available := run.get_available_nodes()
	var map_data: MapData
	if available.size() > 0:
		map_data = _resolve_map_data(available[0])
	else:
		var mg := MapGenerator.new()
		map_data = mg.generate_floor(run.current_floor, run.seed, run.heat_level)

	var saved: Array = run.run_deployment.duplicate(true)
	var ds := preload("res://scripts/ui/DeploymentScreen.gd").new()
	ds.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ds.saved_formation = saved
	ds.saved_formation_loaded = not saved.is_empty()
	ds.map_data = map_data
	# On confirm: save formation to run but do NOT start battle yet.
	ds.battle_started.connect(func(deployment: Array) -> void:
		run.run_deployment = deployment.duplicate(true)
		if _gs:
			_gs.save()
		ds.queue_free()
		_build_ui()
	)
	ds.cancelled.connect(func() -> void: ds.queue_free(); _build_ui())
	get_tree().current_scene.add_child(ds)


func _on_abandon() -> void:
	var rm: Node = get_node_or_null("/root/RunManager")
	if rm and rm.is_run_active: rm.end_run(false)
	elif _gs: _gs.active_run = null
	_build_ui()

func _on_boon_picked(boon: Dictionary) -> void:
	if not _gs or not _gs.active_run:
		return
	if BoonSystem.needs_lane_replacement(_gs.active_run.active_boons, boon):
		_show_boon_replacement(boon)
		return
	_accept_boon(boon)

func _accept_boon(boon: Dictionary, replaced_boon_id: String = "") -> void:
	if not _gs or not _gs.active_run:
		return
	if not replaced_boon_id.is_empty():
		for i in range(_gs.active_run.active_boons.size() - 1, -1, -1):
			if str(_gs.active_run.active_boons[i].get("id", "")) == replaced_boon_id:
				_gs.active_run.active_boons.remove_at(i)
				break
	_gs.active_run.active_boons.append(boon)
	_gs.pending_boon_offers.clear()
	_complete_current_node_with_loadout_xp("boon_pick")
	_apply_between_battle_heal()
	if _boon_overlay:
		_boon_overlay.queue_free()
		_boon_overlay = null
	_build_ui()

func _show_boon_replacement(incoming_boon: Dictionary) -> void:
	if not _gs or not _gs.active_run:
		return
	if _boon_overlay:
		_boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)

	var lane := BoonSystem.boon_lane(incoming_boon)
	var existing := BoonSystem.boons_in_lane(_gs.active_run.active_boons, lane)
	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(760, 0)
	_lbl(vbox, "BOON LIMIT", 11, GOLD, true)
	_space(vbox, 8)
	_lbl(vbox, "Choose What To Give Up", 30, FG, true)
	_space(vbox, 8)
	var incoming_name := str(incoming_boon.get("name", "new boon"))
	var lane_label := lane.capitalize()
	_lbl(vbox, "%s boons are limited to %d. Take %s by replacing one below." % [lane_label, BoonSystem.boon_lane_limit(lane), incoming_name], 13, DIM, true)
	_space(vbox, 18)

	var row := _hbox(vbox)
	row.add_theme_constant_override("separation", 14)
	for old_boon: Dictionary in existing:
		var rd: Dictionary = BoonSystem.RARITIES.get(old_boon.get("rarity", "common"), {})
		var col: Color = rd.get("color", Color.WHITE)
		var card := _boon_card(old_boon, col)
		card.custom_minimum_size = Vector2(240, 320)
		card.pressed.connect(_accept_boon.bind(incoming_boon, str(old_boon.get("id", ""))))
		row.add_child(card)

	_space(vbox, 16)
	var keep := _btn("Keep current boons", DIM)
	keep.custom_minimum_size = Vector2(240, 44)
	keep.pressed.connect(func() -> void: _show_boon_pick(_gs.pending_boon_offers))
	vbox.add_child(keep)

func _on_boon_skip() -> void:
	if _gs: _gs.pending_boon_offers.clear()
	if _gs and _gs.active_run: _complete_current_node_with_loadout_xp("boon_pick")
	_apply_between_battle_heal()
	if _boon_overlay: _boon_overlay.queue_free(); _boon_overlay = null
	_build_ui()

## Apply Swift Recovery and other between-battle heals from boons.
func _apply_between_battle_heal() -> void:
	if not _gs or not _gs.active_run: return
	var bonuses := RunBonuses.for_current_run()
	var pct: float = bonuses.get("between_battle_heal", 0.0)
	if pct <= 0.0: return
	var gs: Node = get_node_or_null("/root/GameState")
	if not gs: return
	var total_healed := 0
	for uid in gs.unit_registry:
		var reg: Dictionary = gs.unit_registry[uid]
		var max_hp: int = reg.get("base_hp", 200)
		var heal: int   = int(float(max_hp) * pct)
		if heal > 0:
			var current: int = int(reg.get("current_hp", max_hp))
			var next_hp: int = min(max_hp, current + heal)
			total_healed += maxi(0, next_hp - current)
			reg["current_hp"] = next_hp
	_record_healing_applied("between_battle_boon", total_healed)


func _record_healing_applied(source: String, amount: int) -> void:
	if not _gs or amount <= 0:
		return
	var healing: Array = _gs.pending_rewards.get("healing_applied", [])
	healing.append({"source": source, "amount": amount})
	_gs.pending_rewards["healing_applied"] = healing

func _on_loot_continue() -> void:
	if _gs: _gs.pending_loot.clear()
	if _loot_overlay: _loot_overlay.queue_free(); _loot_overlay = null
	_build_ui()


#  Gear management overlay

## Opens the Party Gear overlay showing each deployed unit's equipped items.
## Reuses _loot_overlay so Gear and Loot panels are mutually exclusive.
func _show_gear_panel() -> void:
	if not _gs or not _gs.active_run: return
	if _loot_overlay: _loot_overlay.queue_free()
	_loot_overlay = _overlay()
	add_child(_loot_overlay)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_loot_overlay.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(820, 0)
	vbox.add_theme_constant_override("separation", 0)
	center.add_child(vbox)

	_space(vbox, 28)
	_lbl(vbox, "PARTY GEAR", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "Equipment", 30, FG, true)
	_space(vbox, 18)

	# Gather deployed unit ids from run_deployment
	var party_ids: Array[String] = []
	for slot: Dictionary in _gs.active_run.run_deployment:
		var uid: String = str(slot.get("unit_id", ""))
		if uid != "" and uid not in party_ids:
			party_ids.append(uid)

	var chars_node := get_node_or_null("/root/Characters")

	if party_ids.is_empty():
		_lbl(vbox, "No party deployed. Start a battle to assign a formation.", 14, DIM, true)
	else:
		for uid: String in party_ids:
			vbox.add_child(_unit_gear_card(uid, chars_node))
			_space(vbox, 10)

	# — Stash footer ——————————————————————————————
	_space(vbox, 8)
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(1.0, 1.0, 1.0, 0.08))
	vbox.add_child(sep)
	_space(vbox, 12)

	var stash_count: int = _gs.pending_loot.size()
	var stash_row := HBoxContainer.new()
	stash_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stash_row.add_theme_constant_override("separation", 16)
	vbox.add_child(stash_row)

	_lbl(stash_row, "%d item%s in stash" % [stash_count, "s" if stash_count != 1 else ""], 14, DIM)
	if stash_count > 0:
		var stash_btn := _btn("View Stash  →", GOLD)
		stash_btn.custom_minimum_size = Vector2(160, 36)
		stash_btn.pressed.connect(func() -> void: _show_loot(_gs.pending_loot))
		stash_row.add_child(stash_btn)

	_space(vbox, 16)
	var close_btn := _btn("Close", DIM)
	close_btn.custom_minimum_size = Vector2(160, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void:
		if _loot_overlay: _loot_overlay.queue_free(); _loot_overlay = null)
	vbox.add_child(close_btn)
	_space(vbox, 28)


## Builds one unit's gear card — name header + one row per slot.
func _unit_gear_card(uid: String, chars_node: Node) -> PanelContainer:
	var reg: Dictionary       = _gs.unit_registry.get(uid, {}) if _gs else {}
	var equipment: Dictionary = reg.get("equipment", {})

	var display_name: String = uid
	if chars_node and chars_node.CHARACTERS.has(uid):
		display_name = str(chars_node.CHARACTERS[uid].get("human_name", uid))

	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_st := StyleBoxFlat.new()
	card_st.bg_color = Color(0.06, 0.07, 0.10)
	card_st.border_color = Color(1.0, 1.0, 1.0, 0.08)
	card_st.set_border_width_all(1)
	card_st.set_corner_radius_all(8)
	card_st.content_margin_left   = 20
	card_st.content_margin_right  = 20
	card_st.content_margin_top    = 14
	card_st.content_margin_bottom = 14
	pc.add_theme_stylebox_override("panel", card_st)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	pc.add_child(inner)

	_lbl(inner, display_name.to_upper(), 14, FG)

	for slot_id: String in ["weapon", "accessory", "charm"]:
		inner.add_child(_slot_row(uid, slot_id, equipment.get(slot_id, {})))

	return pc


## One slot row: SLOT | item name + affixes | [Unequip] button.
func _slot_row(uid: String, slot_id: String, item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	# Slot label — fixed 88 px so all slots align across units.
	var slot_lbl := Label.new()
	slot_lbl.text = slot_id.to_upper()
	slot_lbl.custom_minimum_size = Vector2(88, 0)
	slot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	slot_lbl.add_theme_font_size_override("font_size", 10)
	slot_lbl.add_theme_color_override("font_color", DIM)
	row.add_child(slot_lbl)

	# Item info — expands to fill remaining width.
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	if item.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "— Empty —"
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", Color(DIM.r, DIM.g, DIM.b, 0.50))
		info.add_child(empty_lbl)
	else:
		var accent: Color = item.get("color", FG)
		var name_lbl := Label.new()
		name_lbl.text = "%s  [%s]" % [item.get("name", "?"), item.get("label", "")]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", accent)
		info.add_child(name_lbl)
		for affix: Dictionary in item.get("affixes", []):
			var al := Label.new()
			al.text = "· %s" % affix.get("label", "")
			al.add_theme_font_size_override("font_size", 11)
			al.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68))
			info.add_child(al)

		# Unequip button — right-aligned, vertically centred.
		var unequip_btn := _btn("Unequip", DIM)
		unequip_btn.custom_minimum_size = Vector2(90, 30)
		unequip_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Capture loop values for the closure.
		var cap_uid  := uid
		var cap_slot := slot_id
		var cap_item := item
		unequip_btn.pressed.connect(func() -> void:
			_on_unequip_item(cap_uid, cap_slot, cap_item))
		row.add_child(unequip_btn)

	return row


## Remove an item from a unit's equipment slot and return it to the stash,
## then rebuild the gear panel so the change is immediately visible.
func _on_unequip_item(uid: String, slot_id: String, item: Dictionary) -> void:
	if not _gs: return
	if _gs.unit_registry.has(uid):
		var eq: Dictionary = _gs.unit_registry[uid].get("equipment", {})
		eq.erase(slot_id)
		_gs.unit_registry[uid]["equipment"] = eq
	_gs.pending_loot.append(item)
	_show_gear_panel()


#  Boon pick overlay

func _show_boon_pick(offers: Array) -> void:
	if _boon_overlay: _boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)

	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(900, 0)

	var pick_eyebrow := Label.new()
	pick_eyebrow.text = "CHOOSE A BOON"
	pick_eyebrow.add_theme_font_override("font", _FONT_HEADER)
	pick_eyebrow.add_theme_font_size_override("font_size", 11)
	pick_eyebrow.add_theme_color_override("font_color", DIM)
	pick_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(pick_eyebrow)
	_space(vbox, 6)
	var pick_title := Label.new()
	pick_title.text = "Power grows with every choice."
	pick_title.add_theme_font_override("font", _FONT_DISPLAY)
	pick_title.add_theme_font_size_override("font_size", 26)
	pick_title.add_theme_color_override("font_color", FG)
	pick_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(pick_title)
	_space(vbox, 20)

	var hbox := _hbox(vbox)
	hbox.add_theme_constant_override("separation", 16)

	for boon in offers:
		var rd: Dictionary = BoonSystem.RARITIES.get(boon.get("rarity","common"), {})
		var col: Color = rd.get("color", Color.WHITE)
		var card := _boon_card(boon, col)
		card.pressed.connect(_on_boon_picked.bind(boon))
		hbox.add_child(card)

	_space(vbox, 16)

	#  Curse offer (Returnal-style tradeoff)
	if _gs and _gs.active_run:
		var cs := CurseSystem.new()
		var owned_curse_ids: Array = _gs.active_run.active_curses.map(
			func(c: Dictionary) -> String: return c.get("id",""))
		var curse_offer := cs.generate_curse_offer(
			_gs.active_run.seed + _gs.active_run.current_node * 31,
			_gs.active_run.current_floor, owned_curse_ids)
		if not curse_offer.is_empty():
			var divider := HSeparator.new()
			vbox.add_child(divider)
			_space(vbox, 8)
			_lbl(vbox, "-- OR ACCEPT A CURSE --", 11, Color(0.65,0.25,0.25), true)
			_space(vbox, 8)
			vbox.add_child(_curse_card(curse_offer))

	_space(vbox, 10)
	var skip := _btn("Decline all", DIM)
	skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip.pressed.connect(_on_boon_skip)
	vbox.add_child(skip)


func _boon_card(boon: Dictionary, accent: Color) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(280, 360)
	_style_card(btn, accent)

	var top_bar := ColorRect.new()
	top_bar.color = accent.lerp(Color.TRANSPARENT, 0.45)
	top_bar.custom_minimum_size = Vector2(0, 3)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	btn.add_child(top_bar)

	var inner := _vbox(btn, true)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left",   20)
	inner.add_theme_constant_override("margin_right",  20)
	inner.add_theme_constant_override("margin_top",    16)
	inner.add_theme_constant_override("margin_bottom", 16)
	inner.add_theme_constant_override("separation",     6)

	var rarity_lbl := Label.new()
	rarity_lbl.text = boon.get("rarity","?").to_upper()
	rarity_lbl.add_theme_font_override("font", _FONT_HEADER)
	rarity_lbl.add_theme_font_size_override("font_size", 10)
	rarity_lbl.add_theme_color_override("font_color", accent)
	rarity_lbl.add_theme_constant_override("outline_size", 0)
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(rarity_lbl)

	var icon_ctrl := _boon_icon_widget(
		str(boon.get("id","")), str(boon.get("icon","+")), accent)
	inner.add_child(icon_ctrl)

	var name_lbl := Label.new()
	name_lbl.text = str(boon.get("name","?")).to_upper()
	name_lbl.add_theme_font_override("font", _FONT_DISPLAY)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", FG)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(name_lbl)

	var guardian: String = str(boon.get("guardian",""))
	if not guardian.is_empty():
		var g_lbl := Label.new()
		g_lbl.text = _guardian_label(guardian)
		g_lbl.add_theme_font_override("font", _FONT_UI)
		g_lbl.add_theme_font_size_override("font_size", 10)
		g_lbl.add_theme_color_override("font_color", accent.lerp(FG, 0.5))
		g_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(g_lbl)

	_space(inner, 4)

	var desc := RichTextLabel.new()
	desc.bbcode_enabled = false
	desc.text = str(boon.get("desc",""))
	desc.add_theme_font_override("normal_font", _FONT_BODY)
	desc.add_theme_font_size_override("normal_font_size", 12)
	desc.add_theme_color_override("default_color", Color(0.86, 0.83, 0.77))
	desc.custom_minimum_size = Vector2(0, 72)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(desc)

	var impact := _boon_impact_text(boon)
	if not impact.is_empty():
		var sep := HSeparator.new()
		var sep_st := StyleBoxFlat.new()
		sep_st.bg_color = accent.lerp(Color.TRANSPARENT, 0.7)
		sep.add_theme_stylebox_override("separator", sep_st)
		inner.add_child(sep)
		var impact_lbl := Label.new()
		impact_lbl.text = "NEXT FIGHT: " + impact
		impact_lbl.add_theme_font_override("font", _FONT_UI)
		impact_lbl.add_theme_font_size_override("font_size", 11)
		impact_lbl.add_theme_color_override("font_color", accent.lerp(Color.WHITE, 0.3))
		impact_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(impact_lbl)

	var flavour: String = str(boon.get("flavour",""))
	if not flavour.is_empty():
		_space(inner, 4)
		var fl := RichTextLabel.new()
		fl.bbcode_enabled = false
		fl.text = '"%s"' % flavour
		fl.add_theme_font_override("normal_font", _FONT_BODY)
		fl.add_theme_font_size_override("normal_font_size", 10)
		fl.add_theme_color_override("default_color", Color(0.42, 0.39, 0.34))
		fl.custom_minimum_size = Vector2(0, 52)
		fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(fl)

	return btn


#  Loot overlay

func _boon_impact_text(boon: Dictionary) -> String:
	var fx: Dictionary = boon.get("effect", {})
	match fx.get("type", ""):
		"stat_bonus":
			var parts: Array[String] = []
			if fx.get("stat", "") in ["move", "movement"]:
				parts.append("party gains +%d Move" % int(fx.get("amount", 0)))
			if fx.get("stat", "") in ["temper", "max_temper"]:
				parts.append("party gains +%d Temper" % int(fx.get("amount", 0)))
			if int(fx.get("move_bonus", 0)) != 0:
				parts.append("party gains +%d Move" % int(fx.get("move_bonus", 0)))
			return ", ".join(parts)
		"elemental_bonus", "elemental_damage_bonus":
			var el := str(fx.get("element", "elemental")).capitalize()
			var pct := int(round(float(fx.get("bonus", 0.0)) * 100.0))
			if int(fx.get("heal_bonus", 0)) > 0:
				return "%s +%d%% damage, heals +%d HP" % [el, pct, int(fx.get("heal_bonus", 0))]
			return "%s +%d%% damage" % [el, pct]
		"between_battle_heal":
			return "after battles, party restores %d%% HP" % int(round(float(fx.get("percent", 0.0)) * 100.0))
		"jp_multiplier":
			return "JP gains are x%.1f" % float(fx.get("mult", 1.0))
		"reaction_echo":
			return "%d%% chance for elemental reactions to trigger twice" % int(round(float(fx.get("chance", 0.0)) * 100.0))
		"once_per_battle":
			if fx.get("outcome", "") == "survive_at_1_hp":
				return "first 0-HP party member survives at 1 HP once per battle"
		"on_elite_kill":
			return "elite kills heal %d HP and %d Temper" % [int(fx.get("heal_hp", 0)), int(fx.get("heal_temper", 0))]
		"battle_start":
			if fx.get("trigger", "") == "vaelthorn_bargain":
				return "party trades HP for +%d%% damage" % int(round(float(fx.get("damage_bonus", 0.0)) * 100.0))
			if fx.get("trigger", "") in ["ignite_all_terrain", "ignite_all"]:
				return "the battlefield starts burning"
			if fx.get("trigger", "") == "summon_tide":
				return "water rises in the center of the map"
			if fx.get("trigger", "") in ["vaelthorn_curse_all", "curse_all"]:
				return "all enemies start cursed"
		"passive":
			match fx.get("id", ""):
				"brand": return "burning enemies take +%d%% physical damage" % int(round(float(fx.get("bonus", 0.0)) * 100.0))
				"double_strike": return "basic attacks can strike twice"
				"first_hit_guard": return "first lethal hit leaves the unit at 1 HP"
				"luminarch_covenant": return "single hits cannot drop party below 1 HP"
				"death_flare": return "enemy deaths splash holy damage"
		"tactical":
			match fx.get("id", ""):
				"cleave":
					return "every attack also hits the two tiles flanking target"
				"piercing_line":
					return "attacks pierce through to the unit standing directly behind target"
				"knockback":
					return "%d%% chance to push target 1 tile away on hit" % int(fx.get("chance", 0.0) * 100.0)
				"echo_strike":
					return "%d%% chance to strike the same target a second time" % int(fx.get("chance", 0.0) * 100.0)
				"battle_fury":
					return "+%d%% damage when you moved before attacking this turn" % int(fx.get("bonus", 0.0) * 100.0)
				"coup_de_grace":
					return "+%d%% damage vs enemies below %d%% HP" % [
						int(fx.get("bonus", 0.0) * 100.0),
						int(fx.get("threshold", 0.0) * 100.0)]
				"sundering":
					return "each hit permanently reduces target's max Temper by %d" % int(fx.get("amount", 0))
				"bloodthirst":
					return "recover %d%% of all damage dealt as HP" % int(fx.get("percent", 0.0) * 100.0)
				"ruinous_field":
					return "every %d hits ignites the ground under your target" % int(fx.get("interval", 3))
				"reaping_step":
					return "kills grant a free %d-tile move toward the next enemy" % int(fx.get("range", 3))
				"iron_momentum":
					return "+30%% damage when moving %d+ tiles before attacking" % int(fx.get("min_move", 3))
				"wrath_crescendo":
					return "+%d%% damage per kill this battle (stacks up to x10)" % int(fx.get("per_kill", 0.0) * 100.0)
	return ""
func _curse_card(curse: Dictionary) -> Button:
	var accent := Color(0.92, 0.24, 0.24)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(620, 190)
	_style_card(btn, accent)

	# Crimson top stripe
	var top_bar := ColorRect.new()
	top_bar.color = accent.lerp(Color.TRANSPARENT, 0.55)
	top_bar.custom_minimum_size = Vector2(0, 3)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	btn.add_child(top_bar)

	var inner := _vbox(btn, false)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left",   20)
	inner.add_theme_constant_override("margin_right",  20)
	inner.add_theme_constant_override("margin_top",    14)
	inner.add_theme_constant_override("margin_bottom", 14)
	inner.add_theme_constant_override("separation",     5)

	var eyebrow := Label.new()
	eyebrow.text = "CURSE TRADE"
	eyebrow.add_theme_font_override("font", _FONT_HEADER)
	eyebrow.add_theme_font_size_override("font_size", 10)
	eyebrow.add_theme_color_override("font_color", accent)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(eyebrow)

	var name_lbl := Label.new()
	name_lbl.text = "%s  %s" % [str(curse.get("icon","!")), str(curse.get("name","?")).to_upper()]
	name_lbl.add_theme_font_override("font", _FONT_DISPLAY)
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", FG)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(name_lbl)

	_space(inner, 6)

	var penalty_lbl := Label.new()
	penalty_lbl.text = "PENALTY - %s" % str(curse.get("penalty",""))
	penalty_lbl.add_theme_font_override("font", _FONT_UI)
	penalty_lbl.add_theme_font_size_override("font_size", 11)
	penalty_lbl.add_theme_color_override("font_color", Color(1.0, 0.66, 0.62))
	penalty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(penalty_lbl)

	var unlock_lbl := Label.new()
	unlock_lbl.text = "REWARD - %s" % str(curse.get("unlock",""))
	unlock_lbl.add_theme_font_override("font", _FONT_UI)
	unlock_lbl.add_theme_font_size_override("font_size", 11)
	unlock_lbl.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
	unlock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(unlock_lbl)

	btn.pressed.connect(_on_curse_picked.bind(curse))
	return btn


func _on_curse_picked(curse: Dictionary) -> void:
	if _gs and _gs.active_run:
		_gs.active_run.active_curses.append(curse)
	if _gs:
		_gs.pending_boon_offers.clear()
	if _gs and _gs.active_run:
		_complete_current_node_with_loadout_xp("boon_pick")
	_apply_between_battle_heal()
	if _boon_overlay:
		_boon_overlay.queue_free()
		_boon_overlay = null
	_build_ui()


func _show_wanderer_encounter(run: RunState) -> void:
	if not run:
		return
	var floor_num: int = int(run.current_floor)

	# Pick a wanderer for this floor, excluding those already met this run.
	var met_ids: Array = []
	if _gs:
		for flag: String in _gs.story_flags:
			if flag.begins_with("met_wanderer_"):
				met_ids.append(flag.substr("met_wanderer_".length()))
	var rng_val: float = fmod(float(run.seed * 13 + floor_num * 7 + run.current_node), 1000.0) / 1000.0
	var wanderer: Dictionary = WandererData.get_for_floor(floor_num, rng_val, met_ids)
	if wanderer.is_empty():
		wanderer = WandererData.WANDERERS[0]

	if _boon_overlay:
		_boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)

	var accent: Color = _wanderer_element_color(str(wanderer.get("element", "")))
	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(800, 0)

	_lbl(vbox, "STORY ENCOUNTER", 11, accent, true)
	_space(vbox, 6)
	_lbl(vbox, str(wanderer.get("name", "Wanderer")), 30, FG, true)
	_lbl(vbox, str(wanderer.get("title", "")), 13, DIM, true)
	_space(vbox, 12)

	var story := RichTextLabel.new()
	story.bbcode_enabled = false
	story.text = str(wanderer.get("greeting", "..."))
	story.add_theme_font_size_override("normal_font_size", 13)
	story.add_theme_color_override("default_color", Color(0.82, 0.80, 0.76))
	story.custom_minimum_size = Vector2(760, 80)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(story)
	_space(vbox, 16)

	# --- Determine payment branch ---
	var cond: Dictionary = wanderer.get("condition", {})
	var cond_type: String = str(cond.get("type", "pay"))
	var gold_cost: int = int(cond.get("cost", 80))
	var current_gold: int = int(_gs.gold) if _gs else 0
	var pay_ok: bool = cond_type == "free" or current_gold >= gold_cost
	var pay_cost_str: String = "Free" if cond_type == "free" else "%dg" % gold_cost
	var pay_card_title: String = str(cond.get("label", "Pay %s" % pay_cost_str))
	var pay_body: String = str(wanderer.get("accept_msg", "The wanderer shares what they know."))
	if cond_type not in ["pay", "free"]:
		gold_cost = 80
		pay_cost_str = "80g"
		pay_card_title = "Offer Payment (80g)"
		pay_ok = current_gold >= 80
		pay_body = "Offer gold as a show of good faith."

	# --- Determine challenge branch ---
	var alt_cond: Dictionary = wanderer.get("alt_condition", {})
	var alt_type: String = str(alt_cond.get("type", "")) if not alt_cond.is_empty() else ""
	var challenge_damage: int = floor_num * 15 + 20
	var chal_ok := true
	var chal_card_title: String
	var chal_cost_str: String
	var chal_body: String
	if alt_type in ["challenge", "duel"]:
		chal_card_title = str(alt_cond.get("label", "Accept the duel"))
		chal_cost_str   = "-%d HP per unit" % challenge_damage
		chal_body       = "Face the wanderer directly. No gold changes hands — only blood."
	elif alt_type == "answer":
		chal_card_title = str(alt_cond.get("label", "Answer correctly"))
		chal_cost_str   = "Free"
		chal_body       = str(alt_cond.get("question", "Answer their question to receive the reward."))
		challenge_damage = 0
	elif alt_type == "party_full_hp":
		chal_card_title = str(alt_cond.get("label", "Arrive at full HP"))
		chal_cost_str   = "Party must be at full HP"
		chal_body       = "The wanderer teaches only those who arrive unblemished."
		challenge_damage = 0
		if _gs:
			for uid in _gs.unit_registry:
				var reg: Dictionary = _gs.unit_registry[uid]
				if int(reg.get("current_hp", 0)) < int(reg.get("base_hp", reg.get("max_hp", 200))):
					chal_ok = false
					break
	else:
		chal_card_title = "Prove Yourself"
		chal_cost_str   = "-%d HP per unit" % challenge_damage
		chal_body       = "Endure a trial by hardship. The wanderer respects those who survive."

	# --- Build service cards ---
	var cards_row := _hbox(vbox)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 16)

	var btn_pay := _town_service_card(cards_row,
		pay_card_title, pay_body, pay_cost_str,
		accent if pay_ok else DIM)
	btn_pay.text = "Accept"
	btn_pay.disabled = not pay_ok

	var btn_chal := _town_service_card(cards_row,
		chal_card_title, chal_body, chal_cost_str,
		Color(0.96, 0.78, 0.28) if chal_ok else DIM)
	btn_chal.text = "Challenge"
	btn_chal.disabled = not chal_ok

	# Connect after both are declared so each lambda can reference the other.
	btn_pay.pressed.connect(func() -> void:
		btn_pay.disabled = true
		btn_chal.disabled = true
		if cond_type == "pay" and _gs:
			_gs.gold -= gold_cost
		_wanderer_mark_met(wanderer)
		_wanderer_show_gift(vbox, wanderer, floor_num))

	btn_chal.pressed.connect(func() -> void:
		btn_pay.disabled = true
		btn_chal.disabled = true
		if challenge_damage > 0 and _gs:
			for uid in _gs.unit_registry:
				var reg: Dictionary = _gs.unit_registry[uid]
				reg["current_hp"] = maxi(1, int(reg.get("current_hp", 0)) - challenge_damage)
		_wanderer_mark_met(wanderer)
		_wanderer_show_gift(vbox, wanderer, floor_num))

	_space(vbox, 18)
	var decline := _btn("Decline", DIM)
	decline.custom_minimum_size = Vector2(160, 40)
	decline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	decline.pressed.connect(func() -> void:
		_wanderer_mark_met(wanderer)
		_complete_current_node_with_loadout_xp("wanderer")
		if _gs: _gs.save()
		if _boon_overlay: _boon_overlay.queue_free(); _boon_overlay = null
		_build_ui())
	vbox.add_child(decline)


func _wanderer_mark_met(wanderer: Dictionary) -> void:
	if not _gs:
		return
	var flag := "met_wanderer_%s" % str(wanderer.get("id", "unknown"))
	if not _gs.story_flags.has(flag):
		_gs.story_flags.append(flag)


func _wanderer_element_color(element: String) -> Color:
	match element:
		"fire":      return Color(0.96, 0.45, 0.20)
		"holy":      return Color(0.97, 0.93, 0.68)
		"dark":      return Color(0.72, 0.30, 0.86)
		"thunder":   return Color(0.94, 0.90, 0.20)
		"water":     return Color(0.28, 0.74, 0.96)
		"resonance": return Color(0.55, 0.92, 0.72)
		_:           return GOLD


func _wanderer_show_gift(parent: Control, wanderer: Dictionary, floor_num: int) -> void:
	if not _gs or not _gs.active_run:
		return
	var owned: Array = _gs.active_run.active_boons.map(
		func(b: Dictionary) -> String: return b.get("id", ""))
	var offers := _bs.generate_offers(
		_gs.active_run.seed * 43 + floor_num * 11 + _gs.active_run.current_node + 5555,
		floor_num, owned, _gs.active_run.get_loadout_bonus())

	_space(parent, 18)
	var reward_msg: String = str(wanderer.get("reward_msg", '"A reward for your efforts." [Grants a Guardian boon]'))
	_lbl(parent, reward_msg, 13, Color(0.82, 0.80, 0.76), true)
	_space(parent, 12)
	_lbl(parent, "CHOOSE YOUR REWARD", 11, GOLD, true)
	_space(parent, 8)

	var row := _hbox(parent)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)

	var gift_btns: Array[Button] = []
	for boon: Dictionary in offers:
		var rd: Dictionary = BoonSystem.RARITIES.get(boon.get("rarity", "common"), {})
		var bc: Color = rd.get("color", GOLD)
		var boon_copy := boon
		var offer_btn := Button.new()
		offer_btn.custom_minimum_size = Vector2(220, 80)
		offer_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var st := StyleBoxFlat.new()
		st.bg_color     = Color(bc.r * 0.10, bc.g * 0.10, bc.b * 0.10, 0.92)
		st.border_color = bc.lerp(Color.TRANSPARENT, 0.30)
		st.set_border_width_all(1)
		st.content_margin_left = 14; st.content_margin_right  = 14
		st.content_margin_top  = 10; st.content_margin_bottom = 10
		offer_btn.add_theme_stylebox_override("normal", st)
		offer_btn.add_theme_stylebox_override("hover",  st)
		offer_btn.add_theme_color_override("font_color", bc)
		offer_btn.add_theme_font_size_override("font_size", 13)
		offer_btn.text = "%s %s  [%s]" % [
			str(boon_copy.get("icon", "+")),
			str(boon_copy.get("name", "?")),
			str(boon_copy.get("rarity", "common")).capitalize()
		]
		offer_btn.pressed.connect(func() -> void:
			_oracle_accept_boon(boon_copy)
			_complete_current_node_with_loadout_xp("wanderer")
			if _gs: _gs.save()
			for b: Button in gift_btns: b.disabled = true
			if _boon_overlay: _boon_overlay.queue_free(); _boon_overlay = null
			_build_ui())
		gift_btns.append(offer_btn)
		row.add_child(offer_btn)

	_space(parent, 12)
	var jp_alt := _btn("Take JP Instead  (+%d JP)" % _wanderer_jp_reward(), DIM)
	jp_alt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	jp_alt.pressed.connect(func() -> void:
		_grant_party_jp(_wanderer_jp_reward())
		_complete_current_node_with_loadout_xp("wanderer")
		if _gs: _gs.save()
		for b: Button in gift_btns: b.disabled = true
		jp_alt.disabled = true
		if _boon_overlay: _boon_overlay.queue_free(); _boon_overlay = null
		_build_ui())
	parent.add_child(jp_alt)


func _wanderer_jp_reward() -> int:
	return 18 + int(_gs.active_run.current_floor) * 5 if _gs and _gs.active_run else 24

func _show_loot(items: Array) -> void:
	if _loot_overlay: _loot_overlay.queue_free()
	_loot_overlay = _overlay()
	add_child(_loot_overlay)

	# Scrollable centre column — wider to fit item cards + buttons.
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_loot_overlay.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(960, 0)
	vbox.add_theme_constant_override("separation", 0)
	center.add_child(vbox)

	# — Header ——————————————————————————————————
	_space(vbox, 28)
	_lbl(vbox, "BATTLE COMPLETE", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "Loot Claim", 30, FG, true)
	_space(vbox, 14)

	# — Rewards summary ——————————————————————————
	if _gs and not _gs.pending_rewards.is_empty():
		var pr: Dictionary = _gs.pending_rewards
		var gold_n: int = pr.get("gold", 0)
		var jp_n:   int = pr.get("jp",   0)
		if gold_n > 0 or jp_n > 0:
			var reward_row := HBoxContainer.new()
			reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
			reward_row.add_theme_constant_override("separation", 24)
			vbox.add_child(reward_row)
			if gold_n > 0:
				_lbl(reward_row, "+%dg Gold" % gold_n, 17, GOLD)
			if jp_n > 0:
				_lbl(reward_row, "+%d JP" % jp_n, 17, TEAL)
			_space(vbox, 10)

	# — Item count ————————————————————————————————
	_lbl(vbox, "%d item%s found." % [items.size(), "s" if items.size() != 1 else ""], 15, DIM, true)
	_space(vbox, 18)

	# — Item cards ————————————————————————————————
	if items.size() > 0:
		var cards_row := HBoxContainer.new()
		cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
		cards_row.add_theme_constant_override("separation", 14)
		vbox.add_child(cards_row)
		for item: Dictionary in items:
			cards_row.add_child(_item_card(item))
	else:
		_lbl(vbox, "The enemies carried nothing of value.", 14, DIM, true)

	# — Done button ———————————————————————————————
	_space(vbox, 24)
	var cont := _btn("Done  →", GOLD)
	cont.custom_minimum_size = Vector2(200, 48)
	cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cont.pressed.connect(_on_loot_continue)
	vbox.add_child(cont)
	_space(vbox, 24)


## Builds one item card.  When pending_loot contains the item, Equip and Sell
## buttons are shown.  If the item was already sold/equipped it is greyed out.
func _item_card(item: Dictionary) -> PanelContainer:
	var is_pending: bool = _gs != null and _gs.pending_loot.has(item)
	var accent: Color = item.get("color", Color.WHITE)

	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(200, 0)
	_style_panel(pc, accent if is_pending else DIM)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("margin_left",  14)
	inner.add_theme_constant_override("margin_right", 14)
	inner.add_theme_constant_override("margin_top",   14)
	inner.add_theme_constant_override("margin_bottom",14)
	inner.add_theme_constant_override("separation",    5)
	pc.add_child(inner)

	var label_col: Color = accent if is_pending else DIM
	_lbl(inner, item.get("label","").to_upper(), 9, label_col, false)
	_lbl(inner, item.get("icon",""), 28, FG if is_pending else DIM, true)
	_lbl(inner, item.get("name","?"), 13, FG if is_pending else DIM, true)
	_lbl(inner, item.get("slot","").to_upper(), 9, DIM, true)
	_space(inner, 4)
	for affix: Dictionary in item.get("affixes", []):
		_lbl(inner, "- " + affix.get("label",""), 11,
			Color(0.85, 0.82, 0.77) if is_pending else DIM, false)

	_space(inner, 8)

	if is_pending:
		# Sell value hint
		var rarity: String = item.get("rarity", "common")
		var sell_price: int = SELL_VALUES.get(rarity, 10)
		_lbl(inner, "Sell: %dg" % sell_price, 10, DIM, true)
		_space(inner, 4)

		# Action buttons
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 6)
		btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.add_child(btn_row)

		var equip_btn := _btn("Equip", TEAL)
		equip_btn.custom_minimum_size = Vector2(80, 30)
		equip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		equip_btn.pressed.connect(func() -> void: _on_equip_item(item))
		btn_row.add_child(equip_btn)

		var sell_btn := _btn("Sell", GOLD)
		sell_btn.custom_minimum_size = Vector2(64, 30)
		sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sell_btn.pressed.connect(func() -> void: _on_sell_item(item))
		btn_row.add_child(sell_btn)
	else:
		_lbl(inner, "EQUIPPED", 10, TEAL, true)

	return pc


## Sell: award gold, remove from pending_loot, rebuild the overlay.
func _on_sell_item(item: Dictionary) -> void:
	if not _gs: return
	var rarity: String = item.get("rarity", "common")
	_gs.gold += SELL_VALUES.get(rarity, 10)
	_gs.pending_loot.erase(item)
	_show_loot(_gs.pending_loot)


## Equip: open the unit-picker popup so the player chooses who wears the item.
func _on_equip_item(item: Dictionary) -> void:
	_show_unit_picker(item)


## Unit picker — a small modal listing deployed party members.
## Clicking a unit assigns item → unit_registry[uid]["equipment"][slot] and
## removes the item from pending_loot, then rebuilds the loot overlay.
func _show_unit_picker(item: Dictionary) -> void:
	# Gather deployed unit ids from run_deployment; fall back to PARTY_ORDER.
	var party_ids: Array[String] = []
	if _gs and _gs.active_run:
		for slot: Dictionary in _gs.active_run.run_deployment:
			var uid: String = str(slot.get("unit_id",""))
			if uid != "" and uid not in party_ids:
				party_ids.append(uid)
	if party_ids.is_empty() and _gs:
		for uid: String in _gs.unit_registry.keys():
			if uid not in party_ids:
				party_ids.append(uid)
			if party_ids.size() >= 4:
				break

	if party_ids.is_empty():
		# No party data — equip without unit binding.
		_gs.pending_loot.erase(item)
		_show_loot(_gs.pending_loot)
		return

	# Build picker overlay.
	var picker := PanelContainer.new()
	picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim_st := StyleBoxFlat.new(); dim_st.bg_color = Color(0.0, 0.0, 0.0, 0.72)
	picker.add_theme_stylebox_override("panel", dim_st)
	add_child(picker)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picker.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(380, 0)
	_style_panel(card, item.get("color", TEAL))
	center.add_child(card)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("margin_left",  24)
	inner.add_theme_constant_override("margin_right", 24)
	inner.add_theme_constant_override("margin_top",   22)
	inner.add_theme_constant_override("margin_bottom",22)
	inner.add_theme_constant_override("separation",   10)
	card.add_child(inner)

	_lbl(inner, "EQUIP TO UNIT", 10, DIM, true)
	_space(inner, 2)
	_lbl(inner, item.get("name", "?"), 16, FG, true)
	_lbl(inner, item.get("slot","").to_upper(), 10, item.get("color", TEAL), true)
	_space(inner, 8)

	var chars_node := get_node_or_null("/root/Characters")

	for uid: String in party_ids:
		var reg: Dictionary = _gs.unit_registry.get(uid, {}) if _gs else {}
		var display_name: String = uid
		if chars_node and chars_node.CHARACTERS.has(uid):
			display_name = str(chars_node.CHARACTERS[uid].get("human_name", uid))
		var current_item: Dictionary = reg.get("equipment", {}).get(item.get("slot",""), {})
		var btn_label: String = display_name
		if not current_item.is_empty():
			btn_label += "  (replaces %s)" % current_item.get("name","?")
		var uid_btn := _btn(btn_label, FG)
		uid_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		uid_btn.custom_minimum_size = Vector2(0, 38)
		var captured_uid := uid
		uid_btn.pressed.connect(func() -> void:
			if _gs and _gs.unit_registry.has(captured_uid):
				if not _gs.unit_registry[captured_uid].has("equipment"):
					_gs.unit_registry[captured_uid]["equipment"] = {}
				_gs.unit_registry[captured_uid]["equipment"][item.get("slot","")] = item
			if _gs: _gs.pending_loot.erase(item)
			picker.queue_free()
			_show_loot(_gs.pending_loot if _gs else []))
		inner.add_child(uid_btn)

	_space(inner, 4)
	var cancel_btn := _btn("Cancel", DIM)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.custom_minimum_size = Vector2(120, 36)
	cancel_btn.pressed.connect(func() -> void: picker.queue_free())
	inner.add_child(cancel_btn)


#  Widget helpers

func _lbl(parent: Control, text: String, font_size: int, color: Color, centered: bool = false) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if centered: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l); return l

func _lbl_widget(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _space(parent: Control, h: int = 8) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(0, h); parent.add_child(s)

func _gap(parent: Control, w: int = 8) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(w, 0); parent.add_child(s)

func _stretch(parent: Control) -> void:
	var s := Control.new(); s.size_flags_horizontal = Control.SIZE_EXPAND_FILL; parent.add_child(s)

func _vbox(parent: Control, centered: bool = false) -> VBoxContainer:
	var v := VBoxContainer.new()
	if centered: v.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(v); return v

func _hbox(parent: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	parent.add_child(h); return h

func _bg(parent: Control) -> void:
	var rect := ColorRect.new(); rect.color = BG
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.z_index = -1; parent.add_child(rect)

func _btn(text: String, color: Color) -> Button:
	var btn := Button.new(); btn.text = text
	var st := StyleBoxFlat.new()
	st.bg_color = color.darkened(0.55); st.border_color = color.lerp(Color.TRANSPARENT, 0.3)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
		st.set_corner_radius(CORNER_TOP_LEFT, 10); st.set_corner_radius(CORNER_TOP_RIGHT, 10)
		st.set_corner_radius(CORNER_BOTTOM_LEFT, 10); st.set_corner_radius(CORNER_BOTTOM_RIGHT, 10)
	btn.add_theme_stylebox_override("normal", st); btn.add_theme_stylebox_override("hover", st)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 14); return btn

func _panel(parent: Control, color: Color, min_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var pc := PanelContainer.new()
	if min_size != Vector2.ZERO: pc.custom_minimum_size = min_size
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new(); st.bg_color = color
	pc.add_theme_stylebox_override("panel", st); parent.add_child(pc); return pc

func _style_card(btn: Button, accent: Color) -> void:
	# Iron-plate aesthetic: no rounded corners, thin accent border, void background.
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.067, 0.063, 0.047)   # --surface-1 slab
	st.border_color = accent.lerp(Color.TRANSPARENT, 0.35)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	var hover := st.duplicate() as StyleBoxFlat
	hover.border_color = accent.lerp(Color.WHITE, 0.15)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		hover.set_border_width(side, 2)
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover",  hover)

func _style_panel(pc: PanelContainer, accent: Color) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04,0.05,0.09); st.border_color = accent.lerp(Color.TRANSPARENT, 0.35)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 2)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 14)
	pc.add_theme_stylebox_override("panel", st)

func _overlay() -> PanelContainer:
	var pc := PanelContainer.new()
	pc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var st := StyleBoxFlat.new(); st.bg_color = Color(0.02,0.03,0.06,0.93)
	pc.add_theme_stylebox_override("panel", st); return pc

func _pill(parent: Control, text: String, color: Color) -> void:
	var pc := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = color.darkened(0.7); st.border_color = color.lerp(Color.TRANSPARENT, 0.4)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 1)
	st.content_margin_left = 6; st.content_margin_right = 8
	st.content_margin_top = 2; st.content_margin_bottom = 2
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 5)
	pc.add_theme_stylebox_override("panel", st)
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", color)
	pc.add_child(l); parent.add_child(pc)

func _node_card(meta: Dictionary, is_cur: bool, is_done: bool, _is_future: bool, is_skipped: bool, node: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(90, 116)
	var accent := meta["color"] as Color

	var st := StyleBoxFlat.new()
	var hover_st := StyleBoxFlat.new()
	if is_cur:
		st.bg_color = accent.darkened(0.62)
		st.border_color = accent
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 2)
		hover_st.bg_color = accent.darkened(0.45)
		hover_st.border_color = accent.lightened(0.2)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: hover_st.set_border_width(side, 2)
	elif is_done:
		st.bg_color = Color(0.09, 0.14, 0.09, 0.80)
		st.border_color = Color(0.28, 0.60, 0.28, 0.55)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 1)
		hover_st = st.duplicate()
	elif is_skipped:
		st.bg_color = Color(0.04, 0.04, 0.06, 0.40)
		st.border_color = Color(1, 1, 1, 0.04)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 1)
		hover_st = st.duplicate()
	else:
		st.bg_color = Color(0.07, 0.08, 0.11, 0.55)
		st.border_color = Color(1, 1, 1, 0.07)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 1)
		hover_st = st.duplicate()
	for c in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 8)
		hover_st.set_corner_radius(c, 8)
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", hover_st)
	btn.add_theme_stylebox_override("pressed", st)
	btn.add_theme_stylebox_override("focus", st)
	btn.disabled = not is_cur

	# Colored top accent strip
	var top_bar := ColorRect.new()
	top_bar.color = accent if is_cur else (Color(0.28, 0.60, 0.28, 0.4) if is_done else Color(1,1,1,0.04))
	top_bar.custom_minimum_size = Vector2(0, 3)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	btn.add_child(top_bar)

	# Node type label (top center, small caps)
	var type_lbl := Label.new()
	type_lbl.text = meta["label"].to_upper() if not is_done and not is_skipped else ("DONE" if is_done else "SKIPPED")
	type_lbl.add_theme_font_override("font", _FONT_HEADER)
	type_lbl.add_theme_font_size_override("font_size", 8)
	type_lbl.add_theme_color_override("font_color", accent if is_cur else (Color(0.35, 0.70, 0.35) if is_done else DIM.darkened(0.3)))
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	type_lbl.offset_top = 7
	type_lbl.offset_bottom = 22
	btn.add_child(type_lbl)

	# Center icon
	var ic: Control
	if is_done:
		var done_lbl := Label.new()
		done_lbl.text = "✓"
		done_lbl.add_theme_font_size_override("font_size", 26)
		done_lbl.add_theme_color_override("font_color", Color(0.35, 0.75, 0.35, 0.9))
		done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic = done_lbl
	elif is_skipped:
		var skip_lbl := Label.new()
		skip_lbl.text = "✗"
		skip_lbl.add_theme_font_size_override("font_size", 20)
		skip_lbl.add_theme_color_override("font_color", DIM.darkened(0.4))
		skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic = skip_lbl
	else:
		var ntype: String = str(node.get("type", "battle"))
		ic = _node_icon_widget(ntype, str(meta["icon"]),
			accent if is_cur else DIM.darkened(0.15), Vector2(38, 38))
	ic.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	ic.offset_top = 2
	btn.add_child(ic)

	# Reward hint at bottom
	var reward_hint := _clean_ui_text(node.get("reward_hint", ""), "")
	if reward_hint.length() > 14:
		reward_hint = reward_hint.substr(0, 14)
	if not reward_hint.is_empty():
		var hint := Label.new()
		hint.text = reward_hint
		hint.add_theme_font_size_override("font_size", 8)
		hint.add_theme_color_override("font_color", accent.lerp(Color.WHITE, 0.2) if is_cur else DIM.darkened(0.15))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		hint.offset_top = -26
		hint.offset_bottom = -8
		btn.add_child(hint)

	# Animated glow ring for current node
	if is_cur:
		var glow := ColorRect.new()
		glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glow.color = Color(accent.r, accent.g, accent.b, 0.0)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(glow)
		var tween := btn.create_tween()
		tween.set_loops()
		tween.tween_property(glow, "color:a", 0.12, 0.9).set_trans(Tween.TRANS_SINE)
		tween.tween_property(glow, "color:a", 0.0, 0.9).set_trans(Tween.TRANS_SINE)

	return btn


func _build_floor_connector(is_current: bool, is_past: bool) -> Control:
	"""Visual connector between floor columns with line + arrowhead."""
	var container := Control.new()
	container.custom_minimum_size = Vector2(28, 96)

	# Horizontal line
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(18, 2)
	var line_color: Color
	if is_current:
		line_color = GOLD.lerp(Color.TRANSPARENT, 0.35)
	elif is_past:
		line_color = Color(0.3, 0.58, 0.3, 0.55)
	else:
		line_color = Color(0.22, 0.22, 0.28, 0.35)
	line.color = line_color
	line.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	line.offset_left = -9
	line.offset_right = 9
	line.offset_top = -1
	line.offset_bottom = 1
	container.add_child(line)

	# Arrowhead label
	var arrow := Label.new()
	arrow.text = "›"
	arrow.add_theme_font_size_override("font_size", 18)
	arrow.add_theme_color_override("font_color", line_color.lightened(0.15))
	arrow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	arrow.offset_left = 2
	arrow.offset_top = -11
	container.add_child(arrow)

	return container


func _node_hint(ntype: String) -> String:
	match ntype:
		"boss":      return "Final floor - all elite enemies."
		"elite":     return "Hard fight, better loot odds."
		"mystery":   return "Unknown event. Could be reward, danger, or help."
		"mystery_cache": return "Claim gold without a fight."
		"mystery_training": return "Gain JP without a fight."
		"mystery_shrine": return "Choose a surprise Guardian boon."
		"mystery_ambush": return "Ambush battle with better spoils."
		"boon_pick": return "Choose one Guardian boon."
		"wanderer":  return "A named character waits here."
		"town_1":    return "Rest, restore HP, and gain a little JP."
		"town_2":    return "Spend gold on party training and supplies."
		"town_3":    return "Reveal hidden route nodes ahead."
		_:           return "Procedurally generated battle."


func _available_route_hint(nodes: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for node in nodes:
		var meta: Dictionary = NODE_META.get(node.get("type", "battle"), NODE_META["battle"])
		var reward_hint := _clean_ui_text(node.get("reward_hint", ""), "")
		parts.append("%s %s" % [meta.get("label", "Battle"), reward_hint])
	return "Pick one path: " + "  /  ".join(parts)


## Returns a TextureRect if a PNG icon exists for this boon, else a Label with the emoji.
func _boon_icon_widget(boon_id: String, emoji: String, accent: Color) -> Control:
	var icon_path: String = AssetRegistry.get_boon_icon(boon_id)
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var icon_rect := TextureRect.new()
		icon_rect.texture = load(icon_path)
		icon_rect.custom_minimum_size = Vector2(64, 64)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return icon_rect
	var lbl := Label.new()
	lbl.text = emoji
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", accent)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

## Returns a TextureRect for a run-node type, or null if no PNG registered.
func _node_icon_widget(ntype: String, fallback_text: String, color: Color, icon_size: Vector2) -> Control:
	var icon_path: String = AssetRegistry.get_run_node_icon(ntype)
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var icon_rect := TextureRect.new()
		icon_rect.texture = load(icon_path)
		icon_rect.custom_minimum_size = icon_size
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return icon_rect
	var lbl := Label.new()
	lbl.text = fallback_text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

func _guardian_label(g: String) -> String:
	var labels := {"ignareth":"The Eternal Flame","nerevan":"The Tide Eternal",
				   "torvahk":"The Storm Father","luminarch":"The Sacred Light","vaelthorn":"The Shadow That Was"}
	return labels.get(g, g.capitalize())
