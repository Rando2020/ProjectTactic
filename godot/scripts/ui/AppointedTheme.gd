extends RefCounted

const INK := Color("101923")
const GOLD := Color("c9aa73")
const PAPER := Color("f1e6d2")

static func panel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = INK
	box.border_color = Color("66543b")
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.shadow_color = Color(0,0,0,0.35)
	box.shadow_size = 8
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", PAPER)
	theme.set_stylebox("panel", "PanelContainer", panel())
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := panel()
		box.shadow_size = 0
		box.bg_color = {"normal":Color("182936"), "hover":Color("254b50"), "pressed":Color("0c242c"), "disabled":Color("151c25"), "focus":Color.TRANSPARENT}[state]
		box.border_color = GOLD if state in ["hover", "focus"] else Color("4c6170")
		if state == "focus": box.set_border_width_all(2)
		if state == "pressed": box.border_color = Color("7bd3c1")
		if state == "disabled": box.border_color = Color("303c48")
		box.content_margin_left = 6
		box.content_margin_right = 6
		theme.set_stylebox(state, "Button", box)
	theme.set_color("font_color", "Button", PAPER)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color("84919e"))
	var bar := panel()
	bar.bg_color = Color("63b8a4")
	bar.set_border_width_all(0)
	bar.shadow_size = 0
	theme.set_stylebox("fill", "ProgressBar", bar)
	var empty := bar.duplicate()
	empty.bg_color = Color("263642")
	theme.set_stylebox("background", "ProgressBar", empty)
	return theme
