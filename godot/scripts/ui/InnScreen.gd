## InnScreen.gd
## Hub rest-point between missions. Lets the player spend Soul Shards
## to restore party HP, Temper, and Ether and clear minor status effects.
##
## Reads from /root/MetaProgression for the soul_shards balance.
## Emits `rested` when the player pays and rests; `back_pressed` to return.

class_name InnScreen
extends Control

signal rested(cost: int)
signal back_pressed

#  Fonts
const _FONT_DISPLAY := preload("res://assets/fonts/TrajanPro-Regular.ttf")
const _FONT_HEADER  := preload("res://assets/fonts/Cinzel-Bold.ttf")
const _FONT_BODY    := preload("res://assets/fonts/IMFellEnglish-Regular.ttf")
const _FONT_UI      := preload("res://assets/fonts/CormorantGaramond-Regular.ttf")

#  Design tokens
const _BG      := Color(0.031, 0.035, 0.051)
const _SURFACE := Color(0.067, 0.063, 0.047)
const _SURFACE2:= Color(0.102, 0.086, 0.063)
const _FG      := Color(0.941, 0.910, 0.816)
const _FG2     := Color(0.784, 0.722, 0.604)
const _DIM     := Color(0.353, 0.322, 0.278)
const _GOLD    := Color(0.831, 0.686, 0.275)
const _HP      := Color(0.298, 0.820, 0.400)
const _TMP     := Color(0.941, 0.502, 0.125)
const _ETH     := Color(0.647, 0.522, 1.000)
const _DANGER  := Color(0.93,  0.27,  0.27)

#  Inn configuration
const REST_COST          := 40        # soul shards
const REST_LABEL_CHEAPLY := "20"      # cosmetic only  shown when half-price
var   town_name: String  = "The Last Hearth"

#  State
var _meta: Node
var _msg_lbl:  Label
var _cost_lbl: Label
var _rest_btn: Button
var _gold_lbl: Label


func _ready() -> void:
	_meta = get_node_or_null("/root/MetaProgression")
	_build_ui()

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
	root.custom_minimum_size = Vector2(900, 0)
	root.add_theme_constant_override("separation", 0)
	scroll.add_child(root)

	#  Header
	var hdr := _solid_panel(root, _SURFACE2, Vector2(0, 80))
	var hh  := HBoxContainer.new()
	hh.add_theme_constant_override("margin_left", 40)
	hh.add_theme_constant_override("margin_right", 40)
	hh.alignment = BoxContainer.ALIGNMENT_CENTER
	hh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hdr.add_child(hh)

	var title_col := VBoxContainer.new()
	hh.add_child(title_col)
	_eyebrow(title_col, "REST POINT")
	_lbl(title_col, town_name + "  The Inn", 24, _FG, _FONT_DISPLAY)

	var stretch := Control.new()
	stretch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(stretch)

	# Gold display
	var gold_panel := _chip_panel()
	hh.add_child(gold_panel)
	_gold_lbl = Label.new()
	_gold_lbl.add_theme_font_override("font", _FONT_DISPLAY)
	_gold_lbl.add_theme_font_size_override("font_size", 13)
	_gold_lbl.add_theme_color_override("font_color", _GOLD)
	gold_panel.add_child(_gold_lbl)
	_refresh_gold_lbl()

	_space(hh, 12)

	var back_btn := _iron_btn(" Back to Town")
	back_btn.pressed.connect(func() -> void: back_pressed.emit())
	hh.add_child(back_btn)

	_space(root, 32)

	#  Main content
	var body := HBoxContainer.new()
	body.add_theme_constant_override("margin_left", 40)
	body.add_theme_constant_override("margin_right", 40)
	body.add_theme_constant_override("separation", 24)
	root.add_child(body)

	_build_rest_card(body)
	_build_effects_panel(body)

	_space(root, 40)

	#  Message bar
	var msg_bar := _solid_panel(root, Color(0.05, 0.05, 0.07), Vector2(0, 38))
	_msg_lbl = Label.new()
	_msg_lbl.add_theme_font_override("font", _FONT_BODY)
	_msg_lbl.add_theme_font_size_override("font_size", 13)
	_msg_lbl.add_theme_color_override("font_color", Color(0.55, 0.92, 0.72))
	_msg_lbl.add_theme_constant_override("margin_left", 40)
	_msg_lbl.set_anchors_and_offsets_preset(Control.PRESET_VCENTER_WIDE)
	msg_bar.add_child(_msg_lbl)

	_space(root, 16)


func _build_rest_card(parent: HBoxContainer) -> void:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(380, 280)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_border_panel_style(pc, _GOLD)
	parent.add_child(pc)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.add_theme_constant_override("margin_left", 28)
	box.add_theme_constant_override("margin_right", 28)
	box.add_theme_constant_override("margin_top", 24)
	box.add_theme_constant_override("margin_bottom", 24)
	pc.add_child(box)

	# Eyebrow chip
	var chip := _tag_chip("Full Rest", _GOLD)
	box.add_child(chip)

	_lbl(box, "Recover Party Resources", 20, _FG, _FONT_DISPLAY)
	_lbl(box, "The party sleeps deeply. All HP, Temper, and Ether are restored.\nMinor status effects are cleared before the next descent.", 14, _FG2, _FONT_BODY)

	_sep(box)

	_cost_lbl = Label.new()
	_cost_lbl.add_theme_font_override("font", _FONT_BODY)
	_cost_lbl.add_theme_font_size_override("font_size", 14)
	_cost_lbl.add_theme_color_override("font_color", _FG2)
	_cost_lbl.text = "Cost: %d Soul Shards" % REST_COST
	box.add_child(_cost_lbl)

	var shards_now: int = _meta.get_currency(Currency.SOUL_SHARDS) if _meta else 0
	var note := Label.new()
	note.add_theme_font_override("font", _FONT_BODY)
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", _DIM)
	note.text = "You have %d Soul Shards." % shards_now
	box.add_child(note)

	_space(box, 8)

	_rest_btn = _gold_btn("Rest the Party")
	_rest_btn.custom_minimum_size = Vector2(0, 48)
	_rest_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rest_btn.disabled = shards_now < REST_COST
	_rest_btn.pressed.connect(_on_rest)
	if shards_now < REST_COST:
		_rest_btn.text = "Not Enough Soul Shards"
	box.add_child(_rest_btn)


func _build_effects_panel(parent: HBoxContainer) -> void:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(300, 0)
	_border_panel_style(pc, Color(0.784, 0.663, 0.431, 0.25))
	parent.add_child(pc)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.add_theme_constant_override("margin_left", 24)
	box.add_theme_constant_override("margin_right", 24)
	box.add_theme_constant_override("margin_top", 24)
	box.add_theme_constant_override("margin_bottom", 24)
	pc.add_child(box)

	_lbl(box, "REST EFFECTS", 12, _GOLD, _FONT_HEADER)

	var effects := [
		{"icon":"*", "label":"HP", "desc":"Fully restored to maximum.", "color":_HP},
		{"icon":"*", "label":"Temper", "desc":"Physical armor fully restored.", "color":_TMP},
		{"icon":"*", "label":"Ether", "desc":"Magical armor fully restored.", "color":_ETH},
		{"icon":"*", "label":"Status", "desc":"Minor status effects cleared.", "color":_FG2},
	]

	for ef in effects:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)

		var icon_lbl := Label.new()
		icon_lbl.text = str(ef["icon"])
		icon_lbl.add_theme_font_size_override("font_size", 20)
		icon_lbl.add_theme_color_override("font_color", ef["color"])
		icon_lbl.custom_minimum_size = Vector2(28, 0)
		row.add_child(icon_lbl)

		var text_col := VBoxContainer.new()
		text_col.add_theme_constant_override("separation", 2)
		row.add_child(text_col)

		_lbl(text_col, str(ef["label"]), 13, ef["color"], _FONT_DISPLAY)
		_lbl(text_col, str(ef["desc"]), 12, _FG2, _FONT_BODY)

	_sep(box)

	_lbl(box, "Future content: upgrading the inn may restore more resources, add buffs, or trigger character dialogue scenes.", 12, _DIM, _FONT_BODY)

#  INTERACTIONS

func _on_rest() -> void:
	if _meta == null:
		_show_msg("MetaProgression not available.", _DANGER)
		return
	if not _meta.spend({Currency.SOUL_SHARDS: REST_COST}):
		_show_msg("Not enough Soul Shards.", _DANGER)
		return
	_show_msg("The party rests. Resources restored.")
	_rest_btn.disabled = true
	_rest_btn.text     = "Rested "
	_refresh_gold_lbl()
	rested.emit(REST_COST)


func _refresh_gold_lbl() -> void:
	if _gold_lbl == null:
		return
	var amount: int = _meta.get_currency(Currency.SOUL_SHARDS) if _meta else 0
	_gold_lbl.text = "Soul Shards: %d" % amount


func _show_msg(text: String, color: Color = Color(0.55, 0.92, 0.72)) -> void:
	if _msg_lbl:
		_msg_lbl.text = text
		_msg_lbl.add_theme_color_override("font_color", color)

#  WIDGET HELPERS

func _lbl(parent: Control, text: String, sz: int, color: Color, font: Font) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


func _eyebrow(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _FONT_UI)
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", _DIM)
	l.add_theme_constant_override("character_spacing", 4)
	parent.add_child(l)
	return l


func _tag_chip(text: String, color: Color) -> PanelContainer:
	var pc  := PanelContainer.new()
	var st  := StyleBoxFlat.new()
	st.bg_color     = color.darkened(0.65)
	st.border_color = color.lerp(Color.TRANSPARENT, 0.3)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	st.content_margin_left = 10; st.content_margin_right  = 10
	st.content_margin_top  = 4;  st.content_margin_bottom = 4
	pc.add_theme_stylebox_override("panel", st)
	pc.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _FONT_UI)
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("character_spacing", 2)
	pc.add_child(l)
	return pc


func _chip_panel() -> PanelContainer:
	var pc := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.12, 0.11, 0.08)
	st.border_color = _GOLD.lerp(Color.TRANSPARENT, 0.5)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	st.content_margin_left = 12; st.content_margin_right  = 12
	st.content_margin_top  = 5;  st.content_margin_bottom = 5
	pc.add_theme_stylebox_override("panel", st)
	return pc


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


func _border_panel_style(pc: PanelContainer, accent: Color) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color     = _SURFACE
	st.border_color = accent.lerp(Color.TRANSPARENT, 0.45)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	st.content_margin_left = 0; st.content_margin_right  = 0
	st.content_margin_top  = 0; st.content_margin_bottom = 0
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
	st.bg_color     = _GOLD
	st.border_color = _GOLD.darkened(0.3)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	st.content_margin_left = 22; st.content_margin_right  = 22
	st.content_margin_top  = 12; st.content_margin_bottom = 12
	st.shadow_color = Color(_GOLD.r, _GOLD.g, _GOLD.b, 0.3)
	st.shadow_size  = 14
	btn.add_theme_stylebox_override("normal", st)
	var hv := st.duplicate() as StyleBoxFlat
	hv.bg_color    = _GOLD.lightened(0.15)
	hv.shadow_size = 22
	btn.add_theme_stylebox_override("hover", hv)
	var dis := StyleBoxFlat.new()
	dis.bg_color     = Color(0.12, 0.11, 0.09)
	dis.border_color = Color(0.20, 0.18, 0.14)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		dis.set_border_width(side, 1)
	dis.content_margin_left = 22; dis.content_margin_right  = 22
	dis.content_margin_top  = 12; dis.content_margin_bottom = 12
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
