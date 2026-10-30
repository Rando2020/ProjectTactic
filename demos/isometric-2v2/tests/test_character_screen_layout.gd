extends Node

const UISettings := preload("res://scripts/ui/UISettings.gd")
var checks := 0
var failures := 0
var screen: CharacterScreen

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func settle() -> void:
	for frame in range(6): await get_tree().process_frame

func send_key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		get_viewport().push_input(event)

func key(code: Key) -> void:
	send_key(code)
	await settle()

func button_named(text: String) -> Button:
	for node in screen.find_children("*", "Button", true, false):
		if node.text == text and not node.is_queued_for_deletion(): return node
	return null

func rail() -> ScrollContainer:
	var found := screen.find_children("*", "ScrollContainer", true, false)
	return found[0] if not found.is_empty() else null

func visible_control(control: Control) -> bool:
	var rect := control.get_global_rect()
	var viewport := get_viewport().get_visible_rect()
	return control.is_visible_in_tree() and viewport.encloses(rect) and (rail() == null or rail().get_global_rect().encloses(rect))

func exercise_size(physical: Vector2i, native_canvas: bool) -> void:
	get_tree().root.content_scale_size = Vector2i(1920, 1080) if native_canvas else Vector2i.ZERO
	get_tree().root.size = physical
	screen = load("res://scenes/CharacterScreen.tscn").instantiate()
	add_child(screen)
	await settle()
	var context := "%s native_canvas=%s" % [physical, native_canvas]
	var before := GameState.serialize_state()
	var disk_before := FileAccess.get_sha256(GameState.SAVE_PATH)
	check(rail() != null, context + " overflowing character content has a scroll surface")
	check(screen._hint_label.get_theme_font_size("font_size") == 28, context + " preserves authored hint typography with title preference 150%")
	# A full-scene minimum-width regression must not push any button off to the right.
	for tab_index in range(4):
		await key([KEY_1, KEY_2, KEY_3, KEY_4][tab_index])
		var tab: String = ["Status", "Jobs", "Abilities", "Equipment"][tab_index]
		check(screen._active_tab == tab, context + " actual number key selects " + tab)
		var active := button_named(tab)
		print("Tab reveal %s %s tab=%s name=%s scroll=%d" % [context, tab, active.get_global_rect(), screen._detail_panel.get_child(1).get_global_rect(), rail().scroll_vertical if rail() else -1])
		check(active != null and visible_control(active), context + " number key reveals selected tab " + tab)
		check(visible_control(screen._detail_panel.get_child(1)) and visible_control(screen._detail_panel.get_child(2)), context + " number key reveals selected identity and panel content, not only the tab edge")
		check(get_viewport().gui_get_focus_owner() == active, context + " selected tab receives keyboard focus")
		if active: check(active.get_theme_font_size("font_size") == 22, context + " preserves authored tab font")
		for node in screen.find_children("*", "Button", true, false):
			var button := node as Button
			var rect := button.get_global_rect()
			check(rect.position.x >= 0 and rect.end.x <= get_viewport().get_visible_rect().end.x, context + " button horizontally accessible: " + button.text + " " + str(rect))
			if button.disabled: continue
			button.grab_focus()
			await settle()
			check(visible_control(button), context + " keyboard focus reveals full button: " + button.text)
	# Roster selection changes the real unit and brings its selected details back into view.
	await key(KEY_3)
	await key(KEY_E)
	check(screen._selected_uid == "mira", context + " E changes real selected unit")
	check(visible_control(button_named("Abilities")), context + " newly selected unit's details remain accessible")
	check(visible_control(screen._detail_panel.get_child(1)), context + " newly selected identity is visible without another scroll")
	check(screen._detail_panel.get_child(1).text == "Mira Vey", context + " details retain real selected identity")
	await key(KEY_Q)
	check(screen._selected_uid == "zane", context + " Q restores selected unit")
	await key(KEY_3)
	await key(KEY_TAB)
	check(get_viewport().gui_get_focus_owner() == button_named("Equipment"), context + " Tab advances to the next visible panel control")
	await key(KEY_ENTER)
	check(screen._active_tab == "Equipment" and visible_control(button_named("Equipment")), context + " Enter activates the focused panel without losing it")
	var kael := screen._roster_grid.get_child(2) as Button
	kael.grab_focus()
	await settle()
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = kael.get_global_rect().get_center()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		# get_global_rect() is in logical canvas coordinates, not physical window pixels.
		get_viewport().push_input(click, true)
	await settle()
	check(screen._selected_uid == "kael", context + " actual pointer activates the roster member")
	check(visible_control(button_named("Equipment")) and screen._detail_panel.get_child(1).text == "Kael", context + " pointer selection reveals matching details")
	await key(KEY_3)
	# Real wheel input must move the existing content rather than lose the panel offscreen.
	if rail():
		rail().scroll_vertical = 0
		await settle()
		var wheel := InputEventMouseButton.new()
		wheel.position = rail().get_global_rect().get_center()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		get_viewport().push_input(wheel, true)
		await settle()
		var bar := rail().get_v_scroll_bar()
		check(rail().scroll_vertical > 0 or bar.max_value <= bar.page, context + " actual wheel reaches overflow, or all content already fits")
		var back := button_named("Back to Hub")
		back.grab_focus()
		await settle()
		check(visible_control(back), context + " Back/footer remains keyboard reachable")
	check(GameState.serialize_state() == before, context + " browsing/layout never mutates identity, JP, equipment or save state")
	check(FileAccess.get_sha256(GameState.SAVE_PATH) == disk_before, context + " browsing/layout never rewrites save bytes")
	print("Character layout %s: viewport=%s root=%s details=%s" % [context, get_viewport().get_visible_rect(), screen._root.get_global_rect(), screen._detail_panel.get_global_rect()])
	screen.queue_free()
	await settle()

func test_live_resize() -> void:
	get_tree().root.content_scale_size = Vector2i.ZERO
	get_tree().root.size = Vector2i(3840, 2160)
	screen = load("res://scenes/CharacterScreen.tscn").instantiate()
	add_child(screen)
	await settle()
	await key(KEY_3)
	await key(KEY_E)
	for size in [Vector2i(1328,861), Vector2i(3840,2160), Vector2i(1920,1080)]:
		get_tree().root.size = size
		await settle()
		check(screen._active_tab == "Abilities" and screen._selected_uid == "mira", "resize preserves current tab and character")
		check(visible_control(button_named("Abilities")), "resize keeps current panel accessible at " + str(size))
		check(screen.find_children("*", "ScrollContainer", true, false).size() == 1, "resize leaves exactly one live scroll surface")
	screen.queue_free()
	await settle()

func test_rapid_selection() -> void:
	var cases := [
		{"keys": [KEY_2, KEY_E], "tab": "Jobs", "uid": "mira"},
		{"keys": [KEY_2, KEY_2], "tab": "Jobs", "uid": "zane"},
		{"keys": [KEY_2, KEY_E, KEY_4, KEY_E, KEY_3, KEY_Q], "tab": "Abilities", "uid": "mira"},
	]
	for native_canvas in [false, true]:
		get_tree().root.content_scale_size = Vector2i(1920,1080) if native_canvas else Vector2i.ZERO
		get_tree().root.size = Vector2i(1328,861)
		for scenario in cases:
			screen = load("res://scenes/CharacterScreen.tscn").instantiate()
			add_child(screen)
			await settle()
			var before := GameState.serialize_state()
			for code in scenario.keys: send_key(code) # Deliberately no frame between real input events.
			await settle()
			check(screen._active_tab == scenario.tab and screen._selected_uid == scenario.uid, "rapid input keeps latest selected tab/unit")
			check(visible_control(button_named(scenario.tab)) and visible_control(screen._detail_panel.get_child(1)), "only latest deferred reveal may scroll: native=%s keys=%s identity=%s" % [native_canvas, scenario.keys, screen._detail_panel.get_child(1).get_global_rect()])
			check(GameState.serialize_state() == before, "rapid UI selection leaves progression untouched")
			screen.queue_free()
			await settle()

func run() -> void:
	GameState.unit_registry.clear()
	GameState._init_defaults()
	GameState.unit_registry.zane.jp = 100 # Browse an actually eligible Learn button; never activate it.
	GameState.save()
	UISettings.shared().set_mode(3, false)
	for physical in [Vector2i(1328,861), Vector2i(3840,2160)]:
		await exercise_size(physical, true)
	for logical in [Vector2i(1328,861), Vector2i(1920,1080), Vector2i(3840,2160)]:
		await exercise_size(logical, false)
	await test_live_resize()
	await test_rapid_selection()
	UISettings.shared().set_mode(0, false)
	print("Character screen layout: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
