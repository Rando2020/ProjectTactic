## ResultsScreen.gd
## Shown after every battle. Reads pending_rewards from GameState,
## displays gold, JP, run/meta rewards, then routes to the next run scene.
class_name ResultsScreen
extends Control


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var gs: Node = get_node_or_null("/root/GameState")
	var rewards: Dictionary = gs.pending_rewards if gs else {}
	var is_victory: bool = not rewards.is_empty()
	var next_scene: String = rewards.get("next_scene", "res://scenes/StageSelect.tscn")

	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(680, 0)
	center.add_theme_constant_override("separation", 16)
	add_child(center)

	var header := Label.new()
	header.text = "VICTORY!" if is_victory else "DEFEATED"
	header.add_theme_font_size_override("font_size", 52)
	header.add_theme_color_override("font_color",
		Color(1.0, 0.88, 0.3) if is_victory else Color(0.85, 0.25, 0.25))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(header)

	center.add_child(_separator())

	if is_victory:
		var map_lbl := Label.new()
		map_lbl.text = rewards.get("map_id", "").replace("_", " ").to_upper()
		map_lbl.add_theme_font_size_override("font_size", 14)
		map_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		map_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		center.add_child(map_lbl)

		var reward_row := HBoxContainer.new()
		reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
		reward_row.add_theme_constant_override("separation", 36)
		center.add_child(reward_row)

		_reward_chip(reward_row, "+%d" % rewards.get("gold", 0), "GOLD",
			Color(1.0, 0.85, 0.3))
		_reward_chip(reward_row, "+%d" % rewards.get("jp", 0), "JP / UNIT",
			Color(0.5, 0.85, 1.0))

		var meta_rewards: Dictionary = rewards.get("meta_rewards", {})
		if not meta_rewards.is_empty():
			center.add_child(_separator())
			var meta_header := Label.new()
			meta_header.text = "RUN REWARDS"
			meta_header.add_theme_font_size_override("font_size", 12)
			meta_header.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			meta_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center.add_child(meta_header)

			var meta_row := HBoxContainer.new()
			meta_row.alignment = BoxContainer.ALIGNMENT_CENTER
			meta_row.add_theme_constant_override("separation", 22)
			center.add_child(meta_row)
			for currency_id: String in meta_rewards.keys():
				_reward_chip(meta_row, "+%d" % int(meta_rewards[currency_id]), Currency.display_name(currency_id).to_upper(),
					Color(0.72, 0.55, 1.0))

		if int(rewards.get("elite_kills", 0)) > 0:
			var elite_lbl := Label.new()
			elite_lbl.text = "Elites defeated: %d" % int(rewards.get("elite_kills", 0))
			elite_lbl.add_theme_font_size_override("font_size", 13)
			elite_lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.25))
			elite_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center.add_child(elite_lbl)

		var loot: Array = rewards.get("loot", [])
		if not loot.is_empty():
			var loot_lbl := Label.new()
			loot_lbl.text = "Loot found: %d item%s" % [loot.size(), "" if loot.size() == 1 else "s"]
			loot_lbl.add_theme_font_size_override("font_size", 13)
			loot_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
			loot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center.add_child(loot_lbl)

		if gs:
			var total_lbl := Label.new()
			var meta: Node = get_node_or_null("/root/MetaProgression")
			if meta:
				total_lbl.text = "Totals: %d Gold  •  %d Soul Shards  •  %d Obsidian  •  %d Boss Tokens" % [
					gs.gold,
					meta.get_currency(Currency.SOUL_SHARDS),
					meta.get_currency(Currency.OBSIDIAN),
					meta.get_currency(Currency.BOSS_TOKENS),
				]
			else:
				total_lbl.text = "Total gold: %d" % gs.gold
			total_lbl.add_theme_font_size_override("font_size", 13)
			total_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
			total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center.add_child(total_lbl)

		center.add_child(_separator())

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
				_jp_chip(unit_row, reg.get("display_name", uid), reg.get("jp", 0))

		center.add_child(_separator())

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	center.add_child(btn_row)

	if is_victory:
		var manage_btn := _nav_btn("Manage Party", Color(0.3, 0.55, 0.9))
		manage_btn.pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://scenes/CharacterScreen.tscn"))
		btn_row.add_child(manage_btn)

	var next_label := "Return to Hub" if next_scene.ends_with("HubScene.tscn") else "Continue Run"
	if not is_victory:
		next_label = "← Back to Hub"
		next_scene = "res://scenes/HubScene.tscn"
	var next_btn := _nav_btn(next_label, Color(0.35, 0.75, 0.45) if is_victory else Color(0.85, 0.35, 0.35))
	next_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(next_scene))
	btn_row.add_child(next_btn)


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
	val_lbl.add_theme_font_size_override("font_size", 28)
	val_lbl.add_theme_color_override("font_color", color)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(val_lbl)

	var key_lbl := Label.new()
	key_lbl.text = label
	key_lbl.add_theme_font_size_override("font_size", 10)
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
	btn.custom_minimum_size = Vector2(190, 48)
	btn.add_theme_color_override("font_color", color)
	return btn
