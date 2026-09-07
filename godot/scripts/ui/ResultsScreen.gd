## ResultsScreen.gd
## Shows after every battle or run end.
## Death screen: explains what killed you + what would have helped.
## Victory screen: full run summary.

class_name ResultsScreen
extends Control

const BG    := Color(0.04, 0.05, 0.08)
const FG    := Color(0.97, 0.94, 0.87)
const DIM   := Color(0.45, 0.42, 0.38)
const GOLD  := Color(0.79, 0.65, 0.34)
const RED   := Color(0.93, 0.27, 0.27)
const GREEN := Color(0.53, 0.94, 0.67)

const GUARDIAN_COLORS := {
	"ignareth": Color(1.0,0.57,0.20), "nerevan": Color(0.22,0.74,1.0),
	"torvahk": Color(1.0,0.92,0.27), "luminarch": Color(1.0,0.96,0.60),
	"vaelthorn": Color(0.66,0.33,0.97),
}

var _gs: Node

func _ready() -> void:
	_gs = get_node_or_null("/root/GameState")
	_build_ui()


func _build_ui() -> void:
	for c in get_children(): c.queue_free()

	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var rewards: Dictionary  = _gs.pending_rewards if _gs else {}
	var death: Dictionary    = (_gs.last_run_death if _gs else {}) if _gs else {}
	var floor: int           = _gs.run_floor_reached if _gs else 0
	var is_defeat: bool      = not death.is_empty()
	var is_run_end: bool     = floor > 0 and _gs != null
	var is_complete: bool    = floor >= 10 and is_defeat == false

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(960, 0)
	root.add_theme_constant_override("separation", 0)
	root.add_theme_constant_override("margin_left", 48)
	root.add_theme_constant_override("margin_right", 48)
	root.add_theme_constant_override("margin_top", 36)
	scroll.add_child(root)

	#  Header
	if is_complete:
		_lbl(root, "THE VAULT FALLS SILENT", 13, DIM)
		_space(root, 4)
		_lbl(root, "Run Complete.", 40, GOLD)
		_space(root, 6)
		_lbl(root, "The Sleeping Anchor has been shattered.", 15, DIM)
	elif is_defeat:
		_lbl(root, "FALLEN", 13, DIM)
		_space(root, 4)
		_lbl(root, "Floor %d  The party falls." % floor, 38, RED)
	else:
		_lbl(root, "BATTLE COMPLETE", 13, DIM)
		_space(root, 4)
		_lbl(root, "Onward.", 30, GOLD)

	_space(root, 20)
	_separator(root)
	_space(root, 18)

	#  DEATH SCREEN
	if is_defeat and is_run_end:
		# How you fell
		var fell_panel := _bordered_panel(root, RED.darkened(0.6), RED.darkened(0.3))
		var fell_box := VBoxContainer.new()
		fell_box.add_theme_constant_override("margin_left",20)
		fell_box.add_theme_constant_override("margin_right",20)
		fell_box.add_theme_constant_override("margin_top",16)
		fell_box.add_theme_constant_override("margin_bottom",16)
		fell_box.add_theme_constant_override("separation",8)
		fell_panel.add_child(fell_box)

		_lbl(fell_box, "HOW YOU FELL", 10, RED.lightened(0.2))
		_space(fell_box, 2)

		var victim:  String = death.get("victim_name","your party")
		var killer:  String = death.get("killer_name","an enemy")
		var ability: String = death.get("ability_used","an attack")
		var was_elite: bool = death.get("was_elite",false)
		var was_anchor: bool = death.get("was_anchor",false)
		var elite_tier: String = death.get("elite_tier","")

		var death_line: String
		if was_anchor:
			death_line = "%s was killed by The Anchor's void pulse." % victim
		elif was_elite:
			death_line = "%s was killed by %s %s." % [victim, elite_tier.capitalize(), killer]
		else:
			death_line = "%s was killed by %s using %s." % [victim, killer, ability]
		_lbl(fell_box, death_line, 15, FG)

		# What would have helped
		_space(fell_box, 8)
		_lbl(fell_box, "WHAT MIGHT HELP NEXT RUN", 10, GREEN.darkened(0.1))
		_space(fell_box, 2)
		var suggestions := _get_suggestions(death, _gs)
		for s in suggestions:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation",8)
			fell_box.add_child(row)
			_lbl_widget(row, "", 13, GREEN)
			var lbl := Label.new()
			lbl.text = s
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", Color(0.85,0.9,0.85))
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(lbl)

		# Active curses at time of death
		if _gs and _gs.active_run and not _gs.active_run.active_curses.is_empty():
			_space(fell_box, 8)
			_lbl(fell_box, "ACTIVE CURSES", 10, Color(0.85,0.3,0.3))
			var curse_row := HBoxContainer.new()
			curse_row.add_theme_constant_override("separation",8)
			fell_box.add_child(curse_row)
			for curse in _gs.active_run.active_curses:
				var chip := _chip(curse.get("icon","") + " " + curse.get("name","?"), Color(0.85,0.3,0.3))
				curse_row.add_child(chip)

		_space(root, 16)

	#  RUN STATS GRID
	if is_run_end:
		var boons: Array  = (_gs.active_run.active_boons if _gs.active_run else []) if _gs else []
		var items: Array  = (_gs.run_inventory if _gs else [])
		var elites: int   = (_gs.active_run.elite_kills if _gs.active_run else 0) if _gs else 0
		var jp: int       = (_gs.run_jp_earned if _gs else 0)
		var gold: int     = rewards.get("gold", 0)

		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		root.add_child(grid)

		var stat_color := GOLD if is_complete else Color(0.75,0.75,0.85)
		grid.add_child(_stat_card("Floor Reached", str(floor) + " / 10", stat_color))
		grid.add_child(_stat_card("Elites Slain",  str(elites),           Color(1.0,0.6,0.2)))
		grid.add_child(_stat_card("JP Earned",      str(jp),              Color(0.48,0.86,1.0)))
		grid.add_child(_stat_card("Gold",           str(gold) + "g",      Color(0.9,0.8,0.3)))
		grid.add_child(_stat_card("Items Found",    str(items.size()),    Color(0.75,0.32,0.97)))
		grid.add_child(_stat_card("Boons Held",     str(boons.size()),    GREEN))

		# Boons row
		if boons.size() > 0:
			_space(root, 16)
			_lbl(root, "Boons You Carried", 13, DIM)
			_space(root, 8)
			var brow := HBoxContainer.new()
			brow.add_theme_constant_override("separation",8)
			root.add_child(brow)
			for boon in boons:
				brow.add_child(_chip(
					boon.get("icon","") + "  " + boon.get("name","?"),
					GUARDIAN_COLORS.get(boon.get("guardian",""), GOLD)))

		# Items row
		if items.size() > 0:
			_space(root, 12)
			_lbl(root, "Items Found", 13, DIM)
			_space(root, 8)
			var irow := HBoxContainer.new()
			irow.add_theme_constant_override("separation",8)
			root.add_child(irow)
			for item in items:
				irow.add_child(_chip(item.get("icon","") + "  " + item.get("name","?"),
					item.get("color", DIM)))

		var loadout_progress: Dictionary = rewards.get("loadout_progress", {})
		if not loadout_progress.is_empty():
			_space(root, 12)
			_lbl(root, "Vow / Sigil Progress", 13, DIM)
			_space(root, 8)
			var xp_amount := int(loadout_progress.get("amount", rewards.get("loadout_xp", 0)))
			var vow_id := str(loadout_progress.get("vow_id", ""))
			var sigil_id := str(loadout_progress.get("sigil_id", ""))
			var vow := VowSigilSystem.get_vow(vow_id)
			var sigil := VowSigilSystem.get_sigil(sigil_id)
			var loadout_row := HBoxContainer.new()
			loadout_row.add_theme_constant_override("separation", 8)
			root.add_child(loadout_row)
			loadout_row.add_child(_chip("+%d XP" % xp_amount, GOLD))
			loadout_row.add_child(_chip("%s Lv.%d" % [
				vow.get("short_name", "Vow"),
				int(loadout_progress.get("vow_level_after", 1)),
			], GOLD))
			loadout_row.add_child(_chip("%s Lv.%d" % [
				sigil.get("short_name", "Sigil"),
				int(loadout_progress.get("sigil_level_after", 1)),
			], Color(0.48,0.86,1.0)))
			if bool(loadout_progress.get("vow_leveled", false)) or bool(loadout_progress.get("sigil_leveled", false)):
				_space(root, 6)
				_lbl(root, "New attunement unlocked. Future boon offers are now more strongly weighted.", 13, GOLD)

		# Soul Shards earned
		var rm: Node = get_node_or_null("/root/RunManager")
		if rm:
			var shards := int(rm.run_aether / 10) + (25 if is_complete else 0)
			_space(root, 12)
			_lbl(root, "Soul Shards Earned: %d" % shards, 14, GOLD)

	_space(root, 24)
	_separator(root)
	_space(root, 20)

	#  Continue button
	var btn_text: String
	var btn_col:  Color
	var btn_dest: String

	if is_complete:
		btn_text = "Return to the Hearth  "
		btn_col  = GOLD
		btn_dest = "res://scenes/HubScene.tscn"
		if _gs:
			_gs.run_floor_reached = 0; _gs.run_jp_earned = 0
			_gs.run_inventory.clear(); _gs.last_run_death.clear()
			_gs.best_floor_reached = max(_gs.best_floor_reached, floor)
	elif is_defeat:
		btn_text = "Back to the Hearth"
		btn_col  = Color(0.7, 0.55, 0.55)
		btn_dest = "res://scenes/HubScene.tscn"
		if _gs:
			_gs.run_floor_reached = 0; _gs.run_jp_earned = 0
			_gs.run_inventory.clear()
			_gs.last_run_death.clear()
			_gs.best_floor_reached = max(_gs.best_floor_reached, floor)
			_gs.active_run = null
	else:
		btn_text = "Continue  "
		btn_col  = Color(0.48,0.86,1.0)
		btn_dest = "res://scenes/CharacterScreen.tscn"

	var btn := _btn(btn_text, btn_col)
	btn.custom_minimum_size = Vector2(260, 50)
	btn.pressed.connect(func() -> void: get_tree().change_scene_to_file(btn_dest))
	root.add_child(btn)
	_space(root, 48)


#  Suggestion engine

func _get_suggestions(death: Dictionary, gs: Node) -> Array[String]:
	var s: Array[String] = []
	var killer_type: String = death.get("killer_type","")
	var was_anchor:  bool   = death.get("was_anchor", false)
	var was_elite:   bool   = death.get("was_elite", false)
	var elite_tier:  String = death.get("elite_tier","")
	var had_curses:  int    = death.get("had_curses", 0)

	var boon_ids: Array = []
	if gs and gs.active_run:
		boon_ids = gs.active_run.active_boons.map(func(b: Dictionary)->String: return b.get("id",""))

	if was_anchor:
		s.append("Luminarch's Covenant boon halves the Anchor's pulse damage  holy abilities hit it for 2.5 normal.")
		s.append("Keep your party 3+ tiles from the Anchor when it drops below 50% HP  the Phase 2 pulse is double-width.")
		if not "luminarch_light" in boon_ids:
			s.append("A Luminary job on Mira gives access to Consecrate (holy, 3-tile range)  ideal for hitting the Anchor safely.")
	elif was_elite:
		if elite_tier == "champion":
			s.append("Champions have 2+ prefixes. Void Sight boon reveals affixes before the battle  no surprises.")
		s.append("Champion's Grit boon turns elite kills into heals: each elite killed restores 30 HP to the attacker.")
		var curse_ids: Array[String] = []
		if gs and gs.active_run:
			for curse: Dictionary in gs.active_run.active_curses:
				curse_ids.append(str(curse.get("id", "")))
		if "null_resonance" in curse_ids:
			s.append("The Null Resonance curse gave every enemy an extra affix - that's what made this elite hit harder.")
	elif killer_type == "void_cultist":
		s.append("Void Cultists drain Ether fast. Kill them first  their magic output drops to zero at 0 Ether.")
	elif killer_type == "storm_imp":
		s.append("Storm Imps have 0 thunder resistance (immune). Hit them with fire or blizzard  1.5 and 1.75 affinity.")
	elif killer_type == "fen_wraith":
		s.append("Fen Wraiths take 1.75 holy damage. Mira's holy abilities are the fastest way through them.")

	if had_curses >= 2 and s.size() < 2:
		s.append("Two active curses reshape the run significantly. Void Hunger + Tide's Price together require very high healing output.")

	if not "swift_recovery" in boon_ids and not was_anchor:
		s.append("Swift Recovery boon restores 25% HP between floors  often the difference on Floors 7-9.")

	return s.slice(0, 3)   # Max 3 suggestions


#  Widget helpers

func _lbl(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l); return l

func _lbl_widget(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l); return l

func _space(parent: Control, h: int) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(0,h); parent.add_child(s)

func _separator(parent: Control) -> void:
	var sep := HSeparator.new()
	var st := StyleBoxFlat.new(); st.bg_color = Color(1,1,1,0.08)
	sep.add_theme_stylebox_override("separator", st); parent.add_child(sep)

func _bordered_panel(parent: Control, bg: Color, border: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color = bg; st.border_color = border
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side,1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]:
		st.set_corner_radius(c, 12)
	pc.add_theme_stylebox_override("panel", st)
	parent.add_child(pc); return pc

func _stat_card(label: String, value: String, color: Color) -> PanelContainer:
	var pc := PanelContainer.new(); pc.custom_minimum_size = Vector2(240,80)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.07,0.08,0.12); st.border_color = color.lerp(Color.TRANSPARENT,0.5)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side,1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]: st.set_corner_radius(c,10)
	pc.add_theme_stylebox_override("panel",st)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("margin_left",16)
	box.add_theme_constant_override("margin_top",12)
	box.add_theme_constant_override("separation",4)
	pc.add_child(box)
	var vl := Label.new(); vl.text = value
	vl.add_theme_font_size_override("font_size",26)
	vl.add_theme_color_override("font_color",color); box.add_child(vl)
	var ll := Label.new(); ll.text = label
	ll.add_theme_font_size_override("font_size",11)
	ll.add_theme_color_override("font_color",DIM); box.add_child(ll)
	return pc

func _chip(text: String, color: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = color.darkened(0.65); st.border_color = color.lerp(Color.TRANSPARENT,0.4)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side,1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]: st.set_corner_radius(c,8)
	st.content_margin_left=10; st.content_margin_right=10
	st.content_margin_top=6; st.content_margin_bottom=6
	pc.add_theme_stylebox_override("panel",st)
	var lbl := Label.new(); lbl.text = text
	lbl.add_theme_font_size_override("font_size",12)
	lbl.add_theme_color_override("font_color",color)
	pc.add_child(lbl); return pc

func _btn(text: String, color: Color) -> Button:
	var b := Button.new(); b.text = text
	var st := StyleBoxFlat.new()
	st.bg_color = color.darkened(0.55); st.border_color = color.lerp(Color.TRANSPARENT,0.3)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: st.set_border_width(side,1)
	for c in [CORNER_TOP_LEFT,CORNER_TOP_RIGHT,CORNER_BOTTOM_LEFT,CORNER_BOTTOM_RIGHT]: st.set_corner_radius(c,10)
	b.add_theme_stylebox_override("normal",st); b.add_theme_stylebox_override("hover",st)
	b.add_theme_color_override("font_color",color)
	b.add_theme_font_size_override("font_size",15); return b
