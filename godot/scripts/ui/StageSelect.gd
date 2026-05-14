## StageSelect.gd
## Map selection screen between battles.
## Sets GameState.selected_map_index then loads Battle.tscn.
class_name StageSelect
extends Control

const MAPS: Array[Dictionary] = [
	{
		"index":       0,
		"id":          "ashvale_road_01",
		"title":       "Ashvale Road",
		"subtitle":    "Chapter 1 — Open fields, shallow water, high ground",
		"reward":      "150g  +40 JP",
		"difficulty":  "★☆☆",
	},
	{
		"index":       1,
		"id":          "crypt_of_echoes_01",
		"title":       "Crypt of Echoes",
		"subtitle":    "Chapter 2 — Stone corridors, fire traps, raised dais",
		"reward":      "220g  +60 JP",
		"difficulty":  "★★☆",
	},
	{
		"index":       2,
		"id":          "grasslands_first_fight_01",
		"title":       "Grasslands First Fight",
		"subtitle":    "Chapter 1 — Open grass, ridges, water, raider pressure",
		"reward":      "180g  +55 JP",
		"difficulty":  "★★☆",
	},
]


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var gs: GameState = get_node_or_null("/root/GameState")

	# ── Title ─────────────────────────────────────────────────────────────
	var title_lbl := Label.new()
	title_lbl.text = "SELECT STAGE"
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.95))
	title_lbl.set_anchor(SIDE_LEFT, 0.0)
	title_lbl.set_anchor(SIDE_RIGHT, 1.0)
	title_lbl.position.y = 48.0
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_lbl)

	if gs:
		var gold_lbl := Label.new()
		gold_lbl.text = "Gold: %d" % gs.gold
		gold_lbl.add_theme_font_size_override("font_size", 14)
		gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		gold_lbl.position = Vector2(1140.0, 52.0)
		add_child(gold_lbl)

	# ── Stage cards ───────────────────────────────────────────────────────
	var cards_root := VBoxContainer.new()
	cards_root.position = Vector2(240.0, 140.0)
	cards_root.custom_minimum_size = Vector2(800.0, 0.0)
	cards_root.add_theme_constant_override("separation", 20)
	add_child(cards_root)

	for map_def: Dictionary in MAPS:
		var map_id: String = map_def.get("id", "")
		var completed: bool = gs != null and map_id in gs.completed_stages
		cards_root.add_child(_build_card(map_def, completed))

	# ── Party button ──────────────────────────────────────────────────────
	var party_btn := Button.new()
	party_btn.text = "← Manage Party"
	party_btn.custom_minimum_size = Vector2(200, 44)
	party_btn.position = Vector2(40.0, 660.0)
	party_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/CharacterScreen.tscn"))
	add_child(party_btn)


func _build_card(map_def: Dictionary, completed: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 120.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 20)
	panel.add_child(inner)

	# ── Left: info block ──────────────────────────────────────────────────
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(info)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	info.add_child(title_row)

	var t_lbl := Label.new()
	t_lbl.text = map_def.get("title", "?")
	t_lbl.add_theme_font_size_override("font_size", 22)
	t_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title_row.add_child(t_lbl)

	if completed:
		var clear_lbl := Label.new()
		clear_lbl.text = "CLEAR"
		clear_lbl.add_theme_font_size_override("font_size", 12)
		clear_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.45))
		title_row.add_child(clear_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = map_def.get("subtitle", "")
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68))
	info.add_child(sub_lbl)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 24)
	info.add_child(meta_row)

	_meta_chip(meta_row, "Rewards", map_def.get("reward", ""), Color(1.0, 0.85, 0.3))
	_meta_chip(meta_row, "Difficulty", map_def.get("difficulty", ""), Color(0.9, 0.55, 0.3))

	# ── Right: play button ────────────────────────────────────────────────
	var btn_col := VBoxContainer.new()
	btn_col.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_child(btn_col)

	var play_btn := Button.new()
	play_btn.text = "FIGHT"
	play_btn.custom_minimum_size = Vector2(110, 56)
	play_btn.add_theme_font_size_override("font_size", 18)
	var map_index: int = map_def.get("index", 0)
	play_btn.pressed.connect(func() -> void: _start_battle(map_index))
	btn_col.add_child(play_btn)

	return panel


func _meta_chip(parent: Control, key: String, value: String, color: Color) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	parent.add_child(box)

	var k_lbl := Label.new()
	k_lbl.text = key
	k_lbl.add_theme_font_size_override("font_size", 10)
	k_lbl.add_theme_color_override("font_color", Color(0.45, 0.48, 0.58))
	box.add_child(k_lbl)

	var v_lbl := Label.new()
	v_lbl.text = value
	v_lbl.add_theme_font_size_override("font_size", 13)
	v_lbl.add_theme_color_override("font_color", color)
	box.add_child(v_lbl)


func _start_battle(map_index: int) -> void:
	var gs: GameState = get_node_or_null("/root/GameState")
	if gs:
		gs.selected_map_index = map_index
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
