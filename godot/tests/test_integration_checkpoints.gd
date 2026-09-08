extends SceneTree

var gs: Node
var rm: Node
var saves: Node
var failures := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func snapshot() -> Dictionary:
	var result: Dictionary = JSON.parse_string(JSON.stringify(saves._serialize()))
	result.erase("saved_at")
	return result

func record() -> void:
	var file := FileAccess.open("user://integration_expected.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshot()))
	file.close()

func restored(label: String) -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://integration_expected.json"))
	check(snapshot() == expected, label + ": complete checkpoint matches across process restart")

func continue_game(ending: String) -> void:
	var title: Node = load("res://scenes/StartScreen.tscn").instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame
	title._on_continue_pressed()
	await process_frame
	await process_frame
	check(current_scene.scene_file_path.ends_with(ending), "actual Continue routes to " + ending)

func _run() -> void:
	gs = root.get_node("GameState")
	rm = root.get_node("RunManager")
	saves = root.get_node("SaveSystem")
	var mode := OS.get_cmdline_user_args()[0]
	match mode:
		"prepare":
			rm.start_new_run(0, 42)
			gs.active_run.run_deployment = [{"unit_id":"zane", "x":2, "y":4, "facing":"N"}]
			check(saves.save(), "before-battle checkpoint saved")
			record()
		"before":
			restored("before battle")
			await continue_game("StageSelect.tscn")
			restored("before battle after Continue")
			change_scene_to_file("res://scenes/Battle.tscn")
			await process_frame
			await process_frame
			var battle: Node = current_scene
			var gold_before: int = gs.gold
			battle._on_battle_won({"gold":100,"jp":11})
			check(gs.gold == gold_before + 100 and gs.active_run.current_floor == 2, "actual victory callback saves reward and advances floor")
			var after := snapshot()
			battle._on_battle_won({"gold":100,"jp":11})
			check(snapshot() == after, "repeated actual victory callback changes nothing")
			record()
			battle.battle_ui.spoils_continue_requested.emit()
			await process_frame
			await process_frame
		"victory":
			restored("after victory")
			await continue_game("StageSelect.tscn")
			restored("after victory after Continue")
			# Fixture setup: bypass floor 2 to reach a real generated floor-3 boon node.
			gs.active_run.complete_current_node()
			for node in gs.active_run.get_available_nodes():
				if node.type == "boon_pick": gs.active_run.select_node(node.id); break
			var offers: Array = BoonSystem.new().generate_offers(42, 3, [], gs.active_run.get_loadout_bonus())
			gs.pending_boon_offers = offers
			var chosen: Dictionary = offers[0].duplicate(true)
			current_scene._on_boon_picked(chosen)
			check(gs.active_run.active_boons.size() == 1 and gs.active_run.current_floor == 4 and gs.pending_boon_offers.is_empty(), "actual boon callback adds one boon and advances once")
			var after := snapshot()
			current_scene._on_boon_picked(chosen)
			check(snapshot() == after, "repeated boon callback changes nothing")
			record()
		"boon":
			restored("after boon")
			await continue_game("StageSelect.tscn")
			restored("after boon after Continue")
			current_scene._on_abandon()
			check(gs.active_run == null and not rm.is_run_active, "actual abandonment clears run")
			var after := snapshot()
			current_scene._on_abandon()
			check(snapshot() == after, "repeated abandonment changes nothing")
			record()
		"abandon":
			restored("after abandonment")
			await continue_game("HubScene.tscn")
			restored("after abandonment after Continue")
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	await process_frame
	await process_frame
	print("Integration mode %s: %d failures" % [mode, failures])
	quit(1 if failures else 0)
