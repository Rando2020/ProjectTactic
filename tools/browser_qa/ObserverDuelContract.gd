extends Node
## Native QA bridge contract only; no browser/title/replay coverage claim.
class SceneFixture:
	extends Node
	var _zane_kick_remaining := 0.0

class OwnerFixture:
	extends Node2D
	var context: Dictionary = {}
	var _fx: Array[CanvasItem] = []
	var _voices: Array[AudioStreamPlayer] = []
	var _reactions: Array[Dictionary] = []

var failures := 0
var _slow_tail_exercised := false
var _slow_frame_exercised := false

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
	await _test_delayed_label_retention(fixture)
	await _test_unbound_handoff(fixture)
	await _test_scene_exit_before_cleanup(fixture)
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
		if "--duel-observer-slow-frame" in OS.get_cmdline_user_args():
			# Delay frames only; never change lifecycle/turn/outcome or time_scale.
			_slow_frame_exercised = true
			OS.delay_msec(300)
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
		if "--duel-observer-slow-frame" in OS.get_cmdline_user_args():
			check(_slow_frame_exercised and completed.zane.samples.is_empty(), "slow real frames reproduce handoff before base visual sample")
		check(completed.unit.moved and completed.unit.acted, "retained record has real spent movement/action")
		check(completed.player_turn_serial == before.player_turn_serial + 1, "retained record has actual handoff serial")
		check(completed.zane.lifecycle.phase == "idle" and not completed.resolving, "retained record is after real recovery")
		check(not sentinel.sword_cleanup.is_empty(), "later observation sees actual original-owner cleanup")
		var presentation: Dictionary = sentinel.sword_presentation
		check(not presentation.overflow and presentation.binding_error.is_empty(), "real original-owner presentation retention stays bounded and bound")
		check(presentation.samples.size() == 1, "real sword retains exactly one actual visible outcome Label")
		check(presentation.key == completed.sword_owner.key and presentation.owner_instance_id == completed.sword_owner.instance_id, "real retained sample is bound to the handoff owner")
		check(presentation.recipient_instance_id == str(target.get_instance_id()), "real retained sample is bound to the selected target")
		if "--duel-observer-slow-frame" in OS.get_cmdline_user_args() and presentation.samples.size() == 1:
			check(presentation.samples[0].frame >= completed.frame, "slow-frame actual Label observation is at/after immutable handoff")
		print("DUEL_OBSERVER_ACTION " + JSON.stringify({"before": before, "completed": completed, "presentation": presentation, "cleanup": sentinel.sword_cleanup}))
	# Teardown only after normal AI settles; freeing a live action would strand
	# its awaited presentation coroutine and is not the observer's cleanup job.
	deadline = Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		var active := get_tree().current_scene
		if active is ResultsScreen: break
		if active is BattleScene and active.battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN and not active.battle_manager.is_resolving_action: break
		await get_tree().process_frame
	var current := get_tree().current_scene
	var retained_presentation: Dictionary = sentinel.sword_presentation.duplicate(true)
	if is_instance_valid(current): current.queue_free()
	await get_tree().create_timer(0.6).timeout
	check(sentinel.completed_sword == completed and sentinel.sword_presentation == retained_presentation, "scene exit never replaces immutable handoff or original Label evidence")
	sentinel.queue_free()
	print("Browser duel observer contract: %d failures" % failures)
	get_tree().quit(1 if failures else 0)

func _test_delayed_label_retention(battle: BattleScene) -> void:
	# Synthetic timing contract using actual Controls, NOT gameplay/browser pixels.
	# A frozen handoff has no sample; only the later visible original Label counts.
	var retained := preload("res://tests/browser_qa/ZaneDuelSentinel.gd").new()
	add_child(retained)
	if not retained.has_method("observe_sword_owner"):
		check(false, "delayed original-owner Label capture must be registered before handoff")
		retained.queue_free()
		return
	var recipient: Unit
	for unit: Unit in battle.battle_manager.units.values():
		if unit.team == "enemy": recipient = unit
	var owner := OwnerFixture.new()
	owner.context = {"action_key": "synthetic:1", "actor_id": "zane", "ability_id": ""}
	add_child(owner)
	var label := Label.new()
	label.text = "-53 HP\n-20 Temper"
	label.set_meta("zane_effect_role", "outcome")
	label.hide()
	owner.add_child(label)
	owner._fx.append(label)
	retained.observe_sword_owner(owner, battle, recipient)
	var frozen := {"frame": Engine.get_process_frames(), "unit": {"hp": 320, "mp": 90},
		"sword_owner": {"key": "synthetic:1", "instance_id": str(owner.get_instance_id())},
		"zane": {"samples": [], "overflow": false, "lifecycle": {"ticket": 1, "phase": "idle"}}}
	retained.observe_completed_sword(frozen, owner, battle)
	await get_tree().process_frame
	check(retained.sword_presentation.samples.is_empty(), "hidden labels cannot satisfy actual visible outcome evidence")
	var foreign := Label.new()
	foreign.text = "-53 HP\n-20 Temper"
	foreign.set_meta("zane_effect_role", "outcome")
	add_child(foreign)
	label.show()
	await get_tree().process_frame
	await get_tree().process_frame
	var samples: Array = retained.sword_presentation.samples.duplicate(true)
	check(samples.size() == 1, "later visible Label retained once, ignoring other owners and repeated reads")
	if samples.size() == 1:
		check(samples[0].text == "-53 HP\n-20 Temper" and samples[0].instance_id == str(label.get_instance_id()), "retention reads actual exact Label text and identity")
		check(samples[0].owner_instance_id == str(owner.get_instance_id()) and samples[0].key == "synthetic:1", "sample bound to original owner and action key")
		check(samples[0].recipient_instance_id == str(recipient.get_instance_id()), "sample bound to original recipient identity")
		check(samples[0].frame > frozen.frame, "late visual frame is distinct from logical handoff frame")
	check(retained.completed_sword == frozen, "late visual capture never mutates frozen logical costs/outcome/ticket")
	# Distinct Labels must never be collapsed by text; overflow must fail closed.
	for index in retained.EVIDENCE_LIMIT:
		var extra := Label.new()
		extra.text = "-53 HP\n-20 Temper"
		extra.set_meta("zane_effect_role", "outcome")
		owner.add_child(extra)
	for frame in 2: await get_tree().process_frame
	check(retained.sword_presentation.samples.size() == retained.EVIDENCE_LIMIT and retained.sword_presentation.overflow, "actual duplicate Labels are distinct evidence and retention is explicitly bounded")
	check(retained.completed_sword == frozen, "visual overflow cannot rewrite immutable logical handoff")
	samples = retained.sword_presentation.samples.duplicate(true)
	owner.queue_free()
	foreign.queue_free()
	for frame in 3: await get_tree().process_frame
	check(not retained.sword_cleanup.is_empty() and retained.sword_presentation.samples == samples, "weak-ref original-owner cleanup retains late actual evidence after destruction")
	retained.queue_free()

func _test_unbound_handoff(battle: BattleScene) -> void:
	var retained := preload("res://tests/browser_qa/ZaneDuelSentinel.gd").new()
	add_child(retained)
	var owner := OwnerFixture.new()
	owner.context = {"action_key": "unbound:1", "actor_id": "zane", "ability_id": ""}
	add_child(owner)
	retained.observe_completed_sword({"frame": Engine.get_process_frames(),
		"sword_owner": {"key": "unbound:1", "instance_id": str(owner.get_instance_id())},
		"zane": {"overflow": false}}, owner, battle)
	retained._observe_outcome_labels()
	check(not retained.sword_presentation.binding_error.is_empty() and retained.sword_presentation.samples.is_empty(), "unregistered handoff fails closed without inventing visual evidence")
	owner.queue_free()
	for frame in 3: await get_tree().process_frame
	check(not retained.sword_cleanup.is_empty(), "unbound visual evidence does not prevent original-owner cleanup observation")
	retained.queue_free()

func _test_scene_exit_before_cleanup(battle: BattleScene) -> void:
	# A disposable synthetic scene exercises weak-ref expiry independently of
	# the real live Battle, whose action/AI is never interrupted for this test.
	var scene := SceneFixture.new()
	add_child(scene)
	var owner := OwnerFixture.new()
	owner.context = {"action_key": "scene-exit:1", "actor_id": "zane", "ability_id": ""}
	scene.add_child(owner)
	var label := Label.new()
	label.text = "actual-scene-exit-label"
	label.set_meta("zane_effect_role", "outcome")
	owner.add_child(label)
	owner._fx.append(label)
	var recipient: Unit
	for unit: Unit in battle.battle_manager.units.values():
		if unit.team == "enemy": recipient = unit
	var retained := preload("res://tests/browser_qa/ZaneDuelSentinel.gd").new()
	add_child(retained)
	retained.observe_sword_owner(owner, scene, recipient)
	for frame in 2: await get_tree().process_frame
	var samples: Array = retained.sword_presentation.samples.duplicate(true)
	check(samples.size() == 1 and samples[0].text == "actual-scene-exit-label", "synthetic scene exit starts with one actual Label sample")
	var frozen := {"frame": Engine.get_process_frames(), "sword_owner": {"key": "scene-exit:1", "instance_id": str(owner.get_instance_id())}, "zane": {"overflow": false}}
	retained.observe_completed_sword(frozen, owner, scene)
	scene.queue_free()
	for frame in 3: await get_tree().process_frame
	check(not retained.sword_cleanup.is_empty() and retained.sword_cleanup.battle_removed and retained.sword_cleanup.camera_kick_remaining == null, "scene-exit cleanup observes absent battle rather than fabricating zero kick")
	check(retained.completed_sword == frozen and retained.sword_presentation.samples == samples, "weak-ref scene expiry preserves original logical and sampled evidence")
	retained.queue_free()
