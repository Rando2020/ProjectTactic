class_name PolishedCinematicBattleUI
extends "res://scripts/battle/CinematicBattleUI.gd"

## Asset-polish layer for the cinematic battle shell.
## BattleUI and CinematicBattleUI remain authoritative for battle state and
## command wiring; this class only upgrades presentation and read-only cards.

const POLISH_FONT := preload("res://assets/fonts/TrajanPro-Regular.ttf")
const CARD_GOLD := Color(0.80, 0.66, 0.39, 1.0)
const CARD_TEXT := Color(0.94, 0.92, 0.86, 1.0)
const CARD_MUTED := Color(0.62, 0.66, 0.72, 1.0)

var _ability_card_row: HBoxContainer
var _intent_card_box: VBoxContainer
var _field_thumb: TextureRect
var _field_title: Label
var _field_meta: Label
var _field_rules: Label


func _build_ui() -> void:
	super._build_ui()
	_install_ability_cards()
	_install_intent_cards()
	_install_field_read_card()
	_apply_command_iconography()


func _style_live_controls() -> void:
	super._style_live_controls()
	_apply_command_iconography()


func _create_party_card(unit: Unit) -> Dictionary:
	var refs: Dictionary = super._create_party_card(unit)
	var portrait := refs.get("portrait") as TextureRect
	if portrait:
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		portrait.texture = _portrait_texture(unit.unit_id)
	return refs


func _update_party_card(unit: Unit, refs: Dictionary) -> void:
	super._update_party_card(unit, refs)
	var portrait := refs.get("portrait") as TextureRect
	if portrait:
		var dedicated: Texture2D = _portrait_texture(unit.unit_id)
		if dedicated:
			portrait.texture = dedicated


func _install_ability_cards() -> void:
	if not _ability_host:
		return
	var host: Container = _find_named_container(_ability_host, "AbilityHostBox")
	if not host:
		return
	_ability_card_row = HBoxContainer.new()
	_ability_card_row.name = "AbilityCardRow"
	_ability_card_row.visible = false
	_ability_card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_ability_card_row.add_theme_constant_override("separation", 10)
	_ability_card_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(_ability_card_row)
	if _ability_panel:
		_ability_panel.visible = false


func _on_ability_mode_started(usable_ids: Array) -> void:
	if not _ability_card_row:
		return
	for child in _ability_card_row.get_children():
		child.queue_free()
	_ability_card_row.visible = not usable_ids.is_empty()
	var idle := _find_named_control(_ability_host, "IdleHint")
	if idle:
		idle.visible = usable_ids.is_empty()
	if usable_ids.is_empty():
		if _result_label:
			_result_label.text = "No usable abilities."
		return
	for id_variant in usable_ids:
		var ability_id: String = str(id_variant)
		var ability: Dictionary = AbilityDB.get_ability(ability_id)
		_add_ability_card(ability_id, ability)


func _add_ability_card(ability_id: String, ability: Dictionary) -> void:
	var spell_type: String = str(ability.get("spell_type", ""))
	var accent: Color = ForecastCalculator.ELEMENT_COLORS.get(spell_type, CARD_GOLD)
	var glyph: String = str(ForecastCalculator.ELEMENT_ICONS.get(spell_type, "✦"))
	var display_name: String = str(ability.get("display_name", ability_id)).to_upper()
	var mp_cost: int = int(ability.get("mp_cost", 0))
	var ability_range: int = int(ability.get("range", 0))
	var aoe_type: String = str(ability.get("aoe_type", ""))
	var shape_label: String = str(ForecastCalculator.AOE_SHAPE_LABELS.get(aoe_type, ""))
	var button := Button.new()
	button.custom_minimum_size = Vector2(176, 112)
	button.text = "%s\n%s\n%d MP  •  R%d%s" % [
		glyph,
		display_name,
		mp_cost,
		ability_range,
		("  •  " + shape_label) if not shape_label.is_empty() else "",
	]
	button.tooltip_text = str(ability.get("description", display_name))
	button.add_theme_font_override("font", POLISH_FONT)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", CARD_TEXT)
	button.add_theme_color_override("font_hover_color", accent.lightened(0.22))
	button.add_theme_stylebox_override("normal", _polish_style(Color(0.025, 0.03, 0.04, 0.96), accent.darkened(0.35), 1))
	button.add_theme_stylebox_override("hover", _polish_style(Color(accent.r * 0.12, accent.g * 0.12, accent.b * 0.12, 0.98), accent, 2))
	button.add_theme_stylebox_override("pressed", _polish_style(Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.18, 0.98), accent.lightened(0.15), 2))
	button.pressed.connect(_select_polished_ability.bind(ability_id))
	_ability_card_row.add_child(button)


func _select_polished_ability(ability_id: String) -> void:
	_play_sfx("ui_confirm")
	if _ability_card_row:
		_ability_card_row.visible = false
	if battle_manager:
		battle_manager.select_ability(ability_id)


func _install_intent_cards() -> void:
	if not _intent_host:
		return
	var host: Container = _find_named_container(_intent_host, "IntentBox")
	if not host:
		return
	_intent_card_box = VBoxContainer.new()
	_intent_card_box.name = "IntentCards"
	_intent_card_box.add_theme_constant_override("separation", 8)
	_intent_card_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(_intent_card_box)


func _on_enemy_intent_changed(intent: Dictionary) -> void:
	super._on_enemy_intent_changed(intent)
	if not _intent_card_box:
		return
	for child in _intent_card_box.get_children():
		child.queue_free()
	if intent.is_empty():
		return
	if _enemy_intent_panel:
		_enemy_intent_panel.visible = false
	if str(intent.get("kind", "")) == "board":
		var rows: Array = intent.get("rows", []) as Array
		for row_variant in rows.slice(0, mini(rows.size(), 4)):
			var row: Dictionary = row_variant as Dictionary
			_add_intent_card(row)
	else:
		_add_intent_card(intent)


func _add_intent_card(intent: Dictionary) -> void:
	var actor: String = str(intent.get("actor", "Enemy"))
	var action: String = str(intent.get("action", "Act"))
	var target: String = str(intent.get("target", "-"))
	var danger: String = str(intent.get("danger", "normal"))
	var details: Dictionary = intent.get("details", {}) as Dictionary
	var accent := Color(0.95, 0.47, 0.28, 1.0)
	if danger == "lethal":
		accent = Color(1.0, 0.22, 0.18, 1.0)
	elif danger == "high":
		accent = Color(1.0, 0.55, 0.20, 1.0)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _polish_style(Color(0.04, 0.035, 0.04, 0.96), accent, 1))
	_intent_card_box.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(54, 54)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = _enemy_texture(actor)
	row.add_child(portrait)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	var actor_lbl := _polish_label(text_box, actor.to_upper(), 11, accent.lightened(0.22))
	actor_lbl.clip_text = true
	_polish_label(text_box, "%s  →  %s" % [action, target], 11, CARD_TEXT)
	var damage: int = int(details.get("damage", 0))
	var meta: String = ""
	if damage > 0:
		meta = "%d dmg" % damage
	elif damage < 0:
		meta = "heals %d" % abs(damage)
	var move_label: String = str(details.get("move_label", ""))
	if not move_label.is_empty():
		meta = "%s%s%s" % [meta, " • " if not meta.is_empty() else "", move_label]
	if not meta.is_empty():
		_polish_label(text_box, meta, 9, CARD_MUTED)


func _install_field_read_card() -> void:
	if not _terrain_host:
		return
	var host: Container = _find_named_container(_terrain_host, "TerrainBox")
	if not host:
		return
	if _tile_info_label:
		_tile_info_label.visible = false
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	host.add_child(body)
	_field_thumb = TextureRect.new()
	_field_thumb.custom_minimum_size = Vector2(116, 88)
	_field_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_field_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.add_child(_field_thumb)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 4)
	body.add_child(copy)
	_field_title = _polish_label(copy, "FIELD", 16, CARD_GOLD)
	_field_meta = _polish_label(copy, "Hover a tile", 10, CARD_TEXT)
	_field_rules = _polish_label(copy, "Height • movement • terrain", 9, CARD_MUTED)


func _on_tile_info_changed(text: String) -> void:
	super._on_tile_info_changed(text)
	if not _field_title:
		return
	if text.is_empty():
		_field_title.text = "FIELD"
		_field_meta.text = "Hover a tile"
		_field_rules.text = "Height • movement • terrain"
		return
	var chunks: PackedStringArray = text.split("  ", false)
	var terrain_label: String = chunks[0] if chunks.size() > 0 else "Field"
	var terrain_key: String = terrain_label.to_lower().replace(" ", "_")
	_field_title.text = terrain_label.to_upper()
	var meta_parts: Array[String] = []
	var rule_parts: Array[String] = []
	for i in range(1, chunks.size()):
		var chunk: String = chunks[i]
		if chunk.begins_with("H:") or chunk.begins_with("Move:") or chunk.contains("H"):
			rule_parts.append(chunk)
		else:
			meta_parts.append(chunk)
	_field_meta.text = " • ".join(meta_parts) if not meta_parts.is_empty() else "TACTICAL TILE"
	_field_rules.text = " • ".join(rule_parts) if not rule_parts.is_empty() else "Terrain rules active"
	var thumb_path: String = str(CinematicUIAssets.TERRAIN_THUMBNAILS.get(terrain_key, CinematicUIAssets.TERRAIN_THUMBNAILS["stone"]))
	_field_thumb.texture = _load_texture(thumb_path)


func _apply_command_iconography() -> void:
	_apply_command_icon(_move_btn, "move")
	_apply_command_icon(_attack_btn, "attack")
	_apply_command_icon(_ability_btn, "ability")
	_apply_command_icon(_wait_btn, "wait")


func _apply_command_icon(button: Button, command_id: String) -> void:
	if not button:
		return
	var path: String = str(CinematicUIAssets.COMMAND_ICONS.get(command_id, ""))
	button.icon = _load_texture(path)
	button.expand_icon = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("icon_max_width", 30)


func _portrait_texture(unit_id: String) -> Texture2D:
	var path: String = str(CinematicUIAssets.PORTRAITS.get(unit_id, ""))
	return _load_texture(path)


func _enemy_texture(actor: String) -> Texture2D:
	var key: String = actor.to_lower().replace(" ", "_").replace("-", "_")
	if not AssetRegistry.ENEMIES.has(key):
		return null
	var data: Dictionary = AssetRegistry.ENEMIES[key] as Dictionary
	return _load_texture(str(data.get("idle", "")))


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var resource: Resource = load(path)
	return resource as Texture2D


func _polish_label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", POLISH_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label


func _polish_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		style.set_border_width(side, width)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		style.set_corner_radius(corner, 3)
	return style
