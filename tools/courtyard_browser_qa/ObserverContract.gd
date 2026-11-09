extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	for i in 30:
		await process_frame
	var observer = load("res://courtyard_browser_qa/Observer.gd").new()
	root.add_child(observer)
	var state: Dictionary = observer.snapshot()
	var failures := 0
	if state.get("scene") != "res://prototypes/blooming/BloomingBattle.tscn": failures += 1
	if state.get("unit_count") != 4: failures += 1
	if state.get("unit", {}).get("id") != "zane": failures += 1
	if state.get("unit", {}).get("mp") != 90: failures += 1
	if state.get("settings", true) or state.get("review", true): failures += 1
	for i in 20:
		if observer.snapshot() != state: failures += 1
	observer.queue_free()
	battle.queue_free()
	await process_frame
	print("Courtyard observer: 25 checks, %d failures" % failures)
	if failures: printerr("FAIL: courtyard observer contract")
	quit(1 if failures else 0)
