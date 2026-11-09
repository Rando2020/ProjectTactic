extends Node

var checks := 0
var failures := 0
var manager: BattleManager
var ui: BattleUI
var scout: Unit
var caster: Unit
var ally: Unit
var enemies: Array[Unit] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func settle() -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while manager.is_resolving_action and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(not manager.is_resolving_action, "real action settles within five seconds")
	await get_tree().process_frame

func begin_turn(unit: Unit) -> void:
	manager.active_unit_id = unit.unit_id
	manager._set_phase(BattleManager.Phase.PLAYER_TURN)
	manager.cancel_pending_action()
	await get_tree().process_frame

func ability_button(label_text: String) -> Button:
	for child in ui._ability_list.get_children():
		if child.is_queued_for_deletion():
			continue
		for label: Label in child.find_children("*", "Label", true, false):
			if label.text == label_text:
				return child as Button
	return null

func choose_ability(label_text: String) -> void:
	ui._ability_btn.pressed.emit()
	await get_tree().process_frame
	var button := ability_button(label_text)
	check(button != null and button.is_visible_in_tree(), "actual menu renders " + label_text)
	if button:
		button.pressed.emit()

func expect_resources(hp_text: String, mp_text: String, context: String) -> void:
	# These are the actual Controls attached to the live Battle.tscn, not model
	# snapshots. Missing action refreshes must fail even when Unit.mp is correct.
	check(ui._hp_label.is_visible_in_tree() and ui._mp_label.is_visible_in_tree(), context + " resource Controls visible")
	check(ui._hp_label.size.x > 0 and ui._mp_label.size.x > 0, context + " resource Controls laid out")
	check(ui._hp_label.text == hp_text, context + " rendered HP expected " + hp_text + ", got " + ui._hp_label.text)
	check(ui._mp_label.text == mp_text, context + " rendered MP expected " + mp_text + ", got " + ui._mp_label.text)

func test_quickstep() -> void:
	scout.mp = 70
	await begin_turn(scout)
	var name_before := ui._unit_name.text
	var portrait_before := ui._active_portrait.texture
	var hp_before := ui._hp_label.text
	var temper_before := ui._temper_label.text
	var ether_before := ui._ether_label.text
	ui._move_btn.pressed.emit()
	var destination: Vector2i = manager.tactical_grid.move_tiles[0]
	manager.tactical_grid.tile_clicked.emit(destination)
	await settle()
	check(manager.active_unit_has_moved and not manager.active_unit_has_acted, "first real move spends movement only")
	await choose_ability("Quickstep")
	await settle()
	print("Quickstep real action: Unit.mp=%d; active MP Label.text=%s" % [scout.mp, ui._mp_label.text])
	check(scout.mp == 65, "Quickstep engine charges authored five MP exactly once")
	expect_resources(hp_before, "MP: 65", "Quickstep after recovery")
	check(ui._unit_name.text == name_before and ui._active_portrait.texture == portrait_before, "Quickstep refresh preserves active identity and portrait")
	check(ui._temper_label.text == temper_before and ui._ether_label.text == ether_before, "Quickstep preserves other resource labels")
	check(not ui._move_btn.disabled and ui._attack_btn.disabled and ui._ability_btn.disabled, "Quickstep retains action/movement tradeoff")
	ui._move_btn.pressed.emit()
	await get_tree().process_frame
	expect_resources(hp_before, "MP: 65", "Quickstep second Move selection")
	manager.cancel_pending_action()
	await begin_turn(caster)
	check(ui._unit_name.text.begins_with(caster.display_name) and ui._mp_label.text == "MP: 100", "turn handoff displays new active unit rather than previous Scout")
	await begin_turn(scout)
	expect_resources(hp_before, "MP: 65", "Scout next turn")

func test_spells() -> void:
	# Literal costs exercise separate single-target, chain-wrapper and healing
	# execution paths; a refresh only in Quickstep must not satisfy these cases.
	for fixture in [["Holy", 76], ["Thunder", 85], ["Cure", 92], ["Mass Cure", 60]]:
		caster.mp = 100
		caster.hp = 100
		ally.hp = 100
		await begin_turn(caster)
		var name_before := ui._unit_name.text
		await choose_ability(fixture[0])
		var target: Unit = ally if fixture[0] in ["Cure", "Mass Cure"] else enemies[0]
		check(target.grid_pos in manager.tactical_grid.ability_tiles, str(fixture[0]) + " real target is selectable")
		manager.tactical_grid.tile_clicked.emit(target.grid_pos)
		await settle()
		check(caster.mp == fixture[1], str(fixture[0]) + " engine spends authored MP once")
		var hp_text := "HP: 160/2000" if fixture[0] == "Mass Cure" else "HP: 100/2000"
		expect_resources(hp_text, "MP: %d" % fixture[1], str(fixture[0]) + " after action")
		check(ui._unit_name.text == name_before, str(fixture[0]) + " does not replace active identity with target")
		check(ui._hp_bar.value == (160 if fixture[0] == "Mass Cure" else 100), str(fixture[0]) + " active HP bar agrees with label")
		check(manager.active_unit_has_acted and not manager.active_unit_has_moved, str(fixture[0]) + " leaves ordinary movement available")
		if fixture[0] == "Cure":
			check(ally.hp == 180, "Cure still restores flat 80 HP to intended ally")
			await begin_turn(ally)
			expect_resources("HP: 180/2000", "MP: 100", "healed ally turn")

func run() -> void:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	manager = battle.battle_manager
	ui = battle.get_node("BattleUI")
	scout = manager.units.lyra
	caster = manager.units.mira
	ally = manager.units.kael
	for unit: Unit in manager.units.values():
		unit.unit_data = unit.unit_data.duplicate(true)
		unit.unit_data.base_stats.hp = 2000
		unit.hp = 1000
		unit.mp = 100
		unit.statuses.clear()
		unit.grid_pos = Vector2i(9, 0)
		if unit.team == "enemy":
			enemies.append(unit)
	scout.grid_pos = Vector2i(1, 4)
	caster.grid_pos = Vector2i(3, 3)
	ally.grid_pos = Vector2i(3, 2)
	enemies[0].grid_pos = Vector2i(4, 3)
	enemies[1].grid_pos = Vector2i(5, 3)
	caster.unit_data.abilities.assign(["holy", "thunder", "cure", "mass_cure"])
	for pos in manager.tactical_grid.tiles:
		manager.tactical_grid.tiles[pos]["height"] = 0
	await test_quickstep()
	await test_spells()
	# An interrupted action can leave a freed actor in the manager dictionary
	# until its existing cleanup runs. A display refresh must not dereference it.
	var mp_before_deletion := ui._mp_label.text
	caster.queue_free()
	await get_tree().process_frame
	manager._emit_action_state()
	check(ui._mp_label.text == mp_before_deletion, "deleted active actor leaves the last rendered resources intact")
	battle.queue_free()
	await get_tree().process_frame
	print("Resource HUD: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
