extends Node
## Native observer/bootstrap contract, not browser/CDP or audible evidence.
class SignalFixture:
	extends Node
	signal phase_presented(phase: String)
	signal cue_started(cue: String)
	var context := {"action_key": "observer-unit-fixture", "actor_id": "zane", "ability_id": "fire"}
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _ready() -> void:
	var bootstrap := preload("res://tests/browser_qa/ZaneShowcaseBootstrap.tscn").instantiate()
	get_tree().root.add_child.call_deferred(bootstrap)
	var fixture: Node
	for frame in 240:
		await get_tree().process_frame
		fixture = get_tree().root.get_node_or_null("BattleScene")
		if is_instance_valid(fixture) and fixture.battle_manager.current_phase == BattleManager.Phase.PLAYER_TURN:
			break
	check(is_instance_valid(fixture), "bootstrap preserves production /root/BattleScene absolute path")
	if not is_instance_valid(fixture):
		get_tree().quit(1)
		return
	var observer: Node = fixture.get_node("BrowserQAObserver")
	var first: Dictionary = observer.snapshot()
	check(first.unit.id == "lyra", "Practice3D retains first normal Lyra initiative")
	check(GameState.practice_session.get("rig3d", false), "existing Practice3D flag selected before battle")
	var players: Array[String] = []
	for unit: Dictionary in first.roster.values():
		if unit.team == "player": players.append(unit.id)
	players.sort()
	check(players == ["kael", "lyra", "mira", "zane"], "normal four-player party preserved")
	var profile: Dictionary = first.get("zane", {}).get("profile", {})
	check(profile.get("available", false), "real approved 3D profile is available")
	check(profile.get("profile_id", "") == "zane_impact_v1", "approved profile identity")
	check(profile.get("asset_path", "") == "res://assets/3d/characters/zane_impact_v1/zane_impact_v1.glb", "new model resource identity")
	check(not profile.get("model_instance_id", "").is_empty() and profile.get("skeleton_bones", 0) > 0, "actual model/skeleton instantiated")
	for frame in 10: await get_tree().process_frame
	var second: Dictionary = observer.snapshot()
	check(first.unit == second.unit and first.roster == second.roster, "repeated observer reads never alter party/resources/initiative")
	check(second.zane.events.is_empty(), "observer never initiates presentation or combat")
	check(second.zane.lifecycle.phase == "idle" and not second.resolving, "observer never creates an action ticket")
	# Signal-fixture proof only: subscribing at child_entered_tree must catch the
	# very first synchronous charge/cue, before a polling snapshot can happen.
	var owner := SignalFixture.new()
	get_node("/root/VFX").add_child(owner)
	owner.phase_presented.emit("charge")
	owner.cue_started.emit("fire_charge")
	var recorded: Dictionary = observer.snapshot()
	check(recorded.zane.events.size() == 2, "observer captures first synchronous presenter signals")
	check(recorded.zane.events[0].value == "charge" and recorded.zane.events[1].value == "fire_charge", "observer preserves phase/cue order and actual values")
	check(recorded.zane.events[0].key == "observer-unit-fixture", "evidence retains owner admission key")
	check(recorded.roster == second.roster and recorded.zane.lifecycle == second.zane.lifecycle, "signal observation never changes gameplay or lifecycle")
	var outcome_label := Label.new()
	outcome_label.text = "MISS-from-real-Control"
	outcome_label.set_meta("zane_effect_role", "outcome")
	owner.add_child(outcome_label)
	await get_tree().process_frame
	var visual_record: Dictionary = observer.snapshot()
	check(visual_record.zane.samples.size() == 1 and visual_record.zane.samples[0].text == outcome_label.text, "observer retains actual effect Label text, never formula estimates")
	check(visual_record.zane.cleanup == {"reaction_marks": 0, "camera_kick_remaining": 0.0, "rig_state": "idle"}, "observer reads baseline cleanup without changing it")
	for index in 513: owner.cue_started.emit("bounded-unit-fixture")
	var bounded: Dictionary = observer.snapshot()
	check(bounded.zane.events.size() == observer.EVIDENCE_LIMIT and bounded.zane.overflow, "evidence is bounded and overflow is explicit")
	check(bounded.roster == second.roster, "bounded observation leaves roster unchanged")
	owner.queue_free()
	fixture.queue_free()
	await get_tree().process_frame
	print("Browser showcase observer contract: %d failures" % failures)
	get_tree().quit(1 if failures else 0)
