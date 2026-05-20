## ResultsScreen.gd
## Shown after boss floor victory (run complete) OR after non-run battles.
## Run complete: shows full run summary — floors, boons, loot, JP earned.
## Single battle: shows gold/JP and continues to CharacterScreen.

class_name ResultsScreen
extends Control

const BG   := Color(0.04, 0.05, 0.08)
const FG   := Color(0.97, 0.94, 0.87)
const DIM  := Color(0.45, 0.42, 0.38)
const GOLD := Color(0.79, 0.65, 0.34)

const GUARDIAN_COLORS := {
	"ignareth": Color(1.0,0.57,0.20), "nerevan": Color(0.22,0.74,1.0),
	"torvahk": Color(1.0,0.92,0.27), "luminarch": Color(1.0,0.96,0.60),
	"vaelthorn": Color(0.66,0.33,0.97),
}


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	for c in get_children(): c.queue_free()

	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var gs: Node     = get_node_or_null("/root/GameState")
	var rewards: Dictionary = gs.pending_rewards if gs else {}
	var is_run_complete: bool = gs != null and gs.get("active_run") == null \
		and gs.get("run_floor_reached", 0) > 0
	var is_victory: bool = not rewards.is_empty()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(900, 0)
	root.add_theme_constant_override("separation", 0)
	root.add_theme_constant_override("margin_left", 40)
	root.add_theme_constant_override("margin_right", 40)
	root.add_theme_constant_override("margin_top", 32)
	scroll.add_child(root)

	# ── Header ─────────────────────────────────────────────────────────────
	if is_run_complete:
		_lbl(root, "RUN COMPLETE", 13, DIM)
		_space(root, 4)
		_lbl(root, "The Vault Falls Silent.", 38, GOLD)
		_space(root, 6)
		_lbl(root, "The Void Anchor has been shattered. The resonance holds — for now.", 14, DIM)
	elif is_victory:
		_lbl(root, "VICTORY", 13, DIM)
		_space(root, 4)
		_lbl(root, "Floor %d — Cleared" % (gs.run_floor_reached if gs else 0), 36, GOLD)
	else:
		_lbl(root, "DEFEATED", 13, DIM)
		_space(root, 4)
		_lbl(root, "The party falls.", 36, Color(0.85, 0.25, 0.25))

	_space(root, 24)
	_separator(root)
	_space(root, 16)

	# ── Run summary grid ───────────────────────────────────────────────────
	if is_run_complete or (is_victory and gs and gs.get("run_floor_reached",0) > 0):
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		root.add_child(grid)

		# Stat cards
		var floor_n: int    = gs.run_floor_reached if gs else 0
		var elite_n: int    = gs.active_run.elite_kills if (gs and gs.active_run) else (gs.get("run_elite_kills",0) if gs else 0)
		var jp_n:    int    = gs.get("run_jp_earned", 0) if gs else 0
		var gold_n:  int    = rewards.get("gold", 0)
		var boons:   Array  = []
		var items:   Array  = gs.get("run_inventory",[]) if gs else []
		if gs and gs.active_run: boons = gs.active_run.active_boons

		grid.add_child(_stat_card("Floors Cleared", str(floor_n) + " / 10", GOLD))
		grid.add_child(_stat_card("Elites Slain",   str(elite_n),            Color(1.0,0.6,0.2)))
		grid.add_child(_stat_card("JP Earned",       str(jp_n),              Color(0.48,0.86,1.0)))
		grid.add_child(_stat_card("Gold Earned",     str(gold_n) + "g",      Color(0.9,0.8,0.3)))
		grid.add_child(_stat_card("Items Found",     str(items.size()),       Color(0.75,0.32,0.97)))
		grid.add_child(_stat_card("Boons Held",      str(boons.size()),       Color(0.53,0.94,0.67)))

		_space(root, 20)

		# Boons held
		if boons.size() > 0:
			_lbl(root, "Boons Carried", 14, DIM)
			_space(root, 8)
			var brow := HBoxContainer.new()
			brow.add_theme_constant_override("separation", 10)
			root.add_child(brow)
			for boon: Dictionary in boons:
				brow.add_child(_boon_chip(boon))
			_space(root, 16)

		# Items found
		if items.size() > 0:
			_lbl(root, "Items Found", 14, DIM)
			_space(root, 8)
			var irow := HBoxContainer.new()
			irow.add_theme_constant_override("separation", 10)
			root.add_child(irow)
			for item: Dictionary in items:
				irow.add_child(_item_chip(item))
			_space(root, 16)

		# Soul Shards earned this run
		var rm: Node = get_node_or_null("/root/RunManager")
		if rm:
			var shards_earned := int(rm.run_aether / 10) + (20 + rm.heat_level * 5 if is_run_complete else 0)
			_lbl(root, "Soul Shards Earned This Run: %d" % shards_earned, 13, GOLD)
			_space(root, 8)

	else:
		# Simple single-battle results
		if is_victory:
			_lbl(root, "+%dg  · +%d JP" % [rewards.get("gold",0), rewards.get("jp",0)], 22, GOLD)
			_space(root, 4)
		_space(root, 16)

	_separator(root)
	_space(root, 20)

	# ── Continue button ─────────────────────────────────────────────────────
	var btn_label: String
	var btn_color: Color
	var btn_scene: String
	if is_run_complete:
		btn_label = "Return to the Hearth  →"
		btn_color = GOLD
		btn_scene = "res://scenes/HubScene.tscn"
		# Clear run stats for next run
		if gs:
			gs.run_floor_reached = 0
			gs.run_jp_earned     = 0
			gs.run_inventory.clear()
	elif is_victory:
		btn_label = "Continue →"
		btn_color = Color(0.48,0.86,1.0)
		btn_scene = "res://scenes/CharacterScreen.tscn"
	else:
		btn_label = "Back to Hub"
		btn_color = DIM
		btn_scene = "res://scenes/HubScene.tscn"

	var btn := _btn(btn_label, btn_color)
	btn.custom_minimum_size = Vector2(280, 50)
	btn.pressed.connect(func() -> void: get_tree().change_scene_to_file(btn_scene))
	root.add_child(btn)
	_space(root, 40)


# ── Widget helpers ────────────────────────────────────────────────────────────

func _stat_card(label: String, value: String, color: Color) -> PanelContainer:
	var pc  := PanelContainer.new()
	pc.custom_minimum_size = Vector2(240, 80)
	var st  := StyleBoxFlat.new()
	st.bg_color    = Color(0.07, 0.08, 0.12)
	st.border_color = color.lerp(Color.TRANSPARENT, 0.5)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 10)
	pc.add_theme_stylebox_override("panel", st)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("margin_left", 16)
	box.add_theme_constant_override("margin_top", 12)
	box.add_theme_constant_override("separation", 4)
	pc.add_child(box)
	var vl := Label.new(); vl.text = value
	vl.add_theme_font_size_override("font_size", 26)
	vl.add_theme_color_override("font_color", color)
	box.add_child(vl)
	var ll := Label.new(); ll.text = label
	ll.add_theme_font_size_override("font_size", 11)
	ll.add_theme_color_override("font_color", DIM)
	box.add_child(ll)
	return pc

func _boon_chip(boon: Dictionary) -> PanelContainer:
	var col: Color = GUARDIAN_COLORS.get(boon.get("guardian",""), GOLD)
	var pc  := PanelContainer.new()
	var st  := StyleBoxFlat.new()
	st.bg_color    = col.darkened(0.65)
	st.border_color = col.lerp(Color.TRANSPARENT, 0.4)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 8)
	st.content_margin_left = 10; st.content_margin_right = 10
	st.content_margin_top  = 6;  st.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", st)
	var lbl := Label.new()
	lbl.text = boon.get("icon","✦") + "  " + boon.get("name","?")
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", col)
	pc.add_child(lbl); return pc

func _item_chip(item: Dictionary) -> PanelContainer:
	var col: Color = item.get("color", DIM)
	var pc  := PanelContainer.new()
	var st  := StyleBoxFlat.new()
	st.bg_color    = Color(0.06,0.07,0.10)
	st.border_color = col.lerp(Color.TRANSPARENT, 0.35)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 8)
	st.content_margin_left = 10; st.content_margin_right = 10
	st.content_margin_top  = 6;  st.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", st)
	var lbl := Label.new()
	lbl.text = item.get("icon","📦") + "  " + item.get("name","?")
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", col)
	pc.add_child(lbl); return pc

func _lbl(parent: Control, text: String, size: int, color: Color) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l); return l

func _space(parent: Control, h: int) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(0,h); parent.add_child(s)

func _separator(parent: Control) -> void:
	var s := HSeparator.new()
	var st := StyleBoxFlat.new(); st.bg_color = Color(1,1,1,0.08)
	s.add_theme_stylebox_override("separator", st); parent.add_child(s)

func _btn(text: String, color: Color) -> Button:
	var b := Button.new(); b.text = text
	var st := StyleBoxFlat.new()
	st.bg_color    = color.darkened(0.55)
	st.border_color = color.lerp(Color.TRANSPARENT, 0.3)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side, 1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 10)
	b.add_theme_stylebox_override("normal", st); b.add_theme_stylebox_override("hover", st)
	b.add_theme_color_override("font_color", color)
	b.add_theme_font_size_override("font_size", 15); return b
