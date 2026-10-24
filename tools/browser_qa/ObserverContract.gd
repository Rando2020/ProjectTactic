extends Node

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _ready() -> void:
	var fixture: Node = load("res://tests/browser_qa/BattleBrowserQA.tscn").instantiate()
	add_child(fixture)
	check(fixture is BattleScene and fixture.name == "BattleScene", "QA preserves production root type/name for absolute VFX paths")
	var observer: Node = fixture.get_node("BrowserQAObserver")
	for frame in range(180):
		await get_tree().process_frame
		var observation: Dictionary = observer.snapshot()
		if observation.get("phase", "") == "PLAYER_TURN":
			break
	var first: Dictionary = observer.snapshot()
	check(first.get("schema", 0) == 2, "observer schema v2 available")
	check(first.get("phase", "") == "PLAYER_TURN", "normal scene reaches player turn")
	check(first.get("unit", {}).get("id", "") == "lyra", "unmodified fixture starts Lyra")
	check(first.get("command", "unexpected").is_empty(), "observer does not select commands")
	var buttons: Dictionary = first.get("buttons", {})
	for key in ["ability", "move", "cancel", "attack"]:
		check(buttons.has(key), "observer exposes real %s control" % key)
		var rect: Array = buttons.get(key, {}).get("rect", [0, 0, 0, 0])
		check(rect[2] > 0 and rect[3] > 0, "%s has nonzero layout" % key)
	var actor_key: String = first.get("unit", {}).get("instance_id", "")
	check(not actor_key.is_empty(), "observer exposes stable stringified instance identity")
	var roster: Dictionary = first.get("roster", {})
	check(roster.has(actor_key), "roster retains original actor by instance identity")
	check(roster.size() == fixture.battle_manager.units.size(), "roster includes all live unit instances")
	check(roster.get(actor_key, {}).get("mp", -1) == first.get("unit", {}).get("mp", -2), "roster MP matches current actor")
	check(first.get("player_turn_serial", -1) == fixture.battle_manager._player_turn_serial, "observer reads existing turn serial")
	check("Attack" in buttons.get("attack", {}).get("labels", []), "observer reads actual button text")
	var sample := Button.new()
	var label := Label.new()
	label.text = "Quickstep"
	sample.add_child(label)
	check("Quickstep" in observer._button(sample).get("labels", []), "observer reads descendant ability label text")
	sample.free()
	check(not buttons.get("ability", {}).get("disabled", true), "Ability enabled")
	check(buttons.get("cancel", {}).get("disabled", false), "Cancel disabled while idle")
	for frame in range(10):
		await get_tree().process_frame
	var second: Dictionary = observer.snapshot()
	check(second.get("unit", {}) == first.get("unit", {}), "observations never alter unit state")
	check(second.get("roster", {}) == first.get("roster", {}), "observations never alter any roster unit")
	check(second.get("command", "unexpected").is_empty(), "observations never invoke commands")
	check(second.get("frame", 0) > first.get("frame", 0), "snapshots identify fresh frames")
	fixture.queue_free()
	await get_tree().process_frame
	print("Browser observer contract: %d failures" % failures)
	get_tree().quit(1 if failures else 0)
