extends Node
## Real factories, forecasts and resolver. No fake combat implementation.
var checks := 0
var failures := 0
var factory: BattleScene
var created: Array[Unit] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
func _ready() -> void:
	call_deferred("run")
func make(history: Dictionary, faction: String = "player") -> Unit:
	GameState.unit_registry.kael.job_jp = history.duplicate(true)
	var unit := factory._make_unit("kael", "Mastery fixture", faction, Vector2i(3, 3), 2000, 100, 4, 2, 6, 100, 100, 100, 100)
	add_child(unit)
	created.append(unit)
	unit.hp = 1000
	unit.temper = 0
	unit.ether = 0
	return unit
func run() -> void:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.practice_session.clear()
	GameState.selected_map_index = 0
	GameState.save()
	var saved := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	factory = load("res://scenes/Battle.tscn").instantiate()
	add_child(factory)
	var resolver: CombatResolver = factory.battle_manager.combat_resolver
	var unmastered := make({"squire": 799, "warder": 799, "luminary": 799})
	var mastered := make({"squire": 800, "warder": 800, "luminary": 800})
	var ordinary := make({})
	check(unmastered.unit_data.base_stats.move == 4, "799 JP does not grant mastery movement")
	check(mastered.unit_data.base_stats.move == 5, "800 Squire JP grants exactly one Move")
	check(make({"squire": 800}).unit_data.base_stats.move == 5, "repeated spawn does not accumulate Move")
	check(make({"unknown_job": 9999}).unit_data.base_stats.move == 4, "unknown job cannot grant mastery")
	check(make({"squire": 800}, "enemy").unit_data.base_stats.move == 4, "enemy with matching character ID never inherits player mastery")
	GameState.unit_registry.kael.current_job_id = "arcanist"
	var switched := make({"squire": 800})
	check(switched.unit_data.base_stats.move == 5, "earned mastery survives current class switch")
	var character := CharacterScreen.new()
	character._gs = GameState
	check(character._stats_for("kael").move == 5, "character Move agrees with battle movement")
	character.free()
	# 100 physical damage: 25% reduction, then 35% Temper absorption and 25% HP reduction from absorbed amount.
	check(CombatFormula.project_physical_armor_result(unmastered, 100).hp_damage == 100, "unmastered physical damage unchanged")
	var projection := CombatFormula.project_physical_armor_result(mastered, 100)
	check(projection.hp_damage == 75, "Warder mastery reduces physical damage by 25 percent")
	check(mastered.receive_damage(100, "physical").hp_damage == 75, "actual physical damage uses same mastery reduction")
	mastered.temper = 100
	projection = CombatFormula.project_physical_armor_result(mastered, 100)
	check(projection.hp_damage == 68 and projection.temper_damage == 26, "Warder reduction applies before Temper absorption")
	var result := mastered.receive_damage(100, "physical")
	check(result.hp_damage == 68 and result.temper_damage == 26 and mastered.temper == 74, "actual Temper spend matches forecast")
	mastered.temper = 0
	var protect := StatusEffect.new(); protect.status_id = "protect"; protect.duration = 2
	mastered.apply_status(protect)
	check(mastered.receive_damage(100, "physical").hp_damage == 53, "Protect stacks multiplicatively with Warder mastery")
	var defending := StatusEffect.new(); defending.status_id = "defending"; defending.duration = 2
	mastered.apply_status(defending)
	check(mastered.receive_damage(100, "physical").hp_damage == 27, "Defend stacks after Warder and Protect without double reduction")
	mastered.statuses.clear()
	check(mastered.receive_damage(100, "magical").hp_damage == 100, "Warder does not reduce magical damage")
	check(mastered.receive_damage(100, "true").hp_damage == 100, "Warder does not reduce true damage")
	# A deterministic roll in the gained 25-40% interval proves the actual resolver threshold changes, with no extra rolls.
	var counter_seed := 0
	while true:
		seed(counter_seed)
		randi_range(1, 100); randi_range(1, 100)
		var roll := randf()
		if roll >= 0.25 and roll < 0.40: break
		counter_seed += 1
	ordinary.grid_pos = Vector2i(3, 2)
	mastered.grid_pos = Vector2i(3, 3)
	unmastered.grid_pos = mastered.grid_pos
	# Back attack forces 100% hit, leaving the same three existing random draws.
	mastered.set_facing("S"); unmastered.set_facing("S")
	seed(counter_seed)
	check(not resolver.resolve_attack(ordinary, unmastered, {}, {}, "slash", false, {}, &"test").counter, "ordinary 25 percent counter does not accept gained interval")
	seed(counter_seed)
	check(resolver.resolve_attack(ordinary, mastered, {}, {}, "slash", false, {}, &"test").counter, "Squire mastery adds 15 percentage points to actual counter roll")
	seed(counter_seed)
	check(not resolver.resolve_attack(ordinary, mastered, {}, {}, "slash", true, {}, &"test").counter, "mastery never chains a counter")
	seed(counter_seed)
	check(not resolver.resolve_attack(ordinary, mastered, {}, {}, "arrow", false, {}, &"test").counter, "mastery preserves ranged counter exclusion")
	ordinary.grid_pos = Vector2i(3, 0)
	seed(counter_seed)
	check(not resolver.resolve_attack(ordinary, mastered, {}, {}, "slash", false, {}, &"test").counter, "mastery does not extend counter range")
	# Restore injured targets before checking capped and uncapped healing.
	for caster in [ordinary, unmastered, mastered]:
		for missing in [0, 20, 200]:
			ordinary.hp = ordinary.unit_data.base_stats.hp - missing
			var ability := AbilityDB.get_ability("cure")
			var expected := mini(missing, 104 if caster == mastered else 80)
			var preview := ForecastCalculator.spell(caster, ordinary, ability)
			check(preview.heal == expected, "Luminary heal forecast matches mastery and missing HP")
			var before := ordinary.hp
			check(resolver.resolve_heal(caster, ordinary, 80).healed == expected and ordinary.hp == before + expected, "actual healing matches forecast")
	GameState.active_run = RunState.new()
	GameState.active_run.active_boons = [{"id":"test_light", "effect":{"type":"elemental_bonus", "element":"holy", "bonus":0.0, "heal_bonus":15}}]
	ordinary.hp = 100
	var preview := ForecastCalculator.spell(mastered, ordinary, AbilityDB.get_ability("cure"))
	var intent := factory.battle_manager._enemy_intent_details(mastered, "heal", ordinary, AbilityDB.get_ability("cure"))
	check(intent.damage == -119 and intent.target_hp_after == 219, "heal intent uses the same earned mastery as forecast")
	check(preview.heal == 119, "mastery multiplies base heal before adding flat run bonus")
	check(resolver.resolve_heal(mastered, ordinary, 80).healed == 119, "run bonus and mastery agree during resolution")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == saved, "mastery projections and combat never rewrite saved ownership")
	for unit in created: unit.queue_free()
	factory.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(2.5).timeout
	print("Job mastery: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
