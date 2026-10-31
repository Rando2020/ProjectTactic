extends Node
## Demo-only input state: browse -> selected unit -> command -> target -> browse/menu.
## The manager remains the sole authority for turns, ranges, costs and commits.
var ui: BattleUI
var manager: BattleManager
var grid: TacticalGrid
var cursor: Node2D
var cursor_cell := Vector2i(-1, -1)
var selected_id := ""
var _header: Label
var _inspect: Label
var _help: Label
var _last_command := ""
var _command_scroll: ScrollContainer

func setup(p_ui: BattleUI, p_manager: BattleManager) -> void:
	ui = p_ui
	manager = p_manager
	grid = manager.tactical_grid
	# The legacy grid uses _input, before GUI consumption: disable it so clicking
	# a popup can never leak through and commit a target underneath it.
	grid.set_process_input(false)
	cursor = preload("res://prototypes/isometric/SelectionCursor.gd").new()
	cursor.grid = grid
	cursor.z_index = 3000
	grid.unit_layer.add_child(cursor)
	_command_scroll = ScrollContainer.new()
	_command_scroll.follow_focus = true
	_command_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_command_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	ui._chapel_command_panel.add_child(_command_scroll)
	ui._chapel_command_buttons.reparent(_command_scroll)
	ui._chapel_command_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header = ui._chapel_command_buttons.get_child(0)
	_inspect = Label.new()
	_inspect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspect.custom_minimum_size = Vector2(210,0)
	_inspect.add_theme_font_size_override("font_size",20)
	ui._chapel_command_buttons.add_child(_inspect)
	ui._chapel_command_buttons.move_child(_inspect,1)
	_help = Label.new()
	_help.position = Vector2(24,154)
	_help.add_theme_font_size_override("font_size",22)
	_help.add_theme_color_override("font_color",Color("fff2c5"))
	_help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_help)
	manager.turn_started.connect(_on_turn)
	manager.turn_ended.connect(func(_id: String): clear_selection())
	manager.unit_defeated.connect(func(id: String):
		if id == selected_id: clear_selection())
	manager.action_state_changed.connect(func(_m: bool,_a: bool,_p: bool): refresh.call_deferred())
	refresh()

func _process(_delta: float) -> void:
	if not is_instance_valid(manager): return
	# select_ability doesn't have a selection-specific signal; observe its real
	# state without duplicating or modifying combat commands.
	if _last_command != manager.active_command:
		refresh()
	layout_popup()

func _on_turn(id: String, _team: String) -> void:
	clear_selection()
	var unit := manager._living_unit(id)
	if unit: set_cursor(unit.grid_pos)
	refresh()

func can_command() -> bool:
	return manager != null and selected_id == manager.active_unit_id \
		and manager.current_phase == BattleManager.Phase.PLAYER_TURN \
		and not manager.is_resolving_action and manager._living_unit(selected_id) != null

func is_targeting() -> bool:
	return manager.active_command in ["move", "attack", "ability_target"]

func set_cursor(cell: Vector2i) -> void:
	if not grid.tiles.has(cell): return
	cursor_cell = cell
	cursor.cell = cell
	grid.selected_tile = cell
	grid._refresh_highlights()
	manager._on_tile_hovered(cell)
	cursor.queue_redraw()

func clear_selection() -> void:
	if is_instance_valid(manager) and manager.active_command == "ability" and not manager.is_resolving_action:
		manager.cancel_pending_action()
	selected_id = ""
	if cursor:
		cursor.selection_cell = Vector2i(-1,-1)
		cursor.queue_redraw()
	if ui:
		ui._chapel_command_panel.hide()
		ui._ability_panel.hide()
		ui._preview_panel.hide()
		var focus := ui.get_viewport().gui_get_focus_owner()
		if focus: focus.release_focus()
	refresh()

func select_unit(id: String) -> void:
	if manager.is_resolving_action: return
	if manager.active_command == "ability":
		manager.cancel_pending_action()
		ui._ability_panel.hide()
	var unit := manager._living_unit(id)
	if not unit: return
	selected_id = id
	set_cursor(unit.grid_pos)
	cursor.selection_cell = unit.grid_pos
	refresh()
	if can_command():
		for button: Button in [ui._move_btn,ui._attack_btn,ui._ability_btn,ui._wait_btn]:
			if not button.disabled:
				button.grab_focus()
				break

func go_back() -> void:
	if manager.is_resolving_action: return
	if not manager.active_command.is_empty():
		manager.cancel_pending_action()
		ui._ability_panel.hide()
		var unit := manager._living_unit(selected_id)
		if unit: set_cursor(unit.grid_pos)
		refresh()
		if can_command(): ui._wait_btn.grab_focus()
	else:
		clear_selection()

func activate_cursor() -> void:
	if manager.is_resolving_action: return
	if not grid.tiles.has(cursor_cell): return
	if is_targeting():
		if not can_command(): return
		# Existing async manager locks before any await; double-clicks cannot spend twice.
		manager._on_tile_clicked(cursor_cell)
		refresh()
		return
	var unit := manager._unit_at_pos(cursor_cell)
	if unit:
		select_unit(unit.unit_id)
	else:
		clear_selection()

func _pointed_cell(position: Vector2) -> Vector2i:
	# Movement always uses the ground diamond, never an overlapping actor.
	var ground := grid._local_to_grid(grid.get_global_transform_with_canvas().affine_inverse() * position)
	if manager.active_command == "move": return ground
	# Click opaque actor pixels as well as feet, respecting painter order.
	var hit: Unit
	for value in manager.units.values():
		var unit := value as Unit
		if not is_instance_valid(unit) or unit.hp <= 0: continue
		var sprite: Sprite2D = unit._sprite
		if is_instance_valid(sprite) and (sprite.visible or bool(grid.get("rotatable_mode"))):
			var point := sprite.get_global_transform_with_canvas().affine_inverse() * position
			if sprite.get_rect().has_point(point) and sprite.is_pixel_opaque(point) and (not hit or unit.position.y > hit.position.y): hit = unit
	if hit: return hit.grid_pos
	return ground

func handle_input(event: InputEvent) -> bool:
	if ui._settings_overlay and ui._settings_overlay.visible: return false
	if event is InputEventMouseMotion:
		var cell := _pointed_cell(event.position)
		if grid.tiles.has(cell) and cell != cursor_cell: set_cursor(cell)
		return false
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			go_back(); return true
		if event.button_index == MOUSE_BUTTON_LEFT:
			var cell := _pointed_cell(event.position)
			if grid.tiles.has(cell):
				set_cursor(cell)
				activate_cursor()
				return true
			return false
	if not event is InputEventKey or not event.pressed: return false
	if event.keycode in [KEY_Q, KEY_E] and not event.echo:
		var scene := ui.get_parent()
		if scene.has_method("rotate_stage"):
			scene.rotate_stage(-1 if event.keycode == KEY_Q else 1)
			return true
	if event.keycode in [KEY_ESCAPE,KEY_BACKSPACE]:
		go_back(); return true
	if event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] and not event.echo:
		var focused := ui.get_viewport().gui_get_focus_owner()
		if not is_targeting() and focused is Button and focused.is_visible_in_tree() and not focused.disabled and ui.is_ancestor_of(focused):
			focused.pressed.emit()
		else:
			activate_cursor()
		return true
	var delta := Vector2i.ZERO
	# Isometric compass: each arrow moves along a visible diagonal grid edge.
	match event.keycode:
		KEY_RIGHT: delta = Vector2i(1,0)
		KEY_LEFT: delta = Vector2i(-1,0)
		KEY_DOWN: delta = Vector2i(0,1)
		KEY_UP: delta = Vector2i(0,-1)
	if delta != Vector2i.ZERO:
		set_cursor(cursor_cell + (grid.screen_step(delta) if grid.has_method("screen_step") else delta))
		return true
	return false

func refresh() -> void:
	if not is_instance_valid(ui) or not is_instance_valid(manager): return
	var unit := manager._living_unit(selected_id)
	var active := manager._living_unit(manager.active_unit_id)
	var busy := manager.is_resolving_action
	var target := is_targeting()
	var was_command := _last_command
	_last_command = manager.active_command
	if not unit:
		selected_id = ""
		ui._chapel_command_panel.hide()
	else:
		cursor.selection_cell = unit.grid_pos
		cursor.queue_redraw()
		_header.text = unit.display_name.to_upper()
		_inspect.text = "HP %d/%d  ·  MP %d\n%s" % [unit.hp,unit.unit_data.base_stats.hp,unit.mp,
			"Your turn" if can_command() else ("Enemy · inspect only" if unit.team == "enemy" else "Ally · waiting for their turn")]
		ui._chapel_command_panel.visible = not busy
		for button: Button in [ui._move_btn,ui._attack_btn,ui._ability_btn,ui._wait_btn]:
			button.visible = can_command() and not target and manager.active_command != "ability"
		ui._cancel_btn.visible = true
		ui._cancel_btn.disabled = busy
		ui._cancel_btn.text = "Back  [Esc]" if not manager.active_command.is_empty() else "Close  [Esc]"
	if busy:
		ui._ability_panel.hide()
		ui._preview_panel.hide()
	if target and was_command != manager.active_command:
		var focus := ui.get_viewport().gui_get_focus_owner()
		if focus: focus.release_focus()
		if grid.tiles.has(cursor_cell): set_cursor(cursor_cell)
	_help.visible = not busy
	if active:
		if grid.active_unit_tile != active.grid_pos and not busy:
			grid.show_active_unit(active.grid_pos,active.team)
		_help.text = ("%s is acting…" % active.display_name) if busy or active.team == "enemy" else \
			("%s · %s" % [active.display_name, "Choose a highlighted target · Esc / Back to cancel" if target else "Select the glowing ally to open commands"])
	layout_popup()

func layout_popup() -> void:
	if not is_instance_valid(ui) or not is_instance_valid(grid): return
	var unit := manager._living_unit(selected_id)
	if not unit: return
	var viewport := ui.get_viewport().get_visible_rect().size
	var anchor := grid.get_global_transform_with_canvas() * grid._grid_to_local(unit.grid_pos)
	var panel := ui._chapel_command_panel
	var top := 145.0 if viewport.y >= 600 else 12.0
	var style := panel.get_theme_stylebox("panel")
	var inset := style.get_minimum_size() if style else Vector2.ZERO
	var content := ui._chapel_command_buttons.get_combined_minimum_size()
	panel.size = Vector2(minf(maxf(220, content.x + inset.x + 20), viewport.x - 24),
		minf(content.y + inset.y, viewport.y - top - 20))
	var x := anchor.x + 65.0
	var right_edge := viewport.x - ui._right_panel_scroll.size.x - 50.0
	if x+panel.size.x > right_edge: x = anchor.x-panel.size.x-65.0
	panel.position = Vector2(clampf(x,12,maxf(12,viewport.x-panel.size.x-12)),clampf(anchor.y-panel.size.y*0.5,top,maxf(top,viewport.y-panel.size.y-20)))
	if is_targeting() or manager.active_command == "ability":
		# Keep the ground targets clear while aiming. The contextual menu returns
		# beside the unit after commit/cancel.
		panel.position = Vector2(20,maxf(top,viewport.y-panel.size.y-24))
	if is_instance_valid(ui._proof_skills_panel):
		ui._layout_skills()
