extends Node

const ENTRY := "Practice: Zane showcase"
const BANNER := "Zane showcase: try movement, a sword attack, or Fire on separate turns. Fire targets a three-tile fan."
const MOTION := "Reduced Zane impact motion"
var checks := 0
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _ready() -> void:
	call_deferred("run")

func button_named(root: Node, text: String) -> Button:
	for candidate in root.find_children("*", "Button", true, false):
		if candidate.text == text: return candidate
	return null

func run() -> void:
	GameState._init_defaults()
	GameState.active_run = null
	GameState.practice_session.clear()
	var start := preload("res://scenes/StartScreen.tscn").instantiate()
	add_child(start)
	var entry := button_named(start, ENTRY)
	check(entry != null, "existing 3D Practice entry has exact discoverable showcase name")
	check(button_named(start, "Continue Descent") != null, "Continue path remains visible")
	check(button_named(start, "Practice Battle / Retry Enabled") != null, "ordinary Practice path remains visible")
	if failures.is_empty():
		await check_title_geometry(start, entry)
		await check_practice(start, entry)
	if is_instance_valid(start):
		start.music_player.stop()
		start.free()
	await get_tree().create_timer(0.25).timeout
	print("Zane impact showcase: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func check_title_geometry(start: Node, entry: Button) -> void:
	var prefs := preload("res://scripts/ui/UISettings.gd").shared()
	var old_mode: int = prefs.mode
	for viewport_size in [Vector2i(1920,1080), Vector2i(3840,2160)]:
		get_viewport().content_scale_size = Vector2i.ZERO
		get_viewport().size = viewport_size
		for mode in range(4):
			prefs.set_mode(mode, false)
			start._apply_ui_size()
			entry.grab_focus()
			await get_tree().process_frame
			await get_tree().process_frame
			check(Rect2(Vector2.ZERO,Vector2(viewport_size)).encloses(entry.get_global_rect()), "focused showcase entry fits %s UI mode %d headless layout" % [viewport_size, mode])
			var text_width := entry.get_theme_font("font").get_string_size(entry.text,HORIZONTAL_ALIGNMENT_LEFT,-1,entry.get_theme_font_size("font_size")).x
			check(text_width + entry.get_theme_stylebox("normal").get_minimum_size().x <= entry.size.x, "exact entry label fits %s UI mode %d without clipping" % [viewport_size, mode])
	prefs.set_mode(old_mode, false)

func settings_snapshot() -> Dictionary:
	var snapshot := {}
	for path in ["user://settings.cfg", "user://ui_settings.cfg"]:
		var exists := FileAccess.file_exists(path)
		snapshot[path] = {"exists": exists, "bytes": FileAccess.get_file_as_bytes(path) if exists else PackedByteArray()}
	return snapshot

func check_practice(start: Node, entry: Button) -> void:
	var baseline: Dictionary = GameState.serialize_state().duplicate(true)
	# Seed the canonical baseline before admission, as an existing player save.
	GameState.save()
	var canonical := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	var settings := settings_snapshot()
	var original_scene := get_tree().current_scene
	# Keep this harness alive while exercising the REAL button/scene transition.
	get_tree().current_scene = null
	entry.pressed.emit()
	for i in 20:
		if get_tree().current_scene is BattleScene: break
		await get_tree().process_frame
	var battle := get_tree().current_scene as BattleScene
	check(is_instance_valid(battle) and bool(GameState.practice_session.get("rig3d",false)) and bool(GameState.practice_session.get("zane_showcase",false)), "actual entry uses existing Practice admission then session-only rig/showcase flags")
	if not is_instance_valid(battle):
		get_tree().current_scene = original_scene
		return
	start.music_player.stop()
	start.free()
	check(settings_snapshot() == settings and FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == canonical, "actual entry preserves existing serialized UI/audio settings and canonical save bytes")
	check(FileAccess.get_file_as_string(GameState.SAVE_PATH) == JSON.stringify(baseline, "\t"), "entry writes only the original canonical baseline save bytes")
	var manager: BattleManager = battle.battle_manager
	var panel = battle.comparison_panel
	check(panel != null, "showcase reuses existing comparison controls")
	var banner := panel.find_child("ZaneShowcaseBanner", true, false) as Label
	var motion := panel.find_child("ReducedZaneMotion", true, false) as CheckButton
	check(banner != null and banner.text == BANNER and banner.is_visible_in_tree(), "exact turn-by-turn fan instructions stay visible with options collapsed")
	check(motion != null and motion.text == MOTION and not motion.is_visible_in_tree(), "session-only reduced motion control is inside collapsed Practice view UI")
	check(manager.units.size() == 7 and manager.units.has("kael") and manager.units.has("mira") and manager.units.has("lyra") and manager.units.has("zane"), "original party and three enemies are retained")
	check(manager.units.Enemy_1.unit_data.id == "null_drake" and manager.units.Enemy_2.unit_data.id == "storm_imp" and manager.units.Enemy_3.unit_data.id == "void_cultist", "existing three enemy archetypes and spawn order are unchanged")
	check(battle.map_index == 0 and manager.units.zane.grid_pos == Vector2i(1,6) and manager.units.lyra.grid_pos == Vector2i(0,7), "showcase keeps existing Practice map and starting deployment")
	for i in 300:
		if manager.current_phase == BattleManager.Phase.PLAYER_TURN: break
		await get_tree().process_frame
	var active := manager.active_unit_id
	check(manager.current_phase == BattleManager.Phase.PLAYER_TURN and active == "lyra", "showcase retains ordinary first Lyra turn, no forced Zane turn")
	check(manager.units.zane.has_zane_impact_presentation(), "existing rig3d flag loads new variant")
	manager.is_resolving_action = true
	panel._update_controls()
	check(motion.disabled and not panel.switch_reduced_motion() and not bool(GameState.practice_session.get("reduced_zane_motion",false)), "disabled comfort control retains resolving-action guard")
	manager.is_resolving_action = false
	manager.current_phase = BattleManager.Phase.RESOLVE
	panel._update_controls()
	check(motion.disabled and not panel.switch_reduced_motion(), "comfort control also refuses non-player phases")
	manager.current_phase = BattleManager.Phase.PLAYER_TURN
	panel._update_controls()
	motion.pressed.emit()
	check(bool(GameState.practice_session.get("reduced_zane_motion",false)) and motion.button_pressed, "actual comfort control stores only session policy")
	check(manager.active_unit_id == active and not manager.active_unit_has_acted and not manager.active_unit_has_moved, "comfort control never changes turn ownership/actions")
	check(GameState.serialize_state() == GameState.practice_session.checkpoint, "comfort flag never becomes a canonical gameplay save field")
	check(panel.switch_mode() and manager.units.zane._rig3d == null and manager.units.zane._sprite.visible, "existing view toggle restores visible sprite fallback")
	check(panel.switch_mode() and manager.units.zane.has_zane_impact_presentation(), "existing Show 3D toggle restores validated new variant")
	var reveal := button_named(panel, "View & quality settings")
	check(reveal != null, "existing settings reveal remains discoverable")
	if reveal != null: reveal.pressed.emit()
	var prefs := preload("res://scripts/ui/UISettings.gd").shared()
	var old_mode: int = prefs.mode
	for viewport_size in [Vector2i(1920,1080),Vector2i(3840,2160)]:
		get_viewport().content_scale_size = Vector2i.ZERO
		get_viewport().size = viewport_size
		for mode in range(4):
			prefs.set_mode(mode, false)
			panel._apply_ui_size()
			await get_tree().process_frame
			await get_tree().process_frame
			check(Rect2(Vector2.ZERO,Vector2(viewport_size)).encloses(panel.get_child(0).get_global_rect()), "complete expanded settings panel fits %s UI mode %d headless layout" % [viewport_size, mode])
			if banner != null:
				check(Rect2(Vector2.ZERO,Vector2(viewport_size)).encloses(banner.get_global_rect()) and banner.get_line_count() == banner.get_visible_line_count(), "complete instructions fit %s UI mode %d headless layout" % [viewport_size, mode])
			if motion != null:
				check(motion.is_visible_in_tree() and Rect2(Vector2.ZERO,Vector2(viewport_size)).encloses(motion.get_global_rect()), "revealed motion control fits %s UI mode %d headless layout" % [viewport_size, mode])
				var text_width := motion.get_theme_font("font").get_string_size(motion.text,HORIZONTAL_ALIGNMENT_LEFT,-1,motion.get_theme_font_size("font_size")).x
				var margins := motion.get_theme_stylebox("normal").get_minimum_size().x + motion.get_theme_icon("checked").get_width() + motion.get_theme_constant("h_separation")
				check(text_width + margins <= motion.size.x, "motion label and checkbox fit without clipping at %s UI mode %d" % [viewport_size, mode])
	prefs.set_mode(old_mode, false)
	var audio := get_node("/root/AudioSettings")
	for bus in ["Game","FX"]:
		var old_game: int = audio.game_volume
		var old_fx: int = audio.fx_volume
		if bus == "Game": audio.game_volume = 0
		else: audio.fx_volume = 0
		audio.apply_all()
		var voice: AudioStreamPlayer = preload("res://scripts/presentation/ZaneImpactAudio.gd").play_cue("fire_hit", panel)
		check(voice != null and voice.bus == "FX" and AudioServer.is_bus_mute(AudioServer.get_bus_index(bus)), bus + " zero genuinely mutes the new FX→Game cue chain")
		check(AudioServer.get_bus_send(AudioServer.get_bus_index("FX")) == "Game" and AudioServer.get_bus_send(AudioServer.get_bus_index("Music")) == "Game", "FX and Music remain independently routed")
		if voice != null: voice.stop(); voice.free()
		audio.game_volume = old_game
		audio.fx_volume = old_fx
		audio.apply_all()
	var old_music: int = audio.music_volume
	var fx_was_muted := AudioServer.is_bus_mute(AudioServer.get_bus_index("FX"))
	audio.music_volume = 0
	audio.apply_all()
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and AudioServer.is_bus_mute(AudioServer.get_bus_index("FX")) == fx_was_muted, "Music mute leaves the existing FX mute preference unchanged")
	audio.music_volume = old_music
	audio.apply_all()
	check(settings_snapshot() == settings, "session comfort/mute verification did not rewrite audio settings")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == canonical, "showcase never leaks transient settings to canonical disk save")
	check(GameState.finish_practice(false) and GameState.retry_practice(), "original retry sandbox still works")
	check(bool(GameState.practice_session.get("reduced_zane_motion",false)) and bool(GameState.practice_session.get("zane_showcase",false)), "retry retains session comfort and discovery flags")
	get_tree().current_scene = null
	battle.queue_free()
	await get_tree().process_frame
	var retry := preload("res://scenes/Battle.tscn").instantiate() as BattleScene
	get_tree().root.add_child(retry)
	get_tree().current_scene = retry
	var retry_motion := retry.comparison_panel.find_child("ReducedZaneMotion",true,false) as CheckButton
	check(retry_motion != null and retry_motion.button_pressed and retry.battle_manager.units.zane.has_zane_impact_presentation(), "fresh retry scene restores session-only comfort and validated 3D variant")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == canonical and settings_snapshot() == settings, "retry leaves canonical save and serialized settings byte-identical")
	get_tree().current_scene = null
	retry.queue_free()
	await get_tree().process_frame
	check(GameState.leave_practice() and GameState.serialize_state() == baseline, "exit restores exact canonical baseline")
	check(GameState.practice_session.is_empty() and settings_snapshot() == settings, "exit clears session-only fields without settings leakage")
	check(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == canonical, "exit writes the same canonical baseline bytes, no session fields")
	get_tree().current_scene = original_scene
