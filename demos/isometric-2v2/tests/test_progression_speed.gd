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

func run() -> void:
	for fixture in [
		{"jp": {"squire": 90}, "speed": 6},
		{"jp": {"squire": 90, "warder": 90}, "speed": 4},
		{"jp": {"squire": 90, "warder": 520}, "speed": 1},
		{"jp": {"squire": 90, "warder": 800}, "speed": 1},
		{"jp": {"squire": 90, "warder": 800, "scout": 90}, "speed": 2},
	]:
		GameState._init_defaults()
		GameState.active_run = null
		GameState.practice_session.clear()
		GameState.selected_map_index = 0
		GameState.unit_registry.kael.job_jp = fixture.jp.duplicate(true)
		GameState.unit_registry.kael.current_job_id = "warder" if fixture.jp.has("warder") else "squire"
		var original_job: String = GameState.unit_registry.kael.current_job_id
		var battle: Node = load("res://scenes/Battle.tscn").instantiate()
		add_child(battle)
		var kael: Unit = battle.battle_manager.units.kael
		var label := "job history " + str(fixture.jp)
		var character_screen := CharacterScreen.new()
		character_screen._gs = GameState
		check(character_screen._stats_for("kael").speed == kael.unit_data.base_stats.speed, label + " displayed speed agrees with actual spawn")
		character_screen.free()
		check(kael.unit_data.base_stats.speed == fixture.speed, label + " actual spawn keeps positive speed and normal class bonuses")
		check(GameState.unit_registry.kael.job_jp == fixture.jp and GameState.unit_registry.kael.current_job_id == original_job, label + " stored progression unchanged")
		var scheduler := TurnOrder.new()
		var lone: Array[Unit] = [kael]
		scheduler.initialize(lone)
		check(scheduler.get_projected_order().size() == 6, label + " living unit appears in forecast")
		check(scheduler.tick_until_ready() == kael, label + " living unit receives real activation")
		var slow := StatusEffect.new()
		slow.status_id = "slow"
		slow.duration = 1
		kael.apply_status(slow)
		check(kael.get_effective_speed() == maxi(1, int(fixture.speed * 0.5)), label + " Slow cannot erase last CT point")
		check(scheduler.tick_until_ready() == kael, label + " slowed unit can reach own turn")
		kael.begin_turn()
		kael.end_turn()
		check(not kael.has_status("slow"), label + " Slow can expire through owner turn")
		scheduler.free()
		battle.queue_free()
		await get_tree().process_frame
	# Exercise the actual factory, not only direct Unit data, at the clamp boundary.
	GameState._init_defaults()
	GameState.active_run = null
	GameState.practice_session.clear()
	GameState.unit_registry.kael.job_jp = {"squire": 90, "warder": 800}
	var factory: Node = load("res://scenes/Battle.tscn").instantiate()
	add_child(factory)
	for fixture in [{"base": -2, "expected": -8}, {"base": 0, "expected": -6}, {"base": 1, "expected": 1}]:
		var unit: Unit = factory._make_unit("kael", "Factory boundary", "player", Vector2i.ZERO, 100, 30, 3, 1, fixture.base, 20, 20, 0, 0)
		check(unit.unit_data.base_stats.speed == fixture.expected, "factory preserves configured nonpositive speed but floors positive speed overwhelmed by history: %d" % fixture.base)
		check(unit.get_effective_speed() == fixture.expected, "factory effective speed matches stored speed: %d" % fixture.base)
		var scheduler := TurnOrder.new()
		var lone: Array[Unit] = [unit]
		scheduler.initialize(lone)
		check((scheduler.tick_until_ready() == unit) == (fixture.base > 0), "factory nonpositive units stay unscheduled and positive units remain actionable: %d" % fixture.base)
		scheduler.free()
		unit.free()
	factory.queue_free()
	await get_tree().process_frame
	# Explicit zero/negative configured speeds are not globally promoted into turns.
	for base_speed in [-2, 0, 1, 2, 6, 9]:
		var unit := Unit.new()
		unit.unit_data = UnitData.new()
		unit.unit_data.base_stats = UnitStats.new()
		unit.unit_data.base_stats.speed = base_speed
		unit.hp = 100
		check(unit.get_effective_speed() == base_speed, "unmodified configured speed preserved: %d" % base_speed)
		var haste := StatusEffect.new()
		haste.status_id = "haste"
		unit.statuses.append(haste)
		check(unit.get_effective_speed() == int(base_speed * 1.5), "normal Haste rounding preserved: %d" % base_speed)
		var slow := StatusEffect.new()
		slow.status_id = "slow"
		unit.statuses.append(slow)
		check(unit.get_effective_speed() == int(base_speed * 1.5), "Haste precedence unchanged: %d" % base_speed)
		unit.statuses.erase(haste)
		var expected := maxi(1, int(base_speed * 0.5)) if base_speed > 0 else int(base_speed * 0.5)
		check(unit.get_effective_speed() == expected, "Slow positive floor preserves explicit nonpositive speed: %d" % base_speed)
		unit.free()
	print("Progression speed: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
