## A non-interactive, compact actor-versus-defender accent shown on committed
## actions. It does not calculate, resolve, pause or change combat outcomes.
extends Control

const UISettings := preload("res://scripts/ui/UISettings.gd")
const BASE_SIZE := Vector2(770.0, 136.0)

var _card: PanelContainer
var _actor_image: TextureRect
var _actor_fallback: Label
var _actor_name: Label
var _target_image: TextureRect
var _target_fallback: Label
var _target_name: Label
var _action_name: Label
var _action_context: Label
var _fade: Tween


func _ready() -> void:
	name = "ActionClashOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_resize()
	visible = false
	get_viewport().size_changed.connect(_resize)
	UISettings.shared().changed.connect(_resize)


func _build() -> void:
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.custom_minimum_size = BASE_SIZE
	_card.size = BASE_SIZE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.045, 0.06, 0.09, 0.94)
	bg.border_color = Color(0.8, 0.66, 0.42, 0.85)
	bg.border_width_left = 2
	bg.border_width_right = 2
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	bg.content_margin_left = 12
	bg.content_margin_right = 12
	bg.content_margin_top = 8
	bg.content_margin_bottom = 8
	_card.add_theme_stylebox_override("panel", bg)
	add_child(_card)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	_card.add_child(row)

	var left := _side(row, false, Color(0.47, 0.8, 0.78))
	_actor_image = left["image"]
	_actor_fallback = left["fallback"]
	_actor_name = left["name"]

	var center := VBoxContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.custom_minimum_size.x = 190
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 6)
	row.add_child(center)

	_action_name = Label.new()
	_action_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_action_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_name.add_theme_font_size_override("font_size", 22)
	_action_name.add_theme_color_override("font_color", Color(1.0, 0.86, 0.58))
	_action_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_action_name)

	_action_context = Label.new()
	_action_context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_action_context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_context.add_theme_font_size_override("font_size", 14)
	_action_context.add_theme_color_override("font_color", Color(0.74, 0.83, 0.86))
	_action_context.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_action_context)

	var right := _side(row, true, Color(0.91, 0.49, 0.43))
	_target_image = right["image"]
	_target_fallback = right["fallback"]
	_target_name = right["name"]


func _side(parent: HBoxContainer, reverse: bool, accent: Color) -> Dictionary:
	var side := HBoxContainer.new()
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 9)
	parent.add_child(side)

	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.custom_minimum_size = Vector2(92, 108)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.11, 0.15, 0.20)
	st.border_color = accent
	st.set_border_width_all(2)
	st.set_corner_radius_all(5)
	frame.add_theme_stylebox_override("panel", st)

	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size = Vector2(88, 104)
	frame.add_child(holder)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(84, 100)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	holder.add_child(portrait)

	var fallback := Label.new()
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback.add_theme_font_size_override("font_size", 38)
	fallback.add_theme_color_override("font_color", accent)
	holder.add_child(fallback)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if reverse else HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.93, 0.91, 0.85))
	if reverse:
		side.add_child(label)
		side.add_child(frame)
	else:
		side.add_child(frame)
		side.add_child(label)
	return {"image": portrait, "fallback": fallback, "name": label}


func _resize() -> void:
	if not is_instance_valid(_card):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	# Keep the portrait strip entirely left of the persistent right command rail.
	var available_width := viewport_size.x * 0.68 - 30.0
	var ui_factor: float = UISettings.shared().effective_scale(viewport_size)
	var factor: float = minf(ui_factor, available_width / BASE_SIZE.x)
	factor = minf(factor, (viewport_size.y * 0.26) / BASE_SIZE.y)
	_card.scale = Vector2.ONE * maxf(0.48, factor)
	_card.position = Vector2(24, viewport_size.y - BASE_SIZE.y * _card.scale.y - 24)


func _portrait(texture_node: TextureRect, fallback: Label, supplied: Variant, unit_id: String, display_name: String) -> void:
	var texture: Texture2D = null
	if supplied is Texture2D:
		texture = supplied as Texture2D
	if texture == null and not unit_id.is_empty():
		texture = AssetRegistry.load_first_texture(AssetRegistry.get_character_candidates(unit_id))
	texture_node.texture = texture
	texture_node.visible = texture != null
	fallback.text = display_name.substr(0, 1).to_upper() if not display_name.is_empty() else "?"
	fallback.visible = texture == null


## Presentation only. A new accepted action replaces the previous strip.
## No await: the source action's contact/resolution timing stays authoritative.
func show_action(context: Dictionary) -> void:
	if _card == null or str(context.get("actor", "")).is_empty():
		return
	if _fade and _fade.is_running():
		_fade.kill()
	_actor_name.text = str(context.get("actor", ""))
	_target_name.text = str(context.get("target", "AREA"))
	_action_name.text = str(context.get("action", "Attack"))
	_action_context.text = str(context.get("context", ""))
	_portrait(_actor_image, _actor_fallback, context.get("actor_portrait"), str(context.get("actor_id", "")), _actor_name.text)
	_portrait(_target_image, _target_fallback, context.get("target_portrait"), str(context.get("target_id", "")), _target_name.text)
	_resize()
	visible = true
	var reduced: bool = bool(context.get("reduced_motion", false))
	modulate.a = 1.0 if reduced else 0.0
	_fade = create_tween()
	if not reduced:
		_fade.tween_property(self, "modulate:a", 1.0, 0.10)
	_fade.tween_interval(0.48 if str(context.get("tier", "light")) == "light" else 0.70)
	if not reduced:
		_fade.tween_property(self, "modulate:a", 0.0, 0.14)
	_fade.tween_callback(hide_clash)


func hide_clash() -> void:
	visible = false
	modulate.a = 1.0
