extends "res://tests/blooming_skills/HeroSkillsTest.gd"
## Exercises the real catalog, Blooming HUD, selection controller and manager.
## A wrong category, hidden unaffordable spell, leaked Back state, or save rewrite
## must fail these contracts. No substitute combat or menu implementation.
var ui
var commands
var default_loadouts: Dictionary = {}

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
	GameState._init_defaults()
	GameState.save()
	var ownership := GameState.unit_registry.duplicate(true)
	var saved := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	check(ResourceLoader.exists("res://scripts/data/AbilityCommands.gd"), "ability catalog groups each unit's equipped commands by school")
	await boot()
	ui = battle.battle_ui
	check(ui.has_method("_on_magic"), "Magic is a separate selectable primary command")
	if not failures.is_empty():
		await cleanup()
		finish()
		return
	commands = load("res://scripts/data/AbilityCommands.gd")
	for id in ["zane", "kael"]:
		default_loadouts[id] = manager.units[id].unit_data.abilities.duplicate()
	catalog_cases()
	await menus_case()
	await affordability_case()
	await unit_availability_case()
	await alias_only_case()
	await silence_and_disabled_case()
	await cancel_stack_case()
	await self_review_case()
	await input_case()
	await small_viewport_focus_case()
	await geometry_case()
	check(GameState.unit_registry == ownership, "opening and cancelling categories never changes saved skill ownership")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == saved, "command browsing and review leave canonical save bytes unchanged")
	await cleanup()
	finish()

func finish() -> void:
	print("Command menu: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func frames(count: int = 4) -> void:
	for i in count: await get_tree().process_frame

func catalog_cases() -> void:
	var source: Array = ["haste", "fireball", "fire", "delay_strike", "defend", "unresolved_legacy", "cure", "protect", "thunderstrike", "void_pulse"]
	var before := source.duplicate(true)
	var result: Dictionary = commands.catalog(source)
	check(result.skills == ["delay_strike", "defend"], "physical and defensive actions stay in Skills")
	var schools := by_school(result)
	check(schools.keys().size() == 3 and schools.has("black") and schools.has("white") and schools.has("time"), "one unit can have Black, White and Time schools")
	check(schools.get("black", {}).get("abilities", []) == ["fire", "thunderstrike", "void_pulse"], "Black Magic canonicalizes Fire alias and deduplicates without losing spells")
	check(schools.get("white", {}).get("abilities", []) == ["cure", "protect"], "White Magic supports existing healing and protection data")
	check(schools.get("time", {}).get("abilities", []) == ["haste"], "Haste belongs to Time Magic")
	for school_id in ["black", "white", "time"]:
		check(schools.get(school_id, {}).get("label", "") == school_id.capitalize() + " Magic", "school has a readable label: " + school_id)
	check(source == before, "catalog projection does not rewrite input aliases or unresolved saved IDs")
	var empty: Dictionary = commands.catalog(["unresolved_legacy"])
	check(empty.skills.is_empty() and empty.schools.is_empty(), "unresolved records never create an empty selectable category")
	var subset: Dictionary = commands.catalog(["haste"])
	check(subset.skills.is_empty() and subset.schools.size() == 1 and subset.schools[0].id == "time", "available schools follow this unit's owned actions, not the global catalog")
	# Old recognized definitions without classification remain reachable.
	var fallback := ""
	for id in AbilityDB.ABILITIES:
		if not AbilityDB.get_ability(id).has("command_category"):
			fallback = id
			break
	if not fallback.is_empty():
		check(fallback in commands.catalog([fallback]).skills, "unclassified legacy action remains available under Skills")

func by_school(result: Dictionary) -> Dictionary:
	var schools: Dictionary = {}
	for school in result.schools: schools[school.id] = school
	return schools

func actor(id: String, abilities: Array = []) -> void:
	fixture(id)
	manager.units[id].unit_data.abilities.assign(default_loadouts[id] if abilities.is_empty() else abilities)
	manager.turn_started.emit(id, "player")
	ui._selection.select_unit(id)
	ui._selection.refresh()

func buttons() -> Array[Button]:
	var result: Array[Button] = []
	for child in ui._ability_list.get_children():
		if child is Button and not child.is_queued_for_deletion(): result.append(child)
	return result

func leaves() -> Array[String]:
	var result: Array[String] = []
	for button in buttons():
		if button.has_meta("ability_id"): result.append(str(button.get_meta("ability_id")))
	return result

func schools() -> Array[String]:
	var result: Array[String] = []
	for button in buttons():
		if button.has_meta("magic_school"): result.append(str(button.get_meta("magic_school")))
	return result

func find_leaf(id: String) -> Button:
	for button in buttons():
		if str(button.get_meta("ability_id", "")) == id: return button
	return null

func find_school(id: String) -> Button:
	for button in buttons():
		if str(button.get_meta("magic_school", "")) == id: return button
	return null

func open_school(id: String) -> bool:
	var button := find_school(id)
	check(is_instance_valid(button), "real school button is available: " + id)
	if not is_instance_valid(button): return false
	button.pressed.emit()
	return true

func choose_leaf(id: String) -> bool:
	var button := find_leaf(id)
	check(is_instance_valid(button), "real leaf button is available: " + id)
	if not is_instance_valid(button): return false
	button.pressed.emit()
	return true

func panel_text() -> String:
	var text := ""
	for label in ui._ability_panel.find_children("*", "Label", true, false): text += label.text + "\n"
	return text

func menus_case() -> void:
	actor("zane")
	await frames()
	check(ui._ability_btn.text.contains("Skills") and ui._magic_btn.text.contains("Magic"), "commands visibly distinguish Skills from Magic")
	check(ui._ability_btn.disabled and not ui._magic_btn.disabled, "pure spell loadout disables empty Skills but enables Magic")
	ui._magic_btn.pressed.emit()
	await frames()
	check(manager.active_command == "ability" and ui._command_category == "magic" and ui._magic_school == "", "Magic starts at school selection")
	check(schools() == ["black", "time"] and leaves().is_empty(), "Zane's first Magic menu contains exactly Black and Time, no leaf spells")
	await capture("01-magic-schools")
	if open_school("black"):
		await frames()
		check(leaves() == ["fire", "thunderstrike", "void_pulse"], "Black Magic contains only the actor's three dark/offensive spells")
		check(panel_text().contains("Black Magic"), "leaf breadcrumb identifies Black Magic")
		await capture("02-black-magic")
		ui._selection.go_back()
		await frames()
	if open_school("time"):
		await frames()
		check(leaves() == ["haste"], "Time Magic contains Haste and no Black Magic spell")
		check(panel_text().contains("Time Magic"), "leaf breadcrumb identifies Time Magic")
		await capture("03-time-magic")
	actor("kael")
	await frames()
	check(ui._magic_btn.disabled and not ui._ability_btn.disabled, "physical loadout disables empty Magic but enables Skills")
	ui._ability_btn.pressed.emit()
	await frames()
	check(leaves() == ["mighty_strike", "defend", "delay_strike", "heavy_slash"] and schools().is_empty(), "Skills opens physical actions directly without a fake school")
	await capture("04-skills")
	manager.cancel_pending_action()
	manager.select_command("ability")
	await frames()
	check(ui._command_category == "skills" and leaves().has("delay_strike"), "direct manager Ability still opens Skills from fresh command state")

func affordability_case() -> void:
	actor("zane")
	manager.units.zane.mp = 0
	ui._selection.refresh()
	await frames()
	check(not ui._magic_btn.disabled, "known but unaffordable Magic remains inspectable")
	ui._magic_btn.pressed.emit()
	if open_school("black"):
		await frames()
		check(leaves().size() == 3, "low MP does not hide any learned Black Magic spell")
		for button in buttons():
			check(button.disabled and (not button.tooltip_text.is_empty() or panel_text().contains("MP")), "unaffordable spell is visibly disabled with cost/reason")
		var before: int = manager.units.zane.mp
		manager.select_ability("fire")
		check(manager.selected_ability_id.is_empty() and manager.units.zane.mp == before and not manager.active_unit_has_acted, "authoritative manager also rejects unaffordable Fire without spending")
	actor("kael")
	manager.units.kael.mp = 0
	ui._ability_btn.pressed.emit()
	await frames()
	check(leaves().size() == 4, "low MP keeps all known Skills visible")
	check(find_leaf("defend") != null and not find_leaf("defend").disabled, "free Defend remains available at zero MP")

func unit_availability_case() -> void:
	actor("kael", ["heavy_slash", "haste", "fireball", "fire", "unresolved_legacy"])
	var before: Array = manager.units.kael.unit_data.abilities.duplicate()
	await frames()
	check(not ui._magic_btn.disabled and not ui._ability_btn.disabled, "any hero can expose both categories based on equipped abilities")
	ui._magic_btn.pressed.emit()
	await frames()
	check(schools().size() == 2 and schools().has("black") and schools().has("time"), "non-caster Kael can use two owned schools without class gating")
	if open_school("black"):
		await frames()
		check(leaves() == ["fire"], "alias duplicate appears once in actual menu and no global spell leaks in")
	check(manager.units.kael.unit_data.abilities == before, "menu projection preserves unresolved and alias records in unit ownership")
	actor("kael", ["unresolved_legacy"])
	await frames()
	check(ui._magic_btn.disabled and ui._ability_btn.disabled, "unresolved-only loadout disables both empty categories")
	actor("zane")
	ui._magic_btn.pressed.emit()
	open_school("time")
	actor("kael")
	await frames()
	check(not ui._ability_panel.visible and ui._magic_btn.disabled, "switching active unit closes old school and recomputes availability")
	ui._ability_btn.pressed.emit()
	await frames()
	check(leaves().has("heavy_slash") and not leaves().has("haste"), "new unit never inherits prior unit's spell submenu")

func alias_only_case() -> void:
	actor("zane", ["fireball"])
	ui._magic_btn.pressed.emit()
	if not open_school("black"): return
	await frames()
	check(leaves() == ["fire"] and not find_leaf("fire").disabled, "alias-only ownership presents one enabled canonical Fire leaf")
	if not choose_leaf("fire"): return
	await frames()
	check(manager.active_command == "ability_target" and manager.selected_ability_id == "fireball", "canonical Fire leaf targets using the actual owned legacy alias")
	ui._selection.go_back()
	await frames()
	check(ui._magic_school == "black" and leaves() == ["fire"] and manager.selected_ability_id.is_empty(), "alias-only targeting Back restores canonical Fire leaf")
	check(manager.units.zane.unit_data.abilities == ["fireball"], "casting navigation never rewrites legacy alias ownership")
	check(manager.units.zane.mp == 200 and not manager.active_unit_has_acted, "alias-only targeting cancel spends no MP or action")

func silence_and_disabled_case() -> void:
	actor("kael", ["heavy_slash", "haste"])
	var effect := StatusEffect.new()
	effect.status_id = "silence"
	effect.duration = 2
	manager.units.kael.apply_status(effect)
	ui._selection.refresh()
	await frames()
	check(not ui._magic_btn.disabled, "silence does not hide owned schools")
	ui._magic_btn.pressed.emit()
	if not open_school("time"): return
	await frames()
	var haste_button := find_leaf("haste")
	check(haste_button != null and haste_button.disabled and haste_button.tooltip_text.contains("Silenced"), "silenced Haste stays visible with its disabled reason")
	if haste_button: haste_button.pressed.emit()
	await frames()
	check(manager.active_command == "ability" and manager.selected_ability_id.is_empty() and not ui._selection.has_review(), "forwarded disabled spell signal cannot enter targeting or review")
	check(manager.units.kael.mp == 200 and not manager.active_unit_has_acted, "forwarded disabled spell signal never spends MP or action")
	ui._selection.go_back()
	ui._selection.go_back()
	ui._ability_btn.pressed.emit()
	await frames()
	check(find_leaf("heavy_slash") != null and not find_leaf("heavy_slash").disabled, "physical Skills remain selectable while silenced")
	if choose_leaf("heavy_slash"):
		await frames()
		check(manager.active_command == "ability_target", "silenced actor can still target physical Skill")
	actor("kael", ["heavy_slash", "haste"])
	manager.active_unit_has_acted = true
	manager._emit_action_state()
	await frames()
	check(ui._magic_btn.disabled and ui._ability_btn.disabled, "spent action disables both categories")
	ui._magic_btn.pressed.emit()
	ui._ability_btn.pressed.emit()
	check(manager.active_command.is_empty(), "forwarded disabled category signals cannot reopen a spent action")

func cancel_stack_case() -> void:
	actor("zane")
	ui._magic_btn.pressed.emit()
	if not open_school("black") or not choose_leaf("fire"): return
	await frames()
	check(manager.active_command == "ability_target" and not ui._ability_panel.visible, "spell leaf enters authoritative targeting")
	ui._selection.set_cursor(manager.units.Enemy_1.grid_pos)
	ui._selection.activate_cursor()
	await frames()
	check(ui._selection.has_review(), "real Fire target stages review")
	ui._selection.go_back()
	await frames()
	check(not ui._selection.has_review() and manager.active_command == "ability_target", "review Back returns to aiming")
	ui._selection.go_back()
	await frames()
	check(ui._ability_panel.visible and ui._magic_school == "black" and leaves().has("fire"), "target Back restores the originating Black Magic leaf list")
	check(manager.selected_ability_id.is_empty(), "returning to leaf list clears selected target spell")
	ui._selection.go_back()
	await frames()
	check(ui._magic_school == "" and schools() == ["black", "time"], "leaf Back restores school list")
	ui._selection.go_back()
	await frames()
	check(manager.active_command.is_empty() and not ui._ability_panel.visible and ui._magic_btn.is_visible_in_tree(), "school Back restores primary commands")
	check(get_viewport().gui_get_focus_owner() != ui._wait_btn, "Back never leaves Wait primed for accidental Enter")
	for i in 3:
		ui._magic_btn.pressed.emit()
		ui._magic_btn.pressed.emit()
		await frames()
		check(schools() == ["black", "time"], "repeated Magic activation never duplicates or bypasses schools")
		open_school("time")
		choose_leaf("haste")
		ui._selection.go_back()
		await frames()
		check(leaves() == ["haste"], "cancel Haste returns to Time rather than flattening the catalog")
		ui._selection.go_back()
		ui._selection.go_back()
	check(manager.units.zane.mp == 200 and not manager.active_unit_has_acted, "repeated navigation spends neither MP nor the action")

func self_review_case() -> void:
	actor("kael")
	ui._ability_btn.pressed.emit()
	if not choose_leaf("defend"): return
	await frames()
	check(ui._selection.has_review() and ui._confirm_btn.visible, "self-target skill still requires review confirmation")
	ui._selection.go_back()
	await frames()
	check(not ui._selection.has_review() and ui._ability_panel.visible and leaves().has("defend"), "cancel self review returns directly to Skills")
	check(get_viewport().gui_get_focus_owner() in buttons(), "cancel self review restores a leaf's keyboard focus")
	check(manager.units.kael.mp == 200 and not manager.active_unit_has_acted, "self review cancellation does not execute")
	ui._selection.go_back()
	await frames()
	check(manager.active_command.is_empty(), "Skills Back reaches commands without a school layer")

func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames()

func joy(button: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames()

func input_case() -> void:
	actor("zane")
	await frames()
	await key(KEY_S)
	check(manager.active_command.is_empty(), "Skills shortcut cannot open an empty category")
	await key(KEY_G)
	check(schools() == ["black", "time"], "G shortcut opens Magic schools")
	await key(KEY_ESCAPE)
	ui._magic_btn.grab_focus()
	await key(KEY_ENTER)
	check(schools() == ["black", "time"], "keyboard Enter opens focused Magic command")
	var time_button := find_school("time")
	if time_button:
		time_button.grab_focus()
		await key(KEY_ENTER)
		check(leaves() == ["haste"], "keyboard Enter opens focused school")
		await key(KEY_ESCAPE)
		check(schools() == ["black", "time"], "keyboard Escape returns from school leaves")
		await key(KEY_ESCAPE)
		check(manager.active_command.is_empty(), "keyboard Escape exits school menu")
	ui._magic_btn.grab_focus()
	await joy(JOY_BUTTON_A)
	check(schools() == ["black", "time"] and ui._ability_panel.visible, "gamepad accept opens focused Magic command")
	var black_button := find_school("black")
	if black_button:
		black_button.grab_focus()
		await joy(JOY_BUTTON_DPAD_DOWN)
		check(get_viewport().gui_get_focus_owner() == find_school("time"), "gamepad D-pad navigates between school rows")
		await joy(JOY_BUTTON_DPAD_UP)
		check(get_viewport().gui_get_focus_owner() == black_button, "gamepad D-pad returns to Black Magic")
		await joy(JOY_BUTTON_A)
		check(leaves().has("fire") and ui._magic_school == "black", "gamepad accept enters Black Magic")
		await joy(JOY_BUTTON_B)
		check(schools() == ["black", "time"], "gamepad cancel returns to schools")
		await joy(JOY_BUTTON_B)
		check(manager.active_command.is_empty(), "gamepad cancel returns to commands")
	actor("kael")
	await key(KEY_S)
	check(leaves().has("heavy_slash") and schools().is_empty(), "S shortcut opens physical Skills directly")
	await key(KEY_ESCAPE)

func small_viewport_focus_case() -> void:
	get_window().content_scale_size = Vector2i(960, 540)
	get_window().size = Vector2i(960, 540)
	var settings = load("res://scripts/ui/UISettings.gd").shared()
	settings.set_mode(3, false)
	actor("kael")
	ui._ability_btn.pressed.emit()
	await frames(6)
	await joy(JOY_BUTTON_DPAD_DOWN)
	var defend_button := find_leaf("defend")
	check(get_viewport().gui_get_focus_owner() == defend_button and ui._preview_panel.visible, "960px gamepad Down focuses Defend and opens its real self forecast")
	if defend_button:
		check(ui._proof_skills_scroll.get_global_rect().grow(2).encloses(defend_button.get_global_rect()), "960px Defend remains fully visible after forecast shrinks the scroll viewport")
	await joy(JOY_BUTTON_A)
	check(ui._selection.has_review(), "960px gamepad accepts focused Defend into self review")
	await joy(JOY_BUTTON_B)
	await frames(6)
	check(not ui._selection.has_review() and get_viewport().gui_get_focus_owner() == defend_button, "960px self-review cancel restores Defend focus")
	if defend_button:
		check(ui._proof_skills_scroll.get_global_rect().grow(2).encloses(defend_button.get_global_rect()), "960px cancelled self review leaves its focused skill visible")
	actor("zane", ["fire", "resonance_fracture"])
	ui._magic_btn.pressed.emit()
	if not open_school("black"): return
	await frames(6)
	await joy(JOY_BUTTON_DPAD_DOWN)
	var fracture := find_leaf("resonance_fracture")
	check(get_viewport().gui_get_focus_owner() == fracture and ui._preview_panel.visible, "960px gamepad reaches long Black Magic self-spell with forecast")
	if fracture:
		check(ui._proof_skills_scroll.get_global_rect().has_point(fracture.get_global_rect().get_center()), "960px long Black Magic self-spell retains a visible activation target")
	check(manager.units.zane.mp == 200 and not manager.active_unit_has_acted, "directional self-preview browsing never casts or spends")

func geometry_case() -> void:
	var settings = load("res://scripts/ui/UISettings.gd").shared()
	for viewport in [Vector2i(960,540), Vector2i(1280,720), Vector2i(1920,1080)]:
		get_window().content_scale_size = viewport
		get_window().size = viewport
		for mode in [1, 2, 3]:
			settings.set_mode(mode, false)
			actor("zane")
			await frames(6)
			var label := "%s scale %s" % [viewport, mode]
			var bounds := get_viewport().get_visible_rect()
			for button in [ui._move_btn, ui._attack_btn, ui._magic_btn, ui._ability_btn, ui._wait_btn]:
				check(bounds.encloses(button.get_global_rect()), "primary command stays on screen " + label)
				check(button.size.x >= button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x + 10, "primary label is not clipped " + label)
			ui._magic_btn.pressed.emit()
			await frames(6)
			check_menu_geometry(bounds, label + " schools")
			if viewport.x == 960 and mode == 3: await capture("05-magic-schools-960-large")
			if open_school("black"):
				await frames(6)
				check_menu_geometry(bounds, label + " Black Magic")
				if viewport.x == 960 and mode == 3: await capture("06-black-magic-960-large")
			actor("kael")
			ui._ability_btn.pressed.emit()
			await frames(6)
			check_menu_geometry(bounds, label + " Skills")
			if viewport.x == 960 and mode == 3: await capture("07-skills-960-large")
			var last := find_leaf("heavy_slash")
			if last:
				last.grab_focus()
				await frames(6)
				check(ui._proof_skills_scroll.get_global_rect().grow(2).encloses(last.get_global_rect()), "focused last skill scrolls into reachable view " + label)
	settings.set_mode(0, false)

func check_menu_geometry(bounds: Rect2, label: String) -> void:
	check(bounds.grow(1).encloses(ui._proof_skills_panel.get_global_rect()), "menu panel stays on screen " + label)
	check(bounds.grow(1).encloses(ui._cancel_btn.get_global_rect()), "Back remains on screen " + label)
	check(not ui._proof_skills_panel.get_global_rect().intersects(ui._cancel_btn.get_global_rect()), "menu never blocks Back " + label)
	check(not ui._proof_skills_panel.get_global_rect().intersects(ui._bloom_active_panel.get_global_rect()), "menu never covers active resources " + label)
	for button in buttons():
		check(button.get_global_rect().position.x >= bounds.position.x and button.get_global_rect().end.x <= bounds.end.x + 1, "leaf or school width stays readable " + label)
