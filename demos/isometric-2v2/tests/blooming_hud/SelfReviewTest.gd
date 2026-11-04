extends Node
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _ready() -> void: run.call_deferred()
func run() -> void:
	Engine.time_scale = 4
	var battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
	add_child(battle)
	var m = battle.battle_manager
	var ui = battle.battle_ui
	for i in 1000:
		if m.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().create_timer(0.025).timeout
	var actor = m.units[m.active_unit_id]
	# Restrict this fixture to a real range-zero AoE so the real UI button is unambiguous.
	actor.unit_data.abilities.clear()
	actor.unit_data.abilities.append("tremor")
	var mp: int = actor.mp
	ui._selection.select_unit(actor.unit_id)
	ui._on_ability()
	ui._ability_list.get_child(0).pressed.emit()
	check(actor.mp == mp and not m.is_resolving_action, "self-cast skill button reviews before spending MP")
	if actor.mp == mp:
		check(ui._confirm_btn.visible and ui._preview_panel.visible, "self-cast review shows confirm and forecast")
		ui._selection.go_back()
		await get_tree().process_frame
		check(ui.get_viewport().gui_get_focus_owner() == ui._ability_list.get_child(0), "cancel self review restores keyboard skill focus")
		check(ui._ability_panel.visible and m.active_command == "ability", "cancel self-cast review reopens skill list")
		ui._ability_list.get_child(0).pressed.emit()
		ui._on_confirm()
		ui._on_confirm()
	for i in 1000:
		if not m.is_resolving_action: break
		await get_tree().create_timer(0.025).timeout
	check(actor.mp == mp - 12 and m.active_unit_has_acted, "confirmed self-cast executes once")
	battle.queue_free()
	await get_tree().create_timer(2).timeout
	print("Self skill review failures: ", failures)
	get_tree().quit(failures)
