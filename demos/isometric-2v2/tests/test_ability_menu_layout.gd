extends Node

const UISettings := preload("res://scripts/ui/UISettings.gd")
var checks := 0
var failures := 0
var manager: BattleManager
var ui: BattleUI
var scout: Unit

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func settle_layout() -> void:
	for frame in range(6):
		await get_tree().process_frame

func button_named(label_text: String) -> Button:
	for child in ui._ability_list.get_children():
		if child.is_queued_for_deletion(): continue
		for label: Label in child.find_children("*", "Label", true, false):
			if label.text == label_text: return child as Button
	return null

func controls_rects() -> Array:
	return [ui._move_btn.get_global_rect(), ui._attack_btn.get_global_rect(),
		ui._ability_btn.get_global_rect(), ui._wait_btn.get_global_rect(), ui._cancel_btn.get_global_rect()]

func test_quickstep_layout(viewport_size: Vector2i, mode: int) -> void:
	get_tree().root.size = viewport_size
	UISettings.shared().set_mode(mode, false)
	manager.active_unit_id = scout.unit_id
	manager._set_phase(BattleManager.Phase.PLAYER_TURN)
	manager.active_unit_has_moved = true
	scout.has_moved = true
	manager._emit_action_state()
	ui._right_panel_scroll.scroll_vertical = 0
	ui._ability_btn.pressed.emit()
	await settle_layout()
	var quick := button_named("Quickstep")
	check(quick != null, "actual Quickstep menu button exists")
	if not quick: return
	var context := "%s mode %d" % [viewport_size, mode]
	var rail := ui._right_panel_scroll.get_global_rect()
	var initial := quick.get_global_rect()
	var commands_before := controls_rects()
	var scroll_before := ui._right_panel_scroll.scroll_vertical
	var mp_before := scout.mp
	check(rail.encloses(initial), context + " opens Quickstep fully within visible rail: " + str(initial))
	for label: Label in quick.find_children("*", "Label", true, false):
		if label.text == "Quickstep":
			check(label.get_theme_font_size("font_size") == roundi(16 * UISettings.shared().effective_scale(Vector2(viewport_size))), context + " preserves readable selected scale")
	for repeat in range(3):
		quick.mouse_entered.emit()
		await settle_layout()
		print("Menu geometry %s repeat %d: before=%s hover=%s scroll=%d->%d" % [context, repeat, initial, quick.get_global_rect(), scroll_before, ui._right_panel_scroll.scroll_vertical])
		check(ui._preview_panel.is_visible_in_tree() and ui._preview_note_label.text.contains("5 MP"), context + " hover retains real forecast content")
		check(quick.get_global_rect() == initial, context + " hover must not move the click target")
		check(controls_rects() == commands_before, context + " hover must not move command controls")
		check(ui._right_panel_scroll.scroll_vertical == scroll_before, context + " hover must not chase the target by scrolling")
		check(rail.encloses(quick.get_global_rect()), context + " hovered button remains fully clickable")
		quick.mouse_exited.emit()
		await settle_layout()
		quick.mouse_entered.emit()
		await settle_layout()
		check(quick.get_global_rect() == initial, context + " mouse exit/reenter has no oscillation")
		manager.action_preview_changed.emit({})
		await settle_layout()
		check(quick.get_global_rect() == initial and controls_rects() == commands_before, context + " clearing preview preserves target and commands")
	check(scout.mp == mp_before and not manager.active_unit_has_acted, context + " hover never commits the ability")
	quick.mouse_entered.emit()
	await settle_layout()
	ui._right_panel_scroll.ensure_control_visible(ui._preview_note_label)
	await settle_layout()
	check(rail.encloses(ui._preview_note_label.get_global_rect()), context + " full forecast explanation remains scroll-reachable")
	ui._cancel_btn.pressed.emit()
	await settle_layout()
	print("Cancel geometry %s: commands=%s rail=%s scroll=%d" % [context, controls_rects(), rail, ui._right_panel_scroll.scroll_vertical])
	check(not ui._ability_panel.visible and not ui._preview_panel.visible, context + " cancellation closes forecast and menu")
	check(rail.encloses(ui._ability_btn.get_global_rect()) and rail.encloses(ui._move_btn.get_global_rect()), context + " ordinary commands are not stranded after cancel")

func test_long_menu() -> void:
	get_tree().root.size = Vector2i(1920, 1080)
	UISettings.shared().set_mode(3, false)
	var abilities: Array[String] = ["fire", "blizzard", "thunder", "cure", "holy", "wind_slash", "cura", "haste", "protect", "mass_cure", "quickstep"]
	scout.unit_data.abilities = abilities
	scout.mp = 1000
	ui._ability_btn.pressed.emit()
	await settle_layout()
	var first := button_named("Fire")
	var last := button_named("Quickstep")
	check(first != null and last != null, "long menu uses authored selectable abilities")
	var rail := ui._right_panel_scroll.get_global_rect()
	check(first != null and rail.encloses(first.get_global_rect()), "long menu opens at its first usable entry")
	if last:
		last.grab_focus()
		await settle_layout()
		check(rail.encloses(last.get_global_rect()), "keyboard can reach last entry of long list at 150 percent")
	ui._cancel_btn.pressed.emit()
	await settle_layout()
	check(rail.encloses(ui._ability_btn.get_global_rect()), "closing scrolled long list returns ordinary commands to view")

func test_rapid_menu_toggle() -> void:
	scout.unit_data.abilities.assign(["long_shot", "quickstep"])
	ui._right_panel_scroll.scroll_vertical = 0
	ui._ability_btn.pressed.emit()
	ui._cancel_btn.pressed.emit()
	ui._ability_btn.pressed.emit()
	await settle_layout()
	var quick := button_named("Quickstep")
	check(ui._ability_panel.visible and manager.active_command == "ability", "rapid reopen keeps the newest menu state")
	check(ui._right_panel_scroll.get_global_rect().encloses(quick.get_global_rect()), "stale close callback cannot scroll a reopened menu away")
	ui._cancel_btn.pressed.emit()
	await settle_layout()

func test_click_at_original_hover_point() -> void:
	get_tree().root.size = Vector2i(2282, 1080)
	UISettings.shared().set_mode(0, false)
	scout.mp = 70
	manager.active_unit_id = scout.unit_id
	manager._set_phase(BattleManager.Phase.PLAYER_TURN)
	manager.active_unit_has_moved = true
	scout.has_moved = true
	manager._emit_action_state()
	ui._ability_btn.pressed.emit()
	await settle_layout()
	var quick := button_named("Quickstep")
	var original_point := quick.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = original_point
	get_viewport().push_input(motion)
	await settle_layout()
	check(ui._preview_panel.visible, "real viewport mouse hover shows Quickstep forecast")
	# Click the original coordinate after hover/layout, not a recomputed target.
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = original_point
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		get_viewport().push_input(click)
	var deadline := Time.get_ticks_msec() + 5000
	while manager.is_resolving_action and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	await settle_layout()
	check(scout.mp == 65 and manager.active_unit_has_acted and not manager.active_unit_has_moved, "original hover coordinate still clicks real Quickstep exactly once")
	check(ui._mp_label.text == "MP: 65", "resource HUD fix survives hover and pointer activation")

func run() -> void:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.selected_map_index = 0
	get_tree().root.content_scale_size = Vector2i.ZERO
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	manager = battle.battle_manager
	ui = battle.get_node("BattleUI")
	scout = manager.units.lyra
	scout.unit_data = scout.unit_data.duplicate(true)
	# Includes the CI logical viewport (1600x757 canvas) and native 150% sizes.
	for viewport_size in [Vector2i(2282,1080), Vector2i(1920,1080), Vector2i(1600,757), Vector2i(1366,768), Vector2i(1328,861), Vector2i(3840,2160)]:
		for mode in [0, 3]:
			await test_quickstep_layout(viewport_size, mode)
	await test_long_menu()
	await test_rapid_menu_toggle()
	await test_click_at_original_hover_point()
	UISettings.shared().set_mode(0, false)
	battle.queue_free()
	await get_tree().process_frame
	print("Ability menu layout: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
