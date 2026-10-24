extends Node

var failures := 0
var checks := 0

func _ready() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var gs := get_tree().root.get_node("GameState")
	var rm := get_tree().root.get_node("RunManager")
	# Run with isolated XDG_DATA_HOME. Never invoke against a player's save.
	gs.delete_save()
	gs.unit_registry["kael"]["jp"] = 77
	gs.unit_registry["kael"]["job_jp"] = {"squire": 90}
	rm.start_new_run(0, 42)
	check(gs.unit_registry.size() == 4, "New run preserves all four characters")
	check(gs.get_jp("kael") == 77, "New run preserves earned JP")
	check(gs.get_all_abilities("mira").size() > 0, "New run retains caster abilities")
	gs.set_current_job("kael", "resonant")
	check(gs.unit_registry.kael.current_job_id == "squire", "Locked jobs rejected")
	gs.set_current_job("kael", "warder")
	check(gs.unit_registry.kael.current_job_id == "warder", "Earned advanced job available")
	gs.active_run.run_deployment = [{"unit_id":"kael", "x":1,"y":6,"facing":"N"}]
	gs.active_run.active_boons = [{"id":"test_boon"}]
	rm.run_aether = 25
	gs.save()
	gs.active_run = null
	check(gs.load_save(), "Checkpoint reload succeeds")
	check(gs.active_run != null and gs.active_run.seed == 42, "Fresh-process null run restores")
	check(gs.active_run.run_aether == 25, "Run currency survives reload")
	check(gs.active_run.run_deployment.size() == 1, "Formation survives reload")
	check(gs.active_run.active_boons.size() == 1, "Boons survive reload")
	# Use real battle scene and rules. Manual startup must not consume turns.
	gs.active_run = null
	gs.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	get_tree().root.add_child(battle)
	get_tree().current_scene = battle
	var manager: BattleManager = battle.battle_manager
	check(battle.comparison_panel == null, "Ordinary battle has no practice comparison panel")
	check(manager.tactical_grid.terrain_view == null, "Ordinary battle retains 2D terrain")
	check(not manager.auto_battle_enabled, "Human controls battle by default")
	for i in range(300):
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN:
			break
		await get_tree().create_timer(0.02).timeout
	check(manager.current_phase == BattleManager.Phase.PLAYER_TURN, "Battle reaches human turn")
	var uid := manager.active_unit_id
	var unit: Unit = manager.units[uid]
	var before := unit.grid_pos
	var mp := unit.mp
	await get_tree().create_timer(0.5).timeout
	check(manager.active_unit_id == uid and unit.grid_pos == before, "Player turn waits for input")
	manager.select_ability("not_a_known_ability")
	check(unit.mp == mp and not manager.active_unit_has_acted, "Unknown ability cannot consume turn")
	manager.select_command("move")
	check(manager.active_command == "move", "Move command accepted")
	manager.cancel_pending_action()
	check(not manager.active_unit_has_moved, "Cancel does not spend movement")
	await _check_terrain_presentation(manager)
	await _check_casting_and_frame(manager)
	await _check_shared_rigs(manager)
	await _check_melee_poses(manager)
	await _check_action_lifecycle(manager, unit)
	if "quickstep" in unit.unit_data.abilities:
		var hp_before := unit.hp
		manager.select_ability("quickstep")
		check(manager.is_resolving_action, "Casting locks player commands during anticipation")
		manager.select_command("wait")
		check(manager.active_unit_id == uid, "Wait cannot interrupt an in-flight action")
		await get_tree().create_timer(0.8).timeout
		check(not manager.is_resolving_action, "Casting releases command lock after recovery")
		await get_tree().create_timer(0.3).timeout
		check(unit.hp == hp_before, "Self buff does not attack the caster")
		check(manager.active_unit_has_acted and not manager.active_unit_has_moved, "Ability first leaves movement available")
		unit.tick_statuses()
		check(unit.hp == hp_before, "Beneficial magnitude is not damage over time")
		manager.select_command("move")
		var moves: Array = manager.tactical_grid.move_tiles
		check(not moves.is_empty(), "Movement remains available after acting")
		if not moves.is_empty():
			await manager._on_tile_clicked(moves.back())
			check(unit.grid_pos != before, "Act-then-move executes")
	# Synchronous authoritative spell results must not apply a second time later.
	var test_target := Unit.new()
	test_target.unit_data = unit.unit_data
	add_child(test_target)
	var target_hp := test_target.hp
	var spell_result: Dictionary = manager.combat_resolver.resolve_spell(unit, test_target, "fire", 1)
	check(test_target.hp == target_hp - int(spell_result.get("hp_damage", 0)), "Spell HP and returned result agree immediately")
	var resolved_hp := test_target.hp
	await get_tree().create_timer(0.3).timeout
	check(test_target.hp == resolved_hp, "Presentation cannot apply spell damage a second time")
	var heal_result: Dictionary = manager.combat_resolver.resolve_heal(unit, test_target, 9999)
	check(heal_result.healed == test_target.hp - resolved_hp, "Healing feedback reports actual restored HP")
	test_target.queue_free()
	# Exercise actual AI, damage, victory and reward routing with opt-in test automation.
	manager.auto_battle_enabled = true
	manager.battle_speed_multiplier = 8.0
	Engine.time_scale = 8.0
	manager._run_auto_player_turn(manager.active_unit_id)
	for i in range(3000):
		if manager.current_phase in [BattleManager.Phase.VICTORY, BattleManager.Phase.DEFEAT]:
			break
		await get_tree().create_timer(0.05).timeout
	check(manager.current_phase == BattleManager.Phase.VICTORY, "Real battle can be won")
	await get_tree().create_timer(0.1).timeout
	check(gs.get_jp("kael") > 77, "Victory awards spendable JP")
	check(gs.unit_registry.kael.get("current_job_id") == "warder", "Victory preserves selected job")
	check(gs.get_all_abilities("mira").size() > 0, "Victory preserves abilities")
	check(gs.run_jp_earned == int(gs.pending_rewards.get("jp", 0)), "Victory JP total counted once")
	var gold: int = gs.gold
	check(gs.load_save() and gs.gold == gold, "Victory survives reload")
	battle.queue_free()
	await get_tree().process_frame
	await _run_route_checks(gs, rm)
	await _run_practice_checks(gs, rm)
	print("Playable loop: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func _run_route_checks(gs: Node, rm: Node) -> void:
	rm.start_new_run(0, 42)
	for floor_number in [1, 2]:
		var choices: Array = gs.active_run.get_available_nodes()
		for choice: Dictionary in choices:
			if choice.get("type") == "battle":
				gs.active_run.select_node(choice.id)
				break
		var map := MapGenerator.new().generate_floor(gs.active_run.current_floor, gs.active_run.seed, 0)
		var deployment := DeploymentScreen.new()
		deployment.map_data = map
		add_child(deployment)
		check(deployment._validate().is_empty(), "Generated deployment is valid on floor %d" % floor_number)
		gs.active_run.run_deployment = deployment._deployment.duplicate(true)
		gs.active_run.set_meta("pending_deployment", deployment._deployment.duplicate(true))
		gs.save()
		deployment.queue_free()
		var scene: Node = load("res://scenes/Battle.tscn").instantiate()
		get_tree().root.add_child(scene)
		get_tree().current_scene = scene
		var bm: BattleManager = scene.battle_manager
		bm.auto_battle_enabled = true
		Engine.time_scale = 8.0
		if bm.current_phase == BattleManager.Phase.PLAYER_TURN:
			bm._run_auto_player_turn(bm.active_unit_id)
		for i in range(4000):
			if bm.current_phase in [BattleManager.Phase.VICTORY, BattleManager.Phase.DEFEAT]:
				break
			await get_tree().create_timer(0.05).timeout
		check(bm.current_phase == BattleManager.Phase.VICTORY, "Procedural floor %d completes" % floor_number)
		if bm.current_phase != BattleManager.Phase.VICTORY:
			return
		check(gs.active_run.current_floor == floor_number + 1, "Rewards commit route advancement before spoils")
		var earned_gold: int = gs.gold
		gs.active_run = null
		check(gs.load_save() and gs.active_run.current_floor == floor_number + 1, "Reload resumes after won encounter")
		check(gs.gold == earned_gold, "Reload preserves rewards without duplication")
		for item: Dictionary in gs.run_inventory:
			check(item.get("color") is Color, "Reload restores loot presentation types")
		scene.battle_ui.spoils_continue_requested.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		check(get_tree().current_scene is StageSelect, "Spoils Continue opens route selection")
		get_tree().current_scene.queue_free()
		await get_tree().process_frame
	var stage := StageSelect.new()
	add_child(stage)
	for choice: Dictionary in gs.active_run.get_available_nodes():
		if choice.get("type") == "boon_pick":
			stage._on_enter_node(choice)
			break
	check(stage._boon_overlay != null, "Boon route opens choice overlay")
	if stage._boon_overlay:
		var cards := stage._boon_overlay.find_children("*", "Button", true, false)
		check(not cards.is_empty(), "Boon choice contains actionable cards")
		if not cards.is_empty():
			cards[0].pressed.emit()
	check(gs.active_run.active_boons.size() == 1, "Selecting boon equips it")
	gs.active_run = null
	check(gs.load_save() and gs.active_run.active_boons.size() == 1 and gs.active_run.current_floor == 4, "Boon checkpoint restores choice and next floor")
	stage.queue_free()
	await get_tree().process_frame

func _check_action_lifecycle(manager: BattleManager, source: Unit) -> void:
	var lifecycle := preload("res://scripts/battle/ActionLifecycle.gd").new()
	var actor := Unit.new()
	actor.unit_data = source.unit_data
	add_child(actor)
	var target := Unit.new()
	target.unit_data = source.unit_data
	add_child(target)
	var ticket: int = lifecycle.begin(actor, target)
	check(ticket > 0, "Living action admitted")
	check(lifecycle.begin(actor, target) == 0, "Duplicate action rejected during anticipation")
	check(lifecycle.contact(ticket), "Action receives one contact permit")
	check(not lifecycle.contact(ticket), "Duplicate contact rejected")
	check(lifecycle.recover(ticket), "Contact advances to recovery")
	check(lifecycle.begin(actor, target) == 0, "New action rejected during recovery")
	lifecycle.finish(ticket)
	var fresh_ticket: int = lifecycle.begin(actor, target)
	lifecycle.finish(ticket)
	check(lifecycle.phase == "anticipation", "Stale completion cannot release newer action")
	lifecycle.cancel()
	check(not lifecycle.contact(fresh_ticket), "Cancelled action cannot commit")
	check(lifecycle.phase == "idle", "Cancellation releases lifecycle")
	get_tree().create_timer(0.05).timeout.connect(target.queue_free)
	var committed: bool = await manager._present_action(actor, Vector2i.ZERO, "cast", target)
	check(not committed, "Removed target aborts before contact")
	check(not manager.is_resolving_action, "Removed target releases input lock")
	get_tree().create_timer(0.05).timeout.connect(actor.queue_free)
	committed = await manager._present_action(actor, Vector2i.ZERO, "slash")
	check(not committed, "Deleted actor cannot leave a tween wait hanging")
	check(not manager.is_resolving_action, "Deleted actor releases input lock")
	var mp_before := source.mp
	var aborted_target := Unit.new()
	aborted_target.unit_data = source.unit_data
	add_child(aborted_target)
	get_tree().create_timer(0.05).timeout.connect(aborted_target.queue_free)
	var accepted: bool = await manager._execute_ability(source, aborted_target, AbilityDB.get_ability("fire"))
	check(not accepted and source.mp == mp_before, "Aborted spell does not spend MP or report success")
	get_tree().create_timer(0.05).timeout.connect(manager.action_lifecycle.cancel)
	committed = await manager._present_action(source, source.grid_pos, "cast", source)
	check(not committed and not manager.is_resolving_action, "Cancelled presentation cannot commit or retain lock")


func _run_practice_checks(gs: Node, rm: Node) -> void:
	var baseline: Dictionary = gs.serialize_state()
	var saved_seed: int = gs.active_run.seed
	var saved_floor: int = gs.active_run.current_floor
	var saved_flags: Array = gs.story_flags.duplicate()
	var saved_rm_active: bool = rm.is_run_active
	check(gs.begin_practice(0, 5678), "Practice starts from explicit checkpoint")
	gs.practice_session["rig3d"] = true
	check(not gs.begin_practice(), "Duplicate practice start rejected")
	check(gs.active_run == null and not rm.is_run_active, "Practice isolated from ordinary run")
	var starting_gold: int = gs.gold
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var formation := {}
	var initial_resources := {}
	for attempt in range(2):
		var battle: BattleScene = get_tree().current_scene
		check(is_instance_valid(battle.battle_manager.units["kael"]._rig3d) and is_instance_valid(battle.battle_manager.units["zane"]._rig3d), "Practice and retry instantiate both shared rigs")
		var bm: BattleManager = battle.battle_manager
		for step in range(300):
			if bm.current_phase == BattleManager.Phase.PLAYER_TURN: break
			await get_tree().create_timer(0.02).timeout
		for enemy: Unit in bm.units.values():
			if enemy.get_meta("archetype_id", "") == "void_cultist":
				check(is_instance_valid(enemy._rig3d) and enemy._rig3d.skin_id == "void_cultist", "Instanced enemy uses its archetype appearance")
		var panel = battle.comparison_panel
		check(is_instance_valid(panel), "Practice exposes comparison controls")
		await _check_terrain_3d(panel, bm)
		var kael: Unit = bm.units["kael"]
		var prior_hp := kael.hp
		var prior_grid := kael.grid_pos
		kael.set_facing("E")
		bm.is_resolving_action = true
		check(not panel.switch_mode(), "Comparison cannot interrupt resolving combat")
		bm.is_resolving_action = false
		for cycle in range(2):
			check(panel.switch_mode() and kael._rig3d == null and kael._sprite.visible, "Switch restores sprite and detaches viewport")
			check(panel.switch_mode() and is_instance_valid(kael._rig3d) and not kael._sprite.visible, "Switch rebuilds one active rig")
		check((kael._rig3d.model.global_basis * Vector3.BACK).dot(Vector3.RIGHT) > 0.999, "Mode switch retains imported Kael east facing")
		check(kael.hp == prior_hp and kael.grid_pos == prior_grid, "Comparison preserves combat resources and tile")
		panel.reset_samples()
		for sample in range(200): panel.record_interval(10.0)
		panel.record_interval(40.0)
		var timing: Dictionary = panel.timing_summary()
		check(timing.frames == 180 and timing.worst_ms == 40.0 and is_equal_approx(timing.mean_ms, 10.0 + 30.0/180), "Frame sample window is bounded and retains slow frames")
		panel.reset_samples()
		check(panel.timing_summary().is_empty(), "Mode timing samples can be reset")
		check(gs.practice_session.state == "playing", "Practice battle acknowledges transition")
		for uid: String in bm.units:
			var unit: Unit = bm.units[uid]
			if unit.team != "player": continue
			if attempt == 0:
				formation[uid] = unit.grid_pos
				initial_resources[uid] = [unit.hp, unit.mp, unit.temper, unit.ether]
			else:
				check(unit.grid_pos == formation[uid], "Retry restores formation for " + uid)
				check([unit.hp, unit.mp, unit.temper, unit.ether] == initial_resources[uid], "Retry restores resources for " + uid)
		# Exercise actual defeat signal and results scene, without changing normal loss rules.
		for unit: Unit in bm.units.values():
			if unit.team == "player": unit.receive_damage(99999, "pure")
		bm._set_phase(BattleManager.Phase.CHECK_OBJECTIVE)
		for i in range(100):
			if get_tree().current_scene is ResultsScreen: break
			await get_tree().create_timer(0.02).timeout
		check(get_tree().current_scene is ResultsScreen, "Practice defeat reaches results")
		check(gs.practice_session.state == "lost" and gs.can_retry_practice(), "Defeat offers valid retry")
		check(gs.story_flags == saved_flags, "Practice loss does not advance narrative")
		gs.gold += 999
		gs.save()
		var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(gs.SAVE_PATH))
		check(int(disk.gold) == int(baseline.gold) and int(disk.active_run.seed) == saved_seed, "Practice saves retain original progress")
		var results: ResultsScreen = get_tree().current_scene
		results._retry_practice()
		results._retry_practice()
		check(results._transitioning and gs.practice_session.state == "loading", "Repeated retry clicks claim one transition")
		check(not gs.retry_practice(), "State rejects duplicate retry")
		check(gs.gold == starting_gold, "Retry rolls back practice gains")
		await get_tree().process_frame
		await get_tree().process_frame
	var battle: BattleScene = get_tree().current_scene
	battle.battle_manager.auto_battle_enabled = true
	Engine.time_scale = 8.0
	if battle.battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN:
		battle.battle_manager._run_auto_player_turn(battle.battle_manager.active_unit_id)
	for i in range(4000):
		if get_tree().current_scene is ResultsScreen: break
		await get_tree().create_timer(0.05).timeout
	check(gs.practice_session.get("state") == "won", "Practice can be won after repeated retries")
	var won_gold: int = gs.gold
	check(won_gold == starting_gold + int(gs.pending_rewards.get("gold", 0)), "Practice victory grants session reward once")
	check(not gs.finish_practice(true, {"gold":999}) and gs.gold == won_gold, "Duplicate victory cannot grant rewards")
	check(not gs.choose_practice_job("missing_job"), "Invalid training choice rejected")
	var old_job: String = gs.unit_registry.kael.current_job_id
	var chosen_job := "scout" if old_job != "scout" else "arcanist"
	check(gs.choose_practice_job(chosen_job), "Victory permits one existing training path choice")
	check(gs.unit_registry.kael.current_job_id == chosen_job, "Training uses canonical job change")
	check(not gs.choose_practice_job("squire"), "Repeated training click rejected")
	gs.start_practice_encounter()
	gs.finish_practice(false)
	check(gs.retry_practice() and gs.unit_registry.kael.current_job_id == chosen_job, "Retry preserves chosen practice path")
	gs.start_practice_encounter()
	gs.finish_practice(true, {})
	check(not gs.choose_practice_job("squire"), "Second victory does not grant another training choice")
	var results: ResultsScreen = get_tree().current_scene
	results._leave_practice()
	results._leave_practice()
	check(gs.practice_session.is_empty(), "Return to Hearth exits practice once")
	check(gs.gold == int(baseline.gold) and gs.active_run.seed == saved_seed and gs.active_run.current_floor == saved_floor, "Exit restores saved gold, seed and route")
	check(gs.story_flags == saved_flags and rm.is_run_active == saved_rm_active, "Exit restores narrative and run manager")
	await get_tree().process_frame
	await get_tree().process_frame
	check(get_tree().current_scene.scene_file_path == "res://scenes/HubScene.tscn", "Return button reaches Hearth")
	get_tree().current_scene.queue_free()
	await get_tree().process_frame
	check(gs.begin_practice(), "Second practice starts without stale state")
	gs.start_practice_encounter()
	gs.finish_practice(false)
	gs.practice_session.erase("checkpoint")
	check(not gs.can_retry_practice() and not gs.retry_practice(), "Missing checkpoint rejects retry")
	check(gs.leave_practice(), "Missing checkpoint still permits baseline restoration")
	check(gs.begin_practice(), "Practice can start before reload test")
	gs.gold += 999
	gs.save()
	check(gs.load_save() and gs.practice_session.is_empty() and gs.gold == int(baseline.gold) and gs.active_run.seed == saved_seed, "Reload exits practice into canonical save")
	# Ordinary run losses retain their original end-run behavior.
	rm.is_run_active = true
	rm.end_run(false)
	check(gs.active_run == null and not rm.is_run_active, "Ordinary defeat still ends the run")

func _check_melee_poses(manager: BattleManager) -> void:
	var kael: Unit = manager.units["kael"]
	var sprite := kael.visual as Sprite2D
	var idle_texture := sprite.texture
	var idle_position := sprite.position
	var idle_scale := sprite.scale
	var grid_before := kael.grid_pos
	check(not kael.set_melee_pose("missing"), "Unknown pose safely retains idle")
	check(sprite.texture == idle_texture, "Missing pose preserves existing art")
	for i in range(3):
		manager._present_action(kael, kael.grid_pos + Vector2i(1, 0), "slash")
		check(kael.melee_pose == "anticipation", "Real action selects anticipation")
		check(sprite.position == Vector2.ZERO, "Anticipation keeps foot root grounded")
		await get_tree().create_timer(0.24).timeout
		check(manager.action_lifecycle.phase == "contact" and kael.melee_pose == "contact", "Contact pose follows lifecycle permission")
		check(kael.grid_pos == grid_before, "Pose does not move authoritative tile")
		await manager._recover_action()
		check(kael.melee_pose == "idle" and sprite.texture == idle_texture, "Recovery restores original idle texture")
		check(sprite.position == idle_position and sprite.scale == idle_scale and sprite.offset == Vector2.ZERO, "Recovery restores exact sprite transform")
		check(not manager.is_resolving_action, "Repeated pose action releases input")
	manager._present_action(kael, kael.grid_pos, "slash")
	manager.action_lifecycle.cancel()
	check(kael.melee_pose == "idle", "Cancellation immediately restores pose")
	await get_tree().create_timer(0.24).timeout
	check(kael.melee_pose == "idle" and not manager.is_resolving_action, "Late anticipation cannot resurrect cancelled pose")
	var doomed := Unit.new()
	doomed.unit_data = kael.unit_data
	add_child(doomed)
	get_tree().create_timer(0.05).timeout.connect(doomed.queue_free)
	var accepted: bool = await manager._present_action(kael, kael.grid_pos, "slash", doomed)
	check(not accepted and kael.melee_pose == "idle", "Deleted melee target restores idle without contact")

func _check_shared_rigs(manager: BattleManager) -> void:
	var actors: Array[Unit] = []
	# All facades obey the same gameplay phases; only the two legacy appearances
	# still share procedural joint motion. Kael owns a distinct imported skeleton.
	for id in ["kael", "zane", "void_cultist"]:
		var actor := Unit.new()
		actor.unit_data = manager.units["kael" if id == "kael" else "zane"].unit_data
		actor.set_meta("archetype_id", id)
		add_child(actor)
		actor.enable_3d_prototype()
		actors.append(actor)
		if id == "kael":
			check(actor._rig3d.skeleton.get_bone_count() == 16, "Imported Kael retains tested skeleton")
			check(actor._rig3d.viewport.size == Vector2i(160,160), "Kael uses controlled pixel source")
		else:
			check(actor._rig3d.rig.get_bone_count() == 11, "Legacy rig retains humanoid joints")
			check(actor._rig3d.viewport.size == Vector2i(192,192), "Legacy viewport retains bounded render size")
		check(not actor._sprite.visible, "Prototype preserves but hides original sprite")
		var base_pos: Vector2 = actor._rig3d.position
		var committed: bool = await manager._present_action(actor, actor.grid_pos + Vector2i(1,0), "slash")
		check(committed and actor._rig3d.state == "contact", "Rig slash reaches authoritative contact")
		await manager._recover_action()
		check(actor._rig3d.state == "idle" and actor._rig3d.position == base_pos, "Rig recovery restores grounded idle")
		actor.set_walk_presentation(true)
		check(actor._rig3d.state == "walk", "Movement uses shared walk state")
		actor.set_walk_presentation(false)
		manager._present_action(actor, actor.grid_pos, "slash")
		manager.action_lifecycle.cancel()
		await get_tree().create_timer(0.24).timeout
		check(actor._rig3d.state == "idle" and not manager.is_resolving_action, "Cancelled rig action returns idle")
		actor.animate_hit()
		check(actor._rig3d.state == "hit", "Damage reaction drives shared rig")
		await get_tree().create_timer(0.3).timeout
		check(actor._rig3d.state == "idle", "Hit reaction recovers")
	for actor in actors:
		actor._rig3d.play("anticipation")
		actor._rig3d._process(0.16)
	check(actors[1]._rig3d.rig.get_bone_pose_rotation(3).is_equal_approx(actors[2]._rig3d.rig.get_bone_pose_rotation(3)), "Legacy appearances retain shared sword motion")
	check(not actors[1]._rig3d.rig.get_bone_pose_rotation(3).is_equal_approx(Quaternion.IDENTITY), "Legacy anticipation rotates shoulder bone")
	check(actors[0]._rig3d.player.current_animation == "slash" and actors[0]._rig3d.player.current_animation_position > 0.0, "Imported Kael samples authored windup")
	check(actors[1]._rig3d.skin_id != actors[2]._rig3d.skin_id, "Legacy rig retains distinct appearance definitions")
	for actor in actors:
		actor.animate_death()
		check(actor._rig3d.state == "defeat", "Death drives shared defeat animation")
	await get_tree().create_timer(0.9).timeout
	check(not is_instance_valid(actors[0]) and not is_instance_valid(actors[1]) and not is_instance_valid(actors[2]), "Defeat cleans imported and legacy viewports")

func _check_casting_and_frame(manager: BattleManager) -> void:
	var layout = preload("res://scripts/ui/BattleHudLayout.gd")
	var bounds := Rect2(-200, -50, 900, 650)
	for size in [Vector2(1366,768), Vector2(1920,1080)]:
		var fit: Dictionary = layout.camera_fit(bounds, size)
		var area: Rect2 = layout.battlefield_rect(size)
		var screen_center: Vector2 = (bounds.get_center() - fit.position) * fit.zoom + size * 0.5
		check(screen_center.is_equal_approx(area.get_center()), "Camera centers board within HUD-free area")
		check(bounds.size.x * fit.zoom <= area.size.x + 0.1 and bounds.size.y * fit.zoom <= area.size.y + 0.1, "Camera fits board at desktop sizes")
	var actor := Unit.new()
	actor.unit_data = manager.units["zane"].unit_data
	add_child(actor)
	actor.enable_3d_prototype()
	var target := Unit.new()
	target.unit_data = manager.units["kael"].unit_data
	add_child(target)
	check("void_pulse" in actor.unit_data.abilities, "Casting example is available in Zane loadout")
	var before_mp := actor.mp
	var accepted: bool = await manager._execute_ability(actor, target, AbilityDB.get_ability("void_pulse"))
	check(accepted and actor._rig3d.state == "cast_release", "Existing Void Pulse uses shared casting release")
	check(actor.mp == before_mp - 12, "Rig spell spends MP once")
	var hp_after := target.hp
	await manager._recover_action()
	check(actor._rig3d.state == "idle" and target.hp == hp_after, "Cast recovery restores idle without repeated damage")
	actor.set_cast_pose("release")
	var origin: Vector2 = actor.cast_origin_world()
	actor.position += Vector2(30,20)
	check(actor.cast_origin_world().is_equal_approx(origin + Vector2(30,20)), "Hand projection follows battlefield translation")
	actor.reset_melee_pose()
	before_mp = actor.mp
	get_tree().create_timer(0.25).timeout.connect(manager.action_lifecycle.cancel)
	accepted = await manager._execute_ability(actor, target, AbilityDB.get_ability("void_pulse"))
	check(not accepted and actor.mp == before_mp and actor._rig3d.state == "idle", "Cancelled rig spell restores idle and preserves MP")
	actor.queue_free()
	target.queue_free()

func _check_terrain_presentation(manager: BattleManager) -> void:
	var grid: TacticalGrid = manager.tactical_grid
	var snapshot := grid.tiles.duplicate(true)
	check(grid.exposed_face_depth(Vector2i(7, 0), Vector2i(7, 1)) == grid.height_step, "Cliff joins lower neighboring surface")
	check(grid.exposed_face_depth(Vector2i(7, 0), Vector2i(7, -1)) == grid.tile_thickness + 2 * grid.height_step, "Board edge extends to base datum")
	check(grid.exposed_face_depth(Vector2i(7, 0), Vector2i(8, 0)) == 0, "Equal-height neighbors have no exposed cliff")
	grid._environment_theme_id = "default"
	var grass: Texture2D = grid._texture_for_terrain("grass")
	check(grass != null and grass.get_width() == 96 and grass.get_height() == 64, "Default maps reuse generated floor family")
	grid.redraw_base_tiles()
	await get_tree().process_frame
	var top = grid._tile_top_polys[Vector2i(0, 0)]
	check(top is Sprite2D and top.position == grid._grid_to_local(Vector2i(0, 0)) + Vector2(0, 8), "Generated tile top aligns with logical diamond")
	var square := ImageTexture.create_from_image(Image.create(32, 32, false, Image.FORMAT_RGBA8))
	grid._add_art_tile_top(Vector2i(0, 0), Vector2.ZERO, square)
	check(grid._tile_top_polys[Vector2i(0, 0)] is Polygon2D, "Square fallback is diamond clipped")
	grid._environment_theme_id = "forgotten-field"
	grid.redraw_base_tiles()
	await get_tree().process_frame
	check(grid.tiles == snapshot, "Terrain presentation preserves terrain rules and heights")
	for pos: Vector2i in [Vector2i(0, 0), Vector2i(7, 0), Vector2i(9, 7)]:
		check(grid._local_to_grid(grid._grid_to_local(pos)) == pos, "Tile picking remains aligned %s" % pos)

func _check_terrain_3d(panel: Node, manager: BattleManager) -> void:
	var grid: TacticalGrid = manager.tactical_grid
	var view = grid.terrain_view
	check(is_instance_valid(view) and view.visible, "Practice/retry instantiate mesh terrain")
	if not is_instance_valid(view): return
	await get_tree().process_frame
	var state := grid.tiles.duplicate(true)
	for pos: Vector2i in grid.tiles:
		check(view.projected_tile_center(pos).distance_to(grid._grid_to_local(pos)) < 0.25, "3D projection matches logical tile %s" % pos)
	var raised: MeshInstance3D = view._visual_root.get_node("Tile_7_0")
	var top_world := raised.to_global(Vector3(0, raised.mesh.get_aabb().end.y, 0))
	var top_screen: Vector2 = view._texture_sprite.position + view._camera.unproject_position(top_world) - Vector2(view.render_size) * 0.5
	check(top_screen.distance_to(grid._grid_to_local(Vector2i(7, 0))) < 0.25, "Actual raised mesh surface matches logical height")
	var original: Vector2 = view.projected_tile_center(Vector2i(7, 0))
	var rig = manager.units["kael"]._rig3d
	var hand: Vector2 = rig.hand_world_position()
	for cycle in range(2):
		check(panel.switch_quality(), "Quality switches during idle turn")
		check(view._viewport.size == Vector2i(3072, 2048), "High terrain doubles sampling")
		check(rig.viewport.size == Vector2i(160, 160), "High quality preserves Kael pixel source grid")
		check(view.projected_tile_center(Vector2i(7, 0)).distance_to(original) < 0.25, "Quality preserves terrain projection")
		check(rig.hand_world_position().distance_to(hand) < 0.25, "Quality preserves hand attachment")
		check(panel.switch_quality() and view._viewport.size == view.render_size, "Standard restores bounded sampling")
	var revision: int = view.revision
	grid.ignite_tile(Vector2i(0, 0))
	check(view.revision == revision + 1 and grid.tiles[Vector2i(0, 0)].terrain == "burning", "Mutation rebuilds terrain from authoritative state")
	check(view._load_mesh("res://assets/3d/ashvale/missing.obj") == null, "Missing mesh safely returns null")
	grid.tiles[Vector2i(0, 0)].terrain = "unknown_test"
	grid.redraw_base_tiles()
	check(not view.visible and grid._tile_top_polys[Vector2i(0, 0)].visible, "Unsupported terrain restores whole 2D fallback")
	grid.tiles = state
	grid.redraw_base_tiles()
	check(view.visible and not grid._tile_top_polys[Vector2i(0, 0)].visible, "Valid terrain restores mesh presentation")
	manager.is_resolving_action = true
	check(not panel.switch_terrain(), "Terrain switch cannot interrupt combat")
	manager.is_resolving_action = false
	for cycle in range(2):
		var prior = grid.terrain_view
		check(panel.switch_terrain() and not is_instance_valid(prior) and grid.terrain_view == null, "Disable frees terrain viewport immediately")
		check(panel.switch_terrain() and is_instance_valid(grid.terrain_view), "Reenable builds one terrain viewport")
	check(grid.tiles == state, "Mode changes preserve logical tiles")
