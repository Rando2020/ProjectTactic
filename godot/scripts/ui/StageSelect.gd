## StageSelect.gd
## 10-floor run map. Start Run → fight through procedurally generated floors.

class_name StageSelect
extends Control

const BG   := Color(0.04, 0.05, 0.08)
const FG   := Color(0.97, 0.94, 0.87)
const DIM  := Color(0.45, 0.42, 0.38)
const GOLD := Color(0.79, 0.65, 0.34)
const CurseSystemScript := preload("res://scripts/roguelike/CurseSystem.gd")

const NODE_META: Dictionary = {
	"battle":      {"icon":"⚔", "color":Color(0.48,0.86,1.0),  "label":"Battle"},
	"boss":        {"icon":"💀", "color":Color(0.93,0.27,0.27), "label":"Boss"},
	"boon_pick":   {"icon":"✦", "color":Color(0.79,0.65,0.34), "label":"Boon"},
	"wanderer":    {"icon":"?", "color":Color(0.53,0.94,0.67), "label":"Wanderer"},
}

var _gs:  Node
var _bs:  BoonSystem

var _boon_overlay:  Control = null
var _loot_overlay:  Control = null


func _ready() -> void:
	_gs = get_node_or_null("/root/GameState")
	_bs = BoonSystem.new()

	if _gs and _gs.pending_boon_offers.size() > 0:
		_build_ui(); _show_boon_pick(_gs.pending_boon_offers); return
	if _gs and _gs.pending_loot.size() > 0:
		_build_ui(); _show_loot(_gs.pending_loot); return
	_build_ui()


func _build_ui() -> void:
	for c in get_children(): c.queue_free()

	_bg(self)

	if not _gs or not _gs.active_run or _gs.active_run.completed:
		_build_start_screen()
	else:
		_build_run_screen(_gs.active_run)


# ── Start screen ──────────────────────────────────────────────────────────────

func _build_start_screen() -> void:
	var vbox := _vbox(self, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(460, 0)

	_lbl(vbox, "VAELTHAR  ·  EIDOLON CHRONICLES", 12, DIM, true)
	_space(vbox, 8)
	_lbl(vbox, "The Roguelike Run", 34, FG, true)
	_space(vbox, 6)
	_lbl(vbox, "10 floors. Randomised maps. Five Guardians.", 14, DIM, true)
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

	var btn := _btn("▶  Start New Run", GOLD)
	btn.custom_minimum_size = Vector2(300, 52)
	btn.pressed.connect(func() -> void: _on_start_run(meta.selected_heat_level if meta else 0))
	vbox.add_child(btn)
	_space(vbox, 12)

	if _gs:
		_lbl(vbox, "Gold: %dg" % _gs.gold, 14, GOLD, true)

	# Show meta currencies
	if meta:
		_lbl(vbox, "Soul Shards: %d  ·  Obsidian: %d" % [meta.get_currency(Currency.SOUL_SHARDS), meta.get_currency(Currency.OBSIDIAN)], 12, DIM, true)


# ── Run screen ────────────────────────────────────────────────────────────────

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
	_lbl(hh, "Floor %d / 10" % run.current_floor, 22, FG)
	_stretch(hh)
	_lbl(hh, "Gold: %dg" % (_gs.gold if _gs else 0), 14, GOLD)
	_lbl(hh, "  Elites: %d" % run.elite_kills, 12, DIM)
	_lbl(hh, "  Boons: %d" % run.active_boons.size(), 12, DIM)
	_gap(hh, 12)
	var ab_btn := _btn("Abandon", Color(0.93,0.27,0.27))
	ab_btn.custom_minimum_size.x = 90
	ab_btn.pressed.connect(_on_abandon)
	hh.add_child(ab_btn)
	_gap(hh, 8)

	# Active boons row
	if run.active_boons.size() > 0:
		var bar := _panel(root, Color(0.06,0.07,0.10), Vector2(0, 44))
		var br  := _hbox(bar)
		br.add_theme_constant_override("margin_left", 24)
		br.set_anchors_and_offsets_preset(Control.PRESET_VCENTER_WIDE)
		_lbl(br, "Boons:", 10, DIM)
		_gap(br, 6)
		for boon in run.active_boons:
			_pill(br, boon.get("icon","✦") + " " + boon.get("name","?"), GOLD)
			_gap(br, 4)

	_space(root, 18)

	# Floor node map — horizontal scroll
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 160
	root.add_child(scroll)

	var hmap := _hbox(scroll)
	hmap.add_theme_constant_override("margin_left", 24)
	hmap.add_theme_constant_override("margin_right", 24)
	hmap.add_theme_constant_override("separation", 10)

	for idx in run.floor_plan.size():
		var node: Dictionary = run.floor_plan[idx]
		var is_cur: bool = idx == run.current_node
		var is_done: bool = bool(node.get("completed", false))
		var is_future: bool = idx > run.current_node
		var ntype: String = str(node.get("type","battle"))
		var meta: Dictionary = NODE_META.get(ntype, NODE_META["battle"])

		var nc := _node_card(meta, is_cur, is_done, is_future, node.get("floor",1))
		if is_cur:
			nc.pressed.connect(_on_enter_node.bind(node))
		hmap.add_child(nc)

		# Connector arrow (not after last node)
		if idx < run.floor_plan.size() - 1:
			var arr := _lbl_widget("→", 14, DIM if is_future else Color(0.4,0.4,0.4))
			hmap.add_child(arr)

	_space(root, 16)

	# Current node prompt
	var cur := run.get_current_node()
	if cur and not cur.get("completed", false):
		var prompt := _panel(root, Color(0.10,0.11,0.08,0.9), Vector2(0, 76))
		var ph     := _hbox(prompt)
		ph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ph.add_theme_constant_override("margin_left", 28)
		ph.add_theme_constant_override("margin_right", 20)
		ph.alignment = BoxContainer.ALIGNMENT_CENTER
		var nm: Dictionary = NODE_META.get(cur.get("type","battle"), NODE_META["battle"])
		_lbl(ph, nm["icon"], 24, nm["color"])
		_gap(ph, 12)
		var info := _vbox(ph)
		_lbl(info, nm["label"], 15, FG)
		_lbl(info, _node_hint(cur.get("type","")), 11, DIM)
		_stretch(ph)
		var eb := _btn("Enter  →", GOLD)
		eb.custom_minimum_size = Vector2(130, 42)
		eb.pressed.connect(_on_enter_node.bind(cur))
		ph.add_child(eb)
		_gap(ph, 12)


# ── Node entry ────────────────────────────────────────────────────────────────

func _on_start_run(heat: int = 0) -> void:
	if not _gs: return
	var rm: Node = get_node_or_null("/root/RunManager")
	if rm:
		rm.start_new_run(heat)
	else:
		# Fallback: create RunState directly if RunManager not registered yet
		var run_seed: int = int(Time.get_unix_time_from_system()) & 0xffffff
		_gs.active_run = RunState.create(run_seed)
	_build_ui()

func _on_enter_node(node: Dictionary) -> void:
	if not _gs or not _gs.active_run: return
	match node.get("type","battle"):
		"battle", "boss":
			get_tree().change_scene_to_file("res://scenes/Battle.tscn")
		"boon_pick":
			var owned: Array = _gs.active_run.active_boons.map(func(b: Dictionary) -> String: return b.get("id",""))
			var floor_num: int = int(_gs.active_run.current_floor)
			var offers := _bs.generate_offers(_gs.active_run.seed * 17 + floor_num * 3 + _gs.active_run.current_node, floor_num, owned)
			_show_boon_pick(offers)
		"wanderer":
			# Auto-complete wanderer node for now (full UI can be added)
			_gs.active_run.complete_current_node()
			_build_ui()

func _on_abandon() -> void:
	var rm: Node = get_node_or_null("/root/RunManager")
	if rm and rm.is_run_active: rm.end_run(false)
	elif _gs: _gs.active_run = null
	_build_ui()

func _on_boon_picked(boon: Dictionary) -> void:
	if _gs and _gs.active_run:
		_gs.active_run.active_boons.append(boon)
	_gs.pending_boon_offers.clear()
	_gs.active_run.complete_current_node()
	_apply_between_battle_heal()
	if _boon_overlay: _boon_overlay.queue_free(); _boon_overlay = null
	_build_ui()

func _on_boon_skip() -> void:
	if _gs: _gs.pending_boon_offers.clear()
	if _gs and _gs.active_run: _gs.active_run.complete_current_node()
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
	for uid in gs.unit_registry:
		var reg: Dictionary = gs.unit_registry[uid]
		var max_hp: int = reg.get("base_hp", 200)
		var heal: int   = int(float(max_hp) * pct)
		if heal > 0:
			reg["current_hp"] = min(max_hp, reg.get("current_hp", max_hp) + heal)

func _on_loot_continue() -> void:
	if _gs: _gs.pending_loot.clear()
	if _loot_overlay: _loot_overlay.queue_free(); _loot_overlay = null
	_build_ui()


# ── Boon pick overlay ─────────────────────────────────────────────────────────

func _show_boon_pick(offers: Array) -> void:
	if _boon_overlay: _boon_overlay.queue_free()
	_boon_overlay = _overlay()
	add_child(_boon_overlay)

	var vbox := _vbox(_boon_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(900, 0)

	_lbl(vbox, "CHOOSE A BOON", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "Power grows with every choice.", 26, FG, true)
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

	# ── Curse offer (Returnal-style tradeoff) ─────────────────────────────
	if _gs and _gs.active_run:
		var cs := CurseSystemScript.new()
		var owned_curse_ids: Array = _gs.active_run.active_curses.map(
			func(c: Dictionary) -> String: return c.get("id",""))
		var curse_offer := cs.generate_curse_offer(
			_gs.active_run.seed + _gs.active_run.current_node * 31,
			_gs.active_run.current_floor, owned_curse_ids)
		if not curse_offer.is_empty():
			var divider := HSeparator.new()
			vbox.add_child(divider)
			_space(vbox, 8)
			_lbl(vbox, "— OR ACCEPT A CURSE —", 11, Color(0.65,0.25,0.25), true)
			_space(vbox, 8)
			vbox.add_child(_curse_card(curse_offer))

	_space(vbox, 10)
	var skip := _btn("Decline all", DIM)
	skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip.pressed.connect(_on_boon_skip)
	vbox.add_child(skip)


func _boon_card(boon: Dictionary, accent: Color) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(280, 340)
	_style_card(btn, accent)

	var inner := _vbox(btn, true)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left", 18)
	inner.add_theme_constant_override("margin_right", 18)
	inner.add_theme_constant_override("margin_top", 18)
	inner.add_theme_constant_override("margin_bottom", 18)
	inner.add_theme_constant_override("separation", 6)

	_lbl(inner, boon.get("rarity","?").to_upper(), 10, accent, true)
	_lbl(inner, boon.get("icon","✦"), 36, accent, true)
	_lbl(inner, boon.get("name","?"), 15, FG, true)
	_space(inner, 4)

	var guardian: String = str(boon.get("guardian",""))
	if guardian:
		_lbl(inner, guardian.capitalize() + " · " + _guardian_label(guardian), 9, accent.lerp(FG, 0.4), true)
		_space(inner, 4)

	var desc := RichTextLabel.new()
	desc.bbcode_enabled = false
	desc.text = boon.get("desc","")
	desc.add_theme_font_size_override("normal_font_size", 12)
	desc.add_theme_color_override("default_color", Color(0.85,0.82,0.77))
	desc.custom_minimum_size = Vector2(0, 80)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(desc)

	var flavour: String = boon.get("flavour","")
	if flavour:
		_space(inner, 4)
		var fl: RichTextLabel = RichTextLabel.new()
		fl.bbcode_enabled = false
		fl.text = '"%s"' % flavour
		fl.add_theme_font_size_override("normal_font_size", 10)
		fl.add_theme_color_override("default_color", Color(0.45,0.42,0.38))
		fl.custom_minimum_size = Vector2(0, 55)
		fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(fl)

	return btn


# ── Loot overlay ──────────────────────────────────────────────────────────────

func _curse_card(curse: Dictionary) -> Button:
	var accent := Color(0.92, 0.24, 0.24)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(620, 190)
	_style_card(btn, accent)

	var inner := _vbox(btn, false)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left", 18)
	inner.add_theme_constant_override("margin_right", 18)
	inner.add_theme_constant_override("margin_top", 16)
	inner.add_theme_constant_override("margin_bottom", 16)
	inner.add_theme_constant_override("separation", 5)

	_lbl(inner, "CURSE TRADE", 10, accent, true)
	_lbl(inner, "%s  %s" % [curse.get("icon", "!"), curse.get("name", "?")], 17, FG, true)
	_space(inner, 4)
	_lbl(inner, "Penalty: %s" % curse.get("penalty", ""), 11, Color(1.0, 0.66, 0.62))
	_lbl(inner, "Unlock: %s" % curse.get("unlock", ""), 11, Color(0.82, 0.92, 1.0))
	_space(inner, 4)
	_lbl(inner, str(curse.get("flavour", "")), 10, DIM, true)
	btn.pressed.connect(_on_curse_picked.bind(curse))
	return btn


func _on_curse_picked(curse: Dictionary) -> void:
	if _gs and _gs.active_run:
		_gs.active_run.active_curses.append(curse)
	if _gs:
		_gs.pending_boon_offers.clear()
	if _gs and _gs.active_run:
		_gs.active_run.complete_current_node()
	_apply_between_battle_heal()
	if _boon_overlay:
		_boon_overlay.queue_free()
		_boon_overlay = null
	_build_ui()


func _show_loot(items: Array) -> void:
	if _loot_overlay: _loot_overlay.queue_free()
	_loot_overlay = _overlay()
	add_child(_loot_overlay)

	var vbox := _vbox(_loot_overlay, true)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(800, 0)

	_lbl(vbox, "BATTLE COMPLETE", 11, DIM, true)
	_space(vbox, 6)
	_lbl(vbox, "%d item%s found." % [items.size(), "s" if items.size() != 1 else ""], 24, FG, true)
	_space(vbox, 20)

	if items.size() > 0:
		var hbox := _hbox(vbox)
		hbox.add_theme_constant_override("separation", 14)
		for item in items:
			hbox.add_child(_item_card(item))
	else:
		_lbl(vbox, "The enemies carried nothing of value.", 14, DIM, true)

	_space(vbox, 20)
	var cont := _btn("Continue  →", GOLD)
	cont.custom_minimum_size = Vector2(200, 44)
	cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cont.pressed.connect(_on_loot_continue)
	vbox.add_child(cont)


func _item_card(item: Dictionary) -> PanelContainer:
	var pc  := PanelContainer.new()
	pc.custom_minimum_size = Vector2(200, 240)
	_style_panel(pc, item.get("color", Color.WHITE))

	var inner := _vbox(pc, false)
	inner.add_theme_constant_override("margin_left", 14)
	inner.add_theme_constant_override("margin_right", 14)
	inner.add_theme_constant_override("margin_top",  14)
	inner.add_theme_constant_override("margin_bottom",14)
	inner.add_theme_constant_override("separation", 5)

	_lbl(inner, item.get("label","").to_upper(), 9, item.get("color", Color.WHITE), false)
	_lbl(inner, item.get("icon",""), 28, Color.WHITE, true)
	_lbl(inner, item.get("name","?"), 13, FG, true)
	_lbl(inner, item.get("slot","").to_upper(), 9, DIM, true)
	_space(inner, 4)
	for affix in item.get("affixes", []):
		_lbl(inner, "• " + affix.get("label",""), 11, Color(0.85,0.82,0.77), false)
	return pc


# ── Widget helpers ────────────────────────────────────────────────────────────

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
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04,0.05,0.09); st.border_color = accent.lerp(Color.TRANSPARENT, 0.3)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 2)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 16)
	btn.add_theme_stylebox_override("normal", st); btn.add_theme_stylebox_override("hover", st)

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

func _node_card(meta: Dictionary, is_cur: bool, is_done: bool, _is_future: bool, floor_num: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(82, 100)
	var st := StyleBoxFlat.new()
	if is_cur:
		st.bg_color = meta["color"].darkened(0.55)
		st.border_color = meta["color"]
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 2)
	elif is_done:
		st.bg_color = Color(0.12, 0.16, 0.12, 0.7)
		st.border_color = Color(0.3, 0.65, 0.3, 0.5)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 1)
	else:
		st.bg_color = Color(0.08, 0.09, 0.12, 0.5)
		st.border_color = Color(1, 1, 1, 0.08)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 10)
	btn.add_theme_stylebox_override("normal", st); btn.add_theme_stylebox_override("hover", st)
	btn.disabled = not is_cur

	var ic := Label.new()
	ic.text = "✓" if is_done else meta["icon"]
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ic.add_theme_font_size_override("font_size", 22)
	ic.add_theme_color_override("font_color",
		Color(0.4,0.75,0.4) if is_done else (meta["color"] if is_cur else DIM.darkened(0.2)))
	ic.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	btn.add_child(ic)

	# Floor number badge at bottom
	if meta["label"] in ["Battle","Boss"]:
		var fl := Label.new()
		fl.text = "F%d" % floor_num
		fl.add_theme_font_size_override("font_size", 9)
		fl.add_theme_color_override("font_color", meta["color"] if is_cur else DIM)
		fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		fl.offset_top = -18
		btn.add_child(fl)

	return btn


func _node_hint(ntype: String) -> String:
	match ntype:
		"boss":      return "Final floor — all elite enemies."
		"boon_pick": return "Choose one Guardian boon."
		"wanderer":  return "A named character waits here."
		_:           return "Procedurally generated battle."


func _guardian_label(g: String) -> String:
	var labels := {"ignareth":"The Eternal Flame","nerevan":"The Tide Eternal",
	               "torvahk":"The Storm Father","luminarch":"The Sacred Light","vaelthorn":"The Shadow That Was"}
	return labels.get(g, g.capitalize())
