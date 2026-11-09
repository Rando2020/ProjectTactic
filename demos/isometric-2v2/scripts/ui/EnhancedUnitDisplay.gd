## EnhancedUnitDisplay.gd
## Enhanced unit portrait system with job colors, silhouettes, and status indicators
## Replaces simple emoji tokens with readable, color-coded unit portraits

class_name EnhancedUnitDisplay
extends Control

const JOB_PROFILES = {
	"warder": {"color": Color("#dc2626"), "border": Color("#991b1b"), "icon": "⚔️", "label": "Warder"},
	"null_breaker": {"color": Color("#b91c1c"), "border": Color("#7f1d1d"), "icon": "🗡️", "label": "Null Breaker"},
	"luminary": {"color": Color("#059669"), "border": Color("#065f46"), "icon": "✨", "label": "Luminary"},
	"seraph": {"color": Color("#0891b2"), "border": Color("#164e63"), "icon": "⭐", "label": "Seraph"},
	"arcanist": {"color": Color("#7c3aed"), "border": Color("#4c1d95"), "icon": "⚡", "label": "Arcanist"},
	"etherweaver": {"color": Color("#6366f1"), "border": Color("#312e81"), "icon": "◆", "label": "Etherweaver"},
	"resonant": {"color": Color("#d97706"), "border": Color("#92400e"), "icon": "◎", "label": "Resonant"},
	"primal_binder": {"color": Color("#ca8a04"), "border": Color("#713f12"), "icon": "⊕", "label": "Primal Binder"},
	"skywarden": {"color": Color("#0ea5e9"), "border": Color("#0c4a6e"), "icon": "△", "label": "Skywarden"},
	"default": {"color": Color("#4b5563"), "border": Color("#1e293b"), "icon": "◇", "label": "Adventurer"},
}

const STATUS_COLORS = {
	"bleed": Color("#ef4444"),
	"burning": Color("#f97316"),
	"blessed": Color("#4ade80"),
	"stun": Color("#fbbf24"),
	"default": Color("#9ca3af"),
}

## Unit data
var unit: Dictionary
var is_selected: bool = false
var is_active: bool = false
var is_flashing: bool = false

## Visual components
var _portrait: Control
var _profile: Dictionary


func _ready() -> void:
	setup()


func setup() -> void:
	"""Initialize portrait with unit data"""
	if not unit:
		return

	var job_id = unit.get("baseJobId", unit.get("currentJobId", "default"))
	_profile = JOB_PROFILES.get(job_id, JOB_PROFILES["default"])

	_build_portrait()
	_start_idle_bob()


func _build_portrait() -> void:
	"""Create the enhanced portrait circle"""
	# Main portrait panel
	_portrait = PanelContainer.new()
	_portrait.custom_minimum_size = Vector2(28, 28)

	var style = StyleBoxFlat.new()
	style.bg_color = _profile["color"]
	style.border_color = _profile["border"]
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)  # Half of size for perfect circle
	_portrait.add_theme_stylebox_override("panel", style)

	add_child(_portrait)

	# Job icon (top-right corner)
	var icon_label = Label.new()
	icon_label.text = _profile["icon"]
	icon_label.add_theme_font_size_override("font_size", 10)
	icon_label.position = Vector2(18, -4)
	_portrait.add_child(icon_label)

	# Unit initials (center)
	var initials = _get_initials()
	var initials_label = Label.new()
	initials_label.text = initials
	initials_label.add_theme_font_size_override("font_size", 8)
	initials_label.add_theme_color_override("font_color", Color.WHITE)
	initials_label.position = Vector2(6, 8)
	_portrait.add_child(initials_label)

	# Enemy badge (red E for enemies)
	if unit.get("team") == "enemy":
		var badge = PanelContainer.new()
		badge.custom_minimum_size = Vector2(14, 14)
		var badge_style = StyleBoxFlat.new()
		badge_style.bg_color = Color("#dc2626")
		badge_style.border_color = Color("#991b1b")
		badge_style.set_border_width_all(1)
		badge_style.set_corner_radius_all(7)
		badge.add_theme_stylebox_override("panel", badge_style)

		var badge_label = Label.new()
		badge_label.text = "E"
		badge_label.add_theme_font_size_override("font_size", 8)
		badge_label.add_theme_color_override("font_color", Color.WHITE)
		badge_label.position = Vector2(-16, -16)
		_portrait.add_child(badge)
		badge.add_child(badge_label)

	# Status indicators (right side)
	if unit.get("statuses", []).size() > 0:
		var status_count = mini(unit["statuses"].size(), 3)
		for i in range(status_count):
			var status = unit["statuses"][i]
			var status_dot = ColorRect.new()
			status_dot.custom_minimum_size = Vector2(6, 6)
			status_dot.color = STATUS_COLORS.get(status.get("id", "default"), STATUS_COLORS["default"])
			status_dot.position = Vector2(32, 4 + i * 8)
			_portrait.add_child(status_dot)

	_update_visual_state()


func _get_initials() -> String:
	"""Extract initials from unit name"""
	var name_str = unit.get("name", "?")
	var parts = name_str.split(" ")
	var initials = ""
	for part in parts:
		if part.length() > 0:
			initials += part[0].to_upper()
	return initials.left(2) if initials else "??"


func _update_visual_state() -> void:
	"""Update portrait styling based on selection/active/flashing states"""
	if not _portrait:
		return

	var style = _portrait.get_theme_stylebox("panel") as StyleBoxFlat
	if not style:
		return

	# Selection glow
	if is_selected:
		_portrait.self_modulate = Color.WHITE
		var glow_style = style.duplicate() as StyleBoxFlat
		glow_style.shadow_color = Color(1.0, 1.0, 1.0, 0.5)
		_portrait.add_theme_stylebox_override("panel", glow_style)
	elif is_active:
		_portrait.self_modulate = Color.WHITE
		var active_style = style.duplicate() as StyleBoxFlat
		active_style.shadow_color = Color(1.0, 1.0, 1.0, 0.25)
		_portrait.add_theme_stylebox_override("panel", active_style)
	else:
		_portrait.self_modulate = Color.WHITE

	# Flash effect
	if is_flashing:
		_portrait.modulate = Color(1.5, 1.3, 0.8, 1.0)
		var flash_style = style.duplicate() as StyleBoxFlat
		flash_style.shadow_color = Color(1.0, 1.0, 0.5, 0.6)
		_portrait.add_theme_stylebox_override("panel", flash_style)
	else:
		_portrait.modulate = Color.WHITE


func _start_idle_bob() -> void:
	"""Smooth floating animation"""
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y - 3.0, 1.1)
	tween.tween_property(self, "position:y", position.y, 1.1)


func set_flashing(flashing: bool) -> void:
	"""Update flash state"""
	is_flashing = flashing
	_update_visual_state()


func set_selected(selected: bool) -> void:
	"""Update selection state"""
	is_selected = selected
	_update_visual_state()


func set_active(active: bool) -> void:
	"""Update active state"""
	is_active = active
	_update_visual_state()


## Static helper to get job profile color
static func get_job_color(job_id: String) -> Color:
	return JOB_PROFILES.get(job_id, JOB_PROFILES["default"])["color"]


## Static helper to get job icon
static func get_job_icon(job_id: String) -> String:
	return JOB_PROFILES.get(job_id, JOB_PROFILES["default"])["icon"]
