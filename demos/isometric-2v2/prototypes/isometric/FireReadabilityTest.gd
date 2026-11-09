extends "res://prototypes/isometric/FireballSheetTest.gd"

var seen: Dictionary = {}
var sample_enabled := false
var owner_ref: WeakRef

func _process(_delta: float) -> void:
	if not sample_enabled: return
	for reference in controllers:
		var owner = reference.get_ref()
		if not is_instance_valid(owner): continue
		for effect in owner._fx:
			if is_instance_valid(effect) and effect is FRAMES and effect.visible:
				seen[effect.frame_index] = true

func run() -> void:
	VFX.child_entered_tree.connect(observe)
	var original_fps := Engine.max_fps
	var original_scale := Engine.time_scale
	await actual_readability(30, 1.0, true)
	await actual_readability(30, 0.25, true)
	await actual_readability(8, 1.0, true)
	Engine.max_fps = original_fps
	Engine.time_scale = original_scale
	print("Fire readability lifecycle: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func actual_readability(fps: int, speed: float, require_all: bool) -> void:
	Engine.max_fps = fps
	Engine.time_scale = 1.0
	GameState._init_defaults()
	GameState.active_run = null
	GameState.practice_session = {}
	var battle := preload("res://prototypes/isometric/Skirmish.tscn").instantiate()
	add_child(battle)
	var manager: BattleManager = battle.battle_manager
	for i in 300:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().process_frame
	check(manager.current_phase == BattleManager.Phase.PLAYER_TURN, "readability fixture boots real Skirmish")
	var actor: Unit = manager.units.zane
	var target: Unit = manager.units.Enemy_2
	actor.grid_pos = Vector2i(2,3)
	actor.mp = 200
	target.grid_pos = Vector2i(4,3)
	target.hp = 2000
	manager.units.Enemy_1.grid_pos = Vector2i(0,0)
	var records: Array[Dictionary] = []
	manager.combat_resolver.combat_resolved.connect(func(result: Dictionary): records.append(result))
	controllers.clear()
	seen.clear()
	sample_enabled = true
	Engine.time_scale = speed
	var mp := actor.mp
	var hp := target.hp
	var ct := actor.ct
	check(await manager._execute_aoe_ability(actor,target.grid_pos,AbilityDB.get_ability("fire")), "Fire succeeds fps=%d scale=%s" % [fps,speed])
	check(actor.mp == mp-12 and actor.ct == ct and target.hp < hp and records.size() == 1, "contact applies MP12 and damage once without CT writes")
	check(controllers.size() == 1, "exactly one presentation owner")
	var owner = controllers.back().get_ref()
	owner_ref = weakref(owner)
	check(is_instance_valid(owner._fire_tail) and owner._fire_tail._tail, "authored tail starts at authoritative contact")
	var tail_ref: WeakRef = weakref(owner._fire_tail)
	for effect in owner._fx:
		if is_instance_valid(effect):
			check(not str(effect.get_meta("zane_effect_role", "")) in ["fan_tile","ember","recipient_accent","trail"], "authored Fire suppresses competing procedural accents")
	await manager._recover_action()
	check(manager.action_lifecycle.phase == "idle", "command lifecycle recovers independently of cosmetic tail")
	check(is_instance_valid(tail_ref.get_ref()) and tail_ref.get_ref()._tail, "cosmetic tail remains active after normal input recovery")
	check(battle.set_stage_mode(true) and battle.rotate_stage(1), "stage controls remain unlocked after recovery while tail plays")
	await get_tree().process_frame
	await get_tree().process_frame
	var tail = tail_ref.get_ref()
	check(is_instance_valid(tail), "rotating recovered stage does not prematurely retire authored tail")
	if is_instance_valid(tail):
		var projected: Vector2 = battle.tactical_grid.to_global(battle.tactical_grid._unit_foot_pos(target.grid_pos))
		check(tail.global_position.distance_to(projected) < 0.1, "active outcome tail tracks destination after recovered stage rotation")
	check(records.size() == 1 and actor.mp == mp-12, "cosmetic rotation never repeats damage or MP charge")
	var elapsed := 0.0
	while is_instance_valid(owner_ref.get_ref()) and elapsed < 4.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	check(not is_instance_valid(owner_ref.get_ref()), "owner retires after scaled tail even at low speed")
	check(not is_instance_valid(tail_ref.get_ref()), "tail child retires with owner")
	if require_all:
		for frame in 16: check(seen.has(frame), "visible frame %d at fps=%d scale=%s" % [frame,fps,speed])
	check(records.size() == 1 and actor.mp == mp-12, "tail completion never repeats contact or MP charge")
	sample_enabled = false
	Engine.time_scale = 1.0
	# A cancelled windup must not leave its input lock or owner behind; immediate retry works.
	mp = actor.mp
	hp = target.hp
	records.clear()
	get_tree().create_timer(0.08).timeout.connect(manager.action_lifecycle.cancel)
	check(not await manager._execute_aoe_ability(actor,target.grid_pos,AbilityDB.get_ability("fire")), "cancel rejects Fire contact")
	await manager._recover_action()
	await get_tree().process_frame
	check(actor.mp == mp and target.hp == hp and records.is_empty(), "cancel spends no MP and causes no damage")
	check(manager.action_lifecycle.phase == "idle" and battle.set_stage_mode(true) and battle.rotate_stage(1), "cancel releases input and rotation lock")
	check(await manager._execute_aoe_ability(actor,target.grid_pos,AbilityDB.get_ability("fire")), "fresh Fire retry succeeds")
	await manager._recover_action()
	# KO after authoritative contact cancels only cosmetic tail, never repeats combat.
	actor.hp = 0
	await get_tree().process_frame
	await get_tree().process_frame
	check(records.size() == 1 and actor.mp == mp-12, "post-contact KO preserves exactly one spend and outcome")
	for reference in controllers: check(not is_instance_valid(reference.get_ref()), "cancel/retry/KO leaves no presentation owner")
	battle.queue_free()
	await get_tree().process_frame
