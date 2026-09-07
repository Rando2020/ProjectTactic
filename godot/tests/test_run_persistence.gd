extends SceneTree

var failures: int = 0
var players: Array[String] = ["zane"]
var gs: Node
var rm: Node
var saves: Node
var meta: Node
const SEED_VALUE: int = 9007199254740993

func _init() -> void:
	call_deferred("_run")

func _expect(condition: bool, label: String) -> void:
	print("PASS " if condition else "FAIL ", label)
	if not condition:
		failures += 1

func _run() -> void:
	gs = root.get_node("GameState")
	rm = root.get_node("RunManager")
	saves = root.get_node("SaveSystem")
	meta = root.get_node("MetaProgression")
	var mode := OS.get_cmdline_user_args()[0]
	match mode:
		"write": _write()
		"read": await _read_checkpoint()
		"ended":
			_expect(gs.active_run == null and not rm.is_run_active, "ended run stays ended across process restart")
			_expect(saves.continue_scene().ends_with("HubScene.tscn"), "campaign-only checkpoint resumes hub")
		"legacy":
			_expect(gs.gold == 91 and gs.get_jp("zane") == 17, "legacy campaign migration")
			_expect(meta.get_currency("soul-shards") == 44, "legacy currency migration")
			_expect(saves.has_save(), "legacy import creates unified autosave")
		"slot2":
			_expect(gs.active_run != null and gs.active_run.seed == 42, "schema 2 cold run restoration")
			_expect(gs.story_flags.is_empty(), "old boolean story flags repaired")
			_expect(rm.is_run_active and rm.run_seed == 42, "schema 2 synchronizes manager")
	print("Persistence mode %s: %d failures" % [mode, failures])
	quit(1 if failures else 0)

func _write() -> void:
	gs.unit_registry["zane"]["equipment"]["main_hand"] = "Checkpoint Staff"
	rm.start_new_run(3, SEED_VALUE)
	_expect(gs.unit_registry["zane"]["equipment"]["main_hand"] == "Checkpoint Staff", "new run retains equipment")
	gs.active_run.run_deployment = [{"unit_id": "zane", "x": 2, "y": 4, "facing": "N"}]
	gs.active_run.active_boons = [{"id": "test-boon", "power": 7}]
	gs.active_run.active_wanderer_conditions = [{"id": "test-condition"}]
	gs.run_inventory = [{"id": "test-loot", "rarity": "rare"}]
	gs.pending_boon_offers = [{"id": "pending-choice"}]
	gs.story_flags.append("checkpoint-story")
	saves.begin_transaction()
	gs.apply_victory("test-map", {"gold": 100, "jp": 11}, players)
	rm.award_stage_reward(1)
	_expect(gs.run_jp_earned == 11, "victory counts JP once")
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://save_1.json"))
	_expect(int(disk["progress"]["gold"]) == 0, "nested reward saves do not write a partial checkpoint")
	gs.active_run.complete_current_node()
	rm.rng.randi()
	_expect(saves.commit_transaction(), "atomic checkpoint writes")
	_expect(saves.save(2), "second slot writes")
	_expect(not saves.save(0) and not saves.load_slot(4), "invalid slots rejected")

func _read_checkpoint() -> void:
	_expect(gs.active_run != null, "cold process restores active run")
	if gs.active_run == null:
		return
	_expect(gs.active_run.seed == SEED_VALUE and rm.run_seed == SEED_VALUE, "64-bit seed survives JSON exactly")
	_expect(gs.active_run.current_floor == 2 and rm.current_stage == 2, "node and manager stage restored")
	_expect(gs.active_run.floor_plan[0]["completed"], "completed node stays completed")
	_expect(gs.active_run.run_deployment[0]["unit_id"] == "zane", "party and positions restored")
	_expect(gs.unit_registry["zane"]["equipment"]["main_hand"] == "Checkpoint Staff" and gs.get_jp("zane") == 11, "equipment and JP restored")
	_expect(rm.active_boons == gs.active_run.active_boons and rm.active_boons.size() == 1, "boon mirror restored")
	_expect(gs.run_inventory[0]["id"] == "test-loot" and gs.active_run.active_wanderer_conditions.size() == 1, "inventory and conditions restored")
	_expect(gs.pending_boon_offers[0]["id"] == "pending-choice", "pending choices restored")
	_expect(rm.run_aether == 20 and meta.get_currency("soul-shards") == 8 and gs.gold == 100, "all currency balances restored")
	var next_random: int = rm.rng.randi()
	_expect(saves.load_slot() and rm.rng.randi() == next_random, "RNG resumes its saved state")
	# Cold slot load must not depend on preexisting run or registry keys.
	gs.active_run = null
	gs.unit_registry.clear()
	rm.is_run_active = false
	_expect(saves.load_slot(2) and gs.active_run != null and rm.is_run_active, "cold slot restore rebuilds null run and empty registry")
	# Exercise a reward callback twice, then again after loading its receipt.
	gs.pending_boon_offers.clear()
	gs.apply_victory("second-map", {"gold": 13, "jp": 2}, players)
	rm.award_stage_reward(2)
	var gold_before: int = gs.gold
	var shards_before: int = meta.get_currency("soul-shards")
	var aether_before: int = rm.run_aether
	_expect(saves.load_slot(), "reward receipt reload")
	gs.apply_victory("second-map", {"gold": 13, "jp": 2}, players)
	rm.award_stage_reward(2)
	_expect(gs.gold == gold_before and meta.get_currency("soul-shards") == shards_before and rm.run_aether == aether_before, "repeated callbacks do not duplicate rewards after reload")
	var file := FileAccess.open("user://save_3.json", FileAccess.WRITE)
	file.store_string('{"schema":999}')
	file.close()
	_expect(not saves.load_slot(3) and gs.gold == gold_before and rm.is_run_active, "future or malformed save leaves live state unchanged")
	file = FileAccess.open("user://save_3.json", FileAccess.WRITE)
	file.store_string('not json')
	file.close()
	_expect(not saves.has_save(3) and not saves.load_slot(3), "corrupt JSON rejected")
	# Use the actual title-screen callback and observe its scene transition.
	var title: Node = load("res://scenes/StartScreen.tscn").instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame
	title._on_continue_pressed()
	await process_frame
	await process_frame
	_expect(current_scene != null and current_scene.scene_file_path.ends_with("StageSelect.tscn"), "Continue routes restored run to map")
	var vow_id: String = gs.active_run.equipped_vow_id
	rm.end_run(true)
	var end_shards: int = meta.get_currency("soul-shards")
	var end_xp: int = gs.get_vow_xp(vow_id)
	rm.end_run(true)
	_expect(saves.load_slot() and gs.active_run == null and not rm.is_run_active, "ended checkpoint clears run and manager")
	_expect(meta.get_currency("soul-shards") == end_shards and gs.get_vow_xp(vow_id) == end_xp and rm.run_aether == 0, "repeat end or reload cannot pay end rewards again")
	rm.start_new_run(0, 77)
	_expect(rm.award_stage_reward(2).is_empty(), "stale stage callback is rejected")
	rm.award_stage_reward(1)
	rm.end_run(false)
	end_shards = meta.get_currency("soul-shards")
	rm.end_run(false)
	_expect(saves.load_slot() and gs.active_run == null and meta.get_currency("soul-shards") == end_shards, "abandonment stays ended without duplicate payout")
