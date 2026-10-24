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
	check(first.get("schema", 0) == 1, "observer schema available")
	check(first.get("phase", "") == "PLAYER_TURN", "normal scene reaches player turn")
	check(first.get("unit", {}).get("id", "") == "lyra", "unmodified fixture starts Lyra")
	check(first.get("command", "unexpected").is_empty(), "observer does not select commands")
	var buttons: Dictionary = first.get("buttons", {})
	for key in ["ability", "move", "cancel"]:
		check(buttons.has(key), "observer exposes real %s control" % key)
		var rect: Array = buttons.get(key, {}).get("rect", [0, 0, 0, 0])
		check(rect[2] > 0 and rect[3] > 0, "%s has nonzero layout" % key)
	check(not buttons.get("ability", {}).get("disabled", true), "Ability enabled")
	check(buttons.get("cancel", {}).get("disabled", false), "Cancel disabled while idle")
	for frame in range(10):
		await get_tree().process_frame
	var second: Dictionary = observer.snapshot()
	check(second.get("unit", {}) == first.get("unit", {}), "observations never alter unit state")
	check(second.get("command", "unexpected").is_empty(), "observations never invoke commands")
	check(second.get("frame", 0) > first.get("frame", 0), "snapshots identify fresh frames")
	fixture.queue_free()
	await get_tree().process_frame
	print("Browser observer contract: %d failures" % failures)
	get_tree().quit(1 if failures else 0)
