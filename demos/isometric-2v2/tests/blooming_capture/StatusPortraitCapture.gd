extends Node
## Actual rendered battle, not a composed mockup. Also runnable against exported PCK.
var output_dir := "user://status-portraits"
var failures := 0
func frames(count: int = 6) -> void:
	for i in count: await get_tree().process_frame
func capture(label: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	if get_viewport().get_texture().get_image().save_png(output_dir.path_join(label + ".png")) != OK:
		failures += 1
func _ready() -> void: run.call_deferred()
func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("FAIL: Status portrait capture needs a real renderer")
		get_tree().quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): output_dir = arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var battle = load("res://prototypes/blooming/BloomingBattle.tscn").instantiate()
	add_child(battle)
	await frames(30)
	var ui = battle.battle_ui
	var manager = battle.battle_manager
	# The check matters in exports: original sheets were previously excluded.
	for id in ["zane","kael"]:
		if not ui._status_portrait(id) is AtlasTexture:
			printerr("FAIL: Exported detailed portrait missing for " + id)
			failures += 1
	ui._selection.select_unit("zane")
	for size in [Vector2i(1920,1080),Vector2i(1366,768),Vector2i(960,540)]:
		get_window().content_scale_size = size
		get_window().size = size
		await frames()
		await capture("zane-status-%d" % size.x)
	# Real mobile-sized render using the game's existing canvas stretch policy.
	get_window().content_scale_size = Vector2i(1920,1080)
	get_window().size = Vector2i(844,390)
	await frames()
	ui.set_tester_collapsed(true)
	await capture("zane-status-mobile-landscape-844")
	get_window().content_scale_size = Vector2i(1920,1080)
	get_window().size = Vector2i(1920,1080)
	ui.set_tester_collapsed(false)
	await frames()
	ui._on_wait()
	ui._on_confirm()
	for i in 1000:
		if manager.active_unit_id == "kael" and manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().create_timer(0.025).timeout
	if manager.active_unit_id != "kael": failures += 1
	ui._selection.select_unit("kael")
	await capture("kael-status-1920")
	battle.set_compact_skins(false)
	await capture("kael-status-original-1920")
	battle.queue_free()
	await frames()
	print("Status portrait capture: 6 images, %d failures" % failures)
	get_tree().quit(0 if failures == 0 else 1)
