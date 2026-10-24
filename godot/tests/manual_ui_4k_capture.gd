## Native-only UI raster fixture: actual BattleUI, representative data, no game-state writes.
## Open manual_ui_4k_capture.tscn and run current scene (F6). Not a gameplay capture.
extends Control

func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(3840, 2160)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var background := ColorRect.new()
	background.color = Color("101923")
	background.size = Vector2(3840, 2160)
	viewport.add_child(background)
	var hud := BattleUI.new()
	viewport.add_child(hud)
	hud._unit_name.text = "Lyra\nArcher"
	hud._phase_label.text = "PLAYER TURN"
	hud._objective_label.text = "Defeat all enemies • UI raster fixture (not gameplay)"
	hud._hp_label.text = "HP: 82/100"
	hud._mp_label.text = "MP: 24"
	hud._temper_label.text = "TMP: 18"
	hud._ether_label.text = "ETH: 12"
	hud._on_timeline_updated([
		{"display_name": "Zane", "unit_id": "zane", "team": "player"},
		{"display_name": "Storm Imp", "unit_id": "imp_a", "team": "enemy"},
		{"display_name": "Void Cultist", "unit_id": "cultist", "team": "enemy"},
		{"display_name": "Storm Imp", "unit_id": "imp_b", "team": "enemy"},
		{"display_name": "Mira", "unit_id": "mira", "team": "player"},
	])
	for button in [hud._move_btn, hud._attack_btn, hud._wait_btn, hud._ability_btn, hud._cancel_btn]:
		button.disabled = false
	var preview := TextureRect.new()
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.texture = viewport.get_texture()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(preview)
	for frame in range(5):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://../reports/native-ui-qa/ui-queue-repair-4k.png")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var error := viewport.get_texture().get_image().save_png(output)
	print("Native UI fixture capture: %s (error %d)" % [output, error])
