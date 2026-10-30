extends Node

const ENTRY := "Practice: Zane vs Storm Imp"
const BANNER := "Zane vs Storm Imp: move one tile closer for a sword attack, or try Fire if equipped. Fire costs 12 MP and targets a three-tile fan."
var checks := 0
var failures: Array[String] = []
var baseline: Dictionary
var checkpoint: Dictionary
var canonical: PackedByteArray
var settings: Dictionary
var original_scene: Node

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _ready() -> void:
	call_deferred("run")

func button_named(root: Node, text: String) -> Button:
	for candidate in root.find_children("*", "Button", true, false):
		if candidate.text == text: return candidate
	return null

func settings_snapshot() -> Dictionary:
	var snapshot := {}
	for path in ["user://settings.cfg", "user://ui_settings.cfg"]:
		var exists := FileAccess.file_exists(path)
		snapshot[path] = {"exists": exists, "bytes": FileAccess.get_file_as_bytes(path) if exists else PackedByteArray()}
	return snapshot

func check_disk(label: String) -> void:
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == canonical, label + " preserves canonical save bytes")
	check(settings_snapshot() == settings, label + " preserves serialized settings bytes")

func run() -> void:
	# This contract is run only with isolated XDG data/config/cache directories.
	GameState.delete_save()
	GameState.practice_session.clear()
	# This profile has visited the Hearth; its normal first-visit story write is not practice.
	GameState.story_flags.append(RecurrenceStory.GUIDE_MET_FLAG)
	original_scene = get_tree().current_scene
	get_tree().current_scene = null
	Engine.time_scale = 4.0
	var start := preload("res://scenes/StartScreen.tscn").instantiate()
	add_child(start)
	var entry := button_named(start, ENTRY)
	check(entry != null, "distinct one-on-one entry exists on the actual title screen")
	check(button_named(start, "Practice Battle / Retry Enabled") != null and button_named(start, "Practice: Zane showcase") != null, "both original full-party entries remain discoverable")
	if entry != null:
		await check_title_geometry(start, entry)
		baseline = GameState.serialize_state().duplicate(true)
		GameState.save()
		canonical = FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
		settings = settings_snapshot()
		entry.pressed.emit()
		entry.pressed.emit()
		await wait_scene("res://scenes/Battle.tscn")
		check(GameState.practice_session.get("mode") == "zane_duel" and bool(GameState.practice_session.get("rig3d",false)), "real title callback admits one session-only duel with the Zane rig")
		check(not GameState.practice_session.get("zane_showcase",false), "duel remains distinct from full-party showcase mode")
		checkpoint = GameState.practice_session.get("checkpoint", {}).duplicate(true)
		check(GameState.practice_session.get("baseline", {}) == baseline, "repeated title click cannot overwrite original baseline")
		check_disk("title admission")
	start.music_player.stop()
	start.free()
	if get_tree().current_scene is BattleScene:
		await check_fresh_fight()
		if get_tree().current_scene is ResultsScreen:
			await replay_from_results("won")
			await check_sword_and_loss()
		if get_tree().current_scene is ResultsScreen:
			await replay_from_results("lost")
			await defeat_fixture()
			await leave_from_results()
		if GameState.practice_session.is_empty():
			await check_saved_profile_and_reload()
	await free_current_scene()
	get_tree().current_scene = original_scene
	Engine.time_scale = 1.0
	# Accelerated harness time must not strand a still-playing real-time defeat sting.
	for voice in get_node("/root/AudioSettings").get_children():
		if voice is AudioStreamPlayer:
			voice.stop()
			voice.stream = null
			voice.queue_free()
	await get_tree().create_timer(0.25).timeout
	print("Zane duel practice: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func check_title_geometry(start: Node, entry: Button) -> void:
	var prefs := preload("res://scripts/ui/UISettings.gd").shared()
	var old_mode: int = prefs.mode
	for viewport_size in [Vector2i(1328,861),Vector2i(1920,1080),Vector2i(3840,2160)]:
		get_viewport().content_scale_size = Vector2i.ZERO
		get_viewport().size = viewport_size
		for mode in range(4):
			prefs.set_mode(mode, false)
			start._apply_ui_size()
			entry.grab_focus()
			await get_tree().process_frame
			await get_tree().process_frame
			check(Rect2(Vector2.ZERO,Vector2(viewport_size)).encloses(entry.get_global_rect()), "focused duel entry fits %s UI mode %d" % [viewport_size,mode])
			var text_width := entry.get_theme_font("font").get_string_size(entry.text,HORIZONTAL_ALIGNMENT_LEFT,-1,entry.get_theme_font_size("font_size")).x
			check(text_width + entry.get_theme_stylebox("normal").get_minimum_size().x <= entry.size.x, "duel title text does not clip at %s UI mode %d" % [viewport_size,mode])
	prefs.set_mode(old_mode,false)

func wait_scene(path: String) -> void:
	for i in 300:
		if is_instance_valid(get_tree().current_scene) and get_tree().current_scene.scene_file_path == path: return
		await get_tree().create_timer(0.02).timeout
	check(false, "scene transition reaches " + path)

func wait_player(manager: BattleManager) -> void:
	for i in 600:
		if not is_instance_valid(manager): return
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN and not manager.is_resolving_action: return
		await get_tree().create_timer(0.025).timeout
	check(false, "real initiative reaches an idle human turn")

func check_roster(battle: BattleScene) -> void:
	var manager := battle.battle_manager
	check(manager.units.size() == 2 and manager.units.has("zane") and manager.units.has("Enemy_1"), "duel contains exactly one Zane and one enemy, not discarded party actors")
	check(battle.tactical_grid.find_children("*", "Unit", true, false).size() == 2, "scene tree also contains exactly two Unit actors")
	if not manager.units.has("zane") or not manager.units.has("Enemy_1"): return
	check(manager.units.Enemy_1.unit_data.id == "storm_imp" and manager.units.Enemy_1.team == "enemy", "single runtime enemy is the original Storm Imp archetype")
	check(battle.map_index == 0 and manager.units.zane.grid_pos == Vector2i(4,5) and manager.units.Enemy_1.grid_pos == Vector2i(6,5), "duel uses Ashvale with legal close spawns")
	check(manager.units.Enemy_1.unit_data.base_stats.hp == 90 and manager.units.Enemy_1.unit_data.base_stats.speed == 8 and manager.units.Enemy_1.unit_data.abilities == ["thunderstrike","void_pulse"], "Storm Imp stats and abilities are unmodified")
	check(not manager.auto_battle_enabled, "duel starts with ordinary human input, not automatic combat")

func observe(manager: BattleManager) -> Dictionary:
	var events := {"enemy_turns":0,"enemy_resolutions":0,"player_resolutions":0,"mp_after":-1}
	manager.turn_started.connect(func(_id: String, team: String) -> void:
		if team == "enemy": events.enemy_turns += 1)
	manager.combat_resolver.combat_resolved.connect(func(_result: Dictionary) -> void:
		if manager.active_unit_id == "zane":
			events.player_resolutions += 1
			events.mp_after = manager.units.zane.mp
		else: events.enemy_resolutions += 1)
	return events

func check_fresh_fight() -> void:
	var battle := get_tree().current_scene as BattleScene
	check_roster(battle)
	var manager := battle.battle_manager
	await wait_player(manager)
	check(manager.active_unit_id == "zane" and manager.units.zane.get_effective_speed() == manager.units.Enemy_1.get_effective_speed(), "fresh profile naturally gives Zane the first tied-speed turn without an initiative override")
	var zane: Unit = manager.units.zane
	var enemy: Unit = manager.units.Enemy_1
	check(zane.unit_data.base_stats.hp == 320 and zane.unit_data.base_stats.mp == 90 and zane.unit_data.base_stats.physical == 42 and zane.unit_data.base_stats.magic == 48, "Zane retains original base combat stats")
	check(zane.has_zane_impact_presentation() and "fire" in zane.unit_data.abilities, "fresh duel retains real rig and normal equipped Fire")
	var banner := battle.comparison_panel.find_child("ZaneDuelBanner",true,false) as Label
	check(banner != null and banner.text == BANNER and banner.is_visible_in_tree(), "duel-specific basics guidance remains visible")
	var before := [zane.grid_pos,zane.mp,zane.hp]
	manager.select_command("move")
	check(Vector2i(5,5) in battle.tactical_grid.move_tiles, "one-step sword approach is legally highlighted")
	manager.cancel_pending_action()
	manager.select_ability("fire")
	check(enemy.grid_pos in battle.tactical_grid.ability_tiles, "Fire is legal immediately from the original spawn")
	manager.cancel_pending_action()
	check(before == [zane.grid_pos,zane.mp,zane.hp] and not manager.active_unit_has_acted and not manager.active_unit_has_moved, "cancelled move and Fire selection spend no action/resources")
	manager.select_command("attack")
	await manager._on_tile_clicked(enemy.grid_pos)
	check(not manager.active_unit_has_acted and enemy.hp == 90, "sword cannot bypass original adjacent range")
	var fire := AbilityDB.get_ability("fire")
	check(fire.mp_cost == 12 and AbilityDB.get_range(fire).y == 3 and fire.aoe_type == "fan", "original Fire cost, range, and fan definition remain unchanged")
	var events := observe(manager)
	manager.select_ability("fire")
	manager._on_tile_clicked(enemy.grid_pos)
	check(manager.is_resolving_action, "actual Fire enters the normal action-resolution input guard")
	var command := manager.active_command
	manager.select_command("wait")
	manager.select_command("move")
	manager.select_ability("fire")
	manager.cancel_pending_action()
	check(manager.is_resolving_action and manager.active_unit_id == "zane" and manager.active_command == command, "in-flight wait/move/recast/cancel cannot interrupt Fire or change turn")
	for i in 600:
		if not is_instance_valid(manager) or not manager.is_resolving_action: break
		await get_tree().create_timer(0.025).timeout
	check(events.player_resolutions == 1 and events.mp_after == int(before[1]) - 12, "real one-target fan resolves once and spends exactly 12 MP")
	check_disk("Fire execution")
	await play_to_results(true)
	check(GameState.practice_session.get("state") == "won", "unmodified real combat can win the duel")

func play_to_results(win: bool) -> void:
	if get_tree().current_scene is BattleScene:
		var manager: BattleManager = get_tree().current_scene.battle_manager
		if win:
			manager.auto_battle_enabled = true
			if manager.current_phase == BattleManager.Phase.PLAYER_TURN and not manager.is_resolving_action:
				manager._run_auto_player_turn(manager.active_unit_id)
		for i in 3000:
			if get_tree().current_scene is ResultsScreen: return
			if not win and is_instance_valid(manager) and manager.current_phase == BattleManager.Phase.PLAYER_TURN and not manager.is_resolving_action:
				manager.select_command("wait")
			await get_tree().create_timer(0.05).timeout
	check(get_tree().current_scene is ResultsScreen, "real battle reaches results within bounded wait")

func replay_from_results(expected_state: String) -> void:
	var results := get_tree().current_scene as ResultsScreen
	check(GameState.practice_session.get("state") == expected_state, "results retain authoritative " + expected_state + " outcome")
	var replay := button_named(results,"Replay Fight")
	check(replay != null and not replay.disabled, "Replay Fight is enabled after " + expected_state)
	check(button_named(results,"Return to Hearth") != null, "duel results retain an exit")
	await check_results_geometry(results)
	var unwanted := false
	for label in results.find_children("*","Label",true,false):
		unwanted = unwanted or "KAEL" in label.text or "Practice rewards:" in label.text
	check(not unwanted, "duel results omit unrelated Kael training and reward UI")
	check(GameState.pending_rewards.is_empty() and GameState.gold == int(baseline.gold) and GameState.serialize_state().unit_jp == baseline.unit_jp and GameState.serialize_state().unit_job_jp == baseline.unit_job_jp, "duel outcome grants no gold or party JP progression")
	check(not bool(GameState.call("choose_practice_job","scout")) and GameState.practice_session.checkpoint == checkpoint, "backend refuses duel training without rewriting original checkpoint")
	check(not GameState.finish_practice(true,{"gold":999,"jp":999}), "duplicate terminal callback cannot award rewards")
	GameState.practice_session["reduced_zane_motion"] = true
	GameState.practice_session["high_quality"] = true
	GameState.practice_session["terrain3d"] = false
	if replay == null: return
	replay.pressed.emit()
	replay.pressed.emit()
	check(results._transitioning and GameState.practice_session.get("state") == "loading" and not GameState.retry_practice(), "double replay claims exactly one transition")
	await wait_scene("res://scenes/Battle.tscn")
	if not get_tree().current_scene is BattleScene: return
	var battle := get_tree().current_scene as BattleScene
	check_roster(battle)
	check(GameState.practice_session.checkpoint == checkpoint and GameState.practice_session.baseline == baseline, "replay never recaptures a post-result baseline/checkpoint")
	check(bool(GameState.practice_session.get("reduced_zane_motion")) and bool(GameState.practice_session.get("high_quality")) and not bool(GameState.practice_session.get("terrain3d")) and bool(GameState.practice_session.get("rig3d")), "replay preserves session-only presentation flags")
	var zane: Unit = battle.battle_manager.units.zane
	check(zane.hp == 320 and zane.mp == 90 and zane.temper == 80 and zane.ether == 110, "replay restores normal original starting HP/MP/armor")
	check_disk(expected_state + " replay")

func check_sword_and_loss() -> void:
	if not get_tree().current_scene is BattleScene: return
	var battle := get_tree().current_scene as BattleScene
	var manager := battle.battle_manager
	await wait_player(manager)
	var events := observe(manager)
	var zane: Unit = manager.units.zane
	var enemy: Unit = manager.units.Enemy_1
	manager.select_command("move")
	await manager._on_tile_clicked(Vector2i(5,5))
	check(zane.grid_pos == Vector2i(5,5) and manager.active_unit_has_moved and not manager.active_unit_has_acted, "one legal step consumes movement but leaves sword action available")
	manager.select_command("attack")
	check(enemy.grid_pos in battle.tactical_grid.attack_tiles, "one-step approach places the original sword in range")
	await manager._on_tile_clicked(enemy.grid_pos)
	check(events.player_resolutions == 1 and events.mp_after == 90, "real sword attack resolves once without a spell MP charge")
	await wait_player(manager)
	check(events.enemy_turns > 0 and events.enemy_resolutions > 0, "real enemy responds to the legal sword turn")
	await defeat_fixture()
	check(GameState.practice_session.get("state") == "lost", "authoritative defeat fixture reaches the duel loss outcome")
	check(events.enemy_turns > 0 and events.enemy_resolutions > 0, "real enemy initiative and combat resolver execute, not a scripted dummy")
	check_disk("authoritative loss")

func defeat_fixture() -> void:
	# Native lifecycle fixture, NOT a natural loss/AI claim: leave combat rules and
	# random counter rolls untouched while exercising the genuine death/objective route.
	if not get_tree().current_scene is BattleScene: return
	var manager: BattleManager = get_tree().current_scene.battle_manager
	await wait_player(manager)
	manager.units.zane.receive_damage(99999,"pure")
	manager._set_phase(BattleManager.Phase.CHECK_OBJECTIVE)
	await wait_scene("res://scenes/ResultsScreen.tscn")

func check_results_geometry(results: ResultsScreen) -> void:
	var prefs := preload("res://scripts/ui/UISettings.gd").shared()
	var old_mode: int = prefs.mode
	for viewport_size in [Vector2i(1328,861),Vector2i(1920,1080),Vector2i(3840,2160)]:
		get_viewport().content_scale_size = Vector2i.ZERO
		get_viewport().size = viewport_size
		for mode in range(4):
			prefs.set_mode(mode,false)
			results._apply_ui_size()
			for caption in ["Replay Fight","Return to Hearth"]:
				var button := button_named(results,caption)
				if button == null: continue
				button.grab_focus()
				await get_tree().process_frame
				await get_tree().process_frame
				check(Rect2(Vector2.ZERO,Vector2(viewport_size)).encloses(button.get_global_rect()), caption + " fits %s UI mode %d" % [viewport_size,mode])
	prefs.set_mode(old_mode,false)

func leave_from_results() -> void:
	if not get_tree().current_scene is ResultsScreen: return
	var results := get_tree().current_scene as ResultsScreen
	var leave := button_named(results,"Return to Hearth")
	check(leave != null, "results expose the real leave button")
	if leave == null: return
	leave.pressed.emit()
	leave.pressed.emit()
	check(GameState.practice_session.is_empty() and not GameState.leave_practice(), "repeated exit restores only once and clears session flags")
	check(GameState.serialize_state() == baseline, "exit restores exact canonical progression and narrative")
	check_disk("sandbox exit before Hearth")
	await wait_scene("res://scenes/HubScene.tscn")
	check_disk("real results exit")

func check_saved_profile_and_reload() -> void:
	await free_current_scene()
	var rm: Node = get_node("/root/RunManager")
	rm.start_new_run(2,271828)
	GameState.selected_map_index = 1
	GameState.gold = 123
	GameState.story_flags.append("duel_contract_story")
	GameState.unit_registry.zane["job_jp"] = {"arcanist":320}
	GameState.unit_registry.zane["jp"] = 91
	GameState.unit_registry.zane["equipped_abilities"] = ["thunderstrike"]
	GameState.unit_registry.zane["current_hp"] = 117
	GameState.unit_registry.zane["current_mp"] = 7
	GameState.unit_registry.zane["current_temper"] = 13
	GameState.unit_registry.zane["current_ether"] = 17
	GameState.pending_rewards = {"gold":17}
	GameState.pending_loot = [{"id":"duel_contract_loot"}]
	GameState.pending_boon_offers = [{"id":"duel_contract_boon"}]
	rm.run_aether = 23
	rm.rng.randi()
	var rng_before: int = rm.rng.state
	var runtime := {"selected_map":GameState.selected_map_index,"rewards":GameState.pending_rewards.duplicate(true),"loot":GameState.pending_loot.duplicate(true),"offers":GameState.pending_boon_offers.duplicate(true),"rm_stage":rm.current_stage,"rm_aether":rm.run_aether}
	baseline = GameState.serialize_state().duplicate(true)
	GameState.save()
	canonical = FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	check(bool(GameState.call("begin_zane_duel_practice")), "new duel can admit an existing saved run without an override loadout")
	check(not bool(GameState.call("begin_zane_duel_practice")) and not GameState.begin_practice(), "nested duel/full-party admissions both reject")
	check(GameState.active_run == null and not rm.is_run_active, "duel detaches active run/bonuses using original sandbox")
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
	await wait_scene("res://scenes/Battle.tscn")
	var battle := get_tree().current_scene as BattleScene
	if battle == null: return
	check_roster(battle)
	var zane: Unit = battle.battle_manager.units.zane
	var bonuses := JobTreeData.compute_stat_bonuses({"arcanist":320})
	check(zane.unit_data.abilities == ["thunderstrike"] and "fire" not in zane.unit_data.abilities, "saved explicit non-Fire loadout is respected without free Fire: " + str(zane.unit_data.abilities))
	check(zane.unit_data.base_stats.hp == 320 + int(bonuses.max_hp) and zane.unit_data.base_stats.magic == 48 + int(bonuses.magic) and zane.unit_data.base_stats.speed == maxi(1,8 + int(bonuses.speed)), "duel uses ordinary saved job stat bonuses rather than a custom preset")
	check(GameState.unit_registry.zane.equipped_abilities == ["thunderstrike"] and GameState.unit_registry.zane.jp == 91, "admission preserves raw saved loadout and earned JP")
	await free_current_scene()
	rm.rng.randi()
	check(GameState.finish_practice(true,{"gold":999,"jp":999}) and GameState.can_retry_practice(), "saved-profile victory permits original-checkpoint replay")
	check(not GameState.choose_practice_job("squire"), "saved-profile duel also rejects backend training")
	check(GameState.retry_practice() and GameState.unit_registry.zane.equipped_abilities == ["thunderstrike"] and GameState.unit_registry.zane.jp == 91, "saved-profile replay does not recapture post-victory gains or equip Fire")
	check(GameState.leave_practice() and GameState.serialize_state() == baseline, "exit restores saved run including original in-run resources")
	check(GameState.selected_map_index == int(runtime.selected_map) and GameState.pending_rewards == runtime.rewards and GameState.pending_loot == runtime.loot and GameState.pending_boon_offers == runtime.offers, "exit restores original pending rewards/loot/boons and map selection")
	check(rm.is_run_active and rm.current_stage == int(runtime.rm_stage) and rm.run_aether == int(runtime.rm_aether) and rm.rng.state == rng_before, "exit restores original RunManager runtime and exact RNG stream")
	check_disk("saved-profile exit")
	check(bool(GameState.call("begin_zane_duel_practice")), "fresh duel admits again before reload")
	GameState.gold += 999
	GameState.save()
	check_disk("in-practice save")
	var loaded := GameState.load_save()
	# JSON's numeric representation is normalized on load; compare canonical serialization.
	check(loaded and GameState.practice_session.is_empty() and JSON.parse_string(JSON.stringify(GameState.serialize_state())) == JSON.parse_string(canonical.get_string_from_utf8()), "reload exits duel into canonical saved progression/resources without session fields")
	check_disk("reload")

func free_current_scene() -> void:
	var scene := get_tree().current_scene
	get_tree().current_scene = null
	if is_instance_valid(scene): scene.queue_free()
	await get_tree().process_frame
