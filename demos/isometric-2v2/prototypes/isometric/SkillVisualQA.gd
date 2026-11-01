## QA-only controlled real-manager dispatch. Not a manual-play or browser claim.
extends Node
var battle: Node
var manager: BattleManager
var banner: Label
signal advance_requested
var waiting := false
var manual := false
func _input(event: InputEvent) -> void:
	if manual and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		if waiting: advance_requested.emit()
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	Engine.time_scale = 1.0
	manual = "--manual" in OS.get_cmdline_user_args()
	GameState._init_defaults()
	GameState.active_run = null
	GameState.practice_session = {}
	battle = preload("res://prototypes/isometric/Skirmish.tscn").instantiate()
	add_child(battle)
	manager = battle.battle_manager
	for frame in 300:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().process_frame
	var overlay := CanvasLayer.new()
	overlay.layer = 90
	add_child(overlay)
	banner = Label.new()
	banner.position = Vector2(240,635)
	banner.add_theme_color_override("font_color",Color.WHITE)
	banner.add_theme_color_override("font_outline_color",Color.BLACK)
	banner.add_theme_constant_override("outline_size",5)
	banner.add_theme_font_size_override("font_size",20)
	overlay.add_child(banner)
	manager.current_phase = BattleManager.Phase.PLAYER_TURN
	manager.active_unit_id = "zane"
	var cycle := 0
	while is_inside_tree():
		cycle += 1
		for id in ["thunderstrike","void_pulse","dark_breath","shadow_mend","mighty_strike","defend"]:
			_reset_units()
			var actor: Unit = manager.units.zane
			var target: Unit = manager.units.Enemy_1
			if id in ["dark_breath","shadow_mend"]:
				actor = manager.units.Enemy_2
				target = actor if id=="shadow_mend" else manager.units.zane
			elif id in ["mighty_strike","defend"]:
				actor = manager.units.kael
				target = actor if id=="defend" else manager.units.Enemy_1
			if id=="shadow_mend": actor.hp = 40
			manager.active_unit_id = actor.unit_id
			manager.tactical_grid.set_active_unit(actor.unit_id) if manager.tactical_grid.has_method("set_active_unit") else null
			banner.text = "QA • NORMAL 1× • %s • %s → %s" % [AbilityDB.get_ability(id).display_name,actor.display_name,target.display_name]
			print("VISUAL_QA_BEGIN ",cycle," ",id)
			if manual:
				banner.text += " • SPACE TO CAST"
				waiting = true
				await advance_requested
				waiting = false
			else:
				await get_tree().create_timer(3.0).timeout
			var ability: Dictionary = AbilityDB.get_ability(id)
			if id=="thunderstrike": await manager._execute_aoe_ability(actor,target.grid_pos,ability)
			else: await manager._execute_ability(actor,target,ability)
			await manager._recover_action()
			print("VISUAL_QA_DONE ",id)
			await get_tree().create_timer(1.0 if manual else 3.0).timeout
func _reset_units() -> void:
	for unit: Unit in manager.units.values():
		unit.unit_data = unit.unit_data.duplicate(true)
		unit.unit_data.base_stats.hp = 2000
		unit.hp = 2000
		unit.mp = 200
		unit.temper = 0
		unit.ether = 0
		unit.statuses.clear()
	var positions := {"zane":Vector2i(1,2),"kael":Vector2i(2,2),"Enemy_1":Vector2i(3,2),"Enemy_2":Vector2i(2,3)}
	for id: String in positions:
		var unit: Unit = manager.units[id]
		unit.grid_pos = positions[id]
		unit.position = manager.tactical_grid._unit_foot_pos(unit.grid_pos)
		unit._update_hp_bar()
	manager.tactical_grid._reproject_units()
