extends "res://tests/blooming_skills/HeroSkillsTest.gd"
## Real courtyard menu, review and manager commits. No replacement combat rules.
var combat_labels: Array[Dictionary] = []
var protection_logs: Array[String] = []
var protection_auras: Array[Dictionary] = []
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
	get_tree().node_added.connect(observe_label)
	GameState._init_defaults()
	GameState.save()
	var ownership := skill_ownership()
	var saved := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	await boot()
	check("cover_ally" in manager.units.kael.unit_data.abilities, "Kael offers battle-local Cover")
	check("iron_wall" in manager.units.kael.unit_data.abilities, "Kael offers battle-local Iron Wall")
	await cover_menu_case()
	await iron_wall_menu_case()
	await interruption_cases()
	await locked_menu_case()
	await weapon_protection_cases()
	await wait_commit_case()
	check(skill_ownership() == ownership, "protection practice never changes owned or equipped skills")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == saved, "protection practice leaves saved bytes unchanged")
	await cleanup()
	await boot()
	check(not manager.units.kael.has_status("iron_wall") and not manager.units.kael.has_status("covering"), "new courtyard encounter clears protection state")
	check("cover_ally" in manager.units.kael.unit_data.abilities and "iron_wall" in manager.units.kael.unit_data.abilities, "new encounter restores only local practice options")
	check(skill_ownership() == ownership and FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == saved, "restarting protection practice leaves ownership and save bytes untouched")
	await cleanup()
	finish()

func finish() -> void:
	print("Protection practice: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func lock_actor() -> void:
	var status := StatusEffect.new()
	status.status_id = "iron_wall"
	status.duration = 3
	manager.units.kael.apply_status(status)

func locked_menu_case() -> void:
	fixture("kael")
	open_ability_menu("defend")
	lock_actor()
	battle.battle_ui._selection.select_skill("defend")
	check(not battle.battle_ui._selection.has_review(), "an actor locked after opening skills cannot stage empty self review")
	battle.battle_ui._selection.refresh()
	check(battle.battle_ui._attack_btn.disabled and battle.battle_ui._ability_btn.disabled and battle.battle_ui._magic_btn.disabled, "Iron Wall disables Attack Magic and Skills even before a manager refresh")
	check(not battle.battle_ui._ability_panel.visible, "Iron Wall dismisses a stale skills menu")
	check(not battle.battle_ui._move_btn.disabled and not battle.battle_ui._wait_btn.disabled, "Iron Wall keeps Move and Wait available")

func observe_label(node: Node) -> void:
	if node is Label and node.text.begins_with("COVER:"):
		combat_labels.append({"text":node.text, "world_anchor":node.get_global_transform() * Vector2(30,54), "depth":canvas_depth(node)})
	if node is ColorRect and node.get_parent() == VFX and is_instance_valid(manager):
		protection_auras.append({"world_anchor":node.get_global_transform() * (node.size * 0.5), "depth":canvas_depth(node), "feedback_owner":manager._presentation_feedback_owner()})

func fixture(actor_id: String) -> void:
	for unit: Unit in manager.units.values():
		unit.remove_status("covering")
	super.fixture(actor_id)
	combat_labels.clear()
	protection_auras.clear()
	protection_logs.clear()

func boot() -> void:
	await super.boot()
	manager.log_message.connect(func(value: String): protection_logs.append(value))

func press_skill(id: String) -> void:
	open_ability_menu(id)
	for button in battle.battle_ui._ability_list.get_children():
		if button is Button and not button.is_queued_for_deletion() and button.get_meta("ability_id", "") == id:
			check(not button.disabled, id + " has an enabled real skill row")
			button.pressed.emit()
			return
	check(false, id + " exists in the real Skills menu")

func cover_menu_case() -> void:
	fixture("kael")
	var guard: Unit = manager.units.kael
	var ally: Unit = manager.units.zane
	var enemy: Unit = manager.units.Enemy_1
	var ui = battle.battle_ui
	open_ability_menu("cover_ally")
	await capture("protection-skills-menu")
	stage("cover_ally", guard)
	check(not ui._selection.has_review(), "Cover cannot review self")
	stage("cover_ally", enemy)
	check(not ui._selection.has_review(), "Cover cannot review an enemy")
	ally.grid_pos = Vector2i(2,8)
	stage("cover_ally", ally)
	check(not ui._selection.has_review(), "unmastered Cover cannot review an ally two tiles away")
	ally.grid_pos = Vector2i(3,8)
	stage("cover_ally", ally)
	check(ui._selection.has_review() and ui._preview_panel.visible, "Cover stages real ally review and visible forecast")
	check(ui._preview_note_label.text.contains("until your next turn") and ui._preview_note_label.text.contains("Direct hits only"), "Cover review explains lifetime and direct-hit boundary")
	await capture("cover-ally-review")
	ui._selection.go_back()
	check(guard.mp == 200 and not guard.has_status("covering") and not manager.active_unit_has_acted, "cancelled Cover does not apply protection or spend action")
	stage("cover_ally", ally)
	ui._selection.confirm_review()
	ui._selection.confirm_review()
	await capture_protection_contact("cover-feedback", "covering")
	await settle()
	check(guard.mp == 200 and guard.has_status("covering") and ally.get_damage_recipient(enemy) == guard, "confirmed Cover establishes one zero-MP protector link")
	check(manager.active_unit_has_acted and not manager.active_unit_has_moved, "Cover spends action and preserves move")
	check(protection_logs.filter(func(value): return value.contains("covers Zane")).size() == 1, "duplicate Cover confirm commits exactly once")
	check(combat_labels.size() == 1 and combat_labels[0].text == "COVER: Kael", "generic Cover feedback identifies Kael as protector")
	if not combat_labels.is_empty():
		check(combat_labels[0].world_anchor.distance_to(ally.global_position) < 0.01, "Cover label is anchored to the protected ally")
		check(combat_labels[0].depth > canvas_depth(manager.tactical_grid.terrain_view) and combat_labels[0].depth > canvas_depth(ally._sprite), "Cover text renders above actual courtyard terrain and actor")
	check_protection_aura("Cover", guard)
	await capture("cover-applied")
	var spell := AbilityDB.get_ability("void_pulse")
	var forecast := ForecastCalculator.spell(enemy, ally, spell)
	check(forecast.target_name == "Kael" and str(forecast.note).contains("Zane"), "direct hostile forecast identifies the actual recipient and protected ally")
	var hp := guard.hp
	var execution: Dictionary = await manager._execute_ability_with_result(enemy, ally, spell)
	check(execution.executed and guard.hp < hp and ally.hp == 2000, "real hostile spell damages the covering hero rather than the aimed ally")
	var record: Dictionary = manager._presentation_record(ally, execution.outcome)
	check(record.target_id == "kael" and record.grid_pos == guard.grid_pos, "intercepted hit presentation uses the actual recipient")
	await manager._recover_action()
	guard.end_turn()
	ally.begin_turn()
	check(ally.get_damage_recipient(enemy) == guard, "ally turn does not expire Cover")
	guard.begin_turn()
	check(not guard.has_status("covering") and ally.get_damage_recipient(enemy) == ally, "protector next begin turn expires Cover")

func iron_wall_menu_case() -> void:
	fixture("kael")
	var guard: Unit = manager.units.kael
	var ui = battle.battle_ui
	guard.mp = 9
	open_ability_menu("iron_wall")
	var unaffordable: Button
	for button in ui._ability_list.get_children():
		if button is Button and button.get_meta("ability_id", "") == "iron_wall": unaffordable = button
	check(is_instance_valid(unaffordable) and unaffordable.disabled, "Iron Wall remains visible but disabled below 10 MP")
	if is_instance_valid(unaffordable): unaffordable.pressed.emit()
	check(not ui._selection.has_review() and guard.mp == 9, "unaffordable Iron Wall cannot stage or spend MP")
	ui._selection.go_back()
	guard.mp = 200
	press_skill("iron_wall")
	check(ui._selection.has_review() and ui._preview_panel.visible and guard.mp == 200, "Iron Wall button reviews self without spending MP")
	check(ui._preview_note_label.text.contains("40%") and ui._preview_note_label.text.contains("two future turns") and ui._preview_note_label.text.contains("Move/Wait allowed"), "Iron Wall review explains reduction duration and retained commands")
	await capture("iron-wall-review")
	ui._selection.go_back()
	await get_tree().process_frame
	check(guard.mp == 200 and not guard.has_status("iron_wall") and ui._ability_panel.visible, "cancel Iron Wall preserves resources and returns to skills")
	press_skill("iron_wall")
	ui._selection.confirm_review()
	ui._selection.confirm_review()
	await capture_protection_contact("iron-wall-feedback", "iron_wall")
	await settle()
	check(guard.mp == 190 and guard.has_status("iron_wall"), "double-confirm Iron Wall spends exactly 10 MP and applies stance")
	check_protection_aura("Iron Wall", guard)
	check(protection_logs.filter(func(value): return value.contains("casts Iron Wall")).size() == 1, "Iron Wall commits once")
	ui._selection.refresh()
	check(ui._attack_btn.disabled and ui._ability_btn.disabled and ui._magic_btn.disabled, "confirmed Iron Wall visibly blocks all action commands")
	check(not ui._move_btn.disabled and not ui._wait_btn.disabled, "confirmed Iron Wall retains Move and Wait")
	await capture("iron-wall-active")
	# End-turn lifecycle is the real Unit contract; the fixture chooses the next
	# owner for deterministic UI coverage without substituting initiative math.
	guard.end_turn()
	for turn in [1,2]:
		guard.begin_turn()
		manager.active_unit_has_acted = false
		manager.active_unit_has_moved = false
		manager._emit_action_state()
		ui._selection.select_unit("kael")
		check(guard.has_status("iron_wall") and ui._attack_btn.disabled and ui._ability_btn.disabled, "Iron Wall action lock persists into future owner turn " + str(turn))
		ui._on_ability()
		check(not ui._ability_panel.visible and not ui._selection.has_review(), "future locked turn cannot reopen skills")
		ui._on_move()
		check(manager.active_command == "move" and not manager.tactical_grid.move_tiles.is_empty(), "Iron Wall future turn admits actual move targeting")
		if turn == 1:
			var destination := guard.grid_pos
			for cell: Vector2i in manager.tactical_grid.move_tiles:
				if cell != guard.grid_pos and manager._unit_at_pos(cell) == null:
					destination = cell
					break
			ui._selection.set_cursor(destination)
			ui._selection.activate_cursor()
			check(destination != guard.grid_pos and ui._selection.has_review(), "Iron Wall stages real movement review")
			ui._selection.confirm_review()
			ui._selection.confirm_review()
			await settle()
			check(guard.grid_pos == destination and manager.active_unit_has_moved and guard.mp == 190, "Iron Wall permits confirmed movement without another MP cost")
		else:
			ui._selection.go_back()
		ui._on_wait()
		check(ui._selection._waiting_facing and ui._confirm_btn.visible, "Iron Wall admits real Wait facing review")
		ui._selection.go_back()
		guard.end_turn()
	guard.begin_turn()
	manager.active_unit_has_acted = false
	manager._emit_action_state()
	ui._selection.select_unit("kael")
	check(not guard.has_status("iron_wall") and not ui._attack_btn.disabled and not ui._ability_btn.disabled, "third future owner turn restores normal action menu")
	press_skill("iron_wall")
	check(ui._selection.has_review(), "expired Iron Wall may be reviewed again")
	ui._selection.go_back()

func interruption_cases() -> void:
	for id in ["cover_ally", "iron_wall"]:
		fixture("kael")
		var guard: Unit = manager.units.kael
		var ally: Unit = manager.units.zane
		if id == "iron_wall": press_skill(id)
		else: stage(id, ally)
		battle.battle_ui._selection.confirm_review()
		manager.action_lifecycle.cancel()
		await settle()
		check(guard.mp == 200 and not guard.has_status("covering") and not guard.has_status("iron_wall") and not manager.active_unit_has_acted, id + " interrupted anticipation spends no resources or action")
		check(not battle.battle_ui._selection.has_review(), id + " interruption retires stale review")
	fixture("kael")
	stage("cover_ally", manager.units.zane)
	manager.units.zane.grid_pos = Vector2i(1,8)
	battle.battle_ui._selection.confirm_review()
	await settle()
	check(not manager.units.kael.has_status("covering") and not manager.active_unit_has_acted, "moving Cover target after review invalidates confirmation without spending action")
	fixture("kael")
	press_skill("iron_wall")
	lock_actor()
	battle.battle_ui._selection.refresh()
	check(not battle.battle_ui._selection.has_review() and not battle.battle_ui._confirm_btn.visible, "new action lock retires previously staged self review")
	battle.battle_ui._selection.confirm_review()
	check(manager.units.kael.mp == 200, "confirm after lock cannot spend MP")

func wait_commit_case() -> void:
	fixture("kael")
	press_skill("iron_wall")
	battle.battle_ui._selection.confirm_review()
	await settle()
	var ended: Array[String] = []
	manager.turn_ended.connect(func(id: String): ended.append(id))
	battle.battle_ui._on_wait()
	battle.battle_ui._selection.choose_facing("E")
	battle.battle_ui._selection.confirm_review()
	battle.battle_ui._selection.confirm_review()
	check(ended == ["kael"] and manager.units.kael.facing == "E", "Iron Wall real Wait double-confirm ends exactly one turn with chosen facing")
	check(manager.units.kael.has_status("iron_wall") and manager.units.kael.mp == 190, "confirmed Wait keeps stance for its future turns without another cost")

func capture_protection_contact(label: String, status_id: String) -> void:
	if capture_dir.is_empty(): return
	for frame in 600:
		if manager.units.kael.has_status(status_id): break
		await get_tree().create_timer(0.01).timeout
	check(manager.units.kael.has_status(status_id), label + " reaches real contact")
	# Capture the live expanding pulse, well inside its 0.45-second lifetime.
	await get_tree().create_timer(0.10).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label + ".png")) == OK, "capture " + label)

func weapon_fixture(weapon: String, guard_inside: bool = false) -> Dictionary:
	var actor_id := "zane" if weapon == "spear" else "kael"
	fixture(actor_id)
	var actor: Unit = manager.units[actor_id]
	var aim: Unit = manager.units.Enemy_1
	var guard: Unit = manager.units.Enemy_2
	var ally: Unit = manager.units.kael if actor_id == "zane" else manager.units.zane
	actor.grid_pos = Vector2i(4,8)
	ally.grid_pos = Vector2i(3,9)
	aim.grid_pos = Vector2i(4,7)
	guard.grid_pos = Vector2i(5,7) if weapon != "greatsword" else Vector2i(4,6)
	if guard_inside:
		guard.grid_pos = Vector2i(4,6) if weapon == "spear" else Vector2i(5,7)
	aim.hp = 1500
	aim.unit_data.base_stats.physical_resistance = 20
	guard.unit_data.base_stats.physical_resistance = 0
	guard.unit_data.base_stats.attack_range_max = 3
	guard.job_mastery = {"counter_chance_bonus":0.75}
	aim.job_mastery = {"counter_chance_bonus":-0.25}
	# Every actual recipient is a guaranteed back hit. A global seed cannot
	# stabilize a 93%/88% secondary hit across rendered presentation timing.
	for target: Unit in [aim, guard]:
		target.set_facing(CombatFormula.FACING_OPPOSITE[CombatFormula.attack_direction(actor.grid_pos, target.grid_pos)])
	for unit: Unit in manager.units.values():
		manager.tactical_grid.tiles[unit.grid_pos].height = 0
		unit.position = manager.tactical_grid._grid_to_local(unit.grid_pos)
	check(guard.cover_ally(aim), weapon + " fixture has a real Cover link")
	check(manager.equip_test_weapon(actor_id, weapon), weapon + " fixture equips through real manager")
	battle.battle_ui._selection.select_unit(actor_id)
	battle.battle_ui._on_attack()
	return {"actor":actor, "aim":aim, "guard":guard}

func weapon_protection_cases() -> void:
	var clashes: Array[Dictionary] = []
	var listen := func(value: Dictionary): clashes.append(value)
	manager.action_clash_started.connect(listen)
	for weapon in ["spear", "greatsword", "sword"]:
		var scene := weapon_fixture(weapon)
		var actor: Unit = scene.actor
		var aim: Unit = scene.aim
		var guard: Unit = scene.guard
		var covered: bool = weapon == "sword"
		var recipient: Unit = guard if covered else aim
		var before_aim := aim.hp
		var before_guard := guard.hp
		var forecast: Dictionary = manager._attack_preview_for_tile(aim.grid_pos)
		check(forecast.target_id == recipient.unit_id and forecast.target_name == recipient.display_name, weapon + " forecast header names actual recipient")
		check(forecast.target_portrait == manager._portrait_path(recipient), weapon + " forecast portrait matches recipient")
		check(forecast.affected_targets.size() == 1 and forecast.affected_targets[0].unit_id == recipient.unit_id and forecast.affected_targets[0].hp_before == recipient.hp, weapon + " affected row identity and HP belong to the same recipient")
		check(str(forecast.weapon_summary).contains(recipient.display_name) and (covered or not str(forecast.weapon_summary).contains(guard.display_name)), weapon + " target summary names actual recipients only")
		check(str(forecast.note).contains("Counter possible: " + recipient.display_name), weapon + " counter warning names actual recipient")
		if covered:
			check(str(forecast.note).contains("Cover:") and str(forecast.note).contains(aim.display_name), "sword forecast preserves Cover and protected ally explanation")
		else:
			check(not str(forecast.get("formula_explain", "")).contains("Cover:"), weapon + " area forecast excludes Cover mitigation recipient")
		battle.battle_ui._selection.set_cursor(aim.grid_pos)
		battle.battle_ui._selection.activate_cursor()
		check(battle.battle_ui._selection.has_review(), weapon + " real UI stages protected target review")
		clashes.clear()
		seed(102)
		battle.battle_ui._selection.confirm_review()
		battle.battle_ui._selection.confirm_review()
		await settle()
		var hits := outcomes.filter(func(value): return value.has("feedback_owner"))
		check(hits.size() == 1, weapon + " repeated confirmation resolves one primary hit")
		check((aim.hp == before_aim and guard.hp < before_guard) if covered else (aim.hp < before_aim and guard.hp == before_guard), weapon + " damages only its permitted recipient")
		var reactions := clashes.filter(func(value): return value.get("action", "") == "Counter")
		check((reactions.size() == 1 and reactions[0].actor_id == guard.unit_id) if covered else reactions.is_empty(), weapon + " counter dispatch belongs only to actual damaged recipient")
		check(protection_logs.any(func(value): return value.contains(weapon.capitalize() + " → " + recipient.display_name + ":")), weapon + " combat log names actual damaged recipient")
		if not hits.is_empty():
			var record: Dictionary = manager._presentation_record(aim, hits[0])
			check(record.target_id == recipient.unit_id and record.grid_pos == recipient.grid_pos, weapon + " contact presentation anchors to actual damaged recipient")
		check(manager.active_unit_has_acted and not manager.active_unit_has_moved and actor.mp == 200, weapon + " spends one action without MP or movement")
	for weapon in ["spear", "greatsword"]:
		var scene := weapon_fixture(weapon, true)
		scene.guard.job_mastery = {"counter_chance_bonus":-0.25}
		var forecast: Dictionary = manager._attack_preview_for_tile(scene.aim.grid_pos)
		check(forecast.affected_targets.map(func(value): return value.unit_id) == ["Enemy_1", "Enemy_2"], weapon + " forecast lists both footprint recipients once despite their Cover link")
		check(forecast.affected_targets.all(func(value): return value.hit_pct == 100), weapon + " recipient fixture guarantees both physical hits through real facing rules")
		print("%s area hit setup: facing=%s/%s; hit chances=%s" % [weapon, scene.aim.facing, scene.guard.facing, forecast.affected_targets.map(func(value): return value.hit_pct)])
		seed(102)
		await manager._commit_weapon_attack(scene.aim.grid_pos)
		var hits := outcomes.filter(func(value): return value.has("feedback_owner"))
		check(hits.size() == 2 and scene.aim.hp < 1500 and scene.guard.hp < 2000, weapon + " hits both in-footprint enemies once without redirecting an extra hit")
		check(hits.all(func(value): return not value.has("protected_id")), weapon + " area outcomes never claim Cover interception")
	var automatic := weapon_fixture("sword")
	automatic.aim.hp = 1
	automatic.aim.set_facing("S")
	automatic.guard.grid_pos = Vector2i(5,8)
	automatic.guard.position = manager.tactical_grid._grid_to_local(automatic.guard.grid_pos)
	automatic.guard.job_mastery = {"cover_range":2, "counter_chance_bonus":-0.25}
	automatic.guard.set_facing("E")
	seed(102)
	check(await manager._auto_try_attack(automatic.actor), "courtyard auto attack executes its real weapon action")
	check(automatic.aim.hp == 1 and automatic.guard.hp < 2000, "auto sword damages the healthy protector rather than the one-HP covered aim")
	var automatic_hits := outcomes.filter(func(value): return value.has("feedback_owner"))
	check(automatic_hits.size() == 1 and not automatic_hits[0].has("protected_id"), "auto sword prefers stronger direct hit instead of false KO bonus on covered aim")
	var locked := weapon_fixture("sword")
	lock_actor()
	check(manager._attack_preview_for_tile(locked.aim.grid_pos).is_empty(), "locked courtyard weapon actor has no stale attack forecast")
	await manager._commit_weapon_attack(locked.aim.grid_pos)
	check(outcomes.is_empty() and locked.aim.hp == 1500 and locked.guard.hp == 2000 and not manager.active_unit_has_acted, "Iron Wall blocks direct courtyard weapon commit without spending action")
	check(not await manager._auto_try_attack(locked.actor), "Iron Wall blocks courtyard auto-attack admission")
	battle.battle_ui._selection.refresh()
	check(battle.battle_ui._attack_btn.disabled and not battle.battle_ui._move_btn.disabled and not battle.battle_ui._wait_btn.disabled, "weapon protection fix retains Iron Wall command gating")
	manager.action_clash_started.disconnect(listen)

func canvas_depth(item: CanvasItem) -> int:
	var depth := 0
	var node: Node = item
	while is_instance_valid(node):
		if node is CanvasItem:
			depth += node.z_index
			if not node.z_as_relative: break
		elif node is CanvasLayer: break
		node = node.get_parent()
	return depth

func check_protection_aura(skill: String, actor: Unit) -> void:
	check(protection_auras.size() == 3, skill + " actually dispatches the three generic aura shapes")
	var terrain_depth := canvas_depth(manager.tactical_grid.terrain_view)
	var actor_depth := canvas_depth(actor._sprite)
	check(protection_auras.all(func(sample): return sample.depth > terrain_depth and sample.depth > actor_depth), skill + " aura renders above actual terrain and actor")
	check(protection_auras.all(func(sample): return sample.world_anchor.distance_to(actor.global_position) < 0.01), skill + " aura world anchor matches the real actor transform")
	print("%s aura dispatch: %d shapes; feedback owners=%s; effect depth=%s; terrain=%d; actor=%d" % [skill, protection_auras.size(), protection_auras.map(func(sample): return str(sample.feedback_owner)), protection_auras.map(func(sample): return sample.depth), terrain_depth, actor_depth])
