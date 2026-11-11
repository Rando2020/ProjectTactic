extends "res://tests/blooming_skills/HeroSkillsTest.gd"
## Real courtyard actors and lifecycle; no replacement animation or combat model.
var captures := 0

func run() -> void:
	Engine.max_fps = 60
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
	VFX.child_entered_tree.connect(observe)
	GameState._init_defaults()
	await boot()
	for compact in [true, false]:
		check(battle.set_compact_skins(compact), "switch skin before action")
		for id in ["zane", "kael"]:
			fixture(id)
			var actor: Unit = manager.units[id]
			var sprite: Sprite2D = actor._sprite
			var rest := sprite.transform
			var texture := sprite.texture
			var anchor := rest.affine_inverse() * Vector2.ZERO
			actor.face_action(actor.grid_pos + Vector2i(1, 0))
			check(actor.set_cast_pose("anticipation"), id + " accepts sprite cast anticipation")
			await get_tree().create_timer(0.22).timeout
			check(not sprite.transform.is_equal_approx(rest), id + " visible anticipation moves existing sprite")
			check((sprite.transform * anchor).is_equal_approx(Vector2.ZERO), id + " anticipation keeps feet planted")
			check(sprite.texture == texture, id + " anticipation preserves painted identity")
			var prepared := sprite.transform
			check(actor.set_cast_pose("release"), id + " accepts sprite cast release")
			await get_tree().create_timer(0.18).timeout
			check(not sprite.transform.is_equal_approx(prepared), id + " release differs from preparation")
			check((sprite.transform * anchor).is_equal_approx(Vector2.ZERO), id + " release keeps feet planted")
			actor.recover_melee_pose()
			await get_tree().create_timer(0.24).timeout
			check(sprite.transform.is_equal_approx(rest), id + " recovery restores original transform")
			actor.reset_melee_pose()
			check(sprite.transform.is_equal_approx(rest) and sprite.texture == texture, id + " idle is exact original art")
			actor.set_cast_pose("anticipation")
			await get_tree().create_timer(0.04).timeout
			actor.reset_melee_pose()
			await get_tree().create_timer(0.28).timeout
			check(sprite.transform.is_equal_approx(rest), id + " canceled tween cannot move idle later")
			GameState.practice_session["reduced_zane_motion"] = true
			actor.set_cast_pose("anticipation")
			actor.set_cast_pose("release")
			await get_tree().create_timer(0.22).timeout
			check(sprite.transform.is_equal_approx(rest), id + " reduced motion keeps body still")
			actor.reset_melee_pose()
			GameState.practice_session["reduced_zane_motion"] = false
	# Removing the actor hook or lifecycle reset must fail these real-menu casts.
	check(battle.set_compact_skins(true), "restore default skins")
	for ability in ["fire", "haste", "thunderstrike", "void_pulse", "defend"]:
		await real_cast(ability)
	for phase in ["casting", "formation", "action"]:
		await canceled_cast(phase, false)
	await canceled_cast("formation", true)
	await direction_cases()
	await cleanup()
	print("Caster motion: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func real_cast(ability: String) -> void:
	fixture("kael" if ability == "defend" else "zane")
	var actor: Unit = manager.units[manager.active_unit_id]
	var sprite: Sprite2D = actor._sprite
	var rest := sprite.transform
	var origin := actor.position
	var tile := actor.grid_pos
	var target: Unit = actor if ability == "defend" else (manager.units.kael if ability == "haste" else manager.units.Enemy_2)
	if ability == "defend":
		open_ability_menu(ability)
		for button in battle.battle_ui._ability_list.get_children():
			if button is Button and str(button.get_meta("ability_id", "")) == ability: button.pressed.emit(); break
	else: stage(ability, target)
	check(battle.battle_ui._selection.has_review(), ability + " uses real review")
	await capture_motion(ability + "-idle")
	battle.battle_ui._selection.confirm_review()
	await get_tree().create_timer(0.24).timeout
	check(not sprite.transform.is_equal_approx(rest), ability + " animates actual caster during windup")
	check(actor.position == origin and actor.grid_pos == tile, ability + " never moves logical actor")
	var anticipation := sprite.transform
	phases.clear()
	await capture_motion(ability + "-anticipation")
	for frame in 180:
		if phases.has("release" if ability == "fire" else "formation"): break
		await get_tree().process_frame
	await get_tree().create_timer(0.16).timeout
	check(not sprite.transform.is_equal_approx(anticipation), ability + " real release changes body posture")
	await capture_motion(ability + "-release")
	await settle()
	check(sprite.transform.is_equal_approx(rest), ability + " real lifecycle restores idle")
	check(actor.mp == 200 - int(AbilityDB.get_ability(ability).mp_cost), ability + " retains one MP payment")

func canceled_cast(phase: String, defeat: bool) -> void:
	fixture("zane")
	var actor: Unit = manager.units.zane
	var target: Unit = manager.units.kael
	var rest: Transform2D = actor._sprite.transform
	var callback := func(node: Node):
		if node.has_signal("phase_presented"):
			node.phase_presented.connect(func(current: String):
				if current != phase: return
				if defeat: actor.hp = 0
				else: manager.action_lifecycle.cancel())
	VFX.child_entered_tree.connect(callback)
	check(not await manager._execute_ability(actor, target, AbilityDB.get_ability("haste")), "interrupted cast does not contact: " + phase)
	VFX.child_entered_tree.disconnect(callback)
	await get_tree().create_timer(0.3).timeout
	check(actor._sprite.transform.is_equal_approx(rest), "interrupted real cast restores body: " + phase)
	check(actor.mp == 200 and not target.has_status("haste"), "interrupted cast spends/applies nothing: " + phase)
	await manager._recover_action()
	actor.hp = 2000
	# A canceled owner's late timer must not overwrite a fresh preparation.
	actor.set_cast_pose("anticipation")
	await get_tree().create_timer(0.24).timeout
	check(not actor._sprite.transform.is_equal_approx(rest), "new cast survives prior cancellation: " + phase)
	actor.reset_melee_pose()

func direction_cases() -> void:
	fixture("zane")
	var actor: Unit = manager.units.zane
	for quarter in 4:
		actor.set_view_quarter(quarter)
		for offset in [Vector2i(1, 0), Vector2i(-1, 0)]:
			var rest: Transform2D = actor._sprite.transform
			actor.face_action(actor.grid_pos + offset)
			actor.set_cast_pose("release")
			await get_tree().create_timer(0.16).timeout
			var head := rest.affine_inverse() * Vector2(0, -75)
			var displacement: Vector2 = actor._sprite.transform * head - Vector2(0, -75)
			# E/W projected through four quarter turns: +,-,-,+ for E.
			var expected: int = (1 if quarter in [0, 3] else -1) * offset.x
			check(signf(displacement.x) == expected, "release leans toward recipient in view " + str(quarter))
			actor.reset_melee_pose()
	actor.set_view_quarter(0)

func capture_motion(label: String) -> void:
	if capture_dir.is_empty(): return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label + ".png")) == OK, "capture " + label)
	captures += 1
