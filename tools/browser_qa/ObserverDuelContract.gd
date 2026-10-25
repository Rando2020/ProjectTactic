extends Node
## Native QA bridge contract only; no browser/title/replay coverage claim.
var failures := 0
var _slow_tail_exercised := false

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	# Keep this contract outside current_scene so the real bootstrap may perform
	# the same normal scene replacement as its exported main-scene entry.
	get_tree().current_scene = null
	var bootstrap := preload("res://tests/browser_qa/ZaneDuelBootstrap.tscn").instantiate()
	get_tree().root.add_child(bootstrap)
	get_tree().current_scene = bootstrap
	var fixture: Node
	for frame in 240:
		await get_tree().process_frame
		fixture = get_tree().current_scene
		if fixture is BattleScene and fixture.battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN:
			break
	check(fixture is BattleScene, "duel bootstrap uses actual Battle as current scene for honest teardown")
	if not fixture is BattleScene:
		get_tree().quit(1)
		return
	var observer: Node = fixture.get_node("BrowserQAObserver")
	var first: Dictionary = observer.snapshot()
	check(first.schema == 2 and first.duel.mode == "zane_duel", "duel schema and real session mode")
	check(first.duel.rig3d and not first.duel.zane_showcase, "duel only selects existing rig3d presentation")
	check(first.roster.size() == 2, "exact two instantiated actors")
	check(first.unit.id == "zane" and first.unit.position == [4, 5], "fresh Zane first by normal initiative")
	var enemy: Dictionary = {}
	for unit: Dictionary in first.roster.values():
		if unit.team == "enemy": enemy = unit
	check(enemy.get("archetype", "") == "storm_imp" and enemy.get("position", []) == [6, 5], "one actual Storm Imp archetype at duel coordinate")
	var profile: Dictionary = first.zane.profile
	var model_path := "res://assets/3d/characters/zane_painterly_v1/zane_painterly_v1.glb"
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/3d/characters/zane_painterly_v1/presentation.json"))
	check(profile.available and profile.profile_id == "zane_painterly_v1" and profile.asset_path == model_path, "duel observes only approved painterly model identity")
	check(profile.model_sha256 == metadata.model_sha256 and FileAccess.get_sha256(model_path) == metadata.model_sha256, "duel observed model digest matches actual frozen local bytes")
	check(profile.output_visible and profile.skeleton_bones == 16 and not profile.model_instance_id.is_empty(), "duel observes actual visible sixteen-bone imported model")
	check(first.legal_attack_targets.is_empty(), "idle has no fabricated legal attack targets")
	for frame in 10: await get_tree().process_frame
	var second: Dictionary = observer.snapshot()
	check(first.unit == second.unit and first.roster == second.roster, "observer never alters gameplay state")
	check(second.completed_sword.is_empty(), "observer never manufactures completed actions")
	check(second.zane.events.is_empty() and second.zane.lifecycle.phase == "idle", "observer never admits actions")
	check(get_tree().root.has_node("ZaneDuelTerminalSentinel"), "separate read-only terminal sentinel survives Battle")
	# Native signals exercise the real gameplay path solely to verify retained
	# observation timing. This is NOT CDP/browser acceptance or forced outcome.
	var ui: BattleUI = fixture.battle_ui
	ui._press_if_ready(ui._move_btn, ui._on_move)
	check(Vector2i(5, 5) in fixture.tactical_grid.move_tiles, "normal one-step destination is legal")
	fixture.tactical_grid.tile_clicked.emit(Vector2i(5, 5))
	var deadline := Time.get_ticks_msec() + 15000
	while (not fixture.battle_manager.active_unit_has_moved or fixture.battle_manager.is_resolving_action) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(fixture.battle_manager.active_unit_has_moved, "native contract performed normal move")
	ui._press_if_ready(ui._attack_btn, ui._on_attack)
	var before: Dictionary = observer.snapshot()
	check(before.legal_attack_targets.size() == 1, "observer sees exact real legal sword target")
	var target: Unit
	for candidate: Unit in fixture.battle_manager.units.values():
		if candidate.team == "enemy": target = candidate
	fixture.battle_manager._on_unit_clicked(target.unit_id)
	var sentinel := get_tree().root.get_node("ZaneDuelTerminalSentinel")
	deadline = Time.get_ticks_msec() + 15000
	while (sentinel.completed_sword.is_empty() or sentinel.sword_cleanup.is_empty()) and Time.get_ticks_msec() < deadline:
		if "--duel-observer-slow-tail" in OS.get_cmdline_user_args() and not _slow_tail_exercised:
			var observed: Dictionary = observer.snapshot()
			for sample: Dictionary in observed.zane.samples:
				if sample.get("role", "") == "outcome":
					# Native-only slow-frame regression, after a real Label sample.
					# No combat/RNG/resource/phase or browser bridge mutation.
					_slow_tail_exercised = true
					OS.delay_msec(600)
					break
		await get_tree().process_frame
	var completed: Dictionary = sentinel.completed_sword.duplicate(true)
	check(not completed.is_empty(), "real turn-ended signal retained completed sword before handoff")
	if not completed.is_empty():
		if "--duel-observer-slow-tail" in OS.get_cmdline_user_args():
			check(_slow_tail_exercised and completed.sword_owner.get("queued_at_handoff", false), "slow real outcome tail queues its original owner before handoff")
		check(completed.unit.moved and completed.unit.acted, "retained record has real spent movement/action")
		check(completed.player_turn_serial == before.player_turn_serial + 1, "retained record has actual handoff serial")
		check(completed.zane.lifecycle.phase == "idle" and not completed.resolving, "retained record is after real recovery")
		check(not sentinel.sword_cleanup.is_empty(), "later observation sees actual original-owner cleanup")
		print("DUEL_OBSERVER_ACTION " + JSON.stringify({"before": before, "completed": completed, "cleanup": sentinel.sword_cleanup}))
	# Teardown only after normal AI settles; freeing a live action would strand
	# its awaited presentation coroutine and is not the observer's cleanup job.
	deadline = Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		var active := get_tree().current_scene
		if active is ResultsScreen: break
		if active is BattleScene and active.battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN and not active.battle_manager.is_resolving_action: break
		await get_tree().process_frame
	var current := get_tree().current_scene
	if is_instance_valid(current): current.queue_free()
	sentinel.queue_free()
	await get_tree().create_timer(0.6).timeout
	print("Browser duel observer contract: %d failures" % failures)
	get_tree().quit(1 if failures else 0)
