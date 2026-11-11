extends "res://tests/blooming_skills/HeroSkillsTest.gd"
## Exercise the visible courtyard menus, admission, audio and actual presentation.
var emitted_pcm: Dictionary = {}
var effect_roles: Dictionary = {}
var active_test := ""
var screenshot_stages: Dictionary = {}
var pcm_by_ability: Dictionary = {}
var feedback_report: Dictionary = {}

func observe(node: Node) -> void:
	super.observe(node)
	if node.has_signal("phase_presented"):
		node.phase_presented.connect(func(phase: String):
			record_effects(node)
			if phase in ["casting", "charge", "support", "impact"]:
				capture_action(active_test + "-" + phase)
		)
	if node.has_signal("cue_started"):
		node.cue_started.connect(func(id: String):
			for voice in node._voices:
				if is_instance_valid(voice) and voice.playing and voice.stream is AudioStreamWAV:
					emitted_pcm[id] = voice.stream.data.hex_encode().sha256_text()
		)

func capture_action(label: String) -> void:
	if capture_dir.is_empty() or screenshot_stages.has(label): return
	screenshot_stages[label] = true
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join(label + ".png")) == OK, "capture " + label)

func stage(id: String, target: Unit) -> void:
	open_ability_menu(id)
	var selected := false
	for button in battle.battle_ui._ability_list.get_children():
		if button is Button and not button.is_queued_for_deletion() and str(button.get_meta("ability_id", "")) == id:
			button.pressed.emit()
			selected = true
			break
	check(selected, id + " selected from real category/school")
	if AbilityDB.get_ability(id).get("target_type", "enemy") != "self":
		battle.battle_ui._selection.set_cursor(target.grid_pos)
		battle.battle_ui._selection.activate_cursor()

func record_effects(owner: Node) -> void:
	for effect in owner._fx:
		if is_instance_valid(effect) and effect.is_visible_in_tree():
			effect_roles[str(effect.get_meta("zane_effect_role", ""))] = true

func _process(_delta: float) -> void:
	for reference in controllers:
		var owner = reference.get_ref()
		if not is_instance_valid(owner): continue
		record_effects(owner)

func run() -> void:
	Engine.max_fps = 60
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
	VFX.child_entered_tree.connect(observe)
	GameState._init_defaults()
	await boot()
	for id in ["haste", "defend", "thunderstrike", "void_pulse", "mighty_strike", "delay_strike", "heavy_slash"]:
		fixture("zane" if id in ["haste", "thunderstrike", "void_pulse"] else "kael")
		active_test = id
		var caster: Unit = manager.units[manager.active_unit_id]
		var target: Unit = manager.units.kael if id == "haste" else (caster if id == "defend" else (manager.units.Enemy_2 if id == "thunderstrike" else manager.units.Enemy_1))
		cues.clear(); phases.clear(); effect_roles.clear(); emitted_pcm.clear()
		stage(id, target)
		check(battle.battle_ui._selection.has_review(), id + " opens a real review")
		seed(8)
		battle.battle_ui._selection.confirm_review()
		await settle()
		check(not controllers.is_empty(), id + " owns a presentation ticket")
		check(cues.has(id + "_charge"), id + " has an identifiable windup cue")
		check(cues.has(id + "_release"), id + " has an identifiable release cue")
		check(cues.has(id + "_contact") or cues.has(id + "_heal"), id + " has contact/support audio")
		check(not effect_roles.is_empty(), id + " has visible owned effects")
		check(emitted_pcm.has(id + "_charge"), id + " actually plays PCM during windup")
		check(emitted_pcm.has(id + "_release"), id + " actually plays PCM on release")
		for cue in [id + "_charge", id + "_release"]:
			check(cues.count(cue) == 1, cue + " fires once per ticket")
		var digest := str(emitted_pcm.get(id + "_charge", ""))
		check(not pcm_by_ability.values().has(digest), id + " sound differs from preceding skills")
		pcm_by_ability[id] = digest
		feedback_report[id] = {"cues":cues.duplicate(), "phases":phases.duplicate(), "effects":effect_roles.keys(), "pcm":emitted_pcm.duplicate()}
		check(caster.mp == 200 - int(AbilityDB.get_ability(id).mp_cost), id + " spends MP exactly once")
		if id == "haste":
			check(target.has_status("haste") and target.hp == 2000, "Haste applies support without damage")
			check(phases.has("casting") and phases.has("support"), "Haste has cast and support phases")
		if id == "defend": check(target.hp == 2000, "Defend is non-damaging")
		await get_tree().create_timer(0.9).timeout
		for ref in controllers: check(not is_instance_valid(ref.get_ref()), id + " retires its audio/effects")
	await cleanup()
	if not capture_dir.is_empty():
		var file := FileAccess.open(capture_dir.path_join("skill-feedback.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"skills":feedback_report}, "  "))
	print("Skill feedback: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
