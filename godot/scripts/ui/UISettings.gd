## UI-only accessibility preference. Never changes render targets or game saves.
extends RefCounted

signal changed
const LABELS := ["Auto", "Standard (100%)", "Large (125%)", "Extra large (150%)"]
static var _shared: RefCounted
var settings_path := "user://ui_settings.cfg"
var mode := 0

static func shared() -> RefCounted:
	if _shared == null:
		_shared = load("res://scripts/ui/UISettings.gd").new()
		_shared.load_settings()
	return _shared

func set_mode(value: Variant, persist := true) -> void:
	mode = value if typeof(value) == TYPE_INT and value >= 0 and value < LABELS.size() else 0
	if persist:
		var config := ConfigFile.new()
		config.set_value("accessibility", "ui_size", mode)
		if config.save(settings_path) != OK:
			push_warning("UI size could not be saved; it still applies this session.")
	changed.emit()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		set_mode(config.get_value("accessibility", "ui_size", 0), false)

func effective_scale(viewport_size: Vector2) -> float:
	var requested: float = [1.5 if viewport_size.x >= 2560 else 1.25, 1.0, 1.25, 1.5][mode]
	# Fit based on logical canvas size, not world rendering resolution. Canvas
	# stretch already magnifies this UI when a 1080p canvas is displayed at 4K.
	return minf(requested, (1.5 if viewport_size.x >= 1600 else 1.0))

func apply_tree(node: Node, viewport_size: Vector2) -> void:
	var factor := effective_scale(viewport_size)
	if node is Control:
		var control := node as Control
		if control is Label or control is Button:
			if not control.has_meta("ui_base_font"):
				control.set_meta("ui_base_font", control.get_theme_font_size("font_size"))
			control.add_theme_font_size_override("font_size", roundi(maxf(16, float(control.get_meta("ui_base_font"))) * factor))
		if control is OptionButton and control.name == "UISizeSelector":
			control.select(mode)
			control.get_popup().add_theme_font_size_override("font_size", roundi(18 * factor))
		if control is Button:
			if not control.has_meta("ui_base_height"):
				control.set_meta("ui_base_height", control.custom_minimum_size.y)
			control.custom_minimum_size.y = maxf(44, float(control.get_meta("ui_base_height"))) * factor
			if control.icon:
				if not control.has_meta("ui_base_icon"):
					control.set_meta("ui_base_icon", control.get_theme_constant("icon_max_width"))
				control.add_theme_constant_override("icon_max_width", roundi(maxf(24, float(control.get_meta("ui_base_icon"))) * factor))
	for child in node.get_children():
		apply_tree(child, viewport_size)

func add_selector(parent: Control) -> OptionButton:
	var selector := OptionButton.new()
	selector.name = "UISizeSelector"
	selector.tooltip_text = "UI text and controls only. Automatically limited to fit smaller windows. World quality is unchanged."
	for label in LABELS:
		selector.add_item("UI size: " + label)
	selector.selected = mode
	selector.focus_mode = Control.FOCUS_ALL
	selector.item_selected.connect(func(index: int) -> void: set_mode(index))
	parent.add_child(selector)
	return selector
