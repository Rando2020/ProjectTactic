## CharacterScreen.gd
## Between-battle JP spending screen.
## Shows each player unit with their JP balance and learnable abilities.
class_name CharacterScreen
extends Control

var _gs: GameState

const UNIT_IDS: Array[String] = ["zane", "mira", "kael", "lyra"]
# Column panels rebuilt when an ability is purchased
var _columns: Array[VBoxContainer] = []


func _ready() -> void:
	_gs = get_node_or_null("/root/GameState")
	_build_ui()


func _build_ui() -> void:
	# Clear previous build (called again after purchases)
	for child in get_children():
		child.queue_free()
	_columns.clear()

	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Title bar ────────────────────────────────────────────────────────
	var title_bar := ColorRect.new()
	title_bar.color = Color(0.10, 0.12, 0.17)
	title_bar.set_anchor(SIDE_LEFT, 0.0)
	title_bar.set_anchor(SIDE_RIGHT, 1.0)
	title_bar.size.y = 60.0
	add_child(title_bar)

	var title_lbl := Label.new()
	title_lbl.text = "MANAGE PARTY"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.95))
	title_lbl.set_anchor(SIDE_LEFT, 0.0)
	title_lbl.set_anchor(SIDE_RIGHT, 1.0)
	title_lbl.position.y = 14.0
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_lbl)

	# ── Gold display ──────────────────────────────────────────────────────
	var gold_lbl := Label.new()
	gold_lbl.text = "Gold: %d" % (_gs.gold if _gs else 0)
	gold_lbl.add_theme_font_size_override("font_size", 14)
	gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	gold_lbl.position = Vector2(1180.0, 18.0)
	add_child(gold_lbl)

	# ── Unit columns ─────────────────────────────────────────────────────
	var columns_root := HBoxContainer.new()
	columns_root.position = Vector2(20.0, 70.0)
	columns_root.size = Vector2(1240.0, 580.0)
	columns_root.add_theme_constant_override("separation", 12)
	add_child(columns_root)

	for uid: String in UNIT_IDS:
		var col := _build_unit_column(uid)
		columns_root.add_child(col)
		_columns.append(col)

	# ── Bottom nav ────────────────────────────────────────────────────────
	var nav_row := HBoxContainer.new()
	nav_row.position = Vector2(20.0, 660.0)
	nav_row.size = Vector2(1240.0, 48.0)
	nav_row.alignment = BoxContainer.ALIGNMENT_END
	add_child(nav_row)

	var next_btn := Button.new()
	next_btn.text = "Select Stage  →"
	next_btn.custom_minimum_size = Vector2(220, 44)
	next_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/StageSelect.tscn"))
	nav_row.add_child(next_btn)


func _build_unit_column(uid: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(285.0, 0.0)
	col.add_theme_constant_override("separation", 8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if not _gs or not _gs.unit_registry.has(uid):
		return col

	var reg: Dictionary = _gs.unit_registry[uid]

	# ── Header panel ──────────────────────────────────────────────────────
	var header_bg := ColorRect.new()
	header_bg.color = Color(0.12, 0.15, 0.22)
	header_bg.custom_minimum_size = Vector2(0.0, 72.0)
	col.add_child(header_bg)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 2)
	header_bg.add_child(header_box)
	header_box.set_anchor(SIDE_LEFT, 0.0)
	header_box.set_anchor(SIDE_RIGHT, 1.0)
	header_box.position = Vector2(12.0, 10.0)

	var name_lbl := Label.new()
	name_lbl.text = reg.get("display_name", uid)
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	header_box.add_child(name_lbl)

	var jp_lbl := Label.new()
	jp_lbl.text = "%d JP available" % reg.get("jp", 0)
	jp_lbl.add_theme_font_size_override("font_size", 13)
	jp_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	header_box.add_child(jp_lbl)

	# ── Known abilities ───────────────────────────────────────────────────
	col.add_child(_section_lbl("KNOWN ABILITIES"))

	var all_known: Array[String] = []
	all_known.append_array(reg.get("base_abilities", []))
	all_known.append_array(reg.get("learned_abilities", []))

	for ab_id: String in all_known:
		var ab: Dictionary = AbilityDB.get_ability(ab_id)
		var row := _ability_row(
			ab.get("display_name", ab_id),
			"MP %d  Rng %d" % [ab.get("mp_cost", 0), ab.get("range", 0)],
			Color(0.35, 0.65, 0.35),
			null, "")
		col.add_child(row)

	# ── Learnable abilities ───────────────────────────────────────────────
	var learnable: Array = reg.get("learnable_abilities", [])
	var has_learnable := false
	for ab_id: String in learnable:
		if not _gs.knows_ability(uid, ab_id):
			has_learnable = true
			break

	if has_learnable:
		col.add_child(_section_lbl("LEARNABLE"))
		for ab_id: String in learnable:
			if _gs.knows_ability(uid, ab_id):
				continue
			var ab: Dictionary = AbilityDB.get_ability(ab_id)
			var cost: int = ab.get("jp_cost", 999)
			var can_afford: bool = reg.get("jp", 0) >= cost
			var captured_uid: String = uid
			var captured_ab: String = ab_id
			var row := _ability_row(
				ab.get("display_name", ab_id),
				"MP %d  Rng %d  |  %d JP" % [ab.get("mp_cost", 0), ab.get("range", 0), cost],
				Color(0.55, 0.55, 0.65) if not can_afford else Color(0.85, 0.85, 0.95),
				func() -> void: _on_learn(captured_uid, captured_ab),
				"Learn" if can_afford else "—")
			col.add_child(row)

	return col


func _on_learn(uid: String, ability_id: String) -> void:
	if not _gs:
		return
	if _gs.learn_ability(uid, ability_id):
		# Rebuild the whole screen so JP balance and lists refresh
		_build_ui()


# ── UI helpers ────────────────────────────────────────────────────────────────

func _section_lbl(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.45, 0.50, 0.60))
	return lbl


func _ability_row(ab_name: String, sub: String, name_color: Color,
		on_learn: Callable, btn_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size.y = 34.0

	var text_col := VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 0)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_col)

	var n_lbl := Label.new()
	n_lbl.text = ab_name
	n_lbl.add_theme_font_size_override("font_size", 14)
	n_lbl.add_theme_color_override("font_color", name_color)
	text_col.add_child(n_lbl)

	var s_lbl := Label.new()
	s_lbl.text = sub
	s_lbl.add_theme_font_size_override("font_size", 10)
	s_lbl.add_theme_color_override("font_color", Color(0.50, 0.53, 0.60))
	text_col.add_child(s_lbl)

	if btn_text != "":
		var btn := Button.new()
		btn.text = btn_text
		btn.custom_minimum_size = Vector2(72.0, 28.0)
		btn.disabled = (btn_text == "—")
		if on_learn.is_valid():
			btn.pressed.connect(on_learn)
		row.add_child(btn)

	return row
