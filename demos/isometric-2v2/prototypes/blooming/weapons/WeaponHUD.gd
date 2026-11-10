extends "res://prototypes/blooming/BloomingHUD.gd"
## Reversible practice controls, distinct from campaign equipment ownership.
const Patterns = preload("res://prototypes/blooming/weapons/WeaponPatterns.gd")
var _weapon_row: GridContainer
var _weapon_buttons: Array[Button] = []
var _weapon_help: Label
func _build_ui() -> void:
	super._build_ui()
	_weapon_help=Label.new()
	_weapon_help.text="TEST WEAPONS · enemies only · free before acting"
	_weapon_help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_weapon_help.add_theme_font_size_override("font_size",14)
	_weapon_help.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_chapel_command_buttons.add_child(_weapon_help)
	_chapel_command_buttons.move_child(_weapon_help,_bloom_command_row.get_index())
	_weapon_row=GridContainer.new()
	_weapon_row.columns=2
	_weapon_row.add_theme_constant_override("separation",5)
	_chapel_command_buttons.add_child(_weapon_row)
	_chapel_command_buttons.move_child(_weapon_row,_bloom_command_row.get_index())
	for index in 2:
		var button:=Button.new()
		button.custom_minimum_size=Vector2(0,40)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",15)
		button.clip_text=true
		button.pressed.connect(_choose_test_weapon.bind(index))
		_weapon_row.add_child(button)
		_weapon_buttons.append(button)
	_weapon_row.hide();_weapon_help.hide()
func _process(delta: float) -> void:
	super._process(delta)
	_refresh_test_weapons()
func _choose_test_weapon(index: int) -> void:
	if not _selection or not _selection.can_command() or _selection.has_review() or _selection._waiting_facing:return
	var options: Array=battle_manager.call("test_weapon_options",_selection.selected_id)
	if index>=options.size():return
	if battle_manager.call("equip_test_weapon",_selection.selected_id,options[index]):
		_selection.refresh()
		_refresh_test_weapons()
func _refresh_test_weapons() -> void:
	if not is_instance_valid(_weapon_row) or not _selection or not battle_manager:return
	var show_controls: bool=_selection.can_command() and battle_manager.active_command.is_empty() and not _selection.has_review() and not _selection._waiting_facing
	_weapon_row.visible=show_controls
	_weapon_help.visible=show_controls
	if not show_controls:return
	var options: Array=battle_manager.call("test_weapon_options",_selection.selected_id)
	var current: String=battle_manager.call("test_weapon_id",_selection.selected_id)
	var widest_label:=0.0
	for index in _weapon_buttons.size():
		var button:=_weapon_buttons[index]
		button.visible=index<options.size()
		if index>=options.size():continue
		var weapon: String=options[index]
		button.text=("✓ " if weapon==current else "")+Patterns.LABELS[weapon]
		button.tooltip_text=button.text+". Provisional test loadout; no art or stat bonus."
		button.disabled=battle_manager.active_unit_has_acted or weapon==current
		widest_label=maxf(widest_label,button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x+24)
	_weapon_row.columns=1 if _chapel_command_panel.size.x<widest_label*2+29 else 2
