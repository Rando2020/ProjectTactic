extends "res://tests/modular/test_presentation.gd"
const Glyph = preload("res://scripts/presentation/SupportSpellGlyph.gd")
var capture_dir := ""
var captured: Dictionary = {}
var action_label := ""
var rendered_checks := 0

func _process(_delta: float) -> void:
	for reference in controllers:
		var owner = reference.get_ref()
		if not is_instance_valid(owner): continue
		for fx in owner._fx:
			if not is_instance_valid(fx) or not fx is Glyph or not fx.is_visible_in_tree(): continue
			var key: String = action_label + "-" + fx.stage
			if fx.progress < 0.3 or captured.has(key): continue
			captured[key] = true
			check(fx.position.is_equal_approx(owner._grid_point(owner._stage_ground if fx == owner._stage_sprite else owner.context.destination)), "support glyph follows semantic ground anchor")
			if not capture_dir.is_empty(): _capture(key)

func _capture(key: String) -> void:
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	check(frame != null and not frame.is_empty(), "rendered support frame exists")
	if frame != null and not frame.is_empty():
		check(frame.save_png(capture_dir.path_join(key+".png")) == OK, "save support screenshot")
		rendered_checks += 1

func run() -> void:
	Engine.max_fps = 30
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
	VFX.child_entered_tree.connect(observe)
	for reduced in [false,true]:
		for mode in ["haste-self", "haste-ally", "defend-self"]:
			controllers.clear(); phases.clear(); cues.clear(); captured.clear()
			action_label = mode + ("-reduced" if reduced else "-normal")
			var battle = await make_demo()
			GameState.practice_session["reduced_zane_motion"] = reduced
			var manager: BattleManager = battle.battle_manager
			var caster: Unit = manager.units.zane
			var target: Unit = manager.units.kael if mode == "haste-ally" else caster
			target.grid_pos = Vector2i(2,2) if mode == "haste-ally" else caster.grid_pos
			var ability: String = mode.get_slice("-",0)
			check(await manager._execute_ability(caster,target,AbilityDB.get_ability(ability)), "actual " + action_label)
			var owner = controllers.back().get_ref()
			check(owner._support, "support classification")
			check(owner._tails[0].sprite.reduced_motion == reduced, "glyph respects reduced motion setting")
			check(owner._reactions.is_empty(), "support never hurts actor")
			check(not get_tree().paused, "support never hitpauses")
			check(target.hp == 2000, "support never damages")
			check(owner._tails.size()==1 and owner._tails[0].tile==target.grid_pos, "completion anchored on actual recipient")
			var labels: Array[String] = []
			for fx in owner._fx:
				if is_instance_valid(fx) and fx is Label: labels.append(fx.text)
			check(labels.has(("HASTE\n4 turns" if mode == "haste-self" else "HASTE\n3 turns") if ability == "haste" else "GUARD\nUntil next turn"), "truthful support label: " + str(labels))
			check(phases.has("casting") and phases.has("formation") and phases.has("action") and phases.has("support"), "complete support sequence")
			await manager._recover_action()
			for frame in 40: await get_tree().process_frame
			check(not is_instance_valid(owner), "support effects retire")
			battle.queue_free()
			await get_tree().process_frame
	for phase in ["casting", "formation", "action"]:
		var battle = await make_demo()
		var manager: BattleManager = battle.battle_manager
		var caster: Unit = manager.units.zane
		var target: Unit = manager.units.kael
		var callback := func(node: Node):
			if node.has_signal("phase_presented"):
				node.phase_presented.connect(func(current: String):
					if current == phase: manager.action_lifecycle.cancel())
		VFX.child_entered_tree.connect(callback)
		check(not await manager._execute_ability(caster,target,AbilityDB.get_ability("haste")), "cancel haste " + phase)
		check(not target.has_status("haste") and caster.mp == 200, "canceled Haste spends/applies nothing")
		VFX.child_entered_tree.disconnect(callback)
		await manager._recover_action()
		battle.queue_free()
		await get_tree().process_frame
	if not capture_dir.is_empty(): check(rendered_checks > 0, "render capture must produce frames")
	print("Support runtime: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
