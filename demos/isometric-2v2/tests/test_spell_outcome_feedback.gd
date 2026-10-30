extends Node

var checks := 0
var failures := 0
var logs: Array[String] = []
var results: Array[Dictionary] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func enemy(manager: BattleManager, archetype: String) -> Unit:
	for unit: Unit in manager.units.values():
		if unit.get_meta("archetype_id", "") == archetype:
			return unit
	return null

func make_battle() -> Node:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.selected_map_index = 0
	var battle: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	manager.units.zane.grid_pos = Vector2i(3, 4)
	enemy(manager, "storm_imp").grid_pos = Vector2i(5, 4)
	enemy(manager, "null_drake").grid_pos = Vector2i(6, 4)
	enemy(manager, "void_cultist").grid_pos = Vector2i(0, 0)
	manager.log_message.connect(func(message: String): logs.append(message))
	manager.combat_resolver.combat_resolved.connect(func(result: Dictionary): results.append(result))
	logs.clear()
	results.clear()
	return battle

func dispose(battle: Node) -> void:
	await battle.battle_manager._recover_action()
	battle.queue_free()
	await get_tree().process_frame

# A return to nominal ability power, projected overkill, or reused hop results
# must fail these literal expectations against the real resolver and log signal.
func run() -> void:
	for fixture in [
		{"id": "native immune", "affinity": 0.0, "hp": 90, "ether": 90, "hp_loss": 0, "ether_loss": 0, "projected": 0, "text": "IMMUNE to damage (0 HP)"},
		{"id": "normal", "affinity": 1.0, "hp": 90, "ether": 0, "hp_loss": 50, "ether_loss": 0, "projected": 50, "text": "-50 HP"},
		{"id": "ether armor", "affinity": 1.0, "hp": 90, "ether": 90, "hp_loss": 45, "ether_loss": 18, "projected": 45, "text": "-45 HP, -18 Ether"},
		{"id": "neutral zero", "affinity": 1.0, "resistance": 100, "hp": 90, "ether": 90, "hp_loss": 0, "ether_loss": 0, "projected": 0, "text": "0 HP"},
		{"id": "resisted", "affinity": 0.5, "hp": 90, "ether": 90, "hp_loss": 23, "ether_loss": 9, "projected": 23, "text": "-23 HP, -9 Ether [resist]"},
		{"id": "weak", "affinity": 1.5, "hp": 90, "ether": 90, "hp_loss": 69, "ether_loss": 27, "projected": 69, "text": "-69 HP, -27 Ether [WEAK!]"},
		{"id": "overkill", "affinity": 1.0, "hp": 7, "ether": 90, "hp_loss": 7, "ether_loss": 18, "projected": 45, "text": "-7 HP, -18 Ether"},
	]:
		for chain in [false, true]:
			var battle := make_battle()
			var manager: BattleManager = battle.battle_manager
			var caster: Unit = manager.units.zane
			var primary: Unit = enemy(manager, "storm_imp")
			var secondary: Unit = enemy(manager, "null_drake")
			primary.unit_data = primary.unit_data.duplicate(true)
			primary.unit_data.elemental_affinities.thunder = fixture.affinity
			primary.unit_data.base_stats.magic_resistance = fixture.get("resistance", 0)
			primary.hp = fixture.hp
			primary.ether = fixture.ether
			var mp_before := caster.mp
			var primary_hp_events: Array[int] = []
			primary.hp_changed.connect(func(_id: String, hp: int, _max_hp: int): primary_hp_events.append(hp))
			var ability := AbilityDB.get_ability("thunderstrike")
			var label := "%s %s" % [fixture.id, "chain" if chain else "single"]
			var accepted: bool
			if chain:
				accepted = await manager._execute_aoe_ability(caster, primary.grid_pos, ability)
			else:
				accepted = await manager._execute_ability(caster, primary, ability)
			check(accepted, label + " executed even on immunity")
			check(caster.mp == mp_before - 14, label + " costs exactly 14 MP")
			check(primary.hp == fixture.hp - fixture.hp_loss, label + " exact primary HP loss")
			check(primary.ether == fixture.ether - fixture.ether_loss, label + " exact primary Ether loss")
			check(primary_hp_events.size() == 1, label + " applies primary damage exactly once")
			check(results.size() == (2 if chain else 1), label + " one resolver result per target")
			check(results[0].get("applied_hp_damage", -1) == fixture.hp_loss, label + " result exposes applied HP loss")
			check(results[0].hp_damage == fixture.projected, label + " preserves projected HP field")
			var expected_line := "Storm Imp: " + str(fixture.text) if chain else "Zane casts Thunderstrike on Storm Imp! " + str(fixture.text)
			check(logs.count(expected_line) == 1, label + " log reports one actual outcome: " + expected_line)
			check(logs.size() == (3 if chain else 1) + (1 if fixture.hp_loss == fixture.hp else 0), label + " no duplicate target logs; existing defeat notice retained")
			if chain:
				# 48 Magic * 63% = 30 incoming; 11 Ether lost; 27 HP lost.
				check(secondary.hp == 93 and secondary.ether == 49, label + " second hop applies its own 27 HP / 11 Ether")
				check(results[1].get("applied_hp_damage", -1) == 27, label + " second hop result is not primary's result")
				check(logs.count("arcs to Null Drake: -27 HP, -11 Ether") == 1, label + " second hop log matches actual loss, not power 63")
			print("Outcome fixture %s: primary HP %d->%d Ether %d->%d; secondary HP=%d Ether=%d; logs=%s" % [label, fixture.hp, primary.hp, fixture.ether, primary.ether, secondary.hp, secondary.ether, str(logs)])
			await dispose(battle)
	await check_miss(false)
	await check_miss(true)
	await check_rejected()
	await check_physical_applied_loss()
	print("Spell outcome feedback: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func check_miss(chain: bool) -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var caster: Unit = manager.units.zane
	var target: Unit = enemy(manager, "storm_imp")
	var blind := StatusEffect.new()
	blind.status_id = "blind"
	caster.apply_status(blind)
	# Disable only optional presentation for this deterministic RNG fixture.
	# Real admission, hit roll, resolver, state changes and logging still run.
	# No production RNG seam or damage mock is introduced.
	var vfx := get_tree().root.get_node("VFX")
	get_tree().root.remove_child(vfx)
	for candidate in range(100):
		seed(candidate)
		if randi_range(1, 100) > 65:
			seed(candidate)
			break
	var ability := AbilityDB.get_ability("thunderstrike").duplicate(true)
	# Intentional later rules correction: damaging secondary status now requires
	# this recipient's actual hit. All existing feedback and cost checks remain.
	ability["status_effect"] = {"id": "slow", "duration": 2}
	var accepted: bool
	if chain:
		accepted = await manager._execute_aoe_ability(caster, target.grid_pos, ability)
	else:
		accepted = await manager._execute_ability(caster, target, ability)
	get_tree().root.add_child(vfx)
	var label := "miss " + ("chain" if chain else "single")
	check(accepted and caster.mp == 76, label + " executed miss still pays once")
	check(results[0].get("missed", false), label + " actual hit roll missed")
	check(target.hp == 90 and target.ether == 90, label + " miss consumes no HP or Ether")
	check(results[0].get("applied_hp_damage", -1) == 0, label + " miss result has zero applied HP")
	check(not target.has_status("slow"), label + " damaging miss applies no secondary status")
	var line := "Storm Imp: MISS (0 HP)" if chain else "Zane casts Thunderstrike on Storm Imp! MISS (0 HP)"
	check(logs.count(line) == 1, label + " miss is not mislabeled immunity or damage")
	print("Outcome fixture %s: result=%s; logs=%s" % [label, str(results[0]), str(logs)])
	await dispose(battle)

func check_rejected() -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var caster: Unit = manager.units.zane
	var target: Unit = enemy(manager, "storm_imp")
	var silence := StatusEffect.new()
	silence.status_id = "silence"
	caster.apply_status(silence)
	for chain in [false, true]:
		var accepted: bool
		if chain:
			accepted = await manager._execute_aoe_ability(caster, target.grid_pos, AbilityDB.get_ability("thunderstrike"))
		else:
			accepted = await manager._execute_ability(caster, target, AbilityDB.get_ability("thunderstrike"))
		check(not accepted, "Silenced cast remains rejected")
		check(caster.mp == 90 and target.hp == 90 and target.ether == 90, "rejection changes no MP/HP/Ether")
		check(results.is_empty() and logs.is_empty(), "rejection produces no resolved result or damage claim")
	await dispose(battle)

func check_physical_applied_loss() -> void:
	var battle := make_battle()
	var manager: BattleManager = battle.battle_manager
	var caster: Unit = manager.units.zane
	var target: Unit = enemy(manager, "storm_imp")
	caster.grid_pos = Vector2i(5, 3)
	target.facing = "S" # rear guarantees physical hit; crit remains a legitimate outcome
	target.hp = 7
	var result := manager.combat_resolver.resolve_attack(caster, target, {}, {}, "arrow")
	check(target.hp == 0, "physical overkill actually defeats target")
	check(result.get("applied_hp_damage", -1) == 7, "shared physical result clamps only applied HP loss")
	check(result.hp_damage > 7 and result.damage == result.hp_damage, "physical projected legacy fields remain unchanged")
	var expected_temper := 35 if result.get("critical", false) else 23
	check(result.temper_damage == expected_temper, "physical result preserves Temper loss")
	check(BattleManager._combat_outcome_text(result) == "-7 HP, -%d Temper" % expected_temper, "shared formatter separates actual HP and Temper loss")
	await dispose(battle)
