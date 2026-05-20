class_name HubManager
extends Control

var _meta: Node
var _currency_row: HBoxContainer
var _message_label: Label

func _ready() -> void:
	_meta = get_node_or_null("/root/MetaProgression")
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.045, 0.050, 0.075)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.position = Vector2(48.0, 34.0)
	root.custom_minimum_size = Vector2(1184.0, 650.0)
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var title := Label.new()
	title.text = "THE LAST HEARTH"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62))
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Spend run rewards, unlock jobs, strengthen Guardian boons, then descend again."
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.70, 0.76, 0.84))
	root.add_child(subtitle)

	_currency_row = HBoxContainer.new()
	_currency_row.add_theme_constant_override("separation", 10)
	root.add_child(_currency_row)

	_message_label = Label.new()
	_message_label.add_theme_font_size_override("font_size", 13)
	_message_label.add_theme_color_override("font_color", Color(0.55, 0.92, 0.72))
	root.add_child(_message_label)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	root.add_child(grid)

	grid.add_child(_panel("Body Training", "Permanent baseline power for every run.", [
		{"label":"Increase Max HP", "desc":"+15 HP to all player units.", "cost":{Currency.SOUL_SHARDS:20}, "action":func(): _buy_stat("max_hp", {Currency.SOUL_SHARDS:20})},
		{"label":"Increase Physical Power", "desc":"+2 physical to all player units.", "cost":{Currency.SOUL_SHARDS:25}, "action":func(): _buy_stat("physical", {Currency.SOUL_SHARDS:25})},
		{"label":"Increase Magic Power", "desc":"+2 magic to all player units.", "cost":{Currency.SOUL_SHARDS:25}, "action":func(): _buy_stat("magic", {Currency.SOUL_SHARDS:25})},
	]))

	grid.add_child(_panel("Job Reliquary", "Spend rare materials to open deeper job routes.", [
		{"label":"Unlock Advanced Jobs", "desc":"Allows advanced job unlock checks to appear.", "cost":{Currency.OBSIDIAN:10, Currency.BOSS_TOKENS:1}, "action":func(): _buy_flag("advanced-jobs-unlocked", {Currency.OBSIDIAN:10, Currency.BOSS_TOKENS:1})},
		{"label":"Unlock Ascended Jobs", "desc":"Late-run class tier gated by boss clears.", "cost":{Currency.OBSIDIAN:25, Currency.BOSS_TOKENS:3}, "action":func(): _buy_flag("ascended-jobs-unlocked", {Currency.OBSIDIAN:25, Currency.BOSS_TOKENS:3})},
	]))

	grid.add_child(_panel("Guardian Shrine", "Summon-aligned currencies upgrade boon pools.", [
		{"label":"Phoenix Resonance I", "desc":"Adds stronger sustain boons to the reward pool.", "cost":{Currency.GLYPHS:8, "phoenix-sigils":5}, "action":func(): _buy_flag("guardian-phoenix-rank-1", {Currency.GLYPHS:8, "phoenix-sigils":5})},
		{"label":"Titan Resonance I", "desc":"Adds defensive terrain and guard boons.", "cost":{Currency.GLYPHS:8, "titan-sigils":5}, "action":func(): _buy_flag("guardian-titan-rank-1", {Currency.GLYPHS:8, "titan-sigils":5})},
	]))

	grid.add_child(_panel("Heat Altar", "Optional difficulty for better rewards.", [
		{"label":"Unlock Heat I", "desc":"Enemies gain HP. Rewards increase.", "cost":{Currency.SOUL_SHARDS:30}, "action":func(): _buy_heat(1, {Currency.SOUL_SHARDS:30})},
		{"label":"Unlock Heat II", "desc":"More elite spawns. Rewards increase.", "cost":{Currency.SOUL_SHARDS:55, Currency.BOSS_TOKENS:1}, "action":func(): _buy_heat(2, {Currency.SOUL_SHARDS:55, Currency.BOSS_TOKENS:1})},
	]))

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	root.add_child(bottom)

	var start_btn := Button.new()
	start_btn.text = "Start Descent"
	start_btn.custom_minimum_size = Vector2(180, 48)
	start_btn.pressed.connect(_start_descent)
	bottom.add_child(start_btn)

	var jobs_btn := Button.new()
	jobs_btn.text = "Manage Jobs"
	jobs_btn.custom_minimum_size = Vector2(160, 48)
	jobs_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/CharacterScreen.tscn"))
	bottom.add_child(jobs_btn)

	var stage_btn := Button.new()
	stage_btn.text = "Debug Stage Select"
	stage_btn.custom_minimum_size = Vector2(180, 48)
	stage_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/StageSelect.tscn"))
	bottom.add_child(stage_btn)

func _panel(title: String, desc: String, rows: Array[Dictionary]) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(570, 188)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62))
	box.add_child(title_label)

	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.66, 0.72, 0.80))
	box.add_child(desc_label)

	for row: Dictionary in rows:
		var btn := Button.new()
		btn.text = "%s  •  %s" % [row.get("label", "?"), _format_cost(row.get("cost", {}))]
		btn.tooltip_text = row.get("desc", "")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 34)
		var callback: Callable = row.get("action", Callable())
		if callback.is_valid():
			btn.pressed.connect(callback)
		box.add_child(btn)
	return panel

func _refresh() -> void:
	for child in _currency_row.get_children():
		child.queue_free()
	if not _meta:
		return
	for currency_id in [Currency.SOUL_SHARDS, Currency.OBSIDIAN, Currency.GLYPHS, Currency.BOSS_TOKENS, "phoenix-sigils", "titan-sigils"]:
		var lbl := Label.new()
		lbl.text = "%s: %d" % [Currency.display_name(currency_id), _meta.get_currency(currency_id)]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.96))
		_currency_row.add_child(lbl)

func _format_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for currency_id: String in cost.keys():
		parts.append("%d %s" % [int(cost[currency_id]), Currency.display_name(currency_id)])
	return ", ".join(parts)

func _buy_stat(stat_id: String, cost: Dictionary) -> void:
	if not _meta or not _meta.spend(cost):
		_message_label.text = "Not enough currency."
		return
	_meta.add_upgrade(stat_id, 1)
	_meta.save()
	_message_label.text = "Upgrade purchased: %s." % stat_id.replace("_", " ").capitalize()
	_refresh()

func _buy_flag(flag_id: String, cost: Dictionary) -> void:
	if not _meta:
		return
	if _meta.has_unlock(flag_id):
		_message_label.text = "Already unlocked."
		return
	if not _meta.spend(cost):
		_message_label.text = "Not enough currency."
		return
	_meta.add_unlock(flag_id)
	_meta.save()
	_message_label.text = "Unlocked: %s." % flag_id.replace("-", " ").capitalize()
	_refresh()

func _buy_heat(level: int, cost: Dictionary) -> void:
	if not _meta:
		return
	if _meta.max_heat_unlocked >= level:
		_message_label.text = "Heat %d already unlocked." % level
		return
	if not _meta.spend(cost):
		_message_label.text = "Not enough currency."
		return
	_meta.max_heat_unlocked = level
	_meta.selected_heat_level = level
	_meta.save()
	_message_label.text = "Heat %d unlocked and selected." % level
	_refresh()

func _start_descent() -> void:
	var run_manager: Node = get_node_or_null("/root/RunManager")
	if run_manager:
		run_manager.start_new_run(_meta.selected_heat_level if _meta else 0)
	get_tree().change_scene_to_file("res://scenes/StageSelect.tscn")
