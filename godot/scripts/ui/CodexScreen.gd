## CodexScreen.gd
## In-game mechanics and lore reference. Entries are gated behind narrative
## flags  players unlock topics by experiencing them in-game.
## Entries are defined as constants below; no external data file required.
##
## Signals:
##   back_pressed   return to previous screen

class_name CodexScreen
extends Control

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
const _PARCH   := Color(0.929, 0.878, 0.761)  # parchment

#  Category colours
const _CAT_COLORS := {
	"Mechanics":   Color(0.22, 0.74,  1.00),
	"Lore":        Color(0.831, 0.686, 0.275),
	"Characters":  Color(0.66,  0.33,  0.97),
	"Combat":      Color(0.93,  0.27,  0.27),
	"The World":   Color(0.30,  0.86,  0.50),
	"Mysteries":   Color(0.55,  0.55,  0.75),
}

#  CODEX ENTRIES
#  Each entry: {id, category, flag, title, summary, gameplay_note}
#  flag = ""  always visible
#  flag = "some_flag"  only visible when GameState.narrative_flags[flag]

const _ENTRIES := [
	#  Always visible (tutorial / core rules)
	{
		"id":       "action_points",
		"category": "Mechanics",
		"flag":     "",
		"title":    "Action Points",
		"summary":  "Each unit begins their turn with Action Points (AP). Movement and abilities consume AP. When AP reaches zero, the turn ends. Units regenerate AP at the start of each turn.",
		"gameplay_note": "Conserving AP for abilities often wins battles.",
	},
	{
		"id":       "facing",
		"category": "Mechanics",
		"flag":     "",
		"title":    "Facing & Flanking",
		"summary":  "Units face one of four cardinal directions. Attacks from the rear deal bonus damage; attacks from the side deal partial bonus damage. Some abilities require facing a specific direction.",
		"gameplay_note": "Positioning is as important as raw stats.",
	},
	{
		"id":       "terrain",
		"category": "Mechanics",
		"flag":     "",
		"title":    "Terrain",
		"summary":  "The battlefield has distinct terrain types: grass, stone, road, shrine, water, and more. Each type affects movement cost, elemental interactions, and line of sight.",
		"gameplay_note": "Shrines restore Ether at turn start. High ground improves ranged accuracy.",
	},
	{
		"id":       "hp_temper_ether",
		"category": "Combat",
		"flag":     "",
		"title":    "HP  Temper  Ether",
		"summary":  "Three defensive layers stack on each unit. Temper (physical armor) and Ether (magical armor) absorb damage before HP. When HP hits zero, the unit falls.",
		"gameplay_note": "Abilities that strip Temper before striking HP are high-value openers.",
	},
	{
		"id":       "jobs",
		"category": "Mechanics",
		"flag":     "",
		"title":    "Jobs",
		"summary":  "Every character can advance through Job trees  branching paths of abilities and stat bonuses unlocked with JP. Jobs define a character's combat role but not their identity.",
		"gameplay_note": "Switching jobs between runs is free. JP persists across jobs.",
	},
	{
		"id":       "boons",
		"category": "Mechanics",
		"flag":     "",
		"title":    "Guardian Boons",
		"summary":  "Each run, the Guardians offer boons  powerful effects that stack and interact across the run. Boons come in four rarities: Common, Rare, Legendary, and Unique.",
		"gameplay_note": "Legendary and Unique boons fundamentally reshape run strategy. Seek synergy.",
	},
	{
		"id":       "soul_shards",
		"category": "Mechanics",
		"flag":     "",
		"title":    "Soul Shards",
		"summary":  "The permanent meta-progression currency. Earned by completing runs and defeating enemies. Spent at the Last Hearth on permanent upgrades  stat increases, heat unlocks, and Guardian shrine upgrades.",
		"gameplay_note": "Run Aether converts to Soul Shards at run's end (10:1 ratio).",
	},

	#  Narrative-gated entries
	{
		"id":       "the_mountain",
		"category": "The World",
		"flag":     "first_run_complete",
		"title":    "The Mountain",
		"summary":  "The Appointed travel upward through a mountain the world has forgotten. Each floor is a layer of something ancient  sediment of a war older than the kingdoms below. At the top is either answers or annihilation.",
		"gameplay_note": "Each run traverses ten floors. The summit is floor 10.",
	},
	{
		"id":       "the_guardians",
		"category": "Lore",
		"flag":     "first_run_complete",
		"title":    "The Five Guardians",
		"summary":  "Ignareth, Nerevan, Torvahk, Luminarch, Vaelthorn. Elemental patrons who offer boons to those who climb. Their motives are their own. Their gifts carry weight.",
		"gameplay_note": "Each Guardian specializes in a damage element and strategic archetype.",
	},
	{
		"id":       "enemies_speak",
		"category": "Mysteries",
		"flag":     "enemy_spoke_words",
		"title":    "They Speak",
		"summary":  "In the heat of battle, one of them paused. Lowered a weapon. Said something that was not a threat. The party did not know what to do with this.",
		"gameplay_note": "Some enemies carry dialogue. These encounters are tracked across runs.",
	},
	{
		"id":       "revelation_tier",
		"category": "Mechanics",
		"flag":     "first_run_complete",
		"title":    "Revelation Tiers",
		"summary":  "Five tiers of understanding, earned by doing: completing runs, witnessing events, forming relationships, reaching resolutions. Each tier shifts the narrative  what characters see, what enemies say, what the mountain reveals.",
		"gameplay_note": "Tier 1: The War. Tier 2: The Cracks. Tier 3: The Fallen. Tier 4: The Pattern. Tier 5: The Ascent.",
	},
	{
		"id":       "crack_events",
		"category": "Characters",
		"flag":     "first_run_complete",
		"title":    "Crack Events",
		"summary":  "Each of the seven carries something they cannot admit. When circumstances force it into the open  the moment is called a Crack. A Crack does not break a character. It lets something through.",
		"gameplay_note": "Crack events trigger at Tier 2+ Revelation. One per character. Unrepeatable.",
	},
	{
		"id":       "the_seven",
		"category": "Characters",
		"flag":     "first_run_complete",
		"title":    "The Seven",
		"summary":  "Aeryn, Cael, Brennan, Solan, Mira, Tobias, Seren. Soldiers, scholars, rogues, clergy. They believe they are here to win a war. They are here to answer a question the war was always about.",
		"gameplay_note": "Each character has a unique story arc, job tree, and true name waiting to be found.",
	},
	{
		"id":       "the_mirror",
		"category": "Mysteries",
		"flag":     "first_run_complete",
		"title":    "The Mirror",
		"summary":  "A recurring figure. Does not appear the same way twice. Knows things it should not know. Targets one member of the party per encounter  and never the same one consecutively.",
		"gameplay_note": "Defeating the Mirror earns Revelation. Its dialogue changes across runs.",
	},
	{
		"id":       "heat",
		"category": "Mechanics",
		"flag":     "first_run_complete",
		"title":    "Heat",
		"summary":  "Optional difficulty modifiers unlocked at the Last Hearth. Higher heat levels add enemy HP, elite spawns, and champion-tier encounters  and multiply reward yields.",
		"gameplay_note": "Heat 0 is baseline. Each heat tier adds ~12% to reward multiplier.",
	},
	{
		"id":       "elites",
		"category": "Combat",
		"flag":     "first_run_complete",
		"title":    "Elite Enemies",
		"summary":  "Elites are variant enemies with elevated stats and a unique modifier: Guardian Marked, Iron-Skinned, Soulbound, Spectral, Enraged, or Hexed. They drop Obsidian  the rare upgrade material.",
		"gameplay_note": "Champion-tier elites appear at Heat 3+. They carry two modifiers.",
	},
	{
		"id":       "wanderers",
		"category": "Lore",
		"flag":     "first_run_complete",
		"title":    "Wanderers",
		"summary":  "Between floors, the party sometimes encounters figures who do not belong on a battlefield: a cartographer, a refugee, a disgraced cleric. These are Wanderers. Their bargains are strange and their gratitude is real.",
		"gameplay_note": "Wanderer nodes appear on the run map. Their offers are unique-per-run and do not repeat.",
	},
	{
		"id":       "curses",
		"category": "Mechanics",
		"flag":     "first_run_complete",
		"title":    "Curses",
		"summary":  "The mountain offers burdens with its gifts. Accepting a Curse grants an immediate boon but imposes a run-long penalty. Some curses are debts. Some are punishments. Some are invitations.",
		"gameplay_note": "Curse and boon synergies exist. A skilled player can build around them.",
	},
	{
		"id":       "true_names",
		"category": "Mysteries",
		"flag":     "enemy_spoke_words",
		"title":    "True Names",
		"summary":  "Each of the seven has a name they have forgotten  or was taken from them. The mountain remembers. Fragments surface through encounters, dialogue, and choices. Recovering a true name changes everything.",
		"gameplay_note": "True name fragments lower Costume Integrity. Full revelation triggers Tier 5 arc content.",
	},
]

#  State
var _active_category: String = "All"
var _gs: Node

#  UI refs
var _cat_bar: HBoxContainer


func _ready() -> void:
	_gs = get_node_or_null("/root/GameState")
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
	root.custom_minimum_size = Vector2(1000, 0)
	root.add_theme_constant_override("separation", 0)
	scroll.add_child(root)

	_build_header(root)
	_build_category_bar(root)
	_space(root, 24)
	_build_entries(root)
	_space(root, 40)


func _build_header(root: VBoxContainer) -> void:
	var hdr := _solid_panel(root, _SURFACE2, Vector2(0, 80))
	var hh  := HBoxContainer.new()
	hh.add_theme_constant_override("margin_left", 40)
	hh.add_theme_constant_override("margin_right", 40)
	hh.alignment = BoxContainer.ALIGNMENT_CENTER
	hh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hdr.add_child(hh)

	var col := VBoxContainer.new()
	hh.add_child(col)
	_eyebrow(col, "ARCHIVE")
	_lbl(col, "Codex", 26, _FG, _FONT_DISPLAY)

	var stretch := Control.new()
	stretch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(stretch)

	# Unlocked count
	var unlocked := _unlocked_entries()
	var chip := _chip(Color(1, 1, 1, 0.12))
	hh.add_child(chip)
	var count_lbl := Label.new()
	count_lbl.add_theme_font_override("font", _FONT_DISPLAY)
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", _FG2)
	count_lbl.text = "%d / %d Entries Unlocked" % [unlocked.size(), _ENTRIES.size()]
	chip.add_child(count_lbl)

	_hspace(hh, 12)

	var back := _iron_btn(" Back")
	back.pressed.connect(func() -> void: back_pressed.emit())
	hh.add_child(back)


func _build_category_bar(root: VBoxContainer) -> void:
	var bar := _solid_panel(root, Color(0.05, 0.05, 0.07), Vector2(0, 44))
	_cat_bar = HBoxContainer.new()
	_cat_bar.add_theme_constant_override("margin_left", 40)
	_cat_bar.add_theme_constant_override("separation", 10)
	_cat_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	_cat_bar.set_anchors_and_offsets_preset(Control.PRESET_VCENTER_WIDE)
	bar.add_child(_cat_bar)

	var cats := ["All"] + _CAT_COLORS.keys()
	for cat_name in cats:
		var cat: String = str(cat_name)
		var is_active   := _active_category == cat
		var cat_col: Color = _CAT_COLORS.get(cat, _GOLD) if cat != "All" else _GOLD

		var fbtn := Button.new()
		fbtn.text = cat
		fbtn.add_theme_font_override("font", _FONT_UI)
		fbtn.add_theme_font_size_override("font_size", 13)
		fbtn.add_theme_color_override("font_color",       cat_col if is_active else _FG2)
		fbtn.add_theme_color_override("font_hover_color", cat_col)
		var st := StyleBoxFlat.new()
		st.bg_color     = _SURFACE.lightened(0.05) if is_active else Color(0, 0, 0, 0)
		st.border_color = cat_col if is_active else Color(1, 1, 1, 0.12)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			st.set_border_width(side, 1)
		st.content_margin_left = 12; st.content_margin_right  = 12
		st.content_margin_top  = 5;  st.content_margin_bottom = 5
		fbtn.add_theme_stylebox_override("normal", st)
		fbtn.pressed.connect(func() -> void: _set_category(cat))
		_cat_bar.add_child(fbtn)


func _build_entries(root: VBoxContainer) -> void:
	var entry_wrap := HBoxContainer.new()
	entry_wrap.add_theme_constant_override("margin_left",  40)
	entry_wrap.add_theme_constant_override("margin_right", 40)
	root.add_child(entry_wrap)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_wrap.add_child(vbox)

	var visible_entries := _filtered_entries()

	if visible_entries.is_empty():
		_build_empty(vbox)
		return

	for entry in visible_entries:
		vbox.add_child(_entry_card(entry))


func _entry_card(entry: Dictionary) -> PanelContainer:
	var cat: String    = str(entry.get("category", "Mechanics"))
	var cat_col: Color = _CAT_COLORS.get(cat, _GOLD)

	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color     = _SURFACE
	st.border_color = cat_col.lerp(Color.TRANSPARENT, 0.5)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	st.border_width_left = 3  # category accent on left edge
	st.border_color_left = cat_col
	pc.add_theme_stylebox_override("panel", st)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	hbox.add_theme_constant_override("margin_left",   20)
	hbox.add_theme_constant_override("margin_right",  24)
	hbox.add_theme_constant_override("margin_top",    18)
	hbox.add_theme_constant_override("margin_bottom", 18)
	pc.add_child(hbox)

	# Left: category pill + title
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.custom_minimum_size = Vector2(220, 0)
	hbox.add_child(left)

	var cat_lbl := Label.new()
	cat_lbl.text = cat.to_upper()
	cat_lbl.add_theme_font_override("font", _FONT_UI)
	cat_lbl.add_theme_font_size_override("font_size", 10)
	cat_lbl.add_theme_color_override("font_color", cat_col)
	cat_lbl.add_theme_constant_override("character_spacing", 3)
	left.add_child(cat_lbl)

	var title := Label.new()
	title.text = str(entry.get("title", ""))
	title.add_theme_font_override("font", _FONT_DISPLAY)
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", _FG)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(title)

	# Right: summary + gameplay note
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right)

	var summary := Label.new()
	summary.text = str(entry.get("summary", ""))
	summary.add_theme_font_override("font", _FONT_BODY)
	summary.add_theme_font_size_override("font_size", 14)
	summary.add_theme_color_override("font_color", _FG2)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(summary)

	var gn: String = str(entry.get("gameplay_note", ""))
	if gn != "":
		var note := Label.new()
		note.text = " " + gn
		note.add_theme_font_override("font", _FONT_UI)
		note.add_theme_font_size_override("font_size", 13)
		note.add_theme_color_override("font_color", cat_col.lerp(_FG2, 0.35))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		right.add_child(note)

	return pc


func _build_empty(parent: Control) -> void:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.custom_minimum_size = Vector2(0, 180)
	var st := StyleBoxFlat.new()
	st.bg_color     = _SURFACE
	st.border_color = Color(1, 1, 1, 0.06)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	pc.add_theme_stylebox_override("panel", st)
	parent.add_child(pc)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	inner.add_theme_constant_override("margin_left",   40)
	inner.add_theme_constant_override("margin_right",  40)
	inner.add_theme_constant_override("margin_top",    40)
	inner.add_theme_constant_override("margin_bottom", 40)
	pc.add_child(inner)

	_lbl(inner, "No Entries Unlocked Yet", 20, _FG2, _FONT_DISPLAY)
	_lbl(inner, "Continue the prologue to unlock your first Codex topics.\nEach discovery in the field is archived here for reference.", 14, _DIM, _FONT_BODY)

#  DATA HELPERS

func _unlocked_entries() -> Array:
	return _ENTRIES.filter(func(e: Dictionary) -> bool:
		var flag: String = str(e.get("flag", ""))
		if flag == "":
			return true
		if _gs == null:
			return false
		return bool(_gs.narrative_flags.get(flag, false)))


func _filtered_entries() -> Array:
	var unlocked := _unlocked_entries()
	if _active_category == "All":
		return unlocked
	return unlocked.filter(func(e: Dictionary) -> bool:
		return str(e.get("category", "")) == _active_category)


func _set_category(cat: String) -> void:
	_active_category = cat
	_build_ui()

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


func _chip(border: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.12, 0.11, 0.08)
	st.border_color = border.lerp(Color.TRANSPARENT, 0.45)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_border_width(side, 1)
	st.content_margin_left = 12; st.content_margin_right  = 12
	st.content_margin_top  = 4;  st.content_margin_bottom = 4
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


func _space(parent: Control, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)


func _hspace(parent: HBoxContainer, w: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(w, 0)
	parent.add_child(s)
