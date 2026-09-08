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
		"menus":
			saves.delete_slot(1)
			var title: Node = load("res://scenes/StartScreen.tscn").instantiate()
			root.add_child(title)
			current_scene = title
			await process_frame
			check(title._buttons[1].disabled, "Continue disabled without a checkpoint")
			title._on_options_pressed()
			var music: HSlider = title._options.find_child("MusicVolume", true, false)
			music.value = 37
			var audio := root.get_node("AudioSettings")
			check(audio.music_volume == 37, "title audio slider updates existing audio owner")
			audio.music_volume = 80
			audio.load_settings()
			check(audio.music_volume == 37, "audio setting persists to disk")
			title._options._close()
			await process_frame
			rm.start_new_run(0, 55)
			gs.gold = 25
			gs.active_run.run_deployment = [{"unit_id":"zane", "x":2, "y":4}]
			check(saves.save(2), "manual fixture checkpoint saved")
			gs.gold = 75
			check(saves.save(), "different autosave fixture saved")
			DirAccess.make_dir_absolute("user://save_1.json.tmp")
			check(not saves.activate_slot(2) and gs.gold == 75, "failed slot activation restores previous live state")
			DirAccess.remove_absolute("user://save_1.json.tmp")
			check(saves.load_slot() and gs.gold == 75, "failed slot activation preserves previous autosave")
			check(saves.activate_slot(2) and gs.gold == 25, "selected slot activates")
			gs.gold = 999
			check(saves.load_slot() and gs.gold == 25, "selected slot becomes Continue autosave")
			title._refresh_continue()
			check(not title._buttons[1].disabled and "Floor 1" in title._status_label.text, "Continue shows active checkpoint")
			title._on_load_pressed()
			check(is_instance_valid(title._load_dialog), "Load Game opens slot picker")
			title._load_dialog.queue_free()
			await continue_from_existing_title(title)
			var before := snapshot()
			current_scene._confirm_abandon()
			var confirmation: ConfirmationDialog
			for child in current_scene.get_children():
				if child is ConfirmationDialog: confirmation = child
			check(confirmation != null and snapshot() == before, "abandon dialog does not end run before confirmation")
			confirmation.canceled.emit()
			await process_frame
			check(snapshot() == before, "cancel abandonment preserves run")
			DirAccess.make_dir_absolute("user://save_1.json.tmp")
			current_scene._save_and_title()
			check(current_scene.scene_file_path.ends_with("StageSelect.tscn") and snapshot() == before, "failed Save and Title keeps run open")
			DirAccess.remove_absolute("user://save_1.json.tmp")
			for child in current_scene.get_children():
				if child is AcceptDialog: child.queue_free()
			await process_frame
			current_scene._save_and_title()
			await process_frame
			await process_frame
			check(current_scene.scene_file_path.ends_with("StartScreen.tscn"), "Save and Title returns to title")
			check(snapshot() == before, "Save and Title preserves complete run without payout")
			current_scene._on_continue_pressed()
			await process_frame
			await process_frame
			check(current_scene.scene_file_path.ends_with("StageSelect.tscn") and snapshot() == before, "Continue resumes saved session exactly")
		"abandon":
			restored("after abandonment")
			await continue_game("HubScene.tscn")
			restored("after abandonment after Continue")
	# Headless tests can exit before confirmation SFX naturally finishes.
	for player in root.get_node("AudioSettings").get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.queue_free()
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	await process_frame
	await process_frame
	# Let the audio mixer release stopped playback references before shutdown.
	await create_timer(0.15).timeout
	print("Integration mode %s: %d failures" % [mode, failures])
	quit(1 if failures else 0)

func continue_from_existing_title(title: Node) -> void:
	title._on_continue_pressed()
	await process_frame
	await process_frame
