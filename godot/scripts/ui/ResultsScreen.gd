## ResultsScreen.gd
## Shown after every battle.  Reads pending_rewards from GameState,
## displays gold / JP earned, then routes to CharacterScreen.
class_name ResultsScreen
extends Control


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Full-screen dark background
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var gs: GameState = get_node_or_null("/root/GameState")
	var rewards: Dictionary = gs.pending_rewards if gs else {}
	var is_victory: bool = not rewards.is_empty()

	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(520, 0)
	center.add_theme_constant_override("separation", 18)
	add_child(center)

	# ── Result header ────────────────────────────────────────────────────
	var header := Label.new()
	header.text = "VICTORY!" if is_victory else "DEFEATED"
	header.add_theme_font_size_override("font_size", 52)
	header.add_theme_color_override("font_color",
		Color(1.0, 0.88, 0.3) if is_victory else Color(0.85, 0.25, 0.25))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(header)

	center.add_child(_separator())

	if is_victory:
		# ── Map name ─────────────────────────────────────────────────────
		var map_lbl := Label.new()
		map_lbl.text = rewards.get("map_id", "").replace("_", " ").to_upper()
		map_lbl.add_theme_font_size_override("font_size", 14)
		map_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		map_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		center.add_child(map_lbl)

		# ── Rewards row ───────────────────────────────────────────────────
		var reward_row := HBoxContainer.new()
		reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
		reward_row.add_theme_constant_override("separation", 40)
		center.add_child(reward_row)

		_reward_chip(reward_row, "+%d" % rewards.get("gold", 0), "GOLD",
			Color(1.0, 0.85, 0.3))
		_reward_chip(reward_row, "+%d" % rewards.get("jp", 0), "JP / UNIT",
			Color(0.5, 0.85, 1.0))

		if gs:
			var total_lbl := Label.new()
			total_lbl.text = "Total gold: %d" % gs.gold
			total_lbl.add_theme_font_size_override("font_size", 13)
			total_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
			total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center.add_child(total_lbl)

		center.add_child(_separator())

		# ── Unit JP totals ────────────────────────────────────────────────
		var jp_header := Label.new()
		jp_header.text = "UNIT JP TOTALS"
		jp_header.add_theme_font_size_override("font_size", 12)
		jp_header.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
		jp_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		center.add_child(jp_header)

		var unit_row := HBoxContainer.new()
		unit_row.alignment = BoxContainer.ALIGNMENT_CENTER
		unit_row.add_theme_constant_override("separation", 24)
		center.add_child(unit_row)

		var unit_ids: Array = rewards.get("units", ["zane", "mira", "kael"])
		for uid: String in unit_ids:
			if gs and gs.unit_registry.has(uid):
				var reg: Dictionary = gs.unit_registry[uid]
				_jp_chip(unit_row, reg.get("display_name", uid),
					reg.get("jp", 0))

		center.add_child(_separator())

	# ── Navigation buttons ────────────────────────────────────────────────
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	center.add_child(btn_row)

	if is_victory:
		var manage_btn := _nav_btn("Manage Party  →", Color(0.3, 0.55, 0.9))
		manage_btn.pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://scenes/CharacterScreen.tscn"))
		btn_row.add_child(manage_btn)

	var skip_btn := _nav_btn(
		"Select Stage  →" if is_victory else "← Back to Map",
		Color(0.35, 0.38, 0.44))
	skip_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/StageSelect.tscn"))
	btn_row.add_child(skip_btn)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.22, 0.25, 0.30))
	return sep


func _reward_chip(parent: Control, value: String,
		label: String, color: Color) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	parent.add_child(box)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", 36)
	val_lbl.add_theme_color_override("font_color", color)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(val_lbl)

	var key_lbl := Label.new()
	key_lbl.text = label
	key_lbl.add_theme_font_size_override("font_size", 12)
	key_lbl.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65))
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(key_lbl)


func _jp_chip(parent: Control, uname: String, jp: int) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)

	var name_lbl := Label.new()
	name_lbl.text = uname
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_lbl)

	var jp_lbl := Label.new()
	jp_lbl.text = "%d JP" % jp
	jp_lbl.add_theme_font_size_override("font_size", 18)
	jp_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	jp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(jp_lbl)


func _nav_btn(label: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(200, 48)
	btn.add_theme_color_override("font_color", color)
	return btn
