extends Node
## Projection/input/combat contracts. These do not substitute for graphical QA.
var checks := 0
var failures := 0
var original_scene: Node
const BATTLE := "res://prototypes/isometric/Skirmish.tscn"
func _ready() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func wait_scene(path: String) -> bool:
	for i in 1600:
		if is_instance_valid(get_tree().current_scene) and get_tree().current_scene.scene_file_path == path: return true
		await get_tree().create_timer(0.025).timeout
	check(false, "transition " + path)
	return false
func wait_player(manager: BattleManager) -> void:
	for i in 1600:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN and not manager.is_resolving_action: return
		await get_tree().create_timer(0.025).timeout
	check(false,"player turn becomes ready")
func wait_resolution(manager: BattleManager) -> void:
	for i in 1600:
		if not manager.is_resolving_action: return
		await get_tree().create_timer(0.025).timeout
	check(false,"action resolves")
func fresh_battle():
	if GameState.practice_session.is_empty(): GameState.begin_illustrated_chapel_practice()
	GameState.practice_session["rotatable_stage"] = false
	get_tree().change_scene_to_file.call_deferred(BATTLE)
	if not await wait_scene(BATTLE): return null
	var battle = get_tree().current_scene
	await wait_player(battle.battle_manager)
	await get_tree().process_frame
	return battle
func verify_queue(ui, manager: BattleManager, prefix: String) -> void:
	check(ui._turn_rows[0].unit_id == manager.active_unit_id, prefix+" NOW preserved")
	var projected := manager.turn_order.get_projected_order(4)
	for i in projected.size():
		check(ui._turn_rows[i+1].unit_id == projected[i].unit_id,prefix+" NEXT %d preserved"%i)
func set_angle(battle, angle: int) -> void:
	if not battle.tactical_grid.rotatable_mode: battle.set_stage_mode(true)
	var difference: int = posmod(angle-battle.tactical_grid.quarter_turn,4)
	if difference: battle.rotate_stage(difference)
	await get_tree().process_frame
func key(controller: Node, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	controller.handle_input(event)
func run() -> void:
	Engine.time_scale = 5
	original_scene = get_tree().current_scene
	get_tree().current_scene = null
	var battle = await fresh_battle()
	if not battle:
		finish(); return
	var grid = battle.tactical_grid
	var manager: BattleManager = battle.battle_manager
	var ui = battle.battle_ui
	var selection = ui._selection
	check(not grid.rotatable_mode,"painted remains initial mode")
	check(not battle.rotate_stage(1),"cannot rotate painted photograph")
	selection.select_unit("zane")
	var facing: String = manager.units.zane.facing
	var original_ct: int = manager.units.zane.ct
	var painted_position: Vector2 = manager.units.zane.position
	check(battle.set_stage_mode(true),"enable shared 3D stage")
	await get_tree().process_frame
	for angle in 4:
		await set_angle(battle,angle)
		check(grid.quarter_turn == angle,"quarter angle %d"%angle)
		for cell: Vector2i in grid.tiles:
			var local: Vector2 = grid._grid_to_local(cell)
			check(grid._local_to_grid(local) == cell,"ground roundtrip angle%d cell%s"%[angle,cell])
		check(grid._local_to_grid(Vector2(-99999,-99999)) == Vector2i(-1,-1),"outside invalid angle%d"%angle)
		check(selection.selected_id == "zane" and selection.can_command(),"selection survives angle%d"%angle)
		check(selection.cursor_cell == manager.units.zane.grid_pos,"cursor logical cell survives angle%d"%angle)
		check(manager.units.zane.facing == facing and manager.units.zane.ct == original_ct,"view cannot change facing or CT angle%d"%angle)
		check(manager.units.zane.view_quarter == angle,"visual facing tracks view angle%d"%angle)
		var directions := {"N":Vector2i(0,-1),"E":Vector2i(1,0),"S":Vector2i(0,1),"W":Vector2i(-1,0)}
		for direction: String in directions:
			var expected_direction: Vector2 = (grid._grid_to_local(Vector2i(2,2)+directions[direction])-grid._grid_to_local(Vector2i(2,2))).normalized()
			check(manager.units.zane._facing_screen_direction(direction).dot(expected_direction) > 0.999,"facing marker matches camera angle%d %s"%[angle,direction])
		check(ui._chapel_command_panel.visible,"context commands visible angle%d"%angle)
		for unit: Unit in manager.units.values():
			var sprite: Sprite2D = unit._sprite
			var rect := sprite.get_rect()
			var found := false
			var hit := false
			for y in range(2,15):
				for x in range(7,14):
					var pixel := rect.position + rect.size * Vector2(x/20.0,y/20.0)
					if not sprite.is_pixel_opaque(pixel): continue
					found = true
					var point: Vector2 = sprite.get_global_transform_with_canvas()*pixel
					var stage = grid.stage_view
					var proxy: Sprite3D = stage._actors[unit.unit_id]
					var card_pixel := Vector2(pixel.x+sprite.position.x/sprite.scale.x,-pixel.y-sprite.position.y/sprite.scale.y)
					var world: Vector3 = proxy.global_position + stage.camera.global_basis.x*card_pixel.x*proxy.scale.x*proxy.pixel_size + stage.camera.global_basis.y*card_pixel.y*proxy.scale.y*proxy.pixel_size
					var proxy_local: Vector2 = stage.VIEW_CENTER + stage.camera.unproject_position(world)-Vector2(stage.RENDER_SIZE)*0.5
					var proxy_screen: Vector2 = grid.get_global_transform_with_canvas()*proxy_local
					check(proxy_screen.distance_to(point) < 3.0,"proxy/source projected upper body agrees angle%d %s"%[angle,unit.unit_id])
					if selection._pointed_cell(point) == unit.grid_pos:
						hit = true
						break
				if hit: break
			check(found and hit,"opaque upper-body pick angle%d %s"%[angle,unit.unit_id])
		verify_queue(ui,manager,"angle%d"%angle)
		selection.clear_selection()
		selection.set_cursor(Vector2i(2,2))
		key(selection,KEY_RIGHT)
		var delta: Vector2i = [Vector2i(1,0),Vector2i(0,-1),Vector2i(-1,0),Vector2i(0,1)][angle]
		check(selection.cursor_cell == Vector2i(2,2)+delta,"right cursor follows screen edge angle%d"%angle)
		var movement: Vector2 = grid._grid_to_local(Vector2i(2,2)+delta)-grid._grid_to_local(Vector2i(2,2))
		check(movement.x > 0,"right cursor projects right angle%d"%angle)
		selection.select_unit("zane")
		ui._on_move()
		selection.set_cursor(Vector2i(2,3))
		var screen: Vector2 = grid.get_global_transform_with_canvas()*grid._grid_to_local(Vector2i(2,3))
		check(selection._pointed_cell(screen) == Vector2i(2,3),"actual movement pointer angle%d"%angle)
		var mp: int = manager.units.zane.mp
		var target_cell: Vector2i = selection.cursor_cell
		check(battle.rotate_stage(1),"rotate while choosing destination angle%d"%angle)
		check(manager.active_command == "move" and selection.cursor_cell == target_cell,"rotation retains pending target angle%d"%angle)
		check(battle.set_stage_mode(false),"painted comparison during target angle%d"%angle)
		check(manager.active_command == "move" and selection.cursor_cell == target_cell,"comparison retains pending target angle%d"%angle)
		selection.go_back()
		check(manager.units.zane.mp == mp and not manager.active_unit_has_moved,"cancel after view change is free angle%d"%angle)
		check(manager.units.zane.position.is_equal_approx(painted_position),"painted position restored angle%d"%angle)
		check(manager.units.zane._sprite.visible,"painted actor returns angle%d"%angle)
		battle.set_stage_mode(true)
		selection.select_unit("zane")
	# Exercise real attack and spell commits independently in every orientation.
	for trial in 8:
		var angle: int = trial % 4
		if is_instance_valid(get_tree().current_scene):
			get_tree().current_scene.queue_free()
			get_tree().current_scene = null
		await get_tree().process_frame
		battle = await fresh_battle()
		if not battle: break
		manager = battle.battle_manager
		grid = battle.tactical_grid
		ui = battle.battle_ui
		selection = ui._selection
		await set_angle(battle,angle)
		selection.select_unit("zane")
		ui._on_move()
		selection.set_cursor(Vector2i(2,3))
		selection.activate_cursor()
		check(manager.is_resolving_action,"move resolves angle%d"%angle)
		check(not battle.rotate_stage(1) and not battle.set_stage_mode(false),"busy projection mutation refused angle%d"%angle)
		await wait_resolution(manager)
		check(manager.units.zane.grid_pos == Vector2i(2,3),"legal move commits angle%d"%angle)
		check(manager.units.zane.position.is_equal_approx(grid._unit_foot_pos(Vector2i(2,3))),"mover ends at projected foot angle%d"%angle)
		var preview_mp: int = manager.units.zane.mp
		manager.select_ability("fire")
		selection.refresh()
		selection.set_cursor(manager.units.Enemy_2.grid_pos)
		check(manager.units.Enemy_2.grid_pos in grid.ability_tiles,"Fire targeting legal in every view angle%d"%angle)
		selection.go_back()
		check(manager.units.zane.mp == preview_mp and not manager.active_unit_has_acted,"Fire cancellation free angle%d"%angle)
		ui._on_attack()
		var enemy: Unit = manager.units.Enemy_1
		selection.set_cursor(enemy.grid_pos)
		check(enemy.grid_pos in grid.attack_tiles,"attack legal angle%d"%angle)
		check(ui._preview_panel.visible,"attack forecast visible angle%d"%angle)
		selection.go_back()
		check(not manager.active_unit_has_acted,"cancel attack free angle%d"%angle)
		if trial < 4:
			var attacked := {"count":0}
			manager.combat_resolver.combat_resolved.connect(func(_result: Dictionary):
				if manager.active_unit_id == "zane": attacked.count += 1)
			ui._on_attack()
			selection.set_cursor(enemy.grid_pos)
			selection.activate_cursor()
			await wait_resolution(manager)
			check(attacked.count >= 1,"real attack resolved (counter may follow) angle%d"%angle)
		else:
			var before_mp: int = manager.units.zane.mp
			manager.select_ability("fire")
			selection.refresh()
			selection.set_cursor(manager.units.Enemy_2.grid_pos)
			check(manager.units.Enemy_2.grid_pos in grid.ability_tiles,"Fire legal angle%d"%angle)
			selection.activate_cursor()
			await wait_resolution(manager)
			check(manager.units.zane.mp == before_mp-12,"real Fire charged once angle%d"%angle)
		check(grid.quarter_turn == angle,"action cannot rotate view angle%d"%angle)
		# Let enemy AI finish before disposing this fixture; do not strand its timers.
		await wait_player(manager)
		await get_tree().process_frame
		verify_queue(ui,manager,"post action%d"%angle)
	# KO and real Replay lifecycle under the rotatable presentation.
	if is_instance_valid(battle):
		for id: String in ["Enemy_1","Enemy_2"]:
			var unit := manager._living_unit(id)
			if unit: unit.receive_damage(99999,"pure")
			await get_tree().process_frame
			await get_tree().process_frame
			check(not grid.stage_view._actors.has(id),"defeated actor proxy removed: "+id)
		await get_tree().process_frame
		manager._set_phase(BattleManager.Phase.CHECK_OBJECTIVE)
		if await wait_scene("res://scenes/ResultsScreen.tscn"):
			var retry: Button
			for candidate in get_tree().current_scene.find_children("*","Button",true,false):
				if candidate.text == "Replay Fight": retry = candidate
			check(retry != null,"real replay control exists")
			if retry:
				retry.pressed.emit()
				if await wait_scene(BATTLE):
					battle = get_tree().current_scene
					await wait_player(battle.battle_manager)
					check(battle.battle_manager.units.size() == 4,"retry restores four fighters")
					check(battle.tactical_grid.rotatable_mode,"retry retains selected presentation")
					check(battle.battle_ui._selection.selected_id.is_empty(),"retry selection fresh")
					verify_queue(battle.battle_ui,battle.battle_manager,"replay")
	finish()
func finish() -> void:
	if is_instance_valid(get_tree().current_scene): get_tree().current_scene.queue_free()
	get_tree().current_scene = original_scene
	Engine.time_scale = 1
	await get_tree().create_timer(2).timeout
	print("Rotatable stage: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
