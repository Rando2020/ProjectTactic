extends Node

var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func make_unit(id: String) -> Unit:
	var unit := Unit.new()
	unit.unit_data = UnitData.new()
	unit.unit_data.base_stats = UnitStats.new()
	unit.unit_data.base_stats.hp = 100
	unit.unit_data.base_stats.magic = 50
	unit.unit_data.base_stats.magic_resistance = 0
	unit.unit_id = id
	unit.display_name = id.capitalize()
	unit.hp = 50
	unit.ether = 0
	return unit

func run() -> void:
	var fixture := {"visible": true, "actor_name": "Zane", "target_name": "Raider",
		"ability_name": "Attack", "hp_before": 50, "hp_after": 10, "max_hp": 100,
		"damage": 40, "crit_damage": 60, "hit_pct": 88, "crit_pct": 5}
	var before := fixture.duplicate(true)
	seed(1729)
	var next_random := randi()
	seed(1729)
	var outcome := CombatOutcome.project(fixture)
	check(randi() == next_random and fixture == before, "projection preserves RNG and input")
	check(is_equal_approx(outcome.ko_probability, 0.044), "critical-only KO is hit times conditional critical probability")
	check(is_equal_approx(outcome.expected_hp_loss, 35.64), "expected HP loss caps overkill per outcome")
	check(outcome.normal_hp_after == 10 and outcome.critical_hp_after == 0, "normal and critical HP stay separate")
	check(CombatOutcome.ko_label(outcome) == "KO chance 4.4% on this hit", "small KO chances remain visible")
	for hit in [0, 20, 88, 100]:
		for crit in [0, 5, 100]:
			var trial := fixture.duplicate()
			trial.hit_pct = hit
			trial.crit_pct = crit
			var result := CombatOutcome.project(trial)
			check(is_equal_approx(result.miss_probability + result.normal_probability + result.critical_probability, 1.0), "outcomes partition probability")
	fixture.damage = 60
	check(is_equal_approx(CombatOutcome.project(fixture).ko_probability, 0.88), "lethal normal damage does not imply guaranteed KO")
	fixture.hit_pct = 100
	check(CombatOutcome.ko_label(CombatOutcome.project(fixture)).begins_with("Guaranteed"), "guaranteed label requires certainty")
	fixture.damage = 0
	fixture.crit_damage = 0
	check(CombatOutcome.project(fixture).ko_probability == 0.0, "immune damage cannot KO")
	check(CombatOutcome.project({"hp_before": 0}).is_empty(), "no probability for absent or defeated target")
	check(CombatOutcome.project({"hp_before": 50, "is_heal": true}).is_empty(), "healing is not a damage roll")
	for affinity in [0.1, 0.25, 0.4, 0.5]:
		check(CombatFormula.affinity_label(affinity) == "Resists", "positive reduced damage is resistance")
		check(ForecastCalculator._affinity_label(affinity) == "RESISTS", "forecast agrees on resistance")
	var caster := make_unit("mira")
	var target := make_unit("raider")
	var burn := StatusEffect.new()
	burn.status_id = "burn"
	target.statuses.append(burn)
	GameState.active_run = RunState.new()
	GameState.active_run.active_boons = [{"effect": {"type": "passive", "id": "brand", "bonus": 0.5}}]
	check(RunBonuses.for_current_run().brand_bonus == 0.5, "fixture activates real brand bonus")
	var spell := ForecastCalculator.spell(caster, target, {"spell_type": "fire", "base_power": 100})
	check(spell.damage == 50, "brand does not inflate fire preview beyond real direct spell formula")
	target.hp = 100
	var resolver := CombatResolver.new()
	add_child(resolver)
	var resolved := resolver.resolve_spell(caster, target, "fire", 100, &"clarity_test")
	check(resolved.applied_hp_damage == spell.damage and target.hp == 50, "real spell resolver matches burning-target forecast with Brand active")
	resolver.queue_free()
	var area := ForecastCalculator.area(caster, AbilityDB.get_ability("mass_cure"))
	check(area.is_heal and area.amount_label == "AREA HEAL" and area.mp_cost == 40, "area healing keeps identity and cost")
	check(not area.has("damage") and not area.has("hit_pct"), "targetless preview invents neither damage nor accuracy")
	check(ForecastCalculator.area(caster, AbilityDB.get_ability("cure")).amount_label == "SELECT TARGET", "single target heal never claims an area effect")
	var manager := BattleManager.new()
	var grid := TacticalGrid.new()
	manager.tactical_grid = grid
	manager.units = {"mira": caster}
	manager.active_unit_id = "mira"
	caster.grid_pos = Vector2i.ZERO
	grid.ability_tiles.assign([Vector2i(2, 2)])
	var actual_area := manager._ability_preview_for_tile(Vector2i(2, 2), AbilityDB.get_ability("mass_cure"))
	check(actual_area.get("amount_label") == "AREA HEAL" and not actual_area.has("damage_min"), "manager uses honest area preview on empty tile")
	manager.free()
	grid.free()
	var ui := BattleUI.new()
	add_child(ui)
	await get_tree().process_frame
	fixture = before.duplicate()
	fixture.affinity_label = "WEAK x1.5"
	ui._on_action_preview_changed(fixture)
	check(ui._preview_hit_label.text.contains("88%") and ui._preview_hit_label.text.contains("WEAK"), "weakness never hides hit chance")
	check(ui._preview_amount_label.text == "40 HP on hit", "headline separates normal damage from critical")
	check(ui._preview_crit_label.text.contains("60 HP (5% of hits)"), "critical amount and conditional probability labeled")
	check(ui._preview_outcome_label.text == "KO chance 4.4% on this hit", "live UI uses shared probability")
	check(ui._preview_target_label.text.contains("on normal hit") and ui._preview_hp_bar.value == 10, "projected HP is conditional and matches bar")
	ui._on_action_preview_changed(area)
	check(ui._preview_amount_label.text == "AREA HEAL" and ui._preview_action_label.text.contains("40 MP"), "live area UI displays identity and cost")
	check(not ui._preview_hp_bar.visible and not ui._preview_hit_label.visible and not ui._preview_outcome_label.visible, "area hover clears stale target probabilities")
	ui._on_action_preview_changed(ForecastCalculator.spell(caster, target, AbilityDB.get_ability("cure")))
	check(ui._preview_amount_label.text == "+50 HP" and ui._preview_hp_bar.value == 100, "healing UI reports capped restoration")
	check(not ui._preview_hit_label.visible and not ui._preview_crit_label.visible, "healing does not advertise hit or critical rolls")
	ui._on_action_preview_changed(fixture)
	get_tree().root.content_scale_size = Vector2i.ZERO
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(3840, 2160)]:
		get_tree().root.size = resolution
		ui._layout_persistent_hud()
		await get_tree().process_frame
		await get_tree().process_frame
		var rail := ui._right_panel_scroll.get_global_rect()
		for label in [ui._preview_amount_label, ui._preview_hit_label, ui._preview_crit_label, ui._preview_outcome_label]:
			var bounds: Rect2 = label.get_global_rect()
			check(bounds.position.x >= rail.position.x - 1 and bounds.end.x <= rail.end.x + 1, "forecast fits rail horizontally at %s" % resolution)
	get_tree().root.size = Vector2i(1280, 720)
	ui._layout_persistent_hud()
	await get_tree().process_frame
	await get_tree().process_frame
	ui._right_panel_scroll.ensure_control_visible(ui._preview_panel)
	if OS.get_environment("TACTIC_CAPTURE") != "":
		await RenderingServer.frame_post_draw
		var output := get_viewport().get_texture().get_image()
		output.save_png(OS.get_environment("TACTIC_CAPTURE"))
	ui._on_action_preview_changed({})
	check(not ui._preview_panel.visible, "cancel hides forecast")
	caster.free()
	target.free()
	print("Combat clarity: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
