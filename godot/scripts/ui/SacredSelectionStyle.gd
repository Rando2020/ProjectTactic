class_name SacredSelectionStyle
extends RefCounted

const GOLD := Color(0.86, 0.61, 0.28)
const GOLD_BRIGHT := Color(1.0, 0.82, 0.42)
const GOLD_DIM := Color(0.38, 0.25, 0.10)
const INK := Color(0.024, 0.022, 0.030, 0.96)
const DISABLED_EDGE := Color(0.18, 0.16, 0.13)


static func row(state: String = "default", fill: Color = INK) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fill
	st.border_color = GOLD_DIM
	st.set_border_width_all(1)
	st.set_corner_radius_all(0)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 5
	st.content_margin_bottom = 5
	st.shadow_offset = Vector2.ZERO

	match state:
		"selected":
			st.bg_color = Color(fill.r + 0.030, fill.g + 0.024, fill.b + 0.012, fill.a)
			st.border_color = GOLD_BRIGHT
			st.set_border_width_all(2)
			st.shadow_color = Color(1.0, 0.55, 0.14, 0.42)
			st.shadow_size = 12
		"hover", "focus":
			st.bg_color = Color(fill.r + 0.040, fill.g + 0.032, fill.b + 0.016, fill.a)
			st.border_color = GOLD
			st.set_border_width_all(2)
			st.shadow_color = Color(1.0, 0.55, 0.14, 0.30)
			st.shadow_size = 8
		"confirmed":
			st.bg_color = Color(fill.r + 0.045, fill.g + 0.034, fill.b + 0.018, fill.a)
			st.border_color = GOLD_BRIGHT
			st.set_border_width_all(2)
			st.shadow_color = Color(1.0, 0.65, 0.20, 0.50)
			st.shadow_size = 16
		"disabled", "locked":
			st.bg_color = Color(fill.r * 0.62, fill.g * 0.62, fill.b * 0.62, 0.72)
			st.border_color = DISABLED_EDGE
			st.shadow_size = 0
		_:
			pass

	return st


static func button_box(state: String = "default", fill: Color = INK) -> StyleBoxFlat:
	var st := row(state, fill)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	return st


static func apply_button(target: Button, fill: Color = INK, selected: bool = false) -> void:
	target.add_theme_stylebox_override("normal", button_box("selected" if selected else "default", fill))
	target.add_theme_stylebox_override("hover", button_box("hover", fill))
	target.add_theme_stylebox_override("focus", button_box("selected", fill))
	target.add_theme_stylebox_override("pressed", button_box("confirmed", fill))
	target.add_theme_stylebox_override("disabled", button_box("disabled", fill))
