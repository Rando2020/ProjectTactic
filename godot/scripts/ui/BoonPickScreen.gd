## BoonPickScreen.gd
## Enhanced boon selection UI with lane visualization and selection context
## Replaces simple boon picking with Hades-style progression feel

class_name BoonPickScreen
extends Control

signal boon_selected(boon: Dictionary, replaced_id: String)

const BG = Color(0.04, 0.05, 0.08)
const FG = Color(0.97, 0.94, 0.87)
const DIM = Color(0.45, 0.42, 0.38)
const GOLD = Color(0.79, 0.65, 0.34)
const DANGER = Color(0.93, 0.27, 0.27)

var _boon_system: BoonSystem
var _active_boons: Array[Dictionary] = []
var _boon_options: Array[Dictionary] = []
var _replacement_modal: Control = null


func _ready() -> void:
	_boon_system = BoonSystem.new()


func setup(active_boons: Array, options: Array) -> void:
	"""Initialize with current boons and selection options"""
	_active_boons = active_boons
	_boon_options = options
	_build_ui()


func _build_ui() -> void:
	"""Build the entire boon selection UI"""
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)

	# Title section
	_build_title_section(vbox)

	# Current blessings
	_build_blessings_section(vbox)

	# Selection grid
	_build_selection_grid(vbox)


func _build_title_section(parent: Control) -> void:
	"""Build title and instructions"""
	var title_lbl = Label.new()
	title_lbl.text = "SELECT YOUR BLESSING"
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", GOLD)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(title_lbl)

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "Blessings provide permanent benefits for this run"
	subtitle_lbl.add_theme_font_size_override("font_size", 12)
	subtitle_lbl.add_theme_color_override("font_color", DIM)
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(subtitle_lbl)


func _build_blessings_section(parent: Control) -> void:
	"""Show current active boons"""
	if _active_boons.is_empty():
		return

	var blessing_box = VBoxContainer.new()
	blessing_box.add_theme_constant_override("separation", 6)
	parent.add_child(blessing_box)

	var blessing_title = Label.new()
	blessing_title.text = "Your Blessings"
	blessing_title.add_theme_font_size_override("font_size", 11)
	blessing_title.add_theme_color_override("font_color", GOLD)
	blessing_box.add_child(blessing_title)

	var blessings_row = HBoxContainer.new()
	blessings_row.add_theme_constant_override("separation", 8)
	blessing_box.add_child(blessings_row)

	for boon in _active_boons:
		var boon_badge = PanelContainer.new()
		boon_badge.custom_minimum_size = Vector2(80, 28)

		var rarity = str(boon.get("rarity", "common"))
		var color = _get_rarity_color(rarity)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(color.r * 0.14, color.g * 0.14, color.b * 0.14, 0.92)
		style.border_color = color
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		boon_badge.add_theme_stylebox_override("panel", style)

		var lbl = Label.new()
		lbl.text = "%s %s" % [str(boon.get("icon", "+")), str(boon.get("name", "Boon")).left(8)]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", color)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boon_badge.add_child(lbl)
		blessings_row.add_child(boon_badge)


func _build_selection_grid(parent: Control) -> void:
	"""Build grid of boon selection cards"""
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	parent.add_child(grid)

	for boon in _boon_options:
		var card = _build_boon_card(boon)
		grid.add_child(card)


func _build_boon_card(boon: Dictionary) -> Control:
	"""Build individual boon selection card"""
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(200, 140)

	var rarity = str(boon.get("rarity", "common"))
	var color = _get_rarity_color(rarity)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.95)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	card_panel.add_theme_stylebox_override("panel", style)

	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 4)
	card_panel.add_child(card_vbox)

	# Header with icon and rarity
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	card_vbox.add_child(header)

	var icon_lbl = Label.new()
	icon_lbl.text = str(boon.get("icon", "+"))
	icon_lbl.add_theme_font_size_override("font_size", 18)
	header.add_child(icon_lbl)

	var rarity_badge = Label.new()
	rarity_badge.text = str(boon.get("rarity", "common")).to_upper()
	rarity_badge.add_theme_font_size_override("font_size", 9)
	rarity_badge.add_theme_color_override("font_color", color)
	rarity_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(rarity_badge)

	# Lane badge if applicable
	var lane = _boon_system.boon_lane(boon)
	if not lane.is_empty():
		var lane_count = _boon_system.boons_in_lane(_active_boons, lane).size()
		var lane_limit = _boon_system.boon_lane_limit(lane)
		var lane_badge = Label.new()
		lane_badge.text = "%s (%d/%d)" % [lane.capitalize(), lane_count, lane_limit]
		lane_badge.add_theme_font_size_override("font_size", 8)
		lane_badge.add_theme_color_override("font_color", color if lane_count < lane_limit else DANGER)
		card_vbox.add_child(lane_badge)

	# Name
	var name_lbl = Label.new()
	name_lbl.text = str(boon.get("name", "Unknown"))
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", FG)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(name_lbl)

	# Description (small)
	var desc_lbl = Label.new()
	desc_lbl.text = _truncate_words(str(boon.get("desc", "")), 40)
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.add_theme_color_override("font_color", DIM)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_vbox.add_child(desc_lbl)

	# Selection button
	var btn = Button.new()
	btn.text = "Choose Boon"
	if not lane.is_empty() and _boon_system.boons_in_lane(_active_boons, lane).size() >= _boon_system.boon_lane_limit(lane):
		btn.text = "Replace"
	btn.custom_minimum_size = Vector2(0, 28)
	btn.pressed.connect(_on_boon_selected.bind(boon))
	card_vbox.add_child(btn)

	return card_panel


func _on_boon_selected(boon: Dictionary) -> void:
	"""Handle boon selection"""
	var lane = _boon_system.boon_lane(boon)
	var needs_replacement = _boon_system.needs_lane_replacement(_active_boons, boon)

	if needs_replacement:
		_show_replacement_modal(boon)
	else:
		boon_selected.emit(boon, "")


func _show_replacement_modal(incoming_boon: Dictionary) -> void:
	"""Show modal for selecting which boon to replace"""
	var lane = _boon_system.boon_lane(incoming_boon)
	var boonsInLane = _boon_system.boons_in_lane(_active_boons, lane)

	_replacement_modal = PanelContainer.new()
	_replacement_modal.custom_minimum_size = Vector2(400, 300)
	_replacement_modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_replacement_modal.offset_left = -200
	_replacement_modal.offset_top = -150

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	style.border_color = DANGER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_replacement_modal.add_theme_stylebox_override("panel", style)

	add_child(_replacement_modal)

	var modal_vbox = VBoxContainer.new()
	modal_vbox.add_theme_constant_override("separation", 12)
	_replacement_modal.add_child(modal_vbox)

	# Title
	var title = Label.new()
	title.text = "Lane Full: %s" % lane.capitalize()
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", DANGER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_vbox.add_child(title)

	# Explanation
	var explanation = Label.new()
	explanation.text = "You can carry a maximum of %d %s boons. Choose one to replace." % [_boon_system.boon_lane_limit(lane), lane]
	explanation.add_theme_font_size_override("font_size", 11)
	explanation.add_theme_color_override("font_color", DIM)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_vbox.add_child(explanation)

	# Incoming boon preview
	var incoming_label = Label.new()
	incoming_label.text = "+ Incoming: %s %s" % [str(incoming_boon.get("icon", "+")), str(incoming_boon.get("name", ""))]
	incoming_label.add_theme_font_size_override("font_size", 12)
	incoming_label.add_theme_color_override("font_color", GOLD)
	modal_vbox.add_child(incoming_label)

	# Radio button group for selection
	var radio_group = VBoxContainer.new()
	radio_group.add_theme_constant_override("separation", 6)
	modal_vbox.add_child(radio_group)

	var selected_idx = 0
	var radio_buttons = []

	for i in range(boonsInLane.size()):
		var boon = boonsInLane[i]
		var radio_btn = CheckButton.new()
		radio_btn.text = "%s %s" % [str(boon.get("icon", "+")), str(boon.get("name", ""))]
		radio_btn.add_theme_font_size_override("font_size", 10)
		if i == 0:
			radio_btn.button_pressed = true
			selected_idx = 0
		radio_btn.toggled.connect(func(pressed: bool) -> void:
			if pressed:
				for j in range(radio_buttons.size()):
					if j != i:
						radio_buttons[j].button_pressed = false
				selected_idx = i
		)
		radio_group.add_child(radio_btn)
		radio_buttons.append(radio_btn)

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 32)
	cancel_btn.pressed.connect(func() -> void:
		_replacement_modal.queue_free()
		_replacement_modal = null
	)
	btn_row.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "Confirm Replacement"
	confirm_btn.custom_minimum_size = Vector2(160, 32)
	confirm_btn.pressed.connect(func() -> void:
		var replaced = boonsInLane[selected_idx]
		_replacement_modal.queue_free()
		_replacement_modal = null
		boon_selected.emit(incoming_boon, str(replaced.get("id", "")))
	)
	btn_row.add_child(confirm_btn)


func _get_rarity_color(rarity: String) -> Color:
	"""Get color for boon rarity"""
	var rarity_data = _boon_system.RARITIES.get(rarity, {})
	return rarity_data.get("color", Color.WHITE)


func _truncate_words(text: String, max_words: int) -> String:
	var words := text.strip_edges().split(" ", false)
	if words.size() <= max_words:
		return text
	return " ".join(words.slice(0, max_words)) + "..."
